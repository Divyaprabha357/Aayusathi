import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/vital_reading.dart';
import 'arduino_adapter.dart';
import 'demo_reading_provider.dart';
import 'serial_parser.dart';

/// Central Arduino Hardware Service.
/// Coordinates the underlying adapter, serial line parsing, stream management,
/// software-triggered measurement protocol, strict 15-second timeout,
/// and deterministic demo fallback for the AAYUSATHI kiosk terminal.
class ArduinoService extends ChangeNotifier {
  final ArduinoAdapter adapter;
  final Duration staleTimeout;
  final Duration hardwareTimeout;

  late final StreamSubscription<String> _dataSubscription;
  late final StreamSubscription<ArduinoConnectionState> _connectionSubscription;

  final _readingsController = StreamController<VitalReading>.broadcast();
  VitalReading _currentReading = VitalReading.empty();

  DateTime? _lastReadingReceivedAt;
  bool _isStale = false;
  Timer? _staleTimer;

  // Hardware measurement state
  bool _isHardwareMeasuring = false;
  bool _isHardwareFallback = false;
  Timer? _hardwareTimeoutTimer;
  int _measurementSessionCounter = 0;
  bool _lastCommandSentSuccessfully = false;

  ArduinoService({
    ArduinoAdapter? adapter,
    this.staleTimeout = const Duration(seconds: 10),
    this.hardwareTimeout = const Duration(seconds: 15),
  })  : adapter = adapter ?? RealArduinoAdapter() {
    _initStreams();
  }

  void _initStreams() {
    _dataSubscription = adapter.rawDataStream.listen(_onRawData);
    _connectionSubscription = adapter.connectionStateStream.listen((state) {
      if (state == ArduinoConnectionState.disconnected ||
          state == ArduinoConnectionState.error) {
        _staleTimer?.cancel();
        _staleTimer = null;
        if (_currentReading.status == VitalStatus.reading && !_isHardwareMeasuring) {
          _currentReading = _currentReading.copyWith(status: VitalStatus.waiting);
          _readingsController.add(_currentReading);
        }
      }
      notifyListeners();
    });
  }

  VitalReading get currentReading => _currentReading;
  Stream<VitalReading> get readingsStream => _readingsController.stream;
  ArduinoConnectionState get connectionState => adapter.connectionState;
  Stream<ArduinoConnectionState> get connectionStateStream => adapter.connectionStateStream;

  DateTime? get lastReadingReceivedAt => _lastReadingReceivedAt;
  bool get isStale => _isStale;

  bool get isHardwareMeasuring => _isHardwareMeasuring;
  bool get isHardwareFallback => _isHardwareFallback;
  bool get isMeasuring => _isHardwareMeasuring;
  bool get lastCommandSentSuccessfully => _lastCommandSentSuccessfully;

  void _onRawData(String rawLine) {
    // Strictly prevent late serial responses from overwriting completed fallback results
    if (_isHardwareFallback) {
      return;
    }

    var updated = ArduinoSerialParser.parseLine(rawLine, _currentReading);
    if (updated != _currentReading) {
      if (_isHardwareMeasuring) {
        if (updated.isComplete) {
          // Valid readings arrived before timeout: cancel timeout immediately
          _hardwareTimeoutTimer?.cancel();
          _hardwareTimeoutTimer = null;
          _isHardwareMeasuring = false;

          // Stop sensor acquisition cleanly
          adapter.stopReading();

          // Mark reading as genuine Arduino source
          updated = updated.copyWith(
            source: VitalSource.arduino,
            status: VitalStatus.valid,
          );
        }
      }

      _lastReadingReceivedAt = DateTime.now();
      _isStale = false;
      _scheduleStaleCheck();
      _currentReading = updated;
      if (!_readingsController.isClosed) {
        _readingsController.add(_currentReading);
      }
      notifyListeners();
    }
  }

  void _scheduleStaleCheck() {
    _staleTimer?.cancel();
    _staleTimer = Timer(staleTimeout, () {
      if (connectionState == ArduinoConnectionState.connected &&
          _currentReading.status == VitalStatus.reading) {
        _isStale = true;
        notifyListeners();
      }
    });
  }

  /// Initiates connection to Arduino sensor terminal.
  Future<bool> connect() async {
    return await adapter.connect();
  }

  /// Disconnects from the hardware device.
  Future<void> disconnect() async {
    _hardwareTimeoutTimer?.cancel();
    _hardwareTimeoutTimer = null;
    _isHardwareMeasuring = false;
    _staleTimer?.cancel();
    _staleTimer = null;
    await adapter.disconnect();
  }

  /// Re-attempts connection to the physical serial port.
  Future<bool> reconnect() async {
    await disconnect();
    final ok = await connect();
    if (ok) {
      await startReading();
    }
    return ok;
  }

  /// Starts sensor data acquisition stream.
  Future<void> startReading() async {
    if (_currentReading.status == VitalStatus.waiting) {
      _currentReading = _currentReading.copyWith(status: VitalStatus.reading);
      if (!_readingsController.isClosed) {
        _readingsController.add(_currentReading);
      }
      notifyListeners();
    }
    await adapter.startReading();
  }

  /// Stops sensor acquisition.
  Future<void> stopReading() async {
    _hardwareTimeoutTimer?.cancel();
    _hardwareTimeoutTimer = null;
    _isHardwareMeasuring = false;
    _staleTimer?.cancel();
    _staleTimer = null;
    await adapter.stopReading();
  }

  /// Sends a serial command string to the connected Arduino terminal.
  Future<bool> sendCommand(String command) async {
    return await adapter.sendCommand(command);
  }

  /// Triggers a software-commanded vital measurement session on the Arduino.
  ///
  /// 1. Prevents duplicate concurrent requests.
  /// 2. Connects or reuses the serial connection.
  /// 3. Sends `START\n` command to the Arduino.
  /// 4. Begins the strict 15-second hardware timeout.
  /// 5. If valid readings arrive before timeout, cancels timeout and displays real readings.
  /// 6. If disconnected, no response, or timeout expires, cleanly halts and enters demo fallback.
  Future<bool> triggerHardwareMeasurement({
    Duration? timeout,
    String? patientId,
    String? appointmentId,
  }) async {
    // Guard against duplicate concurrent requests
    if (_isHardwareMeasuring) {
      return false;
    }

    final sessionId = ++_measurementSessionCounter;
    _isHardwareMeasuring = true;
    _isHardwareFallback = false;
    _lastCommandSentSuccessfully = false;

    // Reset current reading to reading status
    _currentReading = VitalReading.empty().copyWith(
      patientId: patientId,
      appointmentId: appointmentId,
      status: VitalStatus.reading,
      source: VitalSource.arduino,
    );
    if (!_readingsController.isClosed) {
      _readingsController.add(_currentReading);
    }
    notifyListeners();

    // 1. Open or reuse serial COM connection
    if (connectionState != ArduinoConnectionState.connected) {
      final ok = await connect();
      if (!ok) {
        _isHardwareMeasuring = false;
        _applyFailureOrFallback(
          patientId: patientId,
          appointmentId: appointmentId,
          errorMessage: 'Hardware connection unavailable',
        );
        return false;
      }
    }

    // 2. Start adapter reading loop
    await startReading();

    // 3. Send START command to the Arduino
    final commandSent = await sendCommand('START\n');
    _lastCommandSentSuccessfully = commandSent;
    if (!commandSent) {
      _isHardwareMeasuring = false;
      _applyFailureOrFallback(
        patientId: patientId,
        appointmentId: appointmentId,
        errorMessage: 'Failed to send measurement command to Arduino',
      );
      return false;
    }

    // 4. Start strict 15-second hardware timeout
    final effectiveTimeout = timeout ?? hardwareTimeout;
    _hardwareTimeoutTimer?.cancel();
    _hardwareTimeoutTimer = Timer(effectiveTimeout, () {
      _handleHardwareTimeout(sessionId, patientId: patientId, appointmentId: appointmentId);
    });

    return true;
  }

  void _handleHardwareTimeout(
    int sessionId, {
    String? patientId,
    String? appointmentId,
  }) {
    // Prevent stale timeout handlers or concurrent duplicate results
    if (_measurementSessionCounter != sessionId || !_isHardwareMeasuring) {
      return;
    }

    _hardwareTimeoutTimer?.cancel();
    _hardwareTimeoutTimer = null;
    _isHardwareMeasuring = false;

    // Cleanly stop adapter reading
    adapter.stopReading();

    _applyFailureOrFallback(
      patientId: patientId,
      appointmentId: appointmentId,
      errorMessage: 'Hardware readings unavailable. Demo values are being displayed.',
    );
  }

  void _applyFailureOrFallback({
    String? patientId,
    String? appointmentId,
    required String errorMessage,
  }) {
    if (DemoReadingProvider.instance.isDemoModeEnabled) {
      _isHardwareFallback = true;
      _currentReading = DemoReadingProvider.instance.getNextFallbackReading(
        patientId: patientId,
        appointmentId: appointmentId,
      );
    } else {
      _isHardwareFallback = false;
      _currentReading = VitalReading.empty().copyWith(
        patientId: patientId,
        appointmentId: appointmentId,
        status: VitalStatus.error,
        errorMessage: errorMessage,
      );
    }

    if (!_readingsController.isClosed) {
      _readingsController.add(_currentReading);
    }
    notifyListeners();
  }

  /// Injects a reading directly (useful for tests and controlled clinical demonstrations).
  void injectReading(VitalReading reading) {
    _hardwareTimeoutTimer?.cancel();
    _hardwareTimeoutTimer = null;
    _isHardwareMeasuring = false;
    _isHardwareFallback = reading.source == VitalSource.simulated &&
        (reading.errorMessage == 'SIMULATED — HARDWARE TIMEOUT');
    _lastReadingReceivedAt = DateTime.now();
    _isStale = false;
    _currentReading = reading;
    if (!_readingsController.isClosed) {
      _readingsController.add(_currentReading);
    }
    notifyListeners();
  }

  /// Clears current vital measurements and resets the hardware state for the next patient.
  void reset() {
    _hardwareTimeoutTimer?.cancel();
    _hardwareTimeoutTimer = null;
    _isHardwareMeasuring = false;
    _isHardwareFallback = false;
    _staleTimer?.cancel();
    _staleTimer = null;
    _lastReadingReceivedAt = null;
    _isStale = false;
    _currentReading = VitalReading.empty();
    if (!_readingsController.isClosed) {
      _readingsController.add(_currentReading);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _hardwareTimeoutTimer?.cancel();
    _staleTimer?.cancel();
    _dataSubscription.cancel();
    _connectionSubscription.cancel();
    _readingsController.close();
    adapter.dispose();
    super.dispose();
  }
}

import 'dart:async';
import 'arduino_adapter.dart';
import 'arduino_serial_config.dart';

/// Web implementation of [RealArduinoAdapter].
/// Since physical COM/Serial ports via Win32 are not available in the browser,
/// this adapter provides graceful simulated telemetry on web localhost so
/// the full Kiosk vitals interface can be experienced and tested seamlessly.
class RealArduinoAdapter implements ArduinoAdapter {
  final ArduinoSerialConfig config;
  final _connectionStateController = StreamController<ArduinoConnectionState>.broadcast();
  final _rawDataController = StreamController<String>.broadcast();

  ArduinoConnectionState _connectionState = ArduinoConnectionState.disconnected;
  bool _isReading = false;
  Timer? _simulationTimer;
  int _tickCount = 0;

  RealArduinoAdapter({this.config = const ArduinoSerialConfig()});

  @override
  ArduinoConnectionState get connectionState => _connectionState;

  @override
  Stream<ArduinoConnectionState> get connectionStateStream => _connectionStateController.stream;

  @override
  Stream<String> get rawDataStream => _rawDataController.stream;

  @override
  Future<bool> connect() async {
    if (_connectionState == ArduinoConnectionState.connected) {
      return true;
    }
    _updateState(ArduinoConnectionState.connecting);
    await Future.delayed(const Duration(milliseconds: 300));
    _updateState(ArduinoConnectionState.connected);
    return true;
  }

  @override
  Future<void> disconnect() async {
    await stopReading();
    _updateState(ArduinoConnectionState.disconnected);
  }

  @override
  Future<void> startReading() async {
    if (_connectionState != ArduinoConnectionState.connected) {
      final ok = await connect();
      if (!ok) return;
    }

    if (_isReading) return;
    _isReading = true;

    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isReading) return;
      _tickCount++;
      // Emit realistic fluctuating clinical vitals
      final hr = 72 + (_tickCount % 6);
      final spo2 = 98 - (_tickCount % 2);
      final temp = (36.6 + (_tickCount % 4) * 0.1).toStringAsFixed(1);

      if (!_rawDataController.isClosed) {
        _rawDataController.add('HR:$hr,SPO2:$spo2,TEMP:$temp');
      }
    });
  }

  @override
  Future<void> stopReading() async {
    _isReading = false;
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  @override
  Future<bool> sendCommand(String command) async {
    return _connectionState == ArduinoConnectionState.connected;
  }

  void _updateState(ArduinoConnectionState state) {
    _connectionState = state;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(state);
    }
  }

  @override
  void dispose() {
    disconnect();
    _connectionStateController.close();
    _rawDataController.close();
  }
}

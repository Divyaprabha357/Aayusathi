import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:serial_port_win32/serial_port_win32.dart';
import 'package:win32/win32.dart';
import 'arduino_adapter.dart';
import 'arduino_serial_config.dart';

/// Production Arduino adapter for Windows desktop.
/// Connects to Arduino UNO through Windows USB Serial (COM7 @ 9600 baud by default).
/// Reads byte stream, splits lines, and emits decoded telemetry.
class RealArduinoAdapter implements ArduinoAdapter {
  final ArduinoSerialConfig config;
  final _connectionStateController = StreamController<ArduinoConnectionState>.broadcast();
  final _rawDataController = StreamController<String>.broadcast();

  ArduinoConnectionState _connectionState = ArduinoConnectionState.disconnected;
  SerialPort? _serialPort;
  bool _isReading = false;
  Timer? _readTimer;
  final StringBuffer _lineBuffer = StringBuffer();

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

    try {
      // Serial communication via Win32 requires Windows platform
      if (!Platform.isWindows) {
        _updateState(ArduinoConnectionState.error);
        return false;
      }

      // Check available COM ports
      final availablePorts = SerialPort.getAvailablePorts();
      final targetPort = config.port.toUpperCase();
      final hasPort = availablePorts.any((p) => p.toUpperCase() == targetPort);

      if (!hasPort) {
        _updateState(ArduinoConnectionState.error);
        return false;
      }

      // Instantiate and open port
      final port = SerialPort(config.port, openNow: false, BaudRate: config.baudRate);
      if (!port.isOpened) {
        await port.open();
      }

      if (!port.isOpened) {
        _updateState(ArduinoConnectionState.error);
        return false;
      }

      // Configure communication rate and assert DTR/RTS signals
      try {
        port.BaudRate = config.baudRate;
        port.setFlowControlSignal(SETDTR);
        port.setFlowControlSignal(SETRTS);
      } catch (_) {
        // Continue if optional signal assertion is unsupported by host controller
      }

      _serialPort = port;
      _updateState(ArduinoConnectionState.connected);
      return true;
    } catch (e) {
      _updateState(ArduinoConnectionState.error);
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    await stopReading();
    try {
      if (_serialPort != null && _serialPort!.isOpened) {
        _serialPort!.close();
      }
    } catch (_) {}
    _serialPort = null;
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

    _startAsyncReadLoop();
  }

  @override
  Future<void> stopReading() async {
    _isReading = false;
    _readTimer?.cancel();
    _readTimer = null;
    _lineBuffer.clear();
  }

  @override
  Future<bool> sendCommand(String command) async {
    if (_serialPort == null || !_serialPort!.isOpened) {
      return false;
    }
    try {
      final bytes = utf8.encode(command);
      _serialPort!.writeBytesFromUint8List(Uint8List.fromList(bytes));
      return true;
    } catch (_) {
      return false;
    }
  }

  void _startAsyncReadLoop() {
    _readTimer?.cancel();
    _readTimer = Timer.periodic(config.readInterval, (_) async {
      if (!_isReading || _serialPort == null) return;

      try {
        if (!_serialPort!.isOpened) {
          _updateState(ArduinoConnectionState.disconnected);
          stopReading();
          return;
        }

        final bytes = await _serialPort!.readBytes(
          256,
          timeout: const Duration(milliseconds: 80),
        );

        if (bytes.isNotEmpty) {
          final text = utf8.decode(bytes, allowMalformed: true);
          _processIncomingChunk(text);
        }
      } catch (e) {
        _updateState(ArduinoConnectionState.error);
        stopReading();
      }
    });
  }

  void _processIncomingChunk(String chunk) {
    _lineBuffer.write(chunk);
    final content = _lineBuffer.toString();
    if (content.contains('\n') || content.contains('\r')) {
      final lines = content.split(RegExp(r'\r\n|\n|\r'));
      for (int i = 0; i < lines.length - 1; i++) {
        final line = lines[i].trim();
        if (line.isNotEmpty && !_rawDataController.isClosed) {
          _rawDataController.add(line);
        }
      }
      _lineBuffer.clear();
      final lastFragment = lines.last;
      if (lastFragment.isNotEmpty) {
        _lineBuffer.write(lastFragment);
      }
    }
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

import 'dart:async';
import 'arduino_adapter.dart';

/// Mock Arduino adapter used strictly for automated tests and developer simulation fixtures.
/// Completely decoupled from the real hardware adapter.
class MockArduinoAdapter implements ArduinoAdapter {
  final _connectionStateController = StreamController<ArduinoConnectionState>.broadcast();
  final _rawDataController = StreamController<String>.broadcast();

  ArduinoConnectionState _connectionState = ArduinoConnectionState.disconnected;
  bool autoConnectOnStart;
  final List<String> sentCommands = [];
  bool failNextCommand = false;

  MockArduinoAdapter({this.autoConnectOnStart = false});

  @override
  ArduinoConnectionState get connectionState => _connectionState;

  @override
  Stream<ArduinoConnectionState> get connectionStateStream => _connectionStateController.stream;

  @override
  Stream<String> get rawDataStream => _rawDataController.stream;

  @override
  Future<bool> connect() async {
    _updateState(ArduinoConnectionState.connecting);
    await Future.delayed(const Duration(milliseconds: 50));
    _updateState(ArduinoConnectionState.connected);
    return true;
  }

  @override
  Future<void> disconnect() async {
    _updateState(ArduinoConnectionState.disconnected);
  }

  @override
  Future<void> startReading() async {
    if (autoConnectOnStart && _connectionState != ArduinoConnectionState.connected) {
      await connect();
    }
  }

  @override
  Future<void> stopReading() async {}

  @override
  Future<bool> sendCommand(String command) async {
    if (failNextCommand) {
      failNextCommand = false;
      return false;
    }
    sentCommands.add(command);
    return true;
  }

  /// Test helper: Emits an incoming serial message string into the telemetry stream.
  void emitRawLine(String line) {
    if (!_rawDataController.isClosed) {
      _rawDataController.add(line);
    }
  }

  /// Test helper: Emits a standard normal vitals packet.
  void emitNormalVitals() {
    emitRawLine('HR:74,SPO2:98,TEMP:36.8');
  }

  /// Test helper: Emits an abnormal vitals packet (e.g. high HR, low SpO2, high Temp).
  void emitAbnormalVitals() {
    emitRawLine('HR:125,SPO2:89,TEMP:38.9');
  }

  void _updateState(ArduinoConnectionState state) {
    _connectionState = state;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(state);
    }
  }

  @override
  void dispose() {
    _connectionStateController.close();
    _rawDataController.close();
  }
}

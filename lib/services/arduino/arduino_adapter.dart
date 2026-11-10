import 'dart:async';

export 'real_arduino_adapter_io.dart'
    if (dart.library.js_interop) 'real_arduino_adapter_web.dart'
    if (dart.library.html) 'real_arduino_adapter_web.dart';

/// Physical connection states for the Arduino sensor hardware.
enum ArduinoConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

/// Abstract hardware adapter for Arduino USB/Serial communication.
abstract class ArduinoAdapter {
  ArduinoConnectionState get connectionState;
  Stream<ArduinoConnectionState> get connectionStateStream;
  Stream<String> get rawDataStream;

  Future<bool> connect();
  Future<void> disconnect();
  Future<void> startReading();
  Future<void> stopReading();
  Future<bool> sendCommand(String command);
  void dispose();
}

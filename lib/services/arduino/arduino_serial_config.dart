/// Configuration parameters for Arduino USB serial communication on Windows.
class ArduinoSerialConfig {
  /// The physical COM port name (e.g. 'COM7').
  final String port;

  /// Serial communication baud rate (default 9600 for standard Arduino UNO sketches).
  final int baudRate;

  /// Maximum duration to wait when establishing a hardware connection.
  final Duration connectionTimeout;

  /// Duration after which absence of new telemetry is flagged as stale data.
  final Duration staleDataTimeout;

  /// Frequency at which incoming bytes are read from the serial port buffer.
  final Duration readInterval;

  const ArduinoSerialConfig({
    this.port = 'COM7',
    this.baudRate = 9600,
    this.connectionTimeout = const Duration(seconds: 3),
    this.staleDataTimeout = const Duration(seconds: 10),
    this.readInterval = const Duration(milliseconds: 100),
  });

  ArduinoSerialConfig copyWith({
    String? port,
    int? baudRate,
    Duration? connectionTimeout,
    Duration? staleDataTimeout,
    Duration? readInterval,
  }) {
    return ArduinoSerialConfig(
      port: port ?? this.port,
      baudRate: baudRate ?? this.baudRate,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      staleDataTimeout: staleDataTimeout ?? this.staleDataTimeout,
      readInterval: readInterval ?? this.readInterval,
    );
  }

  @override
  String toString() => 'ArduinoSerialConfig(port: $port, baudRate: $baudRate)';
}

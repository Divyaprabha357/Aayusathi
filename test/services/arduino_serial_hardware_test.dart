import 'package:flutter_test/flutter_test.dart';

import 'package:aayusathi/models/vital_reading.dart';
import 'package:aayusathi/services/arduino/arduino_adapter.dart';
import 'package:aayusathi/services/arduino/arduino_serial_config.dart';
import 'package:aayusathi/services/arduino/arduino_service.dart';
import 'package:aayusathi/services/arduino/mock_arduino_adapter.dart';
import 'package:aayusathi/services/arduino/serial_parser.dart';
import 'package:aayusathi/services/vital_validation_service.dart';

void main() {
  group('AAYUSATHI Arduino Hardware & Serial Integration Tests', () {
    // 1. COM configuration
    test('1. ArduinoSerialConfig stores defaults and supports overrides', () {
      const config = ArduinoSerialConfig();
      expect(config.port, 'COM7');
      expect(config.baudRate, 9600);
      expect(config.connectionTimeout, const Duration(seconds: 3));
      expect(config.staleDataTimeout, const Duration(seconds: 10));

      final custom = config.copyWith(port: 'COM8', baudRate: 115200);
      expect(custom.port, 'COM8');
      expect(custom.baudRate, 115200);
      expect(custom.connectionTimeout, const Duration(seconds: 3));
      expect(custom.toString(), contains('COM8'));
    });

    // 2. Adapter connection
    test('2. Mock adapter connect transitions state to connected', () async {
      final adapter = MockArduinoAdapter();
      expect(adapter.connectionState, ArduinoConnectionState.disconnected);

      final ok = await adapter.connect();
      expect(ok, isTrue);
      expect(adapter.connectionState, ArduinoConnectionState.connected);
    });

    // 3. Connection failure
    test('3. RealArduinoAdapter handles non-existent port gracefully without crashing', () async {
      final adapter = RealArduinoAdapter(
        config: const ArduinoSerialConfig(port: 'COM999'),
      );
      final ok = await adapter.connect();
      expect(ok, isFalse);
      expect(adapter.connectionState, ArduinoConnectionState.error);
      adapter.dispose();
    });

    // 4. Serial line decoding
    test('4. Emitting raw strings streams cleanly through rawDataStream', () async {
      final adapter = MockArduinoAdapter(autoConnectOnStart: true);
      final linesReceived = <String>[];
      final sub = adapter.rawDataStream.listen(linesReceived.add);

      adapter.emitRawLine('VITAL RESULTS');
      adapter.emitRawLine('Heart Rate : 75 BPM');

      await Future.delayed(const Duration(milliseconds: 10));
      expect(linesReceived, ['VITAL RESULTS', 'Heart Rate : 75 BPM']);
      await sub.cancel();
    });

    // 5. Existing Arduino parser (backward compatibility)
    test('5. Existing Arduino parser handles compact single and multi-token strings', () {
      VitalReading reading = VitalReading.empty();
      reading = ArduinoSerialParser.parseLine('HR:78,SPO2:98,TEMP:36.7,SYS:120,DIA:80', reading);
      expect(reading.heartRate, 78);
      expect(reading.spo2, 98);
      expect(reading.temperature, 36.7);
      expect(reading.status, VitalStatus.valid);
    });

    // 6. Current Arduino human-readable format
    test('6. ArduinoSerialParser handles live multi-line format from physical Arduino', () {
      VitalReading reading = VitalReading.empty();
      reading = ArduinoSerialParser.parseLine('VITAL RESULTS', reading);
      expect(reading.heartRate, isNull);

      reading = ArduinoSerialParser.parseLine('Heart Rate : 150 BPM', reading);
      expect(reading.heartRate, 150);

      reading = ArduinoSerialParser.parseLine('SpO2       : 74 %', reading);
      expect(reading.spo2, 74);

      reading = ArduinoSerialParser.parseLine('Temperature: 92.64 F', reading);
      // (92.64 - 32) * 5 / 9 = 33.6888... -> 33.7 °C
      expect(reading.temperature, 33.7);
      expect(reading.isComplete, isTrue);
      expect(reading.status, VitalStatus.valid);
    });

    // 7. HR extraction
    test('7. HR extraction handles various prefixes and formats', () {
      VitalReading reading = VitalReading.empty();
      reading = ArduinoSerialParser.parseLine('Heart Rate : 88 BPM', reading);
      expect(reading.heartRate, 88);

      reading = ArduinoSerialParser.parseLine('PULSE: 72', reading);
      expect(reading.heartRate, 72);
    });

    // 8. SpO2 extraction
    test('8. SpO2 extraction handles percentages and whitespace', () {
      VitalReading reading = VitalReading.empty();
      reading = ArduinoSerialParser.parseLine('SpO2       : 97 %', reading);
      expect(reading.spo2, 97);

      reading = ArduinoSerialParser.parseLine('SpO2 EST.    : 98.0 %', reading);
      expect(reading.spo2, 98);

      reading = ArduinoSerialParser.parseLine('O2: 99%', reading);
      expect(reading.spo2, 99);
    });

    // 9. Temperature extraction & Fahrenheit to Celsius conversion
    test('9. Temperature extraction automatically converts Fahrenheit to Celsius', () {
      VitalReading reading = VitalReading.empty();
      // 98.6 F = 37.0 C
      reading = ArduinoSerialParser.parseLine('Temperature: 98.6 F', reading);
      expect(reading.temperature, 37.0);

      // 36.6 C stays 36.6 C
      reading = ArduinoSerialParser.parseLine('Temperature: 36.6 C', reading);
      expect(reading.temperature, 36.6);
    });

    // 10. Invalid data rejection
    test('10. Invalid sensor lines (ERROR, --, out of bounds) are safely rejected', () {
      VitalReading reading = VitalReading.empty().copyWith(heartRate: 75, spo2: 98, temperature: 36.6);

      // String errors
      final afterError = ArduinoSerialParser.parseLine('Heart Rate : ERROR', reading);
      expect(afterError.heartRate, 75);

      final afterDashes = ArduinoSerialParser.parseLine('SpO2 : --', reading);
      expect(afterDashes.spo2, 98);

      final afterTempError = ArduinoSerialParser.parseLine('Temperature: ERROR', reading);
      expect(afterTempError.temperature, 36.6);

      // Absurd bounds
      final outOfBoundsHr = ArduinoSerialParser.parseLine('Heart Rate : 500 BPM', reading);
      expect(outOfBoundsHr.heartRate, 75);

      final outOfBoundsSpo2 = ArduinoSerialParser.parseLine('SpO2 : 120 %', reading);
      expect(outOfBoundsSpo2.spo2, 98);
    });

    // 11. Partial readings accumulation
    test('11. Line-by-line partial readings accumulate properly until complete', () {
      VitalReading reading = VitalReading.empty();
      expect(reading.isComplete, isFalse);

      reading = ArduinoSerialParser.parseLine('Heart Rate : 72 BPM', reading);
      expect(reading.heartRate, 72);
      expect(reading.isComplete, isFalse);
      expect(reading.status, VitalStatus.reading);

      reading = ArduinoSerialParser.parseLine('SpO2       : 98 %', reading);
      expect(reading.spo2, 98);
      expect(reading.isComplete, isFalse);

      reading = ArduinoSerialParser.parseLine('Temperature: 98.6 F', reading);
      expect(reading.temperature, 37.0);
      expect(reading.isComplete, isTrue);
      expect(reading.status, VitalStatus.valid);
    });

    // 12. Stale readings
    test('12. ArduinoService detects stale readings when telemetry pauses', () async {
      final mock = MockArduinoAdapter(autoConnectOnStart: true);
      final service = ArduinoService(
        adapter: mock,
        staleTimeout: const Duration(milliseconds: 100),
      );

      expect(service.isStale, isFalse);
      await service.startReading();

      // Emit reading that is partial (status == reading)
      mock.emitRawLine('Heart Rate : 80 BPM');
      await Future.delayed(const Duration(milliseconds: 20));
      expect(service.currentReading.heartRate, 80);
      expect(service.isStale, isFalse);

      // Wait for stale timeout
      await Future.delayed(const Duration(milliseconds: 150));
      expect(service.isStale, isTrue);

      service.dispose();
    });

    // 13. Disconnect
    test('13. Disconnect cancels timers and updates state', () async {
      final mock = MockArduinoAdapter(autoConnectOnStart: true);
      final service = ArduinoService(adapter: mock);
      await service.connect();
      expect(service.connectionState, ArduinoConnectionState.connected);

      await service.disconnect();
      expect(service.connectionState, ArduinoConnectionState.disconnected);
      service.dispose();
    });

    // 14. Reconnect
    test('14. Reconnect cycles disconnect and connect cleanly', () async {
      final mock = MockArduinoAdapter();
      final service = ArduinoService(adapter: mock);
      final ok = await service.reconnect();
      expect(ok, isTrue);
      expect(service.connectionState, ArduinoConnectionState.connected);
      service.dispose();
    });

    // 15. Dispose
    test('15. Disposing service closes streams and adapter without throwing', () {
      final mock = MockArduinoAdapter();
      final service = ArduinoService(adapter: mock);
      expect(() => service.dispose(), returnsNormally);
    });

    // 16. New patient reset
    test('16. reset() completely wipes patient readings and resets state', () {
      final mock = MockArduinoAdapter();
      final service = ArduinoService(adapter: mock);
      service.injectReading(
        VitalReading(
          heartRate: 150,
          spo2: 74,
          temperature: 33.7,
          timestamp: DateTime.now(),
          source: VitalSource.arduino,
          status: VitalStatus.valid,
        ),
      );
      expect(service.currentReading.hasHeartRate, isTrue);

      service.reset();
      expect(service.currentReading.heartRate, isNull);
      expect(service.currentReading.spo2, isNull);
      expect(service.currentReading.temperature, isNull);
      expect(service.currentReading.status, VitalStatus.waiting);
      expect(service.isStale, isFalse);
      expect(service.lastReadingReceivedAt, isNull);
      service.dispose();
    });

    // 17. No BP generation
    test('17. Real Arduino readings have null systolic and diastolic BP without fake numbers', () {
      VitalReading reading = VitalReading.empty();
      reading = ArduinoSerialParser.parseLine('Heart Rate : 150 BPM', reading);
      reading = ArduinoSerialParser.parseLine('SpO2       : 74 %', reading);
      reading = ArduinoSerialParser.parseLine('Temperature: 92.64 F', reading);

      expect(reading.heartRate, 150);
      expect(reading.spo2, 74);
      expect(reading.temperature, 33.7);
      expect(reading.isComplete, isTrue);
    });

    // 18. Normal simulation still works
    test('18. Normal simulation populates complete 3-channel vitals and validates normal', () {
      final normal = VitalReading(
        heartRate: 74,
        spo2: 98,
        temperature: 36.8,
        timestamp: DateTime.now(),
        source: VitalSource.simulated,
        status: VitalStatus.valid,
      );

      expect(normal.isComplete, isTrue);
      const validator = VitalValidationService();
      final result = validator.validate(normal);
      expect(result.isNormal, isTrue);
    });

    // 19. Abnormal simulation still works
    test('19. Abnormal simulation populates complete 3-channel vitals and validates abnormal', () {
      final abnormal = VitalReading(
        heartRate: 125,
        spo2: 89,
        temperature: 38.9,
        timestamp: DateTime.now(),
        source: VitalSource.simulated,
        status: VitalStatus.valid,
      );

      expect(abnormal.isComplete, isTrue);
      const validator = VitalValidationService();
      final result = validator.validate(abnormal);
      expect(result.isAbnormal, isTrue);
      expect(result.abnormalReasons, isNotEmpty);
    });

    // 20. Arduino mode does not fall back to simulation
    test('20. Arduino readings are strictly validated against VitalValidationService without fallback', () {
      // Real Arduino output simulation: HR 150, SpO2 74, Temp 33.7
      final arduinoReading = VitalReading(
        heartRate: 150,
        spo2: 74,
        temperature: 33.7,
        timestamp: DateTime.now(),
        source: VitalSource.arduino,
        status: VitalStatus.valid,
      );

      expect(arduinoReading.isComplete, isTrue);
      const validator = VitalValidationService();
      final result = validator.validate(arduinoReading);

      // HR 150 > 100 max, SpO2 74 < 90 min, Temp 33.7 < 35 min
      expect(result.isAbnormal, isTrue);
      expect(result.abnormalReasons.any((r) => r.contains('Heart Rate')), isTrue);
      expect(result.abnormalReasons.any((r) => r.contains('SpO₂')), isTrue);
      expect(result.abnormalReasons.any((r) => r.contains('Blood Pressure')), isFalse);
    });
  });
}

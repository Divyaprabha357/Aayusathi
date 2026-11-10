import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/core/localization/kiosk_strings.dart';
import 'package:aayusathi/core/routes/app_routes.dart';
import 'package:aayusathi/kiosk/models/patient_identity.dart';
import 'package:aayusathi/kiosk/screens/otp_success_screen.dart';
import 'package:aayusathi/kiosk/screens/sensor_instructions_screen.dart';
import 'package:aayusathi/kiosk/screens/vitals_screen.dart';
import 'package:aayusathi/kiosk/services/kiosk_service.dart';
import 'package:aayusathi/models/vital_reading.dart';
import 'package:aayusathi/services/arduino/arduino_service.dart';
import 'package:aayusathi/services/arduino/demo_reading_provider.dart';
import 'package:aayusathi/services/arduino/mock_arduino_adapter.dart';
import 'package:aayusathi/services/vital_validation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PatientIdentity testPatient;
  late MockArduinoAdapter mockAdapter;
  late ArduinoService testArduinoService;

  setUp(() {
    BackendProvider.instance.setMode(BackendMode.mock);
    mockAdapter = MockArduinoAdapter(autoConnectOnStart: true);
    testArduinoService = ArduinoService(
      adapter: mockAdapter,
      hardwareTimeout: const Duration(seconds: 15),
      staleTimeout: const Duration(milliseconds: 500),
    );
    KioskService.instance.setArduinoServiceForTesting(testArduinoService);

    KioskService.instance.startNewSession();
    DemoReadingProvider.instance.reset();
    DemoReadingProvider.instance.isDemoModeEnabled = true;

    testPatient = const PatientIdentity(
      aadhaarNumber: '123456789012',
      patientId: 'PAT-2026-TEST',
      fullName: 'Rameshwar Patil',
      dob: '1955-04-12',
      age: 71,
      gender: 'Male',
      phone: '9876543210',
      address: 'Pune, Maharashtra',
      bloodGroup: 'O+',
    );
  });

  tearDown(() {
    testArduinoService.dispose();
  });

  group('AAYUSATHI — Arduino-First Vitals, Instructions & Demo Fallback Tests', () {
    // 1. Instruction screen appears after verification
    testWidgets('1. The instruction screen appears after patient verification before vital collection', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: OtpSuccessScreen(patient: testPatient),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify OTP Success screen is visible with Continue button
      expect(find.text('CONTINUE'), findsOneWidget);

      // Tap Continue
      await tester.tap(find.text('CONTINUE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Sensor Instructions screen appears
      expect(find.byType(SensorInstructionsScreen), findsOneWidget);
      expect(find.text('Sensor Instructions'), findsOneWidget);
      expect(find.text('TAKE VITALS'), findsOneWidget);
    });

    // 2. TAKE VITALS on instruction screen navigates to vitals screen and sends exactly one command
    testWidgets('2. TAKE VITALS on instruction screen navigates to the existing vital screen and sends exactly one command', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      expect(mockAdapter.sentCommands, isEmpty);

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: SensorInstructionsScreen(patient: testPatient),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Find and tap the large TAKE VITALS button
      final takeVitalsButton = find.text('TAKE VITALS');
      expect(takeVitalsButton, findsOneWidget);

      await tester.tap(takeVitalsButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify navigated to VitalsScreen
      expect(find.byType(VitalsScreen), findsOneWidget);

      // Verify instruction-screen button sent START command exactly once
      expect(mockAdapter.sentCommands.where((cmd) => cmd == 'START\n').length, 1);

      // Verify VitalsScreen in Arduino mode contains NO duplicate TAKE VITALS button
      expect(find.widgetWithText(VitalsScreen, 'TAKE VITALS'), findsNothing);

      // Verify progress indicator is displayed with "Collecting measurements…"
      expect(find.text('Collecting measurements…'), findsWidgets);
    });

    // 3. Arduino Hardware is selected by default
    testWidgets('3. Arduino Hardware is selected by default on the vital collection screen and shows no duplicate TAKE VITALS button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      await tester.pumpWidget(
        MaterialApp(
          home: VitalsScreen(patient: testPatient),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Check status indicator displays ARDUINO HARDWARE by default
      expect(find.text('ARDUINO HARDWARE'), findsWidgets);

      // Check no duplicate TAKE VITALS button
      expect(find.text('TAKE VITALS'), findsNothing);
      expect(find.text('Collecting measurements…'), findsOneWidget);
    });

    // 4. Both existing simulation options still work
    testWidgets('4. Both existing simulation options (Normal & Abnormal) function exactly as before', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      await tester.pumpWidget(
        MaterialApp(
          home: VitalsScreen(patient: testPatient),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Simulate Normal in the fixture toolbar
      await tester.tap(find.text('Simulate Normal'));
      await tester.pumpAndSettle();

      expect(find.text('SIMULATED NORMAL'), findsWidgets);
      expect(find.text('74'), findsOneWidget); // Normal HR
      expect(find.text('98'), findsOneWidget); // Normal SpO2
      expect(find.text('36.8'), findsOneWidget); // Normal Temp

      // Tap Simulate Abnormal in the fixture toolbar
      await tester.tap(find.text('Simulate Abnormal'));
      await tester.pumpAndSettle();

      expect(find.text('SIMULATED ABNORMAL'), findsWidgets);
      expect(find.text('125'), findsOneWidget); // Abnormal HR
      expect(find.text('89'), findsOneWidget); // Abnormal SpO2
      expect(find.text('38.9'), findsOneWidget); // Abnormal Temp
    });

    // 5. Pressing button sends correct serial command
    test('5. Pressing trigger sends START command to the Arduino hardware', () async {
      await testArduinoService.connect();
      expect(mockAdapter.sentCommands, isEmpty);

      final triggered = await testArduinoService.triggerHardwareMeasurement();
      expect(triggered, isTrue);
      expect(mockAdapter.sentCommands, contains('START\n'));
      expect(testArduinoService.lastCommandSentSuccessfully, isTrue);
    });

    // 6. Valid hardware readings cancel timeout
    test('6. Valid hardware readings cancel the timeout and are marked source ARDUINO', () async {
      await testArduinoService.connect();
      final triggerFuture = testArduinoService.triggerHardwareMeasurement(
        timeout: const Duration(seconds: 15),
      );
      expect(await triggerFuture, isTrue);
      expect(testArduinoService.isHardwareMeasuring, isTrue);

      // Hardware responds with valid vitals before timeout
      mockAdapter.emitRawLine('Heart Rate : 76 BPM');
      mockAdapter.emitRawLine('SpO2       : 98 %');
      mockAdapter.emitRawLine('Temperature: 36.6 C');

      await Future.delayed(const Duration(milliseconds: 50));

      // Timeout cancelled and measuring completed cleanly
      expect(testArduinoService.isHardwareMeasuring, isFalse);
      expect(testArduinoService.isHardwareFallback, isFalse);
      expect(testArduinoService.currentReading.isComplete, isTrue);
      expect(testArduinoService.currentReading.source, VitalSource.arduino);
      expect(testArduinoService.currentReading.heartRate, 76);
      expect(testArduinoService.currentReading.spo2, 98);
      expect(testArduinoService.currentReading.temperature, 36.6);
    });

    // 7. No valid response within timeout triggers demo fallback
    test('7. No response within timeout triggers deterministic demo fallback', () async {
      await testArduinoService.connect();
      // Start measurement with 50ms test timeout
      await testArduinoService.triggerHardwareMeasurement(
        timeout: const Duration(milliseconds: 50),
      );
      expect(testArduinoService.isHardwareMeasuring, isTrue);

      // Wait for timeout to fire without emitting any sensor data
      await Future.delayed(const Duration(milliseconds: 100));

      expect(testArduinoService.isHardwareMeasuring, isFalse);
      expect(testArduinoService.isHardwareFallback, isTrue);
      expect(testArduinoService.currentReading.isComplete, isTrue);
      expect(testArduinoService.currentReading.source, VitalSource.simulated);
      expect(testArduinoService.currentReading.errorMessage, 'SIMULATED — HARDWARE TIMEOUT');
    });

    // 8. Consecutive attempt 1 & 2 return identical values
    test('8. Consecutive fallback attempts 1 and 2 return exact identical values', () {
      final provider = DemoReadingProvider();
      provider.reset();

      final attempt1 = provider.getNextFallbackReading();
      final attempt2 = provider.getNextFallbackReading();

      expect(attempt1.heartRate, attempt2.heartRate);
      expect(attempt1.spo2, attempt2.spo2);
      expect(attempt1.temperature, attempt2.temperature);
      expect(attempt1.heartRate, 74);
      expect(attempt1.spo2, 98);
      expect(attempt1.temperature, 36.6);
    });

    // 9. Third fallback attempt returns a different plausible set
    test('9. Third fallback attempt returns a different plausible set', () {
      final provider = DemoReadingProvider();
      provider.reset();

      final attempt1 = provider.getNextFallbackReading();
      final attempt2 = provider.getNextFallbackReading();
      final attempt3 = provider.getNextFallbackReading();

      expect(attempt1.heartRate, attempt2.heartRate);
      expect(attempt3.heartRate, isNot(equals(attempt1.heartRate)));
      expect(attempt3.heartRate, 78);
      expect(attempt3.spo2, 97);
      expect(attempt3.temperature, 36.8);
    });

    // 10. Fallback values are always marked simulated
    test('10. Fallback values are always marked as simulated with timeout label', () {
      final provider = DemoReadingProvider();
      provider.reset();

      for (int i = 1; i <= 5; i++) {
        final reading = provider.getNextFallbackReading();
        expect(reading.source, VitalSource.simulated);
        expect(reading.errorMessage, 'SIMULATED — HARDWARE TIMEOUT');
      }
    });

    // 11. Late serial messages cannot overwrite completed fallback results
    test('11. Late serial responses cannot overwrite completed fallback results', () async {
      await testArduinoService.connect();
      // Fast timeout to establish fallback
      await testArduinoService.triggerHardwareMeasurement(
        timeout: const Duration(milliseconds: 30),
      );
      await Future.delayed(const Duration(milliseconds: 60));

      expect(testArduinoService.isHardwareFallback, isTrue);
      final fallbackReading = testArduinoService.currentReading;
      expect(fallbackReading.heartRate, 74);

      // Late message arrives from Arduino after timeout
      mockAdapter.emitRawLine('Heart Rate : 140 BPM');
      mockAdapter.emitRawLine('SpO2       : 82 %');
      mockAdapter.emitRawLine('Temperature: 39.5 C');
      await Future.delayed(const Duration(milliseconds: 20));

      // Reading must remain the fallback reading, NOT overwritten by late serial
      expect(testArduinoService.currentReading.heartRate, 74);
      expect(testArduinoService.currentReading.spo2, 98);
      expect(testArduinoService.currentReading.temperature, 36.6);
      expect(testArduinoService.isHardwareFallback, isTrue);
    });

    // 12. BP does not appear anywhere in hardware measurement UI
    testWidgets('12. Blood pressure does not appear anywhere in the hardware measurement UI', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      await tester.pumpWidget(
        MaterialApp(
          home: VitalsScreen(patient: testPatient),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Blood Pressure'), findsNothing);
      expect(find.text('BP'), findsNothing);
      expect(find.text('SYS'), findsNothing);
      expect(find.text('DIA'), findsNothing);
      expect(find.textContaining('mmHg'), findsNothing);

      // Verify the 3 supported channels are present
      expect(find.text('Blood Oxygen (SpO₂)'), findsOneWidget);
      expect(find.text('Heart Rate'), findsOneWidget);
      expect(find.text('Body Temperature'), findsOneWidget);
    });

    // 13. English, Hindi, and Marathi instructions display correctly
    test('13. English, Hindi, and Marathi instructions display correct localized copy', () {
      const en = KioskStrings(KioskLocale.english);
      const hi = KioskStrings(KioskLocale.hindi);
      const mr = KioskStrings(KioskLocale.marathi);

      // Step 1
      expect(en.step1Instruction, contains('Place your finger gently inside the designated sensor'));
      expect(hi.step1Instruction, contains('अपनी उंगली'));
      expect(mr.step1Instruction, contains('आपले बोट'));

      // Step 2
      expect(en.step2Instruction, contains('Remove the temperature sensor carefully'));
      expect(en.step2Instruction, contains('elbow'));
      expect(hi.step2Instruction, contains('कोहनी'));
      expect(mr.step2Instruction, contains('कोपरा'));

      // Step 3
      expect(en.step3Instruction, contains('When you are ready, press TAKE VITALS'));
      expect(hi.step3Instruction, contains('TAKE VITALS'));
      expect(mr.step3Instruction, contains('TAKE VITALS'));

      // Fallback message
      expect(en.hardwareTimeoutMessage, 'Hardware readings unavailable. Demo values are being displayed.');
      expect(hi.hardwareTimeoutMessage, contains('हार्डवेयर'));
      expect(mr.hardwareTimeoutMessage, contains('हार्डवेअर'));
    });

    // 14. Existing validation, queue, and clinical routing workflow remain intact
    test('14. Established clinical routing (normal to domain, abnormal to IPD) remains intact', () {
      const validator = VitalValidationService();

      // Normal vital reading routes to normal
      final normalReading = VitalReading(
        heartRate: 74,
        spo2: 98,
        temperature: 36.6,
        timestamp: DateTime.now(),
        source: VitalSource.arduino,
        status: VitalStatus.valid,
      );
      final normalResult = validator.validate(normalReading);
      expect(normalResult.isNormal, isTrue);

      // Abnormal vital reading routes to IPD
      final abnormalReading = VitalReading(
        heartRate: 145,
        spo2: 86,
        temperature: 39.4,
        timestamp: DateTime.now(),
        source: VitalSource.arduino,
        status: VitalStatus.valid,
      );
      final abnormalResult = validator.validate(abnormalReading);
      expect(abnormalResult.isAbnormal, isTrue);
      expect(abnormalResult.abnormalReasons, isNotEmpty);
    });

    // 15. RETAKE VITALS initiates a new session safely without duplicate concurrent sessions
    testWidgets('15. RETAKE VITALS initiates a new session safely without duplicate concurrent sessions', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      // Inject complete reading so VALIDATE and RETAKE buttons appear
      testArduinoService.injectReading(
        VitalReading(
          heartRate: 74,
          spo2: 98,
          temperature: 36.6,
          timestamp: DateTime.now(),
          source: VitalSource.arduino,
          status: VitalStatus.valid,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: VitalsScreen(patient: testPatient),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Check VALIDATE VITALS and RETAKE VITALS buttons appear
      expect(find.text('VALIDATE VITALS'), findsOneWidget);
      expect(find.text('RETAKE VITALS'), findsOneWidget);

      final initialCommandCount = mockAdapter.sentCommands.length;

      // Tap RETAKE VITALS
      await tester.tap(find.text('RETAKE VITALS'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Exactly 1 new START command was sent
      expect(mockAdapter.sentCommands.length, initialCommandCount + 1);
      expect(mockAdapter.sentCommands.last, 'START\n');
      expect(testArduinoService.isHardwareMeasuring, isTrue);

      // Verify that while measuring, another trigger request is rejected
      final duplicateTrigger = await testArduinoService.triggerHardwareMeasurement();
      expect(duplicateTrigger, isFalse);
      expect(mockAdapter.sentCommands.length, initialCommandCount + 1);
    });

    // 16. Kiosk session reset clears vital readings and prevents leakage into next session
    test('16. Kiosk session reset clears vital readings and prevents leakage into next session', () {
      testArduinoService.injectReading(
        VitalReading(
          heartRate: 110,
          spo2: 91,
          temperature: 38.5,
          timestamp: DateTime.now(),
          source: VitalSource.arduino,
          status: VitalStatus.valid,
        ),
      );
      expect(testArduinoService.currentReading.isComplete, isTrue);

      // Reset kiosk session
      KioskService.instance.resetSession();

      expect(testArduinoService.currentReading.isComplete, isFalse);
      expect(testArduinoService.currentReading.hasHeartRate, isFalse);
      expect(testArduinoService.currentReading.hasSpo2, isFalse);
      expect(testArduinoService.currentReading.hasTemperature, isFalse);
      expect(testArduinoService.isHardwareMeasuring, isFalse);
      expect(testArduinoService.isHardwareFallback, isFalse);
    });

    // 17. Cleaned UI: Fallback removes yellow banner and card timeout label while preserving connection status and cards
    testWidgets('17. Cleaned UI: Fallback removes yellow warning banner and card timeout label while preserving connection status and vital cards', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      await tester.runAsync(() async {
        await testArduinoService.connect();
        // Fast timeout to trigger fallback
        await testArduinoService.triggerHardwareMeasurement(
          timeout: const Duration(milliseconds: 30),
        );
        await Future.delayed(const Duration(milliseconds: 60));
      });

      expect(testArduinoService.isHardwareFallback, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: VitalsScreen(patient: testPatient),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Confirm yellow warning banner is GONE
      expect(find.text('Hardware readings unavailable. Demo values are being displayed.'), findsNothing);

      // 2. Confirm SIMULATED — HARDWARE TIMEOUT card label is GONE from all vital cards
      expect(find.text('SIMULATED — HARDWARE TIMEOUT'), findsNothing);

      // 3. Confirm 3 vital cards are visible with their fallback values
      expect(find.text('Blood Oxygen (SpO₂)'), findsOneWidget);
      expect(find.text('Heart Rate'), findsOneWidget);
      expect(find.text('Body Temperature'), findsOneWidget);
      expect(find.text('98'), findsOneWidget);
      expect(find.text('74'), findsOneWidget);
      expect(find.text('36.6'), findsOneWidget);

      // 4. Confirm Arduino connection status banner is preserved
      expect(find.textContaining('Arduino Connected'), findsOneWidget);

      // 5. Confirm Patient Information & OTP status are preserved
      expect(find.text('Rameshwar Patil'), findsOneWidget);
      expect(find.text('OTP VERIFIED'), findsOneWidget);

      // 6. Confirm VALIDATE and RETAKE actions are present
      expect(find.text('VALIDATE VITALS'), findsOneWidget);
      expect(find.text('RETAKE VITALS'), findsOneWidget);

      // 7. Verify internal data provenance remains intact
      expect(testArduinoService.currentReading.source, VitalSource.simulated);
      expect(testArduinoService.currentReading.errorMessage, 'SIMULATED — HARDWARE TIMEOUT');
    });
  });
}

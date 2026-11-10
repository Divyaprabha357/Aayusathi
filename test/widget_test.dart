import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/constants/app_constants.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/core/routes/app_routes.dart';
import 'package:aayusathi/kiosk/models/kiosk_session.dart';
import 'package:aayusathi/kiosk/screens/doctor_preference_screen.dart';
import 'package:aayusathi/kiosk/screens/domain_selection_screen.dart';
import 'package:aayusathi/kiosk/screens/existing_patient_confirmation_screen.dart';
import 'package:aayusathi/kiosk/screens/ipd_referral_screen.dart';
import 'package:aayusathi/kiosk/screens/mobile_number_input_screen.dart';
import 'package:aayusathi/kiosk/screens/otp_success_screen.dart';
import 'package:aayusathi/kiosk/screens/otp_verification_screen.dart';
import 'package:aayusathi/kiosk/screens/patient_details_confirmation_screen.dart';
import 'package:aayusathi/kiosk/screens/queue_confirmation_screen.dart';
import 'package:aayusathi/kiosk/screens/thank_you_screen.dart';
import 'package:aayusathi/kiosk/screens/vitals_screen.dart';
import 'package:aayusathi/kiosk/services/kiosk_service.dart';
import 'package:aayusathi/kiosk/services/aadhaar_service.dart';
import 'package:aayusathi/kiosk/services/mock_patient_repository.dart';
import 'package:aayusathi/kiosk/services/otp_service.dart';
import 'package:aayusathi/kiosk/services/patient_lookup_service.dart';
import 'package:aayusathi/kiosk/widgets/aayusathi_ambient_ecg.dart';
import 'package:aayusathi/kiosk/widgets/aayusathi_button.dart';
import 'package:aayusathi/kiosk/widgets/aayusathi_domain_card.dart';
import 'package:aayusathi/kiosk/widgets/aayusathi_heartbeat_logo.dart';
import 'package:aayusathi/kiosk/widgets/aayusathi_numeric_keypad.dart';
import 'package:aayusathi/kiosk/widgets/aayusathi_secondary_button.dart';
import 'package:aayusathi/kiosk/widgets/aayusathi_vital_card.dart';
import 'package:aayusathi/main.dart';
import 'package:aayusathi/models/appointment_request.dart';
import 'package:aayusathi/models/opd_domain.dart';
import 'package:aayusathi/models/previous_visit_record.dart';
import 'package:aayusathi/models/vital_reading.dart';
import 'package:aayusathi/services/appointment_service.dart';
import 'package:aayusathi/services/arduino/arduino_service.dart';
import 'package:aayusathi/services/arduino/mock_arduino_adapter.dart';
import 'package:aayusathi/services/arduino/serial_parser.dart';
import 'package:aayusathi/services/doctor_availability_service.dart';
import 'package:aayusathi/services/previous_visit_service.dart';
import 'package:aayusathi/services/vital_validation_service.dart';

void main() {
  setUp(() {
    KioskService.instance.resetSession();
    (KioskService.instance.aadhaarService as MockAadhaarService).simulateDelay = false;
    (KioskService.instance.patientLookupService as MockPatientLookupService).simulateDelay = false;
    (KioskService.instance.otpService as MockOtpService).simulateDelay = false;
    (KioskService.instance.otpService as MockOtpService).cooldownSeconds = 30;
    (KioskService.instance.appointmentService as MockAppointmentService).resetQueueCounter();
    (KioskService.instance.previousVisitService as MockPreviousVisitService).reset();
    (KioskService.instance.doctorAvailabilityService as MockDoctorAvailabilityService).reset();
  });

  group('AAYUSATHI Phase 6.5 + Phase 7: End-to-End Kiosk Flows', () {
    testWidgets('New User Flow: Standby -> Language (Marathi) -> New User -> Aadhaar -> Send OTP -> OTP -> Identity Confirmation -> Vitals (Normal) -> Domain Selection -> Reset',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Future<void> tapDigit(String d) async {
        await tester.tap(find.byKey(ValueKey('keypad_$d')));
        await tester.pump(const Duration(milliseconds: 30));
      }

      // 1. Boot Application to Standby Screen
      await tester.pumpWidget(const AayusathiApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text(AppConstants.appTagline), findsWidgets);
      expect(find.text('TOUCH ANYWHERE TO BEGIN'), findsOneWidget);

      final logoFinder = find.byType(AayusathiHeartbeatLogo);
      expect(logoFinder, findsOneWidget);
      final AayusathiHeartbeatLogo logoWidget = tester.widget(logoFinder);
      expect(logoWidget.isLightMode, isTrue);

      final ecgFinder = find.byType(AayusathiAmbientEcg);
      expect(ecgFinder, findsOneWidget);
      final AayusathiAmbientEcg ecgWidget = tester.widget(ecgFinder);
      expect(ecgWidget.isLightMode, isTrue);

      // 2. Standby -> Language Selection
      await tester.tap(find.text('TOUCH ANYWHERE TO BEGIN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // 3. Choose Marathi
      await tester.tap(find.text('मराठी'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('पुढे जा'), findsOneWidget);
      await tester.tap(find.text('पुढे जा'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // 4. Select New User
      expect(find.text('नवीन वापरकर्ता'), findsOneWidget);
      await tester.tap(find.text('नवीन वापरकर्ता'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // 5. Enter valid unregistered Aadhaar: "5555 6666 7777"
      for (int i = 0; i < 4; i++) {
        await tapDigit('5');
      }
      for (int i = 0; i < 4; i++) {
        await tapDigit('6');
      }
      for (int i = 0; i < 4; i++) {
        await tapDigit('7');
      }
      await tester.pump();
      expect(find.text('12 / 12'), findsOneWidget);

      // Tap Continue ('पुढे जा') to view verified Aadhaar data
      final continueToDetailsBtn = find.widgetWithText(AayusathiButton, 'पुढे जा');
      await tester.tap(continueToDetailsBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // 6. Identity Confirmation Screen (Read-Only Verified Aadhaar Data without phone)
      expect(find.byType(PatientDetailsConfirmationScreen), findsOneWidget);
      final patientName = KioskService.instance.temporaryAadhaarData!.fullName;
      expect(find.text(patientName), findsOneWidget);

      // Tap Continue ('पुढे जा') -> Navigates to Mobile Number Input Screen
      final continueToMobileBtn = find.widgetWithText(AayusathiButton, 'पुढे जा');
      await tester.tap(continueToMobileBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // 7. Mobile Number Input Screen
      expect(find.byType(MobileNumberInputScreen), findsOneWidget);

      // Enter 10-digit mobile number: 9876543210
      await tapDigit('9');
      await tapDigit('8');
      await tapDigit('7');
      await tapDigit('6');
      await tapDigit('5');
      await tapDigit('4');
      await tapDigit('3');
      await tapDigit('2');
      await tapDigit('1');
      await tapDigit('0');
      await tester.pump();

      // Tap Send OTP ('ओटीपी पाठवा')
      final sendOtpBtn = find.widgetWithText(AayusathiButton, 'ओटीपी पाठवा');
      await tester.tap(sendOtpBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // 8. OTP Verification Screen
      expect(find.byType(OtpVerificationScreen), findsOneWidget);
      expect(find.text('+91 ••••• •3210'), findsOneWidget);

      // Enter correct OTP: 123456 -> creates patient and navigates to Vitals
      await tapDigit('1');
      await tapDigit('2');
      await tapDigit('3');
      await tapDigit('4');
      await tapDigit('5');
      await tapDigit('6');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // 9. Vitals Collection Screen
      expect(find.byType(VitalsScreen), findsOneWidget);
      expect(find.text(patientName), findsOneWidget);
      expect(find.text('OTP VERIFIED'), findsOneWidget);

      // In absence of hardware, all vitals show waiting placeholders (3 vitals)
      expect(find.text('--'), findsNWidgets(3));
      expect(find.text('सेन्सरची प्रतीक्षा करत आहे...'), findsWidgets);

      // Inject simulated normal vitals
      KioskService.instance.arduinoService.injectReading(
        VitalReading(
          heartRate: 74,
          spo2: 98,
          temperature: 36.8,
          timestamp: DateTime.now(),
          status: VitalStatus.valid,
        ),
      );
      await tester.pump();

      expect(find.text('74'), findsOneWidget);
      expect(find.text('98'), findsOneWidget);
      expect(find.text('36.8'), findsOneWidget);
      expect(find.text('118 / 76'), findsNothing);

      // Tap "VALIDATE VITALS"
      final validateBtn = find.widgetWithText(AayusathiButton, 'वाइटल्स तपासा');
      await tester.tap(validateBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 11. Navigates to Domain Selection Screen (Phase 8)
      expect(find.byType(DomainSelectionScreen), findsOneWidget);
      expect(find.byType(AayusathiDomainCard), findsNWidgets(8));

      // Select Dermatology (where Aarav Sharma has no prior visits -> First visit path)
      final dermCard = find.text('त्वचारोगशास्त्र (Dermatology)');
      expect(dermCard, findsOneWidget);
      await tester.ensureVisible(dermCard);
      await tester.tap(dermCard);
      await tester.pump();

      // Tap "पुढे जा" (CONTINUE) -> Directly creates appointment request and routes to QueueConfirmationScreen
      final continueToQueueBtn = find.widgetWithText(AayusathiButton, 'पुढे जा');
      await tester.ensureVisible(continueToQueueBtn);
      await tester.tap(continueToQueueBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 12. Reaches Queue Confirmation Screen
      expect(find.byType(QueueConfirmationScreen), findsOneWidget);
      expect(find.text('A-00001'), findsOneWidget);
      expect(find.text('कृपया आपल्या पाळीची प्रतीक्षा करा.'), findsWidgets);
      expect(find.text('तुमची विनंती यशस्वीरित्या नोंदवली गेली आहे.'), findsOneWidget);

      // Verify privacy: NO doctor name, NO cabin number, NO doctor ID
      expect(find.textContaining('Dr.'), findsNothing);
      expect(find.textContaining('Cabin'), findsNothing);
      expect(find.textContaining('DOC-'), findsNothing);

      // 13. Tap "सत्र पूर्ण करा" (FINISH SESSION) -> Privacy reset to Standby in English
      final finishBtn = find.widgetWithText(AayusathiButton, 'सत्र पूर्ण करा');
      await tester.ensureVisible(finishBtn);
      await tester.tap(finishBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('TOUCH ANYWHERE TO BEGIN'), findsOneWidget);
      expect(KioskService.instance.identifiedPatient, isNull);
      expect(KioskService.instance.userType, isNull);
      expect(KioskService.instance.isOtpVerified, isFalse);
      expect(KioskService.instance.currentVitalReading, isNull);
      expect(KioskService.instance.selectedDomain, isNull);
      expect(KioskService.instance.currentAppointmentRequest, isNull);
      expect(KioskService.instance.activeLocale, KioskLocale.english);
    });

    testWidgets('Existing Patient Flow: Hindi Selection -> Existing Patient -> Patient ID -> OTP -> Vitals (Abnormal) -> IPD Referral -> Reset',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Future<void> tapDigit(String d) async {
        await tester.tap(find.byKey(ValueKey('keypad_$d')));
        await tester.pump(const Duration(milliseconds: 30));
      }

      await tester.pumpWidget(const AayusathiApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Standby -> Language (Hindi)
      await tester.tap(find.text('TOUCH ANYWHERE TO BEGIN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('हिन्दी'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text('आगे बढ़ें'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Existing Patient
      await tester.tap(find.text('मौजूदा मरीज'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Enter Patient ID: 482910 (Priya Patil)
      await tapDigit('4');
      await tapDigit('8');
      await tapDigit('2');
      await tapDigit('9');
      await tapDigit('1');
      await tapDigit('0');
      await tester.pump();

      await tester.tap(find.widgetWithText(AayusathiButton, 'आगे बढ़ें'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Confirm Identity
      expect(find.byType(ExistingPatientConfirmationScreen), findsOneWidget);
      await tester.tap(find.widgetWithText(AayusathiButton, 'पहचान की पुष्टि करें'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // OTP Screen in Hindi
      expect(find.byType(OtpVerificationScreen), findsOneWidget);
      expect(find.text('+91 ••••• •5678'), findsOneWidget);

      // Enter 123456
      await tapDigit('1');
      await tapDigit('2');
      await tapDigit('3');
      await tapDigit('4');
      await tapDigit('5');
      await tapDigit('6');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // OTP Success -> Continue to Vitals
      expect(find.byType(OtpSuccessScreen), findsOneWidget);
      await tester.tap(find.widgetWithText(AayusathiButton, 'आगे बढ़ें'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Vitals Screen in Hindi
      expect(find.byType(VitalsScreen), findsOneWidget);

      // Inject Abnormal Vitals (High HR: 125, Low SpO2: 89, High Temp: 38.9)
      KioskService.instance.arduinoService.injectReading(
        VitalReading(
          heartRate: 125,
          spo2: 89,
          temperature: 38.9,
          timestamp: DateTime.now(),
          status: VitalStatus.valid,
        ),
      );
      await tester.pump();

      // Tap "VALIDATE VITALS"
      await tester.tap(find.widgetWithText(AayusathiButton, 'वाइटल्स सत्यापित करें'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Should route to IPD Referral Screen
      expect(find.byType(IpdReferralScreen), findsOneWidget);
      expect(find.text('कृपया आईपीडी विभाग में संपर्क करें।'), findsWidgets);
      expect(find.textContaining('Priya Patil'), findsOneWidget);

      // Reset to Standby via FINISH SESSION
      final finishBtn = find.widgetWithText(AayusathiButton, 'सत्र समाप्त करें');
      await tester.ensureVisible(finishBtn);
      await tester.pump();
      await tester.tap(finishBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('TOUCH ANYWHERE TO BEGIN'), findsOneWidget);
      expect(KioskService.instance.identifiedPatient, isNull);
      expect(KioskService.instance.activeLocale, KioskLocale.english);
    });
  });

  group('AAYUSATHI Phase 6.5: Hardened OTP Unit & Widget Tests', () {
    test('Valid OTP succeeds and invalid OTP fails', () async {
      final service = MockOtpService(simulateDelay: false);

      final r1 = await service.verifyOtp('000000', phoneNumber: '+91 98765 43210');
      expect(r1.isSuccess, isFalse);
      expect(r1.attemptsRemaining, 2);

      final r2 = await service.verifyOtp('123456', phoneNumber: '+91 98765 43210');
      expect(r2.isSuccess, isTrue);
    });

    test('Third invalid attempt locks the flow and blocks further verification', () async {
      final service = MockOtpService(simulateDelay: false);

      await service.verifyOtp('111111', phoneNumber: '+91 98765 43210');
      await service.verifyOtp('222222', phoneNumber: '+91 98765 43210');
      final r3 = await service.verifyOtp('333333', phoneNumber: '+91 98765 43210');

      expect(r3.status, OtpStatus.tooManyAttempts);
      expect(service.isLockedOut, isTrue);

      // Even correct OTP is blocked when locked out
      final r4 = await service.verifyOtp('123456', phoneNumber: '+91 98765 43210');
      expect(r4.status, OtpStatus.tooManyAttempts);
    });

    test('Resend cooldown works and blocks resend during cooldown', () async {
      final service = MockOtpService(simulateDelay: false, cooldownSeconds: 30);

      expect(service.canResend, isTrue);
      await service.sendOtp('+91 98765 43210');

      expect(service.canResend, isFalse);
      expect(service.cooldownRemainingSeconds, inInclusiveRange(28, 30));

      final blocked = await service.resendOtp('+91 98765 43210');
      expect(blocked.status, OtpStatus.error);
    });

    test('OTP cannot be verified without a valid patient phone number', () async {
      final service = MockOtpService(simulateDelay: false);

      final r1 = await service.verifyOtp('123456', phoneNumber: '');
      expect(r1.status, OtpStatus.error);

      final r2 = await service.verifyOtp('123456', phoneNumber: null);
      expect(r2.status, OtpStatus.error);
    });

    test('Session reset clears OTP state, attempts, and vitals', () {
      final kiosk = KioskService.instance;
      kiosk.startNewSession();
      kiosk.setLocale(KioskLocale.marathi);
      kiosk.setOtpVerified(true);
      kiosk.setVitalReading(VitalReading(
        heartRate: 72,
        spo2: 99,
        timestamp: DateTime.now(),
      ));

      expect(kiosk.isOtpVerified, isTrue);
      expect(kiosk.currentVitalReading, isNotNull);

      kiosk.resetSession();

      expect(kiosk.isOtpVerified, isFalse);
      expect(kiosk.currentVitalReading, isNull);
      expect(kiosk.activeLocale, KioskLocale.english);
      expect(kiosk.otpService.isLockedOut, isFalse);
    });

    testWidgets('OTP screen displays invalid session card when accessed without patient',
        (WidgetTester tester) async {
      KioskService.instance.resetSession();

      final dummyPatient = MockPatientRepository.instance.findByAadhaar('111122223333')!;

      await tester.pumpWidget(
        MaterialApp(
          home: OtpVerificationScreen(patient: dummyPatient),
        ),
      );
      await tester.pump();

      expect(find.text('No active patient session found. Please begin check-in from Standby.'), findsOneWidget);
      expect(find.widgetWithText(AayusathiButton, 'START AGAIN'), findsOneWidget);
    });

    testWidgets('Third invalid OTP locks keypad and shows START AGAIN button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final patient = MockPatientRepository.instance.findByAadhaar('111122223333')!;
      KioskService.instance.setIdentifiedPatient(patient);

      Future<void> tapDigit(String d) async {
        await tester.tap(find.byKey(ValueKey('keypad_$d')));
        await tester.pump(const Duration(milliseconds: 30));
      }

      await tester.pumpWidget(
        MaterialApp(
          home: OtpVerificationScreen(patient: patient),
        ),
      );
      await tester.pump();

      // 3 failed attempts
      for (int attempt = 0; attempt < 3; attempt++) {
        for (int i = 0; i < 6; i++) {
          await tapDigit('0');
        }
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.textContaining('Too many incorrect attempts'), findsOneWidget);
      expect(find.widgetWithText(AayusathiButton, 'START AGAIN'), findsOneWidget);

      final keypad = tester.widget<AayusathiNumericKeypad>(find.byType(AayusathiNumericKeypad));
      expect(keypad.isEnabled, isFalse);
    });
  });

  group('AAYUSATHI Phase 7: Arduino Service, Parser & Vitals Validation Tests', () {
    test('ArduinoSerialParser correctly parses valid multi-token and single-token telemetry', () {
      var reading = VitalReading.empty();

      // Multi-token parsing
      reading = ArduinoSerialParser.parseLine('HR:78,SPO2:98,TEMP:36.7,SYS:120,DIA:80', reading);

      expect(reading.heartRate, 78);
      expect(reading.spo2, 98);
      expect(reading.temperature, 36.7);
      expect(reading.isComplete, isTrue);
      expect(reading.status, VitalStatus.valid);

      // Single token update
      reading = ArduinoSerialParser.parseLine('HR:82', reading);
      expect(reading.heartRate, 82);
      expect(reading.spo2, 98);
    });

    test('ArduinoSerialParser safely rejects corrupted, out-of-bounds, or garbage serial lines without throwing', () {
      var reading = VitalReading.empty();

      // Garbage string
      reading = ArduinoSerialParser.parseLine('RANDOM_CORRUPT_SERIAL_GARBAGE', reading);
      expect(reading.heartRate, isNull);

      // Malformed tokens
      reading = ArduinoSerialParser.parseLine('HR:abc,SPO2:,TEMP:xyz', reading);
      expect(reading.heartRate, isNull);
      expect(reading.spo2, isNull);

      // Out-of-bounds numbers (e.g. HR > 250, SpO2 > 100)
      reading = ArduinoSerialParser.parseLine('HR:999,SPO2:150,TEMP:85.0', reading);
      expect(reading.heartRate, isNull);
      expect(reading.spo2, isNull);
    });

    test('VitalValidationService correctly classifies healthy normal vitals', () {
      const validator = VitalValidationService();
      final reading = VitalReading(
        heartRate: 75,
        spo2: 98,
        temperature: 36.6,
        timestamp: DateTime.now(),
        status: VitalStatus.valid,
      );

      final result = validator.validate(reading);
      expect(result.isNormal, isTrue);
      expect(result.isAbnormal, isFalse);
      expect(result.abnormalReasons, isEmpty);
    });

    test('VitalValidationService correctly flags abnormal vitals (low SpO2, high temp, high HR)', () {
      const validator = VitalValidationService();
      final reading = VitalReading(
        heartRate: 125, // Above 100
        spo2: 91, // Below 95
        temperature: 38.9, // Above 37.5
        timestamp: DateTime.now(),
        status: VitalStatus.valid,
      );

      final result = validator.validate(reading);
      expect(result.isAbnormal, isTrue);
      expect(result.isNormal, isFalse);
      expect(result.abnormalReasons.length, 3);
    });

    test('VitalValidationService marks incomplete readings', () {
      const validator = VitalValidationService();
      final partialReading = VitalReading(
        heartRate: 75,
        spo2: 98,
        timestamp: DateTime.now(),
      );

      final result = validator.validate(partialReading);
      expect(result.isIncomplete, isTrue);
      expect(result.isNormal, isFalse);
    });

    test('MockArduinoAdapter emits telemetry properly to ArduinoService', () async {
      final mockAdapter = MockArduinoAdapter(autoConnectOnStart: true);
      final service = ArduinoService(adapter: mockAdapter);

      await service.startReading();
      mockAdapter.emitNormalVitals();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(service.currentReading.heartRate, 74);
      expect(service.currentReading.spo2, 98);
      expect(service.currentReading.isComplete, isTrue);

      service.dispose();
    });

    testWidgets('Responsive Viewport Check: 1600x900 and 1920x1080 for VitalsScreen without overflow',
        (WidgetTester tester) async {
      final patient = MockPatientRepository.instance.findByAadhaar('111122223333')!;

      for (final size in [const Size(1600, 900), const Size(1920, 1080)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: VitalsScreen(patient: patient),
          ),
        );
        await tester.pump();

        expect(find.byType(VitalsScreen), findsOneWidget);
        expect(find.byType(AayusathiVitalCard), findsNWidgets(3));
        expect(tester.takeException(), isNull);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('AAYUSATHI Phase 8: OPD Domain Selection, Doctor Preference & Queue Tests', () {
    testWidgets('All 8 clinical domains rendered with title and description',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final patient = MockPatientRepository.instance.findByAadhaar('111122223333')!;

      await tester.pumpWidget(
        MaterialApp(
          home: DomainSelectionScreen(patient: patient),
        ),
      );
      await tester.pump();

      expect(find.byType(AayusathiDomainCard), findsNWidgets(8));
      expect(find.text('Cardiology'), findsOneWidget);
      expect(find.text('Neurology'), findsOneWidget);
      expect(find.text('Gastroenterology'), findsOneWidget);
      expect(find.text('Orthopedics'), findsOneWidget);
      expect(find.text('Pediatrics'), findsOneWidget);
      expect(find.text('ENT'), findsOneWidget);
      expect(find.text('Dermatology'), findsOneWidget);
      expect(find.text('General Medicine'), findsOneWidget);

      // Verify simple patient-friendly descriptions without diagnostic claims
      expect(find.text('Heart and cardiovascular-related consultation'), findsOneWidget);
      expect(find.text('Brain, nerves and nervous-system related consultation'), findsOneWidget);
      expect(find.text('General health concerns and common medical conditions'), findsOneWidget);
    });

    testWidgets('Domain selection updates KioskService.instance.selectedDomain and enables Continue',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final patient = MockPatientRepository.instance.findByAadhaar('111122223333')!;

      await tester.pumpWidget(
        MaterialApp(
          home: DomainSelectionScreen(patient: patient),
        ),
      );
      await tester.pump();

      // Continue button should initially be disabled
      final continueBtn = find.widgetWithText(AayusathiButton, 'CONTINUE');
      expect(continueBtn, findsOneWidget);

      // Tap Cardiology card
      await tester.tap(find.text('Cardiology'));
      await tester.pump();

      expect(KioskService.instance.selectedDomain?.id, 'cardiology');
      expect(find.text('Selected Department: Cardiology'), findsOneWidget);
    });

    testWidgets('First-visit patient skips doctor preference and receives sequential queue ticket',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Aarav Sharma has no visits in Dermatology
      final patient = MockPatientRepository.instance.findByAadhaar('111122223333')!;

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: DomainSelectionScreen(patient: patient),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Dermatology'));
      await tester.pump();

      await tester.tap(find.widgetWithText(AayusathiButton, 'CONTINUE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Bypasses Doctor Preference and navigates directly to QueueConfirmationScreen
      expect(find.byType(DoctorPreferenceScreen), findsNothing);
      expect(find.byType(QueueConfirmationScreen), findsOneWidget);
      expect(find.text('A-00001'), findsOneWidget);
      expect(KioskService.instance.currentAppointmentRequest?.preferredDoctorMode,
          PreferredDoctorMode.anyDoctor);
    });

    testWidgets('Previous-visit patient with available doctor selects YES -> appointment created with same doctor',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Aarav Sharma has visited Cardiology with DOC-CARD-01 (who is available)
      final patient = MockPatientRepository.instance.findByAadhaar('111122223333')!;

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: DomainSelectionScreen(patient: patient),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Cardiology'));
      await tester.pump();

      await tester.tap(find.widgetWithText(AayusathiButton, 'CONTINUE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Reaches DoctorPreferenceScreen
      expect(find.byType(DoctorPreferenceScreen), findsOneWidget);
      expect(find.text('You have previously visited this department. Would you like to visit the same doctor?'),
          findsOneWidget);

      // Tap YES
      await tester.tap(find.widgetWithText(AayusathiButton, 'YES'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Reaches QueueConfirmationScreen with same doctor allocation
      expect(find.byType(QueueConfirmationScreen), findsOneWidget);
      expect(KioskService.instance.currentAppointmentRequest?.preferredDoctorMode,
          PreferredDoctorMode.sameDoctor);
      expect(KioskService.instance.currentAppointmentRequest?.previousDoctorId,
          'DOC-CARD-01');
      expect(KioskService.instance.currentAppointmentRequest?.assignedDoctorId,
          isNull);
    });

    testWidgets('Previous-visit patient with unavailable doctor selects YES -> sees prompt, chooses YES -> alternative doctor request created',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Aarav Sharma in Neurology has prior visit with DOC-NEUR-01 (unavailable)
      final patient = MockPatientRepository.instance.findByAadhaar('111122223333')!;
      final domain = OpdDomain.findById('neurology')!;
      final prevVisit = await KioskService.instance.previousVisitService
          .getPreviousVisit(patientId: patient.patientId, domainId: 'neurology');

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: DoctorPreferenceScreen(
            patient: patient,
            domain: domain,
            previousVisit: prevVisit,
          ),
        ),
      );
      await tester.pump();

      // Tap YES -> triggers check and reveals unavailable card
      await tester.tap(find.widgetWithText(AayusathiButton, 'YES'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Doctor Not Available'), findsOneWidget);
      expect(find.text('Doctor not available. Do you want to visit another doctor?'),
          findsOneWidget);

      // Patient taps YES to alternative doctor
      await tester.tap(find.widgetWithText(AayusathiButton, 'YES'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Navigates to QueueConfirmationScreen with alternative doctor
      expect(find.byType(QueueConfirmationScreen), findsOneWidget);
      expect(KioskService.instance.currentAppointmentRequest?.preferredDoctorMode,
          PreferredDoctorMode.alternativeDoctor);
      expect(KioskService.instance.currentAppointmentRequest?.assignedDoctorId,
          isNull);
    });

    testWidgets('Previous-visit patient with unavailable doctor selects YES -> chooses NO to alternative doctor -> full session reset',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final patient = MockPatientRepository.instance.findByAadhaar('111122223333')!;
      final domain = OpdDomain.findById('neurology')!;
      final prevVisit = await KioskService.instance.previousVisitService
          .getPreviousVisit(patientId: patient.patientId, domainId: 'neurology');

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: DoctorPreferenceScreen(
            patient: patient,
            domain: domain,
            previousVisit: prevVisit,
          ),
        ),
      );
      await tester.pump();

      // Tap YES -> reveals unavailable card
      await tester.tap(find.widgetWithText(AayusathiButton, 'YES'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Patient chooses NO to alternative doctor -> routes to ThankYouScreen
      await tester.tap(find.widgetWithText(AayusathiSecondaryButton, 'NO'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Dedicated Thank You Screen displayed
      expect(find.byType(ThankYouScreen), findsOneWidget);
      expect(find.text('Thank you, visit again.'), findsOneWidget);

      // Privacy: No queue number, doctor name, doctor ID, or cabin
      expect(find.textContaining('A-'), findsNothing);
      expect(find.textContaining('DOC-'), findsNothing);
      expect(find.textContaining('Cabin'), findsNothing);

      // Advance clock by 5 seconds to trigger ThankYou auto-reset
      await tester.pump(const Duration(seconds: 5));

      // Session completely wiped back to Standby in English
      expect(KioskService.instance.identifiedPatient, isNull);
      expect(KioskService.instance.userType, isNull);
      expect(KioskService.instance.selectedDomain, isNull);
      expect(KioskService.instance.currentAppointmentRequest, isNull);
      expect(KioskService.instance.activeLocale, KioskLocale.english);
    });

    testWidgets('Previous-visit patient selects NO to same doctor -> alternative eligible doctor request created',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final patient = MockPatientRepository.instance.findByAadhaar('111122223333')!;
      final domain = OpdDomain.findById('cardiology')!;
      final prevVisit = await KioskService.instance.previousVisitService
          .getPreviousVisit(patientId: patient.patientId, domainId: 'cardiology');

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: DoctorPreferenceScreen(
            patient: patient,
            domain: domain,
            previousVisit: prevVisit,
          ),
        ),
      );
      await tester.pump();

      // Tap NO -> directly creates request with alternative doctor
      await tester.tap(find.widgetWithText(AayusathiSecondaryButton, 'NO'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(QueueConfirmationScreen), findsOneWidget);
      expect(KioskService.instance.currentAppointmentRequest?.preferredDoctorMode,
          PreferredDoctorMode.alternativeDoctor);
    });

    testWidgets('All doctors busy creates pending appointment request and displays notice',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // In MockDoctorAvailabilityService, 'orthopedics' has all doctors busy
      final appt = await KioskService.instance.appointmentService.createAppointmentRequest(
        patientId: 'AAYU-102938',
        domainId: 'orthopedics',
        sessionId: 'SESS-123',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
      );

      expect(appt.status, AppointmentStatus.pending);
      expect(appt.assignedDoctorId, isNull);

      await tester.pumpWidget(
        MaterialApp(
          home: QueueConfirmationScreen(appointment: appt),
        ),
      );
      await tester.pump();

      // Displays pending notice
      expect(find.text('OPD consultation request pending. Please proceed to the department waiting area.'),
          findsOneWidget);
      expect(find.text(appt.queueNumber), findsOneWidget);
    });

    test('Sequential queue numbers are generated deterministically', () {
      final service = MockAppointmentService();
      service.resetQueueCounter();

      expect(service.generateNextQueueNumber(), 'A-00001');
      expect(service.generateNextQueueNumber(), 'A-00002');
      expect(service.generateNextQueueNumber(), 'A-00003');
    });

    testWidgets('Queue confirmation screen strictly enforces privacy (zero doctor name, cabin, ID)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final appt = AppointmentRequest(
        requestId: 'REQ-1',
        patientId: 'AAYU-102938',
        domainId: 'cardiology',
        assignedDoctorId: 'DOC-CARD-01',
        previousDoctorId: 'DOC-CARD-01',
        preferredDoctorMode: PreferredDoctorMode.sameDoctor,
        status: AppointmentStatus.waiting,
        queueNumber: 'A-00027',
        createdAt: DateTime(2026, 9, 4),
        sessionId: 'SESS-1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QueueConfirmationScreen(appointment: appt),
        ),
      );
      await tester.pump();

      expect(find.text('A-00027'), findsOneWidget);
      expect(find.text('Please wait for your turn.'), findsWidgets);
      expect(find.text('Your request has been successfully registered.'), findsOneWidget);

      // Strict privacy validation
      expect(find.textContaining('DOC-CARD-01'), findsNothing);
      expect(find.textContaining('Cabin'), findsNothing);
      expect(find.textContaining('Doctor Name'), findsNothing);
    });

    testWidgets('Auto-reset timer triggers full session wipe and returns to Standby',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final patient = MockPatientRepository.instance.findByAadhaar('111122223333')!;
      KioskService.instance.setIdentifiedPatient(patient);
      KioskService.instance.setSelectedDomain(OpdDomain.findById('cardiology')!);
      KioskService.instance.setLocale(KioskLocale.marathi);

      final appt = AppointmentRequest(
        requestId: 'REQ-1',
        patientId: 'AAYU-102938',
        domainId: 'cardiology',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.waiting,
        queueNumber: 'A-00005',
        createdAt: DateTime(2026, 9, 4),
        sessionId: 'SESS-1',
      );

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: QueueConfirmationScreen(
            appointment: appt,
            autoResetSeconds: 1,
          ),
        ),
      );
      await tester.pump();

      // Advance clock by 2 seconds to fire auto-reset timer
      await tester.pump(const Duration(seconds: 2));

      expect(KioskService.instance.identifiedPatient, isNull);
      expect(KioskService.instance.userType, isNull);
      expect(KioskService.instance.selectedDomain, isNull);
      expect(KioskService.instance.activeLocale, KioskLocale.english);
    });

    testWidgets('Hindi flow: Domain selection and queue screen localized in Hindi',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      KioskService.instance.setLocale(KioskLocale.hindi);
      final patient = MockPatientRepository.instance.findByAadhaar('111122223333')!;

      await tester.pumpWidget(
        MaterialApp(
          home: DomainSelectionScreen(patient: patient),
        ),
      );
      await tester.pump();

      expect(find.text('चिकित्सा विभाग चुनें'), findsOneWidget);
      expect(find.text('हृदय रोग (Cardiology)'), findsOneWidget);
      expect(find.text('सामान्य चिकित्सा (General Medicine)'), findsOneWidget);
    });

    testWidgets('Back button in DomainSelectionScreen pops safely without corrupting session',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final patient = MockPatientRepository.instance.findByAadhaar('111122223333')!;
      KioskService.instance.setIdentifiedPatient(patient);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: (context) {
              return ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DomainSelectionScreen(patient: patient)),
                ),
                child: const Text('GO'),
              );
            }),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('GO'));
      await tester.pumpAndSettle();

      expect(find.byType(DomainSelectionScreen), findsOneWidget);

      // Tap Back button
      await tester.tap(find.widgetWithText(AayusathiSecondaryButton, 'BACK'));
      await tester.pumpAndSettle();

      expect(find.byType(DomainSelectionScreen), findsNothing);
      expect(KioskService.instance.identifiedPatient, isNotNull);
    });

    testWidgets('Responsive Viewport Check: 1366x768, 1600x900, 1920x1080 without overflow',
        (WidgetTester tester) async {
      final patient = MockPatientRepository.instance.findByAadhaar('111122223333')!;

      for (final size in [
        const Size(1366, 768),
        const Size(1600, 900),
        const Size(1920, 1080)
      ]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: DomainSelectionScreen(patient: patient),
          ),
        );
        await tester.pump();

        expect(find.byType(DomainSelectionScreen), findsOneWidget);
        expect(find.byType(AayusathiDomainCard), findsNWidgets(8));
        expect(tester.takeException(), isNull);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('Phase 8 Final Correction: Previous Visit Logic + Doctor Availability + Queue Format', () {
    final patient = MockPatientRepository.instance.findByAadhaar('111122223333')!;

    // --- TESTS — NEW USER (1 to 8) ---

    testWidgets('1. New User + Cardiology -> directly appointment/queue', (tester) async {
      KioskService.instance.resetSession();
      KioskService.instance.setUserType(UserType.newUser);
      KioskService.instance.setIdentifiedPatient(patient);

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: DomainSelectionScreen(patient: patient),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Cardiology'));
      await tester.pump();
      await tester.tap(find.widgetWithText(AayusathiButton, 'CONTINUE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(DoctorPreferenceScreen), findsNothing);
      expect(find.byType(QueueConfirmationScreen), findsOneWidget);
      expect(find.text('A-00001'), findsOneWidget);
    });

    testWidgets('2. New User + Neurology -> directly appointment/queue', (tester) async {
      KioskService.instance.resetSession();
      KioskService.instance.setUserType(UserType.newUser);
      KioskService.instance.setIdentifiedPatient(patient);

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: DomainSelectionScreen(patient: patient),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Neurology'));
      await tester.pump();
      await tester.tap(find.widgetWithText(AayusathiButton, 'CONTINUE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(DoctorPreferenceScreen), findsNothing);
      expect(find.byType(QueueConfirmationScreen), findsOneWidget);
      expect(find.text('A-00001'), findsOneWidget);
    });

    testWidgets('3. New User + Orthopedics -> directly appointment/queue', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      KioskService.instance.resetSession();
      KioskService.instance.setUserType(UserType.newUser);
      KioskService.instance.setIdentifiedPatient(patient);

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: DomainSelectionScreen(patient: patient),
        ),
      );
      await tester.pump();

      final orthoCard = find.text('Orthopedics');
      await tester.ensureVisible(orthoCard);
      await tester.tap(orthoCard);
      await tester.pump();
      await tester.tap(find.widgetWithText(AayusathiButton, 'CONTINUE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(DoctorPreferenceScreen), findsNothing);
      expect(find.byType(QueueConfirmationScreen), findsOneWidget);
      expect(find.text('A-00001'), findsOneWidget);
    });

    testWidgets('4. New User + Dermatology -> directly appointment/queue', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      KioskService.instance.resetSession();
      KioskService.instance.setUserType(UserType.newUser);
      KioskService.instance.setIdentifiedPatient(patient);

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: DomainSelectionScreen(patient: patient),
        ),
      );
      await tester.pump();

      final dermCard = find.text('Dermatology');
      await tester.ensureVisible(dermCard);
      await tester.tap(dermCard);
      await tester.pump();
      await tester.tap(find.widgetWithText(AayusathiButton, 'CONTINUE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(DoctorPreferenceScreen), findsNothing);
      expect(find.byType(QueueConfirmationScreen), findsOneWidget);
      expect(find.text('A-00001'), findsOneWidget);
    });

    testWidgets('5. New User NEVER sees previous-visit question', (tester) async {
      KioskService.instance.resetSession();
      KioskService.instance.setUserType(UserType.newUser);
      KioskService.instance.setIdentifiedPatient(patient);

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: DomainSelectionScreen(patient: patient),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Cardiology'));
      await tester.pump();
      await tester.tap(find.widgetWithText(AayusathiButton, 'CONTINUE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('You have previously visited this department. Would you like to visit the same doctor?'),
          findsNothing);
      expect(find.text('Doctor Not Available'), findsNothing);
      expect(find.byType(DoctorPreferenceScreen), findsNothing);
    });

    testWidgets('6. New User NEVER calls PreviousVisitService', (tester) async {
      KioskService.instance.resetSession();
      (KioskService.instance.previousVisitService as MockPreviousVisitService).reset();
      KioskService.instance.setUserType(UserType.newUser);
      KioskService.instance.setIdentifiedPatient(patient);

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: DomainSelectionScreen(patient: patient),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Cardiology'));
      await tester.pump();
      await tester.tap(find.widgetWithText(AayusathiButton, 'CONTINUE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final prevService = KioskService.instance.previousVisitService as MockPreviousVisitService;
      expect(prevService.totalCallCount, 0);
      expect(prevService.hasPreviousVisitCallCount, 0);
      expect(prevService.getPreviousVisitCallCount, 0);
    });

    testWidgets('7. New User receives queue number matching A-XXXXX', (tester) async {
      KioskService.instance.resetSession();
      KioskService.instance.setUserType(UserType.newUser);
      KioskService.instance.setIdentifiedPatient(patient);

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: DomainSelectionScreen(patient: patient),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Cardiology'));
      await tester.pump();
      await tester.tap(find.widgetWithText(AayusathiButton, 'CONTINUE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final queueNumber = KioskService.instance.currentAppointmentRequest?.queueNumber;
      expect(queueNumber, isNotNull);
      expect(RegExp(r'^A-[0-9]{5}$').hasMatch(queueNumber!), isTrue);
      expect(find.text(queueNumber), findsOneWidget);
    });

    testWidgets('8. New User does not inherit previous-visit state from previous session', (tester) async {
      // First, simulate an existing patient session that populated previous visit
      KioskService.instance.resetSession();
      KioskService.instance.setUserType(UserType.existingPatient);
      KioskService.instance.setIdentifiedPatient(patient);
      final prevRecord = await KioskService.instance.previousVisitService.getPreviousVisit(
        patientId: patient.patientId,
        domainId: 'cardiology',
      );
      KioskService.instance.setPreviousVisitRecord(prevRecord);
      expect(KioskService.instance.currentPreviousVisitRecord, isNotNull);

      // Now reset session completely
      KioskService.instance.resetSession();
      expect(KioskService.instance.currentPreviousVisitRecord, isNull);
      expect(KioskService.instance.userType, isNull);

      // Start new user session
      KioskService.instance.setUserType(UserType.newUser);
      KioskService.instance.setIdentifiedPatient(patient);

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: DomainSelectionScreen(patient: patient),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Cardiology'));
      await tester.pump();
      await tester.tap(find.widgetWithText(AayusathiButton, 'CONTINUE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(DoctorPreferenceScreen), findsNothing);
      expect(find.byType(QueueConfirmationScreen), findsOneWidget);
    });

    // --- TESTS — EXISTING PATIENT (9 to 16) ---

    testWidgets('9. Existing Patient + previous visit -> same-doctor question', (tester) async {
      KioskService.instance.resetSession();
      KioskService.instance.setUserType(UserType.existingPatient);
      KioskService.instance.setIdentifiedPatient(patient);

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: DomainSelectionScreen(patient: patient),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Cardiology'));
      await tester.pump();
      await tester.tap(find.widgetWithText(AayusathiButton, 'CONTINUE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(DoctorPreferenceScreen), findsOneWidget);
      expect(find.text('You have previously visited this department. Would you like to visit the same doctor?'),
          findsOneWidget);
    });

    testWidgets('10. Existing Patient + no previous visit -> directly appointment/queue', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      KioskService.instance.resetSession();
      KioskService.instance.setUserType(UserType.existingPatient);
      KioskService.instance.setIdentifiedPatient(patient);

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: DomainSelectionScreen(patient: patient),
        ),
      );
      await tester.pump();

      // Dermatology has no prior visit for patient AAYU-102938
      final dermCard = find.text('Dermatology');
      await tester.ensureVisible(dermCard);
      await tester.tap(dermCard);
      await tester.pump();
      await tester.tap(find.widgetWithText(AayusathiButton, 'CONTINUE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(DoctorPreferenceScreen), findsNothing);
      expect(find.byType(QueueConfirmationScreen), findsOneWidget);
    });

    testWidgets('11. Previous doctor available + YES -> same doctor allocated internally -> queue generated',
        (tester) async {
      KioskService.instance.resetSession();
      KioskService.instance.setUserType(UserType.existingPatient);
      KioskService.instance.setIdentifiedPatient(patient);
      final domain = OpdDomain.findById('cardiology')!;
      final prevVisit = await KioskService.instance.previousVisitService
          .getPreviousVisit(patientId: patient.patientId, domainId: 'cardiology');

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: DoctorPreferenceScreen(
            patient: patient,
            domain: domain,
            previousVisit: prevVisit,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(AayusathiButton, 'YES'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(QueueConfirmationScreen), findsOneWidget);
      expect(KioskService.instance.currentAppointmentRequest?.previousDoctorId, 'DOC-CARD-01');
      expect(KioskService.instance.currentAppointmentRequest?.assignedDoctorId, isNull);
      expect(KioskService.instance.currentAppointmentRequest?.preferredDoctorMode, PreferredDoctorMode.sameDoctor);
    });

    testWidgets('12. Previous doctor unavailable + YES -> alternative doctor question', (tester) async {
      KioskService.instance.resetSession();
      KioskService.instance.setUserType(UserType.existingPatient);
      KioskService.instance.setIdentifiedPatient(patient);
      final domain = OpdDomain.findById('neurology')!;
      final prevVisit = await KioskService.instance.previousVisitService
          .getPreviousVisit(patientId: patient.patientId, domainId: 'neurology');

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: DoctorPreferenceScreen(
            patient: patient,
            domain: domain,
            previousVisit: prevVisit,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(AayusathiButton, 'YES'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Doctor Not Available'), findsOneWidget);
      expect(find.text('Doctor not available. Do you want to visit another doctor?'), findsOneWidget);
    });

    testWidgets('13. Alternative doctor question + YES -> alternative doctor allocated -> queue generated',
        (tester) async {
      KioskService.instance.resetSession();
      KioskService.instance.setUserType(UserType.existingPatient);
      KioskService.instance.setIdentifiedPatient(patient);
      final domain = OpdDomain.findById('neurology')!;
      final prevVisit = await KioskService.instance.previousVisitService
          .getPreviousVisit(patientId: patient.patientId, domainId: 'neurology');

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: DoctorPreferenceScreen(
            patient: patient,
            domain: domain,
            previousVisit: prevVisit,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(AayusathiButton, 'YES'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Patient chooses YES to alternative doctor
      await tester.tap(find.widgetWithText(AayusathiButton, 'YES'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(QueueConfirmationScreen), findsOneWidget);
      expect(KioskService.instance.currentAppointmentRequest?.assignedDoctorId, isNull);
      expect(KioskService.instance.currentAppointmentRequest?.preferredDoctorMode, PreferredDoctorMode.alternativeDoctor);
    });

    testWidgets('14. Alternative doctor question + NO -> no appointment -> no queue -> ThankYouScreen -> Standby',
        (tester) async {
      KioskService.instance.resetSession();
      KioskService.instance.setUserType(UserType.existingPatient);
      KioskService.instance.setIdentifiedPatient(patient);
      final domain = OpdDomain.findById('neurology')!;
      final prevVisit = await KioskService.instance.previousVisitService
          .getPreviousVisit(patientId: patient.patientId, domainId: 'neurology');

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: DoctorPreferenceScreen(
            patient: patient,
            domain: domain,
            previousVisit: prevVisit,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(AayusathiButton, 'YES'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Patient chooses NO to alternative doctor
      await tester.tap(find.widgetWithText(AayusathiSecondaryButton, 'NO'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ThankYouScreen), findsOneWidget);
      expect(find.text('Thank you, visit again.'), findsOneWidget);
      expect(KioskService.instance.currentAppointmentRequest, isNull);

      // Auto-reset returns to Standby
      await tester.pump(const Duration(seconds: 5));
      expect(KioskService.instance.identifiedPatient, isNull);
      expect(KioskService.instance.userType, isNull);
      expect(KioskService.instance.activeLocale, KioskLocale.english);
    });

    testWidgets('15. Same-doctor question + NO -> alternative doctor -> queue', (tester) async {
      KioskService.instance.resetSession();
      KioskService.instance.setUserType(UserType.existingPatient);
      KioskService.instance.setIdentifiedPatient(patient);
      final domain = OpdDomain.findById('cardiology')!;
      final prevVisit = await KioskService.instance.previousVisitService
          .getPreviousVisit(patientId: patient.patientId, domainId: 'cardiology');

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: DoctorPreferenceScreen(
            patient: patient,
            domain: domain,
            previousVisit: prevVisit,
          ),
        ),
      );
      await tester.pump();

      // Tap NO to same doctor
      await tester.tap(find.widgetWithText(AayusathiSecondaryButton, 'NO'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(QueueConfirmationScreen), findsOneWidget);
      expect(KioskService.instance.currentAppointmentRequest?.preferredDoctorMode, PreferredDoctorMode.alternativeDoctor);
      expect(KioskService.instance.currentAppointmentRequest?.queueNumber, isNotNull);
    });

    testWidgets('16. All alternative doctors busy -> pending appointment -> queue', (tester) async {
      KioskService.instance.resetSession();
      // In MockDoctorAvailabilityService, 'orthopedics' has all doctors busy
      final appt = await KioskService.instance.appointmentService.createAppointmentRequest(
        patientId: 'AAYU-102938',
        domainId: 'orthopedics',
        sessionId: 'SESS-ORTH',
        preferredDoctorMode: PreferredDoctorMode.alternativeDoctor,
      );

      expect(appt.status, AppointmentStatus.pending);
      expect(appt.assignedDoctorId, isNull);
      expect(appt.queueNumber, matches(r'^A-[0-9]{5}$'));

      await tester.pumpWidget(
        MaterialApp(
          home: QueueConfirmationScreen(appointment: appt),
        ),
      );
      await tester.pump();

      expect(find.text('OPD consultation request pending. Please proceed to the department waiting area.'), findsOneWidget);
    });

    // --- TESTS — QUEUE FORMAT (17 to 23) ---

    test('17. First queue is A-00001', () {
      final service = MockAppointmentService();
      service.resetQueueCounter();
      expect(service.generateNextQueueNumber(), 'A-00001');
    });

    test('18. 27th queue is A-00027', () {
      final service = MockAppointmentService();
      service.resetQueueCounter();
      for (int i = 1; i < 27; i++) {
        service.generateNextQueueNumber();
      }
      expect(service.generateNextQueueNumber(), 'A-00027');
    });

    test('19. 125th queue is A-00125', () {
      final service = MockAppointmentService();
      service.resetQueueCounter();
      for (int i = 1; i < 125; i++) {
        service.generateNextQueueNumber();
      }
      expect(service.generateNextQueueNumber(), 'A-00125');
    });

    test('20. 12345th queue is A-12345', () {
      final service = MockAppointmentService();
      service.resetQueueCounter();
      for (int i = 1; i < 12345; i++) {
        service.generateNextQueueNumber();
      }
      expect(service.generateNextQueueNumber(), 'A-12345');
    });

    test(r'21. Every queue number matches ^A-[0-9]{5}$', () {
      final service = MockAppointmentService();
      service.resetQueueCounter();
      final regex = RegExp(r'^A-[0-9]{5}$');
      for (int i = 1; i <= 50; i++) {
        final q = service.generateNextQueueNumber();
        expect(regex.hasMatch(q), isTrue, reason: '$q does not match ^A-[0-9]{5}\$');
      }
    });

    test('22. Queue numbers remain sequential', () {
      final service = MockAppointmentService();
      service.resetQueueCounter();
      expect(service.generateNextQueueNumber(), 'A-00001');
      expect(service.generateNextQueueNumber(), 'A-00002');
      expect(service.generateNextQueueNumber(), 'A-00003');
      expect(service.generateNextQueueNumber(), 'A-00004');
    });

    test('23. AppointmentRequest stores the complete queue string', () async {
      final service = MockAppointmentService();
      service.resetQueueCounter();
      final req = await service.createAppointmentRequest(
        patientId: 'AAYU-102938',
        domainId: 'cardiology',
        sessionId: 'SESS-23',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
      );
      expect(req.queueNumber, 'A-00001');
      expect(req.queueNumber.startsWith('A-'), isTrue);
      expect(req.queueNumber.length, 7);
    });

    // --- TESTS — PRIVACY (24 to 29) ---

    testWidgets('24. Queue screen contains queue number', (tester) async {
      final appt = AppointmentRequest(
        requestId: 'REQ-24',
        patientId: 'AAYU-102938',
        domainId: 'cardiology',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.waiting,
        queueNumber: 'A-00027',
        createdAt: DateTime.now(),
        sessionId: 'SESS-24',
      );

      await tester.pumpWidget(MaterialApp(home: QueueConfirmationScreen(appointment: appt)));
      await tester.pump();
      expect(find.text('A-00027'), findsOneWidget);
    });

    testWidgets('25. Queue screen does NOT contain doctor name', (tester) async {
      final appt = AppointmentRequest(
        requestId: 'REQ-25',
        patientId: 'AAYU-102938',
        domainId: 'cardiology',
        assignedDoctorId: 'DOC-CARD-01',
        preferredDoctorMode: PreferredDoctorMode.sameDoctor,
        status: AppointmentStatus.waiting,
        queueNumber: 'A-00027',
        createdAt: DateTime.now(),
        sessionId: 'SESS-25',
      );

      await tester.pumpWidget(MaterialApp(home: QueueConfirmationScreen(appointment: appt)));
      await tester.pump();
      expect(find.textContaining('Dr.'), findsNothing);
      expect(find.textContaining('Doctor Name'), findsNothing);
    });

    testWidgets('26. Queue screen does NOT contain cabin number', (tester) async {
      final appt = AppointmentRequest(
        requestId: 'REQ-26',
        patientId: 'AAYU-102938',
        domainId: 'cardiology',
        status: AppointmentStatus.waiting,
        queueNumber: 'A-00027',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        createdAt: DateTime.now(),
        sessionId: 'SESS-26',
      );

      await tester.pumpWidget(MaterialApp(home: QueueConfirmationScreen(appointment: appt)));
      await tester.pump();
      expect(find.textContaining('Cabin'), findsNothing);
      expect(find.textContaining('Room'), findsNothing);
    });

    testWidgets('27. Queue screen does NOT contain doctor ID', (tester) async {
      final appt = AppointmentRequest(
        requestId: 'REQ-27',
        patientId: 'AAYU-102938',
        domainId: 'cardiology',
        assignedDoctorId: 'DOC-CARD-01',
        preferredDoctorMode: PreferredDoctorMode.sameDoctor,
        status: AppointmentStatus.waiting,
        queueNumber: 'A-00027',
        createdAt: DateTime.now(),
        sessionId: 'SESS-27',
      );

      await tester.pumpWidget(MaterialApp(home: QueueConfirmationScreen(appointment: appt)));
      await tester.pump();
      expect(find.textContaining('DOC-CARD-01'), findsNothing);
      expect(find.textContaining('DOC-'), findsNothing);
    });

    testWidgets('28. Queue screen does NOT contain accepting doctor', (tester) async {
      final appt = AppointmentRequest(
        requestId: 'REQ-28',
        patientId: 'AAYU-102938',
        domainId: 'cardiology',
        assignedDoctorId: 'DOC-CARD-01',
        preferredDoctorMode: PreferredDoctorMode.sameDoctor,
        status: AppointmentStatus.waiting,
        queueNumber: 'A-00027',
        createdAt: DateTime.now(),
        sessionId: 'SESS-28',
      );

      await tester.pumpWidget(MaterialApp(home: QueueConfirmationScreen(appointment: appt)));
      await tester.pump();
      expect(find.textContaining('Accepting'), findsNothing);
      expect(find.textContaining('Assigned'), findsNothing);
    });

    testWidgets('29. ThankYouScreen contains no queue number', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ThankYouScreen()));
      await tester.pump();
      expect(find.text('Thank you, visit again.'), findsOneWidget);
      expect(find.textContaining('A-'), findsNothing);
      expect(find.textContaining('DOC-'), findsNothing);
      expect(find.textContaining('Cabin'), findsNothing);
      expect(find.textContaining('Dr.'), findsNothing);
    });

    // --- TESTS — RESET (30 to 36) ---

    testWidgets('30. ThankYou -> Standby clears session', (tester) async {
      KioskService.instance.startNewSession();
      KioskService.instance.setIdentifiedPatient(patient);
      KioskService.instance.setUserType(UserType.existingPatient);
      KioskService.instance.setSelectedDomain(OpdDomain.findById('cardiology')!);
      expect(KioskService.instance.hasActiveSession, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: const ThankYouScreen(autoResetSeconds: 1),
        ),
      );
      await tester.pump();

      await tester.pump(const Duration(seconds: 2));

      expect(KioskService.instance.identifiedPatient, isNull);
      expect(KioskService.instance.userType, isNull);
      expect(KioskService.instance.selectedDomain, isNull);
      expect(KioskService.instance.hasActiveSession, isFalse);
    });

    testWidgets('31. Queue timeout -> Standby clears session', (tester) async {
      KioskService.instance.startNewSession();
      KioskService.instance.setIdentifiedPatient(patient);
      KioskService.instance.setUserType(UserType.newUser);
      KioskService.instance.setSelectedDomain(OpdDomain.findById('cardiology')!);
      final appt = AppointmentRequest(
        requestId: 'REQ-31',
        patientId: patient.patientId,
        domainId: 'cardiology',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.waiting,
        queueNumber: 'A-00001',
        createdAt: DateTime.now(),
        sessionId: 'SESS-31',
      );
      KioskService.instance.setAppointmentRequest(appt);
      expect(KioskService.instance.hasActiveSession, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: QueueConfirmationScreen(
            appointment: appt,
            autoResetSeconds: 1,
          ),
        ),
      );
      await tester.pump();

      await tester.pump(const Duration(seconds: 2));

      expect(KioskService.instance.identifiedPatient, isNull);
      expect(KioskService.instance.hasActiveSession, isFalse);
    });

    testWidgets('32. Language resets to English on resetSession()', (tester) async {
      KioskService.instance.setLocale(KioskLocale.marathi);
      expect(KioskService.instance.activeLocale, KioskLocale.marathi);

      KioskService.instance.resetSession();
      expect(KioskService.instance.activeLocale, KioskLocale.english);
    });

    test('33. Previous patient\'s user type is cleared on resetSession()', () {
      KioskService.instance.setUserType(UserType.newUser);
      expect(KioskService.instance.userType, UserType.newUser);

      KioskService.instance.resetSession();
      expect(KioskService.instance.userType, isNull);
    });

    test('34. Previous patient\'s domain is cleared on resetSession()', () {
      KioskService.instance.setSelectedDomain(OpdDomain.findById('cardiology')!);
      expect(KioskService.instance.selectedDomain, isNotNull);

      KioskService.instance.resetSession();
      expect(KioskService.instance.selectedDomain, isNull);
    });

    test('35. Previous doctor\'s information is cleared on resetSession()', () {
      KioskService.instance.setPreviousVisitRecord(
        PreviousVisitRecord(
          patientId: 'AAYU-102938',
          domainId: 'cardiology',
          previousDoctorId: 'DOC-CARD-01',
          lastVisitDate: DateTime.now(),
        ),
      );
      expect(KioskService.instance.currentPreviousVisitRecord, isNotNull);

      KioskService.instance.resetSession();
      expect(KioskService.instance.currentPreviousVisitRecord, isNull);
    });

    test('36. Queue number and appointment request are cleared on resetSession()', () {
      final appt = AppointmentRequest(
        requestId: 'REQ-36',
        patientId: 'AAYU-102938',
        domainId: 'cardiology',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.waiting,
        queueNumber: 'A-00001',
        createdAt: DateTime.now(),
        sessionId: 'SESS-36',
      );
      KioskService.instance.setAppointmentRequest(appt);
      expect(KioskService.instance.currentAppointmentRequest, isNotNull);

      KioskService.instance.resetSession();
      expect(KioskService.instance.currentAppointmentRequest, isNull);
    });
  });
}

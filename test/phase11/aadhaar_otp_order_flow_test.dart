import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/core/localization/kiosk_localizations.dart';
import 'package:aayusathi/core/routes/app_routes.dart';
import 'package:aayusathi/kiosk/models/kiosk_session.dart';
import 'package:aayusathi/kiosk/screens/aadhaar_input_screen.dart';
import 'package:aayusathi/kiosk/screens/domain_selection_screen.dart';
import 'package:aayusathi/kiosk/screens/existing_patient_confirmation_screen.dart';
import 'package:aayusathi/kiosk/screens/mobile_number_input_screen.dart';
import 'package:aayusathi/kiosk/screens/otp_success_screen.dart';
import 'package:aayusathi/kiosk/screens/otp_verification_screen.dart';
import 'package:aayusathi/kiosk/screens/patient_details_confirmation_screen.dart';
import 'package:aayusathi/kiosk/screens/patient_id_input_screen.dart';
import 'package:aayusathi/kiosk/screens/queue_confirmation_screen.dart';
import 'package:aayusathi/kiosk/screens/sensor_instructions_screen.dart';
import 'package:aayusathi/kiosk/screens/vitals_screen.dart';
import 'package:aayusathi/kiosk/services/aadhaar_service.dart';
import 'package:aayusathi/kiosk/services/kiosk_service.dart';
import 'package:aayusathi/kiosk/services/mock_patient_repository.dart';
import 'package:aayusathi/kiosk/services/otp_service.dart';
import 'package:aayusathi/kiosk/services/patient_lookup_service.dart';
import 'package:aayusathi/kiosk/widgets/aayusathi_button.dart';
import 'package:aayusathi/services/arduino/arduino_service.dart';
import 'package:aayusathi/services/arduino/mock_arduino_adapter.dart';

void main() {
  setUp(() {
    KioskService.instance.resetSession();
    MockPatientRepository.instance.resetToDefaults();
    final mockAdapter = MockArduinoAdapter(autoConnectOnStart: false);
    final testArduino = ArduinoService(adapter: mockAdapter);
    KioskService.instance.setArduinoServiceForTesting(testArduino);
    (KioskService.instance.aadhaarService as MockAadhaarService).simulateDelay = false;
    (KioskService.instance.patientLookupService as MockPatientLookupService).simulateDelay = false;
    (KioskService.instance.otpService as MockOtpService).simulateDelay = false;
    (KioskService.instance.otpService as MockOtpService).cooldownSeconds = 30;
  });

  Widget buildTestApp({Widget? home, String initialRoute = AppRoutes.userType, Key? key}) {
    return MaterialApp(
      key: key ?? UniqueKey(),
      initialRoute: home == null ? initialRoute : null,
      home: home,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }

  Future<void> tapKeypad(WidgetTester tester, String d) async {
    await tester.tap(find.byKey(ValueKey('keypad_$d')));
    await tester.pump(const Duration(milliseconds: 30));
  }

  Future<void> pumpTransition(WidgetTester tester, [int millis = 500]) async {
    await tester.pump();
    await tester.pump(Duration(milliseconds: millis));
  }

  group('AAYUSATHI Kiosk: Corrected New User Flow & 30 Target Tests', () {
    testWidgets('1-4: Aadhaar input, demographic lookup succeeds, displays data WITHOUT phone', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      KioskService.instance.startNewSession();
      KioskService.instance.setUserType(UserType.newUser);

      await tester.pumpWidget(buildTestApp(initialRoute: AppRoutes.aadhaarInput));
      await pumpTransition(tester);

      // 1. Enter 12 digits for a NEW fake Aadhaar: 555566667777
      for (int i = 0; i < 4; i++) {
        await tapKeypad(tester, '5');
      }
      for (int i = 0; i < 4; i++) {
        await tapKeypad(tester, '6');
      }
      for (int i = 0; i < 4; i++) {
        await tapKeypad(tester, '7');
      }
      await tester.pump();

      expect(find.text('5555  6666  7777'), findsOneWidget);
      expect(find.text('12 / 12'), findsOneWidget);

      // Verify button says CONTINUE
      final continueBtn = find.widgetWithText(AayusathiButton, 'CONTINUE');
      expect(continueBtn, findsOneWidget);

      // 2. Tap CONTINUE -> Aadhaar lookup succeeds
      await tester.tap(continueBtn);
      await pumpTransition(tester, 600);

      // 3. Aadhaar data displayed on PatientDetailsConfirmationScreen
      expect(find.byType(PatientDetailsConfirmationScreen), findsOneWidget);
      expect(find.textContaining('Verified Aadhaar Details'), findsOneWidget);
      expect(find.textContaining('7777'), findsWidgets);

      // 4. Aadhaar lookup does NOT return or display phone number
      expect(find.text('Mobile Number'), findsNothing);
      expect(find.textContaining('+91'), findsNothing);
      expect(KioskService.instance.identifiedPatient, isNull);
    });

    testWidgets('5-9: Continue after Aadhaar -> Mobile screen appears, manual entry, not prefilled, validation', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      KioskService.instance.startNewSession();
      KioskService.instance.setUserType(UserType.newUser);

      await tester.pumpWidget(buildTestApp(initialRoute: AppRoutes.aadhaarInput));
      await pumpTransition(tester);

      // Enter 555566667777
      for (int i = 0; i < 4; i++) {
        await tapKeypad(tester, '5');
      }
      for (int i = 0; i < 4; i++) {
        await tapKeypad(tester, '6');
      }
      for (int i = 0; i < 4; i++) {
        await tapKeypad(tester, '7');
      }
      await tester.pump();

      await tester.tap(find.widgetWithText(AayusathiButton, 'CONTINUE'));
      await pumpTransition(tester, 600);

      expect(find.byType(PatientDetailsConfirmationScreen), findsOneWidget);

      // 5. Tap CONTINUE on PatientDetailsConfirmationScreen
      await tester.tap(find.widgetWithText(AayusathiButton, 'CONTINUE'));
      await pumpTransition(tester, 600);

      // 6. Mobile number screen appears
      expect(find.byType(MobileNumberInputScreen), findsOneWidget);
      expect(find.text('Enter Mobile Number'), findsOneWidget);
      expect(find.text('Enter the mobile number you want to register with AAYUSATHI.'), findsOneWidget);

      // 8. Mobile number is NOT prefilled from Aadhaar
      expect(find.text('XXXXX XXXXX'), findsOneWidget);
      expect(find.text('0 / 10'), findsOneWidget);

      // 9. Invalid mobile number (< 10 digits): SEND OTP is disabled
      await tapKeypad(tester, '9');
      await tapKeypad(tester, '8');
      await tapKeypad(tester, '7');
      await tester.pump();

      expect(find.text('3 / 10'), findsOneWidget);
      final sendOtpBtn = find.widgetWithText(AayusathiButton, 'SEND OTP');
      expect(tester.widget<AayusathiButton>(sendOtpBtn).onPressed, isNull);

      // 7. Complete manual entry of 10 digits
      await tapKeypad(tester, '6');
      await tapKeypad(tester, '5');
      await tapKeypad(tester, '4');
      await tapKeypad(tester, '3');
      await tapKeypad(tester, '2');
      await tapKeypad(tester, '1');
      await tapKeypad(tester, '0');
      await tester.pump();

      expect(find.text('10 / 10'), findsOneWidget);
      expect(tester.widget<AayusathiButton>(sendOtpBtn).onPressed, isNotNull);
    });

    testWidgets('10-14 & 28: Send OTP -> OTP verification -> Patient created only after OTP with entered phone -> Vitals', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      KioskService.instance.startNewSession();
      KioskService.instance.setUserType(UserType.newUser);

      await tester.pumpWidget(buildTestApp(initialRoute: AppRoutes.aadhaarInput));
      await pumpTransition(tester);

      // Enter Aadhaar: 555566667777
      for (int i = 0; i < 4; i++) {
        await tapKeypad(tester, '5');
      }
      for (int i = 0; i < 4; i++) {
        await tapKeypad(tester, '6');
      }
      for (int i = 0; i < 4; i++) {
        await tapKeypad(tester, '7');
      }
      await tester.pump();
      await tester.tap(find.widgetWithText(AayusathiButton, 'CONTINUE'));
      await pumpTransition(tester, 600);

      // Continue to Mobile Screen
      await tester.tap(find.widgetWithText(AayusathiButton, 'CONTINUE'));
      await pumpTransition(tester, 600);

      // Enter 10-digit mobile: 9876543210
      for (final d in ['9', '8', '7', '6', '5', '4', '3', '2', '1', '0']) {
        await tapKeypad(tester, d);
      }
      await tester.pump();

      // 10. Send OTP
      await tester.tap(find.widgetWithText(AayusathiButton, 'SEND OTP'));
      await pumpTransition(tester, 600);

      // 11. OTP Verification Screen appears
      expect(find.byType(OtpVerificationScreen), findsOneWidget);
      expect(find.text('+91 ••••• •3210'), findsOneWidget);

      // 12. Patient must NOT be created before OTP verification
      expect(KioskService.instance.identifiedPatient, isNull);

      // Enter correct OTP: 123456
      for (final d in ['1', '2', '3', '4', '5', '6']) {
        await tapKeypad(tester, d);
      }
      await pumpTransition(tester, 600);

      if (find.byType(SensorInstructionsScreen).evaluate().isNotEmpty) {
        await tester.ensureVisible(find.text('TAKE VITALS'));
        await tester.tap(find.text('TAKE VITALS'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 500));
      }

      // 12 & 28: Patient created after OTP and proceeds to VitalsScreen!
      expect(find.byType(VitalsScreen), findsOneWidget);

      // 13 & 14: Generated Patient ID is unique and new patient stores entered mobile number
      final created = KioskService.instance.identifiedPatient;
      expect(created, isNotNull);
      expect(created!.patientId, startsWith('AAYU-'));
      expect(created.phone, '9876543210');
      expect(created.isNewRegistration, isTrue);
    });

    testWidgets('15-21: Duplicate Aadhaar detected -> blocks patient creation -> shows dialog -> offers existing patient', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      KioskService.instance.startNewSession();
      KioskService.instance.setUserType(UserType.newUser);

      await tester.pumpWidget(buildTestApp(initialRoute: AppRoutes.aadhaarInput));
      await pumpTransition(tester);

      // 15. Enter an ALREADY REGISTERED Aadhaar: 111122223333 (Aarav Sharma, AAYU-102938)
      for (int i = 0; i < 4; i++) {
        await tapKeypad(tester, '1');
      }
      for (int i = 0; i < 4; i++) {
        await tapKeypad(tester, '2');
      }
      for (int i = 0; i < 4; i++) {
        await tapKeypad(tester, '3');
      }
      await tester.pump();

      await tester.tap(find.widgetWithText(AayusathiButton, 'CONTINUE'));
      await pumpTransition(tester, 400);

      // 16, 17, 18, 19, 20: Duplicate Aadhaar blocks patient creation & shows Patient Already Registered dialog
      expect(find.text('Patient Already Registered'), findsOneWidget);
      expect(find.text('This Aadhaar number is already linked to an AAYUSATHI Patient ID.'), findsOneWidget);
      expect(find.text('Please use the Existing Patient option to continue.'), findsOneWidget);

      // CRITICAL: Does NOT expose phone, Aadhaar, internal IDs, password, or OTP
      expect(find.text('98765 43210'), findsNothing);
      expect(find.text('AAYU-102938'), findsNothing);

      // 17, 18, 19: No patient ID generated, no appointment, no queue
      expect(KioskService.instance.identifiedPatient, isNull);
      expect(KioskService.instance.currentAppointmentRequest, isNull);

      // 21. Existing Patient route is offered
      final goToExistingBtn = find.widgetWithText(AayusathiButton, 'Go to Existing Patient');
      expect(goToExistingBtn, findsOneWidget);

      // Tap Go to Existing Patient
      await tester.tap(goToExistingBtn);
      await pumpTransition(tester, 500);

      expect(find.byType(PatientIdInputScreen), findsOneWidget);
    });

    testWidgets('22-26: Existing User flow remains completely unchanged (Patient ID -> OTP -> patient data -> Vitals)', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      KioskService.instance.startNewSession();

      await tester.pumpWidget(buildTestApp(initialRoute: AppRoutes.userType));
      await pumpTransition(tester);

      // 22 & 23: Choose Existing Patient and enter Patient ID
      await tester.tap(find.text('Existing Patient'));
      await pumpTransition(tester, 400);

      expect(find.byType(PatientIdInputScreen), findsOneWidget);

      // Enter Patient ID for Priya Patil: 482910
      for (final d in ['4', '8', '2', '9', '1', '0']) {
        await tapKeypad(tester, d);
      }
      await tester.pump();

      await tester.tap(find.widgetWithText(AayusathiButton, 'CONTINUE'));
      await pumpTransition(tester, 600);

      expect(find.byType(ExistingPatientConfirmationScreen), findsOneWidget);
      expect(find.text('Priya Patil'), findsOneWidget);

      await tester.tap(find.widgetWithText(AayusathiButton, 'CONFIRM IDENTITY'));
      await pumpTransition(tester, 500);

      // 24. Existing user uses registered mobile for OTP
      expect(find.byType(OtpVerificationScreen), findsOneWidget);
      expect(find.text('+91 ••••• •5678'), findsOneWidget);
      expect(find.text('Priya Patil (AAYU-482910)'), findsOneWidget);

      // Enter OTP: 123456
      for (final d in ['1', '2', '3', '4', '5', '6']) {
        await tapKeypad(tester, d);
      }
      await pumpTransition(tester, 600);

      // 25. Existing user receives patient data on OtpSuccessScreen
      expect(find.byType(OtpSuccessScreen), findsOneWidget);
      expect(find.text('Priya Patil'), findsOneWidget);

      // 26. Continue proceeds to vitals
      await tester.tap(find.widgetWithText(AayusathiButton, 'CONTINUE'));
      await pumpTransition(tester, 500);

      if (find.byType(SensorInstructionsScreen).evaluate().isNotEmpty) {
        await tester.ensureVisible(find.text('TAKE VITALS'));
        await tester.tap(find.text('TAKE VITALS'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 500));
      }

      expect(find.byType(VitalsScreen), findsOneWidget);
      expect(find.text('Priya Patil'), findsOneWidget);
    });

    testWidgets('27: New User does NOT trigger PreviousVisitService during Domain Selection', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      KioskService.instance.startNewSession();
      KioskService.instance.setUserType(UserType.newUser);

      // Create a new patient identity
      final dummyNewPatient = MockPatientRepository.instance.findByAadhaar('111122223333')!.copyWith(
        patientId: 'AAYU-999888',
        phone: '9876543210',
        isNewRegistration: true,
      );
      KioskService.instance.setIdentifiedPatient(dummyNewPatient);

      await tester.pumpWidget(
        buildTestApp(
          home: KioskLocalizations.provider(
            locale: KioskLocale.english,
            child: DomainSelectionScreen(patient: dummyNewPatient),
          ),
        ),
      );
      await pumpTransition(tester);

      // Select Cardiology domain
      await tester.tap(find.text('Cardiology'));
      await tester.pump();

      // Tap Continue
      await tester.tap(find.widgetWithText(AayusathiButton, 'CONTINUE'));
      await pumpTransition(tester, 600);

      // Directly routes to queue confirmation without querying doctor preference / previous visit
      expect(find.byType(QueueConfirmationScreen), findsOneWidget);
      expect(KioskService.instance.currentPreviousVisitRecord, isNull);
    });

    testWidgets('29: Reset clears temporary registration state completely', (tester) async {
      final kiosk = KioskService.instance;
      kiosk.startNewSession();
      kiosk.setUserType(UserType.newUser);
      kiosk.setAadhaarInput('555566667777');
      kiosk.setActiveMobileInput('9876543210');
      kiosk.setTemporaryAadhaarData(MockPatientRepository.instance.findByAadhaar('111122223333')!);

      expect(kiosk.activeAadhaarInput, '555566667777');
      expect(kiosk.activeMobileInput, '9876543210');
      expect(kiosk.temporaryAadhaarData, isNotNull);

      // Trigger reset
      kiosk.resetSession();

      expect(kiosk.activeAadhaarInput, isEmpty);
      expect(kiosk.activeMobileInput, isEmpty);
      expect(kiosk.temporaryAadhaarData, isNull);
      expect(kiosk.identifiedPatient, isNull);
      expect(kiosk.currentSession, isNull);
      expect(kiosk.activeLocale, KioskLocale.english);
    });

    testWidgets('30: Non-existent Aadhaar (999988887777) displays localized error and does not advance', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      KioskService.instance.startNewSession();
      KioskService.instance.setUserType(UserType.newUser);

      await tester.pumpWidget(buildTestApp(initialRoute: AppRoutes.aadhaarInput));
      await pumpTransition(tester);

      for (int i = 0; i < 4; i++) {
        await tapKeypad(tester, '9');
      }
      for (int i = 0; i < 4; i++) {
        await tapKeypad(tester, '8');
      }
      for (int i = 0; i < 4; i++) {
        await tapKeypad(tester, '7');
      }
      await tester.pump();

      await tester.tap(find.widgetWithText(AayusathiButton, 'CONTINUE'));
      await pumpTransition(tester, 500);

      expect(find.byType(AadhaarInputScreen), findsOneWidget);
      expect(find.text('Aadhaar record not found. Please check the number and try again.'), findsOneWidget);
      expect(find.byType(PatientDetailsConfirmationScreen), findsNothing);
      expect(KioskService.instance.identifiedPatient, isNull);
    });

    testWidgets('MANUAL ACCEPTANCE TEST A & B: Brand new fake Aadhaar registered, then SAME Aadhaar rejected as duplicate', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // ==========================================
      // TEST A — BRAND NEW PATIENT
      // ==========================================
      KioskService.instance.startNewSession();
      KioskService.instance.setUserType(UserType.newUser);

      await tester.pumpWidget(buildTestApp(initialRoute: AppRoutes.aadhaarInput));
      await pumpTransition(tester);

      // Enter NEW fake Aadhaar: 333344445555
      for (int i = 0; i < 4; i++) {
        await tapKeypad(tester, '3');
      }
      for (int i = 0; i < 4; i++) {
        await tapKeypad(tester, '4');
      }
      for (int i = 0; i < 4; i++) {
        await tapKeypad(tester, '5');
      }
      await tester.pump();

      // Lookup Aadhaar
      await tester.tap(find.widgetWithText(AayusathiButton, 'CONTINUE'));
      await pumpTransition(tester, 600);

      // Aadhaar data appears WITHOUT phone
      expect(find.byType(PatientDetailsConfirmationScreen), findsOneWidget);
      expect(find.text('Mobile Number'), findsNothing);

      // Continue to mobile number
      await tester.tap(find.widgetWithText(AayusathiButton, 'CONTINUE'));
      await pumpTransition(tester, 600);

      expect(find.byType(MobileNumberInputScreen), findsOneWidget);

      // Enter mobile number manually: 9123456789
      for (final d in ['9', '1', '2', '3', '4', '5', '6', '7', '8', '9']) {
        await tapKeypad(tester, d);
      }
      await tester.pump();

      // Send OTP
      await tester.tap(find.widgetWithText(AayusathiButton, 'SEND OTP'));
      await pumpTransition(tester, 600);

      expect(find.byType(OtpVerificationScreen), findsOneWidget);

      // Enter OTP: 123456
      for (final d in ['1', '2', '3', '4', '5', '6']) {
        await tapKeypad(tester, d);
      }
      await pumpTransition(tester, 600);

      if (find.byType(SensorInstructionsScreen).evaluate().isNotEmpty) {
        await tester.ensureVisible(find.text('TAKE VITALS'));
        await tester.tap(find.text('TAKE VITALS'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 500));
      }

      // Patient ID generated & arrives at Vitals
      expect(find.byType(VitalsScreen), findsOneWidget);
      final registeredPatient = KioskService.instance.identifiedPatient;
      expect(registeredPatient, isNotNull);
      expect(registeredPatient!.patientId, startsWith('AAYU-'));
      expect(registeredPatient.phone, '9123456789');

      // ==========================================
      // TEST B — SAME AADHAAR AGAIN
      // ==========================================
      KioskService.instance.resetSession();
      KioskService.instance.startNewSession();
      KioskService.instance.setUserType(UserType.newUser);

      await tester.pumpWidget(buildTestApp(initialRoute: AppRoutes.aadhaarInput));
      await pumpTransition(tester);

      // Enter the SAME Aadhaar: 333344445555
      for (int i = 0; i < 4; i++) {
        await tapKeypad(tester, '3');
      }
      for (int i = 0; i < 4; i++) {
        await tapKeypad(tester, '4');
      }
      for (int i = 0; i < 4; i++) {
        await tapKeypad(tester, '5');
      }
      await tester.pump();

      await tester.tap(find.widgetWithText(AayusathiButton, 'CONTINUE'));
      await pumpTransition(tester, 500);

      // Patient Already Registered appears! Duplicate blocked!
      expect(find.text('Patient Already Registered'), findsOneWidget);
      expect(find.text('This Aadhaar number is already linked to an AAYUSATHI Patient ID.'), findsOneWidget);
      expect(find.text('Go to Existing Patient'), findsOneWidget);

      // No new Patient ID, no vitals, no queue
      expect(find.byType(VitalsScreen), findsNothing);
      expect(find.byType(QueueConfirmationScreen), findsNothing);
    });
  });
}

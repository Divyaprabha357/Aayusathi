import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/core/localization/kiosk_localizations.dart';
import 'package:aayusathi/kiosk/models/patient_identity.dart';
import 'package:aayusathi/kiosk/screens/aadhaar_input_screen.dart';
import 'package:aayusathi/kiosk/screens/otp_verification_screen.dart';
import 'package:aayusathi/kiosk/screens/patient_id_input_screen.dart';
import 'package:aayusathi/kiosk/services/kiosk_service.dart';
import 'package:aayusathi/kiosk/widgets/aayusathi_numeric_keypad.dart';

void main() {
  setUp(() {
    KioskService.instance.resetSession();
  });

  group('Phase 11 UI Cleanup: Strict Verification of Production Patient-Facing UI', () {
    testWidgets('Screen 1 (New Patient / Aadhaar): Verifies legitimate UI and ZERO demo data', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: KioskLocalizations.provider(
            locale: KioskLocale.english,
            child: const AadhaarInputScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify production-facing elements exist
      expect(find.text('STEP 1: AADHAAR VERIFICATION'), findsOneWidget);
      expect(find.text('Aadhaar Number'), findsOneWidget);
      expect(find.text('XXXX XXXX XXXX'), findsOneWidget);
      expect(find.text('0 / 12'), findsOneWidget);
      expect(find.text('Verified identity data cannot be edited directly at the kiosk.'), findsOneWidget);
      expect(find.byType(AayusathiNumericKeypad), findsOneWidget);

      // 2. Strictly verify NO demo text is present
      expect(find.textContaining('Demo records'), findsNothing);
      expect(find.textContaining('1111 2222 3333'), findsNothing);
      expect(find.textContaining('4444 5555 6666'), findsNothing);
      expect(find.textContaining('7777 8888 9999'), findsNothing);
      expect(find.textContaining('1234 5678 9012'), findsNothing);
      expect(find.textContaining('demo', skipOffstage: false), findsNothing);
      expect(find.textContaining('Demo', skipOffstage: false), findsNothing);
    });

    testWidgets('Screen 2 (Existing Patient / Patient ID): Verifies legitimate UI and ZERO demo IDs', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: KioskLocalizations.provider(
            locale: KioskLocale.english,
            child: const PatientIdInputScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify production-facing elements exist
      expect(find.text('EXISTING PATIENT CHECK-IN'), findsOneWidget);
      expect(find.text('AAYUSATHI Patient ID'), findsOneWidget);
      expect(find.text('AAYU-'), findsOneWidget);
      expect(find.text('XXXXXX'), findsOneWidget);
      expect(find.text('0 / 6'), findsOneWidget);
      expect(find.text('Enter the 6 digits of your ID format: AAYU-XXXXXX'), findsOneWidget);
      expect(find.byType(AayusathiNumericKeypad), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);

      // 2. Strictly verify NO demo IDs or hints are present
      expect(find.textContaining('Demo IDs'), findsNothing);
      expect(find.textContaining('AAYU-102938'), findsNothing);
      expect(find.textContaining('AAYU-482910'), findsNothing);
      expect(find.textContaining('AAYU-773829'), findsNothing);
      expect(find.textContaining('AAYU-918234'), findsNothing);
      expect(find.textContaining('demo', skipOffstage: false), findsNothing);
      expect(find.textContaining('Demo', skipOffstage: false), findsNothing);
    });

    testWidgets('Screen 3 (OTP Verification): Verifies legitimate UI and ZERO demo OTP hint', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const testPatient = PatientIdentity(
        aadhaarNumber: '111122223333',
        patientId: 'AAYU-102938',
        fullName: 'Aarav Sharma',
        dob: '14 May 1990',
        age: 34,
        gender: 'Male',
        phone: '+91 98765 43210',
        address: '104, Green Meadows, Pune',
        bloodGroup: 'O+',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: KioskLocalizations.provider(
            locale: KioskLocale.english,
            child: const OtpVerificationScreen(patient: testPatient),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify NO demo OTP hint is present
      expect(find.textContaining('Demo Kiosk OTP'), findsNothing);
      expect(find.textContaining('123456'), findsNothing);
      expect(find.textContaining('demo', skipOffstage: false), findsNothing);
      expect(find.textContaining('Demo', skipOffstage: false), findsNothing);
    });
  });
}

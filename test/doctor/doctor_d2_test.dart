import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/constants/app_constants.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/core/routes/app_routes.dart';
import 'package:aayusathi/core/theme/app_theme.dart';
import 'package:aayusathi/doctor/localization/doctor_localizations.dart';
import 'package:aayusathi/doctor/localization/doctor_strings.dart';
import 'package:aayusathi/doctor/models/doctor_auth_state.dart';
import 'package:aayusathi/doctor/screens/doctor_dashboard_screen.dart';
import 'package:aayusathi/doctor/screens/doctor_login_screen.dart';
import 'package:aayusathi/doctor/screens/doctor_otp_screen.dart';
import 'package:aayusathi/doctor/screens/doctor_standby_screen.dart';
import 'package:aayusathi/doctor/services/doctor_session_service.dart';
import 'package:aayusathi/doctor/widgets/doctor_buttons.dart';
import 'package:aayusathi/kiosk/screens/standby_screen.dart';
import 'package:aayusathi/main.dart';

void main() {
  setUp(() {
    DoctorSessionService.instance.resetSession();
  });

  tearDown(() {
    DoctorSessionService.instance.resetSession();
  });

  Widget buildTestableWidget(
    Widget child, {
    DoctorStrings strings = const DoctorStrings(),
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: DoctorLocalizations.provider(
        strings: strings,
        child: child is Scaffold ? child : Scaffold(body: Center(child: child)),
      ),
    );
  }

  group('AAYUSATHI Phase D2: Doctor Login Screen & Credential Validation', () {
    testWidgets('1. Doctor login screen renders branding, title, subtitle, and fields',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget(const DoctorLoginScreen()));
      await tester.pumpAndSettle();

      // Official Logo & Tagline
      expect(find.byType(Image), findsAtLeastNWidgets(1));
      expect(find.text(AppConstants.appTagline), findsOneWidget);

      // Card Header & Subtitle
      expect(find.text('DOCTOR LOGIN'), findsOneWidget); // Card Title
      expect(find.widgetWithText(DoctorPrimaryButton, 'LOGIN'), findsOneWidget); // Primary Button
      expect(
        find.text('Secure access to your clinical workstation'),
        findsOneWidget,
      );

      // Input Fields
      expect(find.text('Doctor Unique Code'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));

      // Buttons
      expect(find.byType(DoctorPrimaryButton), findsOneWidget);
      expect(find.byType(DoctorSecondaryButton), findsOneWidget);
      expect(find.text('BACK'), findsOneWidget);
    });

    testWidgets('2. Empty Doctor Unique Code shows inline validation error',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget(const DoctorLoginScreen()));
      await tester.pumpAndSettle();

      // Click LOGIN without entering anything
      await tester.tap(find.widgetWithText(DoctorPrimaryButton, 'LOGIN'));
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter your Doctor Unique Code.'),
        findsOneWidget,
      );
      expect(DoctorSessionService.instance.authState, equals(DoctorAuthState.loggedOut));
    });

    testWidgets('3. Empty password shows inline validation error',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget(const DoctorLoginScreen()));
      await tester.pumpAndSettle();

      // Enter code only
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter your assigned doctor code'),
        'DOC-789',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(DoctorPrimaryButton, 'LOGIN'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your password.'), findsOneWidget);
      expect(DoctorSessionService.instance.authState, equals(DoctorAuthState.loggedOut));
    });

    testWidgets('4. Valid credential flow transitions state and triggers success navigation',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool navigationFired = false;
      await tester.pumpWidget(
        buildTestableWidget(
          DoctorLoginScreen(
            onLoginSuccess: () => navigationFired = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter valid credentials
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter your assigned doctor code'),
        'DOC-440',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter workstation password'),
        'clinical@pass123',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(DoctorPrimaryButton, 'LOGIN'));
      await tester.pumpAndSettle();

      expect(navigationFired, isTrue);
      expect(DoctorSessionService.instance.authState, equals(DoctorAuthState.otpPending));
      expect(DoctorSessionService.instance.pendingDoctorCode, equals('DOC-440'));
      expect(DoctorSessionService.instance.maskedPhoneNumber, equals('******4321'));
    });

    testWidgets('5. Invalid credentials show error message and remain on login screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget(const DoctorLoginScreen()));
      await tester.pumpAndSettle();

      // Enter rejected fixture combination
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter your assigned doctor code'),
        'INVALID',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter workstation password'),
        'clinicalPass',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(DoctorPrimaryButton, 'LOGIN'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid login details.'), findsOneWidget);
      expect(DoctorSessionService.instance.authState, equals(DoctorAuthState.loggedOut));
    });

    testWidgets('5b. Password field obscuring toggle functions correctly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget(const DoctorLoginScreen()));
      await tester.pumpAndSettle();

      final passwordFieldFinder =
          find.widgetWithText(TextField, 'Enter workstation password');
      TextField passwordField = tester.widget<TextField>(passwordFieldFinder);
      expect(passwordField.obscureText, isTrue);

      // Tap visibility toggle icon
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      passwordField = tester.widget<TextField>(passwordFieldFinder);
      expect(passwordField.obscureText, isFalse);

      // Tap again to obscure
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pumpAndSettle();

      passwordField = tester.widget<TextField>(passwordFieldFinder);
      expect(passwordField.obscureText, isTrue);
    });

    testWidgets('5c. Forgot Password dialog displays administrative recovery guidance',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget(const DoctorLoginScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      expect(find.text('Workstation Credential Recovery'), findsOneWidget);
      expect(
        find.textContaining('Hospital IT Administration'),
        findsOneWidget,
      );

      // Close dialog
      await tester.tap(find.widgetWithText(DoctorPrimaryButton, 'CLOSE'));
      await tester.pumpAndSettle();

      expect(find.text('Workstation Credential Recovery'), findsNothing);
    });
  });

  group('AAYUSATHI Phase D2: Doctor OTP Screen & Verification Flow', () {
    testWidgets('6. OTP screen renders heading, subtitle, masked mobile, and 6 digit boxes',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget(const DoctorOtpScreen()));
      await tester.pumpAndSettle();

      expect(find.text('OTP VERIFICATION'), findsNWidgets(2)); // Header & Card title
      expect(
        find.text('Enter the verification code sent to your registered mobile number.'),
        findsOneWidget,
      );
      expect(find.textContaining('OTP sent to ******4321'), findsOneWidget);

      // Exactly 6 digit input TextFields
      expect(find.byType(TextField), findsNWidgets(6));

      // Action Buttons
      expect(find.widgetWithText(DoctorPrimaryButton, 'VERIFY OTP'), findsOneWidget);
      expect(find.widgetWithText(DoctorSecondaryButton, 'BACK'), findsOneWidget);
    });

    testWidgets('7. OTP inputs accept exactly 6 numeric digits',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget(const DoctorOtpScreen()));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(6));

      // Type 6 digits across boxes
      for (int i = 0; i < 6; i++) {
        await tester.enterText(textFields.at(i), '${i + 1}');
      }
      await tester.pumpAndSettle();

      // Verify digit entries
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('8. Incomplete OTP shows 6-digit format error',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget(const DoctorOtpScreen()));
      await tester.pumpAndSettle();

      // Only enter 3 digits
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '1');
      await tester.enterText(textFields.at(1), '2');
      await tester.enterText(textFields.at(2), '3');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(DoctorPrimaryButton, 'VERIFY OTP'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter the 6-digit OTP.'), findsOneWidget);
      expect(DoctorSessionService.instance.isAuthenticated, isFalse);
    });

    testWidgets('8b. Invalid OTP remains on OTP screen and shows error message',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget(const DoctorOtpScreen()));
      await tester.pumpAndSettle();

      // Enter rejected fixture OTP '000000'
      final textFields = find.byType(TextField);
      for (int i = 0; i < 6; i++) {
        await tester.enterText(textFields.at(i), '0');
      }
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(DoctorPrimaryButton, 'VERIFY OTP'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid OTP. Please try again.'), findsOneWidget);
      expect(DoctorSessionService.instance.isAuthenticated, isFalse);
      expect(find.byType(DoctorOtpScreen), findsOneWidget);
    });

    testWidgets('9. Successful OTP verification activates session and triggers dashboard transition',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool verifiedFired = false;
      await tester.pumpWidget(
        buildTestableWidget(
          DoctorOtpScreen(
            onVerified: () => verifiedFired = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter valid 6-digit OTP
      final textFields = find.byType(TextField);
      for (int i = 0; i < 6; i++) {
        await tester.enterText(textFields.at(i), '${i + 1}');
      }
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(DoctorPrimaryButton, 'VERIFY OTP'));
      await tester.pumpAndSettle();

      expect(verifiedFired, isTrue);
      expect(DoctorSessionService.instance.isAuthenticated, isTrue);
      expect(DoctorSessionService.instance.authState, equals(DoctorAuthState.authenticated));
      expect(DoctorSessionService.instance.activeDoctorName, isNotNull);
    });
  });

  group('AAYUSATHI Phase D2: Back Navigation & Session Reset', () {
    testWidgets('10. Back button from Doctor Login returns to Doctor Standby',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool backFired = false;
      await tester.pumpWidget(
        buildTestableWidget(
          DoctorLoginScreen(
            onBack: () => backFired = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(DoctorSecondaryButton, 'BACK'));
      await tester.pumpAndSettle();

      expect(backFired, isTrue);
    });

    testWidgets('11. Back button from Doctor OTP returns to Doctor Login',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool backFired = false;
      await tester.pumpWidget(
        buildTestableWidget(
          DoctorOtpScreen(
            onBack: () => backFired = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(DoctorSecondaryButton, 'BACK'));
      await tester.pumpAndSettle();

      expect(backFired, isTrue);
    });

    testWidgets('12. Session reset clears Doctor authentication state and credentials',
        (WidgetTester tester) async {
      // Set session to authenticated
      await DoctorSessionService.instance.validateCredentials(
        doctorCode: 'DOC-101',
        password: 'Password123',
      );
      await DoctorSessionService.instance.verifyOtp('123456');

      expect(DoctorSessionService.instance.isAuthenticated, isTrue);
      expect(DoctorSessionService.instance.activeDoctorId, equals('DOC-101'));

      // Perform reset
      DoctorSessionService.instance.resetSession();

      expect(DoctorSessionService.instance.isAuthenticated, isFalse);
      expect(DoctorSessionService.instance.authState, equals(DoctorAuthState.loggedOut));
      expect(DoctorSessionService.instance.pendingDoctorCode, isNull);
      expect(DoctorSessionService.instance.activeDoctorId, isNull);
      expect(DoctorSessionService.instance.activeDoctorName, isNull);
    });

    testWidgets('13. ZERO demo credentials or demo OTPs appear anywhere in visible UI',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // 1. Inspect Login Screen
      await tester.pumpWidget(buildTestableWidget(const DoctorLoginScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('DOC123'), findsNothing);
      expect(find.textContaining('Demo code'), findsNothing);
      expect(find.textContaining('Demo password'), findsNothing);
      expect(find.textContaining('123456'), findsNothing);

      // 2. Inspect OTP Screen
      await tester.pumpWidget(buildTestableWidget(const DoctorOtpScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Demo OTP'), findsNothing);
      expect(find.textContaining('Your OTP is'), findsNothing);
      expect(find.textContaining('123456'), findsNothing);
    });
  });

  group('AAYUSATHI Phase D2: Localization Foundation (EN, HI, MR)', () {
    test('14. Localization strings exist across English, Hindi, and Marathi', () {
      final en = DoctorLocalizations.forLocale(KioskLocale.english);
      final hi = DoctorLocalizations.forLocale(KioskLocale.hindi);
      final mr = DoctorLocalizations.forLocale(KioskLocale.marathi);

      // English
      expect(en.doctorLoginTitle, equals('DOCTOR LOGIN'));
      expect(en.doctorUniqueCode, equals('Doctor Unique Code'));
      expect(en.password, equals('Password'));
      expect(en.loginButton, equals('LOGIN'));
      expect(en.otpVerificationTitle, equals('OTP VERIFICATION'));
      expect(en.verifyOtpButton, equals('VERIFY OTP'));
      expect(en.resendOtpButton, equals('RESEND OTP'));

      // Hindi
      expect(hi.doctorLoginTitle, equals('डॉक्टर लॉगिन'));
      expect(hi.doctorUniqueCode, equals('डॉक्टर यूनिक कोड'));
      expect(hi.password, equals('पासवर्ड'));
      expect(hi.loginButton, equals('लॉगिन'));
      expect(hi.otpVerificationTitle, equals('ओटीपी सत्यापन'));
      expect(hi.verifyOtpButton, equals('ओटीपी सत्यापित करें'));
      expect(hi.resendOtpButton, equals('ओटीपी पुनः भेजें'));

      // Marathi
      expect(mr.doctorLoginTitle, equals('डॉक्टर लॉगिन'));
      expect(mr.doctorUniqueCode, equals('डॉक्टर युनिक कोड'));
      expect(mr.password, equals('पासवर्ड'));
      expect(mr.loginButton, equals('लॉगिन'));
      expect(mr.otpVerificationTitle, equals('ओटीपी पडताळणी'));
      expect(mr.verifyOtpButton, equals('ओटीपी पडताळा'));
      expect(mr.resendOtpButton, equals('ओटीपी पुन्हा पाठवा'));
    });

    testWidgets('14b. Doctor Login Screen renders properly in Hindi and Marathi',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Hindi test
      await tester.pumpWidget(
        buildTestableWidget(
          const DoctorLoginScreen(),
          strings: DoctorLocalizations.forLocale(KioskLocale.hindi),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('डॉक्टर यूनिक कोड'), findsOneWidget);
      expect(find.text('पासवर्ड'), findsOneWidget);
      expect(find.widgetWithText(DoctorPrimaryButton, 'लॉगिन'), findsOneWidget);
      expect(find.widgetWithText(DoctorSecondaryButton, 'वापस'), findsOneWidget);

      // Marathi test
      await tester.pumpWidget(
        buildTestableWidget(
          const DoctorLoginScreen(),
          strings: DoctorLocalizations.forLocale(KioskLocale.marathi),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('डॉक्टर युनिक कोड'), findsOneWidget);
      expect(find.text('पासवर्ड'), findsOneWidget);
      expect(find.widgetWithText(DoctorPrimaryButton, 'लॉगिन'), findsOneWidget);
      expect(find.widgetWithText(DoctorSecondaryButton, 'मागे'), findsOneWidget);
    });
  });

  group('AAYUSATHI Phase D2: Complete Flow & Routing Integration', () {
    testWidgets('15. Complete Flow: Standby -> Login -> OTP -> Dashboard placeholder',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const AayusathiApp(initialRoute: AppRoutes.doctorStandby),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Doctor Standby Screen
      expect(find.byType(DoctorStandbyScreen), findsOneWidget);

      // 2. Click LOGIN on Standby
      await tester.tap(find.widgetWithText(DoctorPrimaryButton, 'DOCTOR LOGIN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // 3. Arrive at Doctor Login Screen
      expect(find.byType(DoctorLoginScreen), findsOneWidget);

      // 4. Enter valid credentials
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter your assigned doctor code'),
        'DOC-CLINICAL-01',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter workstation password'),
        'HospitalSecure#2026',
      );
      await tester.pumpAndSettle();

      // 5. Submit Login
      await tester.tap(find.widgetWithText(DoctorPrimaryButton, 'LOGIN'));
      await tester.pumpAndSettle();

      // 6. Arrive at Doctor OTP Screen
      expect(find.byType(DoctorOtpScreen), findsOneWidget);
      expect(DoctorSessionService.instance.authState, equals(DoctorAuthState.otpPending));

      // 7. Enter valid 6-digit OTP
      final textFields = find.byType(TextField);
      for (int i = 0; i < 6; i++) {
        await tester.enterText(textFields.at(i), '${i + 1}');
      }
      await tester.pumpAndSettle();

      // 8. Submit OTP
      await tester.tap(find.widgetWithText(DoctorPrimaryButton, 'VERIFY OTP'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // 9. Arrive at Doctor Dashboard Placeholder
      expect(find.byType(DoctorDashboardScreen), findsOneWidget);
      expect(DoctorSessionService.instance.isAuthenticated, isTrue);
    });

    testWidgets('15b. Kiosk routing remains unaffected',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Default AayusathiApp initializes Kiosk route
      await tester.pumpWidget(const AayusathiApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // StandbyScreen for Kiosk is displayed
      expect(find.byType(StandbyScreen), findsOneWidget);
      expect(find.text(AppConstants.appTagline), findsOneWidget);
      expect(DoctorSessionService.instance.isAuthenticated, isFalse);
    });
  });

  group('AAYUSATHI Phase D2: Responsive Desktop Verification', () {
    for (final size in const [
      Size(1366, 768),
      Size(1440, 900),
      Size(1920, 1080),
    ]) {
      testWidgets('16. Login Screen renders cleanly at ${size.width.toInt()}x${size.height.toInt()}',
          (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestableWidget(const DoctorLoginScreen()));
        await tester.pumpAndSettle();

        expect(find.byType(DoctorLoginScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('17. OTP Screen renders cleanly at ${size.width.toInt()}x${size.height.toInt()}',
          (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestableWidget(const DoctorOtpScreen()));
        await tester.pumpAndSettle();

        expect(find.byType(DoctorOtpScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}

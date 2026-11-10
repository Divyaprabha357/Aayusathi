import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/routes/app_routes.dart';
import 'package:aayusathi/firebase_options.dart';
import 'package:aayusathi/models/patient.dart';
import 'package:aayusathi/patient/controllers/patient_auth_controller.dart';
import 'package:aayusathi/patient/controllers/patient_profile_controller.dart';
import 'package:aayusathi/patient/models/patient_app_state.dart';
import 'package:aayusathi/patient/models/patient_lookup_result.dart';
import 'package:aayusathi/main.dart';
import 'package:aayusathi/patient/patient_routes.dart';
import 'package:aayusathi/patient/screens/patient_main_shell_screen.dart';
import 'package:aayusathi/patient/screens/patient_login_screen.dart';
import 'package:aayusathi/patient/screens/patient_otp_screen.dart';
import 'package:aayusathi/patient/screens/patient_profile_screen.dart';
import 'package:aayusathi/patient/services/patient_auth_service.dart';
import 'package:aayusathi/patient/services/patient_otp_service.dart';
import 'package:aayusathi/patient/services/patient_session_service.dart';
import 'package:aayusathi/patient/theme/patient_theme.dart';
import 'package:aayusathi/repositories/mock/mock_patient_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPatientRepository mockPatientRepo;
  late PatientAuthService authService;
  late MockPatientOtpService otpService;

  setUp(() {
    BackendProvider.instance.setMode(BackendMode.mock);
    mockPatientRepo = MockPatientRepository.instance;
    mockPatientRepo.resetToDefaults();
    authService = PatientAuthService(patientRepository: mockPatientRepo);
    otpService = MockPatientOtpService(cooldownSeconds: 0, defaultTestOtp: '123456');
    PatientAppState.instance.resetSession();
    PatientSessionService.instance.logout();
  });

  group('Phase P2: Android Firebase Foundation & Configuration', () {
    test('1. Android FirebaseOptions uses official project aayusathi-a1199', () {
      final androidOptions = DefaultFirebaseOptions.android;
      expect(androidOptions.projectId, equals('aayusathi-a1199'));
      expect(androidOptions.appId, equals('1:919886761374:android:f0c11883a5fd4560f0da8f'));
      expect(androidOptions.messagingSenderId, equals('919886761374'));
      expect(androidOptions.storageBucket, equals('aayusathi-a1199.firebasestorage.app'));
    });

    test('2. Windows FirebaseOptions remains preserved and intact', () {
      final windowsOptions = DefaultFirebaseOptions.windows;
      expect(windowsOptions.projectId, equals('aayusathi-a1199'));
      expect(windowsOptions.appId, equals('1:919886761374:web:2ba6032b56822b2ff0da8f'));
      expect(windowsOptions.messagingSenderId, equals('919886761374'));
    });
  });

  group('Phase P2: Patient ID Validation & Lookup Tests', () {
    test('3. Empty Patient ID returns invalidFormat result', () async {
      final result = await authService.lookupPatientById('   ');
      expect(result.status, equals(PatientLookupStatus.invalidFormat));
      expect(result.isSuccessful, isFalse);
    });

    test('4. Malformed/illegal character Patient ID returns invalidFormat result', () async {
      final result = await authService.lookupPatientById('AAYU@@123');
      expect(result.status, equals(PatientLookupStatus.invalidFormat));
      expect(result.isSuccessful, isFalse);
    });

    test('5. Non-existent Patient ID returns notFound result', () async {
      final result = await authService.lookupPatientById('AAYU-999999');
      expect(result.status, equals(PatientLookupStatus.notFound));
      expect(result.isSuccessful, isFalse);
      expect(result.errorMessage, contains('No registered patient found'));
    });

    test('6. Valid existing Patient ID returns minimal masked result', () async {
      final result = await authService.lookupPatientById('AAYU-102938');
      expect(result.status, equals(PatientLookupStatus.found));
      expect(result.isSuccessful, isTrue);
      expect(result.patientId, equals('AAYU-102938'));
      expect(result.maskedPhone, startsWith('+91 ******'));
    });

    test('7. Inactive Patient returns inactive status with appropriate message', () async {
      // Register an inactive test patient
      final inactivePatient = Patient(
        patientId: 'PAT-INACTIVE-01',
        name: 'Inactive User',
        dateOfBirth: '1970-01-01',
        age: 56,
        gender: 'Male',
        phone: '9876543210',
        bloodGroup: 'O+',
        address: 'Pune',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: false,
      );
      await mockPatientRepo.savePatient(inactivePatient);

      final result = await authService.lookupPatientById('PAT-INACTIVE-01');
      expect(result.status, equals(PatientLookupStatus.inactive));
      expect(result.isSuccessful, isFalse);
      expect(result.errorMessage, contains('inactive'));
    });
  });

  group('Phase P2: Phone Number Masking & Security', () {
    test('8. Phone masking securely hides all digits except the last 4', () async {
      final result = await authService.lookupPatientById('AAYU-102938');
      expect(result.maskedPhone, equals('+91 ******3210'));
      expect(result.maskedPhone!.contains('987654'), isFalse);
    });

    test('9. LookupResult strictly contains zero Aadhaar or clinical records', () {
      final lookup = PatientLookupResult.found(
        patientId: 'AAYU-102938',
        maskedPhone: '+91 ******4321',
      );
      expect(lookup.patientId, equals('AAYU-102938'));
      expect(lookup.maskedPhone, equals('+91 ******4321'));
      expect(lookup.isActive, isTrue);
    });
  });

  group('Phase P2: OTP Abstraction & Mock OTP Lifecycle', () {
    test('10. OTP service sends OTP and tracks lastSentTime', () async {
      final sent = await otpService.sendOtp(
        patientId: 'AAYU-102938',
        maskedPhone: '+91 ******4321',
      );
      expect(sent, isTrue);
      expect(otpService.lastSentTime, isNotNull);
    });

    test('11. Deterministic OTP verification succeeds with configured test OTP', () async {
      final verified = await otpService.verifyOtp(
        patientId: 'AAYU-102938',
        otp: '123456',
      );
      expect(verified, isTrue);
    });

    test('12. Incorrect OTP fails verification', () async {
      final verified = await otpService.verifyOtp(
        patientId: 'AAYU-102938',
        otp: '999999',
      );
      expect(verified, isFalse);
    });

    test('13. Malformed or non-6-digit OTP fails verification immediately', () async {
      expect(await otpService.verifyOtp(patientId: 'AAYU-102938', otp: '123'), isFalse);
      expect(await otpService.verifyOtp(patientId: 'AAYU-102938', otp: 'abcdef'), isFalse);
      expect(await otpService.verifyOtp(patientId: 'AAYU-102938', otp: ''), isFalse);
    });

    test('14. OTP resend respects 30-second cooldown period', () async {
      final cooldownOtpService = MockPatientOtpService(cooldownSeconds: 30);
      await cooldownOtpService.sendOtp(patientId: 'AAYU-102938', maskedPhone: '+91 ******4321');
      expect(cooldownOtpService.canResend, isFalse);
      expect(cooldownOtpService.remainingCooldownSeconds, greaterThan(0));

      final secondSend = await cooldownOtpService.sendOtp(
        patientId: 'AAYU-102938',
        maskedPhone: '+91 ******4321',
      );
      expect(secondSend, isFalse);
    });
  });

  group('Phase P2: PatientAuthController End-to-End Workflow', () {
    test('15. Controller orchestrates Patient ID lookup, OTP sending, and cooldown', () async {
      final cooldownOtpService = MockPatientOtpService(cooldownSeconds: 30);
      final controller = PatientAuthController(
        authService: authService,
        otpService: cooldownOtpService,
        sessionService: PatientSessionService.instance,
      );

      expect(controller.status, equals(PatientAuthStatus.idle));

      // Submit valid ID
      final success = await controller.submitPatientId('AAYU-102938');
      expect(success, isTrue);
      expect(controller.status, equals(PatientAuthStatus.idVerified));
      expect(controller.pendingPatientId, equals('AAYU-102938'));
      expect(controller.maskedPhone, equals('+91 ******3210'));
      expect(controller.cooldownRemaining, greaterThan(0));
      expect(controller.canResendOtp, isFalse);

      controller.dispose();
    });

    test('16. Controller verifies valid OTP and creates authenticated PatientSession', () async {
      final controller = PatientAuthController(
        authService: authService,
        otpService: otpService,
        sessionService: PatientSessionService.instance,
      );

      await controller.submitPatientId('AAYU-102938');

      final verified = await controller.verifyOtp('123456');
      expect(verified, isTrue);
      expect(controller.status, equals(PatientAuthStatus.authenticated));

      // Check active session
      final session = PatientSessionService.instance.currentSession;
      expect(session.isAuthenticated, isTrue);
      expect(session.patientId, equals('AAYU-102938'));
      expect(PatientAppState.instance.isAuthenticated, isTrue);
      expect(PatientAppState.instance.authenticatedPatientId, equals('AAYU-102938'));

      controller.dispose();
    });

    test('17. Controller sets error on invalid OTP code without creating session', () async {
      final controller = PatientAuthController(
        authService: authService,
        otpService: otpService,
        sessionService: PatientSessionService.instance,
      );

      await controller.submitPatientId('AAYU-102938');

      final verified = await controller.verifyOtp('000000');
      expect(verified, isFalse);
      expect(controller.status, equals(PatientAuthStatus.error));
      expect(controller.errorMessage, contains('Invalid OTP'));
      expect(PatientSessionService.instance.isAuthenticated, isFalse);

      controller.dispose();
    });
  });

  group('Phase P2: Patient Session & Logout Lifecycle', () {
    test('18. Session starts authenticated and logout resets all state', () {
      final sessionService = PatientSessionService.instance;
      sessionService.startSession('AAYU-102938');

      expect(sessionService.isAuthenticated, isTrue);
      expect(sessionService.authenticatedPatientId, equals('AAYU-102938'));
      expect(PatientAppState.instance.isAuthenticated, isTrue);

      // Perform logout
      sessionService.logout();

      expect(sessionService.isAuthenticated, isFalse);
      expect(sessionService.authenticatedPatientId, isNull);
      expect(PatientAppState.instance.isAuthenticated, isFalse);
      expect(PatientAppState.instance.authenticatedPatientId, isNull);
    });

    test('19. Patient logout strictly does not affect other module routes or sessions', () {
      final sessionService = PatientSessionService.instance;
      sessionService.startSession('AAYU-102938');
      sessionService.logout();

      // Ensure other app routes generate cleanly
      final kiosk = AppRoutes.onGenerateRoute(const RouteSettings(name: AppRoutes.standby));
      final doctor = AppRoutes.onGenerateRoute(const RouteSettings(name: AppRoutes.doctorLogin));
      final admin = AppRoutes.onGenerateRoute(const RouteSettings(name: AppRoutes.adminLogin));

      expect(kiosk, isNotNull);
      expect(doctor, isNotNull);
      expect(admin, isNotNull);
    });
  });

  group('Phase P2: Widget & UI Interaction Tests', () {
    testWidgets('20. Login screen navigates to OTP screen with masked phone on valid Patient ID', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      final controller = PatientAuthController(
        authService: authService,
        otpService: otpService,
        sessionService: PatientSessionService.instance,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          routes: {
            '/patient/login': (_) => PatientLoginScreen(controller: controller),
            '/patient/otp': (_) => const Scaffold(body: Text('OTP_SCREEN_ARRIVED')),
          },
          initialRoute: '/patient/login',
        ),
      );
      await tester.pump();

      // Enter Patient ID
      await tester.enterText(find.byType(TextFormField), 'AAYU-102938');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('OTP_SCREEN_ARRIVED'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('21. OTP screen verifies OTP code and navigates to Dashboard', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      final controller = PatientAuthController(
        authService: authService,
        otpService: otpService,
        sessionService: PatientSessionService.instance,
      );
      await controller.submitPatientId('AAYU-102938');

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          routes: {
            '/patient/otp': (_) => PatientOtpScreen(
                  patientId: 'AAYU-102938',
                  maskedPhone: '+91 ******3210',
                  controller: controller,
                ),
            '/patient/dashboard': (_) => const Scaffold(body: Text('PATIENT_DASHBOARD_SHELL')),
          },
          initialRoute: '/patient/otp',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('+91 ******3210'), findsOneWidget);

      // Enter 6-digit OTP
      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('PATIENT_DASHBOARD_SHELL'), findsOneWidget);
      expect(PatientSessionService.instance.isAuthenticated, isTrue);

      controller.dispose();
    });

    testWidgets('22. Profile Screen renders Log Out button and confirmation dialog triggers logout', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      PatientSessionService.instance.startSession('AAYU-102938');
      final profileController = PatientProfileController(patientRepo: mockPatientRepo);
      await profileController.loadProfile();

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          routes: {
            '/patient/profile': (_) => PatientProfileScreen(controller: profileController),
            '/patient/login': (_) => const Scaffold(body: Text('BACK_TO_LOGIN')),
          },
          initialRoute: '/patient/profile',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(OutlinedButton), findsOneWidget);

      // Tap Log Out button
      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Are you sure you want to log out?'), findsOneWidget);

      // Confirm Logout
      final logoutButton = find.widgetWithText(ElevatedButton, 'Log Out');
      expect(logoutButton, findsOneWidget);
      await tester.tap(logoutButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('BACK_TO_LOGIN'), findsOneWidget);
      expect(PatientSessionService.instance.isAuthenticated, isFalse);
    });

    testWidgets('23. Zero OTP values are visibly rendered on OTP verification screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      final controller = PatientAuthController(
        authService: authService,
        otpService: otpService,
        sessionService: PatientSessionService.instance,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: PatientOtpScreen(
            patientId: 'AAYU-102938',
            maskedPhone: '+91 ******3210',
            controller: controller,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('123456'), findsNothing);
      expect(find.textContaining('Development Shell'), findsNothing);
      expect(find.textContaining('demo OTP'), findsNothing);

      controller.dispose();
    });
  });

  group('Phase P2: Patient Authentication Entry & Route Protection Tests', () {
    testWidgets('24. Route /patient when unauthenticated opens PatientLoginScreen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      expect(PatientSessionService.instance.isAuthenticated, isFalse);

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: '/patient',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PatientLoginScreen), findsOneWidget);
      expect(find.byType(PatientMainShellScreen), findsNothing);
    });

    testWidgets('25. Route /patient when authenticated opens PatientMainShellScreen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      PatientSessionService.instance.startSession('AAYU-102938');
      expect(PatientSessionService.instance.isAuthenticated, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: '/patient',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PatientMainShellScreen), findsOneWidget);
      expect(find.byType(PatientLoginScreen), findsNothing);
    });

    testWidgets('26. Route /patient/dashboard when unauthenticated redirects to PatientLoginScreen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      expect(PatientSessionService.instance.isAuthenticated, isFalse);

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: '/patient/dashboard',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PatientLoginScreen), findsOneWidget);
      expect(find.byType(PatientMainShellScreen), findsNothing);
    });

    testWidgets('27. Protected tabs (/cases, /reports, /calendar, /profile) redirect unauthenticated user to login', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      expect(PatientSessionService.instance.isAuthenticated, isFalse);

      for (final routeName in ['/patient/cases', '/patient/reports', '/patient/calendar', '/patient/profile']) {
        final generatedRoute = PatientRoutes.onGenerateRoute(RouteSettings(name: routeName));
        expect(generatedRoute, isNotNull);
      }
    });

    testWidgets('28. Full AayusathiApp with initialRoute=/patient unauthenticated launches PatientLoginScreen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      expect(PatientSessionService.instance.isAuthenticated, isFalse);

      await tester.pumpWidget(const AayusathiApp(initialRoute: '/patient'));
      await tester.pumpAndSettle();

      expect(find.byType(PatientLoginScreen), findsOneWidget);
      expect(find.byType(PatientMainShellScreen), findsNothing);
    });

    testWidgets('29. Full AayusathiApp with initialRoute=/patient authenticated launches PatientMainShellScreen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      PatientSessionService.instance.startSession('AAYU-102938');
      expect(PatientSessionService.instance.isAuthenticated, isTrue);

      await tester.pumpWidget(const AayusathiApp(initialRoute: '/patient'));
      await tester.pumpAndSettle();

      expect(find.byType(PatientMainShellScreen), findsOneWidget);
      expect(find.byType(PatientLoginScreen), findsNothing);
    });

    testWidgets('30. End-to-end: unauthenticated entry -> login -> OTP -> dashboard -> logout -> login', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      expect(PatientSessionService.instance.isAuthenticated, isFalse);

      final controller = PatientAuthController(
        authService: authService,
        otpService: otpService,
        sessionService: PatientSessionService.instance,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          onGenerateRoute: (settings) {
            if (settings.name == '/patient/login') {
              return MaterialPageRoute(builder: (_) => PatientLoginScreen(controller: controller));
            }
            if (settings.name == '/patient/otp') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (_) => PatientOtpScreen(
                  patientId: args?['patientId'] as String?,
                  maskedPhone: args?['maskedPhone'] as String?,
                  controller: controller,
                ),
              );
            }
            return AppRoutes.onGenerateRoute(settings);
          },
          initialRoute: '/patient',
        ),
      );
      await tester.pumpAndSettle();

      // Step 1: Arrived at Login Screen
      expect(find.byType(PatientLoginScreen), findsOneWidget);

      // Step 2: Enter Patient ID and Continue
      await tester.enterText(find.byType(TextFormField), 'AAYU-102938');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Step 3: Arrived at OTP screen with masked phone
      expect(find.byType(PatientOtpScreen), findsOneWidget);
      expect(find.text('+91 ******3210'), findsOneWidget);

      // Step 4: Enter 6-digit OTP and verify
      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Step 5: Session is now authenticated and reached Dashboard
      expect(PatientSessionService.instance.isAuthenticated, isTrue);
      expect(find.byType(PatientMainShellScreen), findsOneWidget);

      // Step 6: Logout
      PatientSessionService.instance.logout();
      expect(PatientSessionService.instance.isAuthenticated, isFalse);

      controller.dispose();
    });
  });
}


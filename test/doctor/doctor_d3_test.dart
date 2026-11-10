import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aayusathi/core/auth/auth_user.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/core/routes/app_routes.dart';
import 'package:aayusathi/doctor/localization/doctor_localizations.dart';
import 'package:aayusathi/doctor/models/doctor_auth_state.dart';
import 'package:aayusathi/doctor/models/doctor_profile.dart';
import 'package:aayusathi/doctor/screens/doctor_login_screen.dart';
import 'package:aayusathi/doctor/screens/doctor_otp_screen.dart';
import 'package:aayusathi/doctor/services/doctor_otp_service.dart';
import 'package:aayusathi/doctor/services/doctor_session_service.dart';
import 'package:aayusathi/core/theme/app_theme.dart';
import 'package:aayusathi/doctor/services/mock_doctor_session_service.dart';
import 'package:aayusathi/repositories/mock/mock_audit_repository.dart';

Widget buildTestableWidget(
  Widget child, {
  KioskLocale locale = KioskLocale.english,
  DoctorSessionService? sessionService,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    routes: {
      AppRoutes.doctorStandby: (context) => const Scaffold(body: Text('Doctor Standby Screen')),
      AppRoutes.doctorLogin: (context) => const Scaffold(body: Text('Doctor Login Screen')),
      AppRoutes.doctorOtp: (context) => const Scaffold(body: Text('Doctor OTP Screen')),
      AppRoutes.doctorDashboard: (context) => const Scaffold(body: Text('Doctor Dashboard Screen')),
      AppRoutes.kioskHome: (context) => const Scaffold(body: Text('Kiosk Home Screen')),
    },
    home: DoctorLocalizations.provider(
      strings: DoctorLocalizations.forLocale(locale),
      child: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDoctorSessionService mockSession;
  late MockAuditRepository mockAudit;

  setUp(() {
    mockAudit = MockAuditRepository();
    mockAudit.clear();
    mockSession = MockDoctorSessionService(auditRepository: mockAudit);
    DoctorSessionService.instance = mockSession;
  });

  tearDown(() {
    mockSession.resetSession();
    mockAudit.clear();
  });

  group('AAYUSATHI Phase D3: DoctorProfile Model & Integrity', () {
    test('1. DoctorProfile contains all required fields and serializes cleanly', () {
      final now = DateTime(2026, 9, 5, 12, 0, 0);
      final profile = DoctorProfile(
        doctorId: 'DOC-001',
        doctorUniqueCode: 'DOC-101',
        name: 'Dr. Rajesh Sharma',
        qualification: 'MBBS, MD (Cardiology)',
        department: 'cardiology',
        registeredPhone: '+919876543210',
        email: 'rajesh.sharma@hospital.aayusathi.in',
        isActive: true,
        availabilityStatus: DoctorAvailabilityStatus.available,
        authUid: 'fb-auth-uid-doc-001',
        createdAt: now,
        updatedAt: now,
      );

      expect(profile.doctorId, equals('DOC-001'));
      expect(profile.doctorUniqueCode, equals('DOC-101'));
      expect(profile.name, equals('Dr. Rajesh Sharma'));
      expect(profile.qualification, equals('MBBS, MD (Cardiology)'));
      expect(profile.department, equals('cardiology'));
      expect(profile.registeredPhone, equals('+919876543210'));
      expect(profile.email, equals('rajesh.sharma@hospital.aayusathi.in'));
      expect(profile.isActive, isTrue);
      expect(profile.availabilityStatus, equals(DoctorAvailabilityStatus.available));
      expect(profile.authUid, equals('fb-auth-uid-doc-001'));
      expect(profile.createdAt, equals(now));
      expect(profile.updatedAt, equals(now));
    });

    test('2. DoctorProfile fromFirestore and toFirestore work symmetrically', () {
      final now = DateTime(2026, 9, 5, 12, 0, 0);
      final map = {
        'doctorId': 'DOC-002',
        'doctorUniqueCode': 'DOC-202',
        'name': 'Dr. Priya Patel',
        'qualification': 'MBBS, MS (Neurology)',
        'department': 'neurology',
        'registeredPhone': '+919123456789',
        'email': 'priya.patel@hospital.aayusathi.in',
        'isActive': true,
        'availabilityStatus': 'available',
        'authUid': 'fb-auth-uid-doc-002',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      final profile = DoctorProfile.fromFirestore(map, 'DOC-002');
      expect(profile.doctorId, equals('DOC-002'));
      expect(profile.doctorUniqueCode, equals('DOC-202'));
      expect(profile.name, equals('Dr. Priya Patel'));
      expect(profile.department, equals('neurology'));
      expect(profile.availabilityStatus, equals(DoctorAvailabilityStatus.available));

      final firestoreMap = profile.toFirestore();
      expect(firestoreMap['doctorId'], equals('DOC-002'));
      expect(firestoreMap['doctorUniqueCode'], equals('DOC-202'));
      expect(firestoreMap['name'], equals('Dr. Priya Patel'));
      expect(firestoreMap['isActive'], isTrue);
    });

    test('3. Passwords are NEVER serialized in DoctorProfile or Firestore maps', () {
      final now = DateTime.now();
      final profile = DoctorProfile(
        doctorId: 'DOC-003',
        doctorUniqueCode: 'DOC-303',
        name: 'Dr. Test Physician',
        qualification: 'MBBS',
        department: 'general_medicine',
        registeredPhone: '+919876543210',
        email: 'doc303@hospital.aayusathi.in',
        isActive: true,
        availabilityStatus: DoctorAvailabilityStatus.available,
        authUid: 'auth-003',
        createdAt: now,
        updatedAt: now,
      );

      final toMapKeys = profile.toMap().keys.map((k) => k.toLowerCase()).toList();
      final toFirestoreKeys = profile.toFirestore().keys.map((k) => k.toLowerCase()).toList();

      expect(toMapKeys.contains('password'), isFalse);
      expect(toMapKeys.contains('pwd'), isFalse);
      expect(toMapKeys.contains('secret'), isFalse);

      expect(toFirestoreKeys.contains('password'), isFalse);
      expect(toFirestoreKeys.contains('pwd'), isFalse);
      expect(toFirestoreKeys.contains('secret'), isFalse);
    });

    test('4. Doctor Unique Code normalization is deterministic and case-insensitive', () {
      expect(DoctorProfile.normalizeCode('doc-101'), equals('DOC-101'));
      expect(DoctorProfile.normalizeCode('  DOC-101  '), equals('DOC-101'));
      expect(DoctorProfile.normalizeCode('Doc-101'), equals('DOC-101'));
      expect(DoctorProfile.normalizeCode('doc-card-01'), equals('DOC-CARD-01'));
    });

    test('5. Masked phone number correctly masks digits for privacy', () {
      final profile1 = DoctorProfile(
        doctorId: 'DOC-001',
        doctorUniqueCode: 'DOC-101',
        name: 'Dr. Sharma',
        qualification: 'MBBS',
        department: 'cardiology',
        registeredPhone: '+919876543210',
        email: 'doc@hospital.in',
        authUid: 'uid-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(profile1.maskedPhone, equals('******3210'));

      final profile2 = profile1.copyWith(registeredPhone: '9876544321');
      expect(profile2.maskedPhone, equals('******4321'));
    });
  });

  group('AAYUSATHI Phase D3: Doctor Authentication & Session Transitions', () {
    test('6. Doctor session begins in loggedOut state', () {
      expect(mockSession.authState, equals(DoctorAuthState.loggedOut));
      expect(mockSession.isAuthenticated, isFalse);
      expect(mockSession.activeDoctorId, isNull);
      expect(mockSession.activeProfile, isNull);
      expect(mockSession.pendingProfile, isNull);
    });

    test('7. Valid credentials transition session from loggedOut -> otpPending', () async {
      final result = await mockSession.validateCredentials(
        doctorCode: 'DOC-101',
        password: 'Password123',
      );

      expect(result.isSuccess, isTrue);
      expect(result.state, equals(DoctorAuthState.otpPending));
      expect(mockSession.authState, equals(DoctorAuthState.otpPending));
      expect(mockSession.pendingDoctorCode, equals('DOC-101'));
      expect(mockSession.maskedPhoneNumber, equals('******3210'));
      expect(mockSession.pendingProfile?.doctorId, equals('DOC-101'));
      expect(mockSession.isAuthenticated, isFalse);
    });

    test('8. Normalized unique code lookup works with mixed case and whitespace', () async {
      final result = await mockSession.validateCredentials(
        doctorCode: '  doc-101  ',
        password: 'Password123',
      );

      expect(result.isSuccess, isTrue);
      expect(mockSession.authState, equals(DoctorAuthState.otpPending));
      expect(mockSession.pendingProfile?.name, equals('Dr. Physician'));
    });

    test('9. Inactive Doctor profile is rejected with clinical administrative message', () async {
      final result = await mockSession.validateCredentials(
        doctorCode: 'DOC-INACTIVE',
        password: 'Password123',
      );

      expect(result.isSuccess, isFalse);
      expect(result.state, equals(DoctorAuthState.loggedOut));
      expect(
        result.errorMessage,
        equals('Your doctor account is currently inactive. Please contact Hospital Administration.'),
      );
      expect(mockSession.authState, equals(DoctorAuthState.loggedOut));
      expect(mockSession.isAuthenticated, isFalse);
    });

    test('10. Invalid credentials return clean error without exposing internals', () async {
      final result = await mockSession.validateCredentials(
        doctorCode: 'INVALID',
        password: 'WRONG',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, equals('Invalid login details.'));
      expect(mockSession.authState, equals(DoctorAuthState.loggedOut));
    });

    test('11. Successful OTP verification establishes active Doctor session and role', () async {
      await mockSession.validateCredentials(
        doctorCode: 'DOC-101',
        password: 'Password123',
      );

      final otpResult = await mockSession.verifyOtp('123456');

      expect(otpResult.isSuccess, isTrue);
      expect(mockSession.isAuthenticated, isTrue);
      expect(mockSession.authState, equals(DoctorAuthState.authenticated));
      expect(mockSession.role, equals(UserRole.doctor));
      expect(mockSession.activeDoctorId, equals('DOC-101'));
      expect(mockSession.activeDoctorName, equals('Dr. Physician'));
      expect(mockSession.activeDepartment, equals('cardiology'));
      expect(mockSession.activeProfile, isNotNull);
      expect(mockSession.pendingProfile, isNull);
    });

    test('12. Incomplete or invalid OTP is rejected', () async {
      await mockSession.validateCredentials(
        doctorCode: 'DOC-101',
        password: 'Password123',
      );

      final shortOtpResult = await mockSession.verifyOtp('123');
      expect(shortOtpResult.isSuccess, isFalse);
      expect(shortOtpResult.errorMessage, equals('Please enter the 6-digit OTP.'));

      final invalidOtpResult = await mockSession.verifyOtp('000000');
      expect(invalidOtpResult.isSuccess, isFalse);
      expect(invalidOtpResult.errorMessage, equals('Invalid OTP. Please try again.'));

      // Workstation remains in otpPending state
      expect(mockSession.authState, equals(DoctorAuthState.otpPending));
      expect(mockSession.isAuthenticated, isFalse);
    });

    test('13. Logout completely clears Doctor session and returns to loggedOut state', () async {
      await mockSession.validateCredentials(
        doctorCode: 'DOC-101',
        password: 'Password123',
      );
      await mockSession.verifyOtp('123456');
      expect(mockSession.isAuthenticated, isTrue);

      await mockSession.logout();

      expect(mockSession.isAuthenticated, isFalse);
      expect(mockSession.authState, equals(DoctorAuthState.loggedOut));
      expect(mockSession.activeDoctorId, isNull);
      expect(mockSession.activeDoctorName, isNull);
      expect(mockSession.activeDepartment, isNull);
      expect(mockSession.activeProfile, isNull);
      expect(mockSession.pendingProfile, isNull);
      expect(mockSession.pendingDoctorCode, isNull);
    });
  });

  group('AAYUSATHI Phase D3: Role Security & Anti-Self-Registration', () {
    testWidgets('14. Doctor Login UI contains ZERO self-registration or signup paths',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget(const DoctorLoginScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining(RegExp(r'Sign Up', caseSensitive: false)), findsNothing);
      expect(find.textContaining(RegExp(r'Register', caseSensitive: false)), findsNothing);
      expect(find.textContaining(RegExp(r'Create Account', caseSensitive: false)), findsNothing);
      expect(find.textContaining(RegExp(r'Self Registration', caseSensitive: false)), findsNothing);
    });

    test('15. Role enforcement: Authenticated session strictly holds UserRole.doctor', () async {
      await mockSession.validateCredentials(
        doctorCode: 'DOC-101',
        password: 'Password123',
      );
      expect(mockSession.role, isNot(equals(UserRole.doctor)));

      await mockSession.verifyOtp('123456');
      expect(mockSession.role, equals(UserRole.doctor));
      expect(mockSession.role == UserRole.admin, isFalse);
      expect(mockSession.role == UserRole.kiosk, isFalse);
      expect(mockSession.role == UserRole.patient, isFalse);
    });
  });

  group('AAYUSATHI Phase D3: Audit Logging Architecture', () {
    test('16. Authentication lifecycle records audit logs without sensitive credentials', () async {
      await mockSession.validateCredentials(
        doctorCode: 'DOC-101',
        password: 'SuperSecretPassword123!',
      );
      await mockSession.verifyOtp('123456');
      await mockSession.logout();

      final events = mockAudit.logs;
      expect(events.length, greaterThanOrEqualTo(3));

      final actions = events.map((e) => e.action).toList();
      expect(actions.contains('DOCTOR_LOGIN_ATTEMPT'), isTrue);
      expect(actions.contains('DOCTOR_AUTH_SUCCESS'), isTrue);
      expect(actions.contains('DOCTOR_LOGOUT'), isTrue);

      // Verify ZERO passwords or OTPs leaked into audit log entries or metadata
      for (final event in events) {
        expect(event.actorType, equals('DOCTOR'));
        final metaString = event.metadata.toString();
        expect(metaString.contains('SuperSecretPassword123!'), isFalse);
        expect(metaString.contains('123456'), isFalse);
      }
    });

    test('17. Failed login attempt records DOCTOR_AUTH_FAILURE audit log', () async {
      await mockSession.validateCredentials(
        doctorCode: 'INVALID',
        password: 'WRONG',
      );

      final events = mockAudit.logs;
      expect(events.any((e) => e.action == 'DOCTOR_AUTH_FAILURE'), isTrue);
    });
  });

  group('AAYUSATHI Phase D3: Localization & Responsive Workstation', () {
    test('18. Localization provides D3 messages in English, Hindi, and Marathi', () {
      final en = DoctorLocalizations.forLocale(KioskLocale.english);
      final hi = DoctorLocalizations.forLocale(KioskLocale.hindi);
      final mr = DoctorLocalizations.forLocale(KioskLocale.marathi);

      expect(en.inactiveDoctorError, isNotEmpty);
      expect(hi.inactiveDoctorError, isNotEmpty);
      expect(mr.inactiveDoctorError, isNotEmpty);

      expect(en.serverConnectionError, isNotEmpty);
      expect(hi.serverConnectionError, isNotEmpty);
      expect(mr.serverConnectionError, isNotEmpty);

      expect(en.authFailedError, isNotEmpty);
      expect(hi.authFailedError, isNotEmpty);
      expect(mr.authFailedError, isNotEmpty);
    });

    testWidgets('19. Doctor Login renders cleanly at standard workstation resolutions',
        (WidgetTester tester) async {
      final resolutions = [
        const Size(1366, 768),
        const Size(1440, 900),
        const Size(1920, 1080),
      ];

      for (final size in resolutions) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(buildTestableWidget(const DoctorLoginScreen()));
        await tester.pumpAndSettle();

        expect(find.byType(DoctorLoginScreen), findsOneWidget);
        expect(find.text('DOCTOR LOGIN'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('20. Doctor OTP renders cleanly with privacy-masked phone at workstation resolutions',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await mockSession.validateCredentials(
        doctorCode: 'DOC-101',
        password: 'Password123',
      );

      await tester.pumpWidget(buildTestableWidget(const DoctorOtpScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(DoctorOtpScreen), findsOneWidget);
      expect(find.textContaining('******3210'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('21. WindowsDoctorOtpService handles workstation SMS dispatch abstraction safely', () async {
      final otpService = WindowsDoctorOtpService();
      final sent = await otpService.sendOtp(
        registeredPhone: '+919876543210',
        doctorId: 'DOC-101',
      );
      expect(sent, isTrue);
      expect(otpService.pendingDoctorId, equals('DOC-101'));
      expect(otpService.pendingPhone, equals('+919876543210'));

      final verified = await otpService.verifyOtp(
        otp: '123456',
        doctorId: 'DOC-101',
      );
      expect(verified, isTrue);

      final invalid = await otpService.verifyOtp(
        otp: '000000',
        doctorId: 'DOC-101',
      );
      expect(invalid, isFalse);
    });
  });
}

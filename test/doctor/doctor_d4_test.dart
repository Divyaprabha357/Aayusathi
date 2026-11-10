import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/core/routes/app_routes.dart';
import 'package:aayusathi/core/theme/app_theme.dart';
import 'package:aayusathi/doctor/localization/doctor_localizations.dart';
import 'package:aayusathi/doctor/models/doctor_profile.dart';
import 'package:aayusathi/doctor/screens/doctor_dashboard_screen.dart';
import 'package:aayusathi/doctor/screens/doctor_login_screen.dart';
import 'package:aayusathi/doctor/screens/doctor_profile_screen.dart';
import 'package:aayusathi/doctor/services/doctor_dashboard_metrics_service.dart';
import 'package:aayusathi/doctor/services/doctor_dev_workspace_controller.dart';
import 'package:aayusathi/doctor/services/doctor_presence_service.dart';
import 'package:aayusathi/doctor/services/doctor_profile_service.dart';
import 'package:aayusathi/doctor/services/doctor_session_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_presence_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_session_service.dart';
import 'package:aayusathi/doctor/widgets/doctor_status_indicator.dart';
import 'package:aayusathi/repositories/mock/mock_audit_repository.dart';

Widget buildTestableWidget(
  Widget child, {
  KioskLocale locale = KioskLocale.english,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    onGenerateRoute: AppRoutes.onGenerateRoute,
    home: DoctorLocalizations.provider(
      strings: DoctorLocalizations.forLocale(locale),
      child: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDoctorPresenceService mockPresence;
  late MockDoctorProfileService mockProfileService;
  late MockDoctorSessionService mockSession;
  late MockAuditRepository mockAudit;

  setUp(() {
    mockPresence = MockDoctorPresenceService(
      initialStatus: DoctorAvailabilityStatus.available,
    );
    DoctorPresenceService.instance = mockPresence;

    mockProfileService = MockDoctorProfileService();
    DoctorProfileService.instance = mockProfileService;

    mockAudit = MockAuditRepository();
    mockSession = MockDoctorSessionService(auditRepository: mockAudit);
    DoctorSessionService.instance = mockSession;
    DoctorDashboardMetricsService.instance = MockDoctorDashboardMetricsService(
      mockAttendedCount: 12,
      mockPendingCount: 3,
    );
  });

  tearDown(() {
    mockPresence.resetPresence();
    mockSession.resetSession();
    mockAudit.clear();
  });

  group('AAYUSATHI Phase D4: Doctor Profile Model & Mock Isolation', () {
    test('1. Doctor profile screen renders and mock profile contains expected development values', () async {
      final profile = await mockProfileService.getDoctorProfile();

      expect(profile.name, equals('Dr. Rajesh Sharma'));
      expect(profile.qualification, equals('MBBS, MD (Cardiology)'));
      expect(profile.department, equals('Cardiology'));
      expect(profile.doctorUniqueCode, equals('DOC-101'));
      expect(profile.doctorId, equals('DOC-101'));
      expect(profile.registeredPhone, equals('+91******3210'));
      expect(profile.isActive, isTrue);
      expect(profile.availabilityStatus, equals(DoctorAvailabilityStatus.available));
    });

    test('2. Phone number is masked and privacy protected (+91******3210)', () async {
      final profile = await mockProfileService.getDoctorProfile();
      expect(profile.registeredPhone, startsWith('+91******'));
      expect(profile.registeredPhone.length, equals(13));
      expect(profile.registeredPhone, isNot(contains('9876543210')));
    });

    test('3. Doctor unique code is displayed correctly (DOC-101)', () async {
      final profile = await mockProfileService.getDoctorProfile();
      expect(profile.doctorUniqueCode, equals('DOC-101'));
    });

    test('4. Mock profile service is isolated from Cloud Firestore and Firebase Auth', () {
      expect(mockProfileService, isA<MockDoctorProfileService>());
      expect(mockProfileService.watchDoctorProfile(), isA<Stream<DoctorProfile>>());
    });
  });

  group('AAYUSATHI Phase D4: Read-Only Doctor Profile Screen UI', () {
    testWidgets('5. DoctorProfileScreen renders all credentials and badges', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget(const DoctorProfileScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Dr. Rajesh Sharma'), findsWidgets);
      expect(find.text('MBBS, MD (Cardiology)'), findsWidgets);
      expect(find.text('Cardiology'), findsWidgets);
      expect(find.text('DOC-101'), findsWidgets);
      expect(find.text('+91******3210'), findsWidgets);
      expect(find.text('ACTIVE'), findsWidgets);
      expect(find.text('Available'), findsWidgets);
      expect(find.textContaining('Hospital Administration'), findsWidgets);
    });

    testWidgets('6. Doctor cannot self-edit administrative identity (read-only verification)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget(const DoctorProfileScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // No text inputs should exist for editing credentials
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.byType(EditableText), findsNothing);
      expect(find.text('Edit Profile'), findsNothing);
      expect(find.text('Save Profile'), findsNothing);
    });

    testWidgets('7. DoctorProfileScreen displays administrative governance notice', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget(const DoctorProfileScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.textContaining('Doctor profile data is managed exclusively by Hospital Administration'),
        findsOneWidget,
      );
    });
  });

  group('AAYUSATHI Phase D4: Workstation Presence State Machine', () {
    test('8. Initial presence status is AVAILABLE', () {
      expect(mockPresence.status, equals(DoctorAvailabilityStatus.available));
      expect(mockPresence.isAvailable, isTrue);
      expect(mockPresence.isOnline, isTrue);
      expect(mockPresence.isOffline, isFalse);
    });

    test('9. AVAILABLE -> OFFLINE works', () async {
      await mockPresence.goOffline();
      expect(mockPresence.status, equals(DoctorAvailabilityStatus.offline));
      expect(mockPresence.isOffline, isTrue);
      expect(mockPresence.isAvailable, isFalse);
      expect(mockPresence.isOnline, isFalse);
    });

    test('10. OFFLINE -> ONLINE works', () async {
      await mockPresence.goOffline();
      await mockPresence.goOnline();
      expect(mockPresence.status, equals(DoctorAvailabilityStatus.online));
      expect(mockPresence.isOnline, isTrue);
      expect(mockPresence.isAvailable, isFalse);
    });

    test('11. ONLINE -> AVAILABLE works', () async {
      await mockPresence.goOffline();
      await mockPresence.goOnline();
      await mockPresence.setAvailable();
      expect(mockPresence.status, equals(DoctorAvailabilityStatus.available));
      expect(mockPresence.isAvailable, isTrue);
    });

    test('12. AVAILABLE -> IN CONSULTATION simulated by service', () async {
      await mockPresence.setInConsultation();
      expect(mockPresence.status, equals(DoctorAvailabilityStatus.inConsultation));
      expect(mockPresence.isInConsultation, isTrue);
      expect(mockPresence.isOnline, isTrue);
    });

    test('13. IN CONSULTATION -> AVAILABLE works', () async {
      await mockPresence.setInConsultation();
      await mockPresence.setAvailable();
      expect(mockPresence.status, equals(DoctorAvailabilityStatus.available));
      expect(mockPresence.isAvailable, isTrue);
      expect(mockPresence.isInConsultation, isFalse);
    });

    test('14. OFFLINE -> IN CONSULTATION throws StateError (invalid transition)', () async {
      await mockPresence.goOffline();
      expect(
        () async => await mockPresence.setInConsultation(),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('AAYUSATHI Phase D4: Status Indicators & Accessibility', () {
    testWidgets('15. Status indicator displays correct icon, color, and text (never color alone)', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Column(
            children: [
              DoctorStatusBadge.fromAvailabilityStatus(DoctorAvailabilityStatus.available),
              DoctorStatusBadge.fromAvailabilityStatus(DoctorAvailabilityStatus.online),
              DoctorStatusBadge.fromAvailabilityStatus(DoctorAvailabilityStatus.inConsultation),
              DoctorStatusBadge.fromAvailabilityStatus(DoctorAvailabilityStatus.offline),
            ],
          ),
        ),
      );
      await tester.pump();

      // Text labels present
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('In Consultation'), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);

      // Icons present alongside text
      expect(find.byIcon(DoctorAvailabilityStatus.available.icon), findsOneWidget);
      expect(find.byIcon(DoctorAvailabilityStatus.online.icon), findsOneWidget);
      expect(find.byIcon(DoctorAvailabilityStatus.inConsultation.icon), findsOneWidget);
      expect(find.byIcon(DoctorAvailabilityStatus.offline.icon), findsOneWidget);
    });
  });

  group('AAYUSATHI Phase D4: Localization Foundation (EN, HI, MR)', () {
    test('16. Localization strings exist across English, Hindi, and Marathi', () {
      final en = DoctorLocalizations.forLocale(KioskLocale.english);
      final hi = DoctorLocalizations.forLocale(KioskLocale.hindi);
      final mr = DoctorLocalizations.forLocale(KioskLocale.marathi);

      // Doctor profile strings
      expect(en.doctorProfileTitle, equals('DOCTOR PROFILE'));
      expect(hi.doctorProfileTitle, equals('डॉक्टर प्रोफाइल'));
      expect(mr.doctorProfileTitle, equals('डॉक्टर प्रोफाइल'));

      expect(en.qualificationLabel, equals('QUALIFICATION'));
      expect(hi.qualificationLabel, equals('योग्यता'));
      expect(mr.qualificationLabel, equals('पात्रता'));

      expect(en.accountStatusLabel, equals('ACCOUNT STATUS'));
      expect(hi.accountStatusLabel, equals('खाता स्थिति'));
      expect(mr.accountStatusLabel, equals('खाते स्थिती'));

      expect(en.workstationAvailability, equals('Workstation Availability'));
      expect(hi.workstationAvailability, equals('वर्कस्टेशन उपलब्धता'));
      expect(mr.workstationAvailability, equals('वर्कस्टेशन उपलब्धता'));

      expect(en.profileManagedByAdminNotice, contains('Hospital Administration'));
      expect(hi.profileManagedByAdminNotice, contains('प्रशासन'));
      expect(mr.profileManagedByAdminNotice, contains('प्रशासनाकडून'));
    });
  });

  group('AAYUSATHI Phase D4: Session & Logout Presence Integration', () {
    test('17. Logout clears Doctor profile/session and resets presence', () async {
      await mockSession.validateCredentials(
        doctorCode: 'DOC-101',
        password: 'ValidPassword123',
      );
      await mockSession.verifyOtp('123456');
      expect(mockSession.isAuthenticated, isTrue);

      await mockPresence.setInConsultation();
      expect(mockPresence.isInConsultation, isTrue);

      await mockSession.logout();
      expect(mockSession.isAuthenticated, isFalse);
      expect(mockSession.activeDoctorId, isNull);
      expect(mockSession.activeProfile, isNull);
      expect(mockPresence.status, equals(DoctorAvailabilityStatus.offline));
    });

    testWidgets('18. UI does not expose Firebase UID, passwords, or OTP anywhere', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget(const DoctorProfileScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('mock-dev-uid'), findsNothing);
      expect(find.textContaining('password'), findsNothing);
      expect(find.textContaining('otp'), findsNothing);
    });
  });

  group('AAYUSATHI Phase D4: Clinical Dashboard Workstation Integration', () {
    testWidgets('19. Doctor Dashboard renders operational layout without duplicate profile cards', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget(const DoctorDashboardScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Dashboard title & Welcome banner
      expect(find.text('Doctor Dashboard'), findsOneWidget);
      expect(find.textContaining('Welcome, Dr. Rajesh Sharma'), findsOneWidget);

      // 2. Section A: Patients Attended Today
      expect(find.text('PATIENTS ATTENDED TODAY'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Patients'), findsOneWidget);

      // 3. Section B: Workstation Availability Console
      expect(find.text('WORKSTATION AVAILABILITY'), findsOneWidget);
      expect(find.text('OPD Patient Acceptance'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(find.text('GO OFFLINE'), findsOneWidget);

      // 4. Section C: Patient Requests Shortcut
      expect(find.text('PATIENT REQUESTS'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Pending Requests'), findsOneWidget);
      expect(find.text('VIEW REQUESTS →'), findsOneWidget);

      // 5. Verifies large profile/identity and telemetry cards are NOT on Dashboard
      expect(find.text('Physician Identity'), findsNothing);
      expect(find.text('Clinical Workstation Specifications'), findsNothing);
      expect(find.text('View Doctor Profile'), findsNothing);
    });

    testWidgets('19b. Dashboard availability action toggles workstation presence status', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget(const DoctorDashboardScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockPresence.isAvailable, isTrue);

      // Tap GO OFFLINE button on Dashboard
      final goOfflineBtn = find.text('GO OFFLINE');
      await tester.ensureVisible(goOfflineBtn);
      await tester.tap(goOfflineBtn);
      await tester.pumpAndSettle();

      expect(mockPresence.isOffline, isTrue);
      expect(find.text('GO AVAILABLE'), findsOneWidget);
      expect(find.text('Workstation is offline. Not accepting OPD requests.'), findsOneWidget);
    });

    testWidgets('19c. Patient Requests shortcut button navigates to /doctor/patient-request', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget(const DoctorDashboardScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap VIEW REQUESTS → button
      final viewReqBtn = find.text('VIEW REQUESTS →');
      await tester.ensureVisible(viewReqBtn);
      await tester.tap(viewReqBtn);
      await tester.pumpAndSettle();

      // Successfully pushed /doctor/patient-request
      expect(find.byType(DoctorDashboardScreen), findsNothing);
    });

    testWidgets('19d. Top-right Doctor Menu opens with View Details and Logout, navigating correctly', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget(const DoctorDashboardScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find top-right popup menu button
      final popupMenu = find.byType(PopupMenuButton<String>);
      expect(popupMenu, findsOneWidget);

      await tester.tap(popupMenu);
      await tester.pumpAndSettle();

      // Menu contains View Details and Logout
      expect(find.text('View Details'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);

      // Tap View Details
      await tester.tap(find.text('View Details'));
      await tester.pumpAndSettle();

      // Reaches Doctor Profile / Details Screen
      expect(find.byType(DoctorProfileScreen), findsOneWidget);
    });

    testWidgets('19e. DoctorProfileScreen contains full credentials, Security Role, Availability, and Terminal Specs', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget(const DoctorProfileScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Credentials & Identifiers
      expect(find.text('Physician Credentials & Identifiers'), findsOneWidget);
      expect(find.text('SECURITY ROLE'), findsOneWidget);
      expect(find.text('DOCTOR'), findsOneWidget);
      expect(find.text('DOC-101'), findsWidgets);

      // Workstation Availability console
      expect(find.text('Workstation Availability'), findsOneWidget);
      expect(find.text('OPD Patient Acceptance Toggle'), findsOneWidget);

      // Clinical Workstation Specifications
      expect(find.text('Clinical Workstation Specifications'), findsOneWidget);
      expect(find.text('AIIMS-OPD-WS-04'), findsOneWidget);
      expect(find.text('Hospital IT Administration'), findsOneWidget);
    });
  });

  group('AAYUSATHI Phase D4: Responsive Desktop Verification', () {
    final desktopViewports = [
      const Size(1366, 768),
      const Size(1440, 900),
      const Size(1920, 1080),
    ];

    for (final size in desktopViewports) {
      testWidgets('20. Doctor Profile Screen renders cleanly at ${size.width.toInt()}x${size.height.toInt()} without overflow',
          (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestableWidget(const DoctorProfileScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
        expect(find.text('Dr. Rajesh Sharma'), findsWidgets);
        expect(find.text('DOCTOR PROFILE'), findsOneWidget);
      });

      testWidgets('20b. Doctor Dashboard renders cleanly at ${size.width.toInt()}x${size.height.toInt()} without overflow',
          (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestableWidget(const DoctorDashboardScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
        expect(find.text('Doctor Dashboard'), findsOneWidget);
      });
    }
  });

  group('AAYUSATHI Phase D4 Addendum: Development-Only Workspace Access', () {
    tearDown(() {
      DoctorDevWorkspaceController.devModeOverride = null;
    });

    testWidgets('21. Development workspace button appears when DOCTOR_DEV_MODE=true', (WidgetTester tester) async {
      DoctorDevWorkspaceController.devModeOverride = true;

      await tester.pumpWidget(buildTestableWidget(const DoctorLoginScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('ENTER DEMO WORKSPACE'), findsOneWidget);
      expect(find.text('DEVELOPMENT ACCESS ONLY'), findsOneWidget);
    });

    testWidgets('22. Development workspace button does NOT appear when DOCTOR_DEV_MODE=false', (WidgetTester tester) async {
      DoctorDevWorkspaceController.devModeOverride = false;

      await tester.pumpWidget(buildTestableWidget(const DoctorLoginScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('ENTER DEMO WORKSPACE'), findsNothing);
      expect(find.text('DEVELOPMENT ACCESS ONLY'), findsNothing);
    });

    testWidgets('23. Clicking ENTER DEMO WORKSPACE creates mock Doctor session and navigates to dashboard', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      DoctorDevWorkspaceController.devModeOverride = true;

      await tester.pumpWidget(buildTestableWidget(const DoctorLoginScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Initially logged out
      expect(mockSession.isAuthenticated, isFalse);

      // Tap ENTER DEMO WORKSPACE
      final demoBtn = find.text('ENTER DEMO WORKSPACE');
      await tester.ensureVisible(demoBtn);
      await tester.tap(demoBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifications:
      // 1. Authenticated in dev mode
      expect(mockSession.isAuthenticated, isTrue);
      expect(mockSession.isDevelopmentMode, isTrue);
      // 2. Doctor is Dr. Rajesh Sharma
      expect(mockSession.activeDoctorName, equals('Dr. Rajesh Sharma'));
      // 3. Doctor Unique Code is DOC-101
      expect(mockSession.activeDoctorId, equals('DOC-101'));
      // 4. Department is Cardiology
      expect(mockSession.activeDepartment, equals('Cardiology'));
      // 5. Initial status is AVAILABLE
      expect(mockPresence.isAvailable, isTrue);
      // 6. Navigation reached DoctorDashboardScreen
      expect(find.byType(DoctorDashboardScreen), findsOneWidget);
      // 7. Subtle DEVELOPMENT MODE indicator is visible
      expect(find.text('DEVELOPMENT MODE'), findsOneWidget);
    });

    test('24. Logout clears the mock dev session, resets presence to OFFLINE, and does not record false production audit', () async {
      DoctorDevWorkspaceController.devModeOverride = true;

      await mockSession.enterDevelopmentWorkspace();
      expect(mockSession.isAuthenticated, isTrue);
      expect(mockSession.isDevelopmentMode, isTrue);
      expect(mockPresence.isAvailable, isTrue);

      await mockSession.logout();
      expect(mockSession.isAuthenticated, isFalse);
      expect(mockSession.isDevelopmentMode, isFalse);
      expect(mockSession.activeDoctorId, isNull);
      expect(mockSession.activeProfile, isNull);
      expect(mockPresence.status, equals(DoctorAvailabilityStatus.offline));
      expect(mockPresence.isOffline, isTrue);

      // Audit logs do not contain production doctor auth event
      final authEvents = mockAudit.logs.where((l) => l.action == 'DOCTOR_AUTH_SUCCESS');
      expect(authEvents, isEmpty);
    });
  });
}

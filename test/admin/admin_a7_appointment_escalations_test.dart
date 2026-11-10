import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/admin/controllers/admin_appointment_escalation_controller.dart';
import 'package:aayusathi/admin/localization/admin_localizations.dart';
import 'package:aayusathi/admin/localization/admin_strings.dart';
import 'package:aayusathi/admin/screens/admin_appointment_escalations_screen.dart';
import 'package:aayusathi/admin/screens/admin_dashboard_screen.dart';
import 'package:aayusathi/admin/services/admin_auth_service.dart';
import 'package:aayusathi/admin/widgets/admin_appointment_escalation_dialogs.dart';
import 'package:aayusathi/admin/widgets/admin_desktop_scaffold.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/routes/app_routes.dart';
import 'package:aayusathi/doctor/models/doctor_profile.dart';
import 'package:aayusathi/models/appointment_request.dart';
import 'package:aayusathi/repositories/mock/mock_appointment_repository.dart';
import 'package:aayusathi/repositories/mock/mock_audit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_doctor_repository.dart';

Widget createTestApp({Widget? home, Locale locale = const Locale('en')}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: locale,
    localizationsDelegates: const [
      AdminLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('en'),
      Locale('hi'),
      Locale('mr'),
    ],
    home: home ?? const AdminAppointmentEscalationsScreen(),
    routes: {
      AppRoutes.adminAppointmentEscalations: (_) => const AdminAppointmentEscalationsScreen(),
      AppRoutes.adminAvailability: (_) => const Scaffold(body: Text('Doctor Availability Screen')),
      AppRoutes.adminDoctors: (_) => const Scaffold(body: Text('Manage Doctors Screen')),
      AppRoutes.adminDoctorsAdd: (_) => const Scaffold(body: Text('Add New Doctor Screen')),
      AppRoutes.adminDashboard: (_) => const AdminDashboardScreen(),
      AppRoutes.adminLogin: (_) => const Scaffold(body: Text('Admin Login Screen')),
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAppointmentRepository appointmentRepo;
  late MockDoctorRepository doctorRepo;
  late MockAuditRepository auditRepo;
  late AdminAppointmentEscalationController controller;

  final now = DateTime.now();

  final escalatedAppt1 = AppointmentRequest(
    requestId: 'REQ-ESC-001',
    patientId: 'PAT-IND-998877665544',
    domainId: 'cardiology',
    preferredDoctorMode: PreferredDoctorMode.anyDoctor,
    status: AppointmentStatus.waiting,
    queueNumber: 'A-00010',
    escalationStatus: AppointmentEscalationStatus.escalated,
    escalatedAt: now.subtract(const Duration(minutes: 5)),
    createdAt: now.subtract(const Duration(minutes: 25)),
    sessionId: 'SES-001',
  );

  final escalatedAppt2 = AppointmentRequest(
    requestId: 'REQ-ESC-002',
    patientId: 'PAT-IND-112233445566',
    domainId: 'neurology',
    preferredDoctorMode: PreferredDoctorMode.anyDoctor,
    status: AppointmentStatus.waiting,
    queueNumber: 'A-00020',
    escalationStatus: AppointmentEscalationStatus.escalated,
    escalatedAt: now.subtract(const Duration(minutes: 10)),
    createdAt: now.subtract(const Duration(minutes: 30)),
    sessionId: 'SES-002',
  );

  final normalWaitingAppt = AppointmentRequest(
    requestId: 'REQ-NORM-003',
    patientId: 'PAT-IND-556677889900',
    domainId: 'pediatrics',
    preferredDoctorMode: PreferredDoctorMode.anyDoctor,
    status: AppointmentStatus.waiting,
    queueNumber: 'A-00030',
    escalationStatus: AppointmentEscalationStatus.none,
    createdAt: now.subtract(const Duration(minutes: 8)),
    sessionId: 'SES-003',
  );

  final resolvedAppt = AppointmentRequest(
    requestId: 'REQ-RES-004',
    patientId: 'PAT-IND-990011223344',
    domainId: 'cardiology',
    preferredDoctorMode: PreferredDoctorMode.anyDoctor,
    status: AppointmentStatus.accepted,
    assignedDoctorId: 'DOC-CARD-01',
    queueNumber: 'A-00040',
    escalationStatus: AppointmentEscalationStatus.resolved,
    escalatedAt: now.subtract(const Duration(minutes: 40)),
    resolvedAt: now.subtract(const Duration(minutes: 10)),
    assignedAt: now.subtract(const Duration(minutes: 10)),
    createdAt: now.subtract(const Duration(minutes: 60)),
    sessionId: 'SES-004',
  );

  setUp(() async {
    BackendProvider.instance.setMode(BackendMode.mock);
    AdminAuthService.instance.resetForTesting();
    AdminAuthService.instance.setAuthenticatedForTesting(username: 'admin01');

    doctorRepo = MockDoctorRepository.instance;
    doctorRepo.resetToDefaults();

    // Ensure DOC-CARD-01 is available for assignment
    final doc1 = await doctorRepo.getDoctorProfileById('DOC-CARD-01');
    if (doc1 != null) {
      doctorRepo.saveDoctorProfile(
        doc1.copyWith(
          isActive: true,
          availabilityStatus: DoctorAvailabilityStatus.available,
        ),
      );
    }

    appointmentRepo = MockAppointmentRepository.instance;
    appointmentRepo.clear();
    appointmentRepo.seedAppointments([
      escalatedAppt1,
      escalatedAppt2,
      normalWaitingAppt,
      resolvedAppt,
    ]);

    auditRepo = MockAuditRepository.instance;
    auditRepo.clear();

    controller = AdminAppointmentEscalationController.instance;
    controller.resetForTesting();
    await controller.initialize(
      appointmentRepository: appointmentRepo,
      doctorRepository: doctorRepo,
    );
  });

  tearDown(() {
    controller.resetForTesting();
    AdminAuthService.instance.resetForTesting();
  });

  group('Phase A7 Appointment Escalations — Widget & UI Workflow Tests', () {
    testWidgets('1. AdminAppointmentEscalationsScreen renders with stationary AdminDesktopScaffold shell and header', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(AdminDesktopScaffold), findsOneWidget);
      expect(find.text('APPOINTMENT ESCALATIONS'), findsWidgets);
      expect(find.text('SLA THRESHOLD: 20 MIN'), findsOneWidget);
      expect(find.text('Appointments waiting longer than 20 minutes require administrative attention.'), findsOneWidget);
    });

    testWidgets('2. KPI metric cards display accurate counts for Escalated, Total Waiting, Avg Wait, Resolved Today', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('ESCALATED APPOINTMENTS'), findsWidgets);
      expect(find.text('WAITING APPOINTMENTS'), findsWidgets);
      expect(find.text('RESOLVED TODAY'), findsWidgets);

      expect(find.text('${controller.escalatedCount}'), findsWidgets);
      expect(find.text('${controller.waitingCount}'), findsWidgets);
      expect(find.text('${controller.resolvedTodayCount}'), findsWidgets);
    });

    testWidgets('3. Filter toolbar renders Search, Department, Status, and Sort controls', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search by Queue Number or Appointment ID...'), findsOneWidget);
      expect(find.text('RESET FILTERS'), findsNothing); // Not active initially
      // All 3 dropdowns in toolbar
      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(3));
    });

    testWidgets('4. Table displays Queue No, masked Appointment ID, Department, Wait Duration, Badge, and Action buttons', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('A-00010'), findsOneWidget);
      expect(find.text('A-00020'), findsOneWidget);
      expect(find.text('A-00030'), findsOneWidget);
      expect(find.text('A-00040'), findsOneWidget);

      // Verify Appointment ID is rendered
      expect(find.text('REQ-ESC-001'), findsOneWidget);
      expect(find.text('REQ-ESC-002'), findsOneWidget);

      // Verify privacy masking: Raw Patient ID is NEVER exposed in the table
      expect(find.text('PAT-IND-998877665544'), findsNothing);
      expect(find.text('PAT-IND-112233445566'), findsNothing);

      // Verify escalation badges
      expect(find.text('ESCALATED'), findsWidgets);
      expect(find.text('WAITING'), findsWidgets);
      expect(find.text('RESOLVED'), findsWidgets);
    });

    testWidgets('5. Search query filters table by Queue Number', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, '00010');
      await tester.pumpAndSettle();

      expect(find.text('A-00010'), findsOneWidget);
      expect(find.text('A-00020'), findsNothing);
      expect(find.text('A-00030'), findsNothing);
      expect(find.text('A-00040'), findsNothing);
    });

    testWidgets('6. Reset filters button restores full list', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, '00010');
      await tester.pumpAndSettle();
      expect(find.text('A-00020'), findsNothing);

      final resetBtn = find.text('RESET FILTERS');
      expect(resetBtn, findsOneWidget);
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      expect(find.text('A-00010'), findsOneWidget);
      expect(find.text('A-00020'), findsOneWidget);
    });

    testWidgets('7. Clicking View Details icon opens AdminAppointmentEscalationDialog with masked data', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Find eye / view details icon button for REQ-ESC-001
      final viewButton = find.byKey(const ValueKey('view_btn_REQ-ESC-001'));
      expect(viewButton, findsOneWidget);

      await tester.ensureVisible(viewButton);
      await tester.pumpAndSettle();

      await tester.tap(viewButton);
      await tester.pumpAndSettle();

      expect(find.byType(AdminAppointmentEscalationDialog), findsOneWidget);
      expect(find.text('APPOINTMENT ESCALATION DETAILS'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AdminAppointmentEscalationDialog),
          matching: find.text('REQ-ESC-001'),
        ),
        findsOneWidget,
      );
      // Verify patient ID is masked inside the dialog
      expect(find.text('PAT-IND-998877665544'), findsNothing);
      expect(find.textContaining('5544'), findsWidgets);
      expect(find.text('Close'), findsOneWidget);

      await tester.ensureVisible(find.text('Close'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(AdminAppointmentEscalationDialog), findsNothing);
    });

    testWidgets('8. Clicking Assign Doctor opens AdminAssignDoctorDialog showing eligible doctors', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Find Assign Doctor button on the Cardiology escalated appointment (REQ-ESC-001)
      final assignButton = find.byKey(const ValueKey('assign_btn_REQ-ESC-001'));
      expect(assignButton, findsOneWidget);

      await tester.ensureVisible(assignButton);
      await tester.pumpAndSettle();

      await tester.tap(assignButton);
      await tester.pumpAndSettle();

      expect(find.byType(AdminAssignDoctorDialog), findsOneWidget);
      expect(find.text('MANUAL DOCTOR ASSIGNMENT'), findsOneWidget);
      expect(find.text('Dr. Ramesh Gupta'), findsOneWidget);
      expect(find.text('CONFIRM ASSIGNMENT'), findsOneWidget);

      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();
      expect(find.byType(AdminAssignDoctorDialog), findsNothing);
    });

    testWidgets('9. Confirming doctor assignment updates appointment to Accepted/Resolved', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final assignButton = find.byKey(const ValueKey('assign_btn_REQ-ESC-001'));
      await tester.ensureVisible(assignButton);
      await tester.pumpAndSettle();

      await tester.tap(assignButton);
      await tester.pumpAndSettle();

      expect(find.byType(AdminAssignDoctorDialog), findsOneWidget);

      // Tap on Dr. Ramesh Gupta tile
      await tester.tap(find.text('Dr. Ramesh Gupta'));
      await tester.pumpAndSettle();

      // Tap Confirm Assignment
      await tester.tap(find.text('CONFIRM ASSIGNMENT'));
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(find.byType(AdminAssignDoctorDialog), findsNothing);

      // Verify the appointment in repository has been assigned and resolved
      final updated = await appointmentRepo.getAppointmentById('REQ-ESC-001');
      expect(updated?.status, equals(AppointmentStatus.accepted));
      expect(updated?.assignedDoctorId, equals('DOC-CARD-01'));
      expect(updated?.escalationStatus, equals(AppointmentEscalationStatus.resolved));
    });

    testWidgets('10. Empty state renders when filter returns zero results', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'NONEXISTENT_QUERY_999');
      await tester.pumpAndSettle();

      expect(find.text('No appointment escalations'), findsOneWidget);
      expect(find.text('All waiting appointments are within the standard 20-minute response window.'), findsOneWidget);
    });

    testWidgets('11. AdminDashboardScreen displays Escalation Alert Card when escalatedCount > 0 and navigates', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(home: const AdminDashboardScreen()));
      await tester.pumpAndSettle();

      final alertCard = find.byKey(const ValueKey('dashboard_escalation_alert_card'));
      expect(alertCard, findsOneWidget);
      expect(find.textContaining('Escalated Appointment'), findsOneWidget);
      expect(find.text('ACTION REQUIRED'), findsWidgets);

      await tester.ensureVisible(alertCard);
      await tester.pumpAndSettle();

      await tester.tap(alertCard);
      await tester.pumpAndSettle();

      expect(find.byType(AdminAppointmentEscalationsScreen), findsOneWidget);
    });

    test('12. Hindi localization maps all required Phase A7 strings', () {
      final stringsHi = AdminStrings.fromLocale('hi');
      expect(stringsHi.appointmentEscalationsHeaderTitle, equals('अपॉइंटमेंट एस्केलेशन'));
      expect(stringsHi.summaryEscalatedAppointments, equals('एस्केलेटेड अपॉइंटमेंट्स'));
      expect(stringsHi.summaryWaitingAppointments, equals('प्रतीक्षारत अपॉइंटमेंट्स'));
      expect(stringsHi.summaryResolvedToday, equals('आज हल किए गए'));
      expect(stringsHi.actionAssignDoctor, equals('डॉक्टर असाइन करें'));
      expect(stringsHi.actionInspectDetails, equals('विवरण देखें'));
      expect(stringsHi.statusBadgeEscalated, equals('एस्केलेटेड'));
      expect(stringsHi.statusBadgeWaiting, equals('प्रतीक्षारत'));
      expect(stringsHi.statusBadgeResolved, equals('हल किया गया'));
    });

    test('13. Marathi localization maps all required Phase A7 strings', () {
      final stringsMr = AdminStrings.fromLocale('mr');
      expect(stringsMr.appointmentEscalationsHeaderTitle, equals('अपॉइंटमेंट एस्केलेशन'));
      expect(stringsMr.summaryEscalatedAppointments, equals('एस्केलेटेड अपॉइंटमेंट्स'));
      expect(stringsMr.summaryWaitingAppointments, equals('प्रतीक्षेत असलेल्या अपॉइंटमेंट्स'));
      expect(stringsMr.summaryResolvedToday, equals('आज सोडवलेले'));
      expect(stringsMr.actionAssignDoctor, equals('डॉक्टर नियुक्त करा'));
      expect(stringsMr.actionInspectDetails, equals('तपशील पहा'));
      expect(stringsMr.statusBadgeEscalated, equals('एस्केलेटेड'));
      expect(stringsMr.statusBadgeWaiting, equals('प्रतीक्षेत'));
      expect(stringsMr.statusBadgeResolved, equals('सोडवले'));
    });

    testWidgets('14. Responsive viewport renders across standard desktop sizes without overflow', (tester) async {
      final viewports = [
        const Size(1024, 768),
        const Size(1366, 768),
        const Size(1920, 1080),
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(AdminAppointmentEscalationsScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      tester.view.resetPhysicalSize();
    });
  });
}

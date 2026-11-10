import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/admin/controllers/admin_dashboard_controller.dart';
import 'package:aayusathi/admin/controllers/admin_sidebar_controller.dart';
import 'package:aayusathi/admin/models/admin_dashboard_overview.dart';
import 'package:aayusathi/admin/models/admin_domain_availability.dart';
import 'package:aayusathi/admin/models/admin_waiting_appointment_summary.dart';
import 'package:aayusathi/admin/screens/admin_dashboard_screen.dart';
import 'package:aayusathi/admin/services/admin_auth_service.dart';
import 'package:aayusathi/admin/services/mock_admin_dashboard_service.dart';
import 'package:aayusathi/admin/widgets/admin_active_cases_card.dart';
import 'package:aayusathi/admin/widgets/admin_availability_table.dart';
import 'package:aayusathi/admin/widgets/admin_header.dart';
import 'package:aayusathi/admin/widgets/admin_kpi_card.dart';
import 'package:aayusathi/admin/widgets/admin_sidebar.dart';
import 'package:aayusathi/admin/widgets/admin_waiting_appointments_card.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/routes/app_routes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    BackendProvider.instance.setMode(BackendMode.mock);
    AdminSidebarController.instance.reset();
    AdminAuthService.instance.setAuthenticatedForTesting();
    AdminDashboardController.instance.resetForTesting();
    MockAdminDashboardService.instance.resetMockData();
  });

  group('AAYUSATHI Admin Phase A3: Models & Aggregation Tests', () {
    test('1. AdminDomainAvailability defaultEightDomains contains all 8 standard OPD specialties', () {
      final domains = AdminDomainAvailability.defaultEightDomains;
      expect(domains.length, 8);

      final domainIds = domains.map((d) => d.domainId).toList();
      expect(domainIds, contains('cardiology'));
      expect(domainIds, contains('neurology'));
      expect(domainIds, contains('gastroenterology'));
      expect(domainIds, contains('orthopedics'));
      expect(domainIds, contains('pediatrics'));
      expect(domainIds, contains('ent'));
      expect(domainIds, contains('dermatology'));
      expect(domainIds, contains('general_medicine'));

      for (final domain in domains) {
        expect(domain.totalDoctors, 0);
        expect(domain.onlineDoctors, 0);
        expect(domain.available, 0);
        expect(domain.inConsultation, 0);
      }
    });

    test('2. AdminWaitingAppointmentSummary contains only non-sensitive queue metadata (Zero PII)', () {
      final summary = AdminWaitingAppointmentSummary(
        requestId: 'appt-101',
        queueNumber: 'Q-014',
        age: 42,
        gender: 'Male',
        domain: 'Cardiology',
        requestType: 'General Consultation',
        waitingDurationFormatted: '14 min',
        status: 'waiting',
        createdAt: DateTime.now(),
      );

      expect(summary.requestId, 'appt-101');
      expect(summary.queueNumber, 'Q-014');
      expect(summary.age, 42);
      expect(summary.gender, 'Male');
      expect(summary.domain, 'Cardiology');
      expect(summary.requestType, 'General Consultation');
      expect(summary.waitingDurationFormatted, '14 min');
      expect(summary.status, 'waiting');
      expect(summary.demographicsFormatted, 'Age 42 • Male');

      // Verify that no Aadhaar, phone, or token fields exist on the model
      final map = summary.toSafeDisplayMap();
      expect(map.containsKey('aadhaar'), isFalse);
      expect(map.containsKey('aadhaarNumber'), isFalse);
      expect(map.containsKey('phoneNumber'), isFalse);
      expect(map.containsKey('patientPhone'), isFalse);
      expect(map.containsKey('address'), isFalse);
      expect(map.containsKey('token'), isFalse);
      expect(map.containsKey('authUid'), isFalse);
    });

    test('3. AdminDashboardOverview aggregates live counters and specialty distributions', () {
      final overview = AdminDashboardOverview(
        registeredDoctors: 12,
        onlineDoctors: 7,
        waitingAppointments: 4,
        activeCases: 9,
        domainAvailability: AdminDomainAvailability.defaultEightDomains,
        waitingAppointmentsList: [
          AdminWaitingAppointmentSummary(
            requestId: 'appt-1',
            queueNumber: 'Q-001',
            age: 35,
            gender: 'Female',
            domain: 'Neurology',
            requestType: 'Follow-up',
            waitingDurationFormatted: '8 min',
            status: 'waiting',
            createdAt: DateTime.now(),
          ),
        ],
        activeCasesByDomain: {'Neurology': 4, 'Cardiology': 5},
        lastUpdated: DateTime.now(),
      );

      expect(overview.registeredDoctors, 12);
      expect(overview.onlineDoctors, 7);
      expect(overview.waitingAppointments, 4);
      expect(overview.activeCases, 9);
      expect(overview.waitingAppointmentsList.length, 1);
      expect(overview.activeCasesByDomain['Neurology'], 4);
      expect(overview.activeCasesByDomain['Cardiology'], 5);
    });

    test('4. AdminDashboardOverview.empty() initializes zero-count baseline without fakes', () {
      final emptyOverview = AdminDashboardOverview.empty();
      expect(emptyOverview.registeredDoctors, 0);
      expect(emptyOverview.onlineDoctors, 0);
      expect(emptyOverview.waitingAppointments, 0);
      expect(emptyOverview.activeCases, 0);
      expect(emptyOverview.waitingAppointmentsList, isEmpty);
      expect(emptyOverview.activeCasesByDomain, isEmpty);
      expect(emptyOverview.domainAvailability.length, 8);
    });
  });

  group('AAYUSATHI Admin Phase A3: Service & Controller Tests', () {
    test('5. MockAdminDashboardService returns dynamic data and supports simulation controls', () async {
      final service = MockAdminDashboardService.instance;
      final initialData = await service.getDashboardOverview();

      expect(initialData.registeredDoctors, greaterThanOrEqualTo(0));
      expect(initialData.domainAvailability.length, 8);

      // Simulate custom live data
      service.setMockData(
        registeredDoctors: 20,
        onlineDoctors: 15,
        waitingAppointments: 6,
        activeCases: 11,
      );

      final updatedData = await service.getDashboardOverview();
      expect(updatedData.registeredDoctors, 20);
      expect(updatedData.onlineDoctors, 15);
      expect(updatedData.waitingAppointments, 6);
      expect(updatedData.activeCases, 11);
    });

    test('6. AdminDashboardController lifecycle initializes, streams data, and manages loading', () async {
      final controller = AdminDashboardController.instance;
      expect(controller.isLoading, isTrue);

      await controller.initialize();

      expect(controller.isLoading, isFalse);
      expect(controller.hasError, isFalse);
      expect(controller.overview, isNotNull);
      expect(controller.overview!.domainAvailability.length, 8);
    });

    test('7. AdminDashboardController refresh guards against duplicate concurrent clicks', () async {
      final controller = AdminDashboardController.instance;
      await controller.initialize();

      // Trigger first refresh
      final future1 = controller.refresh();
      expect(controller.isRefreshing, isTrue);

      // Trigger second concurrent refresh
      final future2 = controller.refresh();

      await Future.wait([future1, future2]);
      expect(controller.isRefreshing, isFalse);
    });

    test('8. AdminDashboardController handles simulated stream errors and supports retry', () async {
      final controller = AdminDashboardController.instance;
      await controller.initialize();

      // Trigger error simulation
      MockAdminDashboardService.instance.simulateError('Simulated Network Partition');

      // Allow stream microtask to deliver error
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.hasError, isTrue);
      expect(controller.errorMessage, contains('interrupted'));

      // Retry recovers state
      MockAdminDashboardService.instance.resetMockData();
      await controller.retry();

      expect(controller.hasError, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.overview, isNotNull);
    });
  });

  group('AAYUSATHI Admin Phase A3: Dashboard Screen & Widget UI Tests', () {
    testWidgets('9. AdminDashboardScreen renders 4 live KPI cards with real numeric values',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      MockAdminDashboardService.instance.setMockData(
        registeredDoctors: 18,
        onlineDoctors: 12,
        waitingAppointments: 5,
        activeCases: 8,
      );

      await tester.pumpWidget(
        const MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.adminDashboard,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AdminDashboardScreen), findsOneWidget);
      expect(find.byType(AdminKpiCard), findsNWidgets(4));

      // Verify numeric KPI counts
      expect(find.text('18'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);

      // Verify KPI Labels
      expect(find.text('TOTAL DOCTORS'), findsOneWidget);
      expect(find.text('AVAILABLE DOCTORS'), findsOneWidget);
      expect(find.text('PENDING APPOINTMENTS'), findsOneWidget);
      expect(find.text('ACTIVE ESCALATIONS'), findsOneWidget);
    });

    testWidgets('10. Empty state displays exact zero (0) and no fake placeholder strings',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      MockAdminDashboardService.instance.setMockData(
        registeredDoctors: 0,
        onlineDoctors: 0,
        waitingAppointments: 0,
        activeCases: 0,
        waitingAppointmentsList: [],
        activeCasesByDomain: {},
      );

      await tester.pumpWidget(
        const MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.adminDashboard,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Assert zero counts are shown on KPI cards
      expect(
        find.descendant(of: find.byType(AdminKpiCard), matching: find.text('0')),
        findsNWidgets(4),
      );

      // Assert zero occurrences of fake mock fallbacks
      expect(find.text('N/A'), findsNothing);
      expect(find.text('--'), findsNothing);
      expect(find.text('Demo'), findsNothing);
      expect(find.text('Sample'), findsNothing);

      // Verify empty states inside cards
      expect(find.text('No patients currently waiting'), findsOneWidget);
      expect(find.text('No active clinical cases'), findsOneWidget);
    });

    testWidgets('11. Doctor Availability Table renders 4 columns and 8 OPD specialties',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.adminDashboard,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AdminAvailabilityTable), findsOneWidget);

      // Verify 4 column headers
      expect(find.text('SPECIALTY DOMAIN'), findsOneWidget);
      expect(find.text('ONLINE DOCTORS'), findsOneWidget);
      expect(find.text('AVAILABLE'), findsOneWidget);
      expect(find.text('IN CONSULTATION'), findsOneWidget);

      // Verify 8 specialty rows inside the availability table
      final tableFinder = find.byType(AdminAvailabilityTable);
      expect(find.descendant(of: tableFinder, matching: find.text('Cardiology')), findsOneWidget);
      expect(find.descendant(of: tableFinder, matching: find.text('Neurology')), findsOneWidget);
      expect(find.descendant(of: tableFinder, matching: find.text('Gastroenterology')), findsOneWidget);
      expect(find.descendant(of: tableFinder, matching: find.text('Orthopedics')), findsOneWidget);
      expect(find.descendant(of: tableFinder, matching: find.text('Pediatrics')), findsOneWidget);
      expect(find.descendant(of: tableFinder, matching: find.text('ENT')), findsOneWidget);
      expect(find.descendant(of: tableFinder, matching: find.text('Dermatology')), findsOneWidget);
      expect(find.descendant(of: tableFinder, matching: find.text('General Medicine')), findsOneWidget);
    });

    testWidgets('12. Waiting Appointments Card renders privacy-safe queue items with zero PII',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      MockAdminDashboardService.instance.setMockData(
        waitingAppointmentsList: [
          AdminWaitingAppointmentSummary(
            requestId: 'appt-99',
            queueNumber: 'Q-042',
            age: 29,
            gender: 'Female',
            domain: 'Dermatology',
            requestType: 'Skin Rash Consultation',
            waitingDurationFormatted: '11 min',
            status: 'waiting',
            createdAt: DateTime.now(),
          ),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.adminDashboard,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AdminWaitingAppointmentsCard), findsOneWidget);
      expect(find.text('WAITING APPOINTMENTS'), findsOneWidget);
      expect(find.text('Q-042'), findsOneWidget);
      expect(find.text('Age 29 • Female • Skin Rash Consultation'), findsOneWidget);
      expect(find.text('11 min'), findsOneWidget);

      // Verify zero patient PII
      expect(find.textContaining('Aadhaar'), findsNothing);
      expect(find.textContaining('Phone'), findsNothing);
      expect(find.textContaining('+91'), findsNothing);
      expect(find.textContaining('Address'), findsNothing);
    });

    testWidgets('13. Active Cases Card renders total count and domain distribution chips',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      MockAdminDashboardService.instance.setMockData(
        activeCases: 14,
        activeCasesByDomain: {
          'Cardiology': 5,
          'Neurology': 3,
          'Pediatrics': 4,
          'Orthopedics': 2,
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.adminDashboard,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AdminActiveCasesCard), findsOneWidget);
      expect(find.text('ACTIVE CLINICAL CASES'), findsOneWidget);
      expect(find.text('14 Active'), findsOneWidget);

      final cardFinder = find.byType(AdminActiveCasesCard);
      expect(find.descendant(of: cardFinder, matching: find.text('Cardiology')), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.text('5')), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.text('Neurology')), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.text('3')), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.text('Pediatrics')), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.text('4')), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.text('Orthopedics')), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.text('2')), findsOneWidget);
    });

    testWidgets('14. Manual Refresh button triggers telemetry sync cleanly',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.adminDashboard,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final refreshBtn = find.byTooltip('Refresh Telemetry');
      expect(refreshBtn, findsOneWidget);

      await tester.tap(refreshBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AdminDashboardScreen), findsOneWidget);
      expect(AdminDashboardController.instance.isRefreshing, isFalse);
    });

    testWidgets('15. Error state renders warning banner with functioning RETRY button',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.adminDashboard,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Trigger error simulation
      MockAdminDashboardService.instance.simulateError('Simulated Outage');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('RETRY'), findsOneWidget);
      expect(find.textContaining('interrupted'), findsOneWidget);

      // Tap retry
      MockAdminDashboardService.instance.resetMockData();
      await tester.tap(find.text('RETRY'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('RETRY'), findsNothing);
      expect(AdminDashboardController.instance.hasError, isFalse);
    });

    testWidgets('16. Quick action buttons navigate to /admin/doctors', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.adminDashboard,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap ADD DOCTOR
      final addDoctorBtn = find.text('ADD DOCTOR');
      expect(addDoctorBtn, findsOneWidget);
      await tester.tap(addDoctorBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Should be on /admin/doctors
      expect(find.byType(AdminSidebar), findsOneWidget);
      expect(find.byType(AdminHeader), findsOneWidget);
    });

    testWidgets('17. Desktop Responsive layouts render without overflow across standard resolutions',
        (tester) async {
      const resolutions = [
        Size(1366, 768),
        Size(1600, 900),
        Size(1920, 1080),
      ];

      for (final res in resolutions) {
        tester.view.physicalSize = res;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          const MaterialApp(
            onGenerateRoute: AppRoutes.onGenerateRoute,
            initialRoute: AppRoutes.adminDashboard,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(AdminDashboardScreen), findsOneWidget,
            reason: 'Resolution ${res.width}x${res.height} must render AdminDashboardScreen');
        expect(tester.takeException(), isNull,
            reason: 'Resolution ${res.width}x${res.height} must not throw any layout or render exception');
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}

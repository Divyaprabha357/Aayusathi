import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/routes/app_routes.dart';
import 'package:aayusathi/doctor/screens/doctor_case_screen.dart';
import 'package:aayusathi/doctor/screens/doctor_consultation_screen.dart';
import 'package:aayusathi/doctor/screens/doctor_dashboard_screen.dart';
import 'package:aayusathi/doctor/screens/doctor_patient_request_screen.dart';
import 'package:aayusathi/doctor/screens/doctor_reports_screen.dart';
import 'package:aayusathi/doctor/services/doctor_presence_service.dart';
import 'package:aayusathi/doctor/services/doctor_session_service.dart';
import 'package:aayusathi/doctor/widgets/doctor_header.dart';
import 'package:aayusathi/doctor/widgets/doctor_sidebar.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    BackendProvider.instance.setMode(BackendMode.mock);
    MockCaseRepository.instance.resetToDefaults();
    MockClinicalVisitRepository.instance.resetToDefaults();
    DoctorSessionService.instance.resetSession();
    DoctorPresenceService.instance.resetPresence();
    DoctorSidebarController.instance.reset();
  });

  group('Phase D16 Final: Doctor Sidebar Stationarity & Zero-Shift Navigation Tests', () {
    testWidgets('1. Doctor routes render with zero slide transition and instant switching',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final navKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.doctorDashboard,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DoctorDashboardScreen), findsOneWidget);
      expect(find.byType(DoctorSidebar), findsOneWidget);
      expect(find.byType(DoctorHeader), findsOneWidget);

      // Verify initial sidebar position
      final initialSidebarRect = tester.getRect(find.byType(DoctorSidebar));
      expect(initialSidebarRect.left, equals(0.0));
      expect(initialSidebarRect.width, equals(250.0));

      final initialHeaderRect = tester.getRect(find.byType(DoctorHeader));
      expect(initialHeaderRect.top, equals(0.0));
      expect(initialHeaderRect.left, equals(0.0));

      // Navigate to Cases & Visits via Navigator
      navKey.currentState!.pushReplacementNamed(AppRoutes.doctorCase);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(DoctorCaseScreen), findsOneWidget);
      expect(find.byType(DoctorSidebar), findsOneWidget);

      final caseSidebarRect = tester.getRect(find.byType(DoctorSidebar));
      expect(caseSidebarRect.left, equals(0.0));
      expect(caseSidebarRect.width, equals(250.0));

      final caseHeaderRect = tester.getRect(find.byType(DoctorHeader));
      expect(caseHeaderRect.top, equals(0.0));
      expect(caseHeaderRect.left, equals(0.0));

      // Navigate to Reports & Diagnostics
      navKey.currentState!.pushReplacementNamed(AppRoutes.doctorReports);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(DoctorReportsScreen), findsOneWidget);

      final reportsSidebarRect = tester.getRect(find.byType(DoctorSidebar));
      expect(reportsSidebarRect.left, equals(0.0));
      expect(reportsSidebarRect.width, equals(250.0));

      // Navigate to Patient Requests
      navKey.currentState!.pushReplacementNamed(AppRoutes.doctorPatientRequest);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(DoctorPatientRequestScreen), findsOneWidget);

      final requestsSidebarRect = tester.getRect(find.byType(DoctorSidebar));
      expect(requestsSidebarRect.left, equals(0.0));
      expect(requestsSidebarRect.width, equals(250.0));

      // Navigate to Consultation
      navKey.currentState!.pushReplacementNamed(AppRoutes.doctorConsultation);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(DoctorConsultationScreen), findsOneWidget);

      final consultSidebarRect = tester.getRect(find.byType(DoctorSidebar));
      expect(consultSidebarRect.left, equals(0.0));
      expect(consultSidebarRect.width, equals(250.0));
    });

    testWidgets('2. Clicking sidebar items switches pages with stationary sidebar and header',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.doctorDashboard,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DoctorDashboardScreen), findsOneWidget);

      final initialSidebarRect = tester.getRect(find.byType(DoctorSidebar));
      final initialHeaderRect = tester.getRect(find.byType(DoctorHeader));

      // Tap "Cases & Visits" sidebar item
      final casesItem = find.text('Cases & Visits');
      expect(casesItem, findsOneWidget);
      await tester.tap(casesItem);
      await tester.pumpAndSettle();

      expect(find.byType(DoctorCaseScreen), findsOneWidget);
      expect(find.byType(DoctorDashboardScreen), findsNothing);

      final caseSidebarRect = tester.getRect(find.byType(DoctorSidebar));
      final caseHeaderRect = tester.getRect(find.byType(DoctorHeader));

      // Sidebar and Header must be 100% stationary
      expect(caseSidebarRect.left, equals(initialSidebarRect.left));
      expect(caseSidebarRect.width, equals(initialSidebarRect.width));
      expect(caseHeaderRect.top, equals(initialHeaderRect.top));
      expect(caseHeaderRect.left, equals(initialHeaderRect.left));

      // Tap "Reports & Diagnostics" sidebar item
      final reportsItem = find.text('Reports & Diagnostics');
      expect(reportsItem, findsOneWidget);
      await tester.tap(reportsItem);
      await tester.pumpAndSettle();

      expect(find.byType(DoctorReportsScreen), findsOneWidget);

      final reportsSidebarRect = tester.getRect(find.byType(DoctorSidebar));
      expect(reportsSidebarRect.left, equals(initialSidebarRect.left));
      expect(reportsSidebarRect.width, equals(initialSidebarRect.width));

      // Tap "Dashboard" sidebar item
      final dashboardItem = find.text('Dashboard');
      expect(dashboardItem, findsOneWidget);
      await tester.tap(dashboardItem);
      await tester.pumpAndSettle();

      expect(find.byType(DoctorDashboardScreen), findsOneWidget);

      final finalSidebarRect = tester.getRect(find.byType(DoctorSidebar));
      expect(finalSidebarRect.left, equals(initialSidebarRect.left));
      expect(finalSidebarRect.width, equals(initialSidebarRect.width));
    });

    testWidgets('3. 20 consecutive sidebar navigation switches maintain pixel-stationary geometry',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.doctorDashboard,
        ),
      );
      await tester.pumpAndSettle();

      final baselineSidebarRect = tester.getRect(find.byType(DoctorSidebar));
      final baselineHeaderRect = tester.getRect(find.byType(DoctorHeader));

      for (int i = 0; i < 20; i++) {
        final targetText = (i % 2 == 0) ? 'Cases & Visits' : 'Dashboard';
        final targetFinder = find.text(targetText);
        expect(targetFinder, findsOneWidget);

        await tester.tap(targetFinder);
        await tester.pumpAndSettle();

        final currentSidebarRect = tester.getRect(find.byType(DoctorSidebar));
        final currentHeaderRect = tester.getRect(find.byType(DoctorHeader));

        final sidebarDeltaX = (currentSidebarRect.left - baselineSidebarRect.left).abs();
        final sidebarDeltaW = (currentSidebarRect.width - baselineSidebarRect.width).abs();
        final headerDeltaY = (currentHeaderRect.top - baselineHeaderRect.top).abs();

        expect(sidebarDeltaX, equals(0.0), reason: 'Cycle $i: Sidebar X shifted by $sidebarDeltaX');
        expect(sidebarDeltaW, equals(0.0), reason: 'Cycle $i: Sidebar width shifted by $sidebarDeltaW');
        expect(headerDeltaY, equals(0.0), reason: 'Cycle $i: Header Y shifted by $headerDeltaY');
      }
    });

    testWidgets('4. Persistent sidebar collapse state is preserved across route navigation',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.doctorDashboard,
        ),
      );
      await tester.pumpAndSettle();

      expect(DoctorSidebarController.instance.isCollapsed, isFalse);
      expect(tester.getRect(find.byType(DoctorSidebar)).width, equals(250.0));

      // Collapse sidebar
      final collapseBtn = find.byTooltip('Collapse Sidebar');
      expect(collapseBtn, findsOneWidget);
      await tester.tap(collapseBtn);
      await tester.pumpAndSettle();

      expect(DoctorSidebarController.instance.isCollapsed, isTrue);
      expect(tester.getRect(find.byType(DoctorSidebar)).width, equals(76.0));

      // Navigate to Cases & Visits
      final navKey = tester.state<NavigatorState>(find.byType(Navigator));
      navKey.pushReplacementNamed(AppRoutes.doctorCase);
      await tester.pumpAndSettle();

      expect(find.byType(DoctorCaseScreen), findsOneWidget);
      // Width must remain 76.0 (collapsed)
      expect(tester.getRect(find.byType(DoctorSidebar)).width, equals(76.0));
      expect(DoctorSidebarController.instance.isCollapsed, isTrue);

      // Expand sidebar on Cases & Visits screen
      final expandBtn = find.byTooltip('Expand Sidebar');
      expect(expandBtn, findsOneWidget);
      await tester.tap(expandBtn);
      await tester.pumpAndSettle();

      expect(tester.getRect(find.byType(DoctorSidebar)).width, equals(250.0));
      expect(DoctorSidebarController.instance.isCollapsed, isFalse);

      // Navigate to Reports & Diagnostics
      navKey.pushReplacementNamed(AppRoutes.doctorReports);
      await tester.pumpAndSettle();

      expect(find.byType(DoctorReportsScreen), findsOneWidget);
      // Width must remain 250.0 (expanded)
      expect(tester.getRect(find.byType(DoctorSidebar)).width, equals(250.0));
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/admin/controllers/admin_sidebar_controller.dart';
import 'package:aayusathi/admin/screens/admin_appointment_escalations_screen.dart';
import 'package:aayusathi/admin/screens/admin_availability_screen.dart';
import 'package:aayusathi/admin/screens/admin_dashboard_screen.dart';
import 'package:aayusathi/admin/screens/admin_doctors_screen.dart';
import 'package:aayusathi/admin/screens/admin_login_screen.dart';
import 'package:aayusathi/admin/screens/admin_standby_screen.dart';
import 'package:aayusathi/admin/widgets/admin_availability_table.dart';
import 'package:aayusathi/admin/widgets/admin_escalation_empty_state.dart';
import 'package:aayusathi/admin/widgets/admin_header.dart';
import 'package:aayusathi/admin/widgets/admin_heartbeat_logo.dart';
import 'package:aayusathi/admin/widgets/admin_kpi_card.dart';
import 'package:aayusathi/admin/widgets/admin_sidebar.dart';
import 'package:aayusathi/admin/services/admin_auth_service.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/constants/app_constants.dart';
import 'package:aayusathi/core/routes/app_routes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    BackendProvider.instance.setMode(BackendMode.mock);
    AdminSidebarController.instance.reset();
    AdminAuthService.instance.setAuthenticatedForTesting();
  });

  group('AAYUSATHI Admin Phase A1: Standby & Login UI Tests', () {
    testWidgets('1. Admin standby screen renders logo, heartbeat, title, and Touch to Begin',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.adminStandby,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AdminStandbyScreen), findsOneWidget);
      expect(find.byType(AdminHeartbeatLogo), findsOneWidget);
      expect(find.text('ADMINISTRATION PORTAL'), findsOneWidget);
      expect(find.text('Healthcare Management System'), findsOneWidget);
      expect(find.text(AppConstants.appTagline), findsOneWidget);
      expect(find.text('TOUCH TO BEGIN'), findsOneWidget);
      expect(find.text('CENTRAL ADMINISTRATIVE CONSOLE'), findsOneWidget);
      expect(find.text('TERMINAL ONLINE'), findsOneWidget);

      // Verify sidebar and header are NOT on the standby screen
      expect(find.byType(AdminSidebar), findsNothing);
      expect(find.byType(AdminHeader), findsNothing);
    });

    testWidgets('2. Touch to Begin navigates to Admin Login screen', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.adminStandby,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final beginBtn = find.text('TOUCH TO BEGIN');
      expect(beginBtn, findsOneWidget);
      await tester.tap(beginBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(AdminLoginScreen), findsOneWidget);
      expect(find.text('ADMIN LOGIN'), findsWidgets);
    });

    testWidgets('3. Login UI renders username, password, show/hide toggle, and back button',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.adminLogin,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(AdminLoginScreen), findsOneWidget);
      expect(find.text('ADMIN LOGIN'), findsWidgets);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('LOGIN'), findsOneWidget);
      expect(find.text('BACK'), findsOneWidget);

      // Verify textfields exist
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      // Verify initial password obscurity
      final passwordFieldBefore = tester.widget<TextField>(textFields.at(1));
      expect(passwordFieldBefore.obscureText, isTrue);

      // Tap password show/hide icon
      final visibilityIcon = find.byIcon(Icons.visibility_outlined);
      expect(visibilityIcon, findsOneWidget);
      await tester.tap(visibilityIcon);
      await tester.pump();

      final passwordFieldAfter = tester.widget<TextField>(textFields.at(1));
      expect(passwordFieldAfter.obscureText, isFalse);

      // Tap back button returns to standby
      final backBtn = find.text('BACK');
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(AdminStandbyScreen), findsOneWidget);
    });

    testWidgets('4. Zero demo credentials visible on Admin Login UI', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.adminLogin,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Assert zero occurrences of production credentials in UI
      expect(find.textContaining('admin01'), findsNothing);
      expect(find.textContaining('aayusathi1226'), findsNothing);
    });

    testWidgets('5. Login with valid credentials navigates to Admin Dashboard', (tester) async {
      AdminAuthService.instance.resetForTesting();
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.adminLogin,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'admin01');
      await tester.enterText(textFields.at(1), 'aayusathi1226');
      await tester.pump();

      final loginBtn = find.text('LOGIN');
      await tester.tap(loginBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(AdminDashboardScreen), findsOneWidget);
    });
  });

  group('AAYUSATHI Admin Phase A1: Dashboard Shell & Sidebar Stationarity Tests', () {
    testWidgets('6. Dashboard shell renders stationary Header, persistent Sidebar, and Overview',
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
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(AdminDashboardScreen), findsOneWidget);
      expect(find.byType(AdminHeader), findsOneWidget);
      expect(find.byType(AdminSidebar), findsOneWidget);
      expect(find.text('ADMIN PORTAL'), findsWidgets);
      expect(find.text('SYSTEM OVERVIEW'), findsOneWidget);

      // Verify 4 KPI cards
      expect(find.byType(AdminKpiCard), findsNWidgets(4));
      expect(find.text('TOTAL DOCTORS'), findsOneWidget);
      expect(find.text('AVAILABLE DOCTORS'), findsOneWidget);
      expect(find.text('PENDING APPOINTMENTS'), findsOneWidget);
      expect(find.text('ACTIVE ESCALATIONS'), findsOneWidget);

      // Verify Action Cards
      expect(find.text('ADD NEW DOCTOR'), findsOneWidget);
      expect(find.text('MANAGE DOCTORS'), findsWidgets);

      // Verify Availability Table
      expect(find.byType(AdminAvailabilityTable), findsOneWidget);
      expect(find.text('DOCTOR AVAILABILITY'), findsOneWidget);
      final tableFinder = find.byType(AdminAvailabilityTable);
      expect(find.descendant(of: tableFinder, matching: find.text('Cardiology')), findsOneWidget);
      expect(find.descendant(of: tableFinder, matching: find.text('Neurology')), findsOneWidget);
      expect(find.descendant(of: tableFinder, matching: find.text('Gastroenterology')), findsOneWidget);
      expect(find.descendant(of: tableFinder, matching: find.text('Orthopedics')), findsOneWidget);
      expect(find.descendant(of: tableFinder, matching: find.text('Pediatrics')), findsOneWidget);
      expect(find.descendant(of: tableFinder, matching: find.text('ENT')), findsOneWidget);
      expect(find.descendant(of: tableFinder, matching: find.text('Dermatology')), findsOneWidget);
      expect(find.descendant(of: tableFinder, matching: find.text('General Medicine')), findsOneWidget);

      // Verify Escalations Empty States
      expect(find.byType(AdminEscalationEmptyState), findsNWidgets(2));
      expect(find.text('No appointment escalations'), findsOneWidget);
      expect(find.text('No active case escalations'), findsOneWidget);
    });

    testWidgets('7. Sidebar item selection switches pages with pixel-stationary sidebar and header',
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
      await tester.pump(const Duration(milliseconds: 200));

      final initialSidebarRect = tester.getRect(find.byType(AdminSidebar));
      final initialHeaderRect = tester.getRect(find.byType(AdminHeader));

      expect(initialSidebarRect.left, equals(0.0));
      expect(initialSidebarRect.width, equals(250.0));
      expect(initialHeaderRect.top, equals(0.0));

      // Tap "Doctors" in sidebar
      final doctorsItem = find.text('Doctors');
      expect(doctorsItem, findsOneWidget);
      await tester.tap(doctorsItem);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(AdminDoctorsScreen), findsOneWidget);
      expect(find.text('ADD NEW DOCTOR'), findsWidgets);

      final doctorsSidebarRect = tester.getRect(find.byType(AdminSidebar));
      final doctorsHeaderRect = tester.getRect(find.byType(AdminHeader));

      expect(doctorsSidebarRect.left, equals(initialSidebarRect.left));
      expect(doctorsSidebarRect.width, equals(initialSidebarRect.width));
      expect(doctorsHeaderRect.top, equals(initialHeaderRect.top));

      // Tap "Availability" in sidebar
      final availabilityItem = find.text('Availability');
      expect(availabilityItem, findsOneWidget);
      await tester.tap(availabilityItem);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(AdminAvailabilityScreen), findsOneWidget);

      final availSidebarRect = tester.getRect(find.byType(AdminSidebar));
      expect(availSidebarRect.left, equals(initialSidebarRect.left));
      expect(availSidebarRect.width, equals(initialSidebarRect.width));

      // Tap "Dashboard" to return
      final dashboardItem = find.text('Dashboard');
      expect(dashboardItem, findsOneWidget);
      await tester.tap(dashboardItem);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(AdminDashboardScreen), findsOneWidget);
      final finalSidebarRect = tester.getRect(find.byType(AdminSidebar));
      expect(finalSidebarRect.left, equals(initialSidebarRect.left));
      expect(finalSidebarRect.width, equals(initialSidebarRect.width));
    });

    testWidgets('8. 20 consecutive sidebar navigation switches maintain pixel-stationary geometry',
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
      await tester.pump(const Duration(milliseconds: 200));

      final baselineSidebarRect = tester.getRect(find.byType(AdminSidebar));
      final baselineHeaderRect = tester.getRect(find.byType(AdminHeader));

      for (int i = 0; i < 20; i++) {
        final targetText = (i % 2 == 0) ? 'Doctors' : 'Dashboard';
        final targetFinder = find.text(targetText);
        expect(targetFinder, findsOneWidget);

        await tester.tap(targetFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        final currentSidebarRect = tester.getRect(find.byType(AdminSidebar));
        final currentHeaderRect = tester.getRect(find.byType(AdminHeader));

        final sidebarDeltaX = (currentSidebarRect.left - baselineSidebarRect.left).abs();
        final sidebarDeltaW = (currentSidebarRect.width - baselineSidebarRect.width).abs();
        final headerDeltaY = (currentHeaderRect.top - baselineHeaderRect.top).abs();

        expect(sidebarDeltaX, equals(0.0), reason: 'Cycle $i: Sidebar X shifted by $sidebarDeltaX');
        expect(sidebarDeltaW, equals(0.0), reason: 'Cycle $i: Sidebar width shifted by $sidebarDeltaW');
        expect(headerDeltaY, equals(0.0), reason: 'Cycle $i: Header Y shifted by $headerDeltaY');
      }
    });

    testWidgets('9. Persistent sidebar collapse state is preserved across route navigation',
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
      await tester.pump(const Duration(milliseconds: 200));

      expect(AdminSidebarController.instance.isCollapsed, isFalse);
      expect(tester.getRect(find.byType(AdminSidebar)).width, equals(250.0));

      // Collapse sidebar
      final collapseBtn = find.byTooltip('Collapse Sidebar');
      expect(collapseBtn, findsOneWidget);
      await tester.tap(collapseBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(AdminSidebarController.instance.isCollapsed, isTrue);
      expect(tester.getRect(find.byType(AdminSidebar)).width, equals(76.0));

      // Navigate to Appointment Escalations
      final navKey = tester.state<NavigatorState>(find.byType(Navigator));
      navKey.pushReplacementNamed(AppRoutes.adminAppointmentEscalations);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(AdminAppointmentEscalationsScreen), findsOneWidget);
      // Width must remain 76.0 (collapsed)
      expect(tester.getRect(find.byType(AdminSidebar)).width, equals(76.0));
      expect(AdminSidebarController.instance.isCollapsed, isTrue);

      // Expand sidebar on sub-screen
      final expandBtn = find.byTooltip('Expand Sidebar');
      expect(expandBtn, findsOneWidget);
      await tester.tap(expandBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(tester.getRect(find.byType(AdminSidebar)).width, equals(250.0));
      expect(AdminSidebarController.instance.isCollapsed, isFalse);

      // Navigate back to Dashboard
      navKey.pushReplacementNamed(AppRoutes.adminDashboard);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(AdminDashboardScreen), findsOneWidget);
      // Width must remain 250.0 (expanded)
      expect(tester.getRect(find.byType(AdminSidebar)).width, equals(250.0));
    });

    testWidgets('10. Responsive layout renders without RenderFlex overflow at desktop resolutions',
        (tester) async {
      final resolutions = [
        const Size(1366, 768),
        const Size(1440, 900),
        const Size(1920, 1080),
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

        expect(tester.takeException(), isNull,
            reason: 'Resolution ${res.width}x${res.height} threw an exception');
        expect(find.byType(AdminDashboardScreen), findsOneWidget);
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}

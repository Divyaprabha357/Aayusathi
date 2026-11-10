import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/admin/controllers/admin_sidebar_controller.dart';
import 'package:aayusathi/admin/models/admin_auth_state.dart';
import 'package:aayusathi/admin/models/admin_session.dart';
import 'package:aayusathi/admin/screens/admin_dashboard_screen.dart';
import 'package:aayusathi/admin/screens/admin_login_screen.dart';
import 'package:aayusathi/admin/screens/admin_placeholder_screen.dart';
import 'package:aayusathi/admin/screens/admin_standby_screen.dart';
import 'package:aayusathi/admin/services/admin_auth_service.dart';
import 'package:aayusathi/admin/widgets/admin_header.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/routes/app_routes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    BackendProvider.instance.setMode(BackendMode.mock);
    AdminSidebarController.instance.reset();
    AdminAuthService.instance.resetForTesting();
  });

  tearDown(() {
    AdminAuthService.instance.resetForTesting();
  });

  group('AAYUSATHI Admin Phase A2: Auth Service Unit Tests', () {
    test('1. Exact credentials succeed (admin01 + aayusathi1226)', () async {
      final result = await AdminAuthService.instance.login(
        username: 'admin01',
        password: 'aayusathi1226',
      );

      expect(result.isSuccess, isTrue);
      expect(AdminAuthService.instance.isAuthenticated, isTrue);
      expect(AdminAuthService.instance.authState, equals(AdminAuthState.authenticated));
      expect(AdminAuthService.instance.currentSession, isNotNull);
      expect(AdminAuthService.instance.currentSession!.username, equals('admin01'));
      expect(AdminAuthService.instance.currentSession!.role, equals(AdminRole.admin));
      expect(AdminAuthService.instance.currentSession!.isAuthenticated, isTrue);
    });

    test('2. Case sensitive and variations in username fail', () async {
      final invalidUsernames = [
        'admin',
        'admin1',
        'ADMIN01',
        'Admin01',
        'admin02',
        'root',
        'superuser',
      ];

      for (final u in invalidUsernames) {
        AdminAuthService.instance.resetForTesting();
        final result = await AdminAuthService.instance.login(
          username: u,
          password: 'aayusathi1226',
        );
        expect(result.isSuccess, isFalse, reason: 'Username "$u" should fail');
        expect(AdminAuthService.instance.isAuthenticated, isFalse);
        expect(AdminAuthService.instance.authState, equals(AdminAuthState.authenticationFailed));
      }
    });

    test('3. Variations in password fail (case-sensitive, untrimmed)', () async {
      final invalidPasswords = [
        'aayusathi1226 ',
        ' aayusathi1226',
        'AAYUSATHI1226',
        'Aayusathi1226',
        'aayusathi',
        '1226',
        'password',
      ];

      for (final p in invalidPasswords) {
        AdminAuthService.instance.resetForTesting();
        final result = await AdminAuthService.instance.login(
          username: 'admin01',
          password: p,
        );
        expect(result.isSuccess, isFalse, reason: 'Password "$p" should fail');
        expect(AdminAuthService.instance.isAuthenticated, isFalse);
        expect(AdminAuthService.instance.authState, equals(AdminAuthState.authenticationFailed));
      }
    });

    test('4. Both wrong username and password fail', () async {
      final result = await AdminAuthService.instance.login(
        username: 'wrong_user',
        password: 'wrong_password',
      );

      expect(result.isSuccess, isFalse);
      expect(AdminAuthService.instance.isAuthenticated, isFalse);
      expect(AdminAuthService.instance.authState, equals(AdminAuthState.authenticationFailed));
    });

    test('5. Logout clears session and resets auth state', () async {
      await AdminAuthService.instance.login(
        username: 'admin01',
        password: 'aayusathi1226',
      );
      expect(AdminAuthService.instance.isAuthenticated, isTrue);

      await AdminAuthService.instance.logout();
      expect(AdminAuthService.instance.isAuthenticated, isFalse);
      expect(AdminAuthService.instance.authState, equals(AdminAuthState.loggedOut));
      expect(AdminAuthService.instance.currentSession, isNull);
    });

    test('6. AdminSession model provides safe representation without passwords', () {
      final session = AdminSession.createAuthenticated(username: 'admin01');
      expect(session.isAuthenticated, isTrue);
      expect(session.username, equals('admin01'));
      expect(session.displayName, contains('admin01'));
      expect(session.role, equals(AdminRole.admin));
      expect(session.toString(), isNot(contains('aayusathi1226')));

      final emptySession = AdminSession.empty();
      expect(emptySession.isAuthenticated, isFalse);
      expect(emptySession.username, isEmpty);
    });
  });

  group('AAYUSATHI Admin Phase A2: UI Validation & Interaction Tests', () {
    testWidgets('7. Empty username shows validation error without calling auth', (tester) async {
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
      await tester.enterText(textFields.at(0), ''); // Empty username
      await tester.enterText(textFields.at(1), 'aayusathi1226');
      await tester.pump();

      await tester.tap(find.text('LOGIN'));
      await tester.pump();

      expect(find.text('Please enter your username'), findsOneWidget);
      expect(AdminAuthService.instance.isAuthenticated, isFalse);
      expect(find.byType(AdminLoginScreen), findsOneWidget);
    });

    testWidgets('8. Empty password shows validation error without calling auth', (tester) async {
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
      await tester.enterText(textFields.at(1), ''); // Empty password
      await tester.pump();

      await tester.tap(find.text('LOGIN'));
      await tester.pump();

      expect(find.text('Please enter your password'), findsOneWidget);
      expect(AdminAuthService.instance.isAuthenticated, isFalse);
      expect(find.byType(AdminLoginScreen), findsOneWidget);
    });

    testWidgets('9. Both fields empty shows username error first', (tester) async {
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

      await tester.tap(find.text('LOGIN'));
      await tester.pump();

      expect(find.text('Please enter your username'), findsOneWidget);
    });

    testWidgets('10. Invalid credentials display "Invalid username or password." banner',
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

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'admin01');
      await tester.enterText(textFields.at(1), 'wrong_pass');
      await tester.pump();

      await tester.tap(find.text('LOGIN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Invalid username or password.'), findsOneWidget);
      expect(find.byType(AdminLoginScreen), findsOneWidget);
      expect(AdminAuthService.instance.isAuthenticated, isFalse);
    });

    testWidgets('11. Successful login authenticates and navigates to Dashboard', (tester) async {
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

      await tester.tap(find.text('LOGIN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(AdminAuthService.instance.isAuthenticated, isTrue);
      expect(find.byType(AdminDashboardScreen), findsOneWidget);
      expect(find.text('ADMIN PORTAL'), findsWidgets);
    });

    testWidgets('12. Password visibility toggle works without resizing form', (tester) async {
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
      final passwordFieldInitial = tester.widget<TextField>(textFields.at(1));
      expect(passwordFieldInitial.obscureText, isTrue);

      // Toggle visible
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      final passwordFieldVisible = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(passwordFieldVisible.obscureText, isFalse);

      // Toggle hidden
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      final passwordFieldHidden = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(passwordFieldHidden.obscureText, isTrue);
    });

    testWidgets('13. Credentials are NEVER visible in UI or helper text', (tester) async {
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

      expect(find.textContaining('admin01'), findsNothing);
      expect(find.textContaining('aayusathi1226'), findsNothing);
    });
  });

  group('AAYUSATHI Admin Phase A2: Protected Routes & Guarding Tests', () {
    testWidgets('14. Direct access to /admin/dashboard when unauthenticated redirects to /admin/login',
        (tester) async {
      AdminAuthService.instance.resetForTesting();
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

      expect(find.byType(AdminLoginScreen), findsOneWidget);
      expect(find.byType(AdminDashboardScreen), findsNothing);
    });

    testWidgets('15. Direct access to /admin/doctors when unauthenticated redirects to /admin/login',
        (tester) async {
      AdminAuthService.instance.resetForTesting();
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.adminDoctors,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(AdminLoginScreen), findsOneWidget);
      expect(find.byType(AdminPlaceholderScreen), findsNothing);
    });

    testWidgets('16. Direct access to /admin/availability when unauthenticated redirects to /admin/login',
        (tester) async {
      AdminAuthService.instance.resetForTesting();
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.adminAvailability,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(AdminLoginScreen), findsOneWidget);
    });

    testWidgets('17. Direct access to /admin/appointment-escalations when unauthenticated redirects',
        (tester) async {
      AdminAuthService.instance.resetForTesting();
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.adminAppointmentEscalations,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(AdminLoginScreen), findsOneWidget);
    });

    testWidgets('18. Direct access to /admin/case-escalations when unauthenticated redirects',
        (tester) async {
      AdminAuthService.instance.resetForTesting();
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.adminCaseEscalations,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(AdminLoginScreen), findsOneWidget);
    });

    testWidgets('19. Authenticated admin can access /admin/dashboard and sub-routes directly',
        (tester) async {
      AdminAuthService.instance.setAuthenticatedForTesting();
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
      expect(find.text('SYSTEM OVERVIEW'), findsOneWidget);
    });
  });

  group('AAYUSATHI Admin Phase A2: Logout Flow Tests', () {
    testWidgets('20. Logout from Admin Header clears session and returns to Standby',
        (tester) async {
      AdminAuthService.instance.setAuthenticatedForTesting();
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
      expect(AdminAuthService.instance.isAuthenticated, isTrue);

      // Open profile popup menu
      final profileMenuFinder = find.byType(PopupMenuButton<String>);
      expect(profileMenuFinder, findsOneWidget);
      await tester.tap(profileMenuFinder);
      await tester.pumpAndSettle();

      // Tap Logout
      final logoutFinder = find.text('Logout');
      expect(logoutFinder, findsOneWidget);
      await tester.tap(logoutFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Assert session is cleared and returned to Standby
      expect(AdminAuthService.instance.isAuthenticated, isFalse);
      expect(find.byType(AdminStandbyScreen), findsOneWidget);
    });

    testWidgets('21. Attempting to access dashboard after logout redirects to login',
        (tester) async {
      AdminAuthService.instance.setAuthenticatedForTesting();
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

      // Perform logout
      await AdminAuthService.instance.logout();
      await tester.pump();

      // Try navigating to dashboard
      final navKey = tester.state<NavigatorState>(find.byType(Navigator));
      navKey.pushReplacementNamed(AppRoutes.adminDashboard);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(AdminLoginScreen), findsOneWidget);
    });
  });
}

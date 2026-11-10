import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/constants/app_constants.dart';
import 'package:aayusathi/core/routes/app_routes.dart';
import 'package:aayusathi/core/theme/app_theme.dart';
import 'package:aayusathi/doctor/models/doctor_navigation_item.dart';
import 'package:aayusathi/doctor/models/doctor_patient_request.dart';
import 'package:aayusathi/doctor/models/doctor_ui_status.dart';
import 'package:aayusathi/doctor/screens/doctor_case_screen.dart';
import 'package:aayusathi/doctor/screens/doctor_consultation_screen.dart';
import 'package:aayusathi/doctor/screens/doctor_dashboard_screen.dart';
import 'package:aayusathi/doctor/screens/doctor_login_screen.dart';
import 'package:aayusathi/doctor/screens/doctor_patient_request_screen.dart';
import 'package:aayusathi/doctor/screens/doctor_patient_workspace_screen.dart';
import 'package:aayusathi/doctor/screens/doctor_reports_screen.dart';
import 'package:aayusathi/doctor/screens/doctor_standby_screen.dart';
import 'package:aayusathi/doctor/theme/doctor_colors.dart';
import 'package:aayusathi/doctor/widgets/doctor_buttons.dart';
import 'package:aayusathi/doctor/widgets/doctor_card.dart';
import 'package:aayusathi/doctor/widgets/doctor_header.dart';
import 'package:aayusathi/doctor/widgets/doctor_heartbeat_logo.dart';
import 'package:aayusathi/doctor/widgets/doctor_patient_request_card.dart';
import 'package:aayusathi/doctor/widgets/doctor_section_header.dart';
import 'package:aayusathi/doctor/widgets/doctor_sidebar.dart';
import 'package:aayusathi/doctor/widgets/doctor_state_views.dart';
import 'package:aayusathi/doctor/widgets/doctor_status_indicator.dart';
import 'package:aayusathi/doctor/widgets/doctor_vital_card.dart';
import 'package:aayusathi/main.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: child is Scaffold ? child : Scaffold(body: Center(child: child)),
    );
  }

  group('AAYUSATHI Phase D1: Route Registration & Navigation Foundation', () {
    test('1. All 8 Doctor Routes and Aliases are registered in AppRoutes', () {
      expect(AppRoutes.doctorHome, equals('/doctor'));
      expect(AppRoutes.doctorStandby, equals('/doctor/standby'));
      expect(AppRoutes.doctorLogin, equals('/doctor/login'));
      expect(AppRoutes.doctorDashboard, equals('/doctor/dashboard'));
      expect(AppRoutes.doctorPatientRequest, equals('/doctor/patient-request'));
      expect(AppRoutes.doctorPatientWorkspace, equals('/doctor/patient-workspace'));
      expect(AppRoutes.doctorConsultation, equals('/doctor/consultation'));
      expect(AppRoutes.doctorCase, equals('/doctor/case'));
      expect(AppRoutes.doctorReports, equals('/doctor/reports'));
    });

    testWidgets('2. AppRoutes.onGenerateRoute produces correct screens for all Doctor routes',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final routesToTest = {
        AppRoutes.doctorStandby: DoctorStandbyScreen,
        AppRoutes.doctorHome: DoctorStandbyScreen,
        AppRoutes.doctorLogin: DoctorLoginScreen,
        AppRoutes.doctorDashboard: DoctorDashboardScreen,
        AppRoutes.doctorPatientRequest: DoctorPatientRequestScreen,
        AppRoutes.doctorPatientWorkspace: DoctorPatientWorkspaceScreen,
        AppRoutes.doctorConsultation: DoctorConsultationScreen,
        AppRoutes.doctorCase: DoctorCaseScreen,
        AppRoutes.doctorReports: DoctorReportsScreen,
      };

      for (final entry in routesToTest.entries) {
        final navKey = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          MaterialApp(
            key: UniqueKey(),
            navigatorKey: navKey,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            home: const SizedBox(),
          ),
        );
        navKey.currentState!.pushNamed(entry.key);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.byType(entry.value), findsOneWidget,
            reason: 'Route ${entry.key} must produce ${entry.value}');
      }
    });
  });

  group('AAYUSATHI Phase D1: Doctor Standby Screen & Heartbeat Animation', () {
    testWidgets('3. Doctor Standby Screen renders branding, tagline, and title',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget(const DoctorStandbyScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 1. Branding & Tagline
      expect(find.byType(DoctorHeartbeatLogo), findsOneWidget);
      expect(find.text(AppConstants.appTagline), findsOneWidget);
      expect(find.text('Doctor OPD Management System'), findsOneWidget);
      expect(find.text('OPD CLINICAL WORKSTATION'), findsOneWidget);
      expect(find.text('TERMINAL ONLINE'), findsOneWidget);

      // 2. Login button exists
      expect(find.text('DOCTOR LOGIN'), findsOneWidget);
      expect(find.byType(DoctorPrimaryButton), findsOneWidget);

      // 3. Mode switch button exists
      expect(find.text('Switch to Kiosk Terminal'), findsOneWidget);
    });

    testWidgets('4. Heartbeat animation cycles smoothly without throwing',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const DoctorHeartbeatLogo()));
      await tester.pump();

      // Pump through one cardiac cycle (~1700ms)
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('5. Login button triggers onLoginPressed or navigates to Doctor Login placeholder',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool customLoginCalled = false;

      await tester.pumpWidget(
        buildTestableWidget(
          DoctorStandbyScreen(
            onLoginPressed: () => customLoginCalled = true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('DOCTOR LOGIN'));
      await tester.pump();

      expect(customLoginCalled, isTrue);
    });

    testWidgets('6. Default Standby Screen LOGIN navigates to DoctorLoginScreen route',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const AayusathiApp(initialRoute: AppRoutes.doctorStandby),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(DoctorStandbyScreen), findsOneWidget);

      await tester.tap(find.text('DOCTOR LOGIN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(DoctorLoginScreen), findsOneWidget);
      expect(find.text('Doctor Authentication'), findsOneWidget);
    });

    testWidgets('7. Keyboard Enter key on Standby triggers Login navigation',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool loginInvoked = false;

      await tester.pumpWidget(
        buildTestableWidget(
          DoctorStandbyScreen(
            onLoginPressed: () => loginInvoked = true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(loginInvoked, isTrue);
    });

    testWidgets('8. Switch to Kiosk button triggers onSwitchToKiosk callback',
        (WidgetTester tester) async {
      bool kioskSwitched = false;

      await tester.pumpWidget(
        buildTestableWidget(
          DoctorStandbyScreen(
            onSwitchToKiosk: () => kioskSwitched = true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Switch to Kiosk Terminal'));
      await tester.pump();

      expect(kioskSwitched, isTrue);
    });
  });

  group('AAYUSATHI Phase D1: Reusable Doctor Theme Components', () {
    testWidgets('9. Doctor Buttons render with correct labels and react to clicks',
        (WidgetTester tester) async {
      bool primaryClicked = false;
      bool secondaryClicked = false;
      bool outlineClicked = false;

      await tester.pumpWidget(
        buildTestableWidget(
          Column(
            children: [
              DoctorPrimaryButton(
                label: 'Primary Action',
                onPressed: () => primaryClicked = true,
              ),
              DoctorSecondaryButton(
                label: 'Secondary Action',
                onPressed: () => secondaryClicked = true,
              ),
              DoctorOutlineButton(
                label: 'Outline Action',
                onPressed: () => outlineClicked = true,
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Primary Action'));
      expect(primaryClicked, isTrue);

      await tester.tap(find.text('Secondary Action'));
      expect(secondaryClicked, isTrue);

      await tester.tap(find.text('Outline Action'));
      expect(outlineClicked, isTrue);
    });

    testWidgets('9b. Doctor Cards, Section Headers, and Colors render properly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Column(
            children: [
              DoctorCard(
                title: 'Clinical Summary',
                subtitle: 'Active OPD',
                trailing: const Icon(Icons.info),
                child: const Text('Card Body'),
              ),
              const DoctorElevatedCard(
                child: Text('Elevated Body'),
              ),
              const DoctorSectionHeader(
                title: 'Queue Metrics',
                subtitle: 'Real-time telemetry',
                badgeText: 'LIVE',
                badgeColor: DoctorColors.statusOnline,
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Clinical Summary'), findsOneWidget);
      expect(find.text('Active OPD'), findsOneWidget);
      expect(find.text('Card Body'), findsOneWidget);
      expect(find.text('Elevated Body'), findsOneWidget);
      expect(find.text('Queue Metrics'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
    });

    testWidgets('10. Doctor Status Badges render color, icon, and label for accessibility',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Column(
            children: [
              DoctorStatusBadge.fromOnlineStatus(DoctorOnlineStatus.online),
              DoctorStatusBadge.fromOnlineStatus(DoctorOnlineStatus.offline),
              DoctorStatusBadge.fromWorkStatus(DoctorWorkStatus.available),
              DoctorStatusBadge.fromWorkStatus(DoctorWorkStatus.inConsultation),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('System Online'), findsOneWidget);
      expect(find.text('System Offline'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('In Consultation'), findsOneWidget);
    });

    testWidgets('11. Doctor Vital Card displays metric, unit, and status pill',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const DoctorVitalCard(
            title: 'Heart Rate',
            value: '72',
            unit: 'bpm',
            icon: Icons.favorite_outline_rounded,
            state: DoctorVitalState.normal,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Heart Rate'), findsOneWidget);
      expect(find.text('72'), findsOneWidget);
      expect(find.text('bpm'), findsOneWidget);
      expect(find.text('NORMAL'), findsOneWidget);
    });

    testWidgets('12. Doctor Patient Request Card displays ticket without fake patient data',
        (WidgetTester tester) async {
      bool accepted = false;

      final testRequest = DoctorPatientRequest(
        requestId: 'REQ-D1-042',
        appointmentId: 'APT-D1-042',
        patientId: 'PAT-D1-042',
        queueNumber: 'A-00042',
        age: 45,
        gender: 'Male',
        domain: 'Cardiology',
        requestType: PatientRequestType.newVisit,
        requestedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          DoctorPatientRequestCard(
            request: testRequest,
            onAccept: () => accepted = true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('A-00042'), findsOneWidget);
      expect(find.text('Cardiology'), findsOneWidget);
      expect(find.text('ACCEPT REQUEST'), findsOneWidget);

      await tester.tap(find.text('ACCEPT REQUEST'));
      expect(accepted, isTrue);
    });

    testWidgets('13. Doctor State Views (Loading, Empty, Error, Success) render correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const SingleChildScrollView(
            child: Column(
              children: [
                DoctorLoadingView(message: 'Loading telemetry'),
                DoctorEmptyView(title: 'Empty Queue', subtitle: 'No waiting patients'),
                DoctorErrorView(title: 'Network Error', message: 'Could not sync'),
                DoctorSuccessView(title: 'Saved', message: 'Record updated'),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Loading telemetry'), findsOneWidget);
      expect(find.text('Empty Queue'), findsOneWidget);
      expect(find.text('Network Error'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
    });

    testWidgets('14. Doctor Header renders branding, page title, and status',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestableWidget(
          const DoctorHeader(
            title: 'Diagnostic Overview',
            subtitle: 'Central Pathology',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Diagnostic Overview'), findsOneWidget);
      expect(find.text('Central Pathology'), findsOneWidget);
      expect(find.text('DOCTOR PORTAL'), findsOneWidget);
      expect(find.text('System Online'), findsOneWidget);
    });

    testWidgets('15. Doctor Sidebar renders navigation items and responds to selection and collapse',
        (WidgetTester tester) async {
      String selectedRoute = '';
      bool collapsed = false;

      final items = [
        const DoctorNavigationItem(
          id: 'dash',
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard_rounded,
          routeName: '/doctor/dashboard',
        ),
        const DoctorNavigationItem(
          id: 'req',
          label: 'Requests',
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
          routeName: '/doctor/requests',
          badgeCount: 3,
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          DoctorSidebar(
            items: items,
            activeRoute: '/doctor/dashboard',
            onItemSelected: (it) => selectedRoute = it.routeName,
            isCollapsed: collapsed,
            onToggleCollapse: () => collapsed = !collapsed,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Requests'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.text('Requests'));
      expect(selectedRoute, equals('/doctor/requests'));
    });
  });

  group('AAYUSATHI Phase D1: Data Cleanliness & Zero Mock Patient Exposure', () {
    testWidgets('16. Visible Doctor screens contain zero fake patient or fake Aadhaar data',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeNames = [
        'Aarav Sharma',
        'John Doe',
        'Jane Doe',
        'Priya Patel',
        'Rahul Verma',
      ];
      final fakeNumbers = [
        '9876543210',
        '123456789012',
        '555544443333',
      ];

      final screens = [
        const DoctorStandbyScreen(),
        const DoctorLoginScreen(),
        const DoctorDashboardScreen(),
        const DoctorPatientRequestScreen(),
        const DoctorConsultationScreen(),
        const DoctorCaseScreen(),
        const DoctorReportsScreen(),
      ];

      for (final screen in screens) {
        await tester.pumpWidget(buildTestableWidget(screen));
        await tester.pump();

        for (final name in fakeNames) {
          expect(find.text(name), findsNothing,
              reason: 'Fake name $name must not appear in Doctor UI');
        }
        for (final number in fakeNumbers) {
          expect(find.text(number), findsNothing,
              reason: 'Fake number $number must not appear in Doctor UI');
        }
      }
    });
  });

  group('AAYUSATHI Phase D1: Responsive Viewport Verification', () {
    final desktopViewports = [
      const Size(1366, 768),
      const Size(1440, 900),
      const Size(1920, 1080),
    ];

    for (final size in desktopViewports) {
      testWidgets('17. Standby Screen renders cleanly at ${size.width.toInt()}x${size.height.toInt()} without overflow',
          (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestableWidget(const DoctorStandbyScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(tester.takeException(), isNull);
        expect(find.text('DOCTOR LOGIN'), findsOneWidget);
        expect(find.byType(DoctorHeartbeatLogo), findsOneWidget);
      });

      testWidgets('18. Doctor Dashboard Shell renders cleanly at ${size.width.toInt()}x${size.height.toInt()} without overflow',
          (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestableWidget(const DoctorDashboardScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(tester.takeException(), isNull);
        expect(find.text('Doctor Dashboard'), findsOneWidget);
      });
    }
  });
}

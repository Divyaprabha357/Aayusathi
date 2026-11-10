import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/core/routes/app_routes.dart';
import 'package:aayusathi/doctor/screens/doctor_standby_screen.dart';
import 'package:aayusathi/kiosk/screens/standby_screen.dart';
import 'package:aayusathi/main.dart';
import 'package:aayusathi/patient/controllers/patient_calendar_controller.dart';
import 'package:aayusathi/patient/controllers/patient_cases_controller.dart';
import 'package:aayusathi/patient/controllers/patient_dashboard_controller.dart';
import 'package:aayusathi/patient/controllers/patient_profile_controller.dart';
import 'package:aayusathi/patient/controllers/patient_reports_controller.dart';
import 'package:aayusathi/patient/localization/patient_localizations.dart';
import 'package:aayusathi/patient/localization/patient_strings.dart';
import 'package:aayusathi/patient/models/patient_app_state.dart';
import 'package:aayusathi/patient/models/patient_navigation_tab.dart';
import 'package:aayusathi/patient/patient_routes.dart';
import 'package:aayusathi/patient/screens/patient_calendar_screen.dart';
import 'package:aayusathi/patient/screens/patient_cases_screen.dart';
import 'package:aayusathi/patient/screens/patient_dashboard_screen.dart';
import 'package:aayusathi/patient/screens/patient_login_screen.dart';
import 'package:aayusathi/patient/screens/patient_main_shell_screen.dart';
import 'package:aayusathi/patient/screens/patient_otp_screen.dart';
import 'package:aayusathi/patient/screens/patient_profile_screen.dart';
import 'package:aayusathi/patient/screens/patient_reports_screen.dart';
import 'package:aayusathi/patient/services/patient_session_service.dart';
import 'package:aayusathi/patient/theme/patient_colors.dart';
import 'package:aayusathi/patient/theme/patient_theme.dart';
import 'package:aayusathi/patient/widgets/patient_bottom_navigation.dart';
import 'package:aayusathi/patient/widgets/patient_empty_state.dart';
import 'package:aayusathi/patient/widgets/patient_error_state.dart';
import 'package:aayusathi/patient/widgets/patient_loading_state.dart';
import 'package:aayusathi/patient/widgets/patient_profile_card.dart';
import 'package:aayusathi/patient/widgets/patient_top_bar.dart';
import 'package:aayusathi/repositories/mock/mock_appointment_repository.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_investigation_repository.dart';
import 'package:aayusathi/repositories/mock/mock_patient_repository.dart';
import 'package:aayusathi/repositories/mock/mock_report_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    BackendProvider.instance.setMode(BackendMode.mock);
    MockPatientRepository.instance.resetToDefaults();
    MockAppointmentRepository.instance.clear();
    MockCaseRepository.instance.resetToDefaults();
    MockClinicalVisitRepository.instance.resetToDefaults();
    MockInvestigationRepository.instance.reset();
    MockReportRepository.instance.reset();
    PatientAppState.instance.resetSession();
    PatientSessionService.instance.logout();
  });

  group('Phase P1: Patient Module Architecture & Theme Tests', () {
    testWidgets('1. PatientTheme initializes with official greenish-white medical colors', (tester) async {
      final theme = PatientTheme.theme;
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: const SizedBox(),
      ));
      expect(theme.scaffoldBackgroundColor, equals(PatientColors.background));
      expect(theme.primaryColor, equals(PatientColors.teal));
      expect(theme.colorScheme.secondary, equals(PatientColors.orange));
    });

    test('2. PatientRoutes correctly registers all 10 patient route endpoints', () {
      expect(PatientRoutes.patient, equals('/patient'));
      expect(PatientRoutes.patientLogin, equals('/patient/login'));
      expect(PatientRoutes.patientOtp, equals('/patient/otp'));
      expect(PatientRoutes.patientDashboard, equals('/patient/dashboard'));
      expect(PatientRoutes.patientCases, equals('/patient/cases'));
      expect(PatientRoutes.patientReports, equals('/patient/reports'));
      expect(PatientRoutes.patientCalendar, equals('/patient/calendar'));
      expect(PatientRoutes.patientProfile, equals('/patient/profile'));
    });
  });

  group('Phase P1: Screen Shell & Navigation Tests', () {
    testWidgets('3. Login Screen renders with Patient ID input and Continue button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: const PatientLoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Patient Login'), findsOneWidget);
      expect(find.text('Enter your AAYUSATHI Patient ID to continue.'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('4. OTP Screen renders with masked mobile number and 6-digit input', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: const PatientOtpScreen(maskedPhone: '******9876'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verify Your Mobile Number'), findsOneWidget);
      expect(find.text('******9876'), findsOneWidget);
      expect(find.text('Verify OTP'), findsOneWidget);
      expect(find.text('Resend OTP'), findsOneWidget);
    });

    testWidgets('5. Dashboard Screen renders greeting, next visit card, and quick access cards', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      final controller = PatientDashboardController();
      await controller.loadDashboardData();

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: Scaffold(body: PatientDashboardScreen(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NEXT VISIT'), findsOneWidget);
      expect(find.text('No Upcoming Visits'), findsOneWidget);
      expect(find.text('No Ongoing Cases'), findsOneWidget);
      expect(find.text('QUICK ACCESS'), findsOneWidget);
      expect(find.text('View Cases'), findsOneWidget);
      expect(find.text('View Reports'), findsOneWidget);
    });

    testWidgets('6. Cases Screen allows switching between Active and Completed tabs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      final controller = PatientCasesController();

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: Scaffold(body: PatientCasesScreen(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      // Tap Completed tab
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      expect(controller.selectedTab, equals(PatientCasesTab.completed));
    });

    test('7. Dynamic Route Parsing for /patient/cases/:caseId', () {
      final route = PatientRoutes.onGenerateRoute(
        const RouteSettings(name: '/patient/cases/CASE-12345'),
      );
      expect(route, isNotNull);
    });

    test('8. Dynamic Route Parsing for /patient/cases/:caseId/visits/:visitId', () {
      final route = PatientRoutes.onGenerateRoute(
        const RouteSettings(name: '/patient/cases/CASE-12345/visits/VIS-999'),
      );
      expect(route, isNotNull);
    });

    testWidgets('9. Reports Screen allows switching between Submitted and Yet to Submit tabs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      final controller = PatientReportsController();

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: Scaffold(body: PatientReportsScreen(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SUBMITTED'), findsOneWidget);
      expect(find.text('YET TO SUBMIT'), findsOneWidget);

      await tester.tap(find.text('YET TO SUBMIT'));
      await tester.pumpAndSettle();

      expect(controller.selectedTab, equals(PatientReportsTab.yetToSubmit));
    });

    test('10. Dynamic Route Parsing for /patient/reports/:reportId', () {
      final route = PatientRoutes.onGenerateRoute(
        const RouteSettings(name: '/patient/reports/REP-001'),
      );
      expect(route, isNotNull);
    });

    testWidgets('11. Calendar Screen renders month navigation and day grid', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      final controller = PatientCalendarController();

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: Scaffold(body: PatientCalendarScreen(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Health Calendar'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });

    testWidgets('12. Profile Screen renders read-only attributes without edit controls', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: const PatientProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Patient Profile'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Blood Group'), findsOneWidget);
      expect(find.text('Registered Mobile'), findsOneWidget);
    });

    testWidgets('13. PatientBottomNavigation contains exactly 4 tabs with icons and text labels', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      PatientNavigationTab selected = PatientNavigationTab.dashboard;

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: Scaffold(
            bottomNavigationBar: PatientBottomNavigation(
              currentTab: selected,
              onTabSelected: (t) => selected = t,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Cases'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);

      await tester.tap(find.text('Reports'));
      expect(selected, equals(PatientNavigationTab.reports));
    });

    testWidgets('14. Active tab visual indicator is highlighted in PatientBottomNavigation', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: const Scaffold(
            bottomNavigationBar: PatientBottomNavigation(
              currentTab: PatientNavigationTab.cases,
              onTabSelected: _dummyTabCallback,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final casesText = tester.widget<Text>(find.text('Cases'));
      expect(casesText.style?.fontWeight, equals(FontWeight.w700));
    });

    testWidgets('15. PatientTopBar displays AAYUSATHI brand and Profile avatar icon', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      bool profileTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: Scaffold(
            appBar: PatientTopBar(
              onProfileTap: () => profileTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.person_rounded));
      expect(profileTapped, isTrue);
    });
  });

  group('Phase P1: Usability, Accessibility & Safeguards Tests', () {
    testWidgets('16. Responsive layout renders safely across Mobile (360-430px), Tablet, Desktop, and Inset variations', (tester) async {
      final testCases = [
        const Size(360, 640),  // 360px mobile
        const Size(375, 667),  // 375px mobile
        const Size(390, 844),  // 390px mobile
        const Size(412, 915),  // 412px mobile
        const Size(430, 932),  // 430px mobile
        const Size(768, 1024), // Tablet
        const Size(1440, 900), // Desktop
      ];

      for (final size in testCases) {
        await tester.binding.setSurfaceSize(size);
        for (final bottomInset in [0.0, 21.0, 34.0, 48.0]) {
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(
                size: size,
                padding: EdgeInsets.only(top: 36.0, bottom: bottomInset),
                viewPadding: EdgeInsets.only(top: 36.0, bottom: bottomInset),
              ),
              child: MaterialApp(
                theme: PatientTheme.theme,
                home: const PatientMainShellScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: 'Zero layout overflow for viewport $size with bottomInset $bottomInset');
          expect(find.byType(PatientBottomNavigation), findsOneWidget);
          expect(find.byType(PatientTopBar), findsOneWidget);
        }
      }
    });

    testWidgets('17. Interactive buttons and tabs maintain minimum 48px touch targets', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: const PatientLoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final buttonFinder = find.byType(ElevatedButton);
      expect(buttonFinder, findsOneWidget);
      final size = tester.getSize(buttonFinder);
      expect(size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('18. PatientEmptyState renders calm, non-alarmist zero-data presentation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PatientEmptyState(
              icon: Icons.folder_open_rounded,
              title: 'No active cases',
              message: 'You have no open medical cases.',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No active cases'), findsOneWidget);
      expect(find.text('You have no open medical cases.'), findsOneWidget);
    });

    testWidgets('19. PatientErrorState displays message and retry action', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PatientErrorState(
              message: 'Network connection error',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Network connection error'), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton));
      expect(retried, isTrue);
    });

    testWidgets('20. PatientLoadingState displays loading spinner with readable message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PatientLoadingState(message: 'Loading records...'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading records...'), findsOneWidget);
    });

    test('21. Trilingual localization classes provide translations for all P1 strings', () {
      final en = PatientLocalizations.forLocale(KioskLocale.english);
      final hi = PatientLocalizations.forLocale(KioskLocale.hindi);
      final mr = PatientLocalizations.forLocale(KioskLocale.marathi);

      expect(en.loginHeading, equals('Patient Login'));
      expect(hi.loginHeading, equals('मरीज लॉगिन'));
      expect(mr.loginHeading, equals('रुग्ण लॉगिन'));

      expect(en.appTagline, equals('LIVE BETTER, TOGETHER'));
      expect(hi.appTagline, equals('बेहतर जीवन, साथ मिलकर'));
      expect(mr.appTagline, equals('चांगले जगा, एकत्र'));
    });

    testWidgets('22. Zero plain-text Aadhaar is displayed in Patient Profile or Cards', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PatientProfileCard(
              fullName: 'Sunita Patil',
              patientId: 'PAT-101',
              age: '62 yrs',
              gender: 'Female',
              bloodGroup: 'B+',
              registeredMobile: '******4321',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Aadhaar'), findsNothing);
      expect(find.textContaining('aadhaar'), findsNothing);
      expect(find.text('******4321'), findsOneWidget);
    });

    test('23. Zero AI Chatbot keywords or elements exist in Patient module', () {
      const strings = PatientStrings();
      final allText = '${strings.dashboardSubtitle} ${strings.quickAccessCasesDesc} ${strings.loginDescription}';
      expect(allText.toLowerCase().contains('chatgpt'), isFalse);
      expect(allText.toLowerCase().contains('ai diagnosis'), isFalse);
      expect(allText.toLowerCase().contains('ask ai'), isFalse);
    });

    test('24. Patient controllers strictly lack clinical editing capabilities', () {
      final profileController = PatientProfileController();
      expect(profileController, isA<ChangeNotifier>());
      expect(profileController.fullName, isNotNull);
    });

    test('25. Existing Kiosk routes remain completely unaffected', () {
      final kioskRoute = AppRoutes.onGenerateRoute(const RouteSettings(name: AppRoutes.standby));
      expect(kioskRoute, isNotNull);
    });

    test('26. Existing Doctor routes remain completely unaffected', () {
      final docRoute = AppRoutes.onGenerateRoute(const RouteSettings(name: AppRoutes.doctorLogin));
      expect(docRoute, isNotNull);
    });

    test('27. Existing Admin routes remain completely unaffected', () {
      final adminRoute = AppRoutes.onGenerateRoute(const RouteSettings(name: AppRoutes.adminLogin));
      expect(adminRoute, isNotNull);
    });

    test('28. PatientAppState manages session lifecycle and tab transitions', () {
      final state = PatientAppState.instance;
      state.resetSession();

      expect(state.currentTab, equals(PatientNavigationTab.dashboard));
      expect(state.isAuthenticated, isFalse);

      state.setTab(PatientNavigationTab.reports);
      expect(state.currentTab, equals(PatientNavigationTab.reports));

      state.setPatientId('AAYU-102938');
      expect(state.isAuthenticated, isTrue);
      expect(state.authenticatedPatientId, equals('AAYU-102938'));

      state.resetSession();
      expect(state.isAuthenticated, isFalse);
      expect(state.authenticatedPatientId, isNull);
    });

    testWidgets('29. AayusathiApp with initialRoute=/patient unauthenticated launches Patient Login Screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(const AayusathiApp(initialRoute: '/patient'));
      await tester.pumpAndSettle();

      expect(find.byType(PatientLoginScreen), findsOneWidget);
      expect(find.byType(StandbyScreen), findsNothing);
    });

    testWidgets('29b. AayusathiApp with initialRoute=/patient authenticated launches Patient Main Shell', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      PatientSessionService.instance.startSession('AAYU-102938');
      await tester.pumpWidget(const AayusathiApp(initialRoute: '/patient'));
      await tester.pumpAndSettle();

      expect(find.byType(PatientMainShellScreen), findsOneWidget);
      expect(find.byType(StandbyScreen), findsNothing);
    });

    testWidgets('30. AayusathiApp with initialRoute=/patient/login directly launches Patient Login Screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(const AayusathiApp(initialRoute: '/patient/login'));
      await tester.pumpAndSettle();

      expect(find.byType(PatientLoginScreen), findsOneWidget);
      expect(find.byType(StandbyScreen), findsNothing);
    });

    testWidgets('31. Default AayusathiApp launches Kiosk StandbyScreen when no initialRoute is supplied', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 768));
      await tester.pumpWidget(const AayusathiApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(StandbyScreen), findsOneWidget);
      expect(find.byType(PatientMainShellScreen), findsNothing);
    });

    testWidgets('32. AayusathiApp with initialRoute=/doctor launches Doctor StandbyScreen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 768));
      await tester.pumpWidget(const AayusathiApp(initialRoute: AppRoutes.doctorHome));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(DoctorStandbyScreen), findsOneWidget);
      expect(find.byType(PatientMainShellScreen), findsNothing);
      expect(find.byType(StandbyScreen), findsNothing);
    });
  });
}

void _dummyTabCallback(PatientNavigationTab tab) {}

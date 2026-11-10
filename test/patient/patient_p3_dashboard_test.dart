import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/constants/app_assets.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/models/appointment_request.dart';
import 'package:aayusathi/models/patient.dart';
import 'package:aayusathi/patient/controllers/patient_dashboard_controller.dart';
import 'package:aayusathi/patient/localization/patient_localizations.dart';
import 'package:aayusathi/patient/localization/patient_strings.dart';
import 'package:aayusathi/patient/models/patient_app_state.dart';
import 'package:aayusathi/patient/models/patient_navigation_tab.dart';
import 'package:aayusathi/patient/screens/patient_dashboard_screen.dart';
import 'package:aayusathi/patient/screens/patient_login_screen.dart';
import 'package:aayusathi/patient/screens/patient_main_shell_screen.dart';
import 'package:aayusathi/patient/screens/patient_otp_screen.dart';
import 'package:aayusathi/patient/services/patient_session_service.dart';
import 'package:aayusathi/patient/theme/patient_theme.dart';
import 'package:aayusathi/patient/widgets/patient_bottom_navigation.dart';
import 'package:aayusathi/patient/widgets/patient_quick_access_card.dart';
import 'package:aayusathi/patient/widgets/patient_top_bar.dart';
import 'package:aayusathi/repositories/mock/mock_appointment_repository.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_patient_repository.dart';
import 'package:aayusathi/repositories/patient_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPatientRepository mockPatientRepo;
  late MockAppointmentRepository mockAppointmentRepo;
  late MockCaseRepository mockCaseRepo;
  late PatientSessionService sessionService;

  final testPatientA = Patient(
    patientId: 'PAT-P3-001',
    name: 'Rameshwar Patil',
    dateOfBirth: '1958-05-12',
    age: 68,
    gender: 'Male',
    phone: '9876543210',
    bloodGroup: 'B+',
    address: 'Pune, Maharashtra',
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    updatedAt: DateTime.now(),
    isActive: true,
  );

  final testPatientB = Patient(
    patientId: 'PAT-P3-002',
    name: 'Sunita Deshmukh',
    dateOfBirth: '1965-08-20',
    age: 61,
    gender: 'Female',
    phone: '9812345678',
    bloodGroup: 'O+',
    address: 'Nashik, Maharashtra',
    createdAt: DateTime.now().subtract(const Duration(days: 20)),
    updatedAt: DateTime.now(),
    isActive: true,
  );

  setUp(() async {
    BackendProvider.instance.setMode(BackendMode.mock);
    mockPatientRepo = MockPatientRepository.instance;
    mockAppointmentRepo = MockAppointmentRepository.instance;
    mockCaseRepo = MockCaseRepository.instance;
    sessionService = PatientSessionService.instance;

    mockPatientRepo.resetToDefaults();
    mockAppointmentRepo.clear();
    mockCaseRepo.resetToDefaults();
    PatientAppState.instance.resetSession();
    sessionService.logout();

    await mockPatientRepo.savePatient(testPatientA);
    await mockPatientRepo.savePatient(testPatientB);
  });

  group('Phase P3: Official Branding & Logo Asset Tests', () {
    testWidgets('1. Official AAYUSATHI logo asset is configured in AppAssets.logo', (tester) async {
      expect(AppAssets.logo, equals('assets/images/aayusathi_logo.png'));
    });

    testWidgets('2. PatientTopBar renders official AAYUSATHI logo asset', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: const Scaffold(
            appBar: PatientTopBar(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final imageWidget = tester.widget<Image>(imageFinder);
      expect((imageWidget.image as AssetImage).assetName, equals(AppAssets.logo));
    });

    testWidgets('3. PatientLoginScreen renders official AAYUSATHI logo asset', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: const PatientLoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final imageWidget = tester.widget<Image>(imageFinder);
      expect((imageWidget.image as AssetImage).assetName, equals(AppAssets.logo));
    });

    testWidgets('4. PatientOtpScreen renders official AAYUSATHI logo asset', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: const PatientOtpScreen(
            patientId: 'PAT-P3-001',
            maskedPhone: '+91 ******3210',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final imageWidget = tester.widget<Image>(imageFinder);
      expect((imageWidget.image as AssetImage).assetName, equals(AppAssets.logo));
    });
  });

  group('Phase P3: Patient Dashboard Controller & Data Integration', () {
    test('5. Controller loads authenticated patient data and personal details', () async {
      sessionService.startSession('PAT-P3-001');
      final controller = PatientDashboardController(
        patientRepo: mockPatientRepo,
        appointmentRepo: mockAppointmentRepo,
        caseRepo: mockCaseRepo,
        sessionService: sessionService,
      );

      await controller.loadDashboardData();

      expect(controller.patientDisplayName, equals('Rameshwar Patil'));
      expect(controller.patientIdDisplay, equals('PAT-P3-001'));
      expect(controller.bloodGroupDisplay, equals('B+'));
      expect(controller.ageGenderDisplay, contains('68 yrs'));
      expect(controller.ageGenderDisplay, contains('Male'));
    });

    test('6. Sourced time-of-day greeting (Morning, Afternoon, Evening)', () {
      final controller = PatientDashboardController(
        patientRepo: mockPatientRepo,
        patientId: 'PAT-P3-001',
      );
      const strings = PatientStrings();

      // Morning (8 AM)
      final morning = controller.getGreeting(strings, now: DateTime(2026, 9, 9, 8, 30));
      expect(morning, contains('Good Morning'));

      // Afternoon (2 PM)
      final afternoon = controller.getGreeting(strings, now: DateTime(2026, 9, 9, 14, 0));
      expect(afternoon, contains('Good Afternoon'));

      // Evening (7 PM)
      final evening = controller.getGreeting(strings, now: DateTime(2026, 9, 9, 19, 15));
      expect(evening, contains('Good Evening'));
    });

    test('7. Ongoing cases count only counts open cases for active patient', () async {
      sessionService.startSession('PAT-P3-001');

      // Create 2 open cases and 1 closed case for PAT-P3-001
      final case1 = ClinicalCase(
        caseId: 'CASE-001',
        patientId: 'PAT-P3-001',
        domain: 'Cardiology',
        title: 'Chest tightness',
        status: ClinicalCaseStatus.open,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        visitCount: 1,
      );
      final case2 = ClinicalCase(
        caseId: 'CASE-002',
        patientId: 'PAT-P3-001',
        domain: 'General Medicine',
        title: 'Fever and cold',
        status: ClinicalCaseStatus.open,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        visitCount: 1,
      );
      final case3Closed = ClinicalCase(
        caseId: 'CASE-003',
        patientId: 'PAT-P3-001',
        domain: 'Orthopedics',
        title: 'Knee pain',
        status: ClinicalCaseStatus.closed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        visitCount: 2,
      );

      // Create case for another patient PAT-P3-002
      final caseOther = ClinicalCase(
        caseId: 'CASE-004',
        patientId: 'PAT-P3-002',
        domain: 'Ophthalmology',
        title: 'Blurred vision',
        status: ClinicalCaseStatus.open,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        visitCount: 1,
      );

      await mockCaseRepo.createCase(case1);
      await mockCaseRepo.createCase(case2);
      await mockCaseRepo.createCase(case3Closed);
      await mockCaseRepo.createCase(caseOther);

      final controller = PatientDashboardController(
        patientRepo: mockPatientRepo,
        appointmentRepo: mockAppointmentRepo,
        caseRepo: mockCaseRepo,
        sessionService: sessionService,
      );

      await controller.loadDashboardData();

      // Should only count the 2 open cases for PAT-P3-001
      expect(controller.ongoingCasesCount, equals(2));
    });

    test('8. Next appointment resolves earliest active visit for patient', () async {
      sessionService.startSession('PAT-P3-001');

      final appt1 = AppointmentRequest(
        requestId: 'APT-001',
        patientId: 'PAT-P3-001',
        domainId: 'General Medicine',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.waiting,
        queueNumber: 'Q-101',
        createdAt: DateTime.now().add(const Duration(days: 2)),
        sessionId: 'sess-01',
        source: 'kiosk',
      );
      final appt2Later = AppointmentRequest(
        requestId: 'APT-002',
        patientId: 'PAT-P3-001',
        domainId: 'Cardiology',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.accepted,
        queueNumber: 'Q-102',
        createdAt: DateTime.now().add(const Duration(days: 5)),
        sessionId: 'sess-02',
        source: 'kiosk',
      );
      final apptOtherPatient = AppointmentRequest(
        requestId: 'APT-003',
        patientId: 'PAT-P3-002',
        domainId: 'Neurology',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.waiting,
        queueNumber: 'Q-999',
        createdAt: DateTime.now().add(const Duration(days: 1)),
        sessionId: 'sess-03',
        source: 'kiosk',
      );

      await mockAppointmentRepo.saveAppointment(appt1);
      await mockAppointmentRepo.saveAppointment(appt2Later);
      await mockAppointmentRepo.saveAppointment(apptOtherPatient);

      final controller = PatientDashboardController(
        patientRepo: mockPatientRepo,
        appointmentRepo: mockAppointmentRepo,
        caseRepo: mockCaseRepo,
        sessionService: sessionService,
      );

      await controller.loadDashboardData();

      expect(controller.hasUpcomingVisit, isTrue);
      expect(controller.nextVisit?.requestId, equals('APT-001'));
      expect(controller.nextVisit?.domainId, equals('General Medicine'));
      expect(controller.nextVisit?.queueNumber, equals('Q-101'));
    });

    test('9. Patient data isolation strictly filters by authenticated patient ID', () async {
      sessionService.startSession('PAT-P3-002');
      final controller = PatientDashboardController(
        patientRepo: mockPatientRepo,
        appointmentRepo: mockAppointmentRepo,
        caseRepo: mockCaseRepo,
        sessionService: sessionService,
      );

      await controller.loadDashboardData();

      expect(controller.patientDisplayName, equals('Sunita Deshmukh'));
      expect(controller.patientIdDisplay, equals('PAT-P3-002'));
    });
  });

  group('Phase P3: Dashboard Widget & UI Presentation Tests', () {
    testWidgets('10. Dashboard renders personalized greeting and patient name', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      sessionService.startSession('PAT-P3-001');

      final controller = PatientDashboardController(
        patientRepo: mockPatientRepo,
        appointmentRepo: mockAppointmentRepo,
        caseRepo: mockCaseRepo,
        sessionService: sessionService,
      );
      await controller.loadDashboardData();

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: Scaffold(
            body: PatientDashboardScreen(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Rameshwar Patil'), findsWidgets);
      expect(find.text('Welcome to your healthcare portal'), findsOneWidget);
    });

    testWidgets('11. Dashboard renders Next Visit with department, status, and token number', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      sessionService.startSession('PAT-P3-001');

      final appt = AppointmentRequest(
        requestId: 'APT-100',
        patientId: 'PAT-P3-001',
        domainId: 'Cardiology',
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        status: AppointmentStatus.accepted,
        queueNumber: 'Q-042',
        createdAt: DateTime(2026, 9, 15, 10, 30),
        sessionId: 'sess-100',
        source: 'kiosk',
      );
      await mockAppointmentRepo.saveAppointment(appt);

      final controller = PatientDashboardController(
        patientRepo: mockPatientRepo,
        appointmentRepo: mockAppointmentRepo,
        caseRepo: mockCaseRepo,
        sessionService: sessionService,
      );
      await controller.loadDashboardData();

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: Scaffold(
            body: PatientDashboardScreen(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NEXT VISIT'), findsOneWidget);
      expect(find.text('Cardiology'), findsOneWidget);
      expect(find.text('ACCEPTED'), findsOneWidget);
      expect(find.text('Q-042'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('SEP'), findsOneWidget);
    });

    testWidgets('12. Dashboard renders clean "No Upcoming Visits" empty state when no appointments exist', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      sessionService.startSession('PAT-P3-001');

      final controller = PatientDashboardController(
        patientRepo: mockPatientRepo,
        appointmentRepo: mockAppointmentRepo,
        caseRepo: mockCaseRepo,
        sessionService: sessionService,
      );
      await controller.loadDashboardData();

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: Scaffold(
            body: PatientDashboardScreen(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Upcoming Visits'), findsOneWidget);
      expect(find.text("You don't have a scheduled visit yet."), findsOneWidget);
    });

    testWidgets('13. Dashboard renders Ongoing Cases card with active count', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      sessionService.startSession('PAT-P3-001');

      final c1 = ClinicalCase(
        caseId: 'CASE-01',
        patientId: 'PAT-P3-001',
        domain: 'General Medicine',
        title: 'Fever',
        status: ClinicalCaseStatus.open,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        visitCount: 1,
      );
      await mockCaseRepo.createCase(c1);

      final controller = PatientDashboardController(
        patientRepo: mockPatientRepo,
        appointmentRepo: mockAppointmentRepo,
        caseRepo: mockCaseRepo,
        sessionService: sessionService,
      );
      await controller.loadDashboardData();

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: Scaffold(
            body: PatientDashboardScreen(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ONGOING CASES'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Active medical investigations'), findsOneWidget);
    });

    testWidgets('14. Dashboard renders clean "No Ongoing Cases" empty state when case count is 0', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      sessionService.startSession('PAT-P3-001');

      final controller = PatientDashboardController(
        patientRepo: mockPatientRepo,
        appointmentRepo: mockAppointmentRepo,
        caseRepo: mockCaseRepo,
        sessionService: sessionService,
      );
      await controller.loadDashboardData();

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: Scaffold(
            body: PatientDashboardScreen(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Ongoing Cases'), findsOneWidget);
      expect(find.text('You currently have no active cases.'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('15. Quick Access action cards switch to respective tabs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      sessionService.startSession('PAT-P3-001');

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: const PatientMainShellScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "View Cases"
      final casesCard = find.widgetWithText(PatientQuickAccessCard, 'View Cases');
      await tester.ensureVisible(casesCard);
      await tester.tap(casesCard);
      await tester.pumpAndSettle();
      expect(PatientAppState.instance.currentTab, equals(PatientNavigationTab.cases));

      // Tap "Dashboard" tab in bottom nav to return
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();
      expect(PatientAppState.instance.currentTab, equals(PatientNavigationTab.dashboard));

      // Tap "View Reports"
      final reportsCard = find.widgetWithText(PatientQuickAccessCard, 'View Reports');
      await tester.ensureVisible(reportsCard);
      await tester.tap(reportsCard);
      await tester.pumpAndSettle();
      expect(PatientAppState.instance.currentTab, equals(PatientNavigationTab.reports));

      // Tap "Dashboard" tab
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();

      // Tap "Calendar" Quick Access card
      final calendarCard = find.widgetWithText(PatientQuickAccessCard, 'Calendar');
      await tester.ensureVisible(calendarCard);
      await tester.tap(calendarCard);
      await tester.pumpAndSettle();
      expect(PatientAppState.instance.currentTab, equals(PatientNavigationTab.calendar));
    });

    testWidgets('16. Health Profile summary card displays authorized info (Patient ID, Age/Gender, Blood Group)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      sessionService.startSession('PAT-P3-001');

      final controller = PatientDashboardController(
        patientRepo: mockPatientRepo,
        appointmentRepo: mockAppointmentRepo,
        caseRepo: mockCaseRepo,
        sessionService: sessionService,
      );
      await controller.loadDashboardData();

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: Scaffold(
            body: PatientDashboardScreen(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HEALTH SUMMARY'), findsOneWidget);
      expect(find.text('PAT-P3-001'), findsOneWidget);
      expect(find.textContaining('68 yrs'), findsOneWidget);
      expect(find.text('B+'), findsOneWidget);
    });

    testWidgets('17. Dashboard error state displays friendly message with functional retry', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      final failingRepo = _FailingPatientRepository();
      final controller = PatientDashboardController(
        patientRepo: failingRepo,
        appointmentRepo: mockAppointmentRepo,
        caseRepo: mockCaseRepo,
        patientId: 'PAT-P3-001',
      );
      await controller.loadDashboardData();

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: Scaffold(
            body: PatientDashboardScreen(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to load your information.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      // Verify retry recovers when backend recovers
      failingRepo.shouldFail = false;
      await tester.tap(find.widgetWithText(ElevatedButton, 'Try Again'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Unable to load your information.'), findsNothing);
      expect(find.textContaining('Rameshwar Patil'), findsWidgets);
    });
  });

  group('Phase P3: Responsive Layout & Mobile Multi-Screen Tests', () {
    testWidgets('18. Mobile portrait rendering (360px - 430px) has ZERO RenderFlex overflow', (tester) async {
      sessionService.startSession('PAT-P3-001');

      final widths = [360.0, 375.0, 390.0, 412.0, 430.0];
      for (final w in widths) {
        await tester.binding.setSurfaceSize(Size(w, 800));
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(size: Size(w, 800)),
            child: MaterialApp(
              theme: PatientTheme.theme,
              home: const PatientMainShellScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Zero overflow on width $w px');
        expect(find.byType(PatientBottomNavigation), findsOneWidget);
        expect(find.byType(PatientTopBar), findsOneWidget);
      }
    });

    testWidgets('19. Senior-citizen accessibility: Buttons maintain minimum 48px touch targets', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: const PatientLoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final ctaButton = find.byType(ElevatedButton);
      expect(ctaButton, findsOneWidget);
      final size = tester.getSize(ctaButton);
      expect(size.height, greaterThanOrEqualTo(48.0));
    });
  });

  group('Phase P3: Privacy & Security Guardrails', () {
    testWidgets('20. Zero plain-text Aadhaar or unmasked mobile is exposed on Dashboard', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      sessionService.startSession('PAT-P3-001');

      final controller = PatientDashboardController(
        patientRepo: mockPatientRepo,
        appointmentRepo: mockAppointmentRepo,
        caseRepo: mockCaseRepo,
        sessionService: sessionService,
      );
      await controller.loadDashboardData();

      await tester.pumpWidget(
        MaterialApp(
          theme: PatientTheme.theme,
          home: Scaffold(
            body: PatientDashboardScreen(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Aadhaar'), findsNothing);
      expect(find.textContaining('aadhaar'), findsNothing);
      expect(find.textContaining('9876543210'), findsNothing); // Raw unmasked phone must never appear
    });
  });

  group('Phase P3: Trilingual Localization Verification', () {
    test('21. Dashboard strings exist for English, Hindi, and Marathi', () {
      final en = PatientLocalizations.forLocale(KioskLocale.english);
      final hi = PatientLocalizations.forLocale(KioskLocale.hindi);
      final mr = PatientLocalizations.forLocale(KioskLocale.marathi);

      expect(en.greetingMorning('Ramesh'), equals('Good Morning, Ramesh'));
      expect(hi.greetingMorning('रमेश'), equals('शुभ प्रभात, रमेश'));
      expect(mr.greetingMorning('रमेश'), equals('शुभ प्रभात, रमेश'));

      expect(en.noUpcomingVisitsTitle, equals('No Upcoming Visits'));
      expect(hi.noUpcomingVisitsTitle, equals('कोई आगामी मुलाकात नहीं'));
      expect(mr.noUpcomingVisitsTitle, equals('कोणतीही आगामी भेट नाही'));

      expect(en.noOngoingCasesTitle, equals('No Ongoing Cases'));
      expect(hi.noOngoingCasesTitle, equals('कोई सक्रिय केस नहीं'));
      expect(mr.noOngoingCasesTitle, equals('कोणतीही सक्रिय केस नाही'));

      expect(en.healthSummaryTitle, equals('Health Summary'));
      expect(hi.healthSummaryTitle, equals('स्वास्थ्य सारांश'));
      expect(mr.healthSummaryTitle, equals('आरोग्य सारांश'));
    });
  });
}

class _FailingPatientRepository implements PatientRepository {
  final MockPatientRepository _inner = MockPatientRepository.instance;
  bool shouldFail = true;

  @override
  Future<Patient?> getPatientById(String patientId) async {
    if (shouldFail) {
      throw Exception('Firestore network error');
    }
    return _inner.getPatientById(patientId);
  }

  @override
  Future<void> savePatient(Patient patient) => _inner.savePatient(patient);

  @override
  Future<void> createPatient(Patient patient) => _inner.createPatient(patient);

  @override
  Future<bool> patientExists(String patientId) => _inner.patientExists(patientId);
}

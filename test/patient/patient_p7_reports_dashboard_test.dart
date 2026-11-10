import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/doctor/models/clinical_visit.dart';
import 'package:aayusathi/doctor/models/investigation_request.dart';
import 'package:aayusathi/models/appointment_request.dart';
import 'package:aayusathi/models/patient.dart';
import 'package:aayusathi/patient/controllers/patient_dashboard_controller.dart';
import 'package:aayusathi/patient/controllers/patient_reports_controller.dart';
import 'package:aayusathi/patient/localization/patient_localizations.dart';
import 'package:aayusathi/patient/localization/patient_strings.dart';
import 'package:aayusathi/patient/models/patient_app_state.dart';
import 'package:aayusathi/patient/patient_routes.dart';
import 'package:aayusathi/patient/screens/patient_dashboard_screen.dart';
import 'package:aayusathi/patient/screens/patient_report_detail_screen.dart';
import 'package:aayusathi/patient/screens/patient_reports_screen.dart';
import 'package:aayusathi/patient/services/patient_session_service.dart';
import 'package:aayusathi/patient/theme/patient_theme.dart';
import 'package:aayusathi/patient/widgets/patient_empty_state_visual.dart';
import 'package:aayusathi/patient/widgets/patient_top_bar.dart';
import 'package:aayusathi/repositories/appointment_repository.dart';
import 'package:aayusathi/repositories/mock/mock_appointment_repository.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_investigation_repository.dart';
import 'package:aayusathi/repositories/mock/mock_patient_repository.dart';

class _FailingAppointmentRepository implements AppointmentRepository {
  bool shouldFail = true;
  final List<AppointmentRequest> appointments = [];

  @override
  Future<AppointmentRequest> saveAppointment(AppointmentRequest appointment) async {
    appointments.add(appointment);
    return appointment;
  }

  @override
  Future<List<AppointmentRequest>> getAppointmentsForPatient(String patientId) async {
    if (shouldFail) {
      throw Exception('PERMISSION_DENIED: Missing composite index or permissions.');
    }
    return appointments.where((a) => a.patientId == patientId).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AAYUSATHI P7 — Comprehensive Reports & Dashboard Resilience Suite', () {
    late _FailingAppointmentRepository failingApptRepo;
    final sessionService = PatientSessionService.instance;

    final testPatient = Patient(
      patientId: 'PAT-P7-001',
      name: 'Aarav Sharma',
      dateOfBirth: '14 May 1964',
      age: 62,
      gender: 'Male',
      phone: '9876543210',
      bloodGroup: 'O+',
      address: '104, Green Meadows, Pune',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    setUp(() async {
      BackendProvider.instance.setMode(BackendMode.mock);
      MockCaseRepository.instance.resetToDefaults();
      MockClinicalVisitRepository.instance.resetToDefaults();
      MockInvestigationRepository.instance.reset();
      MockPatientRepository.instance.resetToDefaults();
      MockAppointmentRepository.instance.clear();

      failingApptRepo = _FailingAppointmentRepository();

      await MockPatientRepository.instance.savePatient(testPatient);

      PatientAppState.instance.resetSession();
      sessionService.startSession('PAT-P7-001', authUid: 'test-auth-uid-p7');
      PatientAppState.instance.setAuthenticatedPatient(testPatient);
    });

    tearDown(() {
      PatientAppState.instance.resetSession();
      sessionService.logout();
    });

    Widget createTestWidget(Widget child, {Locale locale = const Locale('en')}) {
      return MaterialApp(
        locale: locale,
        theme: PatientTheme.theme,
        onGenerateRoute: PatientRoutes.onGenerateRoute,
        home: PatientLocalizations.provider(
          strings: PatientLocalizations.forLocaleCode(locale.languageCode),
          child: child,
        ),
      );
    }

    // -------------------------------------------------------------
    // PART A: REPORTS SCREEN & TABS
    // -------------------------------------------------------------

    testWidgets('1. Reports screen renders header and two segmented tabs: SUBMITTED and YET TO SUBMIT', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      final controller = PatientReportsController(sessionService: sessionService);

      await tester.pumpWidget(createTestWidget(PatientReportsScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('SUBMITTED'), findsOneWidget);
      expect(find.text('YET TO SUBMIT'), findsOneWidget);
    });

    testWidgets('2. Empty states: "No Submitted Reports" on Tab 1, "No Reports Required" on Tab 2', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      final controller = PatientReportsController(sessionService: sessionService);

      await tester.pumpWidget(createTestWidget(PatientReportsScreen(controller: controller)));
      await tester.pumpAndSettle();

      // Tab 1 default: Submitted
      expect(find.text('No Submitted Reports'), findsOneWidget);
      expect(find.text("You haven't submitted any reports yet."), findsOneWidget);
      expect(find.byType(PatientEmptyStateVisual), findsOneWidget);

      // Switch to Tab 2: Yet to Submit
      await tester.tap(find.text('YET TO SUBMIT'));
      await tester.pumpAndSettle();

      expect(find.text('No Reports Required'), findsOneWidget);
      expect(find.text("You currently don't have any reports waiting for submission."), findsOneWidget);
      expect(find.byType(PatientEmptyStateVisual), findsOneWidget);
    });

    testWidgets('3. Populated reports: Submitted tab renders uploaded and reviewed cards with dates & case info', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));

      final testCase = ClinicalCase(
        caseId: 'CASE-P7-001',
        patientId: 'PAT-P7-001',
        domain: 'General Medicine',
        title: 'Acute Viral Fever',
        status: ClinicalCaseStatus.open,
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
        visitCount: 1,
      );
      await MockCaseRepository.instance.createCase(testCase);

      final testVisit = ClinicalVisit(
        visitId: 'VIS-P7-001',
        caseId: 'CASE-P7-001',
        patientId: 'PAT-P7-001',
        doctorId: 'DOC-1',
        doctorName: 'Dr. Neha Verma',
        visitNumber: 1,
        startedAt: DateTime(2026, 9, 5, 10, 0),
        status: ClinicalVisitStatus.completed,
      );
      await MockClinicalVisitRepository.instance.createVisit(testVisit);

      // 1 Uploaded, 1 Reviewed
      await MockInvestigationRepository.instance.createInvestigationRequest(
        InvestigationRequest(
          requestId: 'INV-101',
          patientId: 'PAT-P7-001',
          caseId: 'CASE-P7-001',
          visitId: 'VIS-P7-001',
          name: 'Complete Blood Count (CBC)',
          status: InvestigationStatus.uploaded,
          requestedAt: DateTime(2026, 9, 5),
          uploadedAt: DateTime(2026, 9, 6),
        ),
      );
      await MockInvestigationRepository.instance.createInvestigationRequest(
        InvestigationRequest(
          requestId: 'INV-102',
          patientId: 'PAT-P7-001',
          caseId: 'CASE-P7-001',
          visitId: 'VIS-P7-001',
          name: 'Chest X-Ray PA View',
          status: InvestigationStatus.reviewed,
          requestedAt: DateTime(2026, 9, 5),
          uploadedAt: DateTime(2026, 9, 7),
          reviewedAt: DateTime(2026, 9, 8),
        ),
      );

      final controller = PatientReportsController(sessionService: sessionService);

      await tester.pumpWidget(createTestWidget(PatientReportsScreen(controller: controller)));
      await tester.pumpAndSettle();

      // Verify Submitted cards render
      expect(find.text('Complete Blood Count (CBC)'), findsOneWidget);
      expect(find.text('Chest X-Ray PA View'), findsOneWidget);
      expect(find.text('Submitted'), findsOneWidget);
      expect(find.text('Reviewed'), findsOneWidget);
      expect(find.text('Acute Viral Fever'), findsNWidgets(2));
      expect(find.text('View Report'), findsNWidgets(2));
    });

    testWidgets('4. Populated reports: Yet to Submit tab renders pending tests with Submit Report button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));

      final testCase = ClinicalCase(
        caseId: 'CASE-P7-002',
        patientId: 'PAT-P7-001',
        domain: 'Cardiology',
        title: 'Hypertension Follow-up',
        status: ClinicalCaseStatus.open,
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
        visitCount: 1,
      );
      await MockCaseRepository.instance.createCase(testCase);

      final testVisit = ClinicalVisit(
        visitId: 'VIS-P7-002',
        caseId: 'CASE-P7-002',
        patientId: 'PAT-P7-001',
        doctorId: 'DOC-2',
        visitNumber: 1,
        startedAt: DateTime(2026, 9, 8),
        status: ClinicalVisitStatus.active,
      );
      await MockClinicalVisitRepository.instance.createVisit(testVisit);

      await MockInvestigationRepository.instance.createInvestigationRequest(
        InvestigationRequest(
          requestId: 'INV-201',
          patientId: 'PAT-P7-001',
          caseId: 'CASE-P7-002',
          visitId: 'VIS-P7-002',
          name: 'Serum Creatinine & Electrolytes',
          priority: InvestigationPriority.required,
          status: InvestigationStatus.pendingUpload,
          requestedAt: DateTime(2026, 9, 8),
        ),
      );

      final controller = PatientReportsController(sessionService: sessionService);

      await tester.pumpWidget(createTestWidget(PatientReportsScreen(controller: controller)));
      await tester.pumpAndSettle();

      // Switch to Yet to Submit tab
      await tester.tap(find.text('YET TO SUBMIT'));
      await tester.pumpAndSettle();

      expect(find.text('Serum Creatinine & Electrolytes'), findsOneWidget);
      expect(find.text('REQUIRED'), findsOneWidget);
      expect(find.text('Report Required'), findsOneWidget);
      expect(find.text('Submit Report'), findsOneWidget);
    });

    testWidgets('5. Tapping Submit Report displays senior-friendly submission guidance modal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));

      final testCase = ClinicalCase(
        caseId: 'CASE-P7-003',
        patientId: 'PAT-P7-001',
        domain: 'Pathology',
        title: 'Routine Blood Panel',
        status: ClinicalCaseStatus.open,
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
        visitCount: 1,
      );
      await MockCaseRepository.instance.createCase(testCase);

      final testVisit = ClinicalVisit(
        visitId: 'VIS-P7-003',
        caseId: 'CASE-P7-003',
        patientId: 'PAT-P7-001',
        doctorId: 'DOC-3',
        visitNumber: 1,
        startedAt: DateTime(2026, 9, 9),
        status: ClinicalVisitStatus.active,
      );
      await MockClinicalVisitRepository.instance.createVisit(testVisit);

      await MockInvestigationRepository.instance.createInvestigationRequest(
        InvestigationRequest(
          requestId: 'INV-301',
          patientId: 'PAT-P7-001',
          caseId: 'CASE-P7-003',
          visitId: 'VIS-P7-003',
          name: 'Thyroid Stimulating Hormone (TSH)',
          priority: InvestigationPriority.required,
          status: InvestigationStatus.pendingUpload,
          requestedAt: DateTime(2026, 9, 9),
        ),
      );

      final controller = PatientReportsController(sessionService: sessionService);

      await tester.pumpWidget(createTestWidget(PatientReportsScreen(controller: controller)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('YET TO SUBMIT'));
      await tester.pumpAndSettle();

      // Tap "Submit Report"
      await tester.tap(find.text('Submit Report'));
      await tester.pumpAndSettle();

      // Verify Guidance Dialog opens
      expect(find.text('Report Submission Guidance'), findsOneWidget);
      expect(find.textContaining('hospital collection center or during your next consultation visit'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Report Submission Guidance'), findsNothing);
    });

    testWidgets('6. Context navigation from Visit Details highlights target investigation in Yet to Submit tab', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));

      final testCase = ClinicalCase(
        caseId: 'CASE-P7-004',
        patientId: 'PAT-P7-001',
        domain: 'Pulmonology',
        title: 'Persistent Cough Evaluation',
        status: ClinicalCaseStatus.open,
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
        visitCount: 1,
      );
      await MockCaseRepository.instance.createCase(testCase);

      final testVisit = ClinicalVisit(
        visitId: 'VIS-P7-004',
        caseId: 'CASE-P7-004',
        patientId: 'PAT-P7-001',
        doctorId: 'DOC-4',
        visitNumber: 1,
        startedAt: DateTime(2026, 9, 9),
        status: ClinicalVisitStatus.active,
      );
      await MockClinicalVisitRepository.instance.createVisit(testVisit);

      await MockInvestigationRepository.instance.createInvestigationRequest(
        InvestigationRequest(
          requestId: 'INV-401',
          patientId: 'PAT-P7-001',
          caseId: 'CASE-P7-004',
          visitId: 'VIS-P7-004',
          name: 'Spirometry Pulmonary Function',
          status: InvestigationStatus.pendingUpload,
          requestedAt: DateTime(2026, 9, 9),
        ),
      );
      await MockInvestigationRepository.instance.createInvestigationRequest(
        InvestigationRequest(
          requestId: 'INV-TARGET',
          patientId: 'PAT-P7-001',
          caseId: 'CASE-P7-004',
          visitId: 'VIS-P7-004',
          name: 'High-Resolution Chest CT',
          priority: InvestigationPriority.required,
          status: InvestigationStatus.pendingUpload,
          requestedAt: DateTime(2026, 9, 9),
        ),
      );

      // Trigger navigation from visit details
      PatientAppState.instance.navigateToReportsWithInvestigation('INV-TARGET');

      final controller = PatientReportsController(sessionService: sessionService);

      await tester.pumpWidget(createTestWidget(PatientReportsScreen(controller: controller)));
      await tester.pumpAndSettle();

      // Controller must have switched to Yet to Submit automatically
      expect(controller.selectedTab, equals(PatientReportsTab.yetToSubmit));
      expect(find.text('High-Resolution Chest CT'), findsOneWidget);

      // Verify highlighted card visual indicator
      expect(find.text('REPORT REQUIRED'), findsOneWidget);
    });

    testWidgets('7. Report Detail screen displays metadata and has ZERO internal raw ID leakage', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));

      final report = InvestigationRequest(
        requestId: 'INV-SECRET-999',
        patientId: 'PAT-P7-001',
        caseId: 'CASE-P7-001',
        visitId: 'VIS-P7-001',
        name: 'Lipid Profile Assessment',
        status: InvestigationStatus.uploaded,
        requestedAt: DateTime(2026, 9, 1),
        uploadedAt: DateTime(2026, 9, 2),
      );

      await tester.pumpWidget(
        createTestWidget(
          PatientReportDetailScreen(
            reportId: report.requestId,
            preloadedReport: report,
            caseTitle: 'Cardiovascular Risk Check',
            visitDate: DateTime(2026, 9, 1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Report Details'), findsOneWidget);
      expect(find.text('Lipid Profile Assessment'), findsOneWidget);
      expect(find.text('Cardiovascular Risk Check'), findsOneWidget);
      expect(find.text('Submitted'), findsOneWidget);

      // STRICT ZERO ID LEAKAGE
      expect(find.textContaining('ID: INV-SECRET-999'), findsNothing);
      expect(find.text('INV-SECRET-999'), findsNothing);
    });

    // -------------------------------------------------------------
    // PART B: DASHBOARD RUNTIME ERROR FIX & BOUNDARY ISOLATION
    // -------------------------------------------------------------

    testWidgets('8. Dashboard partial failure: Failed appointments query does NOT crash profile or ongoing cases', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));

      // 1 open case
      await MockCaseRepository.instance.createCase(
        ClinicalCase(
          caseId: 'CASE-LIVE-1',
          patientId: 'PAT-P7-001',
          domain: 'General',
          title: 'Active Observation',
          status: ClinicalCaseStatus.open,
          createdAt: DateTime(2026, 9, 1),
          updatedAt: DateTime(2026, 9, 1),
          visitCount: 1,
        ),
      );

      // Appointment repo fails with permission-denied
      failingApptRepo.shouldFail = true;

      final controller = PatientDashboardController(
        patientRepo: MockPatientRepository.instance,
        appointmentRepo: failingApptRepo,
        caseRepo: MockCaseRepository.instance,
        sessionService: sessionService,
      );

      await tester.pumpWidget(createTestWidget(PatientDashboardScreen(controller: controller)));
      await tester.pumpAndSettle();

      // Profile & Greeting render properly
      expect(find.textContaining('Aarav Sharma'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('ONGOING CASES'), findsOneWidget);

      // ZERO global "Unable to load your information." banner!
      expect(find.text('Unable to load your information.'), findsNothing);

      // Next visit card shows isolated friendly retry state
      expect(find.text('Unable to load upcoming visits.\nPlease try again.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      // When appointment service recovers and user taps retry
      failingApptRepo.shouldFail = false;
      await failingApptRepo.saveAppointment(
        AppointmentRequest(
          requestId: 'APT-RECOVERED',
          patientId: 'PAT-P7-001',
          domainId: 'Cardiology',
          preferredDoctorMode: PreferredDoctorMode.anyDoctor,
          status: AppointmentStatus.accepted,
          queueNumber: 'Q-01',
          createdAt: DateTime(2026, 9, 20),
          sessionId: 'sess-1',
          source: 'kiosk',
        ),
      );

      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      // Appointments recovers smoothly
      expect(find.text('Cardiology'), findsOneWidget);
      expect(find.text('Q-01'), findsOneWidget);
      expect(find.text('Unable to load upcoming visits.\nPlease try again.'), findsNothing);
    });

    testWidgets('9. Dashboard valid zero states (0 cases, 0 appointments) display clean reassurance with ZERO errors', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));

      final controller = PatientDashboardController(
        patientRepo: MockPatientRepository.instance,
        appointmentRepo: MockAppointmentRepository.instance,
        caseRepo: MockCaseRepository.instance,
        sessionService: sessionService,
      );

      await tester.pumpWidget(createTestWidget(PatientDashboardScreen(controller: controller)));
      await tester.pumpAndSettle();

      // Reassuring zero states
      expect(find.text('No Ongoing Cases'), findsOneWidget);
      expect(find.text('No Upcoming Visits'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);

      // Absolutely ZERO error banners
      expect(find.text('Unable to load your information.'), findsNothing);
      expect(find.byIcon(Icons.sync_problem_rounded), findsNothing);
    });

    // -------------------------------------------------------------
    // PART C: HEADER, BRANDING & UI INTEGRITY
    // -------------------------------------------------------------

    testWidgets('10. PatientTopBar renders approved AAYUSATHI branding and profile button with ZERO social icons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));

      await tester.pumpWidget(createTestWidget(const Scaffold(appBar: PatientTopBar())));
      await tester.pumpAndSettle();

      expect(find.byType(PatientTopBar), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);

      // Verify ZERO social media icons exist in widget tree
      expect(find.byIcon(Icons.share), findsNothing);
      expect(find.byIcon(Icons.thumb_up), findsNothing);
    });

    testWidgets('11. Responsive layout: Reports screen renders without overflow on mobile (360-430dp), tablet and desktop', (tester) async {
      final widths = [360.0, 390.0, 412.0, 430.0, 768.0, 1280.0];

      for (final width in widths) {
        await tester.binding.setSurfaceSize(Size(width, 915));

        final controller = PatientReportsController(sessionService: sessionService);

        await tester.pumpWidget(createTestWidget(PatientReportsScreen(controller: controller)));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Overflow detected on width $width');
      }
    });

    testWidgets('12. Trilingual localization: Reports strings exist in English, Hindi, and Marathi', (tester) async {
      const en = PatientStrings();
      const hi = PatientStringsHindi();
      const mr = PatientStringsMarathi();

      expect(en.reportsScreenTitle, isNotEmpty);
      expect(hi.reportsScreenTitle, isNotEmpty);
      expect(mr.reportsScreenTitle, isNotEmpty);

      expect(en.reportsTabSubmitted, equals('SUBMITTED'));
      expect(hi.reportsTabSubmitted, isNotEmpty);
      expect(mr.reportsTabSubmitted, isNotEmpty);

      expect(en.reportsTabYetToSubmit, equals('YET TO SUBMIT'));
      expect(hi.reportsTabYetToSubmit, isNotEmpty);
      expect(mr.reportsTabYetToSubmit, isNotEmpty);

      expect(en.submitReportAction, isNotEmpty);
      expect(hi.submitReportAction, isNotEmpty);
      expect(mr.submitReportAction, isNotEmpty);

      expect(en.submitReportGuidanceTitle, isNotEmpty);
      expect(hi.submitReportGuidanceTitle, isNotEmpty);
      expect(mr.submitReportGuidanceTitle, isNotEmpty);

      expect(en.unableToLoadReports, isNotEmpty);
      expect(hi.unableToLoadReports, isNotEmpty);
      expect(mr.unableToLoadReports, isNotEmpty);

      expect(en.unableToLoadAppointments, isNotEmpty);
      expect(hi.unableToLoadAppointments, isNotEmpty);
      expect(mr.unableToLoadAppointments, isNotEmpty);
    });
  });
}

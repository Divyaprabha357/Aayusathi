import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/doctor/models/clinical_visit.dart';
import 'package:aayusathi/doctor/models/investigation_request.dart';
import 'package:aayusathi/doctor/models/prescription_item.dart';
import 'package:aayusathi/patient/localization/patient_localizations.dart';
import 'package:aayusathi/patient/models/patient_app_state.dart';
import 'package:aayusathi/patient/models/patient_navigation_tab.dart';
import 'package:aayusathi/patient/patient_routes.dart';
import 'package:aayusathi/patient/screens/patient_case_detail_screen.dart';
import 'package:aayusathi/patient/screens/patient_cases_screen.dart';
import 'package:aayusathi/patient/screens/patient_dashboard_screen.dart';
import 'package:aayusathi/patient/screens/patient_main_shell_screen.dart';
import 'package:aayusathi/patient/screens/patient_reports_screen.dart';
import 'package:aayusathi/patient/screens/patient_visit_detail_screen.dart';
import 'package:aayusathi/patient/services/patient_session_service.dart';
import 'package:aayusathi/patient/theme/patient_theme.dart';
import 'package:aayusathi/patient/widgets/patient_empty_state_visual.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_investigation_repository.dart';
import 'package:aayusathi/repositories/mock/mock_patient_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    BackendProvider.instance.setMode(BackendMode.mock);
    MockCaseRepository.instance.resetToDefaults();
    MockClinicalVisitRepository.instance.resetToDefaults();
    MockInvestigationRepository.instance.reset();
    MockPatientRepository.instance.resetToDefaults();
    PatientAppState.instance.resetSession();
    PatientSessionService.instance.startSession('PAT-MOCK-001', authUid: 'test-auth-uid-001');
  });

  tearDown(() {
    PatientAppState.instance.resetSession();
    PatientSessionService.instance.logout();
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

  group('P6 Dedicated Tests: Visit Details, Investigations, Report Required & UI Polish', () {
    // 1. Visit Details loads
    testWidgets('1. Visit Details loads with headers, doctor, department, date, and status', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          const PatientVisitDetailScreen(
            caseId: 'CASE-PAT-001-01',
            visitId: 'VIS-PAT-001-01-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Visit Details'), findsWidgets);
      expect(find.text('Visit 1'), findsOneWidget);
      expect(find.text('General Medicine'), findsOneWidget);
      expect(find.text('Dr. Rajesh Sharma'), findsOneWidget);
      expect(find.text('MBBS, MD (Cardiology)'), findsOneWidget);
      expect(find.text('Completed'), findsWidgets);
    });

    // 2. Correct visit selected
    testWidgets('2. Correct visit selected and renders matching clinical information', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          const PatientVisitDetailScreen(
            caseId: 'CASE-PAT-001-01',
            visitId: 'VIS-PAT-001-01-2',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Visit 2'), findsOneWidget);
      expect(find.text('Follow-up on blood pressure control and ECG review.'), findsOneWidget);
    });

    // 3. Patient ownership
    testWidgets('3. Patient ownership enforced - unauthorized patient sees error view', (tester) async {
      PatientSessionService.instance.logout();
      PatientSessionService.instance.startSession('UNAUTHORIZED-PATIENT', authUid: 'unauth-uid');

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          const PatientVisitDetailScreen(
            caseId: 'CASE-PAT-001-01',
            visitId: 'VIS-PAT-001-01-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to load visit history.\nPlease try again.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    // 4. Vitals
    testWidgets('4. Vitals grid renders SpO2, Heart Rate, and Temperature', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          const PatientVisitDetailScreen(
            caseId: 'CASE-PAT-001-01',
            visitId: 'VIS-PAT-001-01-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vitals'), findsOneWidget);
      expect(find.text('SpO₂'), findsOneWidget);
      expect(find.text('Blood Pressure'), findsNothing);
      expect(find.text('Heart Rate'), findsOneWidget);
      expect(find.text('Temperature'), findsOneWidget);
    });

    // 5. Missing vitals
    testWidgets('5. Missing vitals displays Not recorded fallback for all metrics', (tester) async {
      final visitNoVitals = ClinicalVisit(
        visitId: 'VIS-NO-VIT',
        caseId: 'CASE-PAT-001-01',
        patientId: 'PAT-MOCK-001',
        doctorId: 'DOC-101',
        doctorName: 'Dr. Rajesh Sharma',
        visitNumber: 3,
        startedAt: DateTime.now(),
        status: ClinicalVisitStatus.active,
        chiefComplaint: 'Routine checkup without sensors',
      );

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          PatientVisitDetailScreen(
            caseId: 'CASE-PAT-001-01',
            visitId: 'VIS-NO-VIT',
            preloadedVisit: visitNoVitals,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Not recorded'), findsNWidgets(3));
    });

    // 6. Doctor-approved summary
    testWidgets('6. Doctor-approved summary displays approved badge and effective text', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          const PatientVisitDetailScreen(
            caseId: 'CASE-PAT-001-01',
            visitId: 'VIS-PAT-001-01-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Doctor-Approved Summary'), findsOneWidget);
      expect(find.text('APPROVED BY DOCTOR'), findsOneWidget);
      expect(find.text('Initial consultation for elevated blood pressure and exertional dyspnea.'), findsOneWidget);
    });

    // 7. Consultation sections
    testWidgets('7. Structured consultation sections render Chief Complaint, History, Findings, Assessment, Plan', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          const PatientVisitDetailScreen(
            caseId: 'CASE-PAT-001-01',
            visitId: 'VIS-PAT-001-01-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Consultation Details'), findsOneWidget);
      expect(find.text('Chief Complaint'), findsOneWidget);
      expect(find.text('Chest tightness and shortness of breath during exertion.'), findsOneWidget);
      expect(find.text('Assessment'), findsOneWidget);
      expect(find.text('Plan'), findsOneWidget);
    });

    // 8. Prescription
    testWidgets('8. Prescription items render with medicine name, duration, frequency, and remarks', (tester) async {
      final visitWithPrescription = ClinicalVisit(
        visitId: 'VIS-PRES-01',
        caseId: 'CASE-PAT-001-01',
        patientId: 'PAT-MOCK-001',
        doctorId: 'DOC-101',
        doctorName: 'Dr. Rajesh Sharma',
        visitNumber: 1,
        startedAt: DateTime.now(),
        prescriptions: const [
          PrescriptionItem(
            medicineName: 'Metoprolol Succinate 25mg',
            duration: '30 days',
            timesPerDay: 'Once daily with meal',
            remarks: 'Do not discontinue abruptly',
          ),
        ],
      );

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          PatientVisitDetailScreen(
            caseId: 'CASE-PAT-001-01',
            visitId: 'VIS-PRES-01',
            preloadedVisit: visitWithPrescription,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Prescriptions'), findsOneWidget);
      expect(find.text('Metoprolol Succinate 25mg'), findsOneWidget);
      expect(find.text('Once daily with meal • 30 days'), findsOneWidget);
      expect(find.text('Do not discontinue abruptly'), findsOneWidget);
    });

    // 9. Follow-up
    testWidgets('9. Follow-up timeframe and instructions render properly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          const PatientVisitDetailScreen(
            caseId: 'CASE-PAT-001-01',
            visitId: 'VIS-PAT-001-01-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Follow-up'), findsOneWidget);
      expect(find.text('Review in 2 weeks with ECG and Lipid profile results.'), findsOneWidget);
      expect(find.textContaining('Low sodium diet'), findsOneWidget);
    });

    // 10. Investigation display
    testWidgets('10. Investigation card displays requested diagnostic tests with name and priority', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          const PatientVisitDetailScreen(
            caseId: 'CASE-PAT-001-01',
            visitId: 'VIS-PAT-001-01-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Requested Investigations'), findsOneWidget);
      expect(find.text('12-Lead Electrocardiogram (ECG)'), findsOneWidget);
      expect(find.text('Comprehensive Lipid Profile'), findsOneWidget);
      expect(find.text('REQUIRED'), findsNWidgets(2));
    });

    // 11. Pending Upload shows Report Required
    testWidgets('11. Pending Upload status displays Pending Upload badge and Report Required action button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          const PatientVisitDetailScreen(
            caseId: 'CASE-PAT-001-01',
            visitId: 'VIS-PAT-001-01-2',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2D Echocardiography'), findsOneWidget);
      expect(find.text('Pending Upload'), findsOneWidget);
      expect(find.text('Report Required'), findsOneWidget);
    });

    // 12. Uploaded status
    testWidgets('12. Uploaded status displays Report Submitted badge', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          const PatientVisitDetailScreen(
            caseId: 'CASE-PAT-001-01',
            visitId: 'VIS-PAT-001-01-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Report Submitted'), findsNWidgets(2));
    });

    // 13. Reviewed status
    testWidgets('13. Reviewed status displays Report Reviewed badge', (tester) async {
      final visitReviewed = ClinicalVisit(
        visitId: 'VIS-REV-01',
        caseId: 'CASE-PAT-001-01',
        patientId: 'PAT-MOCK-001',
        doctorId: 'DOC-101',
        doctorName: 'Dr. Rajesh Sharma',
        visitNumber: 1,
        startedAt: DateTime.now(),
        investigationRequests: [
          InvestigationRequest(
            requestId: 'REQ-REV-001',
            name: 'Blood Sugar Fasting',
            priority: InvestigationPriority.required,
            status: InvestigationStatus.reviewed,
            requestedAt: DateTime.now(),
          ),
        ],
      );

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          PatientVisitDetailScreen(
            caseId: 'CASE-PAT-001-01',
            visitId: 'VIS-REV-01',
            preloadedVisit: visitReviewed,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Blood Sugar Fasting'), findsOneWidget);
      expect(find.text('Report Reviewed'), findsOneWidget);
    });

    // 14. Report Required navigation
    testWidgets('14. Tapping Report Required switches to Reports tab and passes investigation ID', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          const PatientVisitDetailScreen(
            caseId: 'CASE-PAT-001-01',
            visitId: 'VIS-PAT-001-01-2',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Report Required'), findsOneWidget);
      await tester.ensureVisible(find.text('Report Required'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Report Required'));
      await tester.pumpAndSettle();

      // State check: App state should be switched to Reports tab with target investigation set
      expect(PatientAppState.instance.currentTab, equals(PatientNavigationTab.reports));
      expect(PatientAppState.instance.targetInvestigationId, equals('REQ-INV-003'));
    });

    // 15. Correct report context in Reports screen
    testWidgets('15. Reports screen opens Yet to Submit tab when target investigation is set', (tester) async {
      PatientAppState.instance.navigateToReportsWithInvestigation('REQ-INV-003');

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          const PatientReportsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // In reports screen, Yet to Submit should be active
      expect(find.text('YET TO SUBMIT'), findsOneWidget);
      expect(find.text('SUBMITTED'), findsOneWidget);
    });

    // 16. Empty investigation state
    testWidgets('16. Empty investigation list displays reassurance message', (tester) async {
      final visitNoInv = ClinicalVisit(
        visitId: 'VIS-NO-INV',
        caseId: 'CASE-PAT-001-01',
        patientId: 'PAT-MOCK-001',
        doctorId: 'DOC-101',
        doctorName: 'Dr. Rajesh Sharma',
        visitNumber: 1,
        startedAt: DateTime.now(),
        investigationRequests: const [],
      );

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          PatientVisitDetailScreen(
            caseId: 'CASE-PAT-001-01',
            visitId: 'VIS-NO-INV',
            preloadedVisit: visitNoInv,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No diagnostic investigations requested for this visit.'), findsOneWidget);
    });

    // 17. Error state
    testWidgets('17. Error state renders when visit retrieval fails', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          const PatientVisitDetailScreen(
            caseId: 'CASE-NONEXISTENT',
            visitId: 'VIS-NONEXISTENT',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to load visit history.\nPlease try again.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    // 18. Retry button reloads visit details
    testWidgets('18. Retry button reloads visit details on tap', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          const PatientVisitDetailScreen(
            caseId: 'CASE-NONEXISTENT',
            visitId: 'VIS-NONEXISTENT',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Try Again'), findsOneWidget);
      await tester.tap(find.text('Try Again'));
      await tester.pump();
      expect(find.byType(PatientVisitDetailScreen), findsOneWidget);
    });

    // 19. Read-only enforcement
    testWidgets('19. Read-only enforcement: zero edit buttons exist on the screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          const PatientVisitDetailScreen(
            caseId: 'CASE-PAT-001-01',
            visitId: 'VIS-PAT-001-01-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit), findsNothing);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Update'), findsNothing);
      expect(find.text('Save'), findsNothing);
    });

    // 20. Cases regression check
    testWidgets('20. Cases screen regression: Active and Completed tabs switch smoothly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          const PatientCasesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cases'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      // Active tab shows the active case
      expect(find.text('Hypertension & Exertional Dyspnea'), findsOneWidget);

      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      // Completed tab shows the closed case
      expect(find.text('Right Knee Sprain'), findsOneWidget);
    });

    // 21. P5 regression check: Case details and visit history timeline
    testWidgets('21. P5 regression: Case details and reverse chronological visit timeline', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          const PatientCaseDetailScreen(caseId: 'CASE-PAT-001-01'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Case Details'), findsWidgets);
      expect(find.text('Visit History'), findsOneWidget);
      expect(find.text('Visit 2'), findsOneWidget);
      expect(find.text('Visit 1'), findsOneWidget);
    });

    // 22. P4 regression check: No ongoing cases when zero active cases
    testWidgets('22. P4 regression: Cases screen handles zero active cases without error', (tester) async {
      PatientSessionService.instance.logout();
      PatientSessionService.instance.startSession('PAT-EMPTY-001', authUid: 'empty-uid');

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          const PatientCasesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Ongoing Cases'), findsOneWidget);
      expect(find.text('You currently have no active cases.'), findsOneWidget);
      expect(find.text('View Dashboard'), findsOneWidget);
    });

    // 23. P3 regression check: Dashboard renders all cards
    testWidgets('23. P3 regression: Dashboard renders quick access, ongoing cases, and next visit card', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          const PatientDashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ONGOING CASES'), findsOneWidget);
      expect(find.text('QUICK ACCESS'), findsOneWidget);
      expect(find.text('NEXT VISIT'), findsOneWidget);
    });

    // 24. Four-tab navigation
    testWidgets('24. Four-tab bottom navigation remains stationary and functional', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          const PatientMainShellScreen(initialTab: PatientNavigationTab.dashboard),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Cases'), findsWidgets);
      expect(find.text('Reports'), findsWidgets);
      expect(find.text('Calendar'), findsWidgets);

      // Tap Cases tab
      await tester.tap(find.text('Cases').last);
      await tester.pumpAndSettle();
      expect(PatientAppState.instance.currentTab, equals(PatientNavigationTab.cases));

      // Tap Reports tab
      await tester.tap(find.text('Reports').last);
      await tester.pumpAndSettle();
      expect(PatientAppState.instance.currentTab, equals(PatientNavigationTab.reports));
    });

    // 25. Responsive layout across 360, 375, 390, 412, 430 dp widths
    testWidgets('25. Responsive layout renders without RenderFlex overflow across phone widths', (tester) async {
      for (final width in [360.0, 375.0, 390.0, 412.0, 430.0]) {
        await tester.binding.setSurfaceSize(Size(width, 844));

        await tester.pumpWidget(
          createTestWidget(
            const PatientVisitDetailScreen(
              caseId: 'CASE-PAT-001-01',
              visitId: 'VIS-PAT-001-01-1',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Overflow on width $width');
      }
    });

    // 26. No overflow on tablet and desktop
    testWidgets('26. Zero overflow on tablet and desktop screens', (tester) async {
      for (final size in [const Size(768, 1024), const Size(1280, 800)]) {
        await tester.binding.setSurfaceSize(size);

        await tester.pumpWidget(
          createTestWidget(
            const PatientVisitDetailScreen(
              caseId: 'CASE-PAT-001-01',
              visitId: 'VIS-PAT-001-01-1',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Overflow on size $size');
      }
    });

    // 27. Empty-state UI: specialized healthcare visual (no generic folder icon)
    testWidgets('27. Cases empty state renders healthcare visual and View Dashboard action', (tester) async {
      PatientSessionService.instance.logout();
      PatientSessionService.instance.startSession('PAT-EMPTY-001', authUid: 'empty-uid');

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          const PatientCasesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PatientEmptyStateVisual), findsOneWidget);
      expect(find.byIcon(Icons.folder_open_rounded), findsNothing);
      expect(find.text('No Ongoing Cases'), findsOneWidget);
      expect(find.text('View Dashboard'), findsOneWidget);

      await tester.tap(find.text('View Dashboard'));
      await tester.pumpAndSettle();

      expect(PatientAppState.instance.currentTab, equals(PatientNavigationTab.dashboard));
    });
  });
}

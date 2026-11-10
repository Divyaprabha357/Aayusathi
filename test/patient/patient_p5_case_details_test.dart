import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/doctor/models/clinical_visit.dart';
import 'package:aayusathi/doctor/models/investigation_request.dart';
import 'package:aayusathi/doctor/models/prescription_item.dart';
import 'package:aayusathi/patient/localization/patient_localizations.dart';
import 'package:aayusathi/patient/models/patient_app_state.dart';
import 'package:aayusathi/patient/models/patient_navigation_tab.dart';
import 'package:aayusathi/patient/screens/patient_case_detail_screen.dart';
import 'package:aayusathi/patient/screens/patient_main_shell_screen.dart';
import 'package:aayusathi/patient/screens/patient_visit_detail_screen.dart';
import 'package:aayusathi/patient/services/patient_session_service.dart';
import 'package:aayusathi/patient/theme/patient_theme.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_patient_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    BackendProvider.instance.setMode(BackendMode.mock);
    MockCaseRepository.instance.resetToDefaults();
    MockClinicalVisitRepository.instance.resetToDefaults();
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
      home: PatientLocalizations.provider(
        strings: PatientLocalizations.forLocaleCode(locale.languageCode),
        child: child,
      ),
    );
  }

  group('P5 Case Details & Visit History Tests', () {
    testWidgets('1. Case Details loads correctly with title, domain and metadata', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          const PatientCaseDetailScreen(caseId: 'CASE-PAT-001-01'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Case Details'), findsWidgets);
      expect(find.text('General Medicine'), findsWidgets);
      expect(find.text('Hypertension & Exertional Dyspnea'), findsOneWidget);
      expect(find.text('Ongoing'), findsWidgets);
      expect(find.textContaining('Case #CASE-PAT-001-01'), findsOneWidget);
      expect(find.text('Started on'), findsOneWidget);
      expect(find.text('Visits'), findsWidgets);
    });

    testWidgets('2. Patient ownership enforced - unauthorized patient sees empty or error', (tester) async {
      PatientSessionService.instance.logout();
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          const PatientCaseDetailScreen(caseId: 'CASE-PAT-001-01'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to load case details.\nPlease try again.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('3. Closed case displays Completed badge and completed date', (tester) async {
      final closedCase = ClinicalCase(
        caseId: 'CASE-CLOSED-01',
        patientId: 'PAT-MOCK-001',
        title: 'Resolved Acute Bronchitis',
        domain: 'Pulmonology',
        status: ClinicalCaseStatus.closed,
        createdAt: DateTime(2026, 1, 10),
        updatedAt: DateTime(2026, 1, 20),
        closedAt: DateTime(2026, 1, 20),
        closureNote: 'Patient fully recovered.',
      );
      await MockCaseRepository.instance.createCase(closedCase);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          PatientCaseDetailScreen(
            caseId: 'CASE-CLOSED-01',
            preloadedCase: closedCase,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Completed'), findsWidgets);
      expect(find.text('Completed on'), findsOneWidget);
      expect(find.text('Resolved Acute Bronchitis'), findsOneWidget);
    });

    testWidgets('4. Visit history displays reverse chronological timeline (latest visit at top)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          const PatientCaseDetailScreen(caseId: 'CASE-PAT-001-01'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Visit History'), findsOneWidget);
      expect(find.text('Visit 2'), findsOneWidget);
      expect(find.text('Visit 1'), findsOneWidget);

      // Verify Visit 2 appears visually before Visit 1 in the widget tree
      final visit2Pos = tester.getTopLeft(find.text('Visit 2')).dy;
      final visit1Pos = tester.getTopLeft(find.text('Visit 1')).dy;
      expect(visit2Pos < visit1Pos, isTrue, reason: 'Visit 2 should be displayed above Visit 1');
    });

    testWidgets('5. Empty visit history displays No Visits Yet empty state', (tester) async {
      final emptyCase = ClinicalCase(
        caseId: 'CASE-EMPTY-01',
        patientId: 'PAT-MOCK-001',
        title: 'New Investigation',
        domain: 'Neurology',
        status: ClinicalCaseStatus.open,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await MockCaseRepository.instance.createCase(emptyCase);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          PatientCaseDetailScreen(
            caseId: 'CASE-EMPTY-01',
            preloadedCase: emptyCase,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Visits Yet'), findsOneWidget);
      expect(find.text('No consultation visits have been recorded for this case yet.'), findsOneWidget);
    });

    testWidgets('6. Visit Detail Screen displays all 8 clinical sections, doctor, and vitals', (tester) async {
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
      expect(find.text('Dr. Rajesh Sharma'), findsOneWidget);
      expect(find.text('MBBS, MD (Cardiology)'), findsOneWidget);
      expect(find.text('Vitals'), findsOneWidget);
      expect(find.text('APPROVED BY DOCTOR'), findsOneWidget);
      expect(find.text('Consultation Summary'), findsOneWidget);
      expect(find.text('Consultation Details'), findsOneWidget);
      expect(find.text('Chief Complaint'), findsOneWidget);
      expect(find.text('Assessment'), findsOneWidget);
      expect(find.text('Plan'), findsOneWidget);
      expect(find.text('Follow-up'), findsOneWidget);
    });

    testWidgets('7. Missing vitals fallback displays Not recorded gracefully', (tester) async {
      final visitWithoutVitals = ClinicalVisit(
        visitId: 'VIS-NO-VITALS',
        caseId: 'CASE-PAT-001-01',
        patientId: 'PAT-MOCK-001',
        doctorId: 'DOC-101',
        doctorName: 'Dr. Rajesh Sharma',
        visitNumber: 3,
        startedAt: DateTime.now(),
        status: ClinicalVisitStatus.active,
        chiefComplaint: 'Checkup without sensor readings',
      );

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          PatientVisitDetailScreen(
            caseId: 'CASE-PAT-001-01',
            visitId: 'VIS-NO-VITALS',
            preloadedVisit: visitWithoutVitals,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vitals'), findsOneWidget);
      expect(find.text('SpO₂'), findsOneWidget);
      expect(find.text('Blood Pressure'), findsNothing);
      expect(find.text('Heart Rate'), findsOneWidget);
      expect(find.text('Temperature'), findsOneWidget);
      // All 3 vitals should display 'Not recorded'
      expect(find.text('Not recorded'), findsNWidgets(3));
    });

    testWidgets('8. Prescriptions and investigations are rendered properly in Visit Details', (tester) async {
      final visitWithPrescriptions = ClinicalVisit(
        visitId: 'VIS-MEDS-01',
        caseId: 'CASE-PAT-001-01',
        patientId: 'PAT-MOCK-001',
        doctorId: 'DOC-101',
        doctorName: 'Dr. Rajesh Sharma',
        visitNumber: 1,
        startedAt: DateTime.now(),
        status: ClinicalVisitStatus.completed,
        chiefComplaint: 'Follow-up prescription',
        prescriptions: const [
          PrescriptionItem(
            medicineName: 'Amlodipine 5mg',
            duration: '14 days',
            timesPerDay: 'Once daily after breakfast',
            remarks: 'Monitor blood pressure weekly',
          ),
        ],
        investigationRequests: [
          InvestigationRequest(
            requestId: 'REQ-01',
            name: 'Serum Electrolytes',
            status: InvestigationStatus.pendingUpload,
            requestedAt: DateTime.now(),
          ),
        ],
      );

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          PatientVisitDetailScreen(
            caseId: 'CASE-PAT-001-01',
            visitId: 'VIS-MEDS-01',
            preloadedVisit: visitWithPrescriptions,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Prescriptions'), findsOneWidget);
      expect(find.text('Amlodipine 5mg'), findsOneWidget);
      expect(find.text('Once daily after breakfast • 14 days'), findsOneWidget);
      expect(find.text('Monitor blood pressure weekly'), findsOneWidget);

      expect(find.text('Requested Investigations'), findsOneWidget);
      expect(find.text('Serum Electrolytes'), findsOneWidget);
      expect(find.text('Pending Upload'), findsOneWidget);
    });

    testWidgets('9. Trilingual localization support in Hindi and Marathi', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      // Hindi
      await tester.pumpWidget(
        createTestWidget(
          const PatientCaseDetailScreen(caseId: 'CASE-PAT-001-01'),
          locale: const Locale('hi'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('केस विवरण'), findsWidgets);
      expect(find.text('मुलाकात इतिहास'), findsOneWidget);
      expect(find.text('शुरुआत की तारीख'), findsOneWidget);

      // Marathi
      await tester.pumpWidget(
        createTestWidget(
          const PatientCaseDetailScreen(caseId: 'CASE-PAT-001-01'),
          locale: const Locale('mr'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('केस तपशील'), findsWidgets);
      expect(find.text('भेट इतिहास'), findsOneWidget);
      expect(find.text('सुरुवात तारीख'), findsOneWidget);
    });

    testWidgets('10. Mobile responsiveness without overflow on 360, 375, 412, 430 widths', (tester) async {
      for (final width in [360.0, 375.0, 390.0, 412.0, 430.0]) {
        await tester.binding.setSurfaceSize(Size(width, 844));

        await tester.pumpWidget(
          createTestWidget(
            const PatientCaseDetailScreen(caseId: 'CASE-PAT-001-01'),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Overflow on width $width');

        await tester.pumpWidget(
          createTestWidget(
            const PatientVisitDetailScreen(
              caseId: 'CASE-PAT-001-01',
              visitId: 'VIS-PAT-001-01-1',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Overflow on Visit Details width $width');
      }
    });

    testWidgets('11. P3 Dashboard and P4 Cases regression check', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        createTestWidget(
          const PatientMainShellScreen(initialTab: PatientNavigationTab.dashboard),
        ),
      );
      await tester.pumpAndSettle();

      // P3 elements
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('ONGOING CASES'), findsOneWidget);
      expect(find.text('QUICK ACCESS'), findsOneWidget);

      // P4 Cases elements
      await tester.tap(find.text('Cases').last);
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });
  });
}

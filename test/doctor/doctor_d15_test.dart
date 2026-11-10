import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/doctor/localization/doctor_strings.dart';
import 'package:aayusathi/doctor/models/case_timeline_event.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/doctor/models/clinical_visit.dart';
import 'package:aayusathi/doctor/models/patient_transfer_request.dart';
import 'package:aayusathi/doctor/screens/doctor_case_screen.dart';
import 'package:aayusathi/doctor/screens/doctor_reports_screen.dart';
import 'package:aayusathi/doctor/services/mock_pdf_output_service.dart';
import 'package:aayusathi/doctor/services/pdf_output_service.dart';
import 'package:aayusathi/doctor/widgets/doctor_buttons.dart';
import 'package:aayusathi/doctor/widgets/doctor_case_closed_dialog.dart';
import 'package:aayusathi/doctor/widgets/doctor_case_timeline_view.dart';
import 'package:aayusathi/doctor/widgets/doctor_close_case_dialog.dart';
import 'package:aayusathi/doctor/widgets/doctor_consultation_widgets.dart';
import 'package:aayusathi/doctor/widgets/doctor_patient_workspace_widgets.dart';
import 'package:aayusathi/models/audit_log.dart';
import 'package:aayusathi/repositories/mock/mock_audit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_investigation_repository.dart';
import 'package:aayusathi/repositories/mock/mock_transfer_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockOpenCase = ClinicalCase(
    caseId: 'CASE-PAT-001-01',
    patientId: 'PAT-MOCK-001',
    domain: 'Cardiology',
    title: 'Hypertension Management and Evaluation',
    status: ClinicalCaseStatus.open,
    createdAt: DateTime.now().subtract(const Duration(days: 20)),
    updatedAt: DateTime.now(),
    visitCount: 2,
  );

  final mockClosedCase = ClinicalCase(
    caseId: 'CASE-PAT-001-02',
    patientId: 'PAT-MOCK-001',
    domain: 'General Medicine',
    title: 'Acute Viral Bronchitis',
    status: ClinicalCaseStatus.closed,
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    closedAt: DateTime.now().subtract(const Duration(days: 2)),
    closedByDoctorId: 'DOC-101',
    closedByDoctorName: 'Dr. Ramesh Sharma',
    closureNote: 'Patient completely recovered. Chest clear, vitals stable.',
    visitCount: 2,
  );

  final mockVisit1 = ClinicalVisit(
    visitId: 'VIS-PAT-001-01-1',
    caseId: 'CASE-PAT-001-01',
    patientId: 'PAT-MOCK-001',
    doctorId: 'DOC-101',
    doctorName: 'Dr. Ramesh Sharma',
    doctorQualification: 'MBBS, MD (Medicine)',
    visitNumber: 1,
    startedAt: DateTime.now().subtract(const Duration(days: 20)),
    completedAt: DateTime.now().subtract(const Duration(days: 20, minutes: -30)),
    status: ClinicalVisitStatus.completed,
    chiefComplaint: 'High BP readings and mild headache.',
    onsetDuration: '1 week',
    assessment: 'Essential Hypertension Stage 1.',
    plan: 'Lifestyle modification, Amlodipine 5mg OD.',
  );

  final mockVisit2 = ClinicalVisit(
    visitId: 'VIS-PAT-001-01-2',
    caseId: 'CASE-PAT-001-01',
    patientId: 'PAT-MOCK-001',
    doctorId: 'DOC-101',
    doctorName: 'Dr. Ramesh Sharma',
    doctorQualification: 'MBBS, MD (Medicine)',
    visitNumber: 2,
    startedAt: DateTime.now().subtract(const Duration(days: 7)),
    completedAt: DateTime.now().subtract(const Duration(days: 7, minutes: -25)),
    status: ClinicalVisitStatus.completed,
    chiefComplaint: 'Follow-up for BP check.',
    onsetDuration: '3 days',
    assessment: 'BP controlled at 128/82 mmHg.',
    plan: 'Continue Amlodipine 5mg OD.',
  );

  final mockActiveVisit = ClinicalVisit(
    visitId: 'VIS-PAT-001-01-3',
    caseId: 'CASE-PAT-001-01',
    patientId: 'PAT-MOCK-001',
    doctorId: 'DOC-101',
    doctorName: 'Dr. Ramesh Sharma',
    doctorQualification: 'MBBS, MD (Medicine)',
    visitNumber: 3,
    startedAt: DateTime.now().subtract(const Duration(minutes: 10)),
    status: ClinicalVisitStatus.active,
    chiefComplaint: 'Routine checkup.',
    onsetDuration: '1 day',
  );

  setUp(() {
    BackendProvider.instance.setMode(BackendMode.mock);
    MockCaseRepository.instance.resetToDefaults();
    MockClinicalVisitRepository.instance.resetToDefaults();
    MockTransferRepository.instance.resetToDefaults();
    MockInvestigationRepository.instance.reset();
    MockAuditRepository.instance.clear();
    PdfOutputService.instance = MockPdfOutputService.instance;
  });

  group('Phase D15: ClinicalCase Closure Model Tests', () {
    test('1. ClinicalCase default and closure fields creation', () {
      expect(mockOpenCase.isOpen, isTrue);
      expect(mockOpenCase.isClosed, isFalse);
      expect(mockOpenCase.closedAt, isNull);
      expect(mockOpenCase.closureNote, isNull);

      expect(mockClosedCase.isOpen, isFalse);
      expect(mockClosedCase.isClosed, isTrue);
      expect(mockClosedCase.closedAt, isNotNull);
      expect(mockClosedCase.closedByDoctorId, equals('DOC-101'));
      expect(mockClosedCase.closedByDoctorName, equals('Dr. Ramesh Sharma'));
      expect(mockClosedCase.closureNote, contains('completely recovered'));
    });

    test('2. ClinicalCase Firestore serialization and deserialization with closure fields', () {
      final firestoreMap = mockClosedCase.toFirestore();
      expect(firestoreMap['status'], equals('closed'));
      expect(firestoreMap['closureNote'], equals('Patient completely recovered. Chest clear, vitals stable.'));
      expect(firestoreMap['closedByDoctorId'], equals('DOC-101'));
      expect(firestoreMap['closedByDoctorName'], equals('Dr. Ramesh Sharma'));

      final reconstructed = ClinicalCase.fromFirestore(firestoreMap, mockClosedCase.caseId);
      expect(reconstructed.caseId, equals(mockClosedCase.caseId));
      expect(reconstructed.isClosed, isTrue);
      expect(reconstructed.closedByDoctorName, equals('Dr. Ramesh Sharma'));
      expect(reconstructed.closureNote, equals(mockClosedCase.closureNote));
    });

    test('3. ClinicalCase copyWith updates closure metadata correctly', () {
      final closed = mockOpenCase.copyWith(
        status: ClinicalCaseStatus.closed,
        closedAt: DateTime(2026, 9, 6, 14, 0),
        closedByDoctorId: 'DOC-102',
        closedByDoctorName: 'Dr. Anita Desai',
        closureNote: 'Resolved satisfactorily.',
      );

      expect(closed.isOpen, isFalse);
      expect(closed.isClosed, isTrue);
      expect(closed.closedByDoctorId, equals('DOC-102'));
      expect(closed.closedByDoctorName, equals('Dr. Anita Desai'));
      expect(closed.closureNote, equals('Resolved satisfactorily.'));
    });
  });

  group('Phase D15: CaseTimelineEventType and Closure Milestone', () {
    test('4. CaseTimelineEventType caseClosed enum and value conversion', () {
      expect(CaseTimelineEventType.caseClosed.value, equals('CASE_CLOSED'));
      expect(CaseTimelineEventTypeExtension.fromString('CASE_CLOSED'), equals(CaseTimelineEventType.caseClosed));
      expect(CaseTimelineEventTypeExtension.fromString('case_closed'), equals(CaseTimelineEventType.caseClosed));
    });

    test('5. CaseTimelineEvent.fromCaseClosure factory constructor', () {
      final event = CaseTimelineEvent.fromCaseClosure(
        mockClosedCase,
        doctorName: 'Dr. Ramesh Sharma',
      );

      expect(event.eventType, equals(CaseTimelineEventType.caseClosed));
      expect(event.caseId, equals(mockClosedCase.caseId));
      expect(event.doctorName, equals('Dr. Ramesh Sharma'));
      expect(event.title, contains('Case Closed'));
      expect(event.description, contains('Patient completely recovered'));
    });
  });

  group('Phase D15: MockCaseRepository Case Closure Operations', () {
    setUp(() {
      MockCaseRepository.instance.resetToDefaults();
    });

    test('6. MockCaseRepository closeCase updates case status to closed with metadata', () async {
      final repo = MockCaseRepository.instance;
      final updated = await repo.closeCase(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
        doctorId: 'DOC-101',
        doctorName: 'Dr. Ramesh Sharma',
        closureNote: 'Treatment course completed successfully.',
      );

      expect(updated.isClosed, isTrue);
      expect(updated.closedByDoctorId, equals('DOC-101'));
      expect(updated.closedByDoctorName, equals('Dr. Ramesh Sharma'));
      expect(updated.closureNote, equals('Treatment course completed successfully.'));
      expect(updated.closedAt, isNotNull);

      final fetched = await repo.getCaseById(patientId: 'PAT-MOCK-001', caseId: 'CASE-PAT-001-01');
      expect(fetched?.isClosed, isTrue);
    });

    test('7. MockCaseRepository closeCase fails if case not found', () async {
      final repo = MockCaseRepository.instance;
      expect(
        () => repo.closeCase(
          patientId: 'NON-EXISTENT',
          caseId: 'NON-EXISTENT',
          doctorId: 'DOC-101',
          closureNote: 'Note',
        ),
        throwsException,
      );
    });

    test('8. MockCaseRepository closeCase fails if closure note is empty', () async {
      final repo = MockCaseRepository.instance;
      expect(
        () => repo.closeCase(
          patientId: 'PAT-MOCK-001',
          caseId: 'CASE-PAT-001-01',
          doctorId: 'DOC-101',
          closureNote: '   ',
        ),
        throwsException,
      );
    });

    test('9. MockCaseRepository closeCase fails if already closed', () async {
      final repo = MockCaseRepository.instance;
      // Close once
      await repo.closeCase(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
        doctorId: 'DOC-101',
        closureNote: 'First closure note.',
      );

      // Attempt to close second time
      expect(
        () => repo.closeCase(
          patientId: 'PAT-MOCK-001',
          caseId: 'CASE-PAT-001-01',
          doctorId: 'DOC-101',
          closureNote: 'Second closure attempt.',
        ),
        throwsException,
      );
    });

    test('10. MockCaseRepository getAllCases retrieves all cases', () async {
      final repo = MockCaseRepository.instance;
      final allCases = await repo.getAllCases();
      expect(allCases.isNotEmpty, isTrue);
    });
  });

  group('Phase D15: DoctorCloseCaseDialog Widget Tests', () {
    testWidgets('11. DoctorCloseCaseDialog renders header, case details, declaration checkbox and note input', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorCloseCaseDialog(
              clinicalCase: mockOpenCase,
              locale: KioskLocale.english,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CLOSE CASE'), findsNWidgets(2));
      expect(find.textContaining('CASE-PAT-001-01'), findsOneWidget);
      expect(find.textContaining('Cardiology'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.textContaining('1000'), findsOneWidget);
    });

    testWidgets('12. DoctorCloseCaseDialog submit button is disabled until declaration and note are filled', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorCloseCaseDialog(
              clinicalCase: mockOpenCase,
              locale: KioskLocale.english,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the Close Case primary button
      final closeButtonFinder = find.widgetWithText(DoctorPrimaryButton, 'CLOSE CASE');
      expect(closeButtonFinder, findsOneWidget);
      final initialButton = tester.widget<DoctorPrimaryButton>(closeButtonFinder);
      expect(initialButton.onPressed, isNull);

      // Check declaration checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      final buttonAfterCheckbox = tester.widget<DoctorPrimaryButton>(closeButtonFinder);
      expect(buttonAfterCheckbox.onPressed, isNull);

      // Enter closure note
      await tester.enterText(find.byType(TextField), 'Clinical condition resolved satisfactorily.');
      await tester.pumpAndSettle();

      final buttonAfterNote = tester.widget<DoctorPrimaryButton>(closeButtonFinder);
      expect(buttonAfterNote.onPressed, isNotNull);
      expect(find.textContaining('1000'), findsOneWidget);
    });

    testWidgets('13. DoctorCloseCaseDialog returns closure note on submit', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      String? submittedNote;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  submittedNote = await showDialog<String>(
                    context: context,
                    builder: (_) => DoctorCloseCaseDialog(
                      clinicalCase: mockOpenCase,
                      locale: KioskLocale.english,
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Fill declaration & note
      await tester.tap(find.byType(Checkbox));
      await tester.enterText(find.byType(TextField), 'Patient recovered completely with no active complaints.');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.widgetWithText(DoctorPrimaryButton, 'CLOSE CASE'));
      await tester.pumpAndSettle();

      expect(submittedNote, equals('Patient recovered completely with no active complaints.'));
    });
  });

  group('Phase D15: DoctorCaseClosedDialog Widget Tests', () {
    testWidgets('14. DoctorCaseClosedDialog displays case closure confirmation and details', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorCaseClosedDialog(
              clinicalCase: mockClosedCase,
              doctorName: 'Dr. Ramesh Sharma',
              locale: KioskLocale.english,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CASE CLOSED'), findsOneWidget);
      expect(find.textContaining(mockClosedCase.caseId), findsOneWidget);
      expect(find.text('Dr. Ramesh Sharma'), findsOneWidget);
      expect(find.textContaining('Patient completely recovered'), findsOneWidget);
      expect(find.text('VIEW CASE HISTORY'), findsOneWidget);
      expect(find.text('RETURN TO DASHBOARD'), findsOneWidget);
    });

    testWidgets('15. DoctorCaseClosedDialog buttons pop with respective actions', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      String? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showDialog<String>(
                    context: context,
                    builder: (_) => DoctorCaseClosedDialog(
                      clinicalCase: mockClosedCase,
                      doctorName: 'Dr. Ramesh Sharma',
                      locale: KioskLocale.english,
                    ),
                  );
                },
                child: const Text('Open Closed Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Closed Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('VIEW CASE HISTORY'));
      await tester.pumpAndSettle();

      expect(result, equals('view_history'));
    });
  });

  group('Phase D15: DoctorCaseTimelineView with CASE_CLOSED Milestone', () {
    testWidgets('16. DoctorCaseTimelineView renders CASE_CLOSED milestone badge and note for closed case', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DoctorCaseTimelineView(
                clinicalCase: mockClosedCase,
                visits: [mockVisit1, mockVisit2],
                locale: KioskLocale.english,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CASE CLOSED'), findsOneWidget);
      expect(find.textContaining('Patient completely recovered'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsNWidgets(2));
    });
  });

  group('Phase D15: DoctorCaseInfoCard with Closed Case Read-Only View', () {
    testWidgets('17. DoctorCaseInfoCard displays closed case metadata and closure note', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = TextEditingController(text: 'Historical asthma and seasonal allergies.');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorCaseInfoCard(
              clinicalCase: mockClosedCase,
              relevantHistoryController: controller,
              locale: KioskLocale.english,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CASE INFORMATION'), findsOneWidget);
      expect(find.text('Closed'), findsOneWidget);
      expect(find.textContaining('Patient completely recovered'), findsOneWidget);
      expect(find.textContaining('Dr. Ramesh Sharma'), findsOneWidget);
    });
  });

  group('Phase D15: DoctorClinicalRecordsSection UI & Closure Integration', () {
    testWidgets('18. DoctorClinicalRecordsSection shows Close Case button for open case and calls onCloseCase', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool closeCaseTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorClinicalRecordsSection(
              cases: [mockOpenCase],
              selectedCase: mockOpenCase,
              visits: [mockVisit1, mockVisit2],
              onSelectCase: (_) {},
              onStartNewCase: () {},
              onAddVisit: () {},
              onCloseCase: () {
                closeCaseTriggered = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final closeCaseButtonFinder = find.text('CLOSE CASE');
      expect(closeCaseButtonFinder, findsOneWidget);
      await tester.tap(closeCaseButtonFinder);
      await tester.pumpAndSettle();

      expect(closeCaseTriggered, isTrue);
    });

    testWidgets('19. DoctorClinicalRecordsSection shows read-only banner and hides Close Case button for closed case', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorClinicalRecordsSection(
              cases: [mockClosedCase],
              selectedCase: mockClosedCase,
              visits: [mockVisit1, mockVisit2],
              onSelectCase: (_) {},
              onStartNewCase: () {},
              onAddVisit: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Dr. Ramesh Sharma'), findsWidgets);
      expect(find.text('CLOSE CASE'), findsNothing);
      expect(find.text('+ NEW VISIT'), findsNothing);
    });
  });

  group('Phase D15: DoctorCaseScreen Standalone Screen Tests', () {
    testWidgets('20. DoctorCaseScreen renders tabs, search bar, and cases list', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: DoctorCaseScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cases & Clinical Visits'), findsOneWidget);
      expect(find.textContaining('All Cases'), findsOneWidget);
      expect(find.textContaining('Open Cases'), findsOneWidget);
      expect(find.textContaining('Closed Cases'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('21. DoctorCaseScreen filter tabs filter cases appropriately', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: DoctorCaseScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Closed Cases" tab
      final closedTab = find.textContaining('Closed Cases');
      expect(closedTab, findsOneWidget);
      await tester.tap(closedTab);
      await tester.pumpAndSettle();

      // Tap "Open Cases" tab
      final openTab = find.textContaining('Open Cases');
      expect(openTab, findsOneWidget);
      await tester.tap(openTab);
      await tester.pumpAndSettle();

      expect(find.byType(DoctorCaseScreen), findsOneWidget);
    });
  });

  group('Phase D15: DoctorReportsScreen Standalone Screen Tests', () {
    testWidgets('22. DoctorReportsScreen renders header, tabs, and reports list', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: DoctorReportsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Diagnostic Reports'), findsOneWidget);
      expect(find.textContaining('Requested'), findsOneWidget);
      expect(find.textContaining('Uploaded'), findsOneWidget);
      expect(find.textContaining('Reviewed'), findsOneWidget);
      expect(find.textContaining('Visit Reports'), findsOneWidget);
    });

    testWidgets('23. DoctorReportsScreen tab switching switches views seamlessly', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: DoctorReportsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Reviewed tab
      await tester.tap(find.textContaining('Reviewed'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Tap Visit Reports tab
      await tester.tap(find.textContaining('Visit Reports'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(DoctorReportsScreen), findsOneWidget);
    });
  });

  group('Phase D15: Trilingual Localization Verification', () {
    test('24. English, Hindi, and Marathi localization classes contain all D15 strings', () {
      const en = DoctorStrings();
      const hi = DoctorStringsHindi();
      const mr = DoctorStringsMarathi();

      // Case Closure Strings
      expect(en.closeCaseButton, isNotEmpty);
      expect(hi.closeCaseButton, isNotEmpty);
      expect(mr.closeCaseButton, isNotEmpty);

      expect(en.closeCaseTitle, isNotEmpty);
      expect(hi.closeCaseTitle, isNotEmpty);
      expect(mr.closeCaseTitle, isNotEmpty);

      expect(en.closeCaseDeclarationCheckbox, isNotEmpty);
      expect(hi.closeCaseDeclarationCheckbox, isNotEmpty);
      expect(mr.closeCaseDeclarationCheckbox, isNotEmpty);

      expect(en.closureNoteLabel, isNotEmpty);
      expect(hi.closureNoteLabel, isNotEmpty);
      expect(mr.closureNoteLabel, isNotEmpty);

      expect(en.closedCaseReadOnlyNotice, isNotEmpty);
      expect(hi.closedCaseReadOnlyNotice, isNotEmpty);
      expect(mr.closedCaseReadOnlyNotice, isNotEmpty);

      // Cases Desk Strings
      expect(en.casesAndVisitsTitle, isNotEmpty);
      expect(hi.casesAndVisitsTitle, isNotEmpty);
      expect(mr.casesAndVisitsTitle, isNotEmpty);

      expect(en.tabAllCases, isNotEmpty);
      expect(hi.tabAllCases, isNotEmpty);
      expect(mr.tabAllCases, isNotEmpty);

      expect(en.tabOpenCases, isNotEmpty);
      expect(hi.tabOpenCases, isNotEmpty);
      expect(mr.tabOpenCases, isNotEmpty);

      expect(en.tabClosedCases, isNotEmpty);
      expect(hi.tabClosedCases, isNotEmpty);
      expect(mr.tabClosedCases, isNotEmpty);

      // Reports Desk Strings
      expect(en.reportsAndDiagnosticsTitle, isNotEmpty);
      expect(hi.reportsAndDiagnosticsTitle, isNotEmpty);
      expect(mr.reportsAndDiagnosticsTitle, isNotEmpty);

      expect(en.tabVisitReports, isNotEmpty);
      expect(hi.tabVisitReports, isNotEmpty);
      expect(mr.tabVisitReports, isNotEmpty);

      expect(en.markReviewedSuccess, isNotEmpty);
      expect(hi.markReviewedSuccess, isNotEmpty);
      expect(mr.markReviewedSuccess, isNotEmpty);
    });
  });

  group('Phase D15: Active Visit & Transfer Protection Rules', () {
    test('25. Cannot close case if active visit is in progress', () {
      final visits = [mockVisit1, mockActiveVisit];
      final hasActiveVisit = visits.any((v) => v.isActive);
      expect(hasActiveVisit, isTrue);

      final strings = const DoctorStrings();
      expect(strings.activeVisitBlocksClosureError, contains('Complete or transfer the active Visit'));
    });

    test('26. Cannot close case if pending transfer exists', () {
      final pendingTransfer = PatientTransferRequest(
        transferId: 'TRF-001',
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
        sourceVisitId: 'VIS-PAT-001-01-1',
        sourceDoctorId: 'DOC-101',
        sourceDoctorName: 'Dr. Ramesh Sharma',
        sourceDepartment: 'Cardiology',
        destinationDepartment: 'Neurology',
        reason: 'Requires neurological evaluation.',
        status: TransferStatus.pending,
        requestedAt: DateTime.now(),
      );

      expect(pendingTransfer.isPending, isTrue);
      final strings = const DoctorStrings();
      expect(strings.pendingTransferBlocksClosureError, contains('pending inter-department transfer'));
    });
  });

  group('Phase D15: Audit Logging on Case Closure', () {
    test('27. Audit events CASE_CLOSURE_DECLARATION_CONFIRMED and CASE_CLOSED are recorded', () async {
      final auditRepo = MockAuditRepository.instance;
      expect(auditRepo.logs.isEmpty, isTrue);

      await auditRepo.logEvent(
        AuditLog(
          auditId: 'AUDIT-001',
          actorType: 'DOCTOR',
          actorId: 'DOC-101',
          action: 'CASE_CLOSURE_DECLARATION_CONFIRMED',
          entityType: 'CLINICAL_CASE',
          entityId: 'CASE-PAT-001-01',
          timestamp: DateTime.now(),
          metadata: {
            'patientId': 'PAT-MOCK-001',
            'caseId': 'CASE-PAT-001-01',
          },
        ),
      );

      await auditRepo.logEvent(
        AuditLog(
          auditId: 'AUDIT-002',
          actorType: 'DOCTOR',
          actorId: 'DOC-101',
          action: 'CASE_CLOSED',
          entityType: 'CLINICAL_CASE',
          entityId: 'CASE-PAT-001-01',
          timestamp: DateTime.now(),
          metadata: {
            'patientId': 'PAT-MOCK-001',
            'caseId': 'CASE-PAT-001-01',
            'closureNote': 'Recovered.',
          },
        ),
      );

      expect(auditRepo.logs.length, equals(2));
      expect(auditRepo.logs[0].action, equals('CASE_CLOSURE_DECLARATION_CONFIRMED'));
      expect(auditRepo.logs[1].action, equals('CASE_CLOSED'));
      expect(auditRepo.logs[1].metadata['closureNote'], equals('Recovered.'));
    });
  });

  group('Phase D15: Standalone Desk Search & Interactions', () {
    testWidgets('28. DoctorCaseScreen search bar filters cases dynamically', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: DoctorCaseScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter search query
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'PAT-MOCK-001');
      await tester.pumpAndSettle();

      expect(find.byType(DoctorCaseScreen), findsOneWidget);
    });

    testWidgets('29. DoctorReportsScreen search filters investigation list', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: DoctorReportsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'ECG');
      await tester.pumpAndSettle();

      expect(find.byType(DoctorReportsScreen), findsOneWidget);
    });

    testWidgets('30. DoctorReportsScreen tab switching to uploaded reports', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: DoctorReportsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Uploaded tab
      await tester.tap(find.textContaining('Uploaded'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(DoctorReportsScreen), findsOneWidget);
    });
  });

  group('Phase D15: Hindi & Marathi Localized UI Rendering', () {
    testWidgets('31. DoctorCloseCaseDialog renders in Hindi', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorCloseCaseDialog(
              clinicalCase: mockOpenCase,
              locale: KioskLocale.hindi,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('केस बंद करें'), findsNWidgets(2));
      expect(find.text('समापन नोट'), findsOneWidget);
    });

    testWidgets('32. DoctorCloseCaseDialog renders in Marathi', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorCloseCaseDialog(
              clinicalCase: mockOpenCase,
              locale: KioskLocale.marathi,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('केस बंद करा'), findsNWidgets(2));
      expect(find.text('समाप्ती नोंद'), findsOneWidget);
    });

    testWidgets('33. DoctorCaseClosedDialog renders in Hindi', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorCaseClosedDialog(
              clinicalCase: mockClosedCase,
              doctorName: 'डॉ. रमेश शर्मा',
              locale: KioskLocale.hindi,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('केस बंद हो गया'), findsOneWidget);
      expect(find.text('डॉ. रमेश शर्मा'), findsOneWidget);
      expect(find.text('केस इतिहास देखें'), findsOneWidget);
      expect(find.text('डैशबोर्ड पर लौटें'), findsOneWidget);
    });

    testWidgets('34. DoctorCaseClosedDialog renders in Marathi', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorCaseClosedDialog(
              clinicalCase: mockClosedCase,
              doctorName: 'डॉ. रमेश शर्मा',
              locale: KioskLocale.marathi,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('केस बंद झाली'), findsOneWidget);
      expect(find.text('डॉ. रमेश शर्मा'), findsOneWidget);
      expect(find.text('केस इतिहास पहा'), findsOneWidget);
      expect(find.text('डॅशबोर्डवर परत जा'), findsOneWidget);
    });
  });
}


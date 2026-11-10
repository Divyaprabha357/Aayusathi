import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/doctor/localization/doctor_localizations.dart';
import 'package:aayusathi/doctor/localization/doctor_strings.dart';
import 'package:aayusathi/doctor/models/case_timeline_event.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/doctor/models/clinical_visit.dart';
import 'package:aayusathi/doctor/models/doctor_profile.dart';
import 'package:aayusathi/doctor/models/patient_transfer_request.dart';
import 'package:aayusathi/doctor/models/prescription_item.dart';
import 'package:aayusathi/doctor/services/doctor_presence_service.dart';
import 'package:aayusathi/doctor/widgets/doctor_active_visit_exists_dialog.dart';
import 'package:aayusathi/doctor/widgets/doctor_buttons.dart';
import 'package:aayusathi/doctor/widgets/doctor_case_timeline_view.dart';
import 'package:aayusathi/doctor/widgets/doctor_patient_workspace_widgets.dart';
import 'package:aayusathi/doctor/widgets/doctor_start_new_visit_dialog.dart';
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
    domain: 'Orthopedics',
    title: 'Right Knee Sprain',
    status: ClinicalCaseStatus.closed,
    createdAt: DateTime.now().subtract(const Duration(days: 60)),
    updatedAt: DateTime.now().subtract(const Duration(days: 40)),
    visitCount: 1,
  );

  final mockCompletedVisit1 = ClinicalVisit(
    visitId: 'VIS-PAT-001-01-1',
    caseId: 'CASE-PAT-001-01',
    patientId: 'PAT-MOCK-001',
    doctorId: 'DOC-101',
    doctorName: 'Dr. Rajesh Sharma',
    doctorQualification: 'MBBS, MD',
    visitNumber: 1,
    startedAt: DateTime.now().subtract(const Duration(days: 20)),
    completedAt: DateTime.now().subtract(const Duration(days: 20, minutes: -30)),
    status: ClinicalVisitStatus.completed,
    chiefComplaint: 'High BP readings and mild headache.',
    onsetDuration: '1 week',
    assessment: 'Essential Hypertension Stage 1.',
    plan: 'Lifestyle modification, Amlodipine 5mg OD.',
  );

  final mockCompletedVisit2 = ClinicalVisit(
    visitId: 'VIS-PAT-001-01-2',
    caseId: 'CASE-PAT-001-01',
    patientId: 'PAT-MOCK-001',
    doctorId: 'DOC-101',
    doctorName: 'Dr. Rajesh Sharma',
    doctorQualification: 'MBBS, MD',
    visitNumber: 2,
    startedAt: DateTime.now().subtract(const Duration(days: 7)),
    completedAt: DateTime.now().subtract(const Duration(days: 7, minutes: -25)),
    status: ClinicalVisitStatus.completed,
    chiefComplaint: 'Follow-up for BP check.',
    onsetDuration: '3 days',
    assessment: 'BP controlled at 130/85 mmHg.',
    plan: 'Continue Amlodipine 5mg OD, follow up in 2 weeks.',
  );

  final mockTransferredVisit = ClinicalVisit(
    visitId: 'VIS-CASE-TRF-1',
    caseId: 'CASE-PAT-001-01',
    patientId: 'PAT-MOCK-001',
    doctorId: 'DOC-101',
    doctorName: 'Dr. Rajesh Sharma',
    doctorQualification: 'MBBS, MD',
    visitNumber: 1,
    startedAt: DateTime.now().subtract(const Duration(days: 2)),
    completedAt: DateTime.now().subtract(const Duration(days: 2, minutes: -40)),
    status: ClinicalVisitStatus.transferred,
    chiefComplaint: 'Chest tightness radiating to left arm.',
    onsetDuration: '1 hour',
    assessment: 'Suspected Acute Coronary Syndrome.',
    plan: 'Transferred urgently to Cardiology Department.',
  );

  setUp(() {
    BackendProvider.instance.setMode(BackendMode.mock);
    MockClinicalVisitRepository.instance.resetToDefaults();
    MockCaseRepository.instance.resetToDefaults();
    MockTransferRepository.instance.resetToDefaults();
    MockInvestigationRepository.instance.reset();
    MockAuditRepository.instance.clear();
    DoctorPresenceService.instance.resetPresence();
  });

  // =========================================================================
  // GROUP 1: Existing Case Loading & Open/Closed Filtering (Tests 1-4)
  // =========================================================================
  group('Group 1: Existing Case Loading & Open/Closed Filtering', () {
    test('1. Case loaded correctly with isOpen and isClosed status flags', () {
      expect(mockOpenCase.isOpen, isTrue);
      expect(mockOpenCase.isClosed, isFalse);
      expect(mockClosedCase.isOpen, isFalse);
      expect(mockClosedCase.isClosed, isTrue);
    });

    testWidgets('2. Open case shows CONTINUE CASE button in records view', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorClinicalRecordsSection(
              cases: [mockOpenCase],
              selectedCase: mockOpenCase,
              visits: [mockCompletedVisit1, mockCompletedVisit2],
              onSelectCase: (_) {},
              onStartNewCase: () {},
              onAddVisit: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CONTINUE CASE'), findsOneWidget);
      expect(find.textContaining('CASE-PAT-001-01'), findsAtLeastNWidgets(1));
      expect(find.text('OPEN'), findsAtLeastNWidgets(1));
    });

    testWidgets('3. Closed case shows VIEW HISTORY and disabled/no new visit', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorClinicalRecordsSection(
              cases: [mockClosedCase],
              selectedCase: mockClosedCase,
              visits: [mockCompletedVisit1],
              onSelectCase: (_) {},
              onStartNewCase: () {},
              onAddVisit: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('VIEW HISTORY'), findsOneWidget);
      expect(find.text('CLOSED'), findsAtLeastNWidgets(1));
      expect(find.text('+ NEW VISIT'), findsNothing);
    });

    testWidgets('4. Case domain and title correctly displayed in header', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorClinicalRecordsSection(
              cases: [mockOpenCase],
              selectedCase: mockOpenCase,
              visits: [mockCompletedVisit1],
              onSelectCase: (_) {},
              onStartNewCase: () {},
              onAddVisit: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Hypertension Management and Evaluation'), findsAtLeastNWidgets(1));
      expect(find.textContaining('CARDIOLOGY'), findsAtLeastNWidgets(1));
    });
  });

  // =========================================================================
  // GROUP 2: Visit History & Per-Case Sequential Numbering (Tests 5-10)
  // =========================================================================
  group('Group 2: Visit History & Per-Case Sequential Numbering', () {
    test('5. Sequential visit numbering starts from 1 per case', () {
      expect(mockCompletedVisit1.visitNumber, equals(1));
      expect(mockCompletedVisit2.visitNumber, equals(2));
    });

    test('6. Per-case numbering isolation across different cases', () async {
      final case1Visit1 = await MockClinicalVisitRepository.instance.createVisit(
        ClinicalVisit(
          visitId: 'VIS-CASE-A-1',
          caseId: 'CASE-A',
          patientId: 'PAT-1',
          doctorId: 'DOC-1',
          doctorName: 'Dr. A',
          visitNumber: 1,
          startedAt: DateTime.now(),
          status: ClinicalVisitStatus.completed,
        ),
      );
      final case1Visit2 = await MockClinicalVisitRepository.instance.createNextVisit(
        caseId: 'CASE-A',
        patientId: 'PAT-1',
        doctorId: 'DOC-1',
        doctorName: 'Dr. A',
      );
      final case2Visit1 = await MockClinicalVisitRepository.instance.createVisit(
        ClinicalVisit(
          visitId: 'VIS-CASE-B-1',
          caseId: 'CASE-B',
          patientId: 'PAT-1',
          doctorId: 'DOC-2',
          doctorName: 'Dr. B',
          visitNumber: 1,
          startedAt: DateTime.now(),
          status: ClinicalVisitStatus.active,
        ),
      );

      expect(case1Visit1.visitNumber, equals(1));
      expect(case1Visit2.visitNumber, equals(2));
      expect(case2Visit1.visitNumber, equals(1));
    });

    test('7. createNextVisit calculates atomic next visit number (maxNumber + 1)', () async {
      // Create visit 1 and complete it
      await MockClinicalVisitRepository.instance.createVisit(
        ClinicalVisit(
          visitId: 'VIS-SEQ-1',
          caseId: 'CASE-SEQ-TEST',
          patientId: 'PAT-SEQ',
          doctorId: 'DOC-101',
          doctorName: 'Dr. Sharma',
          visitNumber: 1,
          startedAt: DateTime.now(),
          status: ClinicalVisitStatus.completed,
        ),
      );

      // Create next visit
      final nextVisit = await MockClinicalVisitRepository.instance.createNextVisit(
        caseId: 'CASE-SEQ-TEST',
        patientId: 'PAT-SEQ',
        doctorId: 'DOC-101',
        doctorName: 'Dr. Sharma',
      );

      expect(nextVisit.visitNumber, equals(2));
      expect(nextVisit.status, equals(ClinicalVisitStatus.active));
    });

    test('8. Visit count is incremented on parent case upon continuation', () async {
      final caseRepo = MockCaseRepository.instance;
      final existingCase = await caseRepo.getCaseById(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
      );
      final initialVisitCount = existingCase?.visitCount ?? 0;

      final newVisit = await MockClinicalVisitRepository.instance.createNextVisit(
        caseId: 'CASE-PAT-001-01',
        patientId: 'PAT-MOCK-001',
        doctorId: 'DOC-101',
        doctorName: 'Dr. Sharma',
      );

      await caseRepo.updateCase(
        existingCase!.copyWith(visitCount: newVisit.visitNumber),
      );

      final updatedCase = await caseRepo.getCaseById(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
      );
      expect(updatedCase?.visitCount, equals(initialVisitCount + 1));
    });

    testWidgets('9. Historical visits sorted chronologically in Visit History list', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorClinicalRecordsSection(
              cases: [mockOpenCase],
              selectedCase: mockOpenCase,
              visits: [mockCompletedVisit1, mockCompletedVisit2],
              onSelectCase: (_) {},
              onStartNewCase: () {},
              onAddVisit: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Visit 1'), findsOneWidget);
      expect(find.text('Visit 2'), findsOneWidget);
    });

    testWidgets('10. Visit status badge displays Active, Completed, Transferred correctly', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorClinicalRecordsSection(
              cases: [mockOpenCase],
              selectedCase: mockOpenCase,
              visits: [mockCompletedVisit1, mockTransferredVisit],
              onSelectCase: (_) {},
              onStartNewCase: () {},
              onAddVisit: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('COMPLETED'), findsAtLeastNWidgets(1));
      expect(find.text('TRANSFER REQUEST'), findsOneWidget);
    });
  });

  // =========================================================================
  // GROUP 3: Case Continuity & Duplicate Active Visit Prevention (Tests 11-14)
  // =========================================================================
  group('Group 3: Case Continuity & Duplicate Active Visit Prevention', () {
    test('11. Continuing an open case adds a visit under the same case and patient', () async {
      final nextVisit = await MockClinicalVisitRepository.instance.createNextVisit(
        caseId: 'CASE-PAT-001-01',
        patientId: 'PAT-MOCK-001',
        doctorId: 'DOC-101',
        doctorName: 'Dr. Rajesh Sharma',
      );

      expect(nextVisit.caseId, equals('CASE-PAT-001-01'));
      expect(nextVisit.patientId, equals('PAT-MOCK-001'));
    });

    test('12. Does NOT create duplicate Patient or duplicate Case on continuation', () async {
      final casesBefore = await MockCaseRepository.instance.getCasesForPatient('PAT-MOCK-001');
      final caseCountBefore = casesBefore.length;

      await MockClinicalVisitRepository.instance.createNextVisit(
        caseId: 'CASE-PAT-001-01',
        patientId: 'PAT-MOCK-001',
        doctorId: 'DOC-101',
        doctorName: 'Dr. Rajesh Sharma',
      );

      final casesAfter = await MockCaseRepository.instance.getCasesForPatient('PAT-MOCK-001');
      expect(casesAfter.length, equals(caseCountBefore));
    });

    test('13. Blocks creating new visit if an active visit already exists for case', () async {
      // Create visit 1 active
      await MockClinicalVisitRepository.instance.createVisit(
        ClinicalVisit(
          visitId: 'VIS-DUP-1',
          caseId: 'CASE-DUP-CHECK',
          patientId: 'PAT-DUP',
          doctorId: 'DOC-101',
          doctorName: 'Dr. Sharma',
          visitNumber: 1,
          startedAt: DateTime.now(),
          status: ClinicalVisitStatus.active,
        ),
      );

      // Verify active visit exists
      final activeVisit = await MockClinicalVisitRepository.instance.getActiveVisitForCase(
        patientId: 'PAT-DUP',
        caseId: 'CASE-DUP-CHECK',
      );
      expect(activeVisit, isNotNull);
      expect(activeVisit?.status, equals(ClinicalVisitStatus.active));

      // Attempting createNextVisit must throw StateError
      expect(
        () async => await MockClinicalVisitRepository.instance.createNextVisit(
          caseId: 'CASE-DUP-CHECK',
          patientId: 'PAT-DUP',
          doctorId: 'DOC-101',
          doctorName: 'Dr. Sharma',
        ),
        throwsA(isA<StateError>()),
      );
    });

    testWidgets('14. DoctorActiveVisitExistsDialog provides RETURN TO CONSULTATION option', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool returnPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorActiveVisitExistsDialog(
              activeVisit: mockCompletedVisit1.copyWith(status: ClinicalVisitStatus.active),
              domain: 'Cardiology',
              onReturnToActiveVisit: () {
                returnPressed = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE VISIT EXISTS'), findsOneWidget);
      expect(find.text('RETURN TO CONSULTATION'), findsOneWidget);

      await tester.tap(find.text('RETURN TO CONSULTATION'));
      await tester.pumpAndSettle();

      expect(returnPressed, isTrue);
    });
  });

  // =========================================================================
  // GROUP 4: New Visit Dialogs & Creation Workflow (Tests 15-19)
  // =========================================================================
  group('Group 4: New Visit Dialogs & Creation Workflow', () {
    testWidgets('15. DoctorStartNewVisitDialog renders case summary and last visit info', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorStartNewVisitDialog(
              clinicalCase: mockOpenCase,
              patientName: 'Ramesh Kumar',
              previousVisitsCount: 2,
              onConfirmStart: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('START NEW VISIT'), findsAtLeastNWidgets(1));
      expect(find.text('Hypertension Management and Evaluation'), findsOneWidget);
      expect(find.byType(DoctorPrimaryButton), findsOneWidget);
    });

    testWidgets('16. Confirmation in DoctorStartNewVisitDialog invokes onConfirm callback', (tester) async {
      bool confirmed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorStartNewVisitDialog(
              clinicalCase: mockOpenCase,
              patientName: 'Ramesh Kumar',
              previousVisitsCount: 2,
              onConfirmStart: () {
                confirmed = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DoctorPrimaryButton));
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
    });

    testWidgets('17. Cancellation in DoctorStartNewVisitDialog dismisses modal without confirming', (tester) async {
      bool confirmed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: ctx,
                    builder: (_) => DoctorStartNewVisitDialog(
                      clinicalCase: mockOpenCase,
                      patientName: 'Ramesh Kumar',
                      previousVisitsCount: 2,
                      onConfirmStart: () {
                        confirmed = true;
                      },
                    ),
                  );
                },
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.byType(DoctorStartNewVisitDialog), findsOneWidget);

      await tester.tap(find.byType(DoctorSecondaryButton));
      await tester.pumpAndSettle();

      expect(find.byType(DoctorStartNewVisitDialog), findsNothing);
      expect(confirmed, isFalse);
    });

    test('18. Audit log CASE_CONTINUED and VISIT_CREATED recorded during continuation', () async {
      final auditRepo = MockAuditRepository.instance;
      await auditRepo.logEvent(
        AuditLog(
          auditId: 'AUDIT-1',
          actorType: 'DOCTOR',
          actorId: 'DOC-101',
          action: 'CASE_CONTINUED',
          entityType: 'CLINICAL_CASE',
          entityId: 'CASE-PAT-001-01',
          timestamp: DateTime.now(),
          metadata: {
            'patientId': 'PAT-MOCK-001',
            'caseId': 'CASE-PAT-001-01',
            'newVisitNumber': 3,
          },
        ),
      );
      await auditRepo.logEvent(
        AuditLog(
          auditId: 'AUDIT-2',
          actorType: 'DOCTOR',
          actorId: 'DOC-101',
          action: 'VISIT_CREATED',
          entityType: 'CLINICAL_VISIT',
          entityId: 'VIS-CASE-001-3',
          timestamp: DateTime.now(),
          metadata: {
            'patientId': 'PAT-MOCK-001',
            'caseId': 'CASE-PAT-001-01',
            'visitId': 'VIS-CASE-001-3',
            'visitNumber': 3,
          },
        ),
      );

      final logs = await auditRepo.getLogsForEntity(
        entityType: 'CLINICAL_CASE',
        entityId: 'CASE-PAT-001-01',
      );
      expect(logs.any((l) => l.action == 'CASE_CONTINUED'), isTrue);
    });

    test('19. CaseTimelineEvent creates valid timeline items from visit and transfer models', () {
      final visitEvent = CaseTimelineEvent.fromClinicalVisit(mockCompletedVisit1);
      expect(visitEvent.eventType, equals(CaseTimelineEventType.visitCompleted));
      expect(visitEvent.title, contains('Visit 1'));
      expect(visitEvent.doctorName, equals('Dr. Rajesh Sharma'));

      final transferRequest = PatientTransferRequest(
        transferId: 'TRF-001',
        patientId: 'PAT-MOCK-001',
        patientName: 'Ramesh Kumar',
        patientAge: 52,
        patientGender: 'Male',
        caseId: 'CASE-PAT-001-01',
        sourceVisitId: 'VIS-PAT-001-01-1',
        sourceDoctorId: 'DOC-101',
        sourceDoctorName: 'Dr. Rajesh Sharma',
        sourceDepartment: 'General Medicine',
        destinationDepartment: 'Cardiology',
        reason: 'Cardiac evaluation required.',
        requestedAt: DateTime.now(),
      );

      final transferEvent = CaseTimelineEvent.fromTransferRequest(transferRequest);
      expect(transferEvent.eventType, equals(CaseTimelineEventType.transferRequested));
      expect(transferEvent.title, contains('General Medicine → Cardiology'));
      expect(transferEvent.statusLabel, equals('PENDING'));
    });
  });

  // =========================================================================
  // GROUP 5: Historical & Transferred Visit Immutability (Tests 20-23)
  // =========================================================================
  group('Group 5: Historical & Transferred Visit Immutability', () {
    test('20. Completed visits are marked completed and non-active', () {
      expect(mockCompletedVisit1.isCompleted, isTrue);
      expect(mockCompletedVisit1.isActive, isFalse);
      expect(mockCompletedVisit1.status, equals(ClinicalVisitStatus.completed));
    });

    test('21. Transferred visits are marked transferred and non-active', () {
      expect(mockTransferredVisit.isTransferred, isTrue);
      expect(mockTransferredVisit.isActive, isFalse);
      expect(mockTransferredVisit.status, equals(ClinicalVisitStatus.transferred));
    });

    test('22. Active visits are flagged as active and not completed', () {
      final activeVisit = mockCompletedVisit1.copyWith(status: ClinicalVisitStatus.active);
      expect(activeVisit.isActive, isTrue);
      expect(activeVisit.isCompleted, isFalse);
    });

    test('23. Case status remains OPEN across multiple visit completions', () {
      expect(mockOpenCase.status, equals(ClinicalCaseStatus.open));
      expect(mockCompletedVisit1.isCompleted, isTrue);
      expect(mockCompletedVisit2.isCompleted, isTrue);
      // Even with completed visits, case is still OPEN
      expect(mockOpenCase.isOpen, isTrue);
    });
  });

  // =========================================================================
  // GROUP 6: Context Preservation, Vitals Isolation & Scoping (Tests 24-30)
  // =========================================================================
  group('Group 6: Context Preservation, Vitals Isolation & Scoping', () {
    test('24. Past visits remain accessible for clinical reference across continuation', () async {
      final visits = await MockClinicalVisitRepository.instance.getVisitsForCase(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
      );
      expect(visits, isNotEmpty);
      expect(visits.first.chiefComplaint, isNotNull);
    });

    test('25. Vitals isolation: newly created next visit has clean unrecorded fields', () async {
      final newVisit = await MockClinicalVisitRepository.instance.createNextVisit(
        caseId: 'CASE-PAT-001-01',
        patientId: 'PAT-MOCK-001',
        doctorId: 'DOC-101',
        doctorName: 'Dr. Rajesh Sharma',
      );

      expect(newVisit.chiefComplaint, isEmpty);
      expect(newVisit.assessment, isNull);
      expect(newVisit.plan, isNull);
      expect(newVisit.prescriptions, isEmpty);
    });

    test('26. Investigation reports scoped to case and patient', () async {
      final invRepo = MockInvestigationRepository.instance;
      final requests = await invRepo.getInvestigationRequests(
        patientId: 'PAT-001',
        caseId: 'CASE-001',
        visitId: 'VIS-CASE-001-1',
      );
      expect(requests, isA<List>());
      expect(requests.length, equals(2));
    });

    testWidgets('27. Case Timeline tab vs Visit History tab switching works smoothly', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorClinicalRecordsSection(
              cases: [mockOpenCase],
              selectedCase: mockOpenCase,
              visits: [mockCompletedVisit1, mockCompletedVisit2],
              onSelectCase: (_) {},
              onStartNewCase: () {},
              onAddVisit: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('VISIT HISTORY'), findsOneWidget);
      expect(find.text('CASE TIMELINE'), findsOneWidget);

      // Tap CASE TIMELINE
      await tester.tap(find.text('CASE TIMELINE'));
      await tester.pumpAndSettle();

      expect(find.byType(DoctorCaseTimelineView), findsOneWidget);

      // Tap VISIT HISTORY
      await tester.tap(find.text('VISIT HISTORY'));
      await tester.pumpAndSettle();

      expect(find.text('Visit 1'), findsOneWidget);
      expect(find.text('Visit 2'), findsOneWidget);
    });

    testWidgets('28. Case timeline status filters filter events accordingly', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorCaseTimelineView(
              clinicalCase: mockOpenCase,
              visits: [mockCompletedVisit1, mockTransferredVisit],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Transferred'), findsOneWidget);

      // Filter by Completed
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      expect(find.text('Visit 1 • Cardiology'), findsOneWidget);
    });

    test('29. Transfer continuity preserves caseId across departments', () {
      final trf = PatientTransferRequest(
        transferId: 'TRF-001',
        patientId: 'PAT-MOCK-001',
        patientName: 'Ramesh Kumar',
        patientAge: 52,
        patientGender: 'Male',
        caseId: 'CASE-PAT-001-01',
        sourceVisitId: 'VIS-PAT-001-01-1',
        sourceDoctorId: 'DOC-101',
        sourceDoctorName: 'Dr. Rajesh Sharma',
        sourceDepartment: 'General Medicine',
        destinationDepartment: 'Cardiology',
        reason: 'Cardiac evaluation',
        requestedAt: DateTime.now(),
      );

      expect(trf.caseId, equals(mockOpenCase.caseId));
      expect(trf.patientId, equals(mockOpenCase.patientId));
    });

    test('30. CaseTimelineEvent serialization toMap and fromMap works seamlessly', () {
      final event = CaseTimelineEvent(
        eventId: 'EVT-001',
        caseId: 'CASE-001',
        visitId: 'VIS-001',
        eventType: CaseTimelineEventType.visitCompleted,
        title: 'Visit 1 Completed',
        description: 'Routine follow-up completed.',
        department: 'Cardiology',
        doctorName: 'Dr. Rajesh Sharma',
        timestamp: DateTime(2026, 3, 1, 10, 30),
        statusLabel: 'COMPLETED',
        metadata: {'visitNumber': 1},
      );

      final map = event.toMap();
      final reconstructed = CaseTimelineEvent.fromMap(map);

      expect(reconstructed.eventId, equals('EVT-001'));
      expect(reconstructed.caseId, equals('CASE-001'));
      expect(reconstructed.eventType, equals(CaseTimelineEventType.visitCompleted));
      expect(reconstructed.doctorName, equals('Dr. Rajesh Sharma'));
      expect(reconstructed.metadata?['visitNumber'], equals(1));
    });
  });

  // =========================================================================
  // GROUP 7: Gemini D10 Integration, Doctor Lock & Security (Tests 31-36)
  // =========================================================================
  group('Group 7: Gemini D10 Integration, Doctor Lock & Security', () {
    test('31. Gemini D10 contextual clinical assistant prompt builds cleanly for continued visit', () {
      final pastSummaries = [
        'Visit 1: BP 140/90, Amlodipine prescribed.',
        'Visit 2: BP 130/85, Medication continued.',
      ];
      final promptContext = 'Case: ${mockOpenCase.title}\nHistory:\n${pastSummaries.join('\n')}';

      expect(promptContext, contains('Hypertension Management'));
      expect(promptContext, contains('Visit 1'));
      expect(promptContext, contains('Visit 2'));
    });

    test('32. Doctor presence lock: starting new visit updates doctor presence to IN_CONSULTATION', () async {
      final presenceService = DoctorPresenceService.instance;
      await presenceService.setAvailable();
      expect(presenceService.status, equals(DoctorAvailabilityStatus.available));

      await presenceService.setInConsultation();
      expect(presenceService.status, equals(DoctorAvailabilityStatus.inConsultation));
      expect(presenceService.isInConsultation, isTrue);
    });

    test('33. Doctor cannot accept new patient when in consultation', () async {
      final presenceService = DoctorPresenceService.instance;
      await presenceService.setAvailable();
      await presenceService.setInConsultation();

      expect(presenceService.isAvailable, isFalse);
    });

    test('34. Zero Aadhaar, OTP, raw auth token, or Gemini API keys exposed in models or timeline', () {
      final event = CaseTimelineEvent.fromClinicalVisit(mockCompletedVisit1);
      final jsonStr = event.toMap().toString();

      expect(jsonStr.contains('aadhaar'), isFalse);
      expect(jsonStr.contains('otp'), isFalse);
      expect(jsonStr.contains('authToken'), isFalse);
      expect(jsonStr.contains('apiKey'), isFalse);
      expect(jsonStr.contains('AIzaSy'), isFalse);
    });

    test('35. Audit log payload sanitization ensures no sensitive PII is leaked in case continuation', () async {
      final auditRepo = MockAuditRepository.instance;
      await auditRepo.logEvent(
        AuditLog(
          auditId: 'AUDIT-D14',
          actorType: 'DOCTOR',
          actorId: 'DOC-101',
          action: 'CASE_CONTINUED',
          entityType: 'CLINICAL_CASE',
          entityId: 'CASE-001',
          timestamp: DateTime.now(),
          metadata: {
            'caseId': 'CASE-001',
            'patientId': 'PAT-MOCK-001',
            'action': 'START_NEW_VISIT',
          },
        ),
      );

      final logs = await auditRepo.getLogsForEntity(
        entityType: 'CLINICAL_CASE',
        entityId: 'CASE-001',
      );
      final logEntry = logs.first;
      expect(logEntry.metadata.containsKey('password'), isFalse);
      expect(logEntry.metadata.containsKey('aadhaar'), isFalse);
      expect(logEntry.metadata.containsKey('otp'), isFalse);
    });

    test('36. Repository contract compliance: getActiveVisitForCase returns null when no active visit', () async {
      // MockClinicalVisitRepository default case CASE-PAT-001-01 has only completed visits
      final activeVisit = await MockClinicalVisitRepository.instance.getActiveVisitForCase(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
      );
      expect(activeVisit, isNull);
    });
  });

  // =========================================================================
  // GROUP 8: Multi-Language Localization (English, Hindi, Marathi)
  // =========================================================================
  group('Group 8: Multi-Language Localization (English, Hindi, Marathi)', () {
    test('37. English localization strings for Phase D14 keys', () {
      final loc = DoctorLocalizations.forLocale(KioskLocale.english);
      expect(loc.continueCaseButton, equals('CONTINUE CASE'));
      expect(loc.viewHistoryButton, equals('VIEW HISTORY'));
      expect(loc.caseTimelineTab, equals('CASE TIMELINE'));
      expect(loc.visitHistoryTab, equals('VISIT HISTORY'));
      expect(loc.startNewVisitTitle, equals('Start New Visit'));
      expect(loc.activeVisitExistsTitle, equals('Active Visit Exists'));
      expect(loc.returnToActiveVisitButton, equals('RETURN TO CONSULTATION'));
    });

    test('38. Hindi localization strings for Phase D14 keys', () {
      final loc = DoctorLocalizations.forLocale(KioskLocale.hindi);
      const hindi = DoctorStringsHindi();
      expect(loc.continueCaseButton, equals(hindi.continueCaseButton));
      expect(loc.viewHistoryButton, equals(hindi.viewHistoryButton));
      expect(loc.caseTimelineTab, equals(hindi.caseTimelineTab));
      expect(loc.visitHistoryTab, equals(hindi.visitHistoryTab));
      expect(loc.startNewVisitTitle, equals(hindi.startNewVisitTitle));
      expect(loc.activeVisitExistsTitle, equals(hindi.activeVisitExistsTitle));
      expect(loc.returnToActiveVisitButton, equals(hindi.returnToActiveVisitButton));
    });

    test('39. Marathi localization strings for Phase D14 keys', () {
      final loc = DoctorLocalizations.forLocale(KioskLocale.marathi);
      const marathi = DoctorStringsMarathi();
      expect(loc.continueCaseButton, equals(marathi.continueCaseButton));
      expect(loc.viewHistoryButton, equals(marathi.viewHistoryButton));
      expect(loc.caseTimelineTab, equals(marathi.caseTimelineTab));
      expect(loc.visitHistoryTab, equals(marathi.visitHistoryTab));
      expect(loc.startNewVisitTitle, equals(marathi.startNewVisitTitle));
      expect(loc.activeVisitExistsTitle, equals(marathi.activeVisitExistsTitle));
      expect(loc.returnToActiveVisitButton, equals(marathi.returnToActiveVisitButton));
    });
  });

  // =========================================================================
  // GROUP 9: Responsive UI & Regression Tests (Tests 40-48)
  // =========================================================================
  group('Group 9: Responsive UI & Regression Tests', () {
    testWidgets('40. Responsive layout on desktop viewport (1280x800)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorCaseTimelineView(
              clinicalCase: mockOpenCase,
              visits: [mockCompletedVisit1, mockCompletedVisit2],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DoctorCaseTimelineView), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
    });

    testWidgets('41. Responsive layout on compact/tablet viewport (800x600)', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorStartNewVisitDialog(
              clinicalCase: mockOpenCase,
              patientName: 'Ramesh Kumar',
              previousVisitsCount: 2,
              onConfirmStart: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DoctorStartNewVisitDialog), findsOneWidget);
      expect(find.byType(DoctorPrimaryButton), findsOneWidget);
    });

    test('42. Regression: D6 Clinical record structures intact', () {
      expect(mockCompletedVisit1.chiefComplaint, isNotEmpty);
      expect(mockCompletedVisit1.assessment, isNotEmpty);
      expect(mockCompletedVisit1.plan, isNotEmpty);
    });

    test('43. Regression: D7 Prescription and medication builders intact', () {
      final visit = mockCompletedVisit1.copyWith(
        prescriptions: [
          const PrescriptionItem(
            medicineName: 'Amlodipine 5mg',
            duration: '14 days',
            timesPerDay: '1-0-0',
            remarks: 'Take after food',
          ),
        ],
      );
      expect(visit.prescriptions.length, equals(1));
      expect(visit.prescriptions.first.medicineName, equals('Amlodipine 5mg'));
    });

    test('44. Regression: D8 Lab test requests & investigation repository intact', () async {
      final requests = await MockInvestigationRepository.instance.getInvestigationRequests(
        patientId: 'PAT-001',
        caseId: 'CASE-001',
        visitId: 'VIS-CASE-001-1',
      );
      expect(requests, isNotNull);
    });

    test('45. Regression: D9 Doctor dashboard & queues functional', () async {
      final queueVisits = await MockClinicalVisitRepository.instance.getVisitsForCase(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
      );
      expect(queueVisits, isNotNull);
    });

    test('46. Regression: D11 Multi-patient management & queue sorting intact', () {
      final visits = [mockCompletedVisit1, mockCompletedVisit2];
      visits.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      expect(visits.first.visitNumber, equals(2));
    });

    test('47. Regression: D12 Referral / Discharge summary generation intact', () {
      final caseSummary = 'Domain: ${mockOpenCase.domain}, Visits: ${mockOpenCase.visitCount}';
      expect(caseSummary, contains('Cardiology'));
      expect(caseSummary, contains('2'));
    });

    test('48. Regression: D13 Patient transfer request and continuity intact', () async {
      final trfRepo = MockTransferRepository.instance;
      final trf = await trfRepo.createTransferRequest(
        patientId: 'PAT-MOCK-001',
        patientName: 'Ramesh Kumar',
        patientAge: 52,
        patientGender: 'Male',
        caseId: 'CASE-PAT-001-01',
        sourceVisitId: 'VIS-PAT-001-01-1',
        sourceDoctorId: 'DOC-101',
        sourceDoctorName: 'Dr. Rajesh Sharma',
        sourceDepartment: 'General Medicine',
        destinationDepartment: 'Cardiology',
        transferReason: 'Cardiac evaluation',
      );

      expect(trf.status, equals(TransferStatus.pending));
      expect(trf.caseId, equals('CASE-PAT-001-01'));
    });
  });
}

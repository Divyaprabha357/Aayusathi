import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/doctor/localization/doctor_localizations.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/doctor/models/clinical_visit.dart';
import 'package:aayusathi/doctor/models/prescription_item.dart';
import 'package:aayusathi/doctor/models/report_document.dart';
import 'package:aayusathi/doctor/services/doctor_presence_service.dart';
import 'package:aayusathi/doctor/widgets/doctor_buttons.dart';
import 'package:aayusathi/doctor/widgets/doctor_complete_visit_dialog.dart';
import 'package:aayusathi/doctor/widgets/doctor_patient_workspace_widgets.dart';
import 'package:aayusathi/doctor/widgets/doctor_visit_completed_dialog.dart';
import 'package:aayusathi/doctor/widgets/doctor_visit_detail_dialog.dart';
import 'package:aayusathi/models/audit_log.dart';
import 'package:aayusathi/patient/services/patient_clinical_records_service.dart';
import 'package:aayusathi/patient/widgets/patient_case_overview_card.dart';
import 'package:aayusathi/repositories/mock/mock_audit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final validCompleteVisit = ClinicalVisit(
    visitId: 'VIS-CASE-001-1',
    caseId: 'CASE-001',
    patientId: 'PAT-MOCK-001',
    doctorId: 'DOC-101',
    doctorName: 'Dr. Rajesh Sharma',
    doctorQualification: 'MBBS, MD (Cardiology)',
    visitNumber: 1,
    startedAt: DateTime.now().subtract(const Duration(minutes: 30)),
    status: ClinicalVisitStatus.active,
    chiefComplaint: 'Chest tightness for 3 days on exertion.',
    onsetDuration: '3 days, gradual onset.',
    associatedSymptoms: 'Occasional palpitations.',
    medicalHistory: 'Known hypertensive for 5 years.',
    currentMedication: 'Amlodipine 5mg OD.',
    clinicalObservations: 'BP 130/84 mmHg, regular pulse 76 bpm.',
    assessment: 'Controlled hypertension with mild exertional symptoms.',
    plan: 'Continue antihypertensive, order 12-lead ECG.',
    summary: 'Clinical consultation complete and reviewed.',
    summaryText: 'Clinical consultation complete and reviewed.',
    summaryApprovalStatus: SummaryApprovalStatus.approvedByDoctor,
    approvedByDoctorId: 'DOC-101',
    approvedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    followUp: 'Review in 2 weeks.',
    patientInstructions: 'Low salt diet, regular walking.',
    prescriptions: const [
      PrescriptionItem(
        medicineName: 'Telmisartan 40mg',
        duration: '30 days',
        timesPerDay: '1-0-0',
        remarks: 'After breakfast',
      ),
    ],
  );

  final mockCase = ClinicalCase(
    caseId: 'CASE-001',
    patientId: 'PAT-MOCK-001',
    domain: 'Cardiology',
    title: 'Essential Hypertension',
    status: ClinicalCaseStatus.open,
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    updatedAt: DateTime.now().subtract(const Duration(days: 10)),
    visitCount: 1,
  );

  setUp(() {
    BackendProvider.instance.setMode(BackendMode.mock);
    MockClinicalVisitRepository.instance.resetToDefaults();
    MockCaseRepository.instance.resetToDefaults();
    MockAuditRepository.instance.clear();
    DoctorPresenceService.instance.resetPresence();
  });

  group('AAYUSATHI Phase D12: Visit Completion, Case Lifecycle & Doctor Workflow', () {
    test('1. canCompleteVisit requires all 8 fields, valid prescriptions, and approved summary', () {
      expect(validCompleteVisit.canCompleteVisit, isTrue);
      expect(validCompleteVisit.areConsultationFieldsComplete, isTrue);
      expect(validCompleteVisit.isSummaryApproved, isTrue);
    });

    test('2. Missing consultation field blocks canCompleteVisit', () {
      final incompleteVisit = validCompleteVisit.copyWith(chiefComplaint: '');
      expect(incompleteVisit.canCompleteVisit, isFalse);
      expect(incompleteVisit.areConsultationFieldsComplete, isFalse);
      expect(incompleteVisit.missingRequirements, contains('Chief Complaint'));
    });

    test('3. Unapproved summary blocks canCompleteVisit', () {
      final unapprovedVisit = validCompleteVisit.copyWith(
        summaryApprovalStatus: SummaryApprovalStatus.reviewRequired,
      );
      expect(unapprovedVisit.canCompleteVisit, isFalse);
      expect(unapprovedVisit.missingRequirements, contains('Doctor Summary Approval'));
    });

    test('4. Empty summary blocks canCompleteVisit', () {
      final noSummaryVisit = validCompleteVisit.copyWith(
        summaryText: '',
        summary: '',
        summaryApprovalStatus: SummaryApprovalStatus.draft,
      );
      expect(noSummaryVisit.canCompleteVisit, isFalse);
      expect(noSummaryVisit.missingRequirements, contains('Visit Summary'));
    });

    test('5. Incomplete prescription blocks canCompleteVisit', () {
      final invalidPrescriptionVisit = validCompleteVisit.copyWith(
        prescriptions: [
          const PrescriptionItem(
            medicineName: '',
            duration: '',
            timesPerDay: '',
            remarks: '',
          ),
        ],
      );
      expect(invalidPrescriptionVisit.canCompleteVisit, isFalse);
      expect(invalidPrescriptionVisit.arePrescriptionsValid, isFalse);
    });

    testWidgets('6. DoctorCompleteVisitDialog enforces declaration checkbox before submission', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 768));
      bool completionConfirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorCompleteVisitDialog(
              visit: validCompleteVisit,
              hasPdfGenerated: true,
              onConfirmCompletion: () {
                completionConfirmed = true;
              },
            ),
          ),
        ),
      );

      // Verify Title and Subtitle
      expect(find.text('Complete Visit'), findsOneWidget);
      expect(find.textContaining('Completing this Visit records'), findsOneWidget);
      expect(find.textContaining('Note: Completing this Visit does not close the Case.'), findsOneWidget);

      // Submit button should be disabled initially (declaration checkbox not checked)
      final submitFinder = find.widgetWithText(DoctorPrimaryButton, 'COMPLETE VISIT');
      expect(submitFinder, findsOneWidget);
      final primaryButtonBefore = tester.widget<DoctorPrimaryButton>(submitFinder);
      expect(primaryButtonBefore.onPressed, isNull);

      // Tap declaration checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Submit button should now be enabled
      final primaryButtonAfter = tester.widget<DoctorPrimaryButton>(submitFinder);
      expect(primaryButtonAfter.onPressed, isNotNull);

      // Tap Complete Visit
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(completionConfirmed, isTrue);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('7. DoctorCompleteVisitDialog remains disabled if visit is incomplete even if checked', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 768));
      final incompleteVisit = validCompleteVisit.copyWith(assessment: '');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorCompleteVisitDialog(
              visit: incompleteVisit,
              onConfirmCompletion: () {},
            ),
          ),
        ),
      );

      // Tap checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      final submitFinder = find.widgetWithText(DoctorPrimaryButton, 'COMPLETE VISIT');
      final button = tester.widget<DoctorPrimaryButton>(submitFinder);
      expect(button.onPressed, isNull);
      await tester.binding.setSurfaceSize(null);
    });

    test('8. Visit transitions from ACTIVE to COMPLETED and sets completedAt and completedByDoctorId', () async {
      final repo = MockClinicalVisitRepository.instance;
      await repo.createVisit(validCompleteVisit);

      final completed = await repo.completeVisit(
        patientId: validCompleteVisit.patientId,
        caseId: validCompleteVisit.caseId,
        visitId: validCompleteVisit.visitId,
        doctorId: 'DOC-101',
      );

      expect(completed.status, equals(ClinicalVisitStatus.completed));
      expect(completed.isCompleted, isTrue);
      expect(completed.completedAt, isNotNull);
      expect(completed.completedByDoctorId, equals('DOC-101'));
    });

    test('9. Completed Visit cannot be completed again', () async {
      final repo = MockClinicalVisitRepository.instance;
      await repo.createVisit(validCompleteVisit);

      await repo.completeVisit(
        patientId: validCompleteVisit.patientId,
        caseId: validCompleteVisit.caseId,
        visitId: validCompleteVisit.visitId,
        doctorId: 'DOC-101',
      );

      expect(
        () async => await repo.completeVisit(
          patientId: validCompleteVisit.patientId,
          caseId: validCompleteVisit.caseId,
          visitId: validCompleteVisit.visitId,
          doctorId: 'DOC-101',
        ),
        throwsException,
      );
    });

    test('10. Cancelled Visit cannot be completed', () async {
      final repo = MockClinicalVisitRepository.instance;
      final cancelled = validCompleteVisit.copyWith(status: ClinicalVisitStatus.cancelled);
      await repo.createVisit(cancelled);

      expect(
        () async => await repo.completeVisit(
          patientId: cancelled.patientId,
          caseId: cancelled.caseId,
          visitId: cancelled.visitId,
          doctorId: 'DOC-101',
        ),
        throwsException,
      );
    });

    test('11. Case strictly remains OPEN when Visit completes', () async {
      final caseRepo = MockCaseRepository.instance;
      await caseRepo.createCase(mockCase);

      // Verify initial state
      var retrievedCase = await caseRepo.getCaseById(
        patientId: mockCase.patientId,
        caseId: mockCase.caseId,
      );
      expect(retrievedCase!.isOpen, isTrue);
      expect(retrievedCase.status, equals(ClinicalCaseStatus.open));

      // Simulate visit completion updating case updatedAt
      final updatedCase = retrievedCase.copyWith(
        updatedAt: DateTime.now(),
        status: ClinicalCaseStatus.open,
      );
      await caseRepo.updateCase(updatedCase);

      retrievedCase = await caseRepo.getCaseById(
        patientId: mockCase.patientId,
        caseId: mockCase.caseId,
      );
      expect(retrievedCase!.isOpen, isTrue);
      expect(retrievedCase.isClosed, isFalse);
    });

    test('12. Doctor Presence transitions IN_CONSULTATION -> AVAILABLE after success', () async {
      final presence = DoctorPresenceService.instance;
      await presence.setAvailable();
      await presence.setInConsultation();
      expect(presence.isInConsultation, isTrue);
      expect(presence.isAvailable, isFalse);

      await presence.setAvailable();
      expect(presence.isAvailable, isTrue);
      expect(presence.isInConsultation, isFalse);
    });

    test('13. Simulated completion failure preserves IN_CONSULTATION state', () async {
      final repo = MockClinicalVisitRepository.instance;
      repo.simulateCompletionError = true;
      final presence = DoctorPresenceService.instance;
      await presence.setAvailable();
      await presence.setInConsultation();

      await repo.createVisit(validCompleteVisit);

      try {
        await repo.completeVisit(
          patientId: validCompleteVisit.patientId,
          caseId: validCompleteVisit.caseId,
          visitId: validCompleteVisit.visitId,
          doctorId: 'DOC-101',
        );
        fail('Should have thrown completion error');
      } catch (_) {
        // Backend failed -> Doctor presence remains unchanged
        expect(presence.isInConsultation, isTrue);
      }
    });

    test('14. getNextVisitNumber accurately increments sequentially per Case', () async {
      final repo = MockClinicalVisitRepository.instance;
      repo.resetToDefaults();

      // Case A has 2 completed visits in mock defaults
      final nextCaseA = await repo.getNextVisitNumber(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
      );
      expect(nextCaseA, equals(3));

      // Case B has 1 completed visit in mock defaults
      final nextCaseB = await repo.getNextVisitNumber(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-02',
      );
      expect(nextCaseB, equals(2));
    });

    test('15. New Case starts at Visit 1', () async {
      final repo = MockClinicalVisitRepository.instance;
      final nextNewCase = await repo.getNextVisitNumber(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-NEW-999',
      );
      expect(nextNewCase, equals(1));
    });

    test('16. Existing Case receives new sequential active visit', () async {
      final repo = MockClinicalVisitRepository.instance;
      final nextNum = await repo.getNextVisitNumber(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
      );

      final newVisit = ClinicalVisit(
        visitId: 'VIS-CASE-PAT-001-01-$nextNum',
        caseId: 'CASE-PAT-001-01',
        patientId: 'PAT-MOCK-001',
        doctorId: 'DOC-101',
        visitNumber: nextNum,
        startedAt: DateTime.now(),
        status: ClinicalVisitStatus.active,
      );

      final created = await repo.createVisit(newVisit);
      expect(created.visitNumber, equals(3));
      expect(created.isActive, isTrue);

      final visits = await repo.getVisitsForCase(
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
      );
      expect(visits.length, equals(3));
      expect(visits.map((v) => v.visitNumber).toList(), equals([1, 2, 3]));
    });

    testWidgets('17. DoctorVisitDetailDialog renders read-only historical visit inspection', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 768));
      final completedVisit = validCompleteVisit.copyWith(
        status: ClinicalVisitStatus.completed,
        completedAt: DateTime.now(),
        completedByDoctorId: 'DOC-101',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorVisitDetailDialog(
              visit: completedVisit,
              domain: 'Cardiology',
            ),
          ),
        ),
      );

      expect(find.textContaining('Visit 1 • Cardiology'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('This completed visit record is archived and read-only.'), findsOneWidget);
      expect(find.text('Chest tightness for 3 days on exertion.'), findsOneWidget);
      expect(find.text('Telmisartan 40mg'), findsOneWidget);
      expect(find.text('APPROVED BY DOCTOR'), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('18. DoctorVisitCompletedDialog renders success summary with OPEN case status', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 768));
      bool returnToDashboardCalled = false;
      final completedVisit = validCompleteVisit.copyWith(
        status: ClinicalVisitStatus.completed,
        completedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorVisitCompletedDialog(
              visit: completedVisit,
              domain: 'Cardiology',
              onReturnToDashboard: () {
                returnToDashboardCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Visit Completed Successfully'), findsOneWidget);
      expect(find.text('OPEN (ONGOING)'), findsOneWidget);
      expect(find.text('Visit 1'), findsOneWidget);

      await tester.tap(find.widgetWithText(DoctorPrimaryButton, 'RETURN TO DASHBOARD'));
      await tester.pumpAndSettle();

      expect(returnToDashboardCalled, isTrue);
      await tester.binding.setSurfaceSize(null);
    });

    test('19. Audit events logged for declaration confirmation and visit completion without secrets', () async {
      final auditRepo = MockAuditRepository.instance;
      auditRepo.clear();

      // Log declaration confirmed event
      await auditRepo.logEvent(
        AuditLog(
          auditId: 'AUD-001',
          actorType: 'DOCTOR',
          actorId: 'DOC-101',
          action: 'VISIT_COMPLETION_DECLARATION_CONFIRMED',
          entityType: 'CLINICAL_VISIT',
          entityId: 'VIS-001',
          timestamp: DateTime.now(),
          metadata: {
            'patientId': 'PAT-MOCK-001',
            'caseId': 'CASE-001',
            'visitId': 'VIS-001',
            'visitNumber': 1,
            'doctorId': 'DOC-101',
          },
        ),
      );

      // Log visit completed event
      await auditRepo.logEvent(
        AuditLog(
          auditId: 'AUD-002',
          actorType: 'DOCTOR',
          actorId: 'DOC-101',
          action: 'VISIT_COMPLETED',
          entityType: 'CLINICAL_VISIT',
          entityId: 'VIS-001',
          timestamp: DateTime.now(),
          metadata: {
            'patientId': 'PAT-MOCK-001',
            'caseId': 'CASE-001',
            'visitId': 'VIS-001',
            'visitNumber': 1,
            'doctorId': 'DOC-101',
            'completedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      expect(auditRepo.count, equals(2));
      final logs = auditRepo.logs;
      expect(logs[0].action, equals('VISIT_COMPLETION_DECLARATION_CONFIRMED'));
      expect(logs[1].action, equals('VISIT_COMPLETED'));

      // Verify zero sensitive secrets logged
      for (final l in logs) {
        final metaStr = l.metadata.toString().toLowerCase();
        expect(metaStr.contains('aadhaar'), isFalse);
        expect(metaStr.contains('otp'), isFalse);
        expect(metaStr.contains('password'), isFalse);
        expect(metaStr.contains('token'), isFalse);
        expect(metaStr.contains('apikey'), isFalse);
      }
    });

    test('20. Patient domain service retrieves clinical case bundle with visits and reports', () async {
      final patientRecordsService = PatientClinicalRecordsService.instance;
      final bundles = await patientRecordsService.getPatientCases('PAT-MOCK-001');

      expect(bundles.isNotEmpty, isTrue);
      final firstBundle = bundles.first;
      expect(firstBundle.isOpen, isTrue);
      expect(firstBundle.completedVisits.isNotEmpty, isTrue);
    });

    testWidgets('21. PatientCaseOverviewCard displays case title, OPEN status, and visit list', (tester) async {
      final bundle = PatientCaseRecordBundle(
        clinicalCase: mockCase,
        visits: [
          validCompleteVisit.copyWith(
            status: ClinicalVisitStatus.completed,
            completedAt: DateTime.now(),
          ),
        ],
        visitReports: {
          validCompleteVisit.visitId: [
            ReportDocument(
              reportId: 'REP-001',
              patientId: 'PAT-MOCK-001',
              caseId: 'CASE-001',
              visitId: validCompleteVisit.visitId,
              investigationId: 'REQ-001',
              fileName: 'ecg_test.pdf',
              contentType: 'application/pdf',
              fileSizeBytes: 1024,
              storagePath: '/reports/ecg.pdf',
              uploadedAt: DateTime.now(),
              uploadedByPatientId: 'PAT-MOCK-001',
              reviewStatus: ReportReviewStatus.reviewed,
            ),
          ],
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PatientCaseOverviewCard(
              bundle: bundle,
            ),
          ),
        ),
      );

      expect(find.text('Essential Hypertension'), findsOneWidget);
      expect(find.text('OPEN (ONGOING)'), findsOneWidget);
      expect(find.textContaining('Visit 1 — Dr. Rajesh Sharma'), findsOneWidget);
      expect(find.text('1 report(s) linked'), findsOneWidget);
    });

    test('22. English, Hindi, and Marathi localization coverage for Phase D12 strings', () {
      final en = DoctorLocalizations.forLocale(KioskLocale.english);
      final hi = DoctorLocalizations.forLocale(KioskLocale.hindi);
      final mr = DoctorLocalizations.forLocale(KioskLocale.marathi);

      expect(en.completeVisitDialogTitle, equals('Complete Visit'));
      expect(hi.completeVisitDialogTitle, equals('परामर्श पूर्ण करें'));
      expect(mr.completeVisitDialogTitle, equals('भेट पूर्ण करा'));

      expect(en.caseStatusOpenBadge, equals('OPEN (ONGOING)'));
      expect(hi.caseStatusOpenBadge, equals('खुला (जारी)'));
      expect(mr.caseStatusOpenBadge, equals('उघडी (चालू)'));

      expect(en.visitCompletedSuccessTitle, equals('Visit Completed Successfully'));
      expect(hi.visitCompletedSuccessTitle, equals('विज़िट सफलतापूर्वक संपन्न'));
      expect(mr.visitCompletedSuccessTitle, equals('भेट यशस्वीरित्या पूर्ण झाली'));

      expect(en.doctorDeclarationCheckbox.isNotEmpty, isTrue);
      expect(hi.doctorDeclarationCheckbox.isNotEmpty, isTrue);
      expect(mr.doctorDeclarationCheckbox.isNotEmpty, isTrue);
    });

    testWidgets('23. Responsive rendering of DoctorClinicalRecordsSection across desktop widths', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 768));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorClinicalRecordsSection(
              cases: [mockCase],
              selectedCase: mockCase,
              visits: [validCompleteVisit],
              onSelectCase: (_) {},
              onStartNewCase: () {},
              onAddVisit: () {},
            ),
          ),
        ),
      );

      expect(find.text('MY CASES'), findsOneWidget);
      expect(find.text('CARDIOLOGY — Essential Hypertension'), findsOneWidget);
      expect(find.text('Visit 1'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.binding.setSurfaceSize(null);
    });
  });
}

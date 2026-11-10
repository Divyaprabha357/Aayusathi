import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/doctor/localization/doctor_localizations.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/doctor/models/doctor_profile.dart';
import 'package:aayusathi/doctor/services/doctor_session_service.dart';
import 'package:aayusathi/doctor/widgets/doctor_case_escalation_dialog.dart';
import 'package:aayusathi/doctor/widgets/doctor_patient_workspace_widgets.dart';
import 'package:aayusathi/repositories/mock/mock_audit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    BackendProvider.instance.setMode(BackendMode.mock);
    MockCaseRepository.instance.resetToDefaults();
    MockClinicalVisitRepository.instance.resetToDefaults();
    MockAuditRepository.instance.clear();
    DoctorSessionService.instance.resetSession();

    final testDoctor = DoctorProfile(
      doctorId: 'DOC-101',
      doctorUniqueCode: 'DOC101',
      name: 'Dr. Ramesh Sharma',
      qualification: 'MBBS, MD',
      department: 'General Medicine',
      registeredPhone: '9876543210',
      email: 'ramesh.sharma@aayusathi.org',
      authUid: 'AUTH-101',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
    await DoctorSessionService.instance.enterDevelopmentWorkspace(profile: testDoctor);
  });

  group('Phase A8: Clinical Case Model & Escalation Serialization Tests', () {
    test('1. Default ClinicalCase has none escalation status and no escalation fields', () {
      final c = ClinicalCase(
        caseId: 'CASE-001',
        patientId: 'PAT-001',
        domain: 'General Medicine',
        title: 'Fever and chills',
        createdAt: DateTime(2026, 9, 8, 10, 0),
      );

      expect(c.escalationStatus, equals(CaseEscalationStatus.none));
      expect(c.isEscalated, isFalse);
      expect(c.isUnderReview, isFalse);
      expect(c.escalatedAt, isNull);
      expect(c.escalationReason, isNull);
      expect(c.escalatedByDoctorId, isNull);
      expect(c.escalationNote, isNull);
    });

    test('2. ClinicalCase with escalation serializes and deserializes correctly', () {
      final escalatedDate = DateTime(2026, 9, 8, 11, 30);
      final c = ClinicalCase(
        caseId: 'CASE-002',
        patientId: 'PAT-002',
        domain: 'General Medicine',
        title: 'Severe sepsis',
        createdAt: DateTime(2026, 9, 8, 10, 0),
        escalationStatus: CaseEscalationStatus.escalated,
        escalationReason: CaseEscalationReason.clinicalDeterioration,
        escalatedAt: escalatedDate,
        escalatedByDoctorId: 'DOC-101',
        escalatedByDoctorName: 'Dr. Ramesh Sharma',
        escalationSourceVisitId: 'VISIT-001',
        escalationNote: 'Patient vital signs deteriorating rapidly',
      );

      expect(c.isEscalated, isTrue);
      expect(c.isUnderReview, isFalse);

      final map = c.toMap();
      expect(map['escalationStatus'], equals('escalated'));
      expect(map['escalationReason'], equals('clinicalDeterioration'));
      expect(map['escalatedByDoctorId'], equals('DOC-101'));
      expect(map['escalatedByDoctorName'], equals('Dr. Ramesh Sharma'));
      expect(map['escalationSourceVisitId'], equals('VISIT-001'));
      expect(map['escalationNote'], equals('Patient vital signs deteriorating rapidly'));

      final restored = ClinicalCase.fromMap(map);
      expect(restored.caseId, equals('CASE-002'));
      expect(restored.escalationStatus, equals(CaseEscalationStatus.escalated));
      expect(restored.escalationReason, equals(CaseEscalationReason.clinicalDeterioration));
      expect(restored.escalatedByDoctorId, equals('DOC-101'));
      expect(restored.escalatedByDoctorName, equals('Dr. Ramesh Sharma'));
      expect(restored.escalationSourceVisitId, equals('VISIT-001'));
      expect(restored.escalationNote, equals('Patient vital signs deteriorating rapidly'));
      expect(restored.isEscalated, isTrue);
    });

    test('3. Legacy case without escalation fields deserializes safely as none', () {
      final legacyMap = {
        'caseId': 'CASE-LEGACY-001',
        'patientId': 'PAT-003',
        'domain': 'Pediatrics',
        'title': 'Childhood asthma',
        'status': 'open',
        'createdAt': DateTime.now().toIso8601String(),
      };

      final legacyCase = ClinicalCase.fromMap(legacyMap);
      expect(legacyCase.escalationStatus, equals(CaseEscalationStatus.none));
      expect(legacyCase.isEscalated, isFalse);
      expect(legacyCase.escalationReason, isNull);
    });
  });

  group('Phase A8: Doctor Case Escalation Dialog Widget Tests', () {
    testWidgets('1. DoctorCaseEscalationDialog renders all reasons and handles cancel', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final sampleCase = ClinicalCase(
        caseId: 'CASE-PAT-001-01',
        patientId: 'PAT-MOCK-001',
        domain: 'General Medicine',
        title: 'Persistent Respiratory Infection',
        createdAt: DateTime(2026, 9, 8, 9, 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => DoctorCaseEscalationDialog(
                      clinicalCase: sampleCase,
                      currentVisitNumber: 3,
                      department: 'General Medicine',
                      onConfirm: (reason, note) async {},
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Check header and dialog content
      expect(find.text('Request Higher Authority Review'), findsOneWidget);
      expect(find.text('CASE-PAT-001-01'), findsOneWidget);
      expect(find.text('PAT-MOCK-001'), findsOneWidget);

      // Verify reasons are present
      expect(find.text('Clinical deterioration'), findsOneWidget);
      expect(find.text('Repeated visits without resolution'), findsOneWidget);
      expect(find.text('Higher authority review required'), findsOneWidget);
      expect(find.text('Doctor concern'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);

      // Cancel button should dismiss dialog
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();

      expect(find.text('Request Higher Authority Review'), findsNothing);
    });

    testWidgets('2. Selecting "Other" requires note before escalation can be submitted', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      CaseEscalationReason? submittedReason;
      String? submittedNote;

      final sampleCase = ClinicalCase(
        caseId: 'CASE-PAT-001-01',
        patientId: 'PAT-MOCK-001',
        domain: 'General Medicine',
        title: 'Persistent Respiratory Infection',
        createdAt: DateTime(2026, 9, 8, 9, 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => DoctorCaseEscalationDialog(
                      clinicalCase: sampleCase,
                      currentVisitNumber: 2,
                      department: 'General Medicine',
                      onConfirm: (reason, note) async {
                        submittedReason = reason;
                        submittedNote = note;
                      },
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Select 'Other'
      await tester.tap(find.text('Other'));
      await tester.pumpAndSettle();

      // Attempt submit without note -> displays validation error
      await tester.tap(find.byKey(const ValueKey('confirm_escalate_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please provide an explanation when selecting "Other".'), findsOneWidget);

      // Enter note
      await tester.enterText(
        find.byKey(const ValueKey('doctor_escalation_note_input')),
        'Suspected rare autoimmune condition requiring department head review',
      );
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.byKey(const ValueKey('confirm_escalate_button')));
      await tester.pumpAndSettle();

      expect(submittedReason, equals(CaseEscalationReason.other));
      expect(submittedNote, equals('Suspected rare autoimmune condition requiring department head review'));
    });
  });

  group('Phase A8: Workspace Integration & Preservation of Consultation Invariants', () {
    testWidgets('1. DoctorWorkspaceBottomBar displays Escalate Case button and triggers callback', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool escalateCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: DoctorWorkspaceBottomBar(
              onSaveDraft: () {},
              onComplete: () {},
              onTransfer: () {},
              onEscalateCase: () {
                escalateCalled = true;
              },
            ),
          ),
        ),
      );

      final btn = find.byKey(const ValueKey('escalate_case_bottom_button'));
      expect(btn, findsOneWidget);
      expect(find.text('ESCALATE CASE'), findsOneWidget);

      await tester.tap(btn);
      await tester.pump();

      expect(escalateCalled, isTrue);
    });

    test('2. CaseRepository escalateCase updates status to escalated and records audit log', () async {
      final repo = MockCaseRepository.instance;
      const patientId = 'PAT-MOCK-001';
      const caseId = 'CASE-PAT-001-01';

      final escalatedCase = await repo.escalateCase(
        patientId: patientId,
        caseId: caseId,
        visitId: 'VISIT-PAT-001-01',
        reason: CaseEscalationReason.clinicalDeterioration,
        doctorId: 'DOC-101',
        doctorName: 'Dr. Ramesh Sharma',
        note: 'SPO2 dropping to 88%',
      );

      expect(escalatedCase.escalationStatus, equals(CaseEscalationStatus.escalated));
      expect(escalatedCase.isEscalated, isTrue);
      expect(escalatedCase.escalationReason, equals(CaseEscalationReason.clinicalDeterioration));
      expect(escalatedCase.escalatedByDoctorId, equals('DOC-101'));
      expect(escalatedCase.escalatedByDoctorName, equals('Dr. Ramesh Sharma'));
      expect(escalatedCase.escalationNote, equals('SPO2 dropping to 88%'));
      expect(escalatedCase.isOpen, isTrue); // Case remains OPEN

      // Verify audit repository recorded the event
      final auditEvents = await MockAuditRepository.instance.getLogsForEntity(
        entityType: 'CLINICAL_CASE',
        entityId: caseId,
      );
      expect(auditEvents.any((e) => e.action == 'CASE_ESCALATED'), isTrue);
    });

    test('3. Escalating an already escalated case throws Exception (duplicate prevention)', () async {
      final repo = MockCaseRepository.instance;
      const patientId = 'PAT-MOCK-001';
      const caseId = 'CASE-PAT-001-01';

      // First escalation
      await repo.escalateCase(
        patientId: patientId,
        caseId: caseId,
        visitId: 'VISIT-PAT-001-01',
        reason: CaseEscalationReason.doctorConcern,
        doctorId: 'DOC-101',
        doctorName: 'Dr. Ramesh Sharma',
      );

      // Attempt duplicate escalation
      expect(
        () async => await repo.escalateCase(
          patientId: patientId,
          caseId: caseId,
          visitId: 'VISIT-PAT-001-01',
          reason: CaseEscalationReason.clinicalDeterioration,
          doctorId: 'DOC-101',
          doctorName: 'Dr. Ramesh Sharma',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Phase A8: Doctor Localization Strings Tests', () {
    test('1. English, Hindi, and Marathi translations exist for Phase A8 doctor strings', () {
      final en = DoctorLocalizations.forLocale(KioskLocale.english);
      final hi = DoctorLocalizations.forLocale(KioskLocale.hindi);
      final mr = DoctorLocalizations.forLocale(KioskLocale.marathi);

      expect(en.escalateCaseButton, equals('ESCALATE CASE'));
      expect(hi.escalateCaseButton, isNotEmpty);
      expect(mr.escalateCaseButton, isNotEmpty);

      expect(en.escalateCaseDialogTitle, equals('Request Higher Authority Review'));
      expect(en.reasonClinicalDeterioration, equals('Clinical deterioration'));
      expect(en.reasonRepeatedVisits, equals('Repeated visits without resolution'));
      expect(en.reasonHigherAuthority, equals('Higher authority review required'));
      expect(en.reasonDoctorConcern, equals('Doctor concern'));
      expect(en.reasonOther, equals('Other'));
    });
  });
}

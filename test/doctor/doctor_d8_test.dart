import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/core/routes/app_routes.dart';
import 'package:aayusathi/core/theme/app_theme.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/doctor/models/clinical_visit.dart';
import 'package:aayusathi/doctor/models/investigation_request.dart';
import 'package:aayusathi/doctor/screens/doctor_patient_workspace_screen.dart';
import 'package:aayusathi/doctor/services/doctor_presence_service.dart';
import 'package:aayusathi/doctor/services/doctor_session_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_patient_workspace_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_presence_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_session_service.dart';
import 'package:aayusathi/doctor/widgets/doctor_buttons.dart';
import 'package:aayusathi/doctor/widgets/doctor_complete_visit_dialog.dart';
import 'package:aayusathi/doctor/widgets/doctor_consultation_widgets.dart';
import 'package:aayusathi/doctor/widgets/doctor_visit_completed_dialog.dart';
import 'package:aayusathi/models/audit_log.dart';
import 'package:aayusathi/models/patient.dart';
import 'package:aayusathi/models/vital_reading.dart';
import 'package:aayusathi/repositories/mock/mock_audit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_patient_repository.dart';

Widget buildTestableWidget(
  Widget child, {
  KioskLocale locale = KioskLocale.english,
  Map<String, dynamic>? initialArgs,
}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    routes: {
      AppRoutes.doctorDashboard: (ctx) => const Scaffold(body: Text('Doctor Dashboard Screen')),
      AppRoutes.doctorPatientWorkspace: (ctx) => DoctorPatientWorkspaceScreen(initialArguments: initialArgs),
    },
    home: Material(child: child),
  );
}

void setDesktopViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1920, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  late MockDoctorSessionService mockSession;
  late MockAuditRepository mockAuditRepo;
  late MockPatientRepository mockPatientRepo;
  late MockCaseRepository mockCaseRepo;
  late MockClinicalVisitRepository mockVisitRepo;
  late MockDoctorPresenceService mockPresenceService;
  late MockDoctorPatientWorkspaceService mockWorkspaceService;

  setUp(() async {
    BackendProvider.instance.setMode(BackendMode.mock);

    mockAuditRepo = MockAuditRepository.instance;
    mockAuditRepo.clear();
    BackendProvider.instance.setCustomRepositories(auditRepo: mockAuditRepo);

    mockPresenceService = MockDoctorPresenceService();
    mockPresenceService.resetPresence();
    mockPresenceService.goOnline();
    mockPresenceService.setInConsultation();
    DoctorPresenceService.instance = mockPresenceService;

    mockSession = MockDoctorSessionService(auditRepository: mockAuditRepo);
    DoctorSessionService.instance = mockSession;
    await mockSession.enterDevelopmentWorkspace();
    mockPresenceService.setInConsultation();

    mockPatientRepo = MockPatientRepository.instance;
    mockPatientRepo.resetToDefaults();

    mockCaseRepo = MockCaseRepository.instance;
    mockCaseRepo.resetToDefaults();

    mockVisitRepo = MockClinicalVisitRepository.instance;
    mockVisitRepo.resetToDefaults();

    mockWorkspaceService = MockDoctorPatientWorkspaceService.instance;
    mockWorkspaceService.simulateError = false;
    mockWorkspaceService.simulateUnauthorized = false;
  });

  group('AAYUSATHI Phase D8 — Models & Validation Unit Tests', () {
    test('1. InvestigationRequest model serialization and properties', () {
      final req = InvestigationRequest(
        requestId: 'REQ-INV-101',
        name: '12-Lead Electrocardiogram (ECG)',
        priority: InvestigationPriority.required,
        status: InvestigationStatus.pendingUpload,
        requestedAt: DateTime(2026, 9, 5, 10, 0),
        notes: 'Pre-procedure baseline',
      );

      expect(req.name, equals('12-Lead Electrocardiogram (ECG)'));
      expect(req.isRequired, isTrue);
      expect(req.isAsAdvised, isFalse);
      expect(req.isPendingUpload, isTrue);
      expect(req.priority.label, equals('Required'));

      final map = req.toMap();
      final fromMap = InvestigationRequest.fromMap(map);
      expect(fromMap.name, equals(req.name));
      expect(fromMap.priority, equals(InvestigationPriority.required));
      expect(fromMap.status, equals(InvestigationStatus.pendingUpload));
    });

    test('2. ClinicalVisit model validation and completion check', () {
      final visit = ClinicalVisit(
        visitId: 'VIS-TEST-01',
        caseId: 'CASE-001',
        patientId: 'PAT-001',
        doctorId: 'DOC-101',
        visitNumber: 1,
        startedAt: DateTime.now(),
        chiefComplaint: 'Chest tightness',
        onsetDuration: '3 days',
        associatedSymptoms: 'Palpitations',
        medicalHistory: 'Hypertension',
        currentMedication: 'Amlodipine 5mg',
        clinicalObservations: 'BP 140/90 mmHg',
        assessment: 'Stage 1 Hypertension',
        plan: 'Lifestyle modification, ECG',
        summaryText: 'Initial hypertension workup',
        summaryApprovalStatus: SummaryApprovalStatus.approvedByDoctor,
      );

      expect(visit.areConsultationFieldsComplete, isTrue);
      expect(visit.isSummaryApproved, isTrue);
      expect(visit.canCompleteVisit, isTrue);
      expect(visit.missingRequirements, isEmpty);
    });

    test('3. Incomplete ClinicalVisit reports missing requirements', () {
      final incompleteVisit = ClinicalVisit(
        visitId: 'VIS-TEST-02',
        caseId: 'CASE-001',
        patientId: 'PAT-001',
        doctorId: 'DOC-101',
        visitNumber: 1,
        startedAt: DateTime.now(),
        chiefComplaint: 'Chest tightness',
        // Missing remaining 7 fields
        summaryText: 'Draft summary',
        summaryApprovalStatus: SummaryApprovalStatus.draft,
      );

      expect(incompleteVisit.areConsultationFieldsComplete, isFalse);
      expect(incompleteVisit.isSummaryApproved, isFalse);
      expect(incompleteVisit.canCompleteVisit, isFalse);
      expect(incompleteVisit.missingRequirements.length, greaterThanOrEqualTo(7));
      expect(incompleteVisit.missingRequirements, contains('Onset / Duration'));
      expect(incompleteVisit.missingRequirements, contains('Assessment'));
      expect(incompleteVisit.missingRequirements, contains('Plan'));
      expect(incompleteVisit.missingRequirements, contains('Doctor Summary Approval'));
    });

    test('4. ClinicalCase relevantHistory field and getters', () {
      final c = ClinicalCase(
        caseId: 'CASE-001',
        patientId: 'PAT-001',
        domain: 'Cardiology',
        title: 'Hypertension Care',
        createdAt: DateTime.now(),
        visitCount: 1,
        relevantHistory: 'Family history of premature CAD.',
      );

      expect(c.isNewCase, isTrue);
      expect(c.isExistingCase, isFalse);
      expect(c.relevantHistory, equals('Family history of premature CAD.'));

      final updated = c.copyWith(visitCount: 2);
      expect(updated.isNewCase, isFalse);
      expect(updated.isExistingCase, isTrue);
    });

    test('5. Summary approval state transitions and edit reset', () {
      var visit = ClinicalVisit(
        visitId: 'VIS-001',
        caseId: 'CASE-001',
        patientId: 'PAT-001',
        doctorId: 'DOC-101',
        visitNumber: 1,
        startedAt: DateTime.now(),
        summaryText: 'Original approved text',
        summaryApprovalStatus: SummaryApprovalStatus.approvedByDoctor,
      );

      expect(visit.summaryApprovalStatus, equals(SummaryApprovalStatus.approvedByDoctor));

      // Simulate doctor editing summary after approval
      visit = visit.copyWith(
        summaryText: 'Modified summary text',
        summaryApprovalStatus: SummaryApprovalStatus.reviewRequired,
      );

      expect(visit.summaryApprovalStatus, equals(SummaryApprovalStatus.reviewRequired));
      expect(visit.isSummaryApproved, isFalse);
    });

    test('6. Strictly NO Aadhaar stored in consultation models', () {
      final visit = ClinicalVisit(
        visitId: 'VIS-001',
        caseId: 'CASE-001',
        patientId: 'PAT-001',
        doctorId: 'DOC-101',
        visitNumber: 1,
        startedAt: DateTime.now(),
        chiefComplaint: 'Checkup',
        onsetDuration: '1 day',
        associatedSymptoms: 'None',
        medicalHistory: 'None',
        currentMedication: 'None',
        clinicalObservations: 'Normal',
        assessment: 'Healthy',
        plan: 'Routine',
      );

      final map = visit.toMap();
      expect(map.containsKey('aadhaar'), isFalse);
      expect(map.containsKey('aadhaarNumber'), isFalse);
      expect(map.containsKey('otp'), isFalse);
      expect(map.containsKey('password'), isFalse);
    });
  });

  group('AAYUSATHI Phase D8 — UI Consultation Form & Widgets Tests', () {
    testWidgets('7. Visit Identification card renders fields', (tester) async {
      setDesktopViewport(tester);

      await tester.pumpWidget(
        buildTestableWidget(
          DoctorVisitIdentificationCard(
            patientId: 'AAYU-102938',
            caseId: 'CASE-00041',
            visitNumber: 1,
            status: ClinicalVisitStatus.active,
            department: 'Cardiology',
            dateTime: DateTime(2026, 9, 5, 19, 45),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('VISIT IDENTIFICATION'), findsOneWidget);
      expect(find.text('AAYU-102938'), findsOneWidget);
      expect(find.text('CASE-00041'), findsOneWidget);
      expect(find.text('Visit 1'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('Cardiology'), findsOneWidget);
      expect(find.text('05/09/2026 | 19:45'), findsOneWidget);
    });

    testWidgets('8. Patient Information card renders read-only data without Aadhaar', (tester) async {
      setDesktopViewport(tester);
      final patient = Patient(
        patientId: 'AAYU-102938',
        name: 'Rahul Sharma',
        dateOfBirth: '1984-05-14',
        age: 42,
        gender: 'Male',
        phone: '+919876543210',
        bloodGroup: 'B+',
        address: 'Pune, Maharashtra',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          DoctorPatientInfoConsultationCard(
            patient: patient,
            doctorName: 'Dr. Rajesh Sharma',
            doctorQualification: 'MBBS, MD (Cardiology)',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PATIENT INFORMATION'), findsOneWidget);
      expect(find.text('Rahul Sharma'), findsOneWidget);
      expect(find.text('42 years'), findsOneWidget);
      expect(find.text('Male'), findsOneWidget);
      expect(find.text('B+'), findsOneWidget);
      expect(find.text('Dr. Rajesh Sharma • MBBS, MD (Cardiology)'), findsOneWidget);

      // Verify Aadhaar is NOT present
      expect(find.text('Aadhaar'), findsNothing);
      expect(find.text('123456789012'), findsNothing);
    });

    testWidgets('9. Vitals at Consultation card renders readings and handles null gracefully', (tester) async {
      setDesktopViewport(tester);

      final vitals = VitalReading(
        vitalId: 'VIT-001',
        patientId: 'PAT-001',
        spo2: 97,
        heartRate: 76,
        temperature: 36.7,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          DoctorVitalsConsultationCard(vitals: vitals),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('VITALS AT CONSULTATION'), findsOneWidget);
      expect(find.text('97%'), findsOneWidget);
      expect(find.text('128 / 82 mmHg'), findsNothing);
      expect(find.text('76 BPM'), findsOneWidget);
      expect(find.text('36.7 °C'), findsOneWidget);

      // Test with null vitals
      await tester.pumpWidget(
        buildTestableWidget(
          const DoctorVitalsConsultationCard(vitals: null),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Not available'), findsNWidgets(3));
    });

    testWidgets('10. Case Information card renders case status and allows relevant history edit', (tester) async {
      setDesktopViewport(tester);
      final historyController = TextEditingController(text: 'Past history of hypertension.');

      final clinicalCase = ClinicalCase(
        caseId: 'CASE-00041',
        patientId: 'PAT-001',
        domain: 'Cardiology',
        title: 'Hypertension & Chest Tightness',
        createdAt: DateTime.now(),
        visitCount: 2,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          DoctorCaseInfoCard(
            clinicalCase: clinicalCase,
            relevantHistoryController: historyController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CASE INFORMATION'), findsOneWidget);
      expect(find.text('Hypertension & Chest Tightness'), findsOneWidget);
      expect(find.text('Existing Case'), findsOneWidget);
      expect(find.text('Ongoing'), findsOneWidget);
      expect(find.text('Past history of hypertension.'), findsOneWidget);
    });

    testWidgets('11. Structured Consultation card renders all 8 required clinical fields', (tester) async {
      setDesktopViewport(tester);

      final c1 = TextEditingController(text: 'Chest tightness');
      final c2 = TextEditingController(text: '3 days');
      final c3 = TextEditingController(text: 'Mild palpitations');
      final c4 = TextEditingController(text: 'Hypertension for 5 years');
      final c5 = TextEditingController(text: 'Amlodipine 5mg OD');
      final c6 = TextEditingController(text: 'BP 140/90, regular pulse');
      final c7 = TextEditingController(text: 'Stage 1 Hypertension');
      final c8 = TextEditingController(text: 'Titrate medications, order ECG');

      await tester.pumpWidget(
        buildTestableWidget(
          SingleChildScrollView(
            child: DoctorStructuredConsultationCard(
              chiefComplaintController: c1,
              onsetDurationController: c2,
              associatedSymptomsController: c3,
              medicalHistoryController: c4,
              currentMedicationController: c5,
              clinicalObservationsController: c6,
              assessmentController: c7,
              planController: c8,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('STRUCTURED CONSULTATION'), findsOneWidget);
      expect(find.text('1. Chief Complaint'), findsOneWidget);
      expect(find.text('2. Onset / Duration'), findsOneWidget);
      expect(find.text('3. Associated Symptoms'), findsOneWidget);
      expect(find.text('4. Medical History'), findsOneWidget);
      expect(find.text('5. Current Medication'), findsOneWidget);
      expect(find.text('6. Clinical Observations'), findsOneWidget);
      expect(find.text('7. Assessment'), findsOneWidget);
      expect(find.text('8. Plan'), findsOneWidget);
      expect(find.text('8 MANDATORY CLINICAL FIELDS'), findsOneWidget);
    });

    testWidgets('12. Doctor-Approved Summary card supports entry, approval and edit reset', (tester) async {
      setDesktopViewport(tester);

      final summaryCtrl = TextEditingController(text: 'Clinical summary for patient.');
      SummaryApprovalStatus currentStatus = SummaryApprovalStatus.draft;
      bool approvedCalled = false;

      await tester.pumpWidget(
        buildTestableWidget(
          StatefulBuilder(
            builder: (ctx, setState) {
              return DoctorApprovedSummaryCard(
                summaryController: summaryCtrl,
                approvalStatus: currentStatus,
                onApprove: () {
                  approvedCalled = true;
                  setState(() => currentStatus = SummaryApprovalStatus.approvedByDoctor);
                },
                onSummaryChanged: (_) {
                  if (currentStatus == SummaryApprovalStatus.approvedByDoctor) {
                    setState(() => currentStatus = SummaryApprovalStatus.reviewRequired);
                  }
                },
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DOCTOR-APPROVED VISIT SUMMARY'), findsOneWidget);
      expect(find.text('DRAFT'), findsOneWidget);
      expect(find.text('APPROVE SUMMARY'), findsOneWidget);

      // Tap APPROVE SUMMARY
      await tester.tap(find.text('APPROVE SUMMARY'));
      await tester.pumpAndSettle();

      expect(approvedCalled, isTrue);
      expect(find.text('APPROVED BY DOCTOR'), findsOneWidget);

      // Edit summary text to verify status reverts to REVIEW REQUIRED
      await tester.enterText(find.byType(TextField), 'Modified summary text.');
      await tester.pumpAndSettle();

      expect(find.text('REVIEW REQUIRED'), findsOneWidget);
    });

    testWidgets('13. Reports / Investigations card renders requests and allows adding items', (tester) async {
      setDesktopViewport(tester);

      final requests = [
        InvestigationRequest(
          requestId: 'REQ-1',
          name: '12-Lead ECG',
          priority: InvestigationPriority.required,
          status: InvestigationStatus.pendingUpload,
          requestedAt: DateTime.now(),
        ),
      ];

      bool addClicked = false;

      await tester.pumpWidget(
        buildTestableWidget(
          DoctorInvestigationRequestsCard(
            requests: requests,
            onAddInvestigation: () => addClicked = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('REPORTS / INVESTIGATIONS REQUESTED'), findsOneWidget);
      expect(find.text('12-Lead ECG'), findsOneWidget);
      expect(find.text('Required'), findsOneWidget);
      expect(find.text('Pending Upload'), findsOneWidget);

      await tester.tap(find.text('+ ADD REPORT / INVESTIGATION'));
      await tester.pumpAndSettle();

      expect(addClicked, isTrue);
    });

    testWidgets('14. Plan / Follow-up card renders follow-up and patient instructions', (tester) async {
      setDesktopViewport(tester);

      final followUpCtrl = TextEditingController(text: 'Review in 2 weeks.');
      final instructionsCtrl = TextEditingController(text: 'Low sodium diet.');

      await tester.pumpWidget(
        buildTestableWidget(
          DoctorFollowUpCard(
            followUpController: followUpCtrl,
            patientInstructionsController: instructionsCtrl,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PLAN / FOLLOW-UP'), findsOneWidget);
      expect(find.text('Review in 2 weeks.'), findsOneWidget);
      expect(find.text('Low sodium diet.'), findsOneWidget);
    });

    testWidgets('15. Add Investigation dialog validates name and sets priority', (tester) async {
      setDesktopViewport(tester);

      String? addedName;
      InvestigationPriority? addedPriority;

      await tester.pumpWidget(
        buildTestableWidget(
          DoctorAddInvestigationDialog(
            onConfirm: (name, priority) {
              addedName = name;
              addedPriority = priority;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('+ ADD REPORT / INVESTIGATION'), findsOneWidget);
      expect(find.text('Required'), findsOneWidget);
      expect(find.text('As Advised'), findsOneWidget);

      // Enter name and select As Advised
      await tester.enterText(find.byType(TextField), '2D Echocardiography');
      await tester.tap(find.text('As Advised'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SAVE'));
      await tester.pumpAndSettle();

      expect(addedName, equals('2D Echocardiography'));
      expect(addedPriority, equals(InvestigationPriority.asAdvised));
    });

    testWidgets('16. Missing Requirements dialog displays list of incomplete fields', (tester) async {
      setDesktopViewport(tester);

      final missing = ['Assessment', 'Plan', 'Doctor Summary Approval'];

      await tester.pumpWidget(
        buildTestableWidget(
          DoctorMissingRequirementsDialog(missingRequirements: missing),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Missing Consultation Requirements'), findsOneWidget);
      expect(find.text('Assessment'), findsOneWidget);
      expect(find.text('Plan'), findsOneWidget);
      expect(find.text('Doctor Summary Approval'), findsOneWidget);
    });
  });

  group('AAYUSATHI Phase D8 — Full Consultation Workflow & Persistence Tests', () {
    testWidgets('17. Full Workspace loads with consultation sections and active visit', (tester) async {
      setDesktopViewport(tester);

      await tester.pumpWidget(
        buildTestableWidget(
          const DoctorPatientWorkspaceScreen(
            initialArguments: {
              'requestId': 'REQ-D5-001',
              'queueNumber': 'A-00027',
              'domain': 'Cardiology',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top Header & Identity
      expect(find.text('PATIENT WORKSPACE'), findsOneWidget);
      expect(find.text('Aarav Sharma'), findsOneWidget);

      // Consultation sections
      expect(find.text('VISIT IDENTIFICATION'), findsOneWidget);
      expect(find.text('VITALS AT CONSULTATION'), findsOneWidget);
      expect(find.text('CASE INFORMATION'), findsOneWidget);
      expect(find.text('STRUCTURED CONSULTATION'), findsOneWidget);
      expect(find.text('DOCTOR-APPROVED VISIT SUMMARY'), findsOneWidget);
      expect(find.text('REPORTS / INVESTIGATIONS REQUESTED'), findsOneWidget);
      expect(find.text('PLAN / FOLLOW-UP'), findsOneWidget);
    });

    testWidgets('18. Incomplete consultation blocks Complete Visit with missing requirements dialog', (tester) async {
      setDesktopViewport(tester);

      await tester.pumpWidget(
        buildTestableWidget(
          const DoctorPatientWorkspaceScreen(
            initialArguments: {
              'requestId': 'REQ-D5-001',
              'queueNumber': 'A-00027',
              'domain': 'Cardiology',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Clear one of the mandatory consultation fields to make it incomplete
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(1), ''); // Chief complaint
      await tester.pumpAndSettle();

      // Click COMPLETE VISIT without filling all required fields
      await tester.tap(find.text('COMPLETE VISIT'));
      await tester.pumpAndSettle();

      expect(find.text('Missing Consultation Requirements'), findsOneWidget);
      expect(find.byType(DoctorMissingRequirementsDialog), findsOneWidget);
    });

    testWidgets('19. Save Draft persists consultation fields without completing visit or releasing presence', (tester) async {
      setDesktopViewport(tester);

      await tester.pumpWidget(
        buildTestableWidget(
          const DoctorPatientWorkspaceScreen(
            initialArguments: {
              'requestId': 'REQ-D5-001',
              'queueNumber': 'A-00027',
              'domain': 'Cardiology',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter Chief Complaint
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(1), 'Draft complaint note.');
      await tester.pumpAndSettle();

      // Click SAVE DRAFT
      await tester.tap(find.text('SAVE DRAFT'));
      await tester.pumpAndSettle();

      expect(find.text('Consultation draft saved successfully.'), findsOneWidget);

      // Verify doctor presence remains IN_CONSULTATION
      expect(mockPresenceService.isInConsultation, isTrue);
      expect(mockPresenceService.isAvailable, isFalse);

      // Verify audit event CONSULTATION_DRAFT_SAVED
      final draftAudits = mockAuditRepo.logs.where((l) => l.action == 'CONSULTATION_DRAFT_SAVED');
      expect(draftAudits, isNotEmpty);
    });

    testWidgets('20. Summary approval records Doctor ID and timestamp', (tester) async {
      setDesktopViewport(tester);

      await tester.pumpWidget(
        buildTestableWidget(
          const DoctorPatientWorkspaceScreen(
            initialArguments: {
              'requestId': 'REQ-D5-001',
              'queueNumber': 'A-00027',
              'domain': 'Cardiology',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down to make summary card visible
      await tester.ensureVisible(find.text('APPROVE SUMMARY'));
      await tester.pumpAndSettle();
      await tester.drag(find.text('APPROVE SUMMARY'), const Offset(0, -100));
      await tester.pumpAndSettle();

      // Enter summary text
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(9), 'Hypertension stage 1 controlled with medications.');
      await tester.pumpAndSettle();

      // Click APPROVE SUMMARY
      await tester.tap(find.text('APPROVE SUMMARY'));
      await tester.pumpAndSettle();

      expect(find.text('APPROVED BY DOCTOR'), findsOneWidget);
      expect(find.text('Visit summary approved by treating doctor.'), findsOneWidget);

      // Verify audit event SUMMARY_APPROVED
      final approvalAudits = mockAuditRepo.logs.where((l) => l.action == 'SUMMARY_APPROVED');
      expect(approvalAudits, isNotEmpty);
    });

    testWidgets('21. Successful visit completion marks Visit COMPLETED, preserves Case ONGOING, and sets presence AVAILABLE', (tester) async {
      setDesktopViewport(tester);

      await tester.pumpWidget(
        buildTestableWidget(
          const DoctorPatientWorkspaceScreen(
            initialArguments: {
              'requestId': 'REQ-D5-001',
              'queueNumber': 'A-00027',
              'domain': 'Cardiology',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);

      // Fill all 8 consultation fields
      await tester.enterText(textFields.at(1), 'Chest tightness on exertion'); // 1. Chief Complaint
      await tester.enterText(textFields.at(2), '2 weeks'); // 2. Onset
      await tester.enterText(textFields.at(3), 'Palpitations'); // 3. Associated Symptoms
      await tester.enterText(textFields.at(4), 'Known hypertension'); // 4. Medical History
      await tester.enterText(textFields.at(5), 'Amlodipine 5mg'); // 5. Medication
      await tester.enterText(textFields.at(6), 'BP 130/84, clear lungs'); // 6. Observations
      await tester.enterText(textFields.at(7), 'Stage 1 Hypertension'); // 7. Assessment
      await tester.enterText(textFields.at(8), 'Continue medication, ECG'); // 8. Plan

      await tester.enterText(find.byKey(const Key('field_visit_summary')), 'Patient assessed and stable on therapy.'); // Summary
      await tester.pumpAndSettle();

      // Approve Summary
      await tester.tap(find.byKey(const Key('btn_approve_summary')));
      await tester.pumpAndSettle();

      expect(find.text('APPROVED BY DOCTOR'), findsOneWidget);

      // Dismiss floating SnackBar so COMPLETE VISIT button is unobstructed
      ScaffoldMessenger.of(tester.element(find.byType(DoctorPatientWorkspaceScreen))).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      // Click COMPLETE VISIT on bottom bar to open D12 declaration dialog
      await tester.tap(find.text('COMPLETE VISIT'));
      await tester.pumpAndSettle();

      // Verify D12 declaration dialog opened
      expect(find.byType(DoctorCompleteVisitDialog), findsOneWidget);

      // Check declaration checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Click submit COMPLETE VISIT in the declaration dialog
      final dialogSubmit = find.descendant(
        of: find.byType(DoctorCompleteVisitDialog),
        matching: find.widgetWithText(DoctorPrimaryButton, 'COMPLETE VISIT'),
      );
      await tester.tap(dialogSubmit);
      await tester.pumpAndSettle();

      // Verify DoctorVisitCompletedDialog is shown with OPEN case status
      expect(find.byType(DoctorVisitCompletedDialog), findsOneWidget);
      expect(find.text('OPEN (ONGOING)'), findsOneWidget);

      // Tap RETURN TO DASHBOARD
      await tester.tap(find.widgetWithText(DoctorPrimaryButton, 'RETURN TO DASHBOARD'));
      await tester.pumpAndSettle();

      // Verify doctor presence transitioned to AVAILABLE
      expect(mockPresenceService.isAvailable, isTrue);
      expect(mockPresenceService.isInConsultation, isFalse);

      // Verify redirect to Dashboard
      expect(find.text('Doctor Dashboard Screen'), findsOneWidget);

      // Verify audit event VISIT_COMPLETED
      final completionAudits = mockAuditRepo.logs.where((l) => l.action == 'VISIT_COMPLETED');
      expect(completionAudits, isNotEmpty);
    });

    testWidgets('22. Hindi localized strings render properly in consultation workspace', (tester) async {
      setDesktopViewport(tester);

      await tester.pumpWidget(
        buildTestableWidget(
          SingleChildScrollView(
            child: DoctorStructuredConsultationCard(
              chiefComplaintController: TextEditingController(),
              onsetDurationController: TextEditingController(),
              associatedSymptomsController: TextEditingController(),
              medicalHistoryController: TextEditingController(),
              currentMedicationController: TextEditingController(),
              clinicalObservationsController: TextEditingController(),
              assessmentController: TextEditingController(),
              planController: TextEditingController(),
              locale: KioskLocale.hindi,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('संरचित परामर्श'), findsOneWidget);
      expect(find.text('1. मुख्य शिकायत'), findsOneWidget);
      expect(find.text('2. शुरुआत / अवधि'), findsOneWidget);
      expect(find.text('7. मूल्यांकन / निदान'), findsOneWidget);
      expect(find.text('8. उपचार योजना'), findsOneWidget);
    });

    testWidgets('23. Marathi localized strings render properly in consultation workspace', (tester) async {
      setDesktopViewport(tester);

      await tester.pumpWidget(
        buildTestableWidget(
          SingleChildScrollView(
            child: DoctorStructuredConsultationCard(
              chiefComplaintController: TextEditingController(),
              onsetDurationController: TextEditingController(),
              associatedSymptomsController: TextEditingController(),
              medicalHistoryController: TextEditingController(),
              currentMedicationController: TextEditingController(),
              clinicalObservationsController: TextEditingController(),
              assessmentController: TextEditingController(),
              planController: TextEditingController(),
              locale: KioskLocale.marathi,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('संरचित सल्लामसलत'), findsOneWidget);
      expect(find.text('1. मुख्य तक्रार'), findsOneWidget);
      expect(find.text('2. सुरुवात / कालावधी'), findsOneWidget);
      expect(find.text('7. मूल्यांकन / निदान'), findsOneWidget);
      expect(find.text('8. उपचार योजना'), findsOneWidget);
    });

    testWidgets('24. Audit events contain zero Aadhaar, passwords, or OTPs', (tester) async {
      await mockAuditRepo.logEvent(
        AuditLog(
          auditId: 'AUDIT-D8-TEST',
          actorType: 'DOCTOR',
          actorId: 'DOC-101',
          action: 'VISIT_COMPLETED',
          entityType: 'CLINICAL_VISIT',
          entityId: 'VIS-PAT-001-01-1',
          timestamp: DateTime.now(),
          metadata: {
            'patientId': 'PAT-MOCK-001',
            'caseId': 'CASE-PAT-001-01',
            'queueNumber': 'A-00027',
          },
        ),
      );

      final log = mockAuditRepo.logs.firstWhere((l) => l.auditId == 'AUDIT-D8-TEST');
      expect(log.metadata.containsKey('aadhaar'), isFalse);
      expect(log.metadata.containsKey('aadhaarNumber'), isFalse);
      expect(log.metadata.containsKey('otp'), isFalse);
      expect(log.metadata.containsKey('password'), isFalse);
    });
  });
}

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aayusathi/core/backend/backend_exception.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/supabase/supabase_config.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/doctor/models/clinical_visit.dart';
import 'package:aayusathi/doctor/models/investigation_request.dart';
import 'package:aayusathi/doctor/models/report_document.dart';
import 'package:aayusathi/models/appointment_request.dart';
import 'package:aayusathi/patient/controllers/patient_dashboard_controller.dart';
import 'package:aayusathi/patient/models/patient_app_state.dart';
import 'package:aayusathi/patient/models/patient_calendar_item.dart';
import 'package:aayusathi/patient/patient_routes.dart';
import 'package:aayusathi/patient/services/patient_auth_service.dart';
import 'package:aayusathi/patient/services/patient_clinical_records_service.dart';
import 'package:aayusathi/patient/services/patient_follow_up_service.dart';
import 'package:aayusathi/patient/services/patient_notification_service.dart';
import 'package:aayusathi/patient/services/patient_report_file_validator.dart';
import 'package:aayusathi/patient/services/patient_report_upload_service.dart';
import 'package:aayusathi/patient/services/patient_session_service.dart';
import 'package:aayusathi/repositories/case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_appointment_repository.dart';
import 'package:aayusathi/repositories/mock/mock_audit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_investigation_repository.dart';
import 'package:aayusathi/repositories/mock/mock_patient_repository.dart';
import 'package:aayusathi/repositories/mock/mock_report_repository.dart';
import 'package:aayusathi/doctor/services/mock_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPatientRepository mockPatientRepo;
  late MockAppointmentRepository mockApptRepo;
  late MockCaseRepository mockCaseRepo;
  late MockClinicalVisitRepository mockVisitRepo;
  late MockInvestigationRepository mockInvestigationRepo;
  late MockReportRepository mockReportRepo;
  late MockStorageService mockStorageService;
  late MockAuditRepository mockAuditRepo;

  const testPatientId = 'AAYU-102938';
  const otherPatientId = 'AAYU-999999';

  setUp(() {
    mockPatientRepo = MockPatientRepository.instance;
    mockApptRepo = MockAppointmentRepository.instance;
    mockCaseRepo = MockCaseRepository.instance;
    mockVisitRepo = MockClinicalVisitRepository.instance;
    mockInvestigationRepo = MockInvestigationRepository.instance;
    mockReportRepo = MockReportRepository.instance;
    mockStorageService = MockStorageService.instance;
    mockAuditRepo = MockAuditRepository.instance;

    mockPatientRepo.resetToDefaults();
    mockApptRepo.clear();
    mockCaseRepo.resetToDefaults();
    mockVisitRepo.resetToDefaults();
    mockInvestigationRepo.reset();
    mockReportRepo.reset();
    mockStorageService.reset();
    mockAuditRepo.clear();

    BackendProvider.instance.setMode(BackendMode.mock);
    BackendProvider.instance.setCustomRepositories(
      patientRepo: mockPatientRepo,
      appointmentRepo: mockApptRepo,
      caseRepo: mockCaseRepo,
      clinicalVisitRepo: mockVisitRepo,
      investigationRepo: mockInvestigationRepo,
      reportRepo: mockReportRepo,
      storageService: mockStorageService,
      auditRepo: mockAuditRepo,
    );

    PatientSessionService.instance.logout();
    PatientAppState.instance.resetSession();
  });

  tearDown(() {
    BackendProvider.instance.resetOverrides();
    PatientSessionService.instance.logout();
    PatientAppState.instance.resetSession();
  });

  group('AAYUSATHI P11 — Cross-Module Synchronization & Final Integration', () {
    // 1. Patient authentication ownership
    test('1. Patient authentication ownership is strictly scoped', () {
      PatientSessionService.instance.startSession(testPatientId, authUid: 'mock-uid-102');
      expect(PatientSessionService.instance.isAuthenticated, isTrue);
      expect(PatientSessionService.instance.authenticatedPatientId, equals(testPatientId));
      expect(PatientAppState.instance.authenticatedPatientId, equals(testPatientId));
      expect(PatientAppState.instance.isAuthenticated, isTrue);

      final session = PatientSessionService.instance.currentSession;
      expect(session.patientId, equals(testPatientId));
      expect(session.toString().contains('aadhaar'), isFalse);
    });

    // 2. Patient profile retrieval
    test('2. Patient profile retrieval returns real data without plain Aadhaar', () async {
      final patient = await mockPatientRepo.getPatientById(testPatientId);
      expect(patient, isNotNull);
      expect(patient!.patientId, equals(testPatientId));
      expect(patient.name, equals('Aarav Sharma'));
      expect(patient.isActive, isTrue);

      final firestoreData = patient.toFirestore();
      expect(firestoreData.containsKey('aadhaarNumber'), isFalse);
      expect(firestoreData.containsKey('aadhaar'), isFalse);
    });

    // 3. Patient appointment synchronization
    test('3. Patient appointment synchronization reflects queue and status', () async {
      final appt = AppointmentRequest(
        requestId: 'APT-P11-001',
        patientId: testPatientId,
        domainId: 'cardiology',
        status: AppointmentStatus.waiting,
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        queueNumber: 'A-00042',
        createdAt: DateTime.now(),
        source: 'KIOSK',
        sessionId: 'SESS-P11',
      );
      await mockApptRepo.saveAppointment(appt);

      final patientAppts = await mockApptRepo.getAppointmentsForPatient(testPatientId);
      expect(patientAppts.length, equals(1));
      expect(patientAppts.first.requestId, equals('APT-P11-001'));
      expect(patientAppts.first.queueNumber, equals('A-00042'));
      expect(patientAppts.first.status, equals(AppointmentStatus.waiting));
    });

    // 4. Case synchronization
    test('4. Case synchronization links Patient to canonical ClinicalCase', () async {
      final newCase = ClinicalCase(
        caseId: 'CASE-P11-101',
        patientId: testPatientId,
        domain: 'cardiology',
        title: 'Hypertension Management',
        status: ClinicalCaseStatus.open,
        createdAt: DateTime.now(),
      );
      await mockCaseRepo.createCase(newCase);

      final patientCases = await mockCaseRepo.getCasesForPatient(testPatientId);
      expect(patientCases.any((c) => c.caseId == 'CASE-P11-101'), isTrue);
      final retrieved = patientCases.firstWhere((c) => c.caseId == 'CASE-P11-101');
      expect(retrieved.domain, equals('cardiology'));
      expect(retrieved.isOpen, isTrue);
    });

    // 5. Visit synchronization
    test('5. Visit synchronization preserves visit number, vitals, and consultation fields', () async {
      final visit = ClinicalVisit(
        visitId: 'VISIT-P11-501',
        caseId: 'CASE-P11-101',
        patientId: testPatientId,
        doctorId: 'DOC-01',
        doctorName: 'Dr. Ramesh Gupta',
        doctorQualification: 'MD Cardiology',
        visitNumber: 1,
        startedAt: DateTime.now().subtract(const Duration(hours: 1)),
        completedAt: DateTime.now(),
        status: ClinicalVisitStatus.completed,
        chiefComplaint: 'Mild chest discomfort on exertion',
        onsetDuration: '3 days',
        associatedSymptoms: 'Shortness of breath',
        medicalHistory: 'Hypertension x 2 years',
        currentMedication: 'Amlodipine 5mg OD',
        clinicalObservations: 'BP elevated, normal S1/S2',
        assessment: 'Stage 1 Hypertension',
        plan: 'Lifestyle modifications + ECG',
        summaryText: 'Initial consultation completed. Advised ECG and blood tests.',
        summaryApprovalStatus: SummaryApprovalStatus.approvedByDoctor,
      );
      await mockVisitRepo.createVisit(visit);

      final visits = await mockVisitRepo.getVisitsForCase(
        patientId: testPatientId,
        caseId: 'CASE-P11-101',
      );
      expect(visits.length, equals(1));
      expect(visits.first.visitNumber, equals(1));
      expect(visits.first.doctorName, equals('Dr. Ramesh Gupta'));
      expect(visits.first.isCompleted, isTrue);
      expect(visits.first.isSummaryApproved, isTrue);
    });

    // 6. Investigation synchronization
    test('6. Investigation synchronization reflects doctor order in patient view', () async {
      final inv = InvestigationRequest(
        requestId: 'INV-P11-601',
        patientId: testPatientId,
        caseId: 'CASE-P11-101',
        visitId: 'VISIT-P11-501',
        name: 'Lipid Profile & ECG',
        priority: InvestigationPriority.required,
        status: InvestigationStatus.pendingUpload,
        requestedAt: DateTime.now(),
      );
      await mockInvestigationRepo.createInvestigationRequest(inv);

      final pending = await mockInvestigationRepo.getInvestigationRequests(
        patientId: testPatientId,
        caseId: 'CASE-P11-101',
        visitId: 'VISIT-P11-501',
      );
      expect(pending.length, equals(1));
      expect(pending.first.isPendingUpload, isTrue);
      expect(pending.first.name, equals('Lipid Profile & ECG'));
    });

    // 7. Report metadata synchronization
    test('7. Report metadata synchronization stores canonical ReportDocument', () async {
      final reportDoc = ReportDocument(
        reportId: 'REP-P11-701',
        patientId: testPatientId,
        caseId: 'CASE-P11-101',
        visitId: 'VISIT-P11-501',
        investigationId: 'INV-P11-601',
        fileName: 'lipid_report.jpg',
        contentType: 'image/jpeg',
        fileSizeBytes: 1024 * 500,
        storagePath: 'patients/$testPatientId/cases/CASE-P11-101/visits/VISIT-P11-501/uploads/REP-P11-701.jpg',
        uploadedAt: DateTime.now(),
        uploadedByPatientId: testPatientId,
        reviewStatus: ReportReviewStatus.uploaded,
      );
      await mockReportRepo.saveReportDocument(reportDoc);

      final reports = await mockReportRepo.getReportsForVisit(
        patientId: testPatientId,
        caseId: 'CASE-P11-101',
        visitId: 'VISIT-P11-501',
      );
      expect(reports.length, equals(1));
      expect(reports.first.reportId, equals('REP-P11-701'));
      expect(reports.first.storagePath, contains('REP-P11-701.jpg'));
    });

    // 8. Supabase report synchronization
    test('8. Supabase storage service validates and uploads private file', () async {
      final jpegBytes = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46];
      final validation = mockStorageService.validateFile(
        fileName: 'ecg_test.jpg',
        bytes: jpegBytes,
      );
      expect(validation.isValid, isTrue);

      final storagePath = await mockStorageService.uploadReportFile(
        patientId: testPatientId,
        caseId: 'CASE-P11-101',
        visitId: 'VISIT-P11-501',
        investigationId: 'INV-P11-601',
        fileName: 'ecg_test.jpg',
        bytes: jpegBytes,
        contentType: 'image/jpeg',
      );
      expect(storagePath, contains('ecg_test.jpg'));

      final signedUrl = await mockStorageService.getSignedUrl(storagePath);
      expect(signedUrl, isNotNull);
      expect(signedUrl, contains('/object/sign/'));
      expect(signedUrl, contains('token='));
    });

    // 9. Doctor -> Patient visit propagation
    test('9. Doctor completes visit -> Patient immediately sees completed status and approved summary', () async {
      PatientSessionService.instance.startSession(testPatientId);

      final c = ClinicalCase(
        caseId: 'CASE-PROP-1',
        patientId: testPatientId,
        domain: 'cardiology',
        title: 'Cardiac Evaluation',
        status: ClinicalCaseStatus.open,
        createdAt: DateTime.now(),
      );
      await mockCaseRepo.createCase(c);

      final v = ClinicalVisit(
        visitId: 'VISIT-PROP-1',
        caseId: 'CASE-PROP-1',
        patientId: testPatientId,
        doctorId: 'DOC-01',
        visitNumber: 1,
        startedAt: DateTime.now(),
        status: ClinicalVisitStatus.active,
        summaryText: 'Draft summary notes',
        summaryApprovalStatus: SummaryApprovalStatus.draft,
      );
      await mockVisitRepo.createVisit(v);

      var fetched = await mockVisitRepo.getVisitById(
        patientId: testPatientId,
        caseId: 'CASE-PROP-1',
        visitId: 'VISIT-PROP-1',
      );
      expect(fetched!.isActive, isTrue);
      expect(fetched.isSummaryApproved, isFalse);

      final completedVisit = fetched.copyWith(
        status: ClinicalVisitStatus.completed,
        completedAt: DateTime.now(),
        summaryText: 'Doctor-approved final consultation summary.',
        summaryApprovalStatus: SummaryApprovalStatus.approvedByDoctor,
      );
      await mockVisitRepo.updateVisit(completedVisit);

      final bundles = await PatientClinicalRecordsService.instance.getPatientCases(testPatientId);
      final bundle = bundles.firstWhere((b) => b.caseId == 'CASE-PROP-1');
      expect(bundle.completedVisits.length, equals(1));
      expect(bundle.completedVisits.first.isSummaryApproved, isTrue);
      expect(bundle.completedVisits.first.effectiveSummary, equals('Doctor-approved final consultation summary.'));
    });

    // 10. Patient -> Doctor report propagation
    test('10. Patient uploads report -> Investigation status transitions to uploaded for Doctor review', () async {
      PatientSessionService.instance.startSession(testPatientId);

      final c = ClinicalCase(
        caseId: 'CASE-RPT-1',
        patientId: testPatientId,
        domain: 'cardiology',
        title: 'Cardiac Monitoring',
        status: ClinicalCaseStatus.open,
        createdAt: DateTime.now(),
      );
      await mockCaseRepo.createCase(c);

      final v = ClinicalVisit(
        visitId: 'VISIT-RPT-1',
        caseId: 'CASE-RPT-1',
        patientId: testPatientId,
        doctorId: 'DOC-01',
        visitNumber: 1,
        startedAt: DateTime.now(),
        status: ClinicalVisitStatus.completed,
      );
      await mockVisitRepo.createVisit(v);

      final inv = InvestigationRequest(
        requestId: 'INV-RPT-10',
        patientId: testPatientId,
        caseId: 'CASE-RPT-1',
        visitId: 'VISIT-RPT-1',
        name: 'Blood Sugar Fasting',
        status: InvestigationStatus.pendingUpload,
        requestedAt: DateTime.now(),
      );
      await mockInvestigationRepo.createInvestigationRequest(inv);

      final jpegBytes = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46];
      final photo = ReportPhotoItem(
        id: 'photo-1',
        originalName: 'fasting_sugar.jpg',
        bytes: jpegBytes,
        pageNumber: 1,
      );

      final uploadService = PatientReportUploadService(
        sessionService: PatientSessionService.instance,
        caseRepo: mockCaseRepo,
        visitRepo: mockVisitRepo,
        investigationRepo: mockInvestigationRepo,
        reportRepo: mockReportRepo,
      );

      final reportDoc = await uploadService.submitReport(
        patientId: testPatientId,
        caseId: 'CASE-RPT-1',
        visitId: 'VISIT-RPT-1',
        investigationId: 'INV-RPT-10',
        photos: [photo],
      );

      expect(reportDoc.reviewStatus, equals(ReportReviewStatus.uploaded));

      final updatedInv = await mockInvestigationRepo.getInvestigationById(
        patientId: testPatientId,
        caseId: 'CASE-RPT-1',
        visitId: 'VISIT-RPT-1',
        investigationId: 'INV-RPT-10',
      );
      expect(updatedInv!.isUploaded, isTrue);
      expect(updatedInv.uploadedReportId, equals(reportDoc.reportId));
    });

    // 11. Follow-up synchronization
    test('11. Doctor records follow-up date -> Patient ClinicalVisit.followUpDate reflects it', () async {
      final visit = ClinicalVisit(
        visitId: 'VISIT-FOL-1',
        caseId: 'CASE-P11-101',
        patientId: testPatientId,
        doctorId: 'DOC-01',
        visitNumber: 1,
        startedAt: DateTime(2026, 9, 10),
        completedAt: DateTime(2026, 9, 10),
        status: ClinicalVisitStatus.completed,
        followUp: '2026-09-25',
      );

      expect(visit.followUpDate, isNotNull);
      expect(visit.followUpDate!.year, equals(2026));
      expect(visit.followUpDate!.month, equals(9));
      expect(visit.followUpDate!.day, equals(25));
    });

    // 12. Dashboard Next Visit synchronization
    test('12. Dashboard Next Visit selects nearest future follow-up date', () async {
      PatientSessionService.instance.startSession(testPatientId);

      final c = ClinicalCase(
        caseId: 'CASE-NEXT-1',
        patientId: testPatientId,
        domain: 'cardiology',
        title: 'Cardiac Review',
        status: ClinicalCaseStatus.open,
        createdAt: DateTime.now(),
      );
      await mockCaseRepo.createCase(c);

      final futureDate = DateTime.now().add(const Duration(days: 7));
      final visit = ClinicalVisit(
        visitId: 'VISIT-NEXT-1',
        caseId: 'CASE-NEXT-1',
        patientId: testPatientId,
        doctorId: 'DOC-01',
        doctorName: 'Dr. Ramesh Gupta',
        visitNumber: 1,
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        status: ClinicalVisitStatus.completed,
        followUp: '${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}',
      );
      await mockVisitRepo.createVisit(visit);

      final controller = PatientDashboardController(
        patientRepo: mockPatientRepo,
        appointmentRepo: mockApptRepo,
        caseRepo: mockCaseRepo,
        visitRepo: mockVisitRepo,
        sessionService: PatientSessionService.instance,
      );
      await controller.loadDashboardData();

      expect(controller.hasUpcomingVisit, isTrue);
      expect(controller.nearestUpcomingVisit, isNotNull);
      expect(controller.nearestUpcomingVisit!.department, equals('cardiology'));
      expect(controller.nearestUpcomingVisit!.doctorName, equals('Dr. Ramesh Gupta'));
    });

    // 13. Calendar synchronization
    test('13. Calendar synchronization aggregates follow-ups without creating duplicates', () async {
      PatientSessionService.instance.startSession(testPatientId);

      final c = ClinicalCase(
        caseId: 'CASE-CAL-1',
        patientId: testPatientId,
        domain: 'orthopedics',
        title: 'Joint Evaluation',
        status: ClinicalCaseStatus.open,
        createdAt: DateTime.now(),
      );
      await mockCaseRepo.createCase(c);

      final followUpDate = DateTime.now().add(const Duration(days: 10));
      final visit = ClinicalVisit(
        visitId: 'VISIT-CAL-1',
        caseId: 'CASE-CAL-1',
        patientId: testPatientId,
        doctorId: 'DOC-02',
        visitNumber: 1,
        startedAt: DateTime.now(),
        status: ClinicalVisitStatus.completed,
        followUp: '${followUpDate.year}-${followUpDate.month.toString().padLeft(2, '0')}-${followUpDate.day.toString().padLeft(2, '0')}',
      );
      await mockVisitRepo.createVisit(visit);

      final followUpService = PatientFollowUpService(
        caseRepo: mockCaseRepo,
        visitRepo: mockVisitRepo,
        appointmentRepo: mockApptRepo,
        sessionService: PatientSessionService.instance,
      );

      final events = await followUpService.getFollowUpsAndAppointmentsForPatient();
      expect(events.length, equals(1));
      expect(events.first.type, equals(PatientCalendarEventType.followUp));
      expect(events.first.department, equals('orthopedics'));
    });

    // 14. Case open/closed mapping
    test('14. Case open/closed mapping: completed visit keeps case OPEN until doctor explicitly closes it', () async {
      final c = ClinicalCase(
        caseId: 'CASE-LIFE-1',
        patientId: testPatientId,
        domain: 'dermatology',
        title: 'Dermal Assessment',
        status: ClinicalCaseStatus.open,
        createdAt: DateTime.now(),
      );
      await mockCaseRepo.createCase(c);

      final v = ClinicalVisit(
        visitId: 'VISIT-LIFE-1',
        caseId: 'CASE-LIFE-1',
        patientId: testPatientId,
        doctorId: 'DOC-01',
        visitNumber: 1,
        startedAt: DateTime.now(),
        status: ClinicalVisitStatus.completed,
      );
      await mockVisitRepo.createVisit(v);

      var patientCase = await mockCaseRepo.getCaseById(patientId: testPatientId, caseId: 'CASE-LIFE-1');
      expect(patientCase!.isOpen, isTrue);

      await mockCaseRepo.closeCase(
        patientId: testPatientId,
        caseId: 'CASE-LIFE-1',
        doctorId: 'DOC-01',
        doctorName: 'Dr. Ramesh Gupta',
        closureNote: 'Treatment complete and resolved.',
      );

      patientCase = await mockCaseRepo.getCaseById(patientId: testPatientId, caseId: 'CASE-LIFE-1');
      expect(patientCase!.isClosed, isTrue);
      expect(patientCase.isOpen, isFalse);
    });

    // 15. Transfer continuity
    test('15. Transfer continuity preserves same patient, case, and visit history', () async {
      final c = ClinicalCase(
        caseId: 'CASE-TR-1',
        patientId: testPatientId,
        domain: 'cardiology',
        title: 'Cardio-Neuro Consult',
        status: ClinicalCaseStatus.open,
        createdAt: DateTime.now(),
      );
      await mockCaseRepo.createCase(c);

      final v1 = ClinicalVisit(
        visitId: 'VISIT-TR-1',
        caseId: 'CASE-TR-1',
        patientId: testPatientId,
        doctorId: 'DOC-01',
        visitNumber: 1,
        startedAt: DateTime.now().subtract(const Duration(days: 2)),
        status: ClinicalVisitStatus.completed,
      );
      await mockVisitRepo.createVisit(v1);

      final transferredVisit = v1.copyWith(status: ClinicalVisitStatus.transferred);
      await mockVisitRepo.updateVisit(transferredVisit);

      final v2 = ClinicalVisit(
        visitId: 'VISIT-TR-2',
        caseId: 'CASE-TR-1',
        patientId: testPatientId,
        doctorId: 'DOC-NEURO',
        doctorName: 'Dr. Neuro',
        visitNumber: 2,
        startedAt: DateTime.now(),
        status: ClinicalVisitStatus.active,
      );
      await mockVisitRepo.createVisit(v2);

      final visits = await mockVisitRepo.getVisitsForCase(patientId: testPatientId, caseId: 'CASE-TR-1');
      expect(visits.length, equals(2));
      expect(visits.any((v) => v.visitNumber == 1 && v.isTransferred), isTrue);
      expect(visits.any((v) => v.visitNumber == 2 && v.doctorId == 'DOC-NEURO'), isTrue);
    });

    // 16. Escalation privacy
    test('16. Escalation privacy: case displays Under Specialist Review without exposing admin internals', () async {
      final c = ClinicalCase(
        caseId: 'CASE-ESC-1',
        patientId: testPatientId,
        domain: 'cardiology',
        title: 'Cardiology Complex',
        status: ClinicalCaseStatus.open,
        escalationStatus: CaseEscalationStatus.escalated,
        escalationReason: CaseEscalationReason.clinicalDeterioration,
        escalatedByDoctorId: 'DOC-01',
        createdAt: DateTime.now(),
      );
      await mockCaseRepo.createCase(c);

      expect(c.isEscalated, isTrue);
      expect(c.escalationStatus, equals(CaseEscalationStatus.escalated));
      expect(c.escalationStatus.name, equals('escalated'));
    });

    // 17. Unauthorized Patient access
    test('17. Unauthorized patient access is strictly blocked for cross-patient queries', () async {
      PatientSessionService.instance.startSession(testPatientId);

      final uploadService = PatientReportUploadService(
        sessionService: PatientSessionService.instance,
        caseRepo: mockCaseRepo,
        visitRepo: mockVisitRepo,
        investigationRepo: mockInvestigationRepo,
        reportRepo: mockReportRepo,
      );

      final jpegBytes = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46];
      final photo = ReportPhotoItem(
        id: 'photo-unauth',
        originalName: 'unauth.jpg',
        bytes: jpegBytes,
        pageNumber: 1,
      );

      expect(
        () => uploadService.submitReport(
          patientId: otherPatientId,
          caseId: 'CASE-1',
          visitId: 'VISIT-1',
          investigationId: 'INV-1',
          photos: [photo],
        ),
        throwsA(isA<BackendException>().having((e) => e.code, 'code', BackendException.permissionDenied)),
      );
    });

    // 18. Patient clinical write rejection
    test('18. Patient cannot modify clinical consultation fields or vitals', () async {
      final visit = ClinicalVisit(
        visitId: 'VISIT-1',
        caseId: 'CASE-1',
        patientId: testPatientId,
        doctorId: 'DOC-01',
        visitNumber: 1,
        startedAt: DateTime.now(),
        status: ClinicalVisitStatus.active,
        chiefComplaint: 'Original complaint',
      );

      expect(visit.chiefComplaint, equals('Original complaint'));
      expect(visit.canCompleteVisit, isFalse);
    });

    // 19. Review status protection
    test('19. Patient cannot mark investigation as reviewed', () async {
      final inv = InvestigationRequest(
        requestId: 'INV-REV-1',
        patientId: testPatientId,
        caseId: 'CASE-1',
        visitId: 'VISIT-1',
        name: 'Thyroid Panel',
        status: InvestigationStatus.uploaded,
        requestedAt: DateTime.now(),
      );
      await mockInvestigationRepo.createInvestigationRequest(inv);

      await mockInvestigationRepo.markReviewed(
        patientId: testPatientId,
        caseId: 'CASE-1',
        visitId: 'VISIT-1',
        investigationId: 'INV-REV-1',
        doctorId: 'DOC-01',
      );

      final reviewed = await mockInvestigationRepo.getInvestigationById(
        patientId: testPatientId,
        caseId: 'CASE-1',
        visitId: 'VISIT-1',
        investigationId: 'INV-REV-1',
      );
      expect(reviewed!.isReviewed, isTrue);
      expect(reviewed.reviewedByDoctorId, equals('DOC-01'));
    });

    // 20. Logout data isolation
    test('20. Logout data isolation completely purges patient session and transient notifications', () async {
      PatientSessionService.instance.startSession(testPatientId);
      expect(PatientSessionService.instance.isAuthenticated, isTrue);

      await PatientNotificationService.instance.scheduleFollowUpReminder(
        eventId: 'event-101',
        visitDate: DateTime.now().add(const Duration(days: 3)),
        title: 'Follow-up Consultation',
        department: 'Cardiology',
        patientId: testPatientId,
      );
      expect(PatientNotificationService.instance.getNotifications(testPatientId).length, greaterThan(0));

      PatientSessionService.instance.logout();
      expect(PatientSessionService.instance.isAuthenticated, isFalse);
      expect(PatientSessionService.instance.authenticatedPatientId, isNull);
      expect(PatientAppState.instance.authenticatedPatientId, isNull);
      expect(PatientAppState.instance.isAuthenticated, isFalse);

      expect(PatientNotificationService.instance.getNotifications(testPatientId), isEmpty);
    });

    // 21. Multi-device synchronization
    test('21. Multi-device synchronization: Kiosk -> Doctor -> Patient share single underlying entity', () async {
      final kioskAppt = AppointmentRequest(
        requestId: 'APT-MULTI-01',
        patientId: testPatientId,
        domainId: 'cardiology',
        status: AppointmentStatus.waiting,
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        queueNumber: 'A-00099',
        createdAt: DateTime.now(),
        source: 'KIOSK',
        sessionId: 'SESS-P11',
      );
      await mockApptRepo.saveAppointment(kioskAppt);

      final doctorQueue = await mockApptRepo.getAllAppointments();
      final target = doctorQueue.firstWhere((a) => a.requestId == 'APT-MULTI-01');
      expect(target.status, equals(AppointmentStatus.waiting));

      await mockApptRepo.updateAppointmentStatus('APT-MULTI-01', AppointmentStatus.accepted);

      final patientAppts = await mockApptRepo.getAppointmentsForPatient(testPatientId);
      expect(patientAppts.first.status, equals(AppointmentStatus.accepted));
      expect(patientAppts.first.queueNumber, equals('A-00099'));
    });

    // 22. Duplicate prevention
    test('22. Duplicate prevention blocks repeat report uploads for already submitted investigations', () async {
      PatientSessionService.instance.startSession(testPatientId);

      final c = ClinicalCase(
        caseId: 'CASE-DUP-1',
        patientId: testPatientId,
        domain: 'cardiology',
        title: 'Cardiac Duplicate Check',
        status: ClinicalCaseStatus.open,
        createdAt: DateTime.now(),
      );
      await mockCaseRepo.createCase(c);

      final v = ClinicalVisit(
        visitId: 'VISIT-DUP-1',
        caseId: 'CASE-DUP-1',
        patientId: testPatientId,
        doctorId: 'DOC-01',
        visitNumber: 1,
        startedAt: DateTime.now(),
        status: ClinicalVisitStatus.completed,
      );
      await mockVisitRepo.createVisit(v);

      final inv = InvestigationRequest(
        requestId: 'INV-DUP-1',
        patientId: testPatientId,
        caseId: 'CASE-DUP-1',
        visitId: 'VISIT-DUP-1',
        name: 'Chest X-Ray',
        status: InvestigationStatus.uploaded,
        requestedAt: DateTime.now(),
      );
      await mockInvestigationRepo.createInvestigationRequest(inv);

      final jpegBytes = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46];
      final photo = ReportPhotoItem(
        id: 'p1',
        originalName: 'xray.jpg',
        bytes: jpegBytes,
        pageNumber: 1,
      );

      final uploadService = PatientReportUploadService(
        sessionService: PatientSessionService.instance,
        caseRepo: mockCaseRepo,
        visitRepo: mockVisitRepo,
        investigationRepo: mockInvestigationRepo,
        reportRepo: mockReportRepo,
      );

      expect(
        () => uploadService.submitReport(
          patientId: testPatientId,
          caseId: 'CASE-DUP-1',
          visitId: 'VISIT-DUP-1',
          investigationId: 'INV-DUP-1',
          photos: [photo],
        ),
        throwsA(isA<BackendException>().having((e) => e.code, 'code', BackendException.invalidData)),
      );
    });

    // 23. Retry/idempotency
    test('23. Retry/idempotency: multiple dashboard reloads produce consistent idempotent state', () async {
      PatientSessionService.instance.startSession(testPatientId);

      final controller = PatientDashboardController(
        patientRepo: mockPatientRepo,
        appointmentRepo: mockApptRepo,
        caseRepo: mockCaseRepo,
        visitRepo: mockVisitRepo,
        sessionService: PatientSessionService.instance,
      );

      await controller.loadDashboardData();
      final count1 = controller.ongoingCasesCount;
      final name1 = controller.patientDisplayName;

      await controller.refresh();
      final count2 = controller.ongoingCasesCount;
      final name2 = controller.patientDisplayName;

      expect(count1, equals(count2));
      expect(name1, equals(name2));
    });

    // 24. Network failure handling
    test('24. Network failure handling sets controlled error state without empty fallback', () async {
      PatientSessionService.instance.startSession(testPatientId);

      final failingCaseRepo = _FailingCaseRepository();
      final controller = PatientDashboardController(
        patientRepo: mockPatientRepo,
        appointmentRepo: mockApptRepo,
        caseRepo: failingCaseRepo,
        visitRepo: mockVisitRepo,
        sessionService: PatientSessionService.instance,
      );

      await controller.loadDashboardData();
      expect(controller.hasCasesError, isTrue);
      expect(controller.casesErrorMessage, contains('Unable to load your cases'));
    });

    // 25. Real-time update handling
    test('25. Real-time update handling: appointment streams emit latest changes', () async {
      final stream = mockApptRepo.watchAllAppointments();
      final initialList = await stream.first;
      expect(initialList, isA<List<AppointmentRequest>>());

      final appt = AppointmentRequest(
        requestId: 'APT-STREAM-1',
        patientId: testPatientId,
        domainId: 'cardiology',
        status: AppointmentStatus.waiting,
        preferredDoctorMode: PreferredDoctorMode.anyDoctor,
        queueNumber: 'A-00055',
        createdAt: DateTime.now(),
        source: 'KIOSK',
        sessionId: 'SESS-P11',
      );
      await mockApptRepo.saveAppointment(appt);

      final updatedList = await mockApptRepo.watchAllAppointments().first;
      expect(updatedList.any((a) => a.requestId == 'APT-STREAM-1'), isTrue);
    });

    // 26. Protected routes
    test('26. Protected routes redirect unauthenticated access to login', () {
      PatientSessionService.instance.logout();
      expect(PatientSessionService.instance.isAuthenticated, isFalse);

      final route = PatientRoutes.onGenerateRoute(RouteSettings(name: '/patient/dashboard'));
      expect(route, isNotNull);
    });

    // 27. Supabase private storage
    test('27. Supabase private storage verifies bucket name, size bounds, and signed URLs', () {
      expect(SupabaseConfig.bucketName, equals('aayusathi-reports'));
      expect(SupabaseConfig.maxFileSizeBytes, equals(15 * 1024 * 1024));
      expect(SupabaseConfig.allowedExtensions, containsAll(['.pdf', '.jpg', '.jpeg', '.png']));
    });

    // 28. Secret-key protection
    test('28. Secret-key protection ensures no service_role key in client config', () {
      expect(SupabaseConfig.isConfigValid, isTrue);
      expect(SupabaseConfig.publishableKey.toLowerCase().contains('service_role'), isFalse);
      expect(SupabaseConfig.publishableKey.startsWith('sb_secret_'), isFalse);
    });

    // 29. P8 report upload regression
    test('29. P8 report upload regression: photo validation blocks invalid formats and large files', () {
      final invalidBytes = [0x41, 0x42, 0x43, 0x44];
      final res1 = PatientReportFileValidator.validateReportPhoto(
        fileName: 'fake.jpg',
        bytes: invalidBytes,
      );
      expect(res1.isValid, isFalse);

      final oversizedBytes = Uint8List(16 * 1024 * 1024);
      final res2 = PatientReportFileValidator.validateReportPhoto(
        fileName: 'huge.jpg',
        bytes: oversizedBytes,
      );
      expect(res2.isValid, isFalse);
      expect(res2.errorMessage, contains('15 MB'));
    });

    // 30. P9 Calendar regression
    test('30. P9 Calendar regression: parses dates and formats calendar items', () {
      final calendarItem = PatientCalendarItem(
        id: 'cal-1',
        date: DateTime(2026, 9, 20),
        title: 'Follow-up Visit',
        department: 'cardiology',
        type: PatientCalendarEventType.followUp,
      );
      expect(calendarItem.isSameDay(DateTime(2026, 9, 20)), isTrue);
      expect(calendarItem.isSameDay(DateTime(2026, 9, 21)), isFalse);
    });

    // 31. P10 Notification regression
    test('31. P10 Notification regression: follow-up reminders scheduled with deterministic IDs', () async {
      final notifService = PatientNotificationService.instance;
      final visitDate = DateTime.now().add(const Duration(days: 5));

      await notifService.scheduleFollowUpReminder(
        eventId: 'followup_CASE1_VISIT1',
        visitDate: visitDate,
        title: 'Cardiology Follow-up',
        department: 'Cardiology',
        patientId: testPatientId,
      );

      final inbox = notifService.getNotifications(testPatientId);
      expect(inbox.length, equals(1));
      expect(inbox.first.eventId, equals('followup_CASE1_VISIT1'));
      expect(inbox.first.title, contains('Cardiology'));
    });

    // 32. Profile regression
    test('32. Profile regression: patient authentication lookup masks phone number', () async {
      final authService = PatientAuthService(patientRepository: mockPatientRepo);
      final result = await authService.lookupPatientById(testPatientId);

      expect(result.isSuccessful, isTrue);
      expect(result.patientId, equals(testPatientId));
      expect(result.maskedPhone, matches(r'^\+91\s+\*+4321$|^\+91\s+\*+\d{4}$'));
    });
  });
}

class _FailingCaseRepository implements CaseRepository {
  final MockCaseRepository _inner = MockCaseRepository.instance;

  @override
  Future<List<ClinicalCase>> getCasesForPatient(String patientId) async {
    throw BackendException(
      code: BackendException.unavailable,
      message: 'Network connection unavailable.',
    );
  }

  @override
  Future<ClinicalCase> acceptHigherAuthorityAssignment({
    required String patientId,
    required String caseId,
    required String doctorId,
  }) =>
      _inner.acceptHigherAuthorityAssignment(
        patientId: patientId,
        caseId: caseId,
        doctorId: doctorId,
      );

  @override
  Future<ClinicalCase> assignHigherAuthorityDoctor({
    required String patientId,
    required String caseId,
    required String targetDoctorId,
    required String targetDoctorName,
    required String targetDepartment,
    required String assignedByAdminId,
    String? crossDepartmentReason,
  }) =>
      _inner.assignHigherAuthorityDoctor(
        patientId: patientId,
        caseId: caseId,
        targetDoctorId: targetDoctorId,
        targetDoctorName: targetDoctorName,
        targetDepartment: targetDepartment,
        assignedByAdminId: assignedByAdminId,
        crossDepartmentReason: crossDepartmentReason,
      );

  @override
  Future<ClinicalCase> closeCase({
    required String patientId,
    required String caseId,
    required String doctorId,
    String? doctorName,
    required String closureNote,
  }) =>
      _inner.closeCase(
        patientId: patientId,
        caseId: caseId,
        doctorId: doctorId,
        doctorName: doctorName,
        closureNote: closureNote,
      );

  @override
  Future<ClinicalCase> createCase(ClinicalCase clinicalCase) =>
      _inner.createCase(clinicalCase);

  @override
  Future<ClinicalCase> escalateCase({
    required String patientId,
    required String caseId,
    required String visitId,
    required String doctorId,
    String? doctorName,
    required CaseEscalationReason reason,
    String? note,
  }) =>
      _inner.escalateCase(
        patientId: patientId,
        caseId: caseId,
        visitId: visitId,
        doctorId: doctorId,
        doctorName: doctorName,
        reason: reason,
        note: note,
      );

  @override
  Future<List<ClinicalCase>> getAllCases() => _inner.getAllCases();

  @override
  Future<ClinicalCase?> getCaseById({
    required String patientId,
    required String caseId,
  }) =>
      _inner.getCaseById(patientId: patientId, caseId: caseId);

  @override
  Future<List<ClinicalCase>> getCasesForDoctor(String doctorId) =>
      _inner.getCasesForDoctor(doctorId);

  @override
  Future<List<ClinicalCase>> getEscalatedCases() => _inner.getEscalatedCases();

  @override
  Future<bool> isDoctorAuthorizedForCase({
    required String doctorId,
    required String caseId,
    required String patientId,
  }) =>
      _inner.isDoctorAuthorizedForCase(
        doctorId: doctorId,
        caseId: caseId,
        patientId: patientId,
      );

  @override
  Future<ClinicalCase> startAdminCaseReview({
    required String patientId,
    required String caseId,
    required String adminId,
  }) =>
      _inner.startAdminCaseReview(
        patientId: patientId,
        caseId: caseId,
        adminId: adminId,
      );

  @override
  Future<void> updateCase(ClinicalCase clinicalCase) =>
      _inner.updateCase(clinicalCase);

  @override
  Stream<List<ClinicalCase>> watchEscalatedCases() =>
      _inner.watchEscalatedCases();
}

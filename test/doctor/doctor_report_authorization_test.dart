import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/doctor/models/clinical_visit.dart';
import 'package:aayusathi/doctor/models/doctor_profile.dart';
import 'package:aayusathi/doctor/models/report_document.dart';
import 'package:aayusathi/doctor/services/doctor_ai_report_summarization_service.dart';
import 'package:aayusathi/doctor/services/doctor_report_authorization_service.dart';
import 'package:aayusathi/doctor/services/doctor_session_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_session_service.dart';
import 'package:aayusathi/doctor/services/mock_storage_service.dart';
import 'package:aayusathi/doctor/widgets/doctor_buttons.dart';
import 'package:aayusathi/doctor/widgets/doctor_report_viewer_dialog.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_report_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCaseRepository caseRepo;
  late MockClinicalVisitRepository visitRepo;
  late MockReportRepository reportRepo;
  late MockStorageService storageService;
  late MockDoctorSessionService sessionService;

  // Minimal valid PDF binary (%PDF...)
  final samplePdfBytes = Uint8List.fromList([
    0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34, 0x0A, 0x25, 0xD0, 0xD4,
    0xC5, 0xD8, 0x0A, 0x31, 0x20, 0x30, 0x20, 0x6F, 0x62, 0x6A, 0x0A, 0x3C,
    0x3C, 0x2F, 0x54, 0x79, 0x70, 0x65, 0x2F, 0x43, 0x61, 0x74, 0x61, 0x6C,
    0x6F, 0x67, 0x2F, 0x50, 0x61, 0x67, 0x65, 0x73, 0x20, 0x32, 0x20, 0x30,
    0x20, 0x52, 0x3E, 0x3E, 0x0A, 0x65, 0x6E, 0x64, 0x6F, 0x62, 0x6A, 0x0A,
    0x32, 0x20, 0x30, 0x20, 0x6F, 0x62, 0x6A, 0x0A, 0x3C, 0x3C, 0x2F, 0x54,
    0x79, 0x70, 0x65, 0x2F, 0x50, 0x61, 0x67, 0x65, 0x73, 0x2F, 0x4B, 0x69,
    0x64, 0x73, 0x5B, 0x33, 0x20, 0x30, 0x20, 0x52, 0x5D, 0x2F, 0x43, 0x6F,
    0x75, 0x6E, 0x74, 0x20, 0x31, 0x3E, 0x3E, 0x0A, 0x65, 0x6E, 0x64, 0x6F,
    0x62, 0x6A, 0x0A, 0x33, 0x20, 0x30, 0x20, 0x6F, 0x62, 0x6A, 0x0A, 0x3C,
    0x3C, 0x2F, 0x54, 0x79, 0x70, 0x65, 0x2F, 0x50, 0x61, 0x67, 0x65, 0x2F,
    0x50, 0x61, 0x72, 0x65, 0x6E, 0x74, 0x20, 0x32, 0x20, 0x30, 0x20, 0x52,
    0x2F, 0x4D, 0x65, 0x64, 0x69, 0x61, 0x42, 0x6F, 0x78, 0x5B, 0x30, 0x20,
    0x30, 0x20, 0x33, 0x30, 0x30, 0x20, 0x33, 0x30, 0x30, 0x5D, 0x3E, 0x3E,
    0x0A, 0x65, 0x6E, 0x64, 0x6F, 0x62, 0x6A, 0x0A, 0x78, 0x72, 0x65, 0x66,
    0x0A, 0x30, 0x20, 0x34, 0x0A, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30,
    0x30, 0x30, 0x30, 0x20, 0x36, 0x35, 0x35, 0x33, 0x35, 0x20, 0x66, 0x0D,
    0x0A, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x31, 0x35, 0x20,
    0x30, 0x30, 0x30, 0x30, 0x30, 0x20, 0x6E, 0x0D, 0x0A, 0x30, 0x30, 0x30,
    0x30, 0x30, 0x30, 0x30, 0x30, 0x36, 0x38, 0x20, 0x30, 0x30, 0x30, 0x30,
    0x30, 0x20, 0x6E, 0x0D, 0x0A, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30,
    0x31, 0x32, 0x35, 0x20, 0x30, 0x30, 0x30, 0x30, 0x30, 0x20, 0x6E, 0x0D,
    0x0A, 0x74, 0x72, 0x61, 0x69, 0x6C, 0x65, 0x72, 0x0A, 0x3C, 0x3C, 0x2F,
    0x53, 0x69, 0x7A, 0x65, 0x20, 0x34, 0x2F, 0x52, 0x6F, 0x6F, 0x74, 0x20,
    0x31, 0x20, 0x30, 0x20, 0x52, 0x3E, 0x3E, 0x0A, 0x73, 0x74, 0x61, 0x72,
    0x74, 0x78, 0x72, 0x65, 0x66, 0x0A, 0x32, 0x30, 0x35, 0x0A, 0x25, 0x25,
    0x45, 0x4F, 0x46, 0x0A
  ]);

  const patientA = 'PAT-TEST-001';
  const patientB = 'PAT-TEST-002';
  const caseIdA = 'CASE-CARDIO-001';
  const visitIdA1 = 'VIS-CARDIO-001-1';
  const visitIdA2 = 'VIS-CARDIO-001-2';

  const treatingDoctorId = 'DOC-TREATING-101';
  const completingDoctorId = 'DOC-COMPLETING-102';
  const approvedDoctorId = 'DOC-APPROVER-103';
  const uninvolvedDoctorId = 'DOC-UNINVOLVED-999';

  final treatingDoctorProfile = DoctorProfile(
    doctorId: treatingDoctorId,
    doctorUniqueCode: treatingDoctorId,
    name: 'Dr. Treating Physician',
    qualification: 'MD Cardiology',
    department: 'cardiology',
    registeredPhone: '+919876543201',
    email: 'treating@aayusathi.in',
    isActive: true,
    authUid: 'auth-treating-101',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );

  final completingDoctorProfile = DoctorProfile(
    doctorId: completingDoctorId,
    doctorUniqueCode: completingDoctorId,
    name: 'Dr. Completing Physician',
    qualification: 'MD Internal Medicine',
    department: 'general_medicine',
    registeredPhone: '+919876543202',
    email: 'completing@aayusathi.in',
    isActive: true,
    authUid: 'auth-completing-102',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );

  final uninvolvedDoctorProfile = DoctorProfile(
    doctorId: uninvolvedDoctorId,
    doctorUniqueCode: uninvolvedDoctorId,
    name: 'Dr. Uninvolved Physician',
    qualification: 'MS Orthopedics',
    department: 'orthopedics',
    registeredPhone: '+919876543299',
    email: 'uninvolved@aayusathi.in',
    isActive: true,
    authUid: 'auth-uninvolved-999',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );

  setUp(() async {
    BackendProvider.instance.setMode(BackendMode.mock);
    BackendProvider.instance.resetOverrides();

    caseRepo = MockCaseRepository.instance;
    visitRepo = MockClinicalVisitRepository.instance;
    reportRepo = MockReportRepository.instance..clearAll();
    storageService = MockStorageService.instance..reset();

    sessionService = MockDoctorSessionService();
    DoctorSessionService.instance = sessionService;

    // Seed Clinical Case
    await caseRepo.createCase(
      ClinicalCase(
        caseId: caseIdA,
        patientId: patientA,
        domain: 'cardiology',
        title: 'Hypertensive Heart Disease',
        status: ClinicalCaseStatus.open,
        createdAt: DateTime(2026, 9, 1),
      ),
    );

    // Seed Visit 1 (Completed by completingDoctorId, attended by treatingDoctorId)
    await visitRepo.createVisit(
      ClinicalVisit(
        visitId: visitIdA1,
        caseId: caseIdA,
        patientId: patientA,
        doctorId: treatingDoctorId,
        doctorName: 'Dr. Treating Physician',
        visitNumber: 1,
        startedAt: DateTime(2026, 9, 1, 10, 0),
        completedAt: DateTime(2026, 9, 1, 10, 45),
        completedByDoctorId: completingDoctorId,
        summaryApprovalStatus: SummaryApprovalStatus.approvedByDoctor,
        approvedByDoctorId: approvedDoctorId,
        status: ClinicalVisitStatus.completed,
      ),
    );

    // Seed Visit 2 (Active, attended by treatingDoctorId)
    await visitRepo.createVisit(
      ClinicalVisit(
        visitId: visitIdA2,
        caseId: caseIdA,
        patientId: patientA,
        doctorId: treatingDoctorId,
        doctorName: 'Dr. Treating Physician',
        visitNumber: 2,
        startedAt: DateTime(2026, 9, 15, 11, 0),
        status: ClinicalVisitStatus.active,
      ),
    );
  });

  Widget buildTestHost(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('AAYUSATHI Doctor Report Authorization Unit Tests', () {
    test('1. Unauthenticated or inactive doctor receives DOCTOR_PROFILE_NOT_FOUND', () async {
      final report = ReportDocument(
        reportId: 'REP-001',
        patientId: patientA,
        caseId: caseIdA,
        visitId: visitIdA1,
        investigationId: 'INV-001',
        fileName: 'Blood_Test.pdf',
        contentType: 'application/pdf',
        fileSizeBytes: 1024,
        storagePath: 'patients/$patientA/cases/$caseIdA/visits/$visitIdA1/reports/INV-001/Blood_Test.pdf',
        uploadedAt: DateTime.now(),
        uploadedByPatientId: patientA,
      );

      final result = await DoctorReportAuthorizationService.instance.verifyReportAccess(
        report: report,
      );

      expect(result.isAuthorized, isFalse);
      expect(result.outcome, DoctorReportAuthOutcome.doctorProfileNotFound);
      expect(result.diagnosticOutcome, 'DOCTOR_PROFILE_NOT_FOUND');
    });

    test('2. Different patient report receives REPORT_PATIENT_MISMATCH', () async {
      sessionService.registerProfile(treatingDoctorProfile);
      await sessionService.enterDevelopmentWorkspace(profile: treatingDoctorProfile);

      final reportOtherPatient = ReportDocument(
        reportId: 'REP-OTHER',
        patientId: patientB,
        caseId: caseIdA,
        visitId: visitIdA1,
        investigationId: 'INV-001',
        fileName: 'Other_Report.pdf',
        contentType: 'application/pdf',
        fileSizeBytes: 1024,
        storagePath: 'patients/$patientB/cases/$caseIdA/visits/$visitIdA1/reports/INV-001/Other_Report.pdf',
        uploadedAt: DateTime.now(),
        uploadedByPatientId: patientB,
      );

      // A: mismatched against expected patientId
      final result1 = await DoctorReportAuthorizationService.instance.verifyReportAccess(
        report: reportOtherPatient,
        expectedPatientId: patientA,
      );
      expect(result1.isAuthorized, isFalse);
      expect(result1.outcome, DoctorReportAuthOutcome.reportPatientMismatch);
      expect(result1.diagnosticOutcome, 'REPORT_PATIENT_MISMATCH');

      // B: mismatched against clinical case patientId
      final result2 = await DoctorReportAuthorizationService.instance.verifyReportAccess(
        report: reportOtherPatient,
      );
      expect(result2.isAuthorized, isFalse);
      expect(result2.outcome, DoctorReportAuthOutcome.reportPatientMismatch);
    });

    test('3. Mismatched case ID receives REPORT_CASE_MISMATCH', () async {
      sessionService.registerProfile(treatingDoctorProfile);
      await sessionService.enterDevelopmentWorkspace(profile: treatingDoctorProfile);

      final reportWrongCase = ReportDocument(
        reportId: 'REP-WRONG-CASE',
        patientId: patientA,
        caseId: 'CASE-NONEXISTENT',
        visitId: visitIdA1,
        investigationId: 'INV-001',
        fileName: 'Report.pdf',
        contentType: 'application/pdf',
        fileSizeBytes: 1024,
        storagePath: 'patients/$patientA/cases/CASE-NONEXISTENT/visits/$visitIdA1/reports/INV-001/Report.pdf',
        uploadedAt: DateTime.now(),
        uploadedByPatientId: patientA,
      );

      final result = await DoctorReportAuthorizationService.instance.verifyReportAccess(
        report: reportWrongCase,
        expectedCaseId: caseIdA,
      );
      expect(result.isAuthorized, isFalse);
      expect(result.outcome, DoctorReportAuthOutcome.reportCaseMismatch);
      expect(result.diagnosticOutcome, 'REPORT_CASE_MISMATCH');
    });

    test('4. Mismatched visit ID receives REPORT_VISIT_MISMATCH', () async {
      sessionService.registerProfile(treatingDoctorProfile);
      await sessionService.enterDevelopmentWorkspace(profile: treatingDoctorProfile);

      final reportWrongVisit = ReportDocument(
        reportId: 'REP-WRONG-VISIT',
        patientId: patientA,
        caseId: caseIdA,
        visitId: 'VIS-NONEXISTENT',
        investigationId: 'INV-001',
        fileName: 'Report.pdf',
        contentType: 'application/pdf',
        fileSizeBytes: 1024,
        storagePath: 'patients/$patientA/cases/$caseIdA/visits/VIS-NONEXISTENT/reports/INV-001/Report.pdf',
        uploadedAt: DateTime.now(),
        uploadedByPatientId: patientA,
      );

      final result = await DoctorReportAuthorizationService.instance.verifyReportAccess(
        report: reportWrongVisit,
        expectedVisitId: visitIdA1,
      );
      expect(result.isAuthorized, isFalse);
      expect(result.outcome, DoctorReportAuthOutcome.reportVisitMismatch);
      expect(result.diagnosticOutcome, 'REPORT_VISIT_MISMATCH');
    });

    test('5. Uninvolved doctor receives DOCTOR_NOT_CLINICALLY_INVOLVED', () async {
      sessionService.registerProfile(uninvolvedDoctorProfile);
      await sessionService.enterDevelopmentWorkspace(profile: uninvolvedDoctorProfile);

      final report = ReportDocument(
        reportId: 'REP-001',
        patientId: patientA,
        caseId: caseIdA,
        visitId: visitIdA1,
        investigationId: 'INV-001',
        fileName: 'Blood_Test.pdf',
        contentType: 'application/pdf',
        fileSizeBytes: 1024,
        storagePath: 'patients/$patientA/cases/$caseIdA/visits/$visitIdA1/reports/INV-001/Blood_Test.pdf',
        uploadedAt: DateTime.now(),
        uploadedByPatientId: patientA,
      );

      final result = await DoctorReportAuthorizationService.instance.verifyReportAccess(
        report: report,
      );
      expect(result.isAuthorized, isFalse);
      expect(result.outcome, DoctorReportAuthOutcome.doctorNotClinicallyInvolved);
      expect(result.diagnosticOutcome, 'DOCTOR_NOT_CLINICALLY_INVOLVED');
    });

    test('6. Treating doctor is authorized (attending doctor on visit)', () async {
      sessionService.registerProfile(treatingDoctorProfile);
      await sessionService.enterDevelopmentWorkspace(profile: treatingDoctorProfile);

      final report = ReportDocument(
        reportId: 'REP-001',
        patientId: patientA,
        caseId: caseIdA,
        visitId: visitIdA1,
        investigationId: 'INV-001',
        fileName: 'Blood_Test.pdf',
        contentType: 'application/pdf',
        fileSizeBytes: 1024,
        storagePath: 'patients/$patientA/cases/$caseIdA/visits/$visitIdA1/reports/INV-001/Blood_Test.pdf',
        uploadedAt: DateTime.now(),
        uploadedByPatientId: patientA,
      );

      final result = await DoctorReportAuthorizationService.instance.verifyReportAccess(
        report: report,
        expectedPatientId: patientA,
        expectedCaseId: caseIdA,
        expectedVisitId: visitIdA1,
      );
      expect(result.isAuthorized, isTrue);
      expect(result.outcome, DoctorReportAuthOutcome.reportOpenSuccess);
    });

    test('7. Doctor with verified historical clinical involvement is authorized for completed visit', () async {
      // Testing completing doctor
      sessionService.registerProfile(completingDoctorProfile);
      await sessionService.enterDevelopmentWorkspace(profile: completingDoctorProfile);

      final report = ReportDocument(
        reportId: 'REP-COMPLETED',
        patientId: patientA,
        caseId: caseIdA,
        visitId: visitIdA1, // Visit 1 is status == completed
        investigationId: 'INV-001',
        fileName: 'Histopathology.pdf',
        contentType: 'application/pdf',
        fileSizeBytes: 1024,
        storagePath: 'patients/$patientA/cases/$caseIdA/visits/$visitIdA1/reports/INV-001/Histopathology.pdf',
        uploadedAt: DateTime.now(),
        uploadedByPatientId: patientA,
      );

      final result = await DoctorReportAuthorizationService.instance.verifyReportAccess(
        report: report,
      );
      expect(result.isAuthorized, isTrue);
      expect(result.outcome, DoctorReportAuthOutcome.reportOpenSuccess);
    });
  });

  group('AAYUSATHI Doctor Report Viewer Widget Tests', () {
    testWidgets('1. Treating doctor can view uploaded report and renders PDF', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      sessionService.registerProfile(treatingDoctorProfile);
      await sessionService.enterDevelopmentWorkspace(profile: treatingDoctorProfile);

      final storagePath = await storageService.uploadReportFile(
        patientId: patientA,
        caseId: caseIdA,
        visitId: visitIdA1,
        investigationId: 'INV-001',
        fileName: 'Complete_Blood_Count.pdf',
        bytes: samplePdfBytes,
        contentType: 'application/pdf',
      );

      final reportDoc = ReportDocument(
        reportId: 'REP-CBC-001',
        patientId: patientA,
        caseId: caseIdA,
        visitId: visitIdA1,
        investigationId: 'INV-001',
        fileName: 'Complete_Blood_Count.pdf',
        contentType: 'application/pdf',
        fileSizeBytes: samplePdfBytes.length,
        storagePath: storagePath,
        uploadedAt: DateTime.now(),
        uploadedByPatientId: patientA,
      );
      await reportRepo.saveReportDocument(reportDoc);

      await tester.pumpWidget(
        buildTestHost(
          DoctorReportViewerDialog(
            reportDoc: reportDoc,
            currentPatientId: patientA,
            currentCaseId: caseIdA,
            currentVisitId: visitIdA1,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verified: No unauthorized banner is shown
      expect(
        find.text('You are not authorized to view reports for this patient visit.'),
        findsNothing,
      );

      // Verified: PDF render and document title are shown
      expect(find.text('Complete_Blood_Count.pdf'), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf_rounded), findsOneWidget);
    });

    testWidgets('2. Doctor with historical involvement can view report of completed visit', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      sessionService.registerProfile(completingDoctorProfile);
      await sessionService.enterDevelopmentWorkspace(profile: completingDoctorProfile);

      final storagePath = await storageService.uploadReportFile(
        patientId: patientA,
        caseId: caseIdA,
        visitId: visitIdA1,
        investigationId: 'INV-001',
        fileName: 'Biopsy_Report.pdf',
        bytes: samplePdfBytes,
        contentType: 'application/pdf',
      );

      final reportDoc = ReportDocument(
        reportId: 'REP-BIO-001',
        patientId: patientA,
        caseId: caseIdA,
        visitId: visitIdA1,
        investigationId: 'INV-001',
        fileName: 'Biopsy_Report.pdf',
        contentType: 'application/pdf',
        fileSizeBytes: samplePdfBytes.length,
        storagePath: storagePath,
        uploadedAt: DateTime.now(),
        uploadedByPatientId: patientA,
      );
      await reportRepo.saveReportDocument(reportDoc);

      await tester.pumpWidget(
        buildTestHost(
          DoctorReportViewerDialog(
            reportDoc: reportDoc,
            currentPatientId: patientA,
            currentCaseId: caseIdA,
            currentVisitId: visitIdA1,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('You are not authorized to view reports for this patient visit.'),
        findsNothing,
      );
      expect(find.text('Biopsy_Report.pdf'), findsOneWidget);
    });

    testWidgets('3. Uninvolved doctor is blocked with authorization-denied message', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      sessionService.registerProfile(uninvolvedDoctorProfile);
      await sessionService.enterDevelopmentWorkspace(profile: uninvolvedDoctorProfile);

      final reportDoc = ReportDocument(
        reportId: 'REP-CBC-001',
        patientId: patientA,
        caseId: caseIdA,
        visitId: visitIdA1,
        investigationId: 'INV-001',
        fileName: 'Complete_Blood_Count.pdf',
        contentType: 'application/pdf',
        fileSizeBytes: samplePdfBytes.length,
        storagePath: 'patients/$patientA/cases/$caseIdA/visits/$visitIdA1/reports/INV-001/Complete_Blood_Count.pdf',
        uploadedAt: DateTime.now(),
        uploadedByPatientId: patientA,
      );

      await tester.pumpWidget(
        buildTestHost(
          DoctorReportViewerDialog(
            reportDoc: reportDoc,
            currentPatientId: patientA,
            currentCaseId: caseIdA,
            currentVisitId: visitIdA1,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verified: Displays exact expected unauthorized message
      expect(
        find.text('You are not authorized to view reports for this patient visit.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    });

    testWidgets('4. Different patient report is denied access', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      sessionService.registerProfile(treatingDoctorProfile);
      await sessionService.enterDevelopmentWorkspace(profile: treatingDoctorProfile);

      final reportDoc = ReportDocument(
        reportId: 'REP-DIFF-PAT',
        patientId: patientB,
        caseId: caseIdA,
        visitId: visitIdA1,
        investigationId: 'INV-001',
        fileName: 'Different_Patient.pdf',
        contentType: 'application/pdf',
        fileSizeBytes: samplePdfBytes.length,
        storagePath: 'patients/$patientB/cases/$caseIdA/visits/$visitIdA1/reports/INV-001/Different_Patient.pdf',
        uploadedAt: DateTime.now(),
        uploadedByPatientId: patientB,
      );

      await tester.pumpWidget(
        buildTestHost(
          DoctorReportViewerDialog(
            reportDoc: reportDoc,
            currentPatientId: patientA, // Expected patient is Patient A
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('You are not authorized to view reports for this patient visit.'),
        findsOneWidget,
      );
    });

    testWidgets('5. Wrong case or visit report is denied access', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      sessionService.registerProfile(treatingDoctorProfile);
      await sessionService.enterDevelopmentWorkspace(profile: treatingDoctorProfile);

      final reportDoc = ReportDocument(
        reportId: 'REP-WRONG-VISIT',
        patientId: patientA,
        caseId: caseIdA,
        visitId: 'VIS-NONEXISTENT',
        investigationId: 'INV-001',
        fileName: 'Report.pdf',
        contentType: 'application/pdf',
        fileSizeBytes: samplePdfBytes.length,
        storagePath: 'patients/$patientA/cases/$caseIdA/visits/VIS-NONEXISTENT/reports/INV-001/Report.pdf',
        uploadedAt: DateTime.now(),
        uploadedByPatientId: patientA,
      );

      await tester.pumpWidget(
        buildTestHost(
          DoctorReportViewerDialog(
            reportDoc: reportDoc,
            currentPatientId: patientA,
            currentCaseId: caseIdA,
            currentVisitId: visitIdA1, // Expected visit is Visit A1
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('You are not authorized to view reports for this patient visit.'),
        findsOneWidget,
      );
    });

    testWidgets('6. Storage failure is presented as storage/network error, NOT authorization failure', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      sessionService.registerProfile(treatingDoctorProfile);
      await sessionService.enterDevelopmentWorkspace(profile: treatingDoctorProfile);

      // Doctor is authorized, but file is NOT uploaded in storage (returns null bytes)
      final reportDoc = ReportDocument(
        reportId: 'REP-MISSING-STORAGE',
        patientId: patientA,
        caseId: caseIdA,
        visitId: visitIdA1,
        investigationId: 'INV-001',
        fileName: 'Missing_File.pdf',
        contentType: 'application/pdf',
        fileSizeBytes: 2048,
        storagePath: 'patients/$patientA/cases/$caseIdA/visits/$visitIdA1/reports/INV-001/Missing_File.pdf',
        uploadedAt: DateTime.now(),
        uploadedByPatientId: patientA,
      );

      await tester.pumpWidget(
        buildTestHost(
          DoctorReportViewerDialog(
            reportDoc: reportDoc,
            currentPatientId: patientA,
            currentCaseId: caseIdA,
            currentVisitId: visitIdA1,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verified: DOES NOT show authorization denied!
      expect(
        find.text('You are not authorized to view reports for this patient visit.'),
        findsNothing,
      );

      // Verified: Displays specific storage retrieval error message and Retry button
      expect(
        find.text('Could not load document from secure private storage. Please verify connection and retry.'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('7. AI Summarization receives authorized report bytes', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      sessionService.registerProfile(treatingDoctorProfile);
      await sessionService.enterDevelopmentWorkspace(profile: treatingDoctorProfile);

      final storagePath = await storageService.uploadReportFile(
        patientId: patientA,
        caseId: caseIdA,
        visitId: visitIdA1,
        investigationId: 'INV-001',
        fileName: 'Hemoglobin_Report.pdf',
        bytes: samplePdfBytes,
        contentType: 'application/pdf',
      );

      final reportDoc = ReportDocument(
        reportId: 'REP-HB-001',
        patientId: patientA,
        caseId: caseIdA,
        visitId: visitIdA1,
        investigationId: 'INV-001',
        fileName: 'Hemoglobin_Report.pdf',
        contentType: 'application/pdf',
        fileSizeBytes: samplePdfBytes.length,
        storagePath: storagePath,
        uploadedAt: DateTime.now(),
        uploadedByPatientId: patientA,
      );
      await reportRepo.saveReportDocument(reportDoc);

      await tester.pumpWidget(
        buildTestHost(
          DoctorReportViewerDialog(
            reportDoc: reportDoc,
            currentPatientId: patientA,
            currentCaseId: caseIdA,
            currentVisitId: visitIdA1,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the AI Summarize Report button
      final aiButton = find.widgetWithText(DoctorSecondaryButton, 'AI Summarize Report');
      expect(aiButton, findsOneWidget);

      // Tap AI Summarize Report button
      await tester.tap(aiButton);
      await tester.pumpAndSettle();

      // Verified: DoctorAiReportSummaryDialog opened
      expect(find.byType(DoctorAiReportSummaryDialog), findsOneWidget);
      expect(find.text('AI Report Summary Assistant'), findsOneWidget);
      expect(find.text('Hemoglobin_Report.pdf'), findsWidgets);
    });
  });
}

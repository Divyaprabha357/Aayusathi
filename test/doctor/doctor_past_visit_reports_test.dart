import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/doctor/models/clinical_visit.dart';
import 'package:aayusathi/doctor/models/doctor_profile.dart';
import 'package:aayusathi/doctor/models/investigation_request.dart';
import 'package:aayusathi/doctor/models/report_document.dart';
import 'package:aayusathi/doctor/services/doctor_ai_report_summarization_service.dart';
import 'package:aayusathi/doctor/services/doctor_session_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_session_service.dart';
import 'package:aayusathi/doctor/services/mock_storage_service.dart';
import 'package:aayusathi/doctor/widgets/doctor_report_viewer_dialog.dart';
import 'package:aayusathi/doctor/widgets/doctor_visit_detail_dialog.dart';
import 'package:aayusathi/models/vital_reading.dart';
import 'package:aayusathi/patient/services/patient_report_access_service.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_report_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockReportRepository reportRepo;
  late MockStorageService storageService;
  late MockDoctorSessionService sessionService;

  // Minimal valid PDF binary
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

  // Minimal valid PNG binary
  final samplePngBytes = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
  ]);

  // Minimal valid JPEG binary
  final sampleJpgBytes = Uint8List.fromList([
    0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
    0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
    0x00, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01, 0x00, 0x01, 0x01, 0x01,
    0x11, 0x00, 0xFF, 0xC4, 0x00, 0x14, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x09,
    0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F, 0x00, 0x7F, 0x00,
    0xFF, 0xD9
  ]);

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('AAYUSATHI Doctor Past Visit: Show Patient-Uploaded Reports Test Suite', () {
    const testPatientId = 'AAYU-102938';
    const testCaseId = 'CASE-FATTY-LIVER-001';
    const testVisit1Id = 'VIS-FL-001';
    const testVisit2Id = 'VIS-FL-002';
    const testDoctorId = 'DOC-SOHAM-101';

    final docSohamProfile = DoctorProfile(
      doctorId: testDoctorId,
      doctorUniqueCode: testDoctorId,
      name: 'Dr. Soham Todankar',
      qualification: 'MD, DM Gastroenterology',
      department: 'Gastroenterology',
      registeredPhone: '+919876543212',
      email: 'soham@aayusathi.in',
      isActive: true,
      authUid: 'mock-auth-soham',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    );

    final visit1 = ClinicalVisit(
      visitId: testVisit1Id,
      caseId: testCaseId,
      patientId: testPatientId,
      doctorId: testDoctorId,
      doctorName: 'Dr. Soham Todankar',
      doctorQualification: 'MD, DM Gastroenterology',
      department: 'Gastroenterology',
      visitNumber: 1,
      startedAt: DateTime(2026, 9, 11, 10, 30),
      completedAt: DateTime(2026, 9, 11, 11, 0),
      status: ClinicalVisitStatus.completed,
      chiefComplaint: 'Upper right abdominal discomfort and fatigue',
      onsetDuration: '3 weeks',
      vitals: VitalReading(
        vitalId: 'VIT-001',
        patientId: testPatientId,
        heartRate: 74,
        spo2: 98,
        temperature: 98.4,
        timestamp: DateTime(2026, 9, 11, 10, 30),
      ),
      investigationRequests: [
        InvestigationRequest(
          requestId: 'REQ-USG-001',
          patientId: testPatientId,
          caseId: testCaseId,
          visitId: testVisit1Id,
          requestedByDoctorId: testDoctorId,
          department: 'Gastroenterology',
          name: 'Ultrasound Abdomen & Pelvis',
          category: InvestigationCategory.radiology,
          priority: InvestigationPriority.required,
          status: InvestigationStatus.pendingUpload,
          requestedAt: DateTime(2026, 9, 11, 10, 45),
        ),
      ],
    );

    final visit2 = ClinicalVisit(
      visitId: testVisit2Id,
      caseId: testCaseId,
      patientId: testPatientId,
      doctorId: testDoctorId,
      doctorName: 'Dr. Soham Todankar',
      visitNumber: 2,
      startedAt: DateTime(2026, 9, 25, 14, 0),
      completedAt: DateTime(2026, 9, 25, 14, 30),
      status: ClinicalVisitStatus.completed,
      chiefComplaint: 'Follow-up on liver enzymes',
      investigationRequests: [
        InvestigationRequest(
          requestId: 'REQ-LFT-002',
          patientId: testPatientId,
          caseId: testCaseId,
          visitId: testVisit2Id,
          requestedByDoctorId: testDoctorId,
          department: 'Gastroenterology',
          name: 'Liver Function Test (LFT)',
          category: InvestigationCategory.lab,
          priority: InvestigationPriority.asAdvised,
          status: InvestigationStatus.pendingUpload,
          requestedAt: DateTime(2026, 9, 25, 14, 15),
        ),
      ],
    );

    setUp(() async {
      BackendProvider.instance.setMode(BackendMode.mock);
      BackendProvider.instance.resetOverrides();

      reportRepo = MockReportRepository.instance..clearAll();
      storageService = MockStorageService.instance..reset();
      sessionService = MockDoctorSessionService();
      sessionService.registerProfile(docSohamProfile);
      await sessionService.enterDevelopmentWorkspace(profile: docSohamProfile);
      DoctorSessionService.instance = sessionService;

      await MockCaseRepository.instance.createCase(
        ClinicalCase(
          caseId: testCaseId,
          patientId: testPatientId,
          domain: 'gastroenterology',
          title: 'Fatty Liver Disease',
          status: ClinicalCaseStatus.open,
          createdAt: DateTime(2026, 9, 1),
        ),
      );
      await MockClinicalVisitRepository.instance.createVisit(visit1);
      await MockClinicalVisitRepository.instance.createVisit(visit2);
    });

    test('1 & 2. Patient uploads report for Visit 1 -> Doctor sees report under Visit 1', () async {
      // 1. Upload report for Visit 1 into storage & metadata
      final storagePath = await storageService.uploadReportFile(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit1Id,
        investigationId: 'REQ-USG-001',
        fileName: 'Ultrasound_Report.pdf',
        bytes: samplePdfBytes,
        contentType: 'application/pdf',
      );

      final reportDoc = ReportDocument(
        reportId: 'REP-USG-V1-001',
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit1Id,
        investigationId: 'REQ-USG-001',
        fileName: 'Ultrasound_Report.pdf',
        contentType: 'application/pdf',
        fileSizeBytes: samplePdfBytes.length,
        storagePath: storagePath,
        storageProvider: 'supabase',
        storageBucket: 'aayusathi-reports',
        uploadedAt: DateTime(2026, 9, 11, 12, 0),
        uploadedByPatientId: testPatientId,
        reviewStatus: ReportReviewStatus.uploaded,
      );

      await reportRepo.saveReportDocument(reportDoc);

      // 2. Doctor queries reports for Visit 1
      final reports = await reportRepo.getReportsForVisit(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit1Id,
      );

      expect(reports.length, equals(1));
      expect(reports.first.fileName, equals('Ultrasound_Report.pdf'));
      expect(reports.first.visitId, equals(testVisit1Id));
      expect(reports.first.reviewStatus, equals(ReportReviewStatus.uploaded));
    });

    test('3. Doctor does NOT see Visit 1 report under Visit 2 (Visit isolation)', () async {
      // Setup report for Visit 1
      await reportRepo.saveReportDocument(
        ReportDocument(
          reportId: 'REP-USG-V1-001',
          patientId: testPatientId,
          caseId: testCaseId,
          visitId: testVisit1Id,
          investigationId: 'REQ-USG-001',
          fileName: 'Ultrasound_Report.pdf',
          contentType: 'application/pdf',
          fileSizeBytes: samplePdfBytes.length,
          storagePath: 'patients/$testPatientId/cases/$testCaseId/visits/$testVisit1Id/reports/Ultrasound_Report.pdf',
          uploadedAt: DateTime(2026, 9, 11, 12, 0),
          uploadedByPatientId: testPatientId,
        ),
      );

      // Query Visit 2
      final visit2Reports = await reportRepo.getReportsForVisit(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit2Id,
      );

      expect(visit2Reports, isEmpty);
    });

    test('4. Visit 2 report appears only under Visit 2', () async {
      // Upload for Visit 2
      await reportRepo.saveReportDocument(
        ReportDocument(
          reportId: 'REP-LFT-V2-001',
          patientId: testPatientId,
          caseId: testCaseId,
          visitId: testVisit2Id,
          investigationId: 'REQ-LFT-002',
          fileName: 'LFT_Blood_Report.pdf',
          contentType: 'application/pdf',
          fileSizeBytes: samplePdfBytes.length,
          storagePath: 'patients/$testPatientId/cases/$testCaseId/visits/$testVisit2Id/reports/LFT_Blood_Report.pdf',
          uploadedAt: DateTime(2026, 9, 25, 16, 0),
          uploadedByPatientId: testPatientId,
        ),
      );

      final v1Reports = await reportRepo.getReportsForVisit(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit1Id,
      );
      final v2Reports = await reportRepo.getReportsForVisit(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit2Id,
      );

      expect(v1Reports, isEmpty);
      expect(v2Reports.length, equals(1));
      expect(v2Reports.first.fileName, equals('LFT_Blood_Report.pdf'));
      expect(visit2.visitId, equals(testVisit2Id));
    });

    test('5, 6 & 7. Ownership & Exact matching: Patient, Case, and Visit matching', () async {
      await reportRepo.saveReportDocument(
        ReportDocument(
          reportId: 'REP-MATCH-001',
          patientId: testPatientId,
          caseId: testCaseId,
          visitId: testVisit1Id,
          investigationId: 'REQ-USG-001',
          fileName: 'Ultrasound_Report.pdf',
          contentType: 'application/pdf',
          fileSizeBytes: 1024,
          storagePath: 'some/path.pdf',
          uploadedAt: DateTime.now(),
          uploadedByPatientId: testPatientId,
        ),
      );

      // Different patient -> empty
      final diffPatient = await reportRepo.getReportsForVisit(
        patientId: 'AAYU-999999',
        caseId: testCaseId,
        visitId: testVisit1Id,
      );
      expect(diffPatient, isEmpty);

      // Different case -> empty
      final diffCase = await reportRepo.getReportsForVisit(
        patientId: testPatientId,
        caseId: 'CASE-DIFF-999',
        visitId: testVisit1Id,
      );
      expect(diffCase, isEmpty);

      // Exact match -> found
      final exactMatch = await reportRepo.getReportsForVisit(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit1Id,
      );
      expect(exactMatch.length, equals(1));
    });

    test('8. Multiple reports for one visit', () async {
      final reports = [
        ReportDocument(
          reportId: 'REP-CBC-001',
          patientId: testPatientId,
          caseId: testCaseId,
          visitId: testVisit1Id,
          investigationId: 'REQ-CBC',
          fileName: 'CBC_Report.pdf',
          contentType: 'application/pdf',
          fileSizeBytes: 2048,
          storagePath: 'path/cbc.pdf',
          uploadedAt: DateTime(2026, 9, 11, 12, 0),
          uploadedByPatientId: testPatientId,
        ),
        ReportDocument(
          reportId: 'REP-USG-001',
          patientId: testPatientId,
          caseId: testCaseId,
          visitId: testVisit1Id,
          investigationId: 'REQ-USG-001',
          fileName: 'Ultrasound_Report.pdf',
          contentType: 'application/pdf',
          fileSizeBytes: 4096,
          storagePath: 'path/usg.pdf',
          uploadedAt: DateTime(2026, 9, 11, 12, 30),
          uploadedByPatientId: testPatientId,
        ),
        ReportDocument(
          reportId: 'REP-ECG-001',
          patientId: testPatientId,
          caseId: testCaseId,
          visitId: testVisit1Id,
          investigationId: 'REQ-ECG',
          fileName: 'ECG_Report.jpg',
          contentType: 'image/jpeg',
          fileSizeBytes: 1024,
          storagePath: 'path/ecg.jpg',
          uploadedAt: DateTime(2026, 9, 11, 13, 0),
          uploadedByPatientId: testPatientId,
        ),
      ];

      for (final r in reports) {
        await reportRepo.saveReportDocument(r);
      }

      final fetched = await reportRepo.getReportsForVisit(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit1Id,
      );

      expect(fetched.length, equals(3));
      expect(fetched.map((e) => e.fileName).toSet(), containsAll(['CBC_Report.pdf', 'Ultrasound_Report.pdf', 'ECG_Report.jpg']));
    });

    testWidgets('9 & 10. UI: Empty state and Waiting for patient report', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      // Visit 1 has pending investigation REQ-USG-001 but no uploaded reports yet
      await tester.pumpWidget(
        createTestWidget(
          DoctorVisitDetailDialog(
            visit: visit1,
            domain: 'Gastroenterology',
            locale: KioskLocale.english,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check section header exists
      expect(find.text('Patient Uploaded Reports'), findsOneWidget);

      // Pending investigation shows "Waiting for patient report."
      expect(find.text('Waiting for patient report.'), findsOneWidget);
      expect(find.text('Pending Upload'), findsOneWidget);

      // Empty state notice
      expect(find.text('No patient reports uploaded for this visit.'), findsOneWidget);
    });

    testWidgets('11 & 12. UI: Uploaded report visible, correct status badge, and Mark as Reviewed', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Save report
      await reportRepo.saveReportDocument(
        ReportDocument(
          reportId: 'REP-USG-V1-001',
          patientId: testPatientId,
          caseId: testCaseId,
          visitId: testVisit1Id,
          investigationId: 'REQ-USG-001',
          fileName: 'Ultrasound_Report.pdf',
          contentType: 'application/pdf',
          fileSizeBytes: samplePdfBytes.length,
          storagePath: 'patients/$testPatientId/cases/$testCaseId/visits/$testVisit1Id/reports/Ultrasound_Report.pdf',
          uploadedAt: DateTime(2026, 9, 11, 12, 0),
          uploadedByPatientId: testPatientId,
          reviewStatus: ReportReviewStatus.uploaded,
        ),
      );

      await tester.pumpWidget(
        createTestWidget(
          DoctorVisitDetailDialog(
            visit: visit1,
            domain: 'Gastroenterology',
            locale: KioskLocale.english,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check report title and badge
      expect(find.text('Ultrasound_Report.pdf'), findsOneWidget);
      expect(find.text('Uploaded'), findsWidgets);
      expect(find.text('VIEW REPORT'), findsOneWidget);
      expect(find.text('MARK AS REVIEWED'), findsOneWidget);

      // Tap Mark as Reviewed
      await tester.ensureVisible(find.text('MARK AS REVIEWED'));
      await tester.tap(find.text('MARK AS REVIEWED'));
      await tester.pumpAndSettle();

      // Status should transition to Reviewed
      expect(find.text('Reviewed'), findsWidgets);
    });

    testWidgets('13. Secure Doctor Report Viewer Dialog: PDF opens successfully', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      final path = await storageService.uploadReportFile(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit1Id,
        investigationId: 'REQ-USG-001',
        fileName: 'Ultrasound_Report.pdf',
        bytes: samplePdfBytes,
        contentType: 'application/pdf',
      );

      final reportDoc = ReportDocument(
        reportId: 'REP-USG-001',
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit1Id,
        investigationId: 'REQ-USG-001',
        fileName: 'Ultrasound_Report.pdf',
        contentType: 'application/pdf',
        fileSizeBytes: samplePdfBytes.length,
        storagePath: path,
        uploadedAt: DateTime.now(),
        uploadedByPatientId: testPatientId,
      );

      await tester.pumpWidget(
        createTestWidget(
          DoctorReportViewerDialog(
            reportDoc: reportDoc,
            investigation: visit1.investigationRequests.first,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Ultrasound_Report.pdf'), findsOneWidget);
      expect(find.text('STATUS: '), findsOneWidget);
      expect(find.text('UPLOADED'), findsWidgets);
      expect(find.text('AI Summarize Report'), findsOneWidget);
      expect(find.text('Private Secure Document • In-Memory Stream'), findsOneWidget);
    });

    testWidgets('14. Secure Doctor Report Viewer Dialog: JPG opens successfully', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      final path = await storageService.uploadReportFile(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit1Id,
        investigationId: 'REQ-ECG-001',
        fileName: 'ECG_Report.jpg',
        bytes: sampleJpgBytes,
        contentType: 'image/jpeg',
      );

      final reportDoc = ReportDocument(
        reportId: 'REP-ECG-001',
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit1Id,
        investigationId: 'REQ-ECG-001',
        fileName: 'ECG_Report.jpg',
        contentType: 'image/jpeg',
        fileSizeBytes: sampleJpgBytes.length,
        storagePath: path,
        uploadedAt: DateTime.now(),
        uploadedByPatientId: testPatientId,
      );

      await tester.pumpWidget(
        createTestWidget(
          DoctorReportViewerDialog(
            reportDoc: reportDoc,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ECG_Report.jpg'), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('15. Secure Doctor Report Viewer Dialog: PNG opens successfully', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      final path = await storageService.uploadReportFile(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit1Id,
        investigationId: 'REQ-SKIN-001',
        fileName: 'Lesion_Photo.png',
        bytes: samplePngBytes,
        contentType: 'image/png',
      );

      final reportDoc = ReportDocument(
        reportId: 'REP-SKIN-001',
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit1Id,
        investigationId: 'REQ-SKIN-001',
        fileName: 'Lesion_Photo.png',
        contentType: 'image/png',
        fileSizeBytes: samplePngBytes.length,
        storagePath: path,
        uploadedAt: DateTime.now(),
        uploadedByPatientId: testPatientId,
      );

      await tester.pumpWidget(
        createTestWidget(
          DoctorReportViewerDialog(
            reportDoc: reportDoc,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Lesion_Photo.png'), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('16. Unauthorized access denied: Unauthenticated doctor cannot view report', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      sessionService.resetSession();

      final reportDoc = ReportDocument(
        reportId: 'REP-DENIED-001',
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit1Id,
        investigationId: 'REQ-001',
        fileName: 'Secret_Report.pdf',
        contentType: 'application/pdf',
        fileSizeBytes: 1024,
        storagePath: 'path.pdf',
        uploadedAt: DateTime.now(),
        uploadedByPatientId: testPatientId,
      );

      await tester.pumpWidget(
        createTestWidget(
          DoctorReportViewerDialog(
            reportDoc: reportDoc,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('You are not authorized to view reports for this patient visit.'), findsOneWidget);
    });

    test('17 & 18. Private Supabase storage preserved and time-limited signed URL generation', () async {
      final path = await storageService.uploadReportFile(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit1Id,
        investigationId: 'REQ-001',
        fileName: 'Private_Report.pdf',
        bytes: samplePdfBytes,
        contentType: 'application/pdf',
      );

      // Verify signed URL is generated with token
      final signedUrl = await storageService.getSignedUrl(path, expiresIn: const Duration(minutes: 5));
      expect(signedUrl, isNotNull);
      expect(signedUrl!, contains('aayusathi-reports'));
      expect(signedUrl, contains('token='));

      // File exists check
      final exists = await storageService.fileExists(path);
      expect(exists, isTrue);
    });

    test('19. Patient App Submitted reports still work (PatientReportAccessService)', () async {
      await reportRepo.saveReportDocument(
        ReportDocument(
          reportId: 'REP-PAT-001',
          patientId: testPatientId,
          caseId: testCaseId,
          visitId: testVisit1Id,
          investigationId: 'REQ-001',
          fileName: 'Blood_Test.pdf',
          contentType: 'application/pdf',
          fileSizeBytes: 2048,
          storagePath: 'path.pdf',
          uploadedAt: DateTime.now(),
          uploadedByPatientId: testPatientId,
        ),
      );

      final patientService = PatientReportAccessService.instance;
      final visitReports = await patientService.getVisitReports(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit1Id,
      );

      expect(visitReports.length, equals(1));
      expect(visitReports.first.fileName, equals('Blood_Test.pdf'));
    });

    test('20. Official Visit Report remains separate from patient investigation reports', () {
      final officialPdf = ReportDocument(
        reportId: 'OFFICIAL-REPORT-$testVisit1Id',
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit1Id,
        investigationId: 'OFFICIAL_VISIT_REPORT',
        fileName: 'Doctor_Consultation_Visit1.pdf',
        contentType: 'application/pdf',
        fileSizeBytes: 10240,
        storagePath: 'path/to/official.pdf',
        uploadedAt: DateTime.now(),
        uploadedByPatientId: testDoctorId,
      );

      final patientUpload = ReportDocument(
        reportId: 'REP-PATIENT-USG-001',
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit1Id,
        investigationId: 'REQ-USG-001',
        fileName: 'Patient_Ultrasound.pdf',
        contentType: 'application/pdf',
        fileSizeBytes: 4096,
        storagePath: 'path/to/usg.pdf',
        uploadedAt: DateTime.now(),
        uploadedByPatientId: testPatientId,
      );

      expect(officialPdf.isOfficialVisitReport, isTrue);
      expect(officialPdf.isPatientUploadedReport, isFalse);

      expect(patientUpload.isOfficialVisitReport, isFalse);
      expect(patientUpload.isPatientUploadedReport, isTrue);
    });

    test('21. Duplicate prevention: Retried uploads update rather than duplicating', () async {
      final doc1 = ReportDocument(
        reportId: 'REP-IDEMPOTENT-001',
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit1Id,
        investigationId: 'REQ-001',
        fileName: 'Report_v1.pdf',
        contentType: 'application/pdf',
        fileSizeBytes: 1000,
        storagePath: 'path/rep.pdf',
        uploadedAt: DateTime(2026, 9, 11, 10, 0),
        uploadedByPatientId: testPatientId,
      );

      await reportRepo.saveReportDocument(doc1);

      // Re-upload/retry with same reportId
      final doc2 = doc1.copyWith(
        fileName: 'Report_v2_updated.pdf',
        fileSizeBytes: 2000,
      );

      await reportRepo.saveReportDocument(doc2);

      final list = await reportRepo.getReportsForVisit(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit1Id,
      );

      expect(list.length, equals(1));
      expect(list.first.fileName, equals('Report_v2_updated.pdf'));
      expect(list.first.fileSizeBytes, equals(2000));
    });

    test('22. Real-time stream updates without polling (watchReportsForVisit)', () async {
      final stream = reportRepo.watchReportsForVisit(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit1Id,
      );

      final recordedEmissions = <List<ReportDocument>>[];
      final sub = stream.listen((list) {
        recordedEmissions.add(list);
      });

      // Initially empty
      await Future.delayed(const Duration(milliseconds: 20));
      expect(recordedEmissions.isNotEmpty, isTrue);
      expect(recordedEmissions.first, isEmpty);

      // Patient uploads report in real time
      await reportRepo.saveReportDocument(
        ReportDocument(
          reportId: 'REP-REALTIME-001',
          patientId: testPatientId,
          caseId: testCaseId,
          visitId: testVisit1Id,
          investigationId: 'REQ-001',
          fileName: 'Live_Report.pdf',
          contentType: 'application/pdf',
          fileSizeBytes: 3000,
          storagePath: 'path/live.pdf',
          uploadedAt: DateTime.now(),
          uploadedByPatientId: testPatientId,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 20));

      expect(recordedEmissions.length, greaterThanOrEqualTo(2));
      expect(recordedEmissions.last.first.fileName, equals('Live_Report.pdf'));

      await sub.cancel();
    });

    testWidgets('23. AI Summarize Report extension point opens with safety disclaimers', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final storagePath = await storageService.uploadReportFile(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit1Id,
        investigationId: 'REQ-001',
        fileName: 'Blood_Report.pdf',
        bytes: samplePdfBytes,
        contentType: 'application/pdf',
      );

      final reportDoc = ReportDocument(
        reportId: 'REP-AI-TEST-001',
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit1Id,
        investigationId: 'REQ-001',
        fileName: 'Blood_Report.pdf',
        contentType: 'application/pdf',
        fileSizeBytes: samplePdfBytes.length,
        storagePath: storagePath,
        uploadedAt: DateTime.now(),
        uploadedByPatientId: testPatientId,
      );

      await tester.pumpWidget(
        createTestWidget(
          DoctorAiReportSummaryDialog(
            report: reportDoc,
            preloadedFileBytes: samplePdfBytes,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('AI Report Summary Assistant'), findsOneWidget);
      expect(find.text('AI-generated summary — Doctor verification required.'), findsOneWidget);
      expect(find.text('2. KEY FINDINGS'), findsOneWidget);
      expect(find.text('3. REPORTED MEASUREMENTS'), findsOneWidget);
      expect(find.text('6. ITEMS TO REVIEW'), findsOneWidget);
      expect(find.text('REVIEW REQUIRED'), findsOneWidget);
      expect(find.text('Approve Summary'), findsOneWidget);
    });
  });
}

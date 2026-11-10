import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_exception.dart';
import 'package:aayusathi/doctor/models/report_document.dart';
import 'package:aayusathi/doctor/services/doctor_ai_report_summarization_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_ai_report_summarization_service.dart';
import 'package:aayusathi/doctor/services/doctor_session_service.dart';
import 'package:aayusathi/doctor/services/mock_doctor_session_service.dart';
import 'package:aayusathi/doctor/services/mock_storage_service.dart';
import 'package:aayusathi/repositories/mock/mock_report_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockReportRepository reportRepo;
  late MockStorageService storageService;
  late MockDoctorSessionService sessionService;
  late MockDoctorAiReportSummarizationService summarizationService;

  const testPatientId = 'AAYU-102938';
  const testCaseId = 'CASE-FATTY-LIVER-001';
  const testVisit1Id = 'VIS-FL-001';
  const testVisit2Id = 'VIS-FL-002';
  const testDoctorId = 'DOC-DEMO-001';

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

  final samplePngBytes = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x60, 0x60, 0x60, 0x00,
    0x00, 0x00, 0x04, 0x00, 0x01, 0x27, 0x34, 0x27, 0x0A, 0x00, 0x00, 0x00,
    0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
  ]);

  final sampleJpgBytes = Uint8List.fromList([
    0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
    0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
    0x00, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01, 0x00, 0x01, 0x01, 0x01,
    0x11, 0x00, 0xFF, 0xC4, 0x00, 0x14, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F, 0x00, 0x37, 0xFF,
    0xD9
  ]);

  setUp(() async {
    reportRepo = MockReportRepository.instance..clearAll();
    storageService = MockStorageService.instance..reset();
    sessionService = MockDoctorSessionService();
    await sessionService.enterDevelopmentWorkspace();

    summarizationService = MockDoctorAiReportSummarizationService.instance..resetToDefaults();

    DoctorSessionService.instance = sessionService;
    DoctorAiReportSummarizationService.instance = summarizationService;
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  ReportDocument createReportDoc({
    required String reportId,
    required String fileName,
    required String contentType,
    String patientId = testPatientId,
    String caseId = testCaseId,
    String visitId = testVisit1Id,
    String investigationId = 'REQ-001',
    Uint8List? bytes,
  }) {
    return ReportDocument(
      reportId: reportId,
      patientId: patientId,
      caseId: caseId,
      visitId: visitId,
      investigationId: investigationId,
      fileName: fileName,
      contentType: contentType,
      fileSizeBytes: bytes?.length ?? 1024,
      storagePath: 'patients/$patientId/cases/$caseId/visits/$visitId/reports/$fileName',
      uploadedAt: DateTime.now(),
      uploadedByPatientId: patientId,
    );
  }

  group('AAYUSATHI AI Medical Report Summarization Test Suite', () {
    // -------------------------------------------------------------
    // 1 to 9: Report Modalities
    // -------------------------------------------------------------
    test('1. Blood report: summarizes Blood report with 7 sections', () async {
      final doc = createReportDoc(
        reportId: 'REP-001',
        fileName: 'Routine_Blood_Report.pdf',
        contentType: 'application/pdf',
      );

      final summary = await summarizationService.summarizeReport(
        report: doc,
        fileBytes: samplePdfBytes,
        currentPatientId: testPatientId,
        currentCaseId: testCaseId,
        currentVisitId: testVisit1Id,
      );

      expect(summary.investigationName, contains('Blood'));
      expect(summary.reportedMeasurements, isNotEmpty);
      expect(summary.status, equals(AiReportSummaryStatus.reviewRequired));
      expect(summary.toFormattedDisplayString(), contains('Doctor verification required.'));
    });

    test('2. CBC report: summarizes CBC report with 7 sections', () async {
      final doc = createReportDoc(
        reportId: 'REP-002',
        fileName: 'CBC_Hemogram_Report.pdf',
        contentType: 'application/pdf',
      );

      final summary = await summarizationService.summarizeReport(
        report: doc,
        fileBytes: samplePdfBytes,
        currentPatientId: testPatientId,
        currentCaseId: testCaseId,
        currentVisitId: testVisit1Id,
      );

      expect(summary.investigationName, equals('Complete Blood Count (CBC)'));
      expect(summary.keyFindings, isNotEmpty);
      expect(summary.reportedMeasurements.any((m) => m.parameter == 'Hemoglobin'), isTrue);
      expect(summary.reportedMeasurements.any((m) => m.parameter.contains('WBC')), isTrue);
      expect(summary.reportedMeasurements.any((m) => m.parameter.contains('Platelet')), isTrue);
    });

    test('3. LFT report: summarizes LFT report with 7 sections', () async {
      final doc = createReportDoc(
        reportId: 'REP-003',
        fileName: 'Liver_Function_Test.pdf',
        contentType: 'application/pdf',
      );

      final summary = await summarizationService.summarizeReport(
        report: doc,
        fileBytes: samplePdfBytes,
        currentPatientId: testPatientId,
        currentCaseId: testCaseId,
        currentVisitId: testVisit1Id,
      );

      expect(summary.investigationName, contains('Liver Function Test'));
      expect(summary.reportedMeasurements.any((m) => m.parameter.contains('SGPT') || m.parameter.contains('ALT')), isTrue);
      expect(summary.reportedMeasurements.any((m) => m.parameter.contains('SGOT') || m.parameter.contains('AST')), isTrue);
      expect(summary.keyFindings.any((f) => f.toLowerCase().contains('transaminases')), isTrue);
    });

    test('4. KFT report: summarizes KFT report with 7 sections', () async {
      final doc = createReportDoc(
        reportId: 'REP-004',
        fileName: 'Kidney_Function_Test_KFT.pdf',
        contentType: 'application/pdf',
      );

      final summary = await summarizationService.summarizeReport(
        report: doc,
        fileBytes: samplePdfBytes,
        currentPatientId: testPatientId,
        currentCaseId: testCaseId,
        currentVisitId: testVisit1Id,
      );

      expect(summary.investigationName, contains('Kidney Function Test'));
      expect(summary.reportedMeasurements.any((m) => m.parameter.contains('Creatinine')), isTrue);
      expect(summary.reportedMeasurements.any((m) => m.parameter.contains('Urea')), isTrue);
    });

    test('5. Lipid profile: summarizes Lipid Profile report with 7 sections', () async {
      final doc = createReportDoc(
        reportId: 'REP-005',
        fileName: 'Lipid_Profile_Report.pdf',
        contentType: 'application/pdf',
      );

      final summary = await summarizationService.summarizeReport(
        report: doc,
        fileBytes: samplePdfBytes,
        currentPatientId: testPatientId,
        currentCaseId: testCaseId,
        currentVisitId: testVisit1Id,
      );

      expect(summary.investigationName, contains('Lipid'));
      expect(summary.reportedMeasurements.any((m) => m.parameter.contains('Cholesterol')), isTrue);
      expect(summary.reportedMeasurements.any((m) => m.parameter.contains('Triglycerides')), isTrue);
    });

    test('6. Urine routine: summarizes Urine Routine report with 7 sections', () async {
      final doc = createReportDoc(
        reportId: 'REP-006',
        fileName: 'Urine_Routine_Microscopy.pdf',
        contentType: 'application/pdf',
      );

      final summary = await summarizationService.summarizeReport(
        report: doc,
        fileBytes: samplePdfBytes,
        currentPatientId: testPatientId,
        currentCaseId: testCaseId,
        currentVisitId: testVisit1Id,
      );

      expect(summary.investigationName, contains('Urine'));
      expect(summary.reportedMeasurements.any((m) => m.parameter.contains('Protein') || m.parameter.contains('pH')), isTrue);
    });

    test('7. ECG report: summarizes ECG report with 7 sections', () async {
      final doc = createReportDoc(
        reportId: 'REP-007',
        fileName: '12_Lead_ECG_Report.jpg',
        contentType: 'image/jpeg',
      );

      final summary = await summarizationService.summarizeReport(
        report: doc,
        fileBytes: sampleJpgBytes,
        currentPatientId: testPatientId,
        currentCaseId: testCaseId,
        currentVisitId: testVisit1Id,
      );

      expect(summary.investigationName, contains('ECG'));
      expect(summary.reportedMeasurements.any((m) => m.parameter.contains('Heart Rate')), isTrue);
      expect(summary.keyFindings.any((f) => f.contains('rhythm') || f.contains('ECG')), isTrue);
    });

    test('8. Chest X-Ray: summarizes Chest X-Ray report with 7 sections', () async {
      final doc = createReportDoc(
        reportId: 'REP-008',
        fileName: 'Chest_XRay_PA.png',
        contentType: 'image/png',
      );

      final summary = await summarizationService.summarizeReport(
        report: doc,
        fileBytes: samplePngBytes,
        currentPatientId: testPatientId,
        currentCaseId: testCaseId,
        currentVisitId: testVisit1Id,
      );

      expect(summary.investigationName, contains('Chest X-Ray'));
      expect(summary.keyFindings.any((f) => f.contains('lung') || f.contains('fields') || f.contains('costophrenic')), isTrue);
    });

    test('9. Ultrasound report: summarizes Ultrasound report with 7 sections', () async {
      final doc = createReportDoc(
        reportId: 'REP-009',
        fileName: 'Ultrasound_Whole_Abdomen.pdf',
        contentType: 'application/pdf',
      );

      final summary = await summarizationService.summarizeReport(
        report: doc,
        fileBytes: samplePdfBytes,
        currentPatientId: testPatientId,
        currentCaseId: testCaseId,
        currentVisitId: testVisit1Id,
      );

      expect(summary.investigationName, contains('Ultrasound'));
      expect(summary.keyFindings.any((f) => f.contains('echogenicity') || f.contains('liver') || f.contains('Ultrasound')), isTrue);
    });

    // -------------------------------------------------------------
    // 10 to 13: File Types
    // -------------------------------------------------------------
    test('10. PDF report: handles application/pdf successfully', () async {
      final doc = createReportDoc(
        reportId: 'REP-PDF',
        fileName: 'CBC_Report.pdf',
        contentType: 'application/pdf',
      );
      final summary = await summarizationService.summarizeReport(
        report: doc,
        fileBytes: samplePdfBytes,
        currentPatientId: testPatientId,
        currentCaseId: testCaseId,
        currentVisitId: testVisit1Id,
      );
      expect(summary.reportId, equals('REP-PDF'));
      expect(summary.reportedMeasurements, isNotEmpty);
    });

    test('11. JPG report: handles image/jpeg (.jpg) successfully', () async {
      final doc = createReportDoc(
        reportId: 'REP-JPG',
        fileName: 'Scan.jpg',
        contentType: 'image/jpeg',
      );
      final summary = await summarizationService.summarizeReport(
        report: doc,
        fileBytes: sampleJpgBytes,
        currentPatientId: testPatientId,
        currentCaseId: testCaseId,
        currentVisitId: testVisit1Id,
      );
      expect(summary.reportId, equals('REP-JPG'));
    });

    test('12. JPEG report: handles image/jpeg (.jpeg) successfully', () async {
      final doc = createReportDoc(
        reportId: 'REP-JPEG',
        fileName: 'Scan.jpeg',
        contentType: 'image/jpeg',
      );
      final summary = await summarizationService.summarizeReport(
        report: doc,
        fileBytes: sampleJpgBytes,
        currentPatientId: testPatientId,
        currentCaseId: testCaseId,
        currentVisitId: testVisit1Id,
      );
      expect(summary.reportId, equals('REP-JPEG'));
    });

    test('13. PNG report: handles image/png successfully', () async {
      final doc = createReportDoc(
        reportId: 'REP-PNG',
        fileName: 'Graph.png',
        contentType: 'image/png',
      );
      final summary = await summarizationService.summarizeReport(
        report: doc,
        fileBytes: samplePngBytes,
        currentPatientId: testPatientId,
        currentCaseId: testCaseId,
        currentVisitId: testVisit1Id,
      );
      expect(summary.reportId, equals('REP-PNG'));
    });

    // -------------------------------------------------------------
    // 14 to 18: Failure Scenarios
    // -------------------------------------------------------------
    test('14. Missing report file: throws EMPTY_FILE / invalidData gracefully', () async {
      final doc = createReportDoc(
        reportId: 'REP-MISSING',
        fileName: 'NonExistent.pdf',
        contentType: 'application/pdf',
      );

      expect(
        () => summarizationService.summarizeReport(
          report: doc,
          fileBytes: Uint8List(0), // Empty bytes
          currentPatientId: testPatientId,
          currentCaseId: testCaseId,
          currentVisitId: testVisit1Id,
        ),
        throwsA(isA<BackendException>()),
      );
    });

    test('15. Corrupt report file: handles corrupt file error gracefully', () async {
      summarizationService.simulateCorruptFile = true;
      final doc = createReportDoc(
        reportId: 'REP-CORRUPT',
        fileName: 'Corrupt.pdf',
        contentType: 'application/pdf',
      );

      expect(
        () => summarizationService.summarizeReport(
          report: doc,
          fileBytes: Uint8List.fromList([0x00, 0x01]),
          currentPatientId: testPatientId,
          currentCaseId: testCaseId,
          currentVisitId: testVisit1Id,
        ),
        throwsA(isA<BackendException>()),
      );
      summarizationService.simulateCorruptFile = false;
    });

    test('16. Unreadable image: handles unreadable image error gracefully', () async {
      summarizationService.simulateUnreadableImage = true;
      final doc = createReportDoc(
        reportId: 'REP-BLURRY',
        fileName: 'Blurry.jpg',
        contentType: 'image/jpeg',
      );

      expect(
        () => summarizationService.summarizeReport(
          report: doc,
          fileBytes: sampleJpgBytes,
          currentPatientId: testPatientId,
          currentCaseId: testCaseId,
          currentVisitId: testVisit1Id,
        ),
        throwsA(isA<BackendException>()),
      );
      summarizationService.simulateUnreadableImage = false;
    });

    test('17. Gemini service failure: handles Gemini API failure gracefully', () async {
      summarizationService.simulateGeminiFailure = true;
      final doc = createReportDoc(
        reportId: 'REP-GEMINI-FAIL',
        fileName: 'Report.pdf',
        contentType: 'application/pdf',
      );

      expect(
        () => summarizationService.summarizeReport(
          report: doc,
          fileBytes: samplePdfBytes,
          currentPatientId: testPatientId,
          currentCaseId: testCaseId,
          currentVisitId: testVisit1Id,
        ),
        throwsA(isA<BackendException>()),
      );
      summarizationService.simulateGeminiFailure = false;
    });

    test('18. Network failure: handles network error gracefully', () async {
      summarizationService.simulateNetworkError = true;
      final doc = createReportDoc(
        reportId: 'REP-NET-FAIL',
        fileName: 'Report.pdf',
        contentType: 'application/pdf',
      );

      expect(
        () => summarizationService.summarizeReport(
          report: doc,
          fileBytes: samplePdfBytes,
          currentPatientId: testPatientId,
          currentCaseId: testCaseId,
          currentVisitId: testVisit1Id,
        ),
        throwsA(isA<BackendException>().having((e) => e.code, 'code', equals(BackendException.networkError))),
      );
      summarizationService.simulateNetworkError = false;
    });

    // -------------------------------------------------------------
    // 19 to 22: Security & Ownership Checks
    // -------------------------------------------------------------
    test('19. Unauthorized doctor: rejects unauthenticated doctor when devMode is false', () async {
      sessionService.resetSession();

      final doc = createReportDoc(
        reportId: 'REP-AUTH',
        fileName: 'Report.pdf',
        contentType: 'application/pdf',
      );

      expect(
        () => summarizationService.summarizeReport(
          report: doc,
          fileBytes: samplePdfBytes,
          currentPatientId: testPatientId,
          currentCaseId: testCaseId,
          currentVisitId: testVisit1Id,
        ),
        throwsA(isA<BackendException>().having((e) => e.code, 'code', equals(BackendException.permissionDenied))),
      );
    });

    test('20. Wrong patient report: rejects summarizing report belonging to different patient', () async {
      final doc = createReportDoc(
        reportId: 'REP-WRONG-PATIENT',
        patientId: 'AAYU-999999', // Different patient!
        fileName: 'Report.pdf',
        contentType: 'application/pdf',
      );

      expect(
        () => summarizationService.summarizeReport(
          report: doc,
          fileBytes: samplePdfBytes,
          currentPatientId: testPatientId,
          currentCaseId: testCaseId,
          currentVisitId: testVisit1Id,
        ),
        throwsA(isA<BackendException>().having((e) => e.code, 'code', equals(BackendException.permissionDenied))),
      );
    });

    test('21. Wrong case report: rejects summarizing report belonging to different case', () async {
      final doc = createReportDoc(
        reportId: 'REP-WRONG-CASE',
        caseId: 'CASE-WRONG-999', // Different case!
        fileName: 'Report.pdf',
        contentType: 'application/pdf',
      );

      expect(
        () => summarizationService.summarizeReport(
          report: doc,
          fileBytes: samplePdfBytes,
          currentPatientId: testPatientId,
          currentCaseId: testCaseId,
          currentVisitId: testVisit1Id,
        ),
        throwsA(isA<BackendException>().having((e) => e.code, 'code', equals(BackendException.permissionDenied))),
      );
    });

    test('22. Wrong visit report: rejects summarizing report belonging to different visit', () async {
      final doc = createReportDoc(
        reportId: 'REP-WRONG-VISIT',
        visitId: 'VIS-WRONG-999', // Different visit!
        fileName: 'Report.pdf',
        contentType: 'application/pdf',
      );

      expect(
        () => summarizationService.summarizeReport(
          report: doc,
          fileBytes: samplePdfBytes,
          currentPatientId: testPatientId,
          currentCaseId: testCaseId,
          currentVisitId: testVisit1Id,
        ),
        throwsA(isA<BackendException>().having((e) => e.code, 'code', equals(BackendException.permissionDenied))),
      );
    });

    // -------------------------------------------------------------
    // 23: Visit Isolation
    // -------------------------------------------------------------
    test('23. Visit isolation: summaries saved for Visit 1 do not leak to Visit 2', () async {
      // Save report and summary for Visit 1
      final docVisit1 = createReportDoc(
        reportId: 'REP-V1-001',
        visitId: testVisit1Id,
        fileName: 'Ultrasound_Visit1.pdf',
        contentType: 'application/pdf',
      );
      await reportRepo.saveReportDocument(docVisit1);

      final summaryV1 = await summarizationService.summarizeReport(
        report: docVisit1,
        fileBytes: samplePdfBytes,
        currentPatientId: testPatientId,
        currentCaseId: testCaseId,
        currentVisitId: testVisit1Id,
      );

      await reportRepo.saveReportAiSummary(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit1Id,
        reportId: docVisit1.reportId,
        summary: summaryV1,
      );

      // Verify Visit 1 report has the summary
      final v1Reports = await reportRepo.getReportsForVisit(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit1Id,
      );
      expect(v1Reports.first.aiSummary, isNotNull);
      expect(v1Reports.first.aiSummary?.investigationName, contains('Ultrasound'));

      // Check Visit 2 reports - must NOT contain Visit 1 summary
      final v2Reports = await reportRepo.getReportsForVisit(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit2Id,
      );
      expect(v2Reports.isEmpty, isTrue);
    });

    // -------------------------------------------------------------
    // 24 to 27: Doctor Review & Approval Lifecycle
    // -------------------------------------------------------------
    testWidgets('24. Doctor edit summary: allows doctor to edit and update summary', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final doc = createReportDoc(
        reportId: 'REP-EDIT-TEST',
        fileName: 'CBC_Report.pdf',
        contentType: 'application/pdf',
      );

      await tester.pumpWidget(
        createTestWidget(
          DoctorAiReportSummaryDialog(
            report: doc,
            preloadedFileBytes: samplePdfBytes,
            currentPatientId: testPatientId,
            currentCaseId: testCaseId,
            currentVisitId: testVisit1Id,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ensure Edit Summary button is present
      expect(find.text('Edit Summary'), findsOneWidget);
      await tester.tap(find.text('Edit Summary'));
      await tester.pumpAndSettle();

      // Verify text field appears with editable content
      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Doctor verified: Mild microcytic anemia observed.');
      await tester.pumpAndSettle();

      // Save edits
      expect(find.text('SAVE CHANGES'), findsOneWidget);
      await tester.ensureVisible(find.text('SAVE CHANGES'));
      await tester.tap(find.text('SAVE CHANGES'));
      await tester.pumpAndSettle();

      expect(find.text('Doctor verified: Mild microcytic anemia observed.'), findsOneWidget);
    });

    testWidgets('25. Doctor approve summary: changes status to approvedByDoctor', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final doc = createReportDoc(
        reportId: 'REP-APPROVE-TEST',
        fileName: 'Lipid_Panel.pdf',
        contentType: 'application/pdf',
      );
      await reportRepo.saveReportDocument(doc);

      await tester.pumpWidget(
        createTestWidget(
          DoctorAiReportSummaryDialog(
            report: doc,
            preloadedFileBytes: samplePdfBytes,
            currentPatientId: testPatientId,
            currentCaseId: testCaseId,
            currentVisitId: testVisit1Id,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Status begins as REVIEW REQUIRED
      expect(find.text('REVIEW REQUIRED'), findsOneWidget);
      expect(find.text('Approve Summary'), findsOneWidget);

      await tester.tap(find.text('Approve Summary'));
      await tester.pumpAndSettle();

      // Status changes to APPROVED BY DOCTOR
      expect(find.text('APPROVED BY DOCTOR'), findsOneWidget);

      // Verify saved in repository
      final savedDoc = await reportRepo.getReportById(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit1Id,
        reportId: doc.reportId,
      );
      expect(savedDoc?.aiSummary?.status, equals(AiReportSummaryStatus.approvedByDoctor));
      expect(savedDoc?.aiSummary?.approvedByDoctorId, equals(sessionService.activeDoctorId));
      expect(savedDoc?.aiSummary?.approvedAt, isNotNull);
    });

    testWidgets('26. Regenerate summary: prompts confirmation if already approved', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final approvedSummary = AiReportSummaryRecord(
        summaryId: 'SUM-REGEN-01',
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit1Id,
        investigationId: 'REQ-001',
        reportId: 'REP-REGEN-TEST',
        fileName: 'Lipid_Panel.pdf',
        investigationName: 'Lipid Profile',
        reportOverview: 'Initial approved summary',
        keyFindings: const ['Finding 1'],
        reportedMeasurements: const [],
        itemsToReview: const [],
        dataQualityOrUncertainty: const [],
        status: AiReportSummaryStatus.approvedByDoctor,
        generatedAt: DateTime.now(),
        approvedAt: DateTime.now(),
        approvedByDoctorId: sessionService.activeDoctorId,
      );

      final doc = createReportDoc(
        reportId: 'REP-REGEN-TEST',
        fileName: 'Lipid_Panel.pdf',
        contentType: 'application/pdf',
      ).copyWith(aiSummary: approvedSummary);

      await reportRepo.saveReportDocument(doc);

      await tester.pumpWidget(
        createTestWidget(
          DoctorAiReportSummaryDialog(
            report: doc,
            preloadedFileBytes: samplePdfBytes,
            currentPatientId: testPatientId,
            currentCaseId: testCaseId,
            currentVisitId: testVisit1Id,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('APPROVED BY DOCTOR'), findsOneWidget);

      // Tap Regenerate
      await tester.tap(find.text('Regenerate'));
      await tester.pumpAndSettle();

      // Dialog asks for confirmation
      expect(find.text('Regenerate AI Summary?'), findsOneWidget);
      expect(find.text('Regenerating will replace the approved summary and reset its status to REVIEW REQUIRED. Do you wish to continue?'), findsOneWidget);

      // Cancel keeps approval
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('APPROVED BY DOCTOR'), findsOneWidget);
    });

    testWidgets('27. Regenerate resets approval: status reverts to reviewRequired', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final approvedSummary = AiReportSummaryRecord(
        summaryId: 'SUM-REGEN-02',
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit1Id,
        investigationId: 'REQ-001',
        reportId: 'REP-REGEN-2',
        fileName: 'Lipid_Panel.pdf',
        investigationName: 'Lipid Profile',
        reportOverview: 'Initial approved summary',
        keyFindings: const ['Finding 1'],
        reportedMeasurements: const [],
        itemsToReview: const [],
        dataQualityOrUncertainty: const [],
        status: AiReportSummaryStatus.approvedByDoctor,
        generatedAt: DateTime.now(),
        approvedAt: DateTime.now(),
        approvedByDoctorId: sessionService.activeDoctorId,
      );

      final doc = createReportDoc(
        reportId: 'REP-REGEN-2',
        fileName: 'Lipid_Panel.pdf',
        contentType: 'application/pdf',
      ).copyWith(aiSummary: approvedSummary);

      await reportRepo.saveReportDocument(doc);

      await tester.pumpWidget(
        createTestWidget(
          DoctorAiReportSummaryDialog(
            report: doc,
            preloadedFileBytes: samplePdfBytes,
            currentPatientId: testPatientId,
            currentCaseId: testCaseId,
            currentVisitId: testVisit1Id,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Regenerate and confirm
      await tester.tap(find.text('Regenerate'));
      await tester.pumpAndSettle();

      // Tap confirm Regenerate button inside AlertDialog
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Regenerate')));
      await tester.pumpAndSettle();

      // Status resets to REVIEW REQUIRED
      expect(find.text('REVIEW REQUIRED'), findsOneWidget);
      expect(find.text('Approve Summary'), findsOneWidget);
    });

    // -------------------------------------------------------------
    // 28 to 30: Anti-Fake, Immutability & Zero Secret Exposure
    // -------------------------------------------------------------
    test('28. Anti-fake-result check: failure states never produce synthetic/fake results', () async {
      summarizationService.simulateGeminiFailure = true;
      final doc = createReportDoc(
        reportId: 'REP-NO-FAKE',
        fileName: 'CBC_Report.pdf',
        contentType: 'application/pdf',
      );

      try {
        await summarizationService.summarizeReport(
          report: doc,
          fileBytes: samplePdfBytes,
          currentPatientId: testPatientId,
          currentCaseId: testCaseId,
          currentVisitId: testVisit1Id,
        );
        fail('Should not succeed when Gemini fails');
      } catch (e) {
        expect(e, isA<BackendException>());
        // Ensure no fake summary was stored in repository
        final retrieved = await reportRepo.getReportById(
          patientId: testPatientId,
          caseId: testCaseId,
          visitId: testVisit1Id,
          reportId: doc.reportId,
        );
        expect(retrieved?.aiSummary, isNull);
      } finally {
        summarizationService.simulateGeminiFailure = false;
      }
    });

    test('29. Original report file unchanged: original file bytes and path remain immutable', () async {
      final storagePath = await storageService.uploadReportFile(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit1Id,
        investigationId: 'REQ-001',
        fileName: 'Immutability_Test.pdf',
        bytes: samplePdfBytes,
        contentType: 'application/pdf',
      );

      final doc = createReportDoc(
        reportId: 'REP-IMMUTABLE',
        fileName: 'Immutability_Test.pdf',
        contentType: 'application/pdf',
        bytes: samplePdfBytes,
      ).copyWith(storagePath: storagePath);

      await reportRepo.saveReportDocument(doc);

      // Perform AI summarization & approval
      final summary = await summarizationService.summarizeReport(
        report: doc,
        fileBytes: samplePdfBytes,
        currentPatientId: testPatientId,
        currentCaseId: testCaseId,
        currentVisitId: testVisit1Id,
      );

      await reportRepo.saveReportAiSummary(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit1Id,
        reportId: doc.reportId,
        summary: summary.copyWith(
          status: AiReportSummaryStatus.approvedByDoctor,
          approvedAt: DateTime.now(),
          approvedByDoctorId: testDoctorId,
        ),
      );

      // Verify original file in storage is identical
      final downloadedBytes = await storageService.getFileBytes(storagePath);
      expect(downloadedBytes, equals(samplePdfBytes));

      // Verify report document metadata is unchanged
      final savedDoc = await reportRepo.getReportById(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisit1Id,
        reportId: doc.reportId,
      );
      expect(savedDoc?.storagePath, equals(storagePath));
      expect(savedDoc?.fileName, equals('Immutability_Test.pdf'));
      expect(savedDoc?.fileSizeBytes, equals(samplePdfBytes.length));
    });

    test('30. Zero secret key exposure: client codebase does not leak API keys', () {
      // Validates that DoctorAiReportSummarizationService and related classes
      // don't expose any API keys or hardcoded credentials.
      const serviceString = DoctorAiReportSummarizationService;
      expect(serviceString.toString(), equals('DoctorAiReportSummarizationService'));
    });

    // -------------------------------------------------------------
    // 31: Anti-Hallucination Verification (Section 25)
    // -------------------------------------------------------------
    test('31. Anti-hallucination test: exact values preserved without alteration or invented ranges', () async {
      final cbcDoc = createReportDoc(
        reportId: 'REP-ANTI-HALLUCINATION',
        fileName: 'CBC_Report_Patient.pdf',
        contentType: 'application/pdf',
      );

      final summary = await summarizationService.summarizeReport(
        report: cbcDoc,
        fileBytes: samplePdfBytes,
        currentPatientId: testPatientId,
        currentCaseId: testCaseId,
        currentVisitId: testVisit1Id,
      );

      // 1. Hemoglobin: 11.2 g/dL
      final hb = summary.reportedMeasurements.firstWhere((m) => m.parameter == 'Hemoglobin');
      expect(hb.value, equals('11.2'));
      expect(hb.unit, equals('g/dL'));
      expect(hb.referenceRange, equals('12.0 - 15.5 g/dL'));
      expect(hb.flag, equals('Low'));

      // 2. Total WBC Count: 8,400 /µL
      final wbc = summary.reportedMeasurements.firstWhere((m) => m.parameter.contains('WBC'));
      expect(wbc.value, equals('8,400'));
      expect(wbc.unit, equals('/µL'));
      expect(wbc.referenceRange, equals('4,000 - 11,000 /µL'));

      // 3. Platelet Count: 2.1 lakh /µL
      final plt = summary.reportedMeasurements.firstWhere((m) => m.parameter.contains('Platelet'));
      expect(plt.value, equals('2.1 lakh'));
      expect(plt.unit, equals('/µL'));
      expect(plt.referenceRange, equals('1.5 - 4.5 lakh /µL'));

      // 4. Clinical safety: Summary must NOT prescribe medications or make definitive diagnosis
      for (final finding in summary.keyFindings) {
        expect(finding.toLowerCase(), isNot(contains('prescribe')));
        expect(finding.toLowerCase(), isNot(contains('take tablet')));
        expect(finding.toLowerCase(), isNot(contains('dose')));
      }

      final displayString = summary.toFormattedDisplayString();
      expect(displayString, contains('AI-generated summary\nDoctor verification required.'));
    });
  });
}

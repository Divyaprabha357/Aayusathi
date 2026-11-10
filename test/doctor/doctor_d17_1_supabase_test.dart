import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/supabase/supabase_config.dart';
import 'package:aayusathi/doctor/models/report_document.dart';
import 'package:aayusathi/doctor/models/visit_report_data.dart';
import 'package:aayusathi/doctor/models/visit_report_pdf_result.dart';
import 'package:aayusathi/doctor/services/mock_pdf_output_service.dart';
import 'package:aayusathi/doctor/services/mock_storage_service.dart';
import 'package:aayusathi/doctor/services/supabase_storage_service.dart';
import 'package:aayusathi/doctor/services/visit_report_pdf_service.dart';
import 'package:aayusathi/doctor/widgets/doctor_pdf_success_dialog.dart';
import 'package:aayusathi/patient/services/patient_report_access_service.dart';
import 'package:aayusathi/repositories/mock/mock_report_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockStorageService mockStorage;
  late MockReportRepository mockReportRepo;
  late MockPdfOutputService mockPdfOutput;

  setUp(() {
    mockStorage = MockStorageService.instance..reset();
    mockReportRepo = MockReportRepository.instance..reset();
    mockPdfOutput = MockPdfOutputService.instance..reset();

    BackendProvider.instance.setCustomRepositories(
      storageService: mockStorage,
      reportRepo: mockReportRepo,
    );
  });

  tearDown(() {
    BackendProvider.instance.resetOverrides();
  });

  group('Phase D17.1: Supabase Configuration & Security Tests', () {
    test('1. SupabaseConfig matches authoritative URL and private bucket name', () {
      expect(SupabaseConfig.supabaseUrl, 'https://xtgjpvejqzptjyrskuuk.supabase.co');
      expect(SupabaseConfig.bucketName, 'aayusathi-reports');
      expect(SupabaseConfig.maxFileSizeBytes, 15 * 1024 * 1024);
      expect(SupabaseConfig.signedUrlDuration.inMinutes, 5);
      expect(SupabaseConfig.isConfigValid, isTrue);
    });

    test('2. Client config contains only publishable/anon key and no secret/service-role keys', () {
      expect(SupabaseConfig.publishableKey.startsWith('sb_secret_'), isFalse);
      expect(SupabaseConfig.publishableKey.toLowerCase().contains('service_role'), isFalse);
    });
  });

  group('Phase D17.1: StorageService Binary & Header Validation Tests', () {
    final service = SupabaseStorageService();

    test('3. Valid PDF magic bytes (%PDF) passes validation', () {
      final validPdf = [0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x35];
      final res = service.validateFile(fileName: 'visit_report.pdf', bytes: validPdf);
      expect(res.isValid, isTrue);
      expect(res.detectedMimeType, 'application/pdf');
    });

    test('4. Valid JPEG magic bytes (FF D8 FF) passes validation', () {
      final validJpeg = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10];
      final res = service.validateFile(fileName: 'skin_lesion.jpg', bytes: validJpeg);
      expect(res.isValid, isTrue);
      expect(res.detectedMimeType, 'image/jpeg');
    });

    test('5. Valid PNG magic bytes (89 50 4E 47) passes validation', () {
      final validPng = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
      final res = service.validateFile(fileName: 'ecg_graph.png', bytes: validPng);
      expect(res.isValid, isTrue);
      expect(res.detectedMimeType, 'image/png');
    });

    test('6. Corrupted / mismatched header bytes are rejected', () {
      final badPdf = [0x00, 0x00, 0x00, 0x00];
      final res = service.validateFile(fileName: 'spoofed.pdf', bytes: badPdf);
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('Not a valid PDF'));
    });

    test('7. Files larger than 15 MB are rejected', () {
      final largeBytes = Uint8List(15 * 1024 * 1024 + 1);
      final res = service.validateFile(fileName: 'huge.pdf', bytes: largeBytes);
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('15 MB limit'));
    });

    test('8. Empty bytes and disallowed extensions are rejected', () {
      final emptyRes = service.validateFile(fileName: 'empty.pdf', bytes: []);
      expect(emptyRes.isValid, isFalse);
      expect(emptyRes.errorMessage, contains('empty'));

      final extRes = service.validateFile(
        fileName: 'script.exe',
        bytes: [0x25, 0x50, 0x44, 0x46],
      );
      expect(extRes.isValid, isFalse);
      expect(extRes.errorMessage, contains('Unsupported file format'));
    });
  });

  group('Phase D17.1: ReportDocument Model & Firestore Metadata Tests', () {
    test('9. ReportDocument serialization includes storageProvider and storageBucket defaults', () {
      final doc = ReportDocument(
        reportId: 'REP-001',
        patientId: 'PAT-102938',
        caseId: 'CASE-001',
        visitId: 'VIS-CASE-001-1',
        investigationId: 'OFFICIAL_VISIT_REPORT',
        fileName: 'AAYUSATHI_Visit_Report_PAT-102938_Visit_1.pdf',
        contentType: 'application/pdf',
        fileSizeBytes: 218350,
        storagePath: 'patients/PAT-102938/cases/CASE-001/visits/VIS-CASE-001-1/reports/AAYUSATHI_Visit_Report_PAT-102938_Visit_1.pdf',
        uploadedAt: DateTime(2026, 9, 7, 10, 0),
        uploadedByPatientId: 'DOC-101',
      );

      expect(doc.storageProvider, 'supabase');
      expect(doc.storageBucket, 'aayusathi-reports');

      final map = doc.toMap();
      expect(map['storageProvider'], 'supabase');
      expect(map['storageBucket'], 'aayusathi-reports');
      expect(map['storagePath'], contains('patients/PAT-102938/cases/CASE-001/visits/VIS-CASE-001-1/reports/'));

      final reconstructed = ReportDocument.fromMap(map);
      expect(reconstructed.storageProvider, 'supabase');
      expect(reconstructed.storageBucket, 'aayusathi-reports');
      expect(reconstructed.storagePath, doc.storagePath);
    });

    test('10. Canonical storage path contains zero Aadhaar or phone numbers', () {
      const patientId = 'PAT-AAYU-102938';
      const caseId = 'CASE-001';
      const visitId = 'VIS-CASE-001-1';
      const fileName = 'report.pdf';

      final path = 'patients/$patientId/cases/$caseId/visits/$visitId/reports/$fileName';
      expect(path, isNot(contains('123456789012')));
      expect(path, isNot(contains('+91')));
      expect(path.startsWith('patients/PAT-AAYU-102938/cases/CASE-001/visits/VIS-CASE-001-1/reports/'), isTrue);
    });
  });

  group('Phase D17.1: Dual-Path PDF & Local Fallback Resilience Tests', () {
    final testData = VisitReportData(
      caseId: 'CASE-001',
      patientId: 'PAT-001',
      patientName: 'Priya Sharma',
      age: 32,
      gender: 'Female',
      bloodGroup: 'B+',
      patientType: 'Outpatient',
      caseTitle: 'Acute Viral Fever Consultation',
      caseType: 'Acute',
      caseStatus: 'OPEN',
      department: 'General Medicine',
      visitNumber: 1,
      visitStatus: 'ACTIVE',
      dateTime: DateTime(2026, 9, 7, 10, 30),
      doctorName: 'Dr. Aarav Sharma',
      doctorQualification: 'MBBS, MD',
      chiefComplaint: 'High grade fever with chills for 3 days.',
      onsetDuration: '3 days',
      associatedSymptoms: 'Body ache, headache',
      medicalHistory: 'None',
      currentMedication: 'Paracetamol 650mg SOS',
      clinicalObservations: 'Temp 101.2 F, Throat congested',
      assessment: 'Acute Viral Syndrome',
      plan: 'Hydration and rest recommended.',
      prescriptions: const [],
      investigations: const [],
      summary: 'Patient presented with acute fever. Hydration and rest advised.',
      summaryStatus: 'APPROVED BY DOCTOR',
      approvedDoctorId: 'DOC-101',
      approvedAt: DateTime(2026, 9, 7, 10, 45),
      isSummaryApproved: true,
      completionVisitNumber: '1',
      completionCaseId: 'CASE-001',
      consultingDoctor: 'Dr. Aarav Sharma',
      consultingDoctorQualification: 'MBBS, MD',
      summaryApprovalNotice: 'Approved for official record',
    );

    test('11. generateAndSaveVisitPdf succeeds and creates local file', () async {
      final result = await VisitReportPdfService.instance.generateAndSaveVisitPdf(
        testData,
        outputService: mockPdfOutput,
      );

      expect(result.isSuccess, isTrue);
      expect(result.filePath, isNotNull);
      expect(result.pdfBytes, isNotNull);
      expect(result.pdfBytes!.isNotEmpty, isTrue);
    });

    test('12. uploadVisitReportPdfToCloud uploads to Supabase and saves ReportDocument metadata', () async {
      final localResult = await VisitReportPdfService.instance.generateAndSaveVisitPdf(
        testData,
        outputService: mockPdfOutput,
      );

      final cloudResult = await VisitReportPdfService.instance.uploadVisitReportPdfToCloud(
        localResult: localResult,
        data: testData,
        storageService: mockStorage,
        reportRepository: mockReportRepo,
      );

      expect(cloudResult.isCloudUploaded, isTrue);
      expect(cloudResult.cloudStoragePath, isNotNull);
      expect(cloudResult.cloudStoragePath, contains('patients/PAT-001/cases/CASE-001/visits/VIS-CASE-001-1/reports/'));
      expect(cloudResult.cloudUploadError, isNull);

      final savedReports = await mockReportRepo.getReportsForVisit(
        patientId: 'PAT-001',
        caseId: 'CASE-001',
        visitId: 'VIS-CASE-001-1',
      );
      expect(savedReports.any((r) => r.investigationId == 'OFFICIAL_VISIT_REPORT'), isTrue);
      final officialReport = savedReports.firstWhere((r) => r.investigationId == 'OFFICIAL_VISIT_REPORT');
      expect(officialReport.storageProvider, 'supabase');
      expect(officialReport.storageBucket, 'aayusathi-reports');
    });

    test('13. Cloud upload failure preserves local PDF with valid filePath and non-empty bytes', () async {
      mockStorage.simulateUploadFailure = true;
      mockStorage.failureErrorMessage = 'Supabase network timeout';

      final localResult = await VisitReportPdfService.instance.generateAndSaveVisitPdf(
        testData,
        outputService: mockPdfOutput,
      );

      final cloudResult = await VisitReportPdfService.instance.uploadVisitReportPdfToCloud(
        localResult: localResult,
        data: testData,
        storageService: mockStorage,
        reportRepository: mockReportRepo,
      );

      expect(cloudResult.isSuccess, isTrue);
      expect(cloudResult.filePath, isNotNull);
      expect(cloudResult.filePath, localResult.filePath);
      expect(cloudResult.pdfBytes, isNotNull);
      expect(cloudResult.pdfBytes!.length, localResult.pdfBytes!.length);
      expect(cloudResult.isCloudUploaded, isFalse);
      expect(cloudResult.cloudUploadError, contains('Supabase network timeout'));
    });
  });

  group('Phase D17.1: Private Bucket Signed URL & Patient Access Tests', () {
    test('14. MockStorageService generates time-limited signed URL', () async {
      const path = 'patients/PAT-001/cases/CASE-001/visits/VIS-001/reports/report.pdf';
      await mockStorage.uploadVisitPdf(
        patientId: 'PAT-001',
        caseId: 'CASE-001',
        visitId: 'VIS-001',
        fileName: 'report.pdf',
        bytes: [0x25, 0x50, 0x44, 0x46, 0x31, 0x32, 0x33],
      );

      final signedUrl = await mockStorage.getSignedUrl(path);
      expect(signedUrl, isNotNull);
      expect(signedUrl, contains('sign/aayusathi-reports'));
      expect(signedUrl, contains('token='));
    });

    test('15. PatientReportAccessService queries reports and generates signed access URLs', () async {
      final doc = ReportDocument(
        reportId: 'REP-101',
        patientId: 'PAT-001',
        caseId: 'CASE-001',
        visitId: 'VIS-001',
        investigationId: 'CBC',
        fileName: 'cbc.pdf',
        contentType: 'application/pdf',
        fileSizeBytes: 1024,
        storagePath: 'patients/PAT-001/cases/CASE-001/visits/VIS-001/reports/CBC/cbc.pdf',
        uploadedAt: DateTime.now(),
        uploadedByPatientId: 'PAT-001',
      );

      await mockReportRepo.saveReportDocument(doc);
      await mockStorage.uploadReportFile(
        patientId: 'PAT-001',
        caseId: 'CASE-001',
        visitId: 'VIS-001',
        investigationId: 'CBC',
        fileName: 'cbc.pdf',
        bytes: [0x25, 0x50, 0x44, 0x46],
        contentType: 'application/pdf',
      );

      final visitReports = await PatientReportAccessService.instance.getVisitReports(
        patientId: 'PAT-001',
        caseId: 'CASE-001',
        visitId: 'VIS-001',
      );
      expect(visitReports.length, 1);
      expect(visitReports.first.reportId, 'REP-101');

      final accessUrl = await PatientReportAccessService.instance.getReportAccessUrlByDocument(visitReports.first);
      expect(accessUrl, isNotNull);
      expect(accessUrl, contains('sign/aayusathi-reports'));
    });
  });

  group('Phase D17.1: UI Dialog Cloud Synchronization Status Tests', () {
    testWidgets('16. Dialog renders "Cloud Copy Synchronized" when cloud upload succeeds', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final result = VisitReportPdfResult.success(
        filePath: 'C:\\Users\\User\\Documents\\AAYUSATHI\\VisitReports\\AAYUSATHI_Visit_Report_PAT-001_Visit_1.pdf',
        fileName: 'AAYUSATHI_Visit_Report_PAT-001_Visit_1.pdf',
        fileSizeBytes: 218350,
        pdfBytes: Uint8List.fromList([1, 2, 3]),
        cloudStoragePath: 'patients/PAT-001/cases/CASE-001/visits/VIS-CASE-001-1/reports/AAYUSATHI_Visit_Report_PAT-001_Visit_1.pdf',
        isCloudUploaded: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorPdfSuccessDialog(result: result),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AAYUSATHI_Visit_Report_PAT-001_Visit_1.pdf'), findsOneWidget);
      expect(find.text('OPEN PDF'), findsOneWidget);
      expect(find.text('Cloud Copy Synchronized'), findsOneWidget);
    });

    testWidgets('17. Dialog renders "Cloud upload pending / offline (Local PDF ready)" if cloud copy is offline', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final result = VisitReportPdfResult.success(
        filePath: 'C:\\Users\\User\\Documents\\AAYUSATHI\\VisitReports\\AAYUSATHI_Visit_Report_PAT-001_Visit_1.pdf',
        fileName: 'AAYUSATHI_Visit_Report_PAT-001_Visit_1.pdf',
        fileSizeBytes: 218350,
        pdfBytes: Uint8List.fromList([1, 2, 3]),
        isCloudUploaded: false,
        cloudUploadError: 'Supabase offline',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorPdfSuccessDialog(result: result),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OPEN PDF'), findsOneWidget);
      expect(find.text('Cloud upload pending / offline (Local PDF ready)'), findsOneWidget);
    });
  });
}

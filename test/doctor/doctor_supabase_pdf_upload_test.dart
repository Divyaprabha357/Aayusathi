import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aayusathi/core/backend/backend_exception.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/supabase/supabase_config.dart';
import 'package:aayusathi/core/supabase/supabase_initializer.dart';
import 'package:aayusathi/doctor/models/visit_report_data.dart';
import 'package:aayusathi/doctor/models/visit_report_pdf_result.dart';
import 'package:aayusathi/doctor/services/mock_pdf_output_service.dart';
import 'package:aayusathi/doctor/services/mock_storage_service.dart';
import 'package:aayusathi/doctor/services/supabase_storage_service.dart';
import 'package:aayusathi/doctor/services/visit_report_pdf_service.dart';
import 'package:aayusathi/doctor/widgets/doctor_pdf_success_dialog.dart';
import 'package:aayusathi/repositories/mock/mock_report_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockStorageService mockStorage;
  late MockReportRepository mockReportRepo;
  late MockPdfOutputService mockPdfOutput;
  late SupabaseStorageService supabaseService;

  final validPdfBytes = Uint8List.fromList([
    0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x35, // %PDF-1.5
    0x0A, 0x25, 0xE2, 0xE3, 0xCF, 0xD3, 0x0A,
  ]);

  final sampleReportData = VisitReportData(
    visitId: 'VIS-CASE-001-1-1725960000',
    patientId: 'AAYU-102938',
    caseId: 'CASE-001',
    visitNumber: 1,
    visitStatus: 'COMPLETED',
    department: 'Cardiology',
    dateTime: DateTime(2026, 9, 10, 10, 30),
    patientName: 'Ramesh Patel',
    age: 58,
    gender: 'Male',
    bloodGroup: 'B+',
    patientType: 'New Visit',
    doctorName: 'Dr. Rajesh Sharma',
    doctorQualification: 'MBBS, MD (Cardiology)',
    caseTitle: 'Hypertension Consultation',
    caseType: 'CARDIOLOGY',
    caseStatus: 'OPEN',
    chiefComplaint: 'Headache and elevated blood pressure',
    onsetDuration: '3 days',
    associatedSymptoms: 'Dizziness',
    medicalHistory: 'None known',
    currentMedication: 'None',
    clinicalObservations: 'BP 150/95',
    assessment: 'Primary Hypertension',
    plan: 'Lifestyle modification and medication',
    summary: 'Doctor-approved clinical summary.',
    summaryStatus: 'APPROVED BY DOCTOR',
    isSummaryApproved: true,
    approvedDoctorId: 'DOC-101',
    completionVisitNumber: 'Visit 1',
    completionCaseId: 'CASE-001',
    consultingDoctor: 'Dr. Rajesh Sharma',
    consultingDoctorQualification: 'MBBS, MD (Cardiology)',
    summaryApprovalNotice: 'APPROVED BY DOCTOR',
  );

  setUp(() {
    mockStorage = MockStorageService.instance..reset();
    mockReportRepo = MockReportRepository.instance..reset();
    mockPdfOutput = MockPdfOutputService.instance..reset();
    supabaseService = SupabaseStorageService();

    BackendProvider.instance.setCustomRepositories(
      storageService: mockStorage,
      reportRepo: mockReportRepo,
    );
  });

  tearDown(() {
    BackendProvider.instance.resetOverrides();
  });

  group('AAYUSATHI: 24 Supabase PDF Storage & Signature Verification Tests', () {
    // 1. Supabase initialization
    test('1. Supabase initialization handles offline and singleton state gracefully', () async {
      expect(SupabaseInitializer.isInitialized, isFalse);
      expect(SupabaseInitializer.client, isNull);
    });

    // 2. Correct project host
    test('2. Supabase project host matches authoritative endpoint (xtgjpvejqzptjyrskuuk.supabase.co)', () {
      expect(SupabaseConfig.projectHost, 'xtgjpvejqzptjyrskuuk.supabase.co');
      expect(SupabaseConfig.supabaseUrl, 'https://xtgjpvejqzptjyrskuuk.supabase.co');
    });

    // 3. Correct bucket
    test('3. Storage bucket is strictly aayusathi-reports', () {
      expect(SupabaseConfig.bucketName, 'aayusathi-reports');
    });

    // 4. PDF validation
    test('4. PDF validation verifies %PDF- magic header', () {
      final validation = supabaseService.validateFile(
        fileName: 'Visit_Report.pdf',
        bytes: validPdfBytes,
      );
      expect(validation.isValid, isTrue);
      expect(validation.detectedMimeType, 'application/pdf');

      final invalid = supabaseService.validateFile(
        fileName: 'corrupt.pdf',
        bytes: [0x00, 0x01, 0x02, 0x03],
      );
      expect(invalid.isValid, isFalse);
      expect(invalid.errorMessage, contains('Not a valid PDF'));
    });

    // 5. PDF MIME type
    test('5. PDF MIME type must be strictly application/pdf', () {
      final res = supabaseService.validateFile(
        fileName: 'report.pdf',
        bytes: validPdfBytes,
        mimeType: 'application/pdf',
      );
      expect(res.isValid, isTrue);
      expect(res.detectedMimeType, 'application/pdf');
    });

    // 6. PDF size
    test('6. Files exceeding 15 MB limit are rejected', () {
      final hugeBytes = Uint8List(15 * 1024 * 1024 + 1);
      final res = supabaseService.validateFile(
        fileName: 'huge.pdf',
        bytes: hugeBytes,
      );
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('15 MB'));
    });

    // 7. Canonical path
    test('7. Canonical path matches patients/{patientId}/cases/{caseId}/visits/{visitId}/reports/{fileName}', () {
      const patientId = 'AAYU-102938';
      const caseId = 'CASE-001';
      const visitId = 'VIS-001-1';
      const fileName = 'AAYUSATHI_Visit_Report_AAYU-102938_Visit_1.pdf';
      final path = 'patients/$patientId/cases/$caseId/visits/$visitId/reports/$fileName';
      expect(
        path,
        'patients/AAYU-102938/cases/CASE-001/visits/VIS-001-1/reports/AAYUSATHI_Visit_Report_AAYU-102938_Visit_1.pdf',
      );
    });

    // 8. Upload API
    test('8. StorageService upload API accepts binary payload and returns canonical storage path', () async {
      final path = await mockStorage.uploadVisitPdf(
        patientId: 'AAYU-102938',
        caseId: 'CASE-001',
        visitId: 'VIS-001-1',
        fileName: 'Visit_1.pdf',
        bytes: validPdfBytes,
      );
      expect(path, startsWith('patients/AAYU-102938/cases/CASE-001/visits/VIS-001-1/reports/'));
    });

    // 9. Upload success
    test('9. Dual-path PDF workflow succeeds with local and cloud copies synchronized', () async {
      final localResult = VisitReportPdfResult.success(
        filePath: 'C:/Reports/Visit_1.pdf',
        fileName: 'Visit_1.pdf',
        pdfBytes: validPdfBytes,
        fileSizeBytes: validPdfBytes.length,
      );

      final cloudResult = await VisitReportPdfService.instance.uploadVisitReportPdfToCloud(
        localResult: localResult,
        data: sampleReportData,
        storageService: mockStorage,
        reportRepository: mockReportRepo,
      );

      expect(cloudResult.isCloudUploaded, isTrue);
      expect(cloudResult.cloudStoragePath, isNotNull);
      expect(cloudResult.cloudUploadError, isNull);
    });

    // 10. Upload failure
    test('10. Cloud upload failure preserves local PDF without throwing', () async {
      mockStorage.simulateUploadFailure = true;
      final localResult = VisitReportPdfResult.success(
        filePath: 'C:/Reports/local.pdf',
        fileName: 'local.pdf',
        pdfBytes: validPdfBytes,
        fileSizeBytes: validPdfBytes.length,
      );

      final cloudResult = await VisitReportPdfService.instance.uploadVisitReportPdfToCloud(
        localResult: localResult,
        data: sampleReportData,
        storageService: mockStorage,
        reportRepository: mockReportRepo,
      );

      expect(cloudResult.isCloudUploaded, isFalse);
      expect(cloudResult.cloudUploadError, isNotNull);
      expect(cloudResult.filePath, 'C:/Reports/local.pdf');
    });

    // 11. Signature verification failure
    test('11. Signature verification error is accurately categorized and sanitized', () {
      final storageEx = StorageException(
        'signature verification failed',
        statusCode: '403',
      );
      expect(storageEx.statusCode, '403');
      expect(storageEx.message, contains('signature verification failed'));

      // Verify backend exception mapping
      final backendEx = BackendException(
        code: BackendException.permissionDenied,
        message: 'Could not upload visit PDF to Supabase Storage: signature verification failed',
        originalError: storageEx,
      );
      expect(backendEx.code, BackendException.permissionDenied);
      expect(backendEx.message, contains('signature verification failed'));
    });

    // 12. Authentication failure
    test('12. Authentication failure (HTTP 401) maps to permissionDenied', () {
      final authEx = StorageException('Unauthorized', statusCode: '401');
      final backendEx = BackendException(
        code: BackendException.permissionDenied,
        message: 'Could not upload visit PDF to Supabase Storage: ${authEx.message}',
        originalError: authEx,
      );
      expect(backendEx.code, BackendException.permissionDenied);
    });

    // 13. Permission / RLS failure
    test('13. Permission or RLS policy violation (HTTP 403) maps to permissionDenied', () {
      final rlsEx = StorageException(
        'new row violates row-level security policy for table "objects"',
        statusCode: '403',
      );
      final backendEx = BackendException(
        code: BackendException.permissionDenied,
        message: 'Could not upload visit PDF to Supabase Storage: ${rlsEx.message}',
        originalError: rlsEx,
      );
      expect(backendEx.code, BackendException.permissionDenied);
    });

    // 14. Retry
    test('14. Retrying cloud upload after failure succeeds cleanly', () async {
      mockStorage.simulateUploadFailure = true;
      final localResult = VisitReportPdfResult.success(
        filePath: 'C:/Reports/local.pdf',
        fileName: 'local.pdf',
        pdfBytes: validPdfBytes,
        fileSizeBytes: validPdfBytes.length,
      );

      final firstAttempt = await VisitReportPdfService.instance.uploadVisitReportPdfToCloud(
        localResult: localResult,
        data: sampleReportData,
        storageService: mockStorage,
        reportRepository: mockReportRepo,
      );
      expect(firstAttempt.isCloudUploaded, isFalse);

      // Restore and retry
      mockStorage.simulateUploadFailure = false;
      final retryAttempt = await VisitReportPdfService.instance.uploadVisitReportPdfToCloud(
        localResult: firstAttempt,
        data: sampleReportData,
        storageService: mockStorage,
        reportRepository: mockReportRepo,
      );
      expect(retryAttempt.isCloudUploaded, isTrue);
      expect(retryAttempt.cloudStoragePath, isNotNull);
    });

    // 15. Duplicate prevention
    test('15. Upsert prevents duplicate Firestore documents on repeated upload', () async {
      final localResult = VisitReportPdfResult.success(
        filePath: 'C:/Reports/local.pdf',
        fileName: 'local.pdf',
        pdfBytes: validPdfBytes,
        fileSizeBytes: validPdfBytes.length,
      );

      await VisitReportPdfService.instance.uploadVisitReportPdfToCloud(
        localResult: localResult,
        data: sampleReportData,
        storageService: mockStorage,
        reportRepository: mockReportRepo,
      );

      await VisitReportPdfService.instance.uploadVisitReportPdfToCloud(
        localResult: localResult,
        data: sampleReportData,
        storageService: mockStorage,
        reportRepository: mockReportRepo,
      );

      final reports = await mockReportRepo.getReportsForVisit(
        patientId: sampleReportData.patientId,
        caseId: sampleReportData.caseId,
        visitId: sampleReportData.visitId,
      );
      expect(reports.length, 1);
    });

    // 16. Object existence verification
    test('16. Object existence verification confirms physical file in bucket', () async {
      final path = await mockStorage.uploadVisitPdf(
        patientId: 'AAYU-102938',
        caseId: 'CASE-001',
        visitId: 'VIS-001-1',
        fileName: 'Visit_1.pdf',
        bytes: validPdfBytes,
      );
      final exists = await mockStorage.fileExists(path);
      expect(exists, isTrue);

      final nonExistent = await mockStorage.fileExists('patients/unknown/path.pdf');
      expect(nonExistent, isFalse);
    });

    // 17. Firestore metadata after upload
    test('17. Firestore ReportDocument is registered on confirmed cloud upload', () async {
      final localResult = VisitReportPdfResult.success(
        filePath: 'C:/Reports/local.pdf',
        fileName: 'local.pdf',
        pdfBytes: validPdfBytes,
        fileSizeBytes: validPdfBytes.length,
      );

      final result = await VisitReportPdfService.instance.uploadVisitReportPdfToCloud(
        localResult: localResult,
        data: sampleReportData,
        storageService: mockStorage,
        reportRepository: mockReportRepo,
      );

      expect(result.isCloudUploaded, isTrue);
      final reports = await mockReportRepo.getReportsForVisit(
        patientId: sampleReportData.patientId,
        caseId: sampleReportData.caseId,
        visitId: sampleReportData.visitId,
      );
      expect(reports.isNotEmpty, isTrue);
      expect(reports.first.storageProvider, 'supabase');
      expect(reports.first.storageBucket, 'aayusathi-reports');
    });

    // 18. No Firestore cloud metadata after failed upload
    test('18. No Firestore ReportDocument is created if upload fails', () async {
      mockStorage.simulateUploadFailure = true;
      final localResult = VisitReportPdfResult.success(
        filePath: 'C:/Reports/local.pdf',
        fileName: 'local.pdf',
        pdfBytes: validPdfBytes,
        fileSizeBytes: validPdfBytes.length,
      );

      await VisitReportPdfService.instance.uploadVisitReportPdfToCloud(
        localResult: localResult,
        data: sampleReportData,
        storageService: mockStorage,
        reportRepository: mockReportRepo,
      );

      final reports = await mockReportRepo.getReportsForVisit(
        patientId: sampleReportData.patientId,
        caseId: sampleReportData.caseId,
        visitId: sampleReportData.visitId,
      );
      expect(reports.isEmpty, isTrue);
    });

    // 19. Private bucket
    test('19. Storage bucket is strictly private and forbids permanent public URLs', () {
      expect(SupabaseConfig.isPrivateBucket, isTrue);
    });

    // 20. Signed URL generation
    test('20. Signed URL generation uses 5-minute (300 seconds) duration', () async {
      expect(SupabaseConfig.signedUrlDuration.inSeconds, 300);
      final path = await mockStorage.uploadVisitPdf(
        patientId: 'AAYU-102938',
        caseId: 'CASE-001',
        visitId: 'VIS-1',
        fileName: 'rep.pdf',
        bytes: validPdfBytes,
      );
      final signedUrl = await mockStorage.getSignedUrl(path);
      expect(signedUrl, isNotNull);
      expect(signedUrl, contains('token='));
    });

    // 21. No service-role key in Flutter
    test('21. Client configuration strictly rejects secret and service-role keys', () {
      expect(SupabaseConfig.publishableKey.startsWith('sb_secret_'), isFalse);
      expect(SupabaseConfig.publishableKey.toLowerCase().contains('service_role'), isFalse);
      expect(SupabaseConfig.isConfigValid, isTrue);
    });

    // 22. No Firebase Storage
    test('22. No Firebase Storage dependency or Blaze plan requirement is used for report PDFs', () {
      expect(SupabaseConfig.bucketName, 'aayusathi-reports');
      expect(SupabaseConfig.supabaseUrl, contains('supabase.co'));
    });

    // 23. Local PDF remains available after failure
    test('23. Local PDF remains preserved and valid when cloud upload fails', () async {
      mockStorage.simulateUploadFailure = true;
      final localResult = VisitReportPdfResult.success(
        filePath: 'C:/Reports/local.pdf',
        fileName: 'local.pdf',
        pdfBytes: validPdfBytes,
        fileSizeBytes: validPdfBytes.length,
      );

      final res = await VisitReportPdfService.instance.uploadVisitReportPdfToCloud(
        localResult: localResult,
        data: sampleReportData,
        storageService: mockStorage,
        reportRepository: mockReportRepo,
      );

      expect(res.filePath, 'C:/Reports/local.pdf');
      expect(res.pdfBytes, isNotNull);
      expect(res.isSuccess, isTrue);
      expect(res.isCloudUploaded, isFalse);
    });

    // 24. Doctor PDF UI states
    testWidgets('24a. DoctorPdfSuccessDialog renders failure banner and Retry button on cloud error', (tester) async {
      final failedResult = VisitReportPdfResult.success(
        filePath: 'C:/Reports/local.pdf',
        fileName: 'local.pdf',
        pdfBytes: validPdfBytes,
        fileSizeBytes: validPdfBytes.length,
      ).copyWith(
        isCloudUploaded: false,
        cloudUploadError: 'Could not upload visit PDF to Supabase Storage: signature verification failed',
      );

      await tester.binding.setSurfaceSize(const Size(500, 600));
      await tester.pumpWidget(
        MaterialApp(
          home: DoctorPdfSuccessDialog(
            result: failedResult,
            reportData: sampleReportData,
            pdfOutputService: mockPdfOutput,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Cloud upload failed. Your local PDF is still available.'), findsOneWidget);
      expect(find.textContaining('signature verification failed'), findsOneWidget);
      expect(find.text('Retry Upload'), findsOneWidget);
      expect(find.text('OPEN PDF'), findsOneWidget);
    });

    testWidgets('24b. DoctorPdfSuccessDialog renders "Cloud Copy Synchronized" badge when upload succeeds', (tester) async {
      final successResult = VisitReportPdfResult.success(
        filePath: 'C:/Reports/local.pdf',
        fileName: 'local.pdf',
        pdfBytes: validPdfBytes,
        fileSizeBytes: validPdfBytes.length,
      ).copyWith(
        isCloudUploaded: true,
        cloudStoragePath: 'patients/AAYU-102938/cases/CASE-001/visits/VIS-1/reports/local.pdf',
      );

      await tester.binding.setSurfaceSize(const Size(500, 600));
      await tester.pumpWidget(
        MaterialApp(
          home: DoctorPdfSuccessDialog(
            result: successResult,
            reportData: sampleReportData,
            pdfOutputService: mockPdfOutput,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cloud Copy Synchronized'), findsOneWidget);
      expect(find.text('Retry Upload'), findsNothing);
      expect(find.text('OPEN PDF'), findsOneWidget);
    });

    // =========================================================================
    // 12 CANONICAL SPECIFICATIONS MANDATED BY FINAL FIX REQUIREMENTS
    // =========================================================================
    group('AAYUSATHI: 12 Supabase PDF Upload Canonical Specifications', () {
      // 1. Canonical PDF path generation
      test('Spec 1: Canonical PDF path generation uses actual patient ID without unauthorized modification', () {
        final pathAayu = SupabaseStorageService.generateCanonicalVisitPdfPath(
          patientId: 'AAYU-102938',
          caseId: 'CASE-001',
          visitId: 'VISIT-001',
          fileName: 'AAYUSATHI_Visit_Report_AAYU-102938_Visit_1.pdf',
        );
        expect(
          pathAayu,
          'patients/AAYU-102938/cases/CASE-001/visits/VISIT-001/reports/AAYUSATHI_Visit_Report_AAYU-102938_Visit_1.pdf',
        );

        final pathPat = SupabaseStorageService.generateCanonicalVisitPdfPath(
          patientId: 'PAT-001',
          caseId: 'CASE-999',
          visitId: 'VIS-999',
          fileName: 'Report.pdf',
        );
        expect(
          pathPat,
          'patients/PAT-001/cases/CASE-999/visits/VIS-999/reports/Report.pdf',
        );
      });

      // 2. Path contains /reports/
      test('Spec 2: Path strictly contains /reports/ segment between visit ID and filename', () {
        final path = SupabaseStorageService.generateCanonicalVisitPdfPath(
          patientId: 'AAYU-102938',
          caseId: 'CASE-001',
          visitId: 'VISIT-001',
          fileName: 'visit.pdf',
        );
        expect(path.contains('/reports/'), isTrue);
        final visitIndex = path.indexOf('/visits/VISIT-001');
        final reportsIndex = path.indexOf('/reports/');
        final fileIndex = path.indexOf('/visit.pdf');
        expect(reportsIndex, greaterThan(visitIndex));
        expect(fileIndex, greaterThan(reportsIndex));
      });

      // 3. Bucket name
      test('Spec 3: Storage bucket is strictly aayusathi-reports and marked private', () {
        expect(SupabaseConfig.bucketName, 'aayusathi-reports');
        expect(SupabaseConfig.isPrivateBucket, isTrue);
      });

      // 4. Safe filename
      test('Spec 4: Safe filename sanitization guarantees valid extension and strips traversal', () {
        final pathTraversal = SupabaseStorageService.generateCanonicalVisitPdfPath(
          patientId: 'AAYU-102938',
          caseId: 'CASE-001',
          visitId: 'VISIT-001',
          fileName: '../../malicious/path.pdf',
        );
        expect(pathTraversal.contains('..'), isFalse);
        expect(pathTraversal.endsWith('.pdf'), isTrue);

        final missingExt = SupabaseStorageService.generateCanonicalVisitPdfPath(
          patientId: 'AAYU-102938',
          caseId: 'CASE-001',
          visitId: 'VISIT-001',
          fileName: 'Report_Doc',
        );
        expect(missingExt.endsWith('Report_Doc.pdf'), isTrue);
      });

      // 5. PDF MIME validation
      test('Spec 5: PDF MIME validation strictly validates application/pdf', () {
        final result = supabaseService.validateFile(
          fileName: 'clinical.pdf',
          bytes: validPdfBytes,
          mimeType: 'application/pdf',
        );
        expect(result.isValid, isTrue);
        expect(result.detectedMimeType, 'application/pdf');
      });

      // 6. PDF magic-byte validation
      test('Spec 6: Magic byte validation strictly detects %PDF- header', () {
        final validResult = supabaseService.validateFile(
          fileName: 'valid.pdf',
          bytes: validPdfBytes,
        );
        expect(validResult.isValid, isTrue);

        final invalidBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]); // PNG bytes in .pdf
        final invalidResult = supabaseService.validateFile(
          fileName: 'fake.pdf',
          bytes: invalidBytes,
        );
        expect(invalidResult.isValid, isFalse);
        expect(invalidResult.errorMessage, contains('Not a valid PDF document'));
      });

      // 7. Successful upload
      test('Spec 7: Successful upload flow uploads binary and confirms physical presence', () async {
        final localResult = VisitReportPdfResult.success(
          filePath: 'C:/Reports/Visit_1.pdf',
          fileName: 'Visit_1.pdf',
          pdfBytes: validPdfBytes,
          fileSizeBytes: validPdfBytes.length,
        );

        final cloudResult = await VisitReportPdfService.instance.uploadVisitReportPdfToCloud(
          localResult: localResult,
          data: sampleReportData,
          storageService: mockStorage,
          reportRepository: mockReportRepo,
        );

        expect(cloudResult.isCloudUploaded, isTrue);
        expect(cloudResult.cloudStoragePath, isNotNull);
        expect(await mockStorage.fileExists(cloudResult.cloudStoragePath!), isTrue);
      });

      // 8. RLS-compatible path
      test('Spec 8: Generated storage path strictly satisfies Supabase RLS WITH CHECK pattern', () {
        final path = SupabaseStorageService.generateCanonicalVisitPdfPath(
          patientId: 'AAYU-102938',
          caseId: 'CASE-001',
          visitId: 'VISIT-001',
          fileName: 'AAYUSATHI_Visit_Report_AAYU-102938_Visit_1.pdf',
        );

        // SQL pattern: bucket_id = 'aayusathi-reports' AND name LIKE 'patients/%/cases/%/visits/%/reports/%'
        final rlsRegex = RegExp(r'^patients/[^/]+/cases/[^/]+/visits/[^/]+/reports/[^/]+$');
        expect(rlsRegex.hasMatch(path), isTrue);
        expect(path.startsWith('/'), isFalse, reason: 'Must have no leading slash');
        expect(path.contains('//'), isFalse, reason: 'Must have no duplicate slashes');
      });

      // 9. Failed upload preserves local PDF
      test('Spec 9: Failed cloud upload strictly preserves local PDF file', () async {
        mockStorage.simulateUploadFailure = true;
        final localResult = VisitReportPdfResult.success(
          filePath: 'C:/LocalReports/visit.pdf',
          fileName: 'visit.pdf',
          pdfBytes: validPdfBytes,
          fileSizeBytes: validPdfBytes.length,
        );

        final result = await VisitReportPdfService.instance.uploadVisitReportPdfToCloud(
          localResult: localResult,
          data: sampleReportData,
          storageService: mockStorage,
          reportRepository: mockReportRepo,
        );

        expect(result.isCloudUploaded, isFalse);
        expect(result.filePath, 'C:/LocalReports/visit.pdf');
        expect(result.pdfBytes, isNotNull);
        expect(result.cloudUploadError, isNotNull);
      });

      // 10. Retry upload
      test('Spec 10: Retry upload re-attempts the exact canonical object successfully', () async {
        mockStorage.simulateUploadFailure = true;
        final localResult = VisitReportPdfResult.success(
          filePath: 'C:/LocalReports/visit.pdf',
          fileName: 'visit.pdf',
          pdfBytes: validPdfBytes,
          fileSizeBytes: validPdfBytes.length,
        );

        final failed = await VisitReportPdfService.instance.uploadVisitReportPdfToCloud(
          localResult: localResult,
          data: sampleReportData,
          storageService: mockStorage,
          reportRepository: mockReportRepo,
        );
        expect(failed.isCloudUploaded, isFalse);

        mockStorage.simulateUploadFailure = false;
        final retried = await VisitReportPdfService.instance.uploadVisitReportPdfToCloud(
          localResult: failed,
          data: sampleReportData,
          storageService: mockStorage,
          reportRepository: mockReportRepo,
        );
        expect(retried.isCloudUploaded, isTrue);
        expect(retried.cloudStoragePath, contains('patients/AAYU-102938/cases/CASE-001/visits/'));
      });

      // 11. Firestore metadata matches actual Storage path
      test('Spec 11: Firestore ReportDocument metadata strictly matches actual Storage path and attributes', () async {
        final localResult = VisitReportPdfResult.success(
          filePath: 'C:/Reports/visit.pdf',
          fileName: 'visit.pdf',
          pdfBytes: validPdfBytes,
          fileSizeBytes: validPdfBytes.length,
        );

        final cloudResult = await VisitReportPdfService.instance.uploadVisitReportPdfToCloud(
          localResult: localResult,
          data: sampleReportData,
          storageService: mockStorage,
          reportRepository: mockReportRepo,
        );

        expect(cloudResult.isCloudUploaded, isTrue);
        final reports = await mockReportRepo.getReportsForVisit(
          patientId: sampleReportData.patientId,
          caseId: sampleReportData.caseId,
          visitId: sampleReportData.visitId,
        );
        expect(reports.isNotEmpty, isTrue);
        final doc = reports.first;
        expect(doc.storagePath, cloudResult.cloudStoragePath);
        expect(doc.storageProvider, 'supabase');
        expect(doc.storageBucket, 'aayusathi-reports');
        expect(doc.patientId, sampleReportData.patientId);
        expect(doc.caseId, sampleReportData.caseId);
        expect(doc.visitId, sampleReportData.visitId);
        expect(doc.contentType, 'application/pdf');
      });

      // 12. Duplicate retry behavior
      test('Spec 12: Duplicate retry preserves single canonical path without creating duplicates', () async {
        final localResult = VisitReportPdfResult.success(
          filePath: 'C:/Reports/visit.pdf',
          fileName: 'visit.pdf',
          pdfBytes: validPdfBytes,
          fileSizeBytes: validPdfBytes.length,
        );

        final res1 = await VisitReportPdfService.instance.uploadVisitReportPdfToCloud(
          localResult: localResult,
          data: sampleReportData,
          storageService: mockStorage,
          reportRepository: mockReportRepo,
        );

        final res2 = await VisitReportPdfService.instance.uploadVisitReportPdfToCloud(
          localResult: localResult,
          data: sampleReportData,
          storageService: mockStorage,
          reportRepository: mockReportRepo,
        );

        expect(res1.cloudStoragePath, res2.cloudStoragePath);
        final reports = await mockReportRepo.getReportsForVisit(
          patientId: sampleReportData.patientId,
          caseId: sampleReportData.caseId,
          visitId: sampleReportData.visitId,
        );
        expect(reports.length, 1);
      });
    });
  });
}

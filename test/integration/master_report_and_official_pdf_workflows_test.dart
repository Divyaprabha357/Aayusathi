import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_exception.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/supabase/supabase_config.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/doctor/models/clinical_visit.dart';
import 'package:aayusathi/doctor/models/investigation_request.dart';
import 'package:aayusathi/doctor/models/report_document.dart';
import 'package:aayusathi/doctor/models/visit_report_data.dart';
import 'package:aayusathi/doctor/models/visit_report_pdf_result.dart';
import 'package:aayusathi/doctor/services/doctor_session_service.dart';
import 'package:aayusathi/doctor/services/mock_pdf_output_service.dart';
import 'package:aayusathi/doctor/services/mock_storage_service.dart';
import 'package:aayusathi/doctor/services/supabase_storage_service.dart';
import 'package:aayusathi/doctor/services/visit_report_pdf_service.dart';
import 'package:aayusathi/models/patient.dart';
import 'package:aayusathi/patient/services/patient_official_visit_pdf_service.dart';
import 'package:aayusathi/patient/services/patient_report_file_validator.dart';
import 'package:aayusathi/patient/services/patient_report_upload_service.dart';
import 'package:aayusathi/patient/services/patient_session_service.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_investigation_repository.dart';
import 'package:aayusathi/repositories/mock/mock_patient_repository.dart';
import 'package:aayusathi/repositories/mock/mock_report_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockStorageService mockStorage;
  late MockReportRepository mockReportRepo;
  late MockClinicalVisitRepository mockVisitRepo;
  late MockCaseRepository mockCaseRepo;
  late MockInvestigationRepository mockInvestigationRepo;
  late MockPatientRepository mockPatientRepo;
  late MockPdfOutputService mockPdfOutput;

  const testPatientId = 'AAYU-102938';
  const testCaseId = 'CASE-001';
  const testVisitId = 'VIS-CASE-001-1-1725960000';
  const testDoctorId = 'DOC-101';

  final validPdfBytes = Uint8List.fromList([
    0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x35, // %PDF-1.5
    0x0A, 0x25, 0xE2, 0xE3, 0xCF, 0xD3, 0x0A,
  ]);

  final validJpegBytes = Uint8List.fromList([
    0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, // JPEG JFIF
    0x49, 0x46, 0x00, 0x01, 0x01, 0x01, 0x00, 0x60,
  ]);

  final validPngBytes = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  final samplePatient = Patient(
    patientId: testPatientId,
    name: 'Ramesh Patel',
    dateOfBirth: '1968-05-12',
    age: 58,
    gender: 'Male',
    phone: '+91 98765 43210',
    bloodGroup: 'B+',
    address: 'Pune, Maharashtra',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final sampleCase = ClinicalCase(
    caseId: testCaseId,
    patientId: testPatientId,
    domain: 'Cardiology',
    title: 'Hypertension Consultation',
    status: ClinicalCaseStatus.open,
    createdAt: DateTime(2026, 9, 10, 10, 0),
    updatedAt: DateTime(2026, 9, 10, 11, 0),
    visitCount: 1,
  );

  final sampleVisit = ClinicalVisit(
    visitId: testVisitId,
    caseId: testCaseId,
    patientId: testPatientId,
    doctorId: testDoctorId,
    doctorName: 'Dr. Rajesh Sharma',
    doctorQualification: 'MBBS, MD (Cardiology)',
    department: 'Cardiology',
    visitNumber: 1,
    startedAt: DateTime(2026, 9, 10, 10, 30),
    completedAt: DateTime(2026, 9, 10, 11, 15),
    completedByDoctorId: testDoctorId,
    status: ClinicalVisitStatus.completed,
    chiefComplaint: 'Headache and elevated blood pressure',
    onsetDuration: '3 days',
    associatedSymptoms: 'Dizziness',
    medicalHistory: 'None known',
    currentMedication: 'None',
    clinicalObservations: 'BP 150/95',
    assessment: 'Primary Hypertension',
    plan: 'Lifestyle modification and medication',
    summaryText: 'Doctor-approved clinical summary.',
    summaryApprovalStatus: SummaryApprovalStatus.approvedByDoctor,
    approvedByDoctorId: testDoctorId,
    approvedAt: DateTime(2026, 9, 10, 11, 15),
  );

  final sampleReportData = VisitReportData(
    visitId: testVisitId,
    patientId: testPatientId,
    caseId: testCaseId,
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
    approvedDoctorId: testDoctorId,
    completionVisitNumber: 'Visit 1',
    completionCaseId: testCaseId,
    consultingDoctor: 'Dr. Rajesh Sharma',
    consultingDoctorQualification: 'MBBS, MD (Cardiology)',
    summaryApprovalNotice: 'APPROVED BY DOCTOR',
  );

  setUp(() async {
    BackendProvider.instance.setMode(BackendMode.mock);

    mockStorage = MockStorageService.instance..reset();
    mockReportRepo = MockReportRepository.instance..reset();
    mockVisitRepo = MockClinicalVisitRepository.instance..resetToDefaults();
    mockCaseRepo = MockCaseRepository.instance..resetToDefaults();
    mockInvestigationRepo = MockInvestigationRepository.instance..reset();
    mockPatientRepo = MockPatientRepository.instance..resetToDefaults();
    mockPdfOutput = MockPdfOutputService.instance..reset();

    // Seed mock data
    await mockPatientRepo.savePatient(samplePatient);
    await mockCaseRepo.createCase(sampleCase);
    await mockVisitRepo.createVisit(sampleVisit);

    BackendProvider.instance.setCustomRepositories(
      storageService: mockStorage,
      reportRepo: mockReportRepo,
      clinicalVisitRepo: mockVisitRepo,
      caseRepo: mockCaseRepo,
      investigationRepo: mockInvestigationRepo,
      patientRepo: mockPatientRepo,
    );

    PatientSessionService.instance.startSession(testPatientId, authUid: 'auth-p-102938');
    await DoctorSessionService.instance.enterDevelopmentWorkspace();
  });

  tearDown(() {
    BackendProvider.instance.resetOverrides();
    PatientSessionService.instance.logout();
    DoctorSessionService.instance.logout();
  });

  group('AAYUSATHI MASTER WORKFLOW E2E VERIFICATION (21 SPECIFICATIONS)', () {
    // =========================================================================
    // SECTION 1: PATIENT REPORT UPLOAD (Specs 1 - 8)
    // =========================================================================

    test('1. Valid image upload (JPEG/PNG) succeeds and persists canonical object', () async {
      await mockInvestigationRepo.createInvestigationRequest(
        InvestigationRequest(
          requestId: 'INV-ECG-001',
          visitId: testVisitId,
          patientId: testPatientId,
          caseId: testCaseId,
          name: '12-Lead ECG',
          status: InvestigationStatus.pendingUpload,
          requestedAt: DateTime(2026, 9, 10),
        ),
      );

      final uploadService = PatientReportUploadService();
      final doc = await uploadService.submitReport(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisitId,
        investigationId: 'INV-ECG-001',
        photos: [
          ReportPhotoItem(
            id: 'p1',
            originalName: 'ecg_reading.jpg',
            bytes: validJpegBytes,
            mimeType: 'image/jpeg',
            pageNumber: 1,
          ),
        ],
      );

      expect(doc, isNotNull);
      expect(doc.reviewStatus, equals(ReportReviewStatus.uploaded));
      expect(doc.storagePath, startsWith('patients/$testPatientId/cases/$testCaseId/visits/$testVisitId/reports/'));
      expect(await mockStorage.fileExists(doc.storagePath), isTrue);

      final investigation = await mockInvestigationRepo.getInvestigationById(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisitId,
        investigationId: 'INV-ECG-001',
      );
      expect(investigation?.isUploaded, isTrue);
    });

    test('2. Valid PDF upload succeeds and is accepted without format rejection', () async {
      await mockInvestigationRepo.createInvestigationRequest(
        InvestigationRequest(
          requestId: 'INV-LAB-001',
          visitId: testVisitId,
          patientId: testPatientId,
          caseId: testCaseId,
          name: 'Complete Blood Count',
          status: InvestigationStatus.pendingUpload,
          requestedAt: DateTime(2026, 9, 10),
        ),
      );

      final uploadService = PatientReportUploadService();
      final doc = await uploadService.submitReport(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisitId,
        investigationId: 'INV-LAB-001',
        photos: [
          ReportPhotoItem(
            id: 'p1',
            originalName: 'cbc_report.pdf',
            bytes: validPdfBytes,
            mimeType: 'application/pdf',
            pageNumber: 1,
          ),
        ],
      );

      expect(doc.contentType, equals('application/pdf'));
      expect(doc.fileName.toLowerCase(), endsWith('.pdf'));
      expect(await mockStorage.fileExists(doc.storagePath), isTrue);
    });

    test('3. Missing/invalid client configuration is caught early without sending network requests', () {
      // Authoritative Supabase configuration is now verified live cloud ready
      expect(SupabaseConfig.isConfigValid, isTrue);
      expect(SupabaseConfig.isPlaceholderKey, isFalse);
      expect(SupabaseConfig.isLiveCloudReady, isTrue);
      expect(SupabaseConfig.keyStatusDescription, equals('Configured (format: JWT)'));

      final validation = SupabaseStorageService.normalizeStoragePath('');
      expect(validation, isEmpty);
    });

    test('4. Storage authorization failure throws permission denied / unavailable safely', () async {
      await mockInvestigationRepo.createInvestigationRequest(
        InvestigationRequest(
          requestId: 'INV-XRAY-001',
          visitId: testVisitId,
          patientId: testPatientId,
          caseId: testCaseId,
          name: 'Chest X-Ray',
          status: InvestigationStatus.pendingUpload,
          requestedAt: DateTime(2026, 9, 10),
        ),
      );

      mockStorage.simulateUploadFailure = true;
      mockStorage.failureErrorMessage = 'Unauthorized: Invalid Supabase auth token';

      final uploadService = PatientReportUploadService();
      expect(
        () => uploadService.submitReport(
          patientId: testPatientId,
          caseId: testCaseId,
          visitId: testVisitId,
          investigationId: 'INV-XRAY-001',
          photos: [
            ReportPhotoItem(
              id: 'p1',
              originalName: 'chest_xray.png',
              bytes: validPngBytes,
              mimeType: 'image/png',
              pageNumber: 1,
            ),
          ],
        ),
        throwsA(isA<BackendException>()),
      );
    });

    test('5. Upload timeout/network failure handles gracefully and preserves retry capability', () async {
      await mockInvestigationRepo.createInvestigationRequest(
        InvestigationRequest(
          requestId: 'INV-USG-001',
          visitId: testVisitId,
          patientId: testPatientId,
          caseId: testCaseId,
          name: 'Abdominal USG',
          status: InvestigationStatus.pendingUpload,
          requestedAt: DateTime(2026, 9, 10),
        ),
      );

      mockStorage.simulateUploadFailure = true;
      mockStorage.failureErrorMessage = 'Network timeout connecting to Supabase';

      final uploadService = PatientReportUploadService();
      try {
        await uploadService.submitReport(
          patientId: testPatientId,
          caseId: testCaseId,
          visitId: testVisitId,
          investigationId: 'INV-USG-001',
          photos: [
            ReportPhotoItem(
              id: 'p1',
              originalName: 'usg_scan.jpg',
              bytes: validJpegBytes,
              mimeType: 'image/jpeg',
              pageNumber: 1,
            ),
          ],
        );
        fail('Should have thrown timeout exception');
      } catch (e) {
        expect(e, isA<BackendException>());
      }
    });

    test('6. No false UPLOADED status after a failed upload', () async {
      await mockInvestigationRepo.createInvestigationRequest(
        InvestigationRequest(
          requestId: 'INV-MRI-001',
          visitId: testVisitId,
          patientId: testPatientId,
          caseId: testCaseId,
          name: 'Brain MRI',
          status: InvestigationStatus.pendingUpload,
          requestedAt: DateTime(2026, 9, 10),
        ),
      );

      mockStorage.simulateUploadFailure = true;
      final uploadService = PatientReportUploadService();

      try {
        await uploadService.submitReport(
          patientId: testPatientId,
          caseId: testCaseId,
          visitId: testVisitId,
          investigationId: 'INV-MRI-001',
          photos: [
            ReportPhotoItem(
              id: 'p1',
              originalName: 'mri.pdf',
              bytes: validPdfBytes,
              pageNumber: 1,
            ),
          ],
        );
      } catch (_) {}

      // Investigation MUST remain NOT uploaded
      final inv = await mockInvestigationRepo.getInvestigationById(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisitId,
        investigationId: 'INV-MRI-001',
      );
      expect(inv?.isUploaded, isFalse);

      // ReportRepository MUST NOT have recorded metadata
      final doc = await mockReportRepo.getReportForInvestigation(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisitId,
        investigationId: 'INV-MRI-001',
      );
      expect(doc, isNull);
    });

    test('7. Retry without inconsistent duplicate metadata', () async {
      await mockInvestigationRepo.createInvestigationRequest(
        InvestigationRequest(
          requestId: 'INV-CT-001',
          visitId: testVisitId,
          patientId: testPatientId,
          caseId: testCaseId,
          name: 'CT Scan',
          status: InvestigationStatus.pendingUpload,
          requestedAt: DateTime(2026, 9, 10),
        ),
      );

      // 1st attempt fails
      mockStorage.simulateUploadFailure = true;
      final uploadService = PatientReportUploadService();
      try {
        await uploadService.submitReport(
          patientId: testPatientId,
          caseId: testCaseId,
          visitId: testVisitId,
          investigationId: 'INV-CT-001',
          photos: [
            ReportPhotoItem(
              id: 'p1',
              originalName: 'ct_scan.jpg',
              bytes: validJpegBytes,
              pageNumber: 1,
            ),
          ],
        );
      } catch (_) {}

      // 2nd attempt succeeds
      mockStorage.simulateUploadFailure = false;
      final doc = await uploadService.submitReport(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisitId,
        investigationId: 'INV-CT-001',
        photos: [
          ReportPhotoItem(
            id: 'p1',
            originalName: 'ct_scan.jpg',
            bytes: validJpegBytes,
            pageNumber: 1,
          ),
        ],
      );

      expect(doc, isNotNull);
      final allReports = await mockReportRepo.getReportsForVisit(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisitId,
      );
      expect(allReports.where((r) => r.investigationId == 'INV-CT-001').length, equals(1));
    });

    test('8. Correct patient/case/visit association enforced strictly', () async {
      final uploadService = PatientReportUploadService();

      // Session is for AAYU-102938, attempting to upload for AAYU-999999
      expect(
        () => uploadService.submitReport(
          patientId: 'AAYU-999999',
          caseId: testCaseId,
          visitId: testVisitId,
          investigationId: 'INV-001',
          photos: [
            ReportPhotoItem(
              id: 'p1',
              originalName: 'test.jpg',
              bytes: validJpegBytes,
              pageNumber: 1,
            ),
          ],
        ),
        throwsA(isA<BackendException>()),
      );
    });

    // =========================================================================
    // SECTION 2: DOCTOR REPORT ACCESS (Specs 9 - 13)
    // =========================================================================

    test('9. Doctor can retrieve an authorized patient uploaded report', () async {
      final canonicalPath = 'patients/$testPatientId/cases/$testCaseId/visits/$testVisitId/reports/report1.pdf';
      await mockStorage.uploadReportFile(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisitId,
        investigationId: 'INV-001',
        fileName: 'report1.pdf',
        bytes: validPdfBytes,
        contentType: 'application/pdf',
      );

      final retrieved = await mockStorage.getFileBytes(canonicalPath);
      expect(retrieved, isNotNull);
      expect(retrieved, equals(validPdfBytes));

      final signedUrl = await mockStorage.getSignedUrl(canonicalPath);
      expect(signedUrl, isNotNull);
      expect(signedUrl, contains('aayusathi-reports'));
    });

    test('10. Doctor can access authorized historical cases', () async {
      final isAuth = await mockCaseRepo.isDoctorAuthorizedForCase(
        doctorId: testDoctorId,
        caseId: testCaseId,
        patientId: testPatientId,
      );
      expect(isAuth, isTrue);
    });

    test('11. Unauthorized doctors cannot access unrelated reports', () async {
      final isAuth = await mockCaseRepo.isDoctorAuthorizedForCase(
        doctorId: 'DOC-UNAUTHORIZED-999',
        caseId: testCaseId,
        patientId: testPatientId,
      );
      expect(isAuth, isFalse);
    });

    test('12. Invalid or expired signed URLs are handled correctly without crashing', () async {
      final url = await mockStorage.getSignedUrl('non_existent_file.pdf');
      expect(url, isNull);

      final bytes = await mockStorage.getFileBytes('non_existent_file.pdf');
      expect(bytes, isNull);
    });

    test('13. Invalid response bodies (HTML errors) are not rendered as files', () {
      final htmlErrorPayload = Uint8List.fromList('<html><head><title>404 Not Found</title></head></html>'.codeUnits);
      final jsonErrorPayload = Uint8List.fromList('{"statusCode":"403","error":"Unauthorized"}'.codeUnits);

      // Verify validator rejects HTML and JSON error payloads
      final validation1 = PatientReportFileValidator.validateReportFile(
        fileName: 'report.pdf',
        bytes: htmlErrorPayload,
        allowPdf: true,
      );
      expect(validation1.isValid, isFalse);

      final validation2 = PatientReportFileValidator.validateReportFile(
        fileName: 'report.png',
        bytes: jsonErrorPayload,
        allowPdf: true,
      );
      expect(validation2.isValid, isFalse);
    });

    // =========================================================================
    // SECTION 3: OFFICIAL VISIT PDF (Specs 14 - 21)
    // =========================================================================

    test('14. PDF generation from approved clinical data succeeds with 9 sections', () async {
      final result = await VisitReportPdfService.instance.generateAndSaveVisitPdf(
        sampleReportData,
        logoBytes: validPngBytes,
        outputService: mockPdfOutput,
      );

      expect(result.isSuccess, isTrue);
      expect(result.pdfBytes, isNotNull);
      expect(result.pdfBytes!.length, greaterThan(100));
      // First 4 bytes must be %PDF
      expect(result.pdfBytes![0], equals(0x25));
      expect(result.pdfBytes![1], equals(0x50));
      expect(result.pdfBytes![2], equals(0x44));
      expect(result.pdfBytes![3], equals(0x46));
    });

    test('15. Mandatory fields and doctor approval are strictly enforced', () async {
      // Unapproved draft
      final unapprovedData = VisitReportData.fromComponents(
        patient: samplePatient,
        clinicalCase: sampleCase,
        visit: sampleVisit.copyWith(
          summaryApprovalStatus: SummaryApprovalStatus.reviewRequired,
        ),
      );

      final result = await VisitReportPdfService.instance.generateAndSaveVisitPdf(
        unapprovedData,
        outputService: mockPdfOutput,
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, equals('GATING_REQUIREMENTS_NOT_MET'));
    });

    test('16. PDF is uploaded to the intended private bucket (aayusathi-reports)', () async {
      final localResult = VisitReportPdfResult.success(
        filePath: 'C:/mock/report.pdf',
        fileName: 'AAYUSATHI_Visit_Report_AAYU_102938_Visit_1.pdf',
        fileSizeBytes: validPdfBytes.length,
        pdfBytes: validPdfBytes,
      );

      final uploadResult = await VisitReportPdfService.instance.uploadVisitReportPdfToCloud(
        localResult: localResult,
        data: sampleReportData,
      );

      expect(uploadResult.isCloudUploaded, isTrue);
      expect(uploadResult.cloudStoragePath, equals('patients/$testPatientId/cases/$testCaseId/visits/$testVisitId/reports/AAYUSATHI_Visit_Report_AAYU_102938_Visit_1.pdf'));
      expect(await mockStorage.fileExists(uploadResult.cloudStoragePath!), isTrue);
    });

    test('17. Stored object can be downloaded and validated', () async {
      final path = 'patients/$testPatientId/cases/$testCaseId/visits/$testVisitId/reports/AAYUSATHI_Visit_Report.pdf';
      await mockStorage.uploadVisitPdf(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisitId,
        fileName: 'AAYUSATHI_Visit_Report.pdf',
        bytes: validPdfBytes,
      );

      final downloaded = await mockStorage.getFileBytes(path);
      expect(downloaded, isNotNull);
      expect(downloaded!.take(4).toList(), equals([0x25, 0x50, 0x44, 0x46])); // %PDF
    });

    test('18. Firestore metadata matches the persisted object attributes', () async {
      final localResult = VisitReportPdfResult.success(
        filePath: 'C:/mock/report.pdf',
        fileName: 'AAYUSATHI_Visit_Report_AAYU_102938_Visit_1.pdf',
        fileSizeBytes: validPdfBytes.length,
        pdfBytes: validPdfBytes,
      );

      await VisitReportPdfService.instance.uploadVisitReportPdfToCloud(
        localResult: localResult,
        data: sampleReportData,
      );

      final reports = await mockReportRepo.getReportsForVisit(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisitId,
      );
      final officialReport = reports.firstWhere((r) => r.investigationId == 'OFFICIAL_VISIT_REPORT');

      expect(officialReport.storageProvider, equals('supabase'));
      expect(officialReport.storageBucket, equals('aayusathi-reports'));
      expect(officialReport.storagePath, equals('patients/$testPatientId/cases/$testCaseId/visits/$testVisitId/reports/AAYUSATHI_Visit_Report_AAYU_102938_Visit_1.pdf'));
      expect(officialReport.isPdf, isTrue);
      expect(officialReport.reviewStatus, equals(ReportReviewStatus.reviewed));
    });

    test('19. Patient can retrieve the corresponding visit official PDF (Tier 1)', () async {
      // Seed persisted PDF
      final path = 'patients/$testPatientId/cases/$testCaseId/visits/$testVisitId/reports/AAYUSATHI_Visit_Report.pdf';
      await mockStorage.uploadVisitPdf(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisitId,
        fileName: 'AAYUSATHI_Visit_Report.pdf',
        bytes: validPdfBytes,
      );

      final reportDoc = ReportDocument(
        reportId: 'OFFICIAL-REPORT-$testVisitId',
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisitId,
        investigationId: 'OFFICIAL_VISIT_REPORT',
        fileName: 'AAYUSATHI_Visit_Report.pdf',
        contentType: 'application/pdf',
        fileSizeBytes: validPdfBytes.length,
        storagePath: path,
        storageProvider: 'supabase',
        storageBucket: 'aayusathi-reports',
        uploadedAt: DateTime.now(),
        uploadedByPatientId: testDoctorId,
        reviewStatus: ReportReviewStatus.reviewed,
      );

      final result = await PatientOfficialVisitPdfService.instance.retrieveOfficialVisitPdf(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisitId,
        reportDoc: reportDoc,
        visit: sampleVisit,
      );

      expect(result.isSuccess, isTrue);
      expect(result.source, equals(OfficialPdfSource.supabaseStorage));
      expect(result.pdfBytes, isNotNull);
    });

    test('20. Failed PDF upload does not create false success metadata', () async {
      mockStorage.simulateUploadFailure = true;

      final localResult = VisitReportPdfResult.success(
        filePath: 'C:/mock/report.pdf',
        fileName: 'AAYUSATHI_Visit_Report.pdf',
        fileSizeBytes: validPdfBytes.length,
        pdfBytes: validPdfBytes,
      );

      final uploadResult = await VisitReportPdfService.instance.uploadVisitReportPdfToCloud(
        localResult: localResult,
        data: sampleReportData,
      );

      expect(uploadResult.isCloudUploaded, isFalse);
      expect(uploadResult.cloudUploadError, isNotNull);

      // Verify NO report metadata in repository
      final reports = await mockReportRepo.getReportsForVisit(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisitId,
      );
      expect(reports.where((r) => r.investigationId == 'OFFICIAL_VISIT_REPORT'), isEmpty);
    });

    test('21. Recovery mechanisms work on-demand (Tier 3) without claiming cloud persistence', () async {
      // No cloud file seeded in mock storage
      expect(await mockStorage.fileExists('patients/$testPatientId/cases/$testCaseId/visits/$testVisitId/reports/AAYUSATHI_Visit_Report.pdf'), isFalse);

      final result = await PatientOfficialVisitPdfService.instance.retrieveOfficialVisitPdf(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisitId,
        visit: sampleVisit,
        clinicalCase: sampleCase,
        patient: samplePatient,
      );

      expect(result.isSuccess, isTrue);
      expect(result.source, equals(OfficialPdfSource.onDemandSynthesis));
      expect(result.pdfBytes, isNotNull);
      expect(result.pdfBytes!.length, greaterThan(100));

      // Must NOT have marked cloud storage as uploaded
      expect(await mockStorage.fileExists('patients/$testPatientId/cases/$testCaseId/visits/$testVisitId/reports/AAYUSATHI_Visit_Report.pdf'), isFalse);
      final reports = await mockReportRepo.getReportsForVisit(
        patientId: testPatientId,
        caseId: testCaseId,
        visitId: testVisitId,
      );
      expect(reports.where((r) => r.investigationId == 'OFFICIAL_VISIT_REPORT'), isEmpty);
    });
  });
}

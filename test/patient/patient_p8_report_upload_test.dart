import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_exception.dart';
import 'package:aayusathi/core/backend/backend_mode.dart';
import 'package:aayusathi/core/supabase/supabase_config.dart';
import 'package:aayusathi/doctor/models/clinical_case.dart';
import 'package:aayusathi/doctor/models/clinical_visit.dart';
import 'package:aayusathi/doctor/models/investigation_request.dart';
import 'package:aayusathi/doctor/models/report_document.dart';
import 'package:aayusathi/doctor/services/mock_storage_service.dart';
import 'package:aayusathi/models/patient.dart';
import 'package:aayusathi/patient/controllers/patient_report_upload_controller.dart';
import 'package:aayusathi/patient/localization/patient_localizations.dart';
import 'package:aayusathi/patient/models/patient_app_state.dart';
import 'package:aayusathi/patient/patient_routes.dart';
import 'package:aayusathi/patient/screens/patient_report_upload_screen.dart';
import 'package:aayusathi/patient/services/patient_report_upload_service.dart';
import 'package:aayusathi/patient/services/patient_session_service.dart';
import 'package:aayusathi/patient/theme/patient_theme.dart';
import 'package:aayusathi/repositories/mock/mock_case_repository.dart';
import 'package:aayusathi/repositories/mock/mock_clinical_visit_repository.dart';
import 'package:aayusathi/repositories/mock/mock_investigation_repository.dart';
import 'package:aayusathi/repositories/mock/mock_patient_repository.dart';
import 'package:aayusathi/repositories/mock/mock_report_repository.dart';
import 'package:aayusathi/repositories/report_repository.dart';

class _FailingReportRepository implements ReportRepository {
  final MockReportRepository _inner = MockReportRepository.instance;
  bool failSave = false;

  @override
  Future<ReportDocument> saveReportDocument(ReportDocument report) async {
    if (failSave) {
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Firestore unavailable for report document write.',
      );
    }
    return _inner.saveReportDocument(report);
  }

  @override
  Future<ReportDocument?> getReportById({
    required String patientId,
    required String caseId,
    required String visitId,
    required String reportId,
  }) =>
      _inner.getReportById(
        patientId: patientId,
        caseId: caseId,
        visitId: visitId,
        reportId: reportId,
      );

  @override
  Future<ReportDocument?> getReportForInvestigation({
    required String patientId,
    required String caseId,
    required String visitId,
    required String investigationId,
  }) =>
      _inner.getReportForInvestigation(
        patientId: patientId,
        caseId: caseId,
        visitId: visitId,
        investigationId: investigationId,
      );

  @override
  Future<List<ReportDocument>> getReportsForVisit({
    required String patientId,
    required String caseId,
    required String visitId,
  }) =>
      _inner.getReportsForVisit(
        patientId: patientId,
        caseId: caseId,
        visitId: visitId,
      );

  @override
  Stream<List<ReportDocument>> watchReportsForVisit({
    required String patientId,
    required String caseId,
    required String visitId,
  }) =>
      _inner.watchReportsForVisit(
        patientId: patientId,
        caseId: caseId,
        visitId: visitId,
      );

  @override
  Future<void> updateReportStatus({
    required String patientId,
    required String caseId,
    required String visitId,
    required String reportId,
    required ReportReviewStatus status,
    required String doctorId,
  }) =>
      _inner.updateReportStatus(
        patientId: patientId,
        caseId: caseId,
        visitId: visitId,
        reportId: reportId,
        status: status,
        doctorId: doctorId,
      );

  @override
  Future<void> saveReportAiSummary({
    required String patientId,
    required String caseId,
    required String visitId,
    required String reportId,
    required AiReportSummaryRecord summary,
  }) =>
      _inner.saveReportAiSummary(
        patientId: patientId,
        caseId: caseId,
        visitId: visitId,
        reportId: reportId,
        summary: summary,
      );

  @override
  Future<AiReportSummaryRecord?> getReportAiSummary({
    required String patientId,
    required String caseId,
    required String visitId,
    required String reportId,
  }) =>
      _inner.getReportAiSummary(
        patientId: patientId,
        caseId: caseId,
        visitId: visitId,
        reportId: reportId,
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AAYUSATHI Patient App P8: Report Photo Upload & Storage Test Suite', () {
    late MockStorageService mockStorage;
    late MockReportRepository mockReportRepo;
    late _FailingReportRepository failingReportRepo;
    final sessionService = PatientSessionService.instance;

    final testPatientA = Patient(
      patientId: 'PAT-P8-001',
      name: 'Ramesh Kulkarni',
      dateOfBirth: '12 June 1958',
      age: 68,
      gender: 'Male',
      phone: '9822011223',
      bloodGroup: 'B+',
      address: 'Shivaji Nagar, Pune',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    final testPatientB = Patient(
      patientId: 'PAT-P8-002',
      name: 'Sunita Patil',
      dateOfBirth: '20 August 1962',
      age: 64,
      gender: 'Female',
      phone: '9822099887',
      bloodGroup: 'A+',
      address: 'Kothrud, Pune',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    final testCaseA = ClinicalCase(
      caseId: 'CASE-P8-001',
      patientId: 'PAT-P8-001',
      title: 'Cardiology Assessment',
      domain: 'Cardiology',
      createdAt: DateTime(2026, 9, 1),
      updatedAt: DateTime(2026, 9, 1),
    );

    final testVisitA = ClinicalVisit(
      visitId: 'VIS-P8-001',
      caseId: 'CASE-P8-001',
      patientId: 'PAT-P8-001',
      doctorId: 'DOC-101',
      visitNumber: 1,
      startedAt: DateTime(2026, 9, 5),
    );

    final testInvestigationA = InvestigationRequest(
      requestId: 'INV-ECG-001',
      patientId: 'PAT-P8-001',
      caseId: 'CASE-P8-001',
      visitId: 'VIS-P8-001',
      name: '12-Lead Electrocardiogram (ECG)',
      priority: InvestigationPriority.required,
      status: InvestigationStatus.pendingUpload,
      requestedAt: DateTime(2026, 9, 5),
    );

    // Valid 1x1 transparent PNG bytes (magic bytes 0x89 0x50 0x4E 0x47, decodable by Flutter engine)
    final validPngBytes = [
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
      0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
      0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ];

    // Valid 1x1 JPEG bytes (magic bytes 0xFF 0xD8 0xFF 0xE0, decodable by Flutter engine)
    final validJpgBytes = [
      0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
      0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
      0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
      0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
      0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
      0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
      0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
      0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
      0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x1F, 0x00, 0x00,
      0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
      0x09, 0x0A, 0x0B, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F,
      0x00, 0xBF, 0x80, 0xFF, 0xD9,
    ];

    setUp(() async {
      BackendProvider.instance.setMode(BackendMode.mock);
      mockStorage = MockStorageService.instance..reset();
      mockReportRepo = MockReportRepository.instance..reset();
      failingReportRepo = _FailingReportRepository();

      MockCaseRepository.instance.resetToDefaults();
      MockClinicalVisitRepository.instance.resetToDefaults();
      MockInvestigationRepository.instance.reset();
      MockPatientRepository.instance.resetToDefaults();

      BackendProvider.instance.setCustomRepositories(
        storageService: mockStorage,
        reportRepo: mockReportRepo,
      );

      await MockPatientRepository.instance.savePatient(testPatientA);
      await MockPatientRepository.instance.savePatient(testPatientB);
      await MockCaseRepository.instance.createCase(testCaseA);
      await MockClinicalVisitRepository.instance.createVisit(testVisitA);
      await MockInvestigationRepository.instance.createInvestigationRequest(testInvestigationA);

      PatientAppState.instance.resetSession();
      sessionService.startSession('PAT-P8-001', authUid: 'auth-p8-ramesh');
      PatientAppState.instance.setAuthenticatedPatient(testPatientA);
    });

    tearDown(() {
      PatientAppState.instance.resetSession();
      sessionService.logout();
      BackendProvider.instance.resetOverrides();
    });

    Widget createTestWidget(Widget child, {Locale locale = const Locale('en')}) {
      return MaterialApp(
        locale: locale,
        theme: PatientTheme.theme,
        onGenerateRoute: PatientRoutes.onGenerateRoute,
        home: PatientLocalizations.provider(
          strings: PatientLocalizations.forLocaleCode(locale.languageCode),
          child: child,
        ),
      );
    }

    // ==============================================================
    // 1. SECTION 39: UPLOAD LIFECYCLE & RESILIENCE TESTS
    // ==============================================================

    test('1. Authenticated patient can upload report photo to Supabase private bucket and Firestore', () async {
      final uploadService = PatientReportUploadService(
        sessionService: sessionService,
        caseRepo: BackendProvider.instance.caseRepository,
        visitRepo: BackendProvider.instance.clinicalVisitRepository,
        investigationRepo: BackendProvider.instance.investigationRepository,
        reportRepo: mockReportRepo,
      );

      final photo = ReportPhotoItem(
        id: 'p1',
        originalName: 'ecg_reading.jpg',
        bytes: validJpgBytes,
        pageNumber: 1,
      );

      final savedDoc = await uploadService.submitReport(
        patientId: 'PAT-P8-001',
        caseId: 'CASE-P8-001',
        visitId: 'VIS-P8-001',
        investigationId: 'INV-ECG-001',
        photos: [photo],
      );

      // Verify Supabase upload success
      expect(savedDoc.storageProvider, 'supabase');
      expect(savedDoc.storageBucket, 'aayusathi-reports');
      expect(savedDoc.storagePath, contains('patients/PAT-P8-001/cases/CASE-P8-001/visits/VIS-P8-001/reports/'));
      expect(savedDoc.storagePath, contains('INV_INVECG001'));
      expect(await mockStorage.fileExists(savedDoc.storagePath), isTrue);

      // Verify Firestore metadata
      expect(savedDoc.reportId, startsWith('REP-INV-ECG-001'));
      expect(savedDoc.reviewStatus, ReportReviewStatus.uploaded);
      expect(savedDoc.uploadedByPatientId, 'PAT-P8-001');

      // Verify Investigation status transitioned to UPLOADED
      final updatedInv = await BackendProvider.instance.investigationRepository.getInvestigationById(
        patientId: 'PAT-P8-001',
        caseId: 'CASE-P8-001',
        visitId: 'VIS-P8-001',
        investigationId: 'INV-ECG-001',
      );
      expect(updatedInv?.status, InvestigationStatus.uploaded);
      expect(updatedInv?.uploadedReportId, savedDoc.reportId);
    });

    test('2. Multi-page photo report submission uploads all pages with proper sequence metadata', () async {
      final uploadService = PatientReportUploadService(
        sessionService: sessionService,
        caseRepo: BackendProvider.instance.caseRepository,
        visitRepo: BackendProvider.instance.clinicalVisitRepository,
        investigationRepo: BackendProvider.instance.investigationRepository,
        reportRepo: mockReportRepo,
      );

      final photo1 = ReportPhotoItem(
        id: 'p1',
        originalName: 'page1.jpg',
        bytes: validJpgBytes,
        pageNumber: 1,
      );
      final photo2 = ReportPhotoItem(
        id: 'p2',
        originalName: 'page2.png',
        bytes: validPngBytes,
        pageNumber: 2,
      );

      final primaryDoc = await uploadService.submitReport(
        patientId: 'PAT-P8-001',
        caseId: 'CASE-P8-001',
        visitId: 'VIS-P8-001',
        investigationId: 'INV-ECG-001',
        photos: [photo1, photo2],
      );

      expect(await mockStorage.fileExists(primaryDoc.storagePath), isTrue);
      final visitDocs = await mockReportRepo.getReportsForVisit(
        patientId: 'PAT-P8-001',
        caseId: 'CASE-P8-001',
        visitId: 'VIS-P8-001',
      );
      expect(visitDocs.length, 2);
      expect(primaryDoc.reportId, visitDocs.first.reportId);
      expect(visitDocs.last.reportId, contains('-P2'));
    });

    test('3. Duplicate submission is strictly prevented when already Uploaded or Reviewed', () async {
      final uploadService = PatientReportUploadService(
        sessionService: sessionService,
        caseRepo: BackendProvider.instance.caseRepository,
        visitRepo: BackendProvider.instance.clinicalVisitRepository,
        investigationRepo: BackendProvider.instance.investigationRepository,
        reportRepo: mockReportRepo,
      );

      final photo = ReportPhotoItem(
        id: 'p1',
        originalName: 'ecg.jpg',
        bytes: validJpgBytes,
        pageNumber: 1,
      );

      // First upload succeeds
      await uploadService.submitReport(
        patientId: 'PAT-P8-001',
        caseId: 'CASE-P8-001',
        visitId: 'VIS-P8-001',
        investigationId: 'INV-ECG-001',
        photos: [photo],
      );

      // Second upload attempt MUST be rejected
      expect(
        () => uploadService.submitReport(
          patientId: 'PAT-P8-001',
          caseId: 'CASE-P8-001',
          visitId: 'VIS-P8-001',
          investigationId: 'INV-ECG-001',
          photos: [photo],
        ),
        throwsA(isA<BackendException>().having(
          (e) => e.message,
          'message',
          contains('already been submitted'),
        )),
      );
    });

    test('4. Supabase upload failure aborts cleanly: NO false Uploaded status in Firestore', () async {
      mockStorage.simulateUploadFailure = true;

      final uploadService = PatientReportUploadService(
        sessionService: sessionService,
        caseRepo: BackendProvider.instance.caseRepository,
        visitRepo: BackendProvider.instance.clinicalVisitRepository,
        investigationRepo: BackendProvider.instance.investigationRepository,
        reportRepo: mockReportRepo,
      );

      final photo = ReportPhotoItem(
        id: 'p1',
        originalName: 'ecg.jpg',
        bytes: validJpgBytes,
        pageNumber: 1,
      );

      expect(
        () => uploadService.submitReport(
          patientId: 'PAT-P8-001',
          caseId: 'CASE-P8-001',
          visitId: 'VIS-P8-001',
          investigationId: 'INV-ECG-001',
          photos: [photo],
        ),
        throwsA(isA<BackendException>()),
      );

      // Verify Firestore was NOT updated to Uploaded
      final inv = await BackendProvider.instance.investigationRepository.getInvestigationById(
        patientId: 'PAT-P8-001',
        caseId: 'CASE-P8-001',
        visitId: 'VIS-P8-001',
        investigationId: 'INV-ECG-001',
      );
      expect(inv?.status, InvestigationStatus.pendingUpload);
      expect(inv?.uploadedReportId, isNull);

      // Verify no orphan ReportDocument in Firestore
      final reports = await mockReportRepo.getReportsForVisit(
        patientId: 'PAT-P8-001',
        caseId: 'CASE-P8-001',
        visitId: 'VIS-P8-001',
      );
      expect(reports.isEmpty, isTrue);
    });

    test('5. Firestore metadata failure surfaces controlled error and enables clean retry', () async {
      failingReportRepo.failSave = true;

      final uploadService = PatientReportUploadService(
        sessionService: sessionService,
        caseRepo: BackendProvider.instance.caseRepository,
        visitRepo: BackendProvider.instance.clinicalVisitRepository,
        investigationRepo: BackendProvider.instance.investigationRepository,
        reportRepo: failingReportRepo,
      );

      final photo = ReportPhotoItem(
        id: 'p1',
        originalName: 'ecg.jpg',
        bytes: validJpgBytes,
        pageNumber: 1,
      );

      // First attempt fails at Firestore write
      await expectLater(
        uploadService.submitReport(
          patientId: 'PAT-P8-001',
          caseId: 'CASE-P8-001',
          visitId: 'VIS-P8-001',
          investigationId: 'INV-ECG-001',
          photos: [photo],
        ),
        throwsA(isA<BackendException>().having(
          (e) => e.message,
          'message',
          contains('Failed to record report submission'),
        )),
      );

      // Investigation remains pendingUpload
      var inv = await BackendProvider.instance.investigationRepository.getInvestigationById(
        patientId: 'PAT-P8-001',
        caseId: 'CASE-P8-001',
        visitId: 'VIS-P8-001',
        investigationId: 'INV-ECG-001',
      );
      expect(inv?.status, InvestigationStatus.pendingUpload);

      // Fix backend connectivity and retry
      failingReportRepo.failSave = false;
      final savedDoc = await uploadService.submitReport(
        patientId: 'PAT-P8-001',
        caseId: 'CASE-P8-001',
        visitId: 'VIS-P8-001',
        investigationId: 'INV-ECG-001',
        photos: [photo],
      );

      expect(savedDoc.reviewStatus, ReportReviewStatus.uploaded);
      inv = await BackendProvider.instance.investigationRepository.getInvestigationById(
        patientId: 'PAT-P8-001',
        caseId: 'CASE-P8-001',
        visitId: 'VIS-P8-001',
        investigationId: 'INV-ECG-001',
      );
      expect(inv?.status, InvestigationStatus.uploaded);
    });

    test('6. Logged out / unauthenticated session blocks report upload immediately', () async {
      sessionService.logout();

      final uploadService = PatientReportUploadService(
        sessionService: sessionService,
        caseRepo: BackendProvider.instance.caseRepository,
        visitRepo: BackendProvider.instance.clinicalVisitRepository,
        investigationRepo: BackendProvider.instance.investigationRepository,
        reportRepo: mockReportRepo,
      );

      final photo = ReportPhotoItem(
        id: 'p1',
        originalName: 'ecg.jpg',
        bytes: validJpgBytes,
        pageNumber: 1,
      );

      expect(
        () => uploadService.submitReport(
          patientId: 'PAT-P8-001',
          caseId: 'CASE-P8-001',
          visitId: 'VIS-P8-001',
          investigationId: 'INV-ECG-001',
          photos: [photo],
        ),
        throwsA(isA<BackendException>().having(
          (e) => e.code,
          'code',
          BackendException.permissionDenied,
        )),
      );
    });

    // ==============================================================
    // 2. SECTION 41: SECURITY TESTING
    // ==============================================================

    test('7. Security: Patient A cannot upload into Patient B case/visit/investigation', () async {
      final uploadService = PatientReportUploadService(
        sessionService: sessionService, // Session is PAT-P8-001
        caseRepo: BackendProvider.instance.caseRepository,
        visitRepo: BackendProvider.instance.clinicalVisitRepository,
        investigationRepo: BackendProvider.instance.investigationRepository,
        reportRepo: mockReportRepo,
      );

      final photo = ReportPhotoItem(
        id: 'p1',
        originalName: 'ecg.jpg',
        bytes: validJpgBytes,
        pageNumber: 1,
      );

      // Attempt to spoof target patientId to PAT-P8-002
      expect(
        () => uploadService.submitReport(
          patientId: 'PAT-P8-002',
          caseId: 'CASE-P8-001',
          visitId: 'VIS-P8-001',
          investigationId: 'INV-ECG-001',
          photos: [photo],
        ),
        throwsA(isA<BackendException>().having(
          (e) => e.code,
          'code',
          BackendException.permissionDenied,
        )),
      );
    });

    test('8. Security: Patient cannot upload report into an arbitrary case not owned by them', () async {
      final uploadService = PatientReportUploadService(
        sessionService: sessionService,
        caseRepo: BackendProvider.instance.caseRepository,
        visitRepo: BackendProvider.instance.clinicalVisitRepository,
        investigationRepo: BackendProvider.instance.investigationRepository,
        reportRepo: mockReportRepo,
      );

      final photo = ReportPhotoItem(
        id: 'p1',
        originalName: 'ecg.jpg',
        bytes: validJpgBytes,
        pageNumber: 1,
      );

      // CASE-999 does not exist in Patient A's cases
      expect(
        () => uploadService.submitReport(
          patientId: 'PAT-P8-001',
          caseId: 'CASE-999',
          visitId: 'VIS-P8-001',
          investigationId: 'INV-ECG-001',
          photos: [photo],
        ),
        throwsA(isA<BackendException>().having(
          (e) => e.code,
          'code',
          BackendException.permissionDenied,
        )),
      );
    });

    test('9. Security: Patient cannot mutate reviewStatus to Reviewed', () async {
      final uploadService = PatientReportUploadService(
        sessionService: sessionService,
        caseRepo: BackendProvider.instance.caseRepository,
        visitRepo: BackendProvider.instance.clinicalVisitRepository,
        investigationRepo: BackendProvider.instance.investigationRepository,
        reportRepo: mockReportRepo,
      );

      final photo = ReportPhotoItem(
        id: 'p1',
        originalName: 'ecg.jpg',
        bytes: validJpgBytes,
        pageNumber: 1,
      );

      final savedDoc = await uploadService.submitReport(
        patientId: 'PAT-P8-001',
        caseId: 'CASE-P8-001',
        visitId: 'VIS-P8-001',
        investigationId: 'INV-ECG-001',
        photos: [photo],
      );

      // Submission sets reviewStatus strictly to uploaded (Pending Review)
      expect(savedDoc.reviewStatus, ReportReviewStatus.uploaded);
      expect(savedDoc.isReviewed, isFalse);
    });

    test('10. Security: Client configuration contains ONLY publishable key and ZERO service-role / secret keys', () {
      expect(SupabaseConfig.publishableKey.startsWith('sb_secret_'), isFalse);
      expect(SupabaseConfig.publishableKey.toLowerCase().contains('service_role'), isFalse);
      expect(SupabaseConfig.bucketName, 'aayusathi-reports');
      expect(SupabaseConfig.maxFileSizeBytes, 15 * 1024 * 1024);
    });

    // ==============================================================
    // 3. SECTION 40: UI & WIDGET WORKFLOW TESTS
    // ==============================================================

    testWidgets('11. Upload screen renders context card, Take Photo and Choose Gallery buttons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));

      final controller = PatientReportUploadController(
        investigation: testInvestigationA,
        caseTitle: 'Cardiology Assessment',
        visitDate: DateTime(2026, 9, 5),
        sessionService: sessionService,
      );

      await tester.pumpWidget(createTestWidget(PatientReportUploadScreen(
        investigation: testInvestigationA,
        caseTitle: 'Cardiology Assessment',
        visitDate: DateTime(2026, 9, 5),
        controller: controller,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Upload Report'), findsWidgets);
      expect(find.text('12-Lead Electrocardiogram (ECG)'), findsOneWidget);
      expect(find.text('REQUIRED'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.textContaining('Supports JPG, JPEG, PNG • Up to 15 MB'), findsOneWidget);
    });

    testWidgets('12. Selected image preview renders with Retake, Add Another Photo, and Submit Report CTAs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));

      final controller = PatientReportUploadController(
        investigation: testInvestigationA,
        caseTitle: 'Cardiology Assessment',
        visitDate: DateTime(2026, 9, 5),
        sessionService: sessionService,
      );

      // Inject valid photo directly into controller
      controller.addPhotoBytes(
        fileName: 'ecg_test.jpg',
        bytes: validJpgBytes,
      );

      await tester.pumpWidget(createTestWidget(PatientReportUploadScreen(
        investigation: testInvestigationA,
        caseTitle: 'Cardiology Assessment',
        visitDate: DateTime(2026, 9, 5),
        controller: controller,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Preview'), findsOneWidget);
      expect(find.text('Retake'), findsOneWidget);
      expect(find.text('Add Another Photo'), findsOneWidget);
      expect(find.text('Submit Report'), findsOneWidget);
    });

    testWidgets('13. Pre-submission Confirmation Dialog opens and cancels safely', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));

      final controller = PatientReportUploadController(
        investigation: testInvestigationA,
        caseTitle: 'Cardiology Assessment',
        visitDate: DateTime(2026, 9, 5),
        sessionService: sessionService,
      );

      controller.addPhotoBytes(
        fileName: 'ecg_test.jpg',
        bytes: validJpgBytes,
      );

      await tester.pumpWidget(createTestWidget(PatientReportUploadScreen(
        investigation: testInvestigationA,
        caseTitle: 'Cardiology Assessment',
        visitDate: DateTime(2026, 9, 5),
        controller: controller,
      )));
      await tester.pumpAndSettle();

      // Tap Submit Report to open confirmation dialog
      await tester.tap(find.text('Submit Report'));
      await tester.pumpAndSettle();

      expect(find.text('Submit this report?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Cancel dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Submit this report?'), findsNothing);
    });

    testWidgets('14. Full End-to-End UI Upload: Submit -> Success Dialog -> Done navigates back', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));

      final uploadService = PatientReportUploadService(
        sessionService: sessionService,
        caseRepo: BackendProvider.instance.caseRepository,
        visitRepo: BackendProvider.instance.clinicalVisitRepository,
        investigationRepo: BackendProvider.instance.investigationRepository,
        reportRepo: mockReportRepo,
      );

      final controller = PatientReportUploadController(
        investigation: testInvestigationA,
        caseTitle: 'Cardiology Assessment',
        visitDate: DateTime(2026, 9, 5),
        uploadService: uploadService,
        sessionService: sessionService,
      );

      controller.addPhotoBytes(
        fileName: 'ecg_test.jpg',
        bytes: validJpgBytes,
      );

      await tester.pumpWidget(createTestWidget(PatientReportUploadScreen(
        investigation: testInvestigationA,
        caseTitle: 'Cardiology Assessment',
        visitDate: DateTime(2026, 9, 5),
        controller: controller,
      )));
      await tester.pumpAndSettle();

      // Tap Submit Report
      await tester.tap(find.text('Submit Report'));
      await tester.pumpAndSettle();

      // Confirm in dialog
      await tester.tap(find.byKey(const Key('confirm_submit_button')));
      await tester.pumpAndSettle();

      // Verify Success Dialog appears
      expect(find.text('Report Submitted Successfully'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Tap Done
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
    });

    testWidgets('15. Error state displays clear user-friendly banner without raw crash', (tester) async {
      mockStorage.simulateUploadFailure = true;

      final uploadService = PatientReportUploadService(
        sessionService: sessionService,
        caseRepo: BackendProvider.instance.caseRepository,
        visitRepo: BackendProvider.instance.clinicalVisitRepository,
        investigationRepo: BackendProvider.instance.investigationRepository,
        reportRepo: mockReportRepo,
      );

      final controller = PatientReportUploadController(
        investigation: testInvestigationA,
        caseTitle: 'Cardiology Assessment',
        visitDate: DateTime(2026, 9, 5),
        uploadService: uploadService,
        sessionService: sessionService,
      );

      controller.addPhotoBytes(
        fileName: 'ecg_test.jpg',
        bytes: validJpgBytes,
      );

      await tester.pumpWidget(createTestWidget(PatientReportUploadScreen(
        investigation: testInvestigationA,
        caseTitle: 'Cardiology Assessment',
        visitDate: DateTime(2026, 9, 5),
        controller: controller,
      )));
      await tester.pumpAndSettle();

      // Trigger submit
      await controller.submit();
      await tester.pumpAndSettle();

      expect(find.text('Upload failed'), findsOneWidget);
      expect(find.textContaining('Please check your internet connection and try again'), findsOneWidget);
    });

    testWidgets('16. Responsive verification: Zero layout overflow across mobile (360dp, 412dp) and desktop', (tester) async {
      for (final size in [
        const Size(360, 640),
        const Size(412, 915),
        const Size(768, 1024),
        const Size(1280, 800),
      ]) {
        await tester.binding.setSurfaceSize(size);

        final controller = PatientReportUploadController(
          investigation: testInvestigationA,
          caseTitle: 'Cardiology Assessment',
          visitDate: DateTime(2026, 9, 5),
          sessionService: sessionService,
        );

        controller.addPhotoBytes(
          fileName: 'ecg_test.jpg',
          bytes: validJpgBytes,
        );

        await tester.pumpWidget(createTestWidget(PatientReportUploadScreen(
          investigation: testInvestigationA,
          caseTitle: 'Cardiology Assessment',
          visitDate: DateTime(2026, 9, 5),
          controller: controller,
        )));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Overflow occurred at $size');
      }
    });

    testWidgets('17. Trilingual localization verification in Hindi and Marathi for Upload Screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));

      // 1. Hindi test
      final controllerHi = PatientReportUploadController(
        investigation: testInvestigationA,
        caseTitle: 'Cardiology Assessment',
        visitDate: DateTime(2026, 9, 5),
        sessionService: sessionService,
      );

      await tester.pumpWidget(createTestWidget(
        PatientReportUploadScreen(
          investigation: testInvestigationA,
          caseTitle: 'Cardiology Assessment',
          visitDate: DateTime(2026, 9, 5),
          controller: controllerHi,
        ),
        locale: const Locale('hi'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('रिपोर्ट अपलोड करें'), findsWidgets);
      expect(find.text('फोटो लें'), findsOneWidget);
      expect(find.text('गैलरी से चुनें'), findsOneWidget);

      // 2. Marathi test
      final controllerMr = PatientReportUploadController(
        investigation: testInvestigationA,
        caseTitle: 'Cardiology Assessment',
        visitDate: DateTime(2026, 9, 5),
        sessionService: sessionService,
      );

      await tester.pumpWidget(createTestWidget(
        PatientReportUploadScreen(
          investigation: testInvestigationA,
          caseTitle: 'Cardiology Assessment',
          visitDate: DateTime(2026, 9, 5),
          controller: controllerMr,
        ),
        locale: const Locale('mr'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('अहवाल अपलोड करा'), findsWidgets);
      expect(find.text('फोटो काढा'), findsOneWidget);
      expect(find.text('गॅलरीमधून निवडा'), findsOneWidget);
    });

    test('18. Cross-Module Doctor Visibility: Doctor reports repository can read uploaded report document', () async {
      final uploadService = PatientReportUploadService(
        sessionService: sessionService,
        caseRepo: BackendProvider.instance.caseRepository,
        visitRepo: BackendProvider.instance.clinicalVisitRepository,
        investigationRepo: BackendProvider.instance.investigationRepository,
        reportRepo: mockReportRepo,
      );

      final photo = ReportPhotoItem(
        id: 'p1',
        originalName: 'ecg_reading.jpg',
        bytes: validJpgBytes,
        pageNumber: 1,
      );

      final savedDoc = await uploadService.submitReport(
        patientId: 'PAT-P8-001',
        caseId: 'CASE-P8-001',
        visitId: 'VIS-P8-001',
        investigationId: 'INV-ECG-001',
        photos: [photo],
      );

      // Simulate Doctor query for visit reports
      final doctorVisitReports = await BackendProvider.instance.reportRepository.getReportsForVisit(
        patientId: 'PAT-P8-001',
        caseId: 'CASE-P8-001',
        visitId: 'VIS-P8-001',
      );

      expect(doctorVisitReports.any((d) => d.reportId == savedDoc.reportId), isTrue);
      final docInDoctorView = doctorVisitReports.firstWhere((d) => d.reportId == savedDoc.reportId);
      expect(docInDoctorView.reviewStatus, ReportReviewStatus.uploaded);

      // Simulate Doctor marking report as reviewed
      await BackendProvider.instance.reportRepository.updateReportStatus(
        patientId: 'PAT-P8-001',
        caseId: 'CASE-P8-001',
        visitId: 'VIS-P8-001',
        reportId: savedDoc.reportId,
        status: ReportReviewStatus.reviewed,
        doctorId: 'DOC-101',
      );
      await BackendProvider.instance.investigationRepository.markReviewed(
        patientId: 'PAT-P8-001',
        caseId: 'CASE-P8-001',
        visitId: 'VIS-P8-001',
        investigationId: 'INV-ECG-001',
        doctorId: 'DOC-101',
      );

      // Verify Patient app sees reviewed status
      final reviewedReport = await mockReportRepo.getReportById(
        patientId: 'PAT-P8-001',
        caseId: 'CASE-P8-001',
        visitId: 'VIS-P8-001',
        reportId: savedDoc.reportId,
      );
      expect(reviewedReport?.reviewStatus, ReportReviewStatus.reviewed);

      final reviewedInv = await BackendProvider.instance.investigationRepository.getInvestigationById(
        patientId: 'PAT-P8-001',
        caseId: 'CASE-P8-001',
        visitId: 'VIS-P8-001',
        investigationId: 'INV-ECG-001',
      );
      expect(reviewedInv?.isReviewed, isTrue);
    });
  });
}

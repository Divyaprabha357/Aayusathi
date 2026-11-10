import 'package:flutter/foundation.dart';
import '../../core/backend/backend_exception.dart';
import '../../core/backend/backend_mode.dart';
import '../../doctor/models/report_document.dart';
import '../../repositories/case_repository.dart';
import '../../repositories/clinical_visit_repository.dart';
import '../../repositories/investigation_repository.dart';
import '../../repositories/report_repository.dart';
import '../services/patient_report_file_validator.dart';
import '../services/patient_session_service.dart';

/// Single selected photo item for patient report upload (supports multi-page reports).
class ReportPhotoItem {
  final String id;
  final String originalName;
  final List<int> bytes;
  final String? mimeType;
  final int pageNumber;

  const ReportPhotoItem({
    required this.id,
    required this.originalName,
    required this.bytes,
    this.mimeType,
    required this.pageNumber,
  });

  int get sizeBytes => bytes.length;
}

/// Service orchestrating the complete patient medical report upload lifecycle in Phase P8.
///
/// Ensures:
/// 1. Strict authenticated session and patient ownership verification.
/// 2. Duplicate submission prevention.
/// 3. Strict photo validation (JPG/PNG, magic bytes, 15MB limit, no path traversal).
/// 4. Supabase private bucket upload before Firestore metadata write.
/// 5. Safe recovery and retry without orphan duplicate metadata.
class PatientReportUploadService {
  final PatientSessionService _sessionService;
  final CaseRepository _caseRepo;
  final ClinicalVisitRepository _visitRepo;
  final InvestigationRepository _investigationRepo;
  final ReportRepository _reportRepo;

  PatientReportUploadService({
    PatientSessionService? sessionService,
    CaseRepository? caseRepo,
    ClinicalVisitRepository? visitRepo,
    InvestigationRepository? investigationRepo,
    ReportRepository? reportRepo,
  })  : _sessionService = sessionService ?? PatientSessionService.instance,
        _caseRepo = caseRepo ?? BackendProvider.instance.caseRepository,
        _visitRepo = visitRepo ?? BackendProvider.instance.clinicalVisitRepository,
        _investigationRepo = investigationRepo ?? BackendProvider.instance.investigationRepository,
        _reportRepo = reportRepo ?? BackendProvider.instance.reportRepository;

  static final PatientReportUploadService instance = PatientReportUploadService();

  /// Submits one or more report photos for a specific patient investigation.
  ///
  /// Returns the primary saved [ReportDocument].
  Future<ReportDocument> submitReport({
    required String patientId,
    required String caseId,
    required String visitId,
    required String investigationId,
    required List<ReportPhotoItem> photos,
    String? notes,
  }) async {
    // 1. Session & Ownership Verification
    final authenticatedId = _sessionService.authenticatedPatientId;
    if (!_sessionService.isAuthenticated || authenticatedId == null || authenticatedId.isEmpty) {
      throw BackendException(
        code: BackendException.permissionDenied,
        message: 'Your session has expired. Please log in again.',
      );
    }

    final cleanInputPatientId = patientId.replaceAll(RegExp(r'\s+'), '').toUpperCase().trim();
    final cleanAuthPatientId = authenticatedId.replaceAll(RegExp(r'\s+'), '').toUpperCase().trim();

    if (cleanInputPatientId != cleanAuthPatientId) {
      debugPrint(
        '[PatientReportUploadService] Security violation: Session $cleanAuthPatientId attempted upload for $cleanInputPatientId',
      );
      throw BackendException(
        code: BackendException.permissionDenied,
        message: 'Security violation: Cannot upload reports for another patient.',
      );
    }

    // 2. Validate Case Ownership
    final patientCases = await _caseRepo.getCasesForPatient(cleanAuthPatientId);
    final hasCase = patientCases.any((c) => c.caseId == caseId.trim());
    if (!hasCase) {
      throw BackendException(
        code: BackendException.permissionDenied,
        message: 'Case not found or does not belong to your account.',
      );
    }

    // 3. Validate Visit Ownership
    final caseVisits = await _visitRepo.getVisitsForCase(
      patientId: cleanAuthPatientId,
      caseId: caseId.trim(),
    );
    final hasVisit = caseVisits.any((v) => v.visitId == visitId.trim());
    if (!hasVisit) {
      throw BackendException(
        code: BackendException.permissionDenied,
        message: 'Clinical visit not found or does not belong to this case.',
      );
    }

    // 4. Validate Investigation Ownership & Status
    final investigation = await _investigationRepo.getInvestigationById(
      patientId: cleanAuthPatientId,
      caseId: caseId.trim(),
      visitId: visitId.trim(),
      investigationId: investigationId.trim(),
    );

    if (investigation == null) {
      throw BackendException(
        code: BackendException.notFound,
        message: 'Investigation request not found.',
      );
    }

    // 5. Duplicate Submission Prevention
    if (investigation.isUploaded || investigation.isReviewed) {
      throw BackendException(
        code: BackendException.invalidData,
        message: 'This report has already been submitted for review.',
      );
    }

    final existingReport = await _reportRepo.getReportForInvestigation(
      patientId: cleanAuthPatientId,
      caseId: caseId.trim(),
      visitId: visitId.trim(),
      investigationId: investigationId.trim(),
    );
    if (existingReport != null) {
      throw BackendException(
        code: BackendException.invalidData,
        message: 'A report document has already been uploaded for this investigation.',
      );
    }

    // 6. Validate Selected Files / Photos
    if (photos.isEmpty) {
      throw BackendException(
        code: BackendException.invalidData,
        message: 'Please take or select at least one report file.',
      );
    }

    for (final photo in photos) {
      final validation = PatientReportFileValidator.validateReportFile(
        fileName: photo.originalName,
        bytes: photo.bytes,
        declaredMimeType: photo.mimeType,
        allowPdf: true,
      );
      if (!validation.isValid) {
        throw BackendException(
          code: BackendException.invalidData,
          message: validation.errorMessage ?? 'Invalid report file.',
        );
      }
    }

    final storage = BackendProvider.instance.storageService;
    ReportDocument? primarySavedDoc;

    // 7. Upload Files to Supabase Private Bucket first
    final uploadedPages = <Map<String, dynamic>>[];

    try {
      for (int i = 0; i < photos.length; i++) {
        final photo = photos[i];
        final extIndex = photo.originalName.lastIndexOf('.');
        final ext = extIndex != -1 ? photo.originalName.substring(extIndex) : '.jpg';

        final safeFileName = PatientReportFileValidator.generateSafeFileName(
          patientId: cleanAuthPatientId,
          investigationId: investigationId.trim(),
          extension: ext,
          timestamp: DateTime.now().millisecondsSinceEpoch + i,
        );

        final validation = PatientReportFileValidator.validateReportFile(
          fileName: photo.originalName,
          bytes: photo.bytes,
          declaredMimeType: photo.mimeType,
          allowPdf: true,
        );

        final effectiveMime = validation.detectedMimeType ??
            (ext.toLowerCase() == '.pdf' ? 'application/pdf' : 'image/jpeg');

        final storagePath = await storage.uploadReportFile(
          patientId: cleanAuthPatientId,
          caseId: caseId.trim(),
          visitId: visitId.trim(),
          investigationId: investigationId.trim(),
          fileName: safeFileName,
          bytes: photo.bytes,
          contentType: effectiveMime,
        );

        // Explicit physical storage verification before metadata creation
        final exists = await storage.fileExists(storagePath);
        if (!exists) {
          throw BackendException(
            code: BackendException.unavailable,
            message: 'Report storage verification failed for $safeFileName. Object was not confirmed in storage.',
          );
        }

        uploadedPages.add({
          'safeFileName': safeFileName,
          'storagePath': storagePath,
          'contentType': effectiveMime,
          'fileSizeBytes': photo.sizeBytes,
        });
      }
    } on BackendException {
      rethrow;
    } catch (e) {
      debugPrint('[PatientReportUploadService] Supabase upload failed: $e');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Could not upload report file. Please check your internet connection and try again.',
        originalError: e,
      );
    }

    // 8. Write ReportDocument metadata to Firestore
    try {
      for (int i = 0; i < uploadedPages.length; i++) {
        final pageData = uploadedPages[i];
        final pageSuffix = uploadedPages.length > 1 ? '-P${i + 1}' : '';
        final reportDocId =
            'REP-${investigationId.trim()}-${DateTime.now().millisecondsSinceEpoch}$pageSuffix';

        final reportDoc = ReportDocument(
          reportId: reportDocId,
          patientId: cleanAuthPatientId,
          caseId: caseId.trim(),
          visitId: visitId.trim(),
          investigationId: investigationId.trim(),
          fileName: pageData['safeFileName'] as String,
          contentType: pageData['contentType'] as String,
          fileSizeBytes: pageData['fileSizeBytes'] as int,
          storagePath: pageData['storagePath'] as String,
          storageProvider: 'supabase',
          storageBucket: 'aayusathi-reports',
          uploadedAt: DateTime.now(),
          uploadedByPatientId: cleanAuthPatientId,
          reviewStatus: ReportReviewStatus.uploaded,
          notes: notes,
        );

        final saved = await _reportRepo.saveReportDocument(reportDoc);
        if (i == 0) {
          primarySavedDoc = saved;
        }
      }
    } catch (e) {
      debugPrint('[PatientReportUploadService] Firestore metadata write failed: $e');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Failed to record report submission. Please try again to complete submission.',
        originalError: e,
      );
    }

    // 9. Update Investigation status to UPLOADED
    try {
      await _investigationRepo.markUploaded(
        patientId: cleanAuthPatientId,
        caseId: caseId.trim(),
        visitId: visitId.trim(),
        investigationId: investigationId.trim(),
        reportId: primarySavedDoc!.reportId,
      );
    } catch (e) {
      debugPrint('[PatientReportUploadService] Warning: Failed to mark investigation uploaded: $e');
      // If markUploaded fails after metadata is saved, retry once
      try {
        await _investigationRepo.markUploaded(
          patientId: cleanAuthPatientId,
          caseId: caseId.trim(),
          visitId: visitId.trim(),
          investigationId: investigationId.trim(),
          reportId: primarySavedDoc!.reportId,
        );
      } catch (_) {}
    }

    debugPrint(
      '[PatientReportUploadService] Report ${primarySavedDoc!.reportId} submitted successfully for investigation $investigationId',
    );
    return primarySavedDoc;
  }
}

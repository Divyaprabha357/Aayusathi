import 'package:flutter/foundation.dart';
import '../../core/backend/backend_exception.dart';
import '../../core/backend/backend_mode.dart';
import '../../doctor/models/investigation_request.dart';
import '../../doctor/models/report_document.dart';

/// Reusable domain service for the Patient application to retrieve requested investigations
/// and securely upload corresponding medical reports.
///
/// Hierarchy:
/// `patients/{patientId}/cases/{caseId}/visits/{visitId}/investigations/{investigationId}`
class PatientInvestigationService {
  static final PatientInvestigationService instance =
      PatientInvestigationService._();
  PatientInvestigationService._();
  factory PatientInvestigationService() => instance;

  /// Retrieves all diagnostic investigations requested for a specific patient visit.
  Future<List<InvestigationRequest>> getPendingInvestigations({
    required String patientId,
    required String caseId,
    required String visitId,
  }) async {
    final repo = BackendProvider.instance.investigationRepository;
    final all = await repo.getInvestigationRequests(
      patientId: patientId,
      caseId: caseId,
      visitId: visitId,
    );
    return all.where((r) => r.isPendingUpload).toList();
  }

  /// Uploads a report document for a specific investigation request.
  ///
  /// Strictly links the upload to [patientId], [caseId], [visitId], and [investigationId].
  Future<ReportDocument> uploadReport({
    required String patientId,
    required String caseId,
    required String visitId,
    required String investigationId,
    required String fileName,
    required List<int> fileBytes,
    String? mimeType,
    String? notes,
  }) async {
    if (patientId.trim().isEmpty ||
        caseId.trim().isEmpty ||
        visitId.trim().isEmpty ||
        investigationId.trim().isEmpty) {
      throw BackendException(
        code: BackendException.invalidData,
        message: 'All identifier parameters (patient, case, visit, investigation) are required for report upload.',
      );
    }

    final storage = BackendProvider.instance.storageService;
    final validation = storage.validateFile(
      fileName: fileName,
      bytes: fileBytes,
      mimeType: mimeType,
    );

    if (!validation.isValid) {
      throw BackendException(
        code: BackendException.invalidData,
        message: validation.errorMessage ?? 'Invalid report file.',
      );
    }

    final effectiveMimeType = validation.detectedMimeType ?? 'application/pdf';

    // 1. Upload binary file to Storage
    final storagePath = await storage.uploadReportFile(
      patientId: patientId,
      caseId: caseId,
      visitId: visitId,
      investigationId: investigationId,
      fileName: fileName,
      bytes: fileBytes,
      contentType: effectiveMimeType,
    );

    // 2. Save Document Metadata
    final reportDoc = ReportDocument(
      reportId: 'REP-$investigationId-${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      caseId: caseId,
      visitId: visitId,
      investigationId: investigationId,
      fileName: fileName,
      contentType: effectiveMimeType,
      fileSizeBytes: fileBytes.length,
      storagePath: storagePath,
      uploadedAt: DateTime.now(),
      uploadedByPatientId: patientId,
      reviewStatus: ReportReviewStatus.uploaded,
      notes: notes,
    );

    final savedDoc = await BackendProvider.instance.reportRepository
        .saveReportDocument(reportDoc);

    // 3. Update Investigation status to UPLOADED
    await BackendProvider.instance.investigationRepository.markUploaded(
      patientId: patientId,
      caseId: caseId,
      visitId: visitId,
      investigationId: investigationId,
      reportId: savedDoc.reportId,
    );

    debugPrint(
        '[PatientInvestigationService] Successfully uploaded report ${savedDoc.reportId} for investigation $investigationId');

    return savedDoc;
  }
}

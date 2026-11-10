import 'package:flutter/foundation.dart';
import '../../core/backend/backend_mode.dart';
import '../../doctor/models/report_document.dart';

/// Contract and service managing patient diagnostic report retrieval and time-limited
/// signed URL access for the future Patient Application.
///
/// Security & Architecture:
/// - Firebase Firestore remains the authoritative source for document metadata.
/// - Supabase Storage (`aayusathi-reports`) holds the private binary files.
/// - Access URLs are strictly short-lived signed URLs (never permanent public URLs).
class PatientReportAccessService {
  static final PatientReportAccessService instance =
      PatientReportAccessService._();
  PatientReportAccessService._();
  factory PatientReportAccessService() => instance;

  /// Retrieves all diagnostic reports and visit documentation for a specific patient.
  Future<List<ReportDocument>> getPatientReports(String patientId) async {
    final cleanId = patientId.trim().toUpperCase();
    if (cleanId.isEmpty) return [];

    try {
      final caseRepo = BackendProvider.instance.caseRepository;
      final visitRepo = BackendProvider.instance.clinicalVisitRepository;
      final reportRepo = BackendProvider.instance.reportRepository;

      final cases = await caseRepo.getCasesForPatient(cleanId);
      final allReports = <ReportDocument>[];

      for (final c in cases) {
        final visits = await visitRepo.getVisitsForCase(
          patientId: cleanId,
          caseId: c.caseId,
        );

        for (final v in visits) {
          try {
            final reports = await reportRepo.getReportsForVisit(
              patientId: cleanId,
              caseId: c.caseId,
              visitId: v.visitId,
            );
            allReports.addAll(reports);
          } catch (e) {
            debugPrint('[PatientReportAccessService] Warning reading reports for visit ${v.visitId}: $e');
          }
        }
      }

      allReports.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return allReports;
    } catch (e) {
      debugPrint('[PatientReportAccessService] Error querying patient reports: $e');
      return [];
    }
  }

  /// Retrieves all reports linked to a specific clinical visit.
  Future<List<ReportDocument>> getVisitReports({
    required String patientId,
    required String caseId,
    required String visitId,
  }) async {
    final cleanId = patientId.trim().toUpperCase();
    if (cleanId.isEmpty || caseId.isEmpty || visitId.isEmpty) return [];

    try {
      final reportRepo = BackendProvider.instance.reportRepository;
      return await reportRepo.getReportsForVisit(
        patientId: cleanId,
        caseId: caseId,
        visitId: visitId,
      );
    } catch (e) {
      debugPrint('[PatientReportAccessService] Error querying visit reports: $e');
      return [];
    }
  }

  /// Generates a time-limited signed URL for securely streaming or viewing a private report file.
  ///
  /// Returns null if the file cannot be found or storage is offline.
  Future<String?> getReportAccessUrl({
    required String storagePath,
    Duration? expiresIn,
  }) async {
    if (storagePath.trim().isEmpty) return null;

    try {
      final storage = BackendProvider.instance.storageService;
      return await storage.getSignedUrl(storagePath, expiresIn: expiresIn);
    } catch (e) {
      debugPrint('[PatientReportAccessService] Error generating signed URL for $storagePath: $e');
      return null;
    }
  }

  /// Helper to generate a time-limited signed URL directly from a [ReportDocument].
  Future<String?> getReportAccessUrlByDocument(
    ReportDocument document, {
    Duration? expiresIn,
  }) {
    return getReportAccessUrl(
      storagePath: document.storagePath,
      expiresIn: expiresIn,
    );
  }
}

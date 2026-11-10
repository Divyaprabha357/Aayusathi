import '../doctor/models/report_document.dart';

/// Abstract repository managing uploaded patient diagnostic report documents and metadata.
///
/// Hierarchy:
/// `patients/{patientId}/cases/{caseId}/visits/{visitId}/reports/{reportId}`
abstract class ReportRepository {
  /// Saves a new report document metadata record.
  Future<ReportDocument> saveReportDocument(ReportDocument report);

  /// Retrieves all report documents for a clinical visit.
  Future<List<ReportDocument>> getReportsForVisit({
    required String patientId,
    required String caseId,
    required String visitId,
  });

  /// Emits real-time updates of all report documents for a clinical visit.
  Stream<List<ReportDocument>> watchReportsForVisit({
    required String patientId,
    required String caseId,
    required String visitId,
  }) =>
      Stream.fromFuture(getReportsForVisit(
        patientId: patientId,
        caseId: caseId,
        visitId: visitId,
      ));

  /// Retrieves a specific report document by ID.
  Future<ReportDocument?> getReportById({
    required String patientId,
    required String caseId,
    required String visitId,
    required String reportId,
  });

  /// Retrieves the report document associated with a specific investigation request.
  Future<ReportDocument?> getReportForInvestigation({
    required String patientId,
    required String caseId,
    required String visitId,
    required String investigationId,
  });

  /// Updates the doctor review status of a report document.
  Future<void> updateReportStatus({
    required String patientId,
    required String caseId,
    required String visitId,
    required String reportId,
    required ReportReviewStatus status,
    required String doctorId,
  });

  /// Saves or updates the AI medical report summary for a specific report document.
  Future<void> saveReportAiSummary({
    required String patientId,
    required String caseId,
    required String visitId,
    required String reportId,
    required AiReportSummaryRecord summary,
  });

  /// Retrieves the AI medical report summary for a specific report document.
  Future<AiReportSummaryRecord?> getReportAiSummary({
    required String patientId,
    required String caseId,
    required String visitId,
    required String reportId,
  });
}

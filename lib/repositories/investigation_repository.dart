import '../doctor/models/investigation_request.dart';

/// Abstract repository managing diagnostic and laboratory investigation requests.
///
/// Hierarchy:
/// `patients/{patientId}/cases/{caseId}/visits/{visitId}/investigations/{investigationId}`
abstract class InvestigationRepository {
  /// Creates a new diagnostic investigation request for a clinical visit.
  Future<InvestigationRequest> createInvestigationRequest(
    InvestigationRequest request,
  );

  /// Retrieves all investigation requests associated with a clinical visit.
  Future<List<InvestigationRequest>> getInvestigationRequests({
    required String patientId,
    required String caseId,
    required String visitId,
  });

  /// Retrieves a specific investigation request by ID.
  Future<InvestigationRequest?> getInvestigationById({
    required String patientId,
    required String caseId,
    required String visitId,
    required String investigationId,
  });

  /// Updates status and reviewer details of an investigation.
  Future<void> updateInvestigationStatus({
    required String patientId,
    required String caseId,
    required String visitId,
    required String investigationId,
    required InvestigationStatus status,
    String? doctorId,
    String? reportId,
  });

  /// Convenience method: Marks an investigation request as UPLOADED with linked report ID.
  Future<void> markUploaded({
    required String patientId,
    required String caseId,
    required String visitId,
    required String investigationId,
    required String reportId,
  });

  /// Convenience method: Marks an investigation request as REVIEWED by a doctor.
  Future<void> markReviewed({
    required String patientId,
    required String caseId,
    required String visitId,
    required String investigationId,
    required String doctorId,
  });

  /// Deletes or cancels an investigation request.
  Future<void> deleteInvestigation({
    required String patientId,
    required String caseId,
    required String visitId,
    required String investigationId,
  });
}

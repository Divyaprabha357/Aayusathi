import '../models/previous_visit_record.dart';

/// Abstract contract for patient consultation visit persistence and query.
abstract class VisitRepository {
  /// Persists a new or updated visit record.
  Future<void> saveVisit(PreviousVisitRecord visit);

  /// Retrieves the most recent prior consultation record for a specific patient in a given medical domain.
  Future<PreviousVisitRecord?> getLatestVisitForPatientAndDomain({
    required String patientId,
    required String domainId,
  });

  /// Retrieves all prior consultation visits for a given patient.
  Future<List<PreviousVisitRecord>> getVisitsForPatient(String patientId);
}

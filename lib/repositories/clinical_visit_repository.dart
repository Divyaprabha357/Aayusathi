import '../doctor/models/clinical_visit.dart';
import '../models/vital_reading.dart';

/// Abstract contract for clinical consultation encounter visits persistence and queries.
abstract class ClinicalVisitRepository {
  /// Retrieves all visits recorded under a specific [caseId] for a [patientId].
  Future<List<ClinicalVisit>> getVisitsForCase({
    required String patientId,
    required String caseId,
  });

  /// Retrieves a single visit by its identifiers.
  Future<ClinicalVisit?> getVisitById({
    required String patientId,
    required String caseId,
    required String visitId,
  });

  /// Creates and persists a new consultation encounter visit.
  Future<ClinicalVisit> createVisit(ClinicalVisit visit);

  /// Updates an existing consultation encounter visit.
  Future<void> updateVisit(ClinicalVisit visit);

  /// Computes the next sequential visit number for the given [caseId] (1-indexed).
  Future<int> getNextVisitNumber({
    required String patientId,
    required String caseId,
  });

  /// Retrieves the active consultation visit for a specific [caseId] if one exists.
  Future<ClinicalVisit?> getActiveVisitForCase({
    required String patientId,
    required String caseId,
  });

  /// Atomically creates the next sequential visit for an existing open case.
  ///
  /// Guarantees:
  /// - Verifies no active consultation visit already exists for this case.
  /// - Assigns the next sequential visit number (1, 2, 3...) per case.
  /// - Initializes visit status to [ClinicalVisitStatus.active].
  Future<ClinicalVisit> createNextVisit({
    required String patientId,
    required String caseId,
    required String doctorId,
    required String doctorName,
    String? doctorQualification,
    String? appointmentId,
    String? chiefComplaint,
    VitalReading? vitals,
    String? department,
  });

  /// Completes an active consultation encounter visit.
  ///
  /// Validation & Guarantees:
  /// - Visit must be in [ClinicalVisitStatus.active] state.
  /// - Sets [completedAt] and [completedByDoctorId].
  /// - Parent Case strictly remains open.
  Future<ClinicalVisit> completeVisit({
    required String patientId,
    required String caseId,
    required String visitId,
    required String doctorId,
  });
}

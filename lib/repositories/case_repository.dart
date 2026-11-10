import '../doctor/models/clinical_case.dart';

/// Abstract contract for patient clinical case persistence and queries.
abstract class CaseRepository {
  /// Retrieves all clinical cases associated with a given [patientId].
  Future<List<ClinicalCase>> getCasesForPatient(String patientId);

  /// Retrieves a specific clinical case by its [patientId] and [caseId].
  Future<ClinicalCase?> getCaseById({
    required String patientId,
    required String caseId,
  });

  /// Persists a new clinical case for a patient.
  Future<ClinicalCase> createCase(ClinicalCase clinicalCase);

  /// Updates an existing clinical case.
  Future<void> updateCase(ClinicalCase clinicalCase);

  /// Atomically closes an existing OPEN clinical case with doctor declaration and closure note.
  Future<ClinicalCase> closeCase({
    required String patientId,
    required String caseId,
    required String doctorId,
    String? doctorName,
    required String closureNote,
  });

  /// Retrieves all clinical cases across patients (for Cases & Visits desk).
  Future<List<ClinicalCase>> getAllCases();

  /// Retrieves clinical cases where [doctorId] is the attending, consulting, or closing doctor.
  Future<List<ClinicalCase>> getCasesForDoctor(String doctorId);

  /// Atomically escalates an existing OPEN clinical case for administrative / higher-authority review.
  ///
  /// Concurrency & Safeguards:
  /// - Case must be OPEN (`status == ClinicalCaseStatus.open`).
  /// - Case must not already be escalated (`escalationStatus == CaseEscalationStatus.none`).
  /// - Active visit remains active; case remains open.
  Future<ClinicalCase> escalateCase({
    required String patientId,
    required String caseId,
    required String visitId,
    required String doctorId,
    String? doctorName,
    required CaseEscalationReason reason,
    String? note,
  });

  /// Atomically marks an escalated case as under administrative review.
  ///
  /// Concurrency:
  /// - Case must currently be in `CaseEscalationStatus.escalated`.
  /// - Transitions status to `CaseEscalationStatus.underReview`.
  Future<ClinicalCase> startAdminCaseReview({
    required String patientId,
    required String caseId,
    required String adminId,
  });

  /// Real-time stream of all escalated / under-review clinical cases across all patients.
  Stream<List<ClinicalCase>> watchEscalatedCases();

  /// Retrieves all currently escalated / under-review clinical cases across all patients.
  Future<List<ClinicalCase>> getEscalatedCases();

  /// Verifies if a doctor has authorization to view or consult on a specific case.
  Future<bool> isDoctorAuthorizedForCase({
    required String doctorId,
    required String caseId,
    required String patientId,
  });

  /// Atomically assigns an escalated clinical case to an eligible higher-authority doctor.
  ///
  /// Concurrency & Safeguards:
  /// - Case must be OPEN (`status == ClinicalCaseStatus.open`).
  /// - Case must be escalated or underReview.
  /// - Case must not already be assigned to a higher-authority doctor.
  /// - Target doctor must be active, available, not in consultation, not source doctor.
  /// - Target doctor authority level must be > source doctor authority level.
  Future<ClinicalCase> assignHigherAuthorityDoctor({
    required String patientId,
    required String caseId,
    required String targetDoctorId,
    required String targetDoctorName,
    required String targetDepartment,
    required String assignedByAdminId,
    String? crossDepartmentReason,
  });

  /// Atomically marks a higher-authority case assignment as accepted by the assigned doctor.
  Future<ClinicalCase> acceptHigherAuthorityAssignment({
    required String patientId,
    required String caseId,
    required String doctorId,
  });
}


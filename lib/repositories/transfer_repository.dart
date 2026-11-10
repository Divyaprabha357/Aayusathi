import '../doctor/models/doctor_assignment_result.dart';
import '../doctor/models/patient_transfer_request.dart';

/// Abstract contract for patient inter-department transfer requests and lifecycle operations.
abstract class TransferRepository {
  /// Creates and persists a new inter-department transfer request in [TransferStatus.pending] state.
  Future<PatientTransferRequest> createTransfer(PatientTransferRequest transfer);

  /// Retrieves a transfer request by its unique [transferId].
  Future<PatientTransferRequest?> getTransferById(String transferId);

  /// Retrieves all pending transfer requests destined for the specified [department].
  Future<List<PatientTransferRequest>> getPendingTransfersForDepartment(
      String department);

  /// Atomically claims and accepts a pending transfer request for the destination doctor.
  /// Enforces first-doctor-wins semantics, eligibility, presence, and atomic status transition.
  Future<DoctorAssignmentResult> acceptTransfer({
    required String transferId,
    required String doctorId,
    required String doctorName,
    required String doctorDepartment,
  });

  /// Cancels a pending transfer request if initiated by the authorized [doctorId].
  Future<bool> cancelTransfer({
    required String transferId,
    required String doctorId,
  });

  /// Retrieves all transfer requests for a given [patientId].
  Future<List<PatientTransferRequest>> getTransfersForPatient(String patientId);

  /// Retrieves all transfer requests for a specific [caseId] of a patient.
  Future<List<PatientTransferRequest>> getTransfersForCase({
    required String patientId,
    required String caseId,
  });

  /// Retrieves all transfer requests for a specific [visitId] of a case.
  Future<List<PatientTransferRequest>> getTransfersForVisit({
    required String patientId,
    required String caseId,
    required String visitId,
  });
}

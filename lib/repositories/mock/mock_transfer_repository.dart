import 'package:flutter/foundation.dart';
import '../../core/backend/backend_exception.dart';
import '../../doctor/models/doctor_assignment_result.dart';
import '../../doctor/models/patient_transfer_request.dart';
import '../../models/vital_reading.dart';
import '../transfer_repository.dart';

/// In-memory mock implementation of [TransferRepository] for testing and Phase D13 dev mode.
///
/// Ensures zero Firebase writes in dev mode, deterministic fixtures,
/// and atomic first-doctor-wins race condition simulation.
class MockTransferRepository implements TransferRepository {
  static final MockTransferRepository instance = MockTransferRepository._();
  MockTransferRepository._() {
    resetToDefaults();
  }
  factory MockTransferRepository() => instance;

  final Map<String, PatientTransferRequest> _transfers = {};
  bool simulateError = false;
  bool simulateAcceptanceRace = false;

  /// Default demo transfer fixture
  static List<PatientTransferRequest> get defaultDemoTransfers => [
        PatientTransferRequest(
          transferId: 'TRF-DEMO-001',
          patientId: 'PAT-MOCK-001',
          caseId: 'CASE-PAT-001-01',
          sourceVisitId: 'VIS-PAT-001-01-1',
          sourceDoctorId: 'DOC-101',
          sourceDoctorName: 'Dr. Rajesh Sharma',
          sourceDepartment: 'Cardiology',
          destinationDepartment: 'Neurology',
          reason: 'Requires neurological evaluation for transient dizziness.',
          requestedAt: DateTime.now().subtract(const Duration(minutes: 20)),
          status: TransferStatus.pending,
          queueNumber: 'A-00027',
          patientAge: 42,
          patientGender: 'Male',
          vitals: VitalReading(
            vitalId: 'VIT-MOCK-001',
            patientId: 'PAT-MOCK-001',
            appointmentId: 'APT-D5-001',
            spo2: 97,
            heartRate: 78,
            temperature: 36.8,
            timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
            status: VitalStatus.valid,
            validationStatus: 'normal',
          ),
        ),
      ];

  void resetToDefaults() {
    _transfers.clear();
    for (final trf in defaultDemoTransfers) {
      _transfers[trf.transferId] = trf;
    }
    simulateError = false;
    simulateAcceptanceRace = false;
  }

  Map<String, PatientTransferRequest> get transfers => _transfers;

  void clear() {
    _transfers.clear();
    simulateError = false;
    simulateAcceptanceRace = false;
  }

  @override
  Future<PatientTransferRequest> createTransfer(
      PatientTransferRequest transfer) async {
    if (simulateError) {
      throw const BackendException(
        code: BackendException.persistenceFailed,
        message: 'Simulated transfer persistence failure.',
      );
    }

    if (!transfer.isReasonValid) {
      throw const BackendException(
        code: BackendException.invalidData,
        message: 'Transfer reason must be between 1 and 1000 characters.',
      );
    }

    if (!transfer.isDestinationValid) {
      throw const BackendException(
        code: BackendException.invalidData,
        message: 'Destination department cannot be the same as current department.',
      );
    }

    _transfers[transfer.transferId] = transfer;
    debugPrint('[MockTransferRepository] Created transfer: ${transfer.transferId}');
    return transfer;
  }

  /// Convenience factory helper for creating a transfer with individual parameters.
  Future<PatientTransferRequest> createTransferRequest({
    required String patientId,
    String? patientName,
    int? patientAge,
    String? patientGender,
    required String caseId,
    required String sourceVisitId,
    required String sourceDoctorId,
    String? sourceDoctorName,
    required String sourceDepartment,
    required String destinationDepartment,
    required String transferReason,
    VitalReading? vitals,
  }) async {
    final transferId = 'TRF-${DateTime.now().millisecondsSinceEpoch}';
    final transfer = PatientTransferRequest(
      transferId: transferId,
      patientId: patientId,
      caseId: caseId,
      sourceVisitId: sourceVisitId,
      sourceDoctorId: sourceDoctorId,
      sourceDoctorName: sourceDoctorName,
      sourceDepartment: sourceDepartment,
      destinationDepartment: destinationDepartment,
      reason: transferReason,
      requestedAt: DateTime.now(),
      status: TransferStatus.pending,
      patientAge: patientAge,
      patientGender: patientGender,
      vitals: vitals,
    );
    return createTransfer(transfer);
  }

  @override
  Future<PatientTransferRequest?> getTransferById(String transferId) async {
    if (simulateError) {
      throw const BackendException(
        code: BackendException.persistenceFailed,
        message: 'Simulated transfer fetch failure.',
      );
    }
    return _transfers[transferId];
  }

  @override
  Future<List<PatientTransferRequest>> getPendingTransfersForDepartment(
      String department) async {
    if (simulateError) {
      throw const BackendException(
        code: BackendException.persistenceFailed,
        message: 'Simulated department transfer fetch failure.',
      );
    }

    final list = _transfers.values
        .where((t) =>
            t.status == TransferStatus.pending &&
            t.destinationDepartment.toLowerCase() == department.toLowerCase())
        .toList();

    list.sort((a, b) => a.requestedAt.compareTo(b.requestedAt));
    return list;
  }

  @override
  Future<DoctorAssignmentResult> acceptTransfer({
    required String transferId,
    required String doctorId,
    required String doctorName,
    required String doctorDepartment,
  }) async {
    if (simulateError) {
      return DoctorAssignmentResult.error(
        requestId: transferId,
        message: 'Simulated server error during transfer acceptance.',
      );
    }

    final existing = _transfers[transferId];
    if (existing == null) {
      return DoctorAssignmentResult.invalidRequest(
        requestId: transferId,
        message: 'Transfer request not found.',
      );
    }

    // 1. Department match verification
    if (existing.destinationDepartment.toLowerCase() !=
        doctorDepartment.toLowerCase()) {
      return DoctorAssignmentResult.ineligible(
        requestId: transferId,
        message:
            'Doctor department does not match destination department (${existing.destinationDepartment}).',
      );
    }

    // 2. Atomic race / already assigned check
    if (existing.status != TransferStatus.pending ||
        existing.destinationDoctorId != null ||
        simulateAcceptanceRace) {
      return DoctorAssignmentResult.alreadyAssigned(
        requestId: transferId,
        queueNumber: existing.queueNumber,
        message: 'Patient transfer has already been claimed by another doctor.',
      );
    }

    // 3. Accept and claim transfer
    final accepted = existing.copyWith(
      status: TransferStatus.accepted,
      destinationDoctorId: doctorId,
      destinationDoctorName: doctorName,
      acceptedAt: DateTime.now(),
    );

    _transfers[transferId] = accepted;
    debugPrint(
        '[MockTransferRepository] Transfer $transferId accepted by $doctorId ($doctorName)');

    return DoctorAssignmentResult.success(
      requestId: transferId,
      appointmentId: transferId,
      queueNumber: existing.queueNumber ?? 'TRF',
      assignedDoctorId: doctorId,
    );
  }

  @override
  Future<bool> cancelTransfer({
    required String transferId,
    required String doctorId,
  }) async {
    if (simulateError) return false;

    final existing = _transfers[transferId];
    if (existing == null) return false;

    if (!existing.canCancelBy(doctorId)) {
      return false;
    }

    _transfers[transferId] = existing.copyWith(
      status: TransferStatus.cancelled,
      cancelledAt: DateTime.now(),
    );
    debugPrint(
        '[MockTransferRepository] Transfer $transferId cancelled by $doctorId');
    return true;
  }

  @override
  Future<List<PatientTransferRequest>> getTransfersForPatient(
      String patientId) async {
    if (simulateError) {
      throw const BackendException(
        code: BackendException.persistenceFailed,
        message: 'Simulated transfer fetch failure.',
      );
    }

    final list = _transfers.values
        .where((t) => t.patientId == patientId)
        .toList();
    list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return list;
  }

  @override
  Future<List<PatientTransferRequest>> getTransfersForCase({
    required String patientId,
    required String caseId,
  }) async {
    if (simulateError) {
      throw const BackendException(
        code: BackendException.persistenceFailed,
        message: 'Simulated case transfer fetch failure.',
      );
    }

    final list = _transfers.values
        .where((t) => t.patientId == patientId && t.caseId == caseId)
        .toList();
    list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return list;
  }

  @override
  Future<List<PatientTransferRequest>> getTransfersForVisit({
    required String patientId,
    required String caseId,
    required String visitId,
  }) async {
    if (simulateError) {
      throw const BackendException(
        code: BackendException.persistenceFailed,
        message: 'Simulated visit transfer fetch failure.',
      );
    }

    final list = _transfers.values
        .where((t) =>
            t.patientId == patientId &&
            t.caseId == caseId &&
            t.sourceVisitId == visitId)
        .toList();
    return list;
  }
}

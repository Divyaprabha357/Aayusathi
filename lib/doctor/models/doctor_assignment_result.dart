/// Structured status outcomes for doctor patient request acceptance operations.
enum DoctorAssignmentStatus {
  /// Request was successfully assigned exclusively to the requesting doctor.
  success,

  /// Request has already been claimed/assigned to another doctor (First-Doctor-Wins).
  alreadyAssigned,

  /// Doctor is unavailable (offline or in consultation) and cannot accept requests.
  unavailable,

  /// Request is invalid or not found in the system.
  invalidRequest,

  /// Doctor is unauthorized to claim this request (e.g. unauthenticated).
  unauthorized,

  /// Doctor is ineligible (e.g. domain mismatch, inactive account, or previous-doctor restriction).
  ineligible,

  /// Concurrent modification or transaction conflict occurred during assignment.
  conflict,

  /// Internal server or network communication error during assignment.
  error,
}

/// Immutable structured result representing the outcome of an atomic doctor patient request acceptance.
class DoctorAssignmentResult {
  final DoctorAssignmentStatus status;
  final String requestId;
  final String? appointmentId;
  final String? queueNumber;
  final String? assignedDoctorId;
  final DateTime? assignedAt;
  final String? message;

  const DoctorAssignmentResult({
    required this.status,
    required this.requestId,
    this.appointmentId,
    this.queueNumber,
    this.assignedDoctorId,
    this.assignedAt,
    this.message,
  });

  /// Factory constructor for successful exclusive assignment.
  factory DoctorAssignmentResult.success({
    required String requestId,
    required String appointmentId,
    required String queueNumber,
    required String assignedDoctorId,
    DateTime? assignedAt,
    String? message,
  }) {
    return DoctorAssignmentResult(
      status: DoctorAssignmentStatus.success,
      requestId: requestId,
      appointmentId: appointmentId,
      queueNumber: queueNumber,
      assignedDoctorId: assignedDoctorId,
      assignedAt: assignedAt ?? DateTime.now(),
      message: message ?? 'Patient request assigned successfully.',
    );
  }

  /// Factory constructor when another doctor has already claimed the request.
  factory DoctorAssignmentResult.alreadyAssigned({
    required String requestId,
    String? queueNumber,
    String? message,
  }) {
    return DoctorAssignmentResult(
      status: DoctorAssignmentStatus.alreadyAssigned,
      requestId: requestId,
      queueNumber: queueNumber,
      message: message ??
          'Patient request has already been assigned to another doctor.',
    );
  }

  /// Factory constructor when doctor presence is not available.
  factory DoctorAssignmentResult.unavailable({
    required String requestId,
    String? message,
  }) {
    return DoctorAssignmentResult(
      status: DoctorAssignmentStatus.unavailable,
      requestId: requestId,
      message: message ??
          'Doctor is currently unavailable or in another consultation.',
    );
  }

  /// Factory constructor when doctor is ineligible (domain or previous doctor mismatch).
  factory DoctorAssignmentResult.ineligible({
    required String requestId,
    String? message,
  }) {
    return DoctorAssignmentResult(
      status: DoctorAssignmentStatus.ineligible,
      requestId: requestId,
      message: message ?? 'Doctor is not eligible to accept this request.',
    );
  }

  /// Factory constructor for invalid request identifiers.
  factory DoctorAssignmentResult.invalidRequest({
    required String requestId,
    String? message,
  }) {
    return DoctorAssignmentResult(
      status: DoctorAssignmentStatus.invalidRequest,
      requestId: requestId,
      message: message ?? 'Patient request was not found or is no longer valid.',
    );
  }

  /// Factory constructor for unauthorized requests.
  factory DoctorAssignmentResult.unauthorized({
    required String requestId,
    String? message,
  }) {
    return DoctorAssignmentResult(
      status: DoctorAssignmentStatus.unauthorized,
      requestId: requestId,
      message: message ?? 'Doctor authentication or active role required.',
    );
  }

  /// Factory constructor for concurrent conflicts.
  factory DoctorAssignmentResult.conflict({
    required String requestId,
    String? message,
  }) {
    return DoctorAssignmentResult(
      status: DoctorAssignmentStatus.conflict,
      requestId: requestId,
      message: message ?? 'Transaction conflict occurred. Please retry.',
    );
  }

  /// Factory constructor for unexpected errors.
  factory DoctorAssignmentResult.error({
    required String requestId,
    required String message,
  }) {
    return DoctorAssignmentResult(
      status: DoctorAssignmentStatus.error,
      requestId: requestId,
      message: message,
    );
  }

  bool get isSuccess => status == DoctorAssignmentStatus.success;
  bool get isAlreadyAssigned => status == DoctorAssignmentStatus.alreadyAssigned;
  bool get isUnavailable => status == DoctorAssignmentStatus.unavailable;
  bool get isIneligible => status == DoctorAssignmentStatus.ineligible;
  bool get isInvalidRequest => status == DoctorAssignmentStatus.invalidRequest;
  bool get isUnauthorized => status == DoctorAssignmentStatus.unauthorized;
  bool get isConflict => status == DoctorAssignmentStatus.conflict;
  bool get isError => status == DoctorAssignmentStatus.error;

  @override
  String toString() =>
      'DoctorAssignmentResult(status: $status, requestId: $requestId, queue: $queueNumber, doctor: $assignedDoctorId)';
}

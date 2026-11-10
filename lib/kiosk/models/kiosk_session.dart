/// User registration classification at the Kiosk.
enum UserType {
  newUser,
  existingPatient,
}

/// Lifecycle state of an active Kiosk check-in session.
enum KioskSessionStatus {
  idle,
  patientIdentified,
  vitalsMeasuring,
  consultationPending,
  completed,
}

/// Represents an ongoing session at the AAYUSATHI physical Kiosk.
class KioskSession {
  final String sessionId;
  final UserType? userType;
  final String? patientId;
  final String? domainId;
  final String? queueNumber;
  final KioskSessionStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;

  const KioskSession({
    required this.sessionId,
    this.userType,
    this.patientId,
    this.domainId,
    this.queueNumber,
    required this.status,
    required this.startedAt,
    this.completedAt,
  });

  KioskSession copyWith({
    String? sessionId,
    UserType? userType,
    String? patientId,
    String? domainId,
    String? queueNumber,
    KioskSessionStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return KioskSession(
      sessionId: sessionId ?? this.sessionId,
      userType: userType ?? this.userType,
      patientId: patientId ?? this.patientId,
      domainId: domainId ?? this.domainId,
      queueNumber: queueNumber ?? this.queueNumber,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

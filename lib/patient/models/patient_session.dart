/// State representation of the patient authentication lifecycle.
enum PatientSessionState {
  loggedOut,
  patientIdEntered,
  otpPending,
  authenticated,
}

/// Lightweight, privacy-safe patient session model.
/// 
/// Privacy & Security Guardrails:
/// - Only contains minimal authenticated identity ([patientId], optional [authUid]).
/// - Strictly NEVER holds Aadhaar, plaintext passwords, or OTP secrets.
class PatientSession {
  final String? patientId;
  final String? authUid;
  final PatientSessionState state;
  final DateTime? authenticatedAt;

  const PatientSession({
    this.patientId,
    this.authUid,
    this.state = PatientSessionState.loggedOut,
    this.authenticatedAt,
  });

  bool get isAuthenticated => state == PatientSessionState.authenticated && patientId != null;

  factory PatientSession.loggedOut() {
    return const PatientSession(state: PatientSessionState.loggedOut);
  }

  factory PatientSession.patientIdEntered(String patientId) {
    return PatientSession(
      patientId: patientId,
      state: PatientSessionState.patientIdEntered,
    );
  }

  factory PatientSession.otpPending(String patientId) {
    return PatientSession(
      patientId: patientId,
      state: PatientSessionState.otpPending,
    );
  }

  factory PatientSession.authenticated({
    required String patientId,
    String? authUid,
    DateTime? authenticatedAt,
  }) {
    return PatientSession(
      patientId: patientId,
      authUid: authUid,
      state: PatientSessionState.authenticated,
      authenticatedAt: authenticatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() => 'PatientSession(patientId: $patientId, state: $state, authenticated: $isAuthenticated)';
}

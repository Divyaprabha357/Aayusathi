/// Conceptual authentication states for the Doctor Clinical Workstation.
enum DoctorAuthState {
  /// No doctor authenticated; workstation is in standby or logged-out state.
  loggedOut,

  /// Credentials have been entered into the form.
  credentialsEntered,

  /// Valid credentials accepted; awaiting 6-digit OTP verification.
  otpPending,

  /// OTP verified; full clinical workstation session is active.
  authenticated,
}

/// Result of an authentication or verification attempt in the Doctor module.
class DoctorAuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final DoctorAuthState state;

  const DoctorAuthResult.success({
    this.state = DoctorAuthState.otpPending,
  })  : isSuccess = true,
        errorMessage = null;

  const DoctorAuthResult.failure(
    this.errorMessage, {
    this.state = DoctorAuthState.loggedOut,
  }) : isSuccess = false;
}

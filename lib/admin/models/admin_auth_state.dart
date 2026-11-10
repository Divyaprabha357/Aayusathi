/// Administrative Authentication State Enumeration.
enum AdminAuthState {
  /// No active administrative session.
  loggedOut,

  /// Authentication request is actively in progress.
  authenticating,

  /// Valid administrative credentials verified; active session in progress.
  authenticated,

  /// Credential verification failed.
  authenticationFailed,
}

/// Administrative Authority Role.
enum AdminRole {
  /// Level-1 Super Administrator with full governance privileges.
  admin('ADMIN', 'Level 1 Authority');

  final String code;
  final String label;

  const AdminRole(this.code, this.label);
}

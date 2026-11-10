import 'admin_auth_state.dart';

/// Lightweight, safe representation of an active administrative session.
///
/// Contains strictly non-sensitive metadata required by UI shells.
/// NEVER stores passwords, hashes, tokens, or secret keys.
class AdminSession {
  final bool isAuthenticated;
  final String username;
  final String displayName;
  final AdminRole role;
  final DateTime loginTimestamp;

  const AdminSession({
    required this.isAuthenticated,
    required this.username,
    required this.displayName,
    this.role = AdminRole.admin,
    required this.loginTimestamp,
  });

  /// Factory for an empty / logged-out session.
  factory AdminSession.empty() {
    return AdminSession(
      isAuthenticated: false,
      username: '',
      displayName: '',
      loginTimestamp: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /// Factory for creating an authenticated session for prototype administrator.
  factory AdminSession.createAuthenticated({
    required String username,
    String? displayName,
    AdminRole role = AdminRole.admin,
  }) {
    return AdminSession(
      isAuthenticated: true,
      username: username,
      displayName: displayName ?? 'System Administrator ($username)',
      role: role,
      loginTimestamp: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'AdminSession(username: $username, role: ${role.code}, authenticated: $isAuthenticated, loginAt: $loginTimestamp)';
  }
}

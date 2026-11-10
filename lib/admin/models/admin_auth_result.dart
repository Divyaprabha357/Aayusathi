import 'admin_session.dart';

/// Result envelope for administrative authentication attempts.
class AdminAuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final AdminSession? session;

  const AdminAuthResult({
    required this.isSuccess,
    this.errorMessage,
    this.session,
  });

  factory AdminAuthResult.success(AdminSession session) {
    return AdminAuthResult(
      isSuccess: true,
      session: session,
    );
  }

  factory AdminAuthResult.failure(String errorMessage) {
    return AdminAuthResult(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}

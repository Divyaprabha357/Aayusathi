import 'auth_user.dart';

/// Abstract contract for authentication services across AAYUSATHI.
abstract class AuthService {
  /// Current authenticated user identity, or `null` if unauthenticated.
  AuthUser? get currentUser;

  /// Whether there is an active authenticated user.
  bool get isAuthenticated => currentUser != null;

  /// Stream emitting user state changes (sign-in, sign-out, token refresh).
  Stream<AuthUser?> get authStateChanges;

  /// Authenticates the client anonymously (primary mechanism for Kiosk devices).
  Future<AuthUser?> signInAnonymously({UserRole role = UserRole.kiosk});

  /// Authenticates using email and password (for future Doctor and Admin access).
  Future<AuthUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
    UserRole role = UserRole.doctor,
  });

  /// Signs out the current authenticated user session.
  Future<void> signOut();
}

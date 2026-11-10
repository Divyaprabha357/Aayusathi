import 'dart:async';
import 'auth_service.dart';
import 'auth_user.dart';

/// In-memory mock implementation of [AuthService] for unit testing and offline development.
class MockAuthService implements AuthService {
  static final MockAuthService instance = MockAuthService._();
  MockAuthService._();
  factory MockAuthService() => instance;

  AuthUser? _currentUser;
  final StreamController<AuthUser?> _authController =
      StreamController<AuthUser?>.broadcast();

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  bool get isAuthenticated => _currentUser != null;

  @override
  Stream<AuthUser?> get authStateChanges => _authController.stream;

  @override
  Future<AuthUser?> signInAnonymously({UserRole role = UserRole.kiosk}) async {
    final user = AuthUser(
      uid: 'mock-kiosk-${DateTime.now().millisecondsSinceEpoch}',
      displayName: 'AAYUSATHI Kiosk Terminal',
      role: role,
      isAnonymous: true,
      createdAt: DateTime.now(),
      lastSignInAt: DateTime.now(),
    );
    _currentUser = user;
    _authController.add(user);
    return user;
  }

  @override
  Future<AuthUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
    UserRole role = UserRole.doctor,
  }) async {
    final user = AuthUser(
      uid: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: email.split('@').first,
      role: role,
      isAnonymous: false,
      createdAt: DateTime.now(),
      lastSignInAt: DateTime.now(),
    );
    _currentUser = user;
    _authController.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authController.add(null);
  }

  /// Injects custom auth state for test scenarios.
  void setMockUser(AuthUser? user) {
    _currentUser = user;
    _authController.add(user);
  }

  /// Resets mock auth state back to unauthenticated.
  void reset() {
    _currentUser = null;
    _authController.add(null);
  }
}

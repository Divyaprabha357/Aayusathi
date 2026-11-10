import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/auth/auth_user.dart';
import 'package:aayusathi/core/auth/mock_auth_service.dart';

void main() {
  group('Phase 10: MockAuthService Unit Tests', () {
    late MockAuthService authService;

    setUp(() {
      authService = MockAuthService();
      authService.reset();
    });

    tearDown(() {
      authService.reset();
    });

    test('Initial state is unauthenticated', () {
      expect(authService.currentUser, isNull);
      expect(authService.isAuthenticated, isFalse);
    });

    test('signInAnonymously creates a kiosk session and updates stream', () async {
      final emittedUsers = <AuthUser?>[];
      final subscription = authService.authStateChanges.listen(emittedUsers.add);

      final user = await authService.signInAnonymously();

      expect(user, isNotNull);
      expect(user!.isAnonymous, isTrue);
      expect(user.role, UserRole.kiosk);
      expect(user.displayName, contains('Kiosk Terminal'));
      expect(authService.isAuthenticated, isTrue);
      expect(authService.currentUser?.uid, user.uid);

      await Future.delayed(const Duration(milliseconds: 10));
      expect(emittedUsers.length, 1);
      expect(emittedUsers.first?.uid, user.uid);

      await subscription.cancel();
    });

    test('signInWithEmailAndPassword creates authenticated doctor session', () async {
      final user = await authService.signInWithEmailAndPassword(
        email: 'dr.sharma@aayusathi.org',
        password: 'securePassword123',
        role: UserRole.doctor,
      );

      expect(user, isNotNull);
      expect(user!.isAnonymous, isFalse);
      expect(user.role, UserRole.doctor);
      expect(user.email, 'dr.sharma@aayusathi.org');
      expect(user.displayName, 'dr.sharma');
      expect(authService.isAuthenticated, isTrue);
    });

    test('signOut clears authenticated user and emits null', () async {
      await authService.signInAnonymously();
      expect(authService.isAuthenticated, isTrue);

      final emitted = <AuthUser?>[];
      final subscription = authService.authStateChanges.listen(emitted.add);

      await authService.signOut();

      expect(authService.currentUser, isNull);
      expect(authService.isAuthenticated, isFalse);

      await Future.delayed(const Duration(milliseconds: 10));
      expect(emitted.length, 1);
      expect(emitted.first, isNull);

      await subscription.cancel();
    });

    test('setMockUser injects test identity and reset restores clean state', () {
      final customUser = AuthUser(
        uid: 'admin-001',
        email: 'admin@aayusathi.org',
        role: UserRole.admin,
      );

      authService.setMockUser(customUser);
      expect(authService.currentUser?.uid, 'admin-001');
      expect(authService.currentUser?.isAdmin, isTrue);

      authService.reset();
      expect(authService.currentUser, isNull);
      expect(authService.isAuthenticated, isFalse);
    });
  });
}

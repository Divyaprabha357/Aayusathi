import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'auth_exception.dart';
import 'auth_service.dart';
import 'auth_user.dart';

/// Firebase Authentication implementation of [AuthService].
///
/// Features:
/// - Lazy access to [fb.FirebaseAuth.instance] to support offline and headless testing.
/// - Anonymous authentication for the physical Kiosk device.
/// - Controlled error mapping to [AuthException].
class FirebaseAuthService implements AuthService {
  final fb.FirebaseAuth? _customAuth;

  FirebaseAuthService({fb.FirebaseAuth? auth}) : _customAuth = auth;

  fb.FirebaseAuth get _auth => _customAuth ?? fb.FirebaseAuth.instance;

  @override
  AuthUser? get currentUser {
    try {
      final fbUser = _auth.currentUser;
      if (fbUser == null) return null;
      return AuthUser.fromFirebaseUser(fbUser);
    } catch (_) {
      return null;
    }
  }

  @override
  bool get isAuthenticated => currentUser != null;

  @override
  Stream<AuthUser?> get authStateChanges {
    try {
      return _auth.authStateChanges().map((fbUser) {
        if (fbUser == null) return null;
        return AuthUser.fromFirebaseUser(fbUser);
      });
    } catch (_) {
      return const Stream.empty();
    }
  }

  @override
  Future<AuthUser?> signInAnonymously({UserRole role = UserRole.kiosk}) async {
    try {
      debugPrint('[AAYUSATHI] Attempting Firebase Anonymous Authentication for Kiosk...');
      final userCredential = await _auth.signInAnonymously();
      final fbUser = userCredential.user;
      if (fbUser == null) {
        throw const AuthException(
          code: AuthException.authFailed,
          message: 'Failed to obtain user identity from Firebase Auth.',
        );
      }

      final authUser = AuthUser.fromFirebaseUser(fbUser, role: role);
      debugPrint('[AAYUSATHI] Kiosk authenticated successfully: uid=${authUser.uid} (role: ${role.name}, anonymous: true)');
      return authUser;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('[AAYUSATHI] Firebase Authentication failed: ${e.code} - ${e.message}');
      throw AuthException(
        code: _mapFirebaseErrorCode(e.code),
        message: e.message ?? 'Authentication error occurred.',
        originalError: e,
      );
    } catch (e) {
      debugPrint('[AAYUSATHI] Unexpected error during authentication: $e');
      throw AuthException(
        code: AuthException.authFailed,
        message: e.toString(),
        originalError: e,
      );
    }
  }

  @override
  Future<AuthUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
    UserRole role = UserRole.doctor,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final fbUser = userCredential.user;
      if (fbUser == null) return null;
      return AuthUser.fromFirebaseUser(fbUser, role: role);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(
        code: _mapFirebaseErrorCode(e.code),
        message: e.message ?? 'Sign-in failed.',
        originalError: e,
      );
    } catch (e) {
      throw AuthException(
        code: AuthException.authFailed,
        message: e.toString(),
        originalError: e,
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('[AAYUSATHI] Signed out from Firebase Authentication.');
    } catch (e) {
      debugPrint('[AAYUSATHI] Error during sign-out: $e');
    }
  }

  String _mapFirebaseErrorCode(String code) {
    switch (code) {
      case 'user-disabled':
        return AuthException.accountDisabled;
      case 'network-request-failed':
        return AuthException.networkError;
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return AuthException.invalidCredentials;
      case 'operation-not-allowed':
        return AuthException.unauthorized;
      default:
        return AuthException.authFailed;
    }
  }
}

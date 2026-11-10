import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/auth/auth_user.dart';

void main() {
  group('Phase 10: AuthUser & UserRole Model Tests', () {
    test('UserRole enum parses strings and defaults correctly', () {
      expect(UserRole.fromString('kiosk'), UserRole.kiosk);
      expect(UserRole.fromString('KIOSK'), UserRole.kiosk);
      expect(UserRole.fromString('patient'), UserRole.patient);
      expect(UserRole.fromString('doctor'), UserRole.doctor);
      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('unknown'), UserRole.patient);
      expect(UserRole.fromString(null), UserRole.patient);
    });

    test('AuthUser model serializes and deserializes correctly', () {
      final now = DateTime(2026, 9, 5, 12, 0, 0);
      final user = AuthUser(
        uid: 'user-12345',
        email: 'doctor@aayusathi.com',
        displayName: 'Dr. Ramesh Gupta',
        role: UserRole.doctor,
        isAnonymous: false,
        createdAt: now,
        lastSignInAt: now,
      );

      expect(user.isDoctor, isTrue);
      expect(user.isKiosk, isFalse);
      expect(user.isAdmin, isFalse);
      expect(user.isPatient, isFalse);

      final map = user.toMap();
      expect(map['uid'], 'user-12345');
      expect(map['role'], 'doctor');
      expect(map['isAnonymous'], isFalse);

      final reconstructed = AuthUser.fromMap(map);
      expect(reconstructed.uid, 'user-12345');
      expect(reconstructed.email, 'doctor@aayusathi.com');
      expect(reconstructed.role, UserRole.doctor);
      expect(reconstructed.isAnonymous, isFalse);
    });

    test('AuthUser anonymous kiosk terminal representation', () {
      final kiosk = AuthUser(
        uid: 'anon-kiosk-999',
        displayName: 'Kiosk Terminal Pune-01',
        role: UserRole.kiosk,
        isAnonymous: true,
      );

      expect(kiosk.isKiosk, isTrue);
      expect(kiosk.isAnonymous, isTrue);
      expect(kiosk.email, isNull);

      final copied = kiosk.copyWith(displayName: 'Updated Terminal');
      expect(copied.displayName, 'Updated Terminal');
      expect(copied.uid, 'anon-kiosk-999');
      expect(copied.isAnonymous, isTrue);
    });
  });
}

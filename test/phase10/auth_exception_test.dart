import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/auth/auth_exception.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';

void main() {
  group('Phase 10: AuthException Unit Tests', () {
    test('Constructs AuthException correctly', () {
      final ex = AuthException(
        code: AuthException.networkError,
        message: 'Underlying socket timed out',
        originalError: 'SocketException',
      );

      expect(ex.code, AuthException.networkError);
      expect(ex.message, 'Underlying socket timed out');
      expect(ex.originalError, 'SocketException');
      expect(ex.toString(), contains('NETWORK_ERROR'));
    });

    test('Localizes networkError across EN, HI, MR', () {
      final ex = AuthException(
        code: AuthException.networkError,
        message: 'Network failure',
      );

      expect(
        ex.getLocalizedMessage(KioskLocale.english),
        'Network unavailable. Please check your connectivity.',
      );
      expect(
        ex.getLocalizedMessage(KioskLocale.hindi),
        contains('नेटवर्क अनुपलब्ध है'),
      );
      expect(
        ex.getLocalizedMessage(KioskLocale.marathi),
        contains('नेटवर्क अनुपलब्ध आहे'),
      );
    });

    test('Localizes accountDisabled across EN, HI, MR', () {
      final ex = AuthException(
        code: AuthException.accountDisabled,
        message: 'User is disabled',
      );

      expect(
        ex.getLocalizedMessage(KioskLocale.english),
        contains('disabled'),
      );
      expect(
        ex.getLocalizedMessage(KioskLocale.hindi),
        contains('खाता अक्षम'),
      );
      expect(
        ex.getLocalizedMessage(KioskLocale.marathi),
        contains('खाते अक्षम'),
      );
    });

    test('Localizes permissionDenied and unauthorized across EN, HI, MR', () {
      final ex = AuthException(
        code: AuthException.permissionDenied,
        message: 'Denied',
      );

      expect(
        ex.getLocalizedMessage(KioskLocale.english),
        'Unauthorized access. You do not have permission.',
      );
      expect(
        ex.getLocalizedMessage(KioskLocale.hindi),
        contains('अनधिकृत पहुंच'),
      );
      expect(
        ex.getLocalizedMessage(KioskLocale.marathi),
        contains('अनधिकृत प्रवेश'),
      );
    });

    test('Localizes sessionExpired across EN, HI, MR', () {
      final ex = AuthException(
        code: AuthException.sessionExpired,
        message: 'Expired',
      );

      expect(
        ex.getLocalizedMessage(KioskLocale.english),
        'Session expired. Please try again.',
      );
      expect(
        ex.getLocalizedMessage(KioskLocale.hindi),
        contains('सत्र समाप्त'),
      );
      expect(
        ex.getLocalizedMessage(KioskLocale.marathi),
        contains('सत्र समाप्त'),
      );
    });

    test('Defaults to generic auth failure for unknown codes', () {
      final ex = AuthException(
        code: 'SOME_UNKNOWN_CODE',
        message: 'Unknown',
      );

      expect(
        ex.getLocalizedMessage(KioskLocale.english),
        'Authentication failed. Please try again.',
      );
      expect(
        ex.getLocalizedMessage(KioskLocale.hindi),
        contains('प्रमाणीकरण विफल रहा'),
      );
      expect(
        ex.getLocalizedMessage(KioskLocale.marathi),
        contains('प्रमाणीकरण अयशस्वी झाले'),
      );
    });
  });
}

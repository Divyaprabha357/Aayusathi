import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_exception.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';

void main() {
  group('Phase 11: BackendException Localization & Error Codes', () {
    test('duplicatePatient localized in EN, HI, MR', () {
      const ex = BackendException(
        code: BackendException.duplicatePatient,
        message: 'Patient already exists',
      );

      expect(
        ex.getLocalizedMessage(KioskLocale.english),
        contains('already registered'),
      );
      expect(
        ex.getLocalizedMessage(KioskLocale.hindi),
        contains('पहले से पंजीकृत'),
      );
      expect(
        ex.getLocalizedMessage(KioskLocale.marathi),
        contains('आधीच नोंदणीकृत'),
      );
    });

    test('queueCapacityReached localized in EN, HI, MR', () {
      const ex = BackendException(
        code: BackendException.queueCapacityReached,
        message: 'Queue limit 99,999 reached',
      );

      expect(
        ex.getLocalizedMessage(KioskLocale.english),
        contains('capacity limit reached'),
      );
      expect(
        ex.getLocalizedMessage(KioskLocale.hindi),
        contains('क्षमता समाप्त हो गई है'),
      );
      expect(
        ex.getLocalizedMessage(KioskLocale.marathi),
        contains('क्षमता समाप्त झाली आहे'),
      );
    });

    test('queueAllocationFailed and persistenceFailed localized in EN, HI, MR', () {
      const ex1 = BackendException(
        code: BackendException.queueAllocationFailed,
        message: 'Transaction aborted',
      );
      const ex2 = BackendException(
        code: BackendException.persistenceFailed,
        message: 'Save failed',
      );

      expect(
        ex1.getLocalizedMessage(KioskLocale.english),
        'Failed to save appointment. Please try again.',
      );
      expect(
        ex2.getLocalizedMessage(KioskLocale.hindi),
        contains('सहेजने में विफल'),
      );
      expect(
        ex2.getLocalizedMessage(KioskLocale.marathi),
        contains('सेव्ह करण्यात अयशस्वी'),
      );
    });
  });
}

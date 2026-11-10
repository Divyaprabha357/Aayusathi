import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/localization/kiosk_locale.dart';
import 'package:aayusathi/doctor/services/windows_speech_to_text_service.dart';

void main() {
  test('Live Windows Speech diagnostics verification', () async {
    final service = WindowsSpeechToTextService.instance;
    debugPrint('--- Testing English (en-IN requested) ---');
    final diagEn = await service.checkConfiguration(locale: KioskLocale.english);
    debugPrint(diagEn.toString());
    expect(diagEn.isSupported, isTrue);
    expect(diagEn.selectedLocale, isNotNull);

    debugPrint('--- Testing Hindi (hi-IN requested) ---');
    final diagHi = await service.checkConfiguration(locale: KioskLocale.hindi);
    debugPrint(diagHi.toString());
    expect(diagHi.isSupported, isFalse);
    expect(diagHi.statusMessage, contains('is not available on this Windows installation'));

    debugPrint('--- Testing Marathi (mr-IN requested) ---');
    final diagMr = await service.checkConfiguration(locale: KioskLocale.marathi);
    debugPrint(diagMr.toString());
    expect(diagMr.isSupported, isFalse);
    expect(diagMr.statusMessage, contains('is not available on this Windows installation'));
  });
}

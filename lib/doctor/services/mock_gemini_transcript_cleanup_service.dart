import 'dart:async';
import '../../core/localization/kiosk_locale.dart';
import '../models/transcript_cleanup_input.dart';
import '../models/transcript_cleanup_result.dart';
import 'gemini_transcript_cleanup_service.dart';

/// In-memory mock implementation of [GeminiTranscriptCleanupService] for development and testing.
///
/// Safety & Behavioral Rules:
/// - Provides deterministic transcript cleanup without contacting external Gemini APIs.
/// - Never diagnoses, never infers disease, never adds unmentioned symptoms or medications.
/// - Strictly preserves clinical negations, measurements, durations, and medical terminology.
/// - Flags ambiguous/unclear fragments into [TranscriptCleanupResult.uncertainSegments].
/// - Supports multilingual cleanup across English, Hindi, and Marathi without cross-translation.
class MockGeminiTranscriptCleanupService implements GeminiTranscriptCleanupService {
  static final MockGeminiTranscriptCleanupService instance =
      MockGeminiTranscriptCleanupService._();
  MockGeminiTranscriptCleanupService._();
  factory MockGeminiTranscriptCleanupService() => instance;

  // Error & Scenario Simulation Flags
  bool simulateNetworkError = false;
  bool simulateTimeout = false;
  bool simulateRateLimit = false;
  bool simulateMalformedResponse = false;
  bool simulateEmptyResponse = false;
  bool simulateSafetyRefusal = false;
  bool simulateServiceUnavailable = false;
  bool simulateUncertainty = false;

  // Custom override for unit testing
  String? customCleanedOverride;
  List<String>? customUncertainSegments;

  void resetToDefaults() {
    simulateNetworkError = false;
    simulateTimeout = false;
    simulateRateLimit = false;
    simulateMalformedResponse = false;
    simulateEmptyResponse = false;
    simulateSafetyRefusal = false;
    simulateServiceUnavailable = false;
    simulateUncertainty = false;
    customCleanedOverride = null;
    customUncertainSegments = null;
  }

  @override
  Future<TranscriptCleanupResult> cleanupTranscript(
    TranscriptCleanupInput input,
  ) async {
    // Simulate brief realistic async processing
    await Future.delayed(const Duration(milliseconds: 100));

    final raw = input.transcript;

    // 1. Check Error Simulations
    if (simulateNetworkError) {
      return TranscriptCleanupResult.failure(
        rawTranscript: raw,
        errorMessage: 'Network connection failed.',
        errorCode: 'NETWORK_ERROR',
        isDevelopmentMock: true,
      );
    }

    if (simulateTimeout) {
      return TranscriptCleanupResult.failure(
        rawTranscript: raw,
        errorMessage: 'AI cleanup request timed out.',
        errorCode: 'TIMEOUT',
        isDevelopmentMock: true,
      );
    }

    if (simulateRateLimit) {
      return TranscriptCleanupResult.failure(
        rawTranscript: raw,
        errorMessage: 'AI cleanup rate limit exceeded. Please try again shortly.',
        errorCode: 'RATE_LIMITED',
        isDevelopmentMock: true,
      );
    }

    if (simulateServiceUnavailable) {
      return TranscriptCleanupResult.failure(
        rawTranscript: raw,
        errorMessage:
            'AI cleanup is unavailable. You can use the original transcript or edit it manually.',
        errorCode: 'SERVICE_UNAVAILABLE',
        isDevelopmentMock: true,
      );
    }

    if (simulateSafetyRefusal) {
      return TranscriptCleanupResult.failure(
        rawTranscript: raw,
        errorMessage: 'Transcript cleanup declined by safety filter.',
        errorCode: 'SAFETY_REFUSAL',
        isDevelopmentMock: true,
      );
    }

    if (simulateMalformedResponse) {
      return TranscriptCleanupResult.failure(
        rawTranscript: raw,
        errorMessage: 'Unable to parse AI cleanup response.',
        errorCode: 'MALFORMED_RESPONSE',
        isDevelopmentMock: true,
      );
    }

    if (simulateEmptyResponse) {
      return TranscriptCleanupResult.failure(
        rawTranscript: raw,
        errorMessage: 'AI returned an empty transcript.',
        errorCode: 'EMPTY_RESPONSE',
        isDevelopmentMock: true,
      );
    }

    // 2. Validate input constraints
    if (input.isEmpty) {
      return TranscriptCleanupResult.failure(
        rawTranscript: raw,
        errorMessage: 'Cannot clean an empty speech transcript.',
        errorCode: 'EMPTY_INPUT',
        isDevelopmentMock: true,
      );
    }

    if (input.isTooLong) {
      return TranscriptCleanupResult.failure(
        rawTranscript: raw,
        errorMessage:
            'Transcript is too long for AI cleanup. Please edit or split the dictation.',
        errorCode: 'TRANSCRIPT_TOO_LONG',
        isDevelopmentMock: true,
      );
    }

    // 3. Check custom override
    if (customCleanedOverride != null) {
      return TranscriptCleanupResult.success(
        rawTranscript: raw,
        cleanedTranscript: customCleanedOverride!,
        uncertainSegments: customUncertainSegments ?? (simulateUncertainty ? ['unclear phrase'] : const []),
        isDevelopmentMock: true,
      );
    }

    // 4. Deterministic cleanup engine
    final uncertainSegments = <String>[];

    // Detect uncertain or truncated fragments (e.g. trailing dots, partial tokens)
    if (simulateUncertainty || raw.contains('...') || raw.contains('dizzi...') || raw.contains('unclear')) {
      final match = RegExp(r'(\b\w+\.\.\.|\bunclear\s+\w+\b)').firstMatch(raw);
      if (match != null) {
        uncertainSegments.add(match.group(0)!);
      } else if (simulateUncertainty) {
        uncertainSegments.add('unclear phrase');
      }
    }

    String cleaned = _cleanRawText(raw, input.locale);

    return TranscriptCleanupResult.success(
      rawTranscript: raw,
      cleanedTranscript: cleaned,
      uncertainSegments: uncertainSegments,
      isDevelopmentMock: true,
    );
  }

  /// Internal deterministic text normalizer adhering strictly to clinical safety rules.
  String _cleanRawText(String text, KioskLocale locale) {
    var s = text.trim();

    // 1. Remove speech disfluencies and fillers
    s = s.replaceAll(RegExp(r'\b(uh|um|er|ah)\b', caseSensitive: false), '');

    // 2. Fix specific known speech-to-text acoustic artifacts and repetitions
    // "has had ake headache" -> "has had a headache"
    s = s.replaceAll(RegExp(r'\bhad\s+ake\s+headache\b', caseSensitive: false), 'had a headache');
    s = s.replaceAll(RegExp(r'\bake\s+headache\b', caseSensitive: false), 'a headache');
    s = s.replaceAll(RegExp(r'\bfrom\s+three\s+days\b', caseSensitive: false), 'for three days');

    // "patient taking paracetamol" -> "Patient is taking paracetamol."
    s = s.replaceAll(RegExp(r'\bpatient\s+taking\b', caseSensitive: false), 'patient is taking');
    s = s.replaceAll(RegExp(r'\bpatient\s+has\s+headache\b', caseSensitive: false), 'patient has a headache');

    // Number / Measurement normalization:
    // "one twenty over eighty" -> "120/80 mmHg"
    s = s.replaceAll(
      RegExp(r'\bone\s+twenty\s+over\s+eighty\b', caseSensitive: false),
      '120/80 mmHg',
    );
    s = s.replaceAll(
      RegExp(r'\bone\s+twenty\s+eighty\b', caseSensitive: false),
      '120/80 mmHg',
    );

    // 3. Remove multiple contiguous spaces
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    // 4. Capitalize first letter of sentences and ensure terminating punctuation based on locale
    if (s.isEmpty) return text;

    switch (locale) {
      case KioskLocale.hindi:
        if (!s.endsWith('।') && !s.endsWith('.') && !s.endsWith('?')) {
          s += '।';
        }
        break;

      case KioskLocale.marathi:
        if (!s.endsWith('.') && !s.endsWith('?') && !s.endsWith('।')) {
          s += '.';
        }
        break;

      case KioskLocale.english:
        // Capitalize first character
        s = s[0].toUpperCase() + s.substring(1);
        // Ensure ends with a period if not already punctuated
        if (!s.endsWith('.') && !s.endsWith('?') && !s.endsWith('!') && !s.endsWith('...')) {
          s += '.';
        }
        break;
    }

    return s;
  }
}

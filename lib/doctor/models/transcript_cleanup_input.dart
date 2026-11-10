import '../../core/localization/kiosk_locale.dart';

/// Data Transfer Object representing the input payload sent to the Gemini Speech Transcript Cleanup Assistant.
///
/// Security & Privacy Invariants:
/// - Strictly NEVER includes patient PII (Aadhaar, OTP, phone, passwords, auth tokens, etc.).
/// - Strictly NEVER includes audio recordings or binary audio buffers.
/// - Contains ONLY the sanitized raw speech transcript and the active locale.
/// - Enforces maximum transcript length to prevent excessive payload attacks or timeouts.
class TranscriptCleanupInput {
  /// Maximum permissible character length for AI transcript cleanup requests.
  static const int maxTranscriptLength = 4000;

  /// The raw, unedited speech transcript produced by the speech-to-text engine.
  final String transcript;

  /// The language/locale context for preserving transcription language.
  final KioskLocale locale;

  const TranscriptCleanupInput({
    required this.transcript,
    this.locale = KioskLocale.english,
  });

  /// Whether the raw transcript is blank or whitespace-only.
  bool get isEmpty => transcript.trim().isEmpty;

  /// Whether the raw transcript is non-empty.
  bool get isNotEmpty => !isEmpty;

  /// Whether the transcript exceeds the maximum permitted cleanup length.
  bool get isTooLong => transcript.length > maxTranscriptLength;

  /// Total character count of the transcript.
  int get characterCount => transcript.length;

  /// Validates whether the input payload is eligible for AI cleanup.
  bool get isValid => isNotEmpty && !isTooLong;

  /// Serializes the input payload to a minimal Map for backend transmission.
  Map<String, dynamic> toMap() {
    return {
      'transcript': transcript.trim(),
      'locale': locale.name,
    };
  }

  /// Deserializes a Map into a [TranscriptCleanupInput].
  factory TranscriptCleanupInput.fromMap(Map<String, dynamic> map) {
    return TranscriptCleanupInput(
      transcript: map['transcript'] as String? ?? '',
      locale: KioskLocale.values.firstWhere(
        (l) => l.name == (map['locale'] as String?),
        orElse: () => KioskLocale.english,
      ),
    );
  }

  /// Creates a copy with optional field overrides.
  TranscriptCleanupInput copyWith({
    String? transcript,
    KioskLocale? locale,
  }) {
    return TranscriptCleanupInput(
      transcript: transcript ?? this.transcript,
      locale: locale ?? this.locale,
    );
  }

  @override
  String toString() =>
      'TranscriptCleanupInput(locale: ${locale.name}, length: $characterCount)';
}

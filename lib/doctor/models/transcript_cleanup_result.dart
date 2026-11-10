/// Structured result model produced by the Gemini Speech Transcript Cleanup Assistant.
///
/// Features:
/// - Provides normalized and cleaned transcript draft while preserving original text.
/// - Identifies ambiguous or uncertain speech segments requiring explicit doctor verification.
/// - Captures failure states gracefully without destroying the doctor's raw dictation.
class TranscriptCleanupResult {
  /// The original, unmodified raw transcript from speech-to-text.
  final String rawTranscript;

  /// The Gemini-normalized cleaned transcript draft.
  final String cleanedTranscript;

  /// List of ambiguous or unclear word segments identified during cleanup.
  final List<String> uncertainSegments;

  /// Whether the AI cleanup completed successfully.
  final bool isSuccess;

  /// Human-readable error message if cleanup failed.
  final String? errorMessage;

  /// Machine-readable error code if cleanup failed.
  final String? errorCode;

  /// Whether this result was produced by the in-memory mock development service.
  final bool isDevelopmentMock;

  const TranscriptCleanupResult({
    required this.rawTranscript,
    required this.cleanedTranscript,
    this.uncertainSegments = const [],
    required this.isSuccess,
    this.errorMessage,
    this.errorCode,
    this.isDevelopmentMock = false,
  });

  /// Factory for a successful transcript cleanup.
  factory TranscriptCleanupResult.success({
    required String rawTranscript,
    required String cleanedTranscript,
    List<String> uncertainSegments = const [],
    bool isDevelopmentMock = false,
  }) {
    return TranscriptCleanupResult(
      rawTranscript: rawTranscript,
      cleanedTranscript: cleanedTranscript,
      uncertainSegments: List.unmodifiable(uncertainSegments),
      isSuccess: true,
      isDevelopmentMock: isDevelopmentMock,
    );
  }

  /// Factory for a failed transcript cleanup.
  /// Preserves the [rawTranscript] so the doctor can proceed without AI.
  factory TranscriptCleanupResult.failure({
    required String rawTranscript,
    required String errorMessage,
    String errorCode = 'CLEANUP_FAILED',
    List<String> uncertainSegments = const [],
    bool isDevelopmentMock = false,
  }) {
    return TranscriptCleanupResult(
      rawTranscript: rawTranscript,
      cleanedTranscript: rawTranscript,
      uncertainSegments: List.unmodifiable(uncertainSegments),
      isSuccess: false,
      errorMessage: errorMessage,
      errorCode: errorCode,
      isDevelopmentMock: isDevelopmentMock,
    );
  }

  /// Whether any unclear phrases were detected that warrant doctor verification.
  bool get hasUncertainties => uncertainSegments.isNotEmpty;

  /// Serializes result to a map.
  Map<String, dynamic> toMap() {
    return {
      'rawTranscript': rawTranscript,
      'cleanedTranscript': cleanedTranscript,
      'uncertainSegments': uncertainSegments,
      'isSuccess': isSuccess,
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (errorCode != null) 'errorCode': errorCode,
      'isDevelopmentMock': isDevelopmentMock,
    };
  }

  /// Deserializes a map into a [TranscriptCleanupResult].
  factory TranscriptCleanupResult.fromMap(
    Map<String, dynamic> map, {
    String? fallbackRawTranscript,
  }) {
    final raw = map['rawTranscript'] as String? ?? fallbackRawTranscript ?? '';
    final cleaned = map['cleanedTranscript'] as String? ?? raw;
    final uncertainRaw = map['uncertainSegments'] as List<dynamic>?;
    final uncertain = uncertainRaw != null
        ? uncertainRaw.map((e) => e.toString()).toList()
        : <String>[];
    final isSuccess = map['isSuccess'] as bool? ?? true;

    return TranscriptCleanupResult(
      rawTranscript: raw,
      cleanedTranscript: cleaned,
      uncertainSegments: List.unmodifiable(uncertain),
      isSuccess: isSuccess,
      errorMessage: map['errorMessage'] as String?,
      errorCode: map['errorCode'] as String?,
      isDevelopmentMock: map['isDevelopmentMock'] as bool? ?? false,
    );
  }

  @override
  String toString() =>
      'TranscriptCleanupResult(isSuccess: $isSuccess, cleanedLength: ${cleanedTranscript.length}, uncertainties: ${uncertainSegments.length})';
}

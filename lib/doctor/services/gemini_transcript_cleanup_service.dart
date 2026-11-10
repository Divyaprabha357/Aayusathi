import '../../core/backend/backend_mode.dart';
import '../../core/firebase/firebase_initializer.dart';
import '../models/transcript_cleanup_input.dart';
import '../models/transcript_cleanup_result.dart';
import 'doctor_session_service.dart';
import 'firebase_gemini_transcript_cleanup_service.dart';
import 'mock_gemini_transcript_cleanup_service.dart';

/// Abstract service contract for the Gemini Speech Transcript Cleanup Assistant.
///
/// Features & Architectural Rules:
/// - Provides normalized and cleaned transcript drafts without altering clinical meaning.
/// - Prioritizes [MockGeminiTranscriptCleanupService] in Development Mode (`DOCTOR_DEV_MODE=true`).
/// - Uses [FirebaseGeminiTranscriptCleanupService] in production with secure server-side API keys.
/// - Never exposes `GEMINI_API_KEY` to the Flutter client.
/// - Strictly decoupled from [GeminiDocumentationService] and prescription logic.
abstract class GeminiTranscriptCleanupService {
  static GeminiTranscriptCleanupService? _customInstance;

  /// Sets custom service override for testing.
  static set instance(GeminiTranscriptCleanupService? service) {
    _customInstance = service;
  }

  /// Resolves the active transcript cleanup service based on doctor session and backend mode.
  static GeminiTranscriptCleanupService get instance {
    if (_customInstance != null) return _customInstance!;

    // Explicitly prioritize Development Mode (same pattern as D4-D10)
    if (DoctorSessionService.instance.isDevelopmentMode) {
      return MockGeminiTranscriptCleanupService.instance;
    }

    if (BackendProvider.instance.isFirebaseMode && FirebaseInitializer.isInitialized) {
      return FirebaseGeminiTranscriptCleanupService.instance;
    }

    return MockGeminiTranscriptCleanupService.instance;
  }

  /// Cleans and normalizes the speech transcript provided in [input].
  Future<TranscriptCleanupResult> cleanupTranscript(
    TranscriptCleanupInput input,
  );
}

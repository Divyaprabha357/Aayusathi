import '../../core/backend/backend_mode.dart';
import '../../core/firebase/firebase_initializer.dart';
import '../../core/localization/kiosk_locale.dart';
import '../models/documentation_input.dart';
import '../models/documentation_summary_result.dart';
import 'doctor_session_service.dart';
import 'firebase_gemini_documentation_service.dart';
import 'mock_gemini_documentation_service.dart';

/// Abstract service contract for the Gemini Clinical Documentation Assistant.
///
/// Features:
/// - Provides structured documentation summaries synthesized from explicit doctor notes.
/// - Prioritizes [MockGeminiDocumentationService] in Development Mode (`DOCTOR_DEV_MODE=true`).
/// - Uses [FirebaseGeminiDocumentationService] in production with secure server-side API keys.
/// - Never exposes `GEMINI_API_KEY` to the Flutter client.
abstract class GeminiDocumentationService {
  static GeminiDocumentationService? _customInstance;

  /// Sets custom service override for testing.
  static set instance(GeminiDocumentationService? service) {
    _customInstance = service;
  }

  /// Resolves the active documentation service based on doctor session and backend mode.
  static GeminiDocumentationService get instance {
    if (_customInstance != null) return _customInstance!;

    // Explicitly prioritize Development Mode (same pattern as D4-D9)
    if (DoctorSessionService.instance.isDevelopmentMode) {
      return MockGeminiDocumentationService.instance;
    }

    if (BackendProvider.instance.isFirebaseMode && FirebaseInitializer.isInitialized) {
      return FirebaseGeminiDocumentationService.instance;
    }

    return MockGeminiDocumentationService.instance;
  }

  /// Generates a structured clinical visit summary draft from sanitized [input].
  Future<DocumentationSummaryResult> generateDocumentationSummary(
    DocumentationInput input, {
    KioskLocale locale = KioskLocale.english,
  });
}

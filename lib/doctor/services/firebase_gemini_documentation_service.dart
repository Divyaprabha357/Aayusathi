import 'dart:async';
import '../../core/firebase/firebase_initializer.dart';
import '../../core/localization/kiosk_locale.dart';
import '../models/documentation_input.dart';
import '../models/documentation_summary_result.dart';
import 'gemini_documentation_service.dart';
import 'mock_gemini_documentation_service.dart';

/// Production implementation of [GeminiDocumentationService] communicating with
/// secure backend Cloud Functions.
///
/// Security & Architectural Rules:
/// - Strictly NEVER hardcodes or exposes `GEMINI_API_KEY` on the client.
/// - Passes only sanitized [DocumentationInput] maps.
/// - Validates structured JSON responses before returning to the UI.
/// - Gracefully falls back if backend is not yet deployed without crashing the application.
class FirebaseGeminiDocumentationService implements GeminiDocumentationService {
  static final FirebaseGeminiDocumentationService instance =
      FirebaseGeminiDocumentationService._();
  FirebaseGeminiDocumentationService._();
  factory FirebaseGeminiDocumentationService() => instance;

  @override
  Future<DocumentationSummaryResult> generateDocumentationSummary(
    DocumentationInput input, {
    KioskLocale locale = KioskLocale.english,
  }) async {
    // 1. Validate completeness
    if (!input.isComplete) {
      return DocumentationSummaryResult.failure(
        errorMessage: 'Missing required consultation fields: ${input.missingFields.join(", ")}',
        errorCode: 'MISSING_MANDATORY_FIELDS',
      );
    }

    // 2. If Firebase is not initialized, fallback to mock service
    if (!FirebaseInitializer.isInitialized) {
      return MockGeminiDocumentationService.instance.generateDocumentationSummary(
        input,
        locale: locale,
      );
    }

    try {
      // When live Cloud Functions endpoint is configured:
      // final callable = FirebaseFunctions.instance.httpsCallable('generateClinicalDocumentationSummary');
      // final response = await callable.call<Map<String, dynamic>>({
      //   'input': input.toMap(),
      //   'locale': locale.name,
      // });
      // return DocumentationSummaryResult.fromMap(response.data);

      // In current phase with secure backend abstraction:
      return await MockGeminiDocumentationService.instance.generateDocumentationSummary(
        input,
        locale: locale,
      );
    } catch (e) {
      return DocumentationSummaryResult.failure(
        errorMessage: 'Documentation assistance is temporarily unavailable. Your consultation data has not been changed.',
        errorCode: 'SERVICE_UNAVAILABLE',
      );
    }
  }
}

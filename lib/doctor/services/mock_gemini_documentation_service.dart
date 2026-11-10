import 'dart:async';
import '../../core/localization/kiosk_locale.dart';
import '../models/documentation_input.dart';
import '../models/documentation_summary_result.dart';
import 'gemini_documentation_service.dart';

/// In-memory mock implementation of [GeminiDocumentationService] for development and testing.
///
/// Features:
/// - Provides deterministic clinical documentation summaries synthesized strictly from doctor notes.
/// - Never contacts external Gemini APIs and never requires an API key.
/// - Implements comprehensive error simulation flags for robust test coverage.
/// - Supports multilingual synthesis across English, Hindi, and Marathi.
class MockGeminiDocumentationService implements GeminiDocumentationService {
  static final MockGeminiDocumentationService instance =
      MockGeminiDocumentationService._();
  MockGeminiDocumentationService._();
  factory MockGeminiDocumentationService() => instance;

  // Error simulation flags
  bool simulateNetworkError = false;
  bool simulateTimeout = false;
  bool simulateRateLimit = false;
  bool simulateMalformedResponse = false;
  bool simulateEmptyResponse = false;
  bool simulateSafetyRefusal = false;
  bool simulateServiceUnavailable = false;

  // Custom summary override for testing
  String? customSummaryOverride;

  void resetToDefaults() {
    simulateNetworkError = false;
    simulateTimeout = false;
    simulateRateLimit = false;
    simulateMalformedResponse = false;
    simulateEmptyResponse = false;
    simulateSafetyRefusal = false;
    simulateServiceUnavailable = false;
    customSummaryOverride = null;
  }

  @override
  Future<DocumentationSummaryResult> generateDocumentationSummary(
    DocumentationInput input, {
    KioskLocale locale = KioskLocale.english,
  }) async {
    // Simulate realistic processing delay
    await Future.delayed(const Duration(milliseconds: 150));

    // 1. Check Error Simulations
    if (simulateNetworkError) {
      return DocumentationSummaryResult.failure(
        errorMessage: 'Network connection failed.',
        errorCode: 'NETWORK_ERROR',
      );
    }

    if (simulateTimeout) {
      return DocumentationSummaryResult.failure(
        errorMessage: 'Documentation request timed out.',
        errorCode: 'TIMEOUT',
      );
    }

    if (simulateRateLimit) {
      return DocumentationSummaryResult.failure(
        errorMessage: 'AI documentation rate limit exceeded. Please try again shortly.',
        errorCode: 'RATE_LIMITED',
      );
    }

    if (simulateServiceUnavailable) {
      return DocumentationSummaryResult.failure(
        errorMessage: 'Documentation assistance is temporarily unavailable. Your consultation data has not been changed.',
        errorCode: 'SERVICE_UNAVAILABLE',
      );
    }

    if (simulateSafetyRefusal) {
      return DocumentationSummaryResult.failure(
        errorMessage: 'Documentation generation declined by safety filter.',
        errorCode: 'SAFETY_REFUSAL',
      );
    }

    if (simulateMalformedResponse) {
      return DocumentationSummaryResult.failure(
        errorMessage: 'Unable to parse AI response.',
        errorCode: 'MALFORMED_RESPONSE',
      );
    }

    if (simulateEmptyResponse) {
      return DocumentationSummaryResult.failure(
        errorMessage: 'AI returned an empty response.',
        errorCode: 'EMPTY_RESPONSE',
      );
    }

    // 2. Validate completeness of required consultation fields
    if (!input.isComplete) {
      return DocumentationSummaryResult.failure(
        errorMessage: 'Missing required consultation fields: ${input.missingFields.join(", ")}',
        errorCode: 'MISSING_MANDATORY_FIELDS',
      );
    }

    // 3. Check custom override
    if (customSummaryOverride != null) {
      return DocumentationSummaryResult.success(
        summary: customSummaryOverride!,
        keyDocumentedFindings: [
          'Chief Complaint: ${input.chiefComplaint}',
          'Observations: ${input.clinicalObservations}',
        ],
        documentedAssessment: input.assessment,
        documentedPlan: input.plan,
      );
    }

    // 4. Generate deterministic summary based on locale
    final keyFindings = <String>[
      'Chief Complaint: ${input.chiefComplaint} (${input.onsetDuration})',
      'Associated Symptoms: ${input.associatedSymptoms}',
      'Medical History: ${input.medicalHistory}',
      'Current Medication: ${input.currentMedication}',
      'Clinical Observations: ${input.clinicalObservations}',
    ];

    String summaryText;
    switch (locale) {
      case KioskLocale.hindi:
        summaryText =
            'मरीज़ ${input.chiefComplaint} की शिकायत के साथ आया (${input.onsetDuration})। संबंधित लक्षण: ${input.associatedSymptoms}। चिकित्सा इतिहास: ${input.medicalHistory}। वर्तमान दवाएं: ${input.currentMedication}। क्लिनिकल अवलोकन: ${input.clinicalObservations}। नैदानिक मूल्यांकन: ${input.assessment}। उपचार योजना: ${input.plan}।';
        if (input.followUp != null && input.followUp!.isNotEmpty) {
          summaryText += ' अनुवर्ती परामर्श: ${input.followUp}।';
        }
        if (input.patientInstructions != null && input.patientInstructions!.isNotEmpty) {
          summaryText += ' मरीज़ निर्देश: ${input.patientInstructions}।';
        }
        break;

      case KioskLocale.marathi:
        summaryText =
            'रुग्ण ${input.chiefComplaint} च्या तक्रारीसह आला (${input.onsetDuration}). संबंधित लक्षणे: ${input.associatedSymptoms}. वैद्यकीय इतिहास: ${input.medicalHistory}. सध्याची औषधे: ${input.currentMedication}. क्लिनिकल निरीक्षणे: ${input.clinicalObservations}. निदान अंदाज: ${input.assessment}. उपचार योजना: ${input.plan}.';
        if (input.followUp != null && input.followUp!.isNotEmpty) {
          summaryText += ' पुढील भेट: ${input.followUp}.';
        }
        if (input.patientInstructions != null && input.patientInstructions!.isNotEmpty) {
          summaryText += ' रुग्णाला सूचना: ${input.patientInstructions}.';
        }
        break;

      case KioskLocale.english:
        summaryText =
            'Patient presented with ${input.chiefComplaint} for ${input.onsetDuration}. Associated symptoms documented: ${input.associatedSymptoms}. Medical history: ${input.medicalHistory}. Current medication: ${input.currentMedication}. Clinical examination revealed: ${input.clinicalObservations}. Diagnostic assessment: ${input.assessment}. Management plan: ${input.plan}.';
        if (input.followUp != null && input.followUp!.isNotEmpty) {
          summaryText += ' Follow-up: ${input.followUp}.';
        }
        if (input.patientInstructions != null && input.patientInstructions!.isNotEmpty) {
          summaryText += ' Patient Instructions: ${input.patientInstructions}.';
        }
        break;
    }

    return DocumentationSummaryResult.success(
      summary: summaryText,
      keyDocumentedFindings: keyFindings,
      documentedAssessment: input.assessment,
      documentedPlan: input.plan,
    );
  }
}

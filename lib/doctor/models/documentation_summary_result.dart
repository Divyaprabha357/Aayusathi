/// Structured output result from the Gemini Clinical Documentation Assistant.
///
/// Rules:
/// - Contains synthesized clinical visit summary and organized findings derived strictly from input notes.
/// - Never contains autonomous diagnoses or treatment prescriptions.
/// - Requires explicit doctor review before approval.
class DocumentationSummaryResult {
  final String summary;
  final List<String> keyDocumentedFindings;
  final String documentedAssessment;
  final String documentedPlan;
  final bool isSuccess;
  final String? errorMessage;
  final String? errorCode;
  final DateTime generatedAt;

  const DocumentationSummaryResult({
    required this.summary,
    required this.keyDocumentedFindings,
    required this.documentedAssessment,
    required this.documentedPlan,
    required this.isSuccess,
    this.errorMessage,
    this.errorCode,
    required this.generatedAt,
  });

  /// Factory for a successful documentation response
  factory DocumentationSummaryResult.success({
    required String summary,
    List<String> keyDocumentedFindings = const [],
    String documentedAssessment = '',
    String documentedPlan = '',
    DateTime? generatedAt,
  }) {
    return DocumentationSummaryResult(
      summary: summary.trim(),
      keyDocumentedFindings: keyDocumentedFindings,
      documentedAssessment: documentedAssessment.trim(),
      documentedPlan: documentedPlan.trim(),
      isSuccess: true,
      generatedAt: generatedAt ?? DateTime.now(),
    );
  }

  /// Factory for a failed documentation response
  factory DocumentationSummaryResult.failure({
    required String errorMessage,
    String? errorCode,
    DateTime? generatedAt,
  }) {
    return DocumentationSummaryResult(
      summary: '',
      keyDocumentedFindings: const [],
      documentedAssessment: '',
      documentedPlan: '',
      isSuccess: false,
      errorMessage: errorMessage,
      errorCode: errorCode,
      generatedAt: generatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'summary': summary,
      'keyDocumentedFindings': keyDocumentedFindings,
      'documentedAssessment': documentedAssessment,
      'documentedPlan': documentedPlan,
      'isSuccess': isSuccess,
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (errorCode != null) 'errorCode': errorCode,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory DocumentationSummaryResult.fromMap(Map<String, dynamic> map) {
    return DocumentationSummaryResult(
      summary: map['summary'] as String? ?? '',
      keyDocumentedFindings: (map['keyDocumentedFindings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      documentedAssessment: map['documentedAssessment'] as String? ?? '',
      documentedPlan: map['documentedPlan'] as String? ?? '',
      isSuccess: map['isSuccess'] as bool? ?? false,
      errorMessage: map['errorMessage'] as String?,
      errorCode: map['errorCode'] as String?,
      generatedAt: map['generatedAt'] != null
          ? DateTime.tryParse(map['generatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

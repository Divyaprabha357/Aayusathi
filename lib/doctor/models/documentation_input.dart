/// Sanitized input Data Transfer Object (DTO) for the Gemini Clinical Documentation Assistant.
///
/// Hierarchy & Security Rules:
/// - Strictly contains ONLY documentation-related consultation fields.
/// - NEVER includes Aadhaar numbers, OTPs, auth passwords, raw UIDs, phone numbers, or raw audio.
/// - Requires all 8 mandatory consultation fields to be non-empty for complete status.
class DocumentationInput {
  // 8 Mandatory Consultation Fields
  final String chiefComplaint;
  final String onsetDuration;
  final String associatedSymptoms;
  final String medicalHistory;
  final String currentMedication;
  final String clinicalObservations;
  final String assessment;
  final String plan;

  // 3 Optional Contextual Fields
  final String? previousRelevantHistory;
  final String? followUp;
  final String? patientInstructions;

  const DocumentationInput({
    required this.chiefComplaint,
    required this.onsetDuration,
    required this.associatedSymptoms,
    required this.medicalHistory,
    required this.currentMedication,
    required this.clinicalObservations,
    required this.assessment,
    required this.plan,
    this.previousRelevantHistory,
    this.followUp,
    this.patientInstructions,
  });

  /// Factory for an empty input
  factory DocumentationInput.empty() {
    return const DocumentationInput(
      chiefComplaint: '',
      onsetDuration: '',
      associatedSymptoms: '',
      medicalHistory: '',
      currentMedication: '',
      clinicalObservations: '',
      assessment: '',
      plan: '',
    );
  }

  /// Whether all 8 mandatory fields are filled with non-whitespace content.
  bool get isComplete =>
      chiefComplaint.trim().isNotEmpty &&
      onsetDuration.trim().isNotEmpty &&
      associatedSymptoms.trim().isNotEmpty &&
      medicalHistory.trim().isNotEmpty &&
      currentMedication.trim().isNotEmpty &&
      clinicalObservations.trim().isNotEmpty &&
      assessment.trim().isNotEmpty &&
      plan.trim().isNotEmpty;

  /// Returns missing mandatory field names for validation feedback in the UI.
  List<String> get missingFields {
    final missing = <String>[];
    if (chiefComplaint.trim().isEmpty) missing.add('Chief Complaint');
    if (onsetDuration.trim().isEmpty) missing.add('Onset / Duration');
    if (associatedSymptoms.trim().isEmpty) missing.add('Associated Symptoms');
    if (medicalHistory.trim().isEmpty) missing.add('Medical History');
    if (currentMedication.trim().isEmpty) missing.add('Current Medication');
    if (clinicalObservations.trim().isEmpty) missing.add('Clinical Observations');
    if (assessment.trim().isEmpty) missing.add('Assessment');
    if (plan.trim().isEmpty) missing.add('Plan');
    return missing;
  }

  Map<String, dynamic> toMap() {
    return {
      'chiefComplaint': chiefComplaint.trim(),
      'onsetDuration': onsetDuration.trim(),
      'associatedSymptoms': associatedSymptoms.trim(),
      'medicalHistory': medicalHistory.trim(),
      'currentMedication': currentMedication.trim(),
      'clinicalObservations': clinicalObservations.trim(),
      'assessment': assessment.trim(),
      'plan': plan.trim(),
      if (previousRelevantHistory != null && previousRelevantHistory!.trim().isNotEmpty)
        'previousRelevantHistory': previousRelevantHistory!.trim(),
      if (followUp != null && followUp!.trim().isNotEmpty)
        'followUp': followUp!.trim(),
      if (patientInstructions != null && patientInstructions!.trim().isNotEmpty)
        'patientInstructions': patientInstructions!.trim(),
    };
  }

  factory DocumentationInput.fromMap(Map<String, dynamic> map) {
    return DocumentationInput(
      chiefComplaint: map['chiefComplaint'] as String? ?? '',
      onsetDuration: map['onsetDuration'] as String? ?? '',
      associatedSymptoms: map['associatedSymptoms'] as String? ?? '',
      medicalHistory: map['medicalHistory'] as String? ?? '',
      currentMedication: map['currentMedication'] as String? ?? '',
      clinicalObservations: map['clinicalObservations'] as String? ?? '',
      assessment: map['assessment'] as String? ?? '',
      plan: map['plan'] as String? ?? '',
      previousRelevantHistory: map['previousRelevantHistory'] as String?,
      followUp: map['followUp'] as String?,
      patientInstructions: map['patientInstructions'] as String?,
    );
  }

  DocumentationInput copyWith({
    String? chiefComplaint,
    String? onsetDuration,
    String? associatedSymptoms,
    String? medicalHistory,
    String? currentMedication,
    String? clinicalObservations,
    String? assessment,
    String? plan,
    String? previousRelevantHistory,
    String? followUp,
    String? patientInstructions,
  }) {
    return DocumentationInput(
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      onsetDuration: onsetDuration ?? this.onsetDuration,
      associatedSymptoms: associatedSymptoms ?? this.associatedSymptoms,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      currentMedication: currentMedication ?? this.currentMedication,
      clinicalObservations: clinicalObservations ?? this.clinicalObservations,
      assessment: assessment ?? this.assessment,
      plan: plan ?? this.plan,
      previousRelevantHistory: previousRelevantHistory ?? this.previousRelevantHistory,
      followUp: followUp ?? this.followUp,
      patientInstructions: patientInstructions ?? this.patientInstructions,
    );
  }
}

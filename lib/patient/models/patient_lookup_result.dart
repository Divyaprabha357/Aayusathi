/// Represents the minimal non-sensitive result of a pre-authentication patient lookup.
/// 
/// Privacy & Security Guardrails:
/// - Only exposes [patientId], masked [maskedPhone], and [isActive] status.
/// - STRICTLY NEVER contains Aadhaar, cases, visits, or full clinical/PII data.
enum PatientLookupStatus {
  found,
  notFound,
  inactive,
  invalidFormat,
  networkError,
}

class PatientLookupResult {
  final String? patientId;
  final String? maskedPhone;
  final bool isActive;
  final PatientLookupStatus status;
  final String? errorMessage;

  const PatientLookupResult({
    this.patientId,
    this.maskedPhone,
    this.isActive = false,
    required this.status,
    this.errorMessage,
  });

  bool get isSuccessful => status == PatientLookupStatus.found && isActive;

  factory PatientLookupResult.found({
    required String patientId,
    required String maskedPhone,
    bool isActive = true,
  }) {
    return PatientLookupResult(
      patientId: patientId,
      maskedPhone: maskedPhone,
      isActive: isActive,
      status: isActive ? PatientLookupStatus.found : PatientLookupStatus.inactive,
      errorMessage: isActive ? null : 'This patient account is currently inactive. Please contact the clinic.',
    );
  }

  factory PatientLookupResult.notFound(String patientId) {
    return const PatientLookupResult(
      status: PatientLookupStatus.notFound,
      errorMessage: 'No registered patient found with this Patient ID. Please check the ID or visit the kiosk.',
    );
  }

  factory PatientLookupResult.invalidFormat([String? message]) {
    return PatientLookupResult(
      status: PatientLookupStatus.invalidFormat,
      errorMessage: message ?? 'Please enter a valid AAYUSATHI Patient ID (e.g. AAYU-102938).',
    );
  }

  factory PatientLookupResult.error(String message) {
    return PatientLookupResult(
      status: PatientLookupStatus.networkError,
      errorMessage: message,
    );
  }
}

import 'package:flutter/foundation.dart';
import '../../core/backend/backend_mode.dart';
import '../../models/patient.dart';
import '../../repositories/patient_repository.dart';
import '../models/patient_lookup_result.dart';

/// Service responsible for privacy-safe Patient ID lookup and validation.
/// 
/// Privacy & Security Guardrails:
/// - Strictly NEVER returns Aadhaar numbers or full clinical history before authentication.
/// - Returns phone numbers in masked format only (e.g., `+91 ******4321`).
/// - Handles Firestore errors gracefully with non-technical messages.
class PatientAuthService {
  final PatientRepository _patientRepository;

  PatientAuthService({PatientRepository? patientRepository})
      : _patientRepository = patientRepository ?? BackendProvider.instance.patientRepository;

  /// Looks up a patient by [rawPatientId] in the Cloud Firestore `patients` collection.
  Future<PatientLookupResult> lookupPatientById(String rawPatientId) async {
    final cleanId = rawPatientId.trim().toUpperCase();

    // 1. Format Validation
    if (cleanId.isEmpty) {
      return PatientLookupResult.invalidFormat('Please enter your Patient ID.');
    }

    // Must be at least 3 alphanumeric characters (e.g. AAYU-102938, PAT-1001, etc.)
    final idRegex = RegExp(r'^[A-Z0-9\-]{3,30}$');
    if (!idRegex.hasMatch(cleanId)) {
      return PatientLookupResult.invalidFormat('Please enter a valid Patient ID format (e.g. AAYU-102938).');
    }

    try {
      final Patient? patient = await _patientRepository.getPatientById(cleanId);

      if (patient == null) {
        return PatientLookupResult.notFound(cleanId);
      }

      if (!patient.isActive) {
        return PatientLookupResult(
          patientId: patient.patientId,
          maskedPhone: _maskPhoneNumber(patient.phone),
          isActive: false,
          status: PatientLookupStatus.inactive,
          errorMessage: 'This patient account is inactive. Please contact the hospital reception.',
        );
      }

      // Return only minimal non-sensitive data
      final masked = _maskPhoneNumber(patient.phone);
      return PatientLookupResult.found(
        patientId: patient.patientId,
        maskedPhone: masked,
        isActive: true,
      );
    } catch (e) {
      debugPrint('PatientAuthService.lookupPatientById error: $e');
      return PatientLookupResult.error(
        'Unable to connect to healthcare server. Please check your connection and try again.',
      );
    }
  }

  /// Securely masks phone numbers to show only the last 4 digits.
  /// Example: '9876543210' -> '+91 ******3210'
  String _maskPhoneNumber(String rawPhone) {
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 4) {
      final lastFour = digits.substring(digits.length - 4);
      return '+91 ******$lastFour';
    }
    return '+91 ******4321';
  }
}

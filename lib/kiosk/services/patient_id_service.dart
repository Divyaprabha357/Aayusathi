import '../models/patient_identity.dart';
import 'mock_patient_repository.dart';

/// Dedicated service responsible for generating unique AAYUSATHI Patient IDs.
abstract class PatientIdService {
  String generatePatientId(PatientIdentity patient);
}

/// Standard generator producing IDs in the format: AAYU-XXXXXX (6 numeric digits).
class StandardPatientIdService implements PatientIdService {
  final MockPatientRepository _repository;
  static int _sequenceCounter = 100;

  StandardPatientIdService({MockPatientRepository? repository})
      : _repository = repository ?? MockPatientRepository.instance;

  @override
  String generatePatientId(PatientIdentity patient) {
    // If the mock identity already had an assigned Patient ID, use it
    if (patient.patientId.isNotEmpty && patient.patientId.startsWith('AAYU-')) {
      return patient.patientId;
    }

    // Generate a deterministic 6-digit number based on Aadhaar digits + sequence
    final cleanAadhaar = patient.aadhaarNumber.replaceAll(RegExp(r'\s+'), '');
    int seed = 123456;
    if (cleanAadhaar.length >= 6) {
      seed = int.tryParse(cleanAadhaar.substring(cleanAadhaar.length - 6)) ?? 123456;
    }
    _sequenceCounter++;
    final candidateSuffix = ((seed + _sequenceCounter) % 900000 + 100000).toString();
    final generatedId = 'AAYU-$candidateSuffix';

    // Register into repository
    final updated = patient.copyWith(patientId: generatedId, isNewRegistration: true);
    _repository.savePatient(updated);

    return generatedId;
  }
}

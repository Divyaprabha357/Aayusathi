import '../../core/backend/backend_exception.dart';
import '../../core/backend/backend_mode.dart';
import '../../repositories/patient_repository.dart';
import '../models/patient_identity.dart';
import 'mock_patient_repository.dart';

/// Result status for an Existing Patient ID lookup.
class PatientLookupResult {
  final bool isSuccess;
  final PatientIdentity? patient;
  final String? errorCode;

  const PatientLookupResult.success(this.patient)
      : isSuccess = true,
        errorCode = null;

  const PatientLookupResult.failure(this.errorCode)
      : isSuccess = false,
        patient = null;
}

/// Abstract contract for looking up existing registered patients.
abstract class PatientLookupService {
  Future<PatientLookupResult> lookupPatient(String patientId, {bool simulateDelay = true});
}

/// Production repository-backed patient lookup service.
/// Dynamically queries the active [BackendProvider.instance.patientRepository]
/// (works seamlessly with both Mock and Firebase backends).
class RepositoryPatientLookupService extends MockPatientLookupService {
  final PatientRepository? _customRepository;

  RepositoryPatientLookupService({
    PatientRepository? repository,
    super.simulateDelay = false,
  }) : _customRepository = repository;

  PatientRepository get _patientRepo =>
      _customRepository ?? BackendProvider.instance.patientRepository;

  @override
  Future<PatientLookupResult> lookupPatient(
    String patientId, {
    bool? simulateDelay,
  }) async {
    final clean = patientId.replaceAll(RegExp(r'\s+'), '').toUpperCase().trim();

    if (clean.isEmpty) {
      return const PatientLookupResult.failure('EMPTY_ID');
    }

    String normalized = clean;
    if (!clean.startsWith('AAYU-')) {
      if (clean.length != 6 || !RegExp(r'^\d{6}$').hasMatch(clean)) {
        return const PatientLookupResult.failure('INVALID_FORMAT');
      }
      normalized = 'AAYU-$clean';
    } else {
      final suffix = clean.replaceFirst('AAYU-', '');
      if (suffix.length != 6 || !RegExp(r'^\d{6}$').hasMatch(suffix)) {
        return const PatientLookupResult.failure('INVALID_FORMAT');
      }
    }

    if (simulateDelay ?? this.simulateDelay) {
      await Future.delayed(const Duration(milliseconds: 350));
    }

    try {
      final patient = await _patientRepo.getPatientById(normalized);
      if (patient != null) {
        final legacyIdentity = MockPatientRepository.instance.findByPatientId(normalized);
        final patientIdentity = patient.toPatientIdentity(
          aadhaarNumber: legacyIdentity?.aadhaarNumber ?? '',
        );
        return PatientLookupResult.success(patientIdentity);
      } else {
        return const PatientLookupResult.failure('NOT_FOUND');
      }
    } on BackendException catch (e) {
      return PatientLookupResult.failure(e.code);
    } catch (e) {
      return const PatientLookupResult.failure('UNAVAILABLE');
    }
  }
}

/// Mock implementation searching the controlled fictional dataset (retained for backward compatibility).
class MockPatientLookupService implements PatientLookupService {
  final MockPatientRepository _repository;
  bool simulateDelay;

  MockPatientLookupService({MockPatientRepository? repository, this.simulateDelay = true})
      : _repository = repository ?? MockPatientRepository.instance;

  @override
  Future<PatientLookupResult> lookupPatient(
    String patientId, {
    bool? simulateDelay,
  }) async {
    final clean = patientId.replaceAll(RegExp(r'\s+'), '').toUpperCase().trim();

    if (clean.isEmpty) {
      return const PatientLookupResult.failure('EMPTY_ID');
    }

    String normalized = clean;
    if (!clean.startsWith('AAYU-')) {
      if (clean.length != 6 || !RegExp(r'^\d{6}$').hasMatch(clean)) {
        return const PatientLookupResult.failure('INVALID_FORMAT');
      }
      normalized = 'AAYU-$clean';
    } else {
      final suffix = clean.replaceFirst('AAYU-', '');
      if (suffix.length != 6 || !RegExp(r'^\d{6}$').hasMatch(suffix)) {
        return const PatientLookupResult.failure('INVALID_FORMAT');
      }
    }

    if (simulateDelay ?? this.simulateDelay) {
      await Future.delayed(const Duration(milliseconds: 350));
    }

    final patient = _repository.findByPatientId(normalized);
    if (patient != null) {
      return PatientLookupResult.success(patient);
    } else {
      return const PatientLookupResult.failure('NOT_FOUND');
    }
  }
}

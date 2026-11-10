import '../models/patient.dart';

/// Abstract contract for patient persistence and retrieval.
abstract class PatientRepository {
  /// Retrieves a patient record by [patientId] (e.g. "AAYU-102938").
  Future<Patient?> getPatientById(String patientId);

  /// Saves or updates a patient record.
  Future<void> savePatient(Patient patient);

  /// Creates a new patient record with duplicate protection.
  /// Throws [BackendException] with code `duplicatePatient` if [patient.patientId] already exists.
  Future<void> createPatient(Patient patient);

  /// Checks if a patient with [patientId] exists.
  Future<bool> patientExists(String patientId);
}

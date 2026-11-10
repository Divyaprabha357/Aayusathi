import '../../core/backend/backend_exception.dart';
import '../../models/patient.dart';
import '../patient_repository.dart';

/// In-memory mock implementation of [PatientRepository] containing
/// fictional patient records for development, offline execution, and unit tests.
///
/// NOTE: Uses purely fictional data. No real personal records or UIDAI integrations.
class MockPatientRepository implements PatientRepository {
  static final MockPatientRepository instance = MockPatientRepository._();
  MockPatientRepository._() {
    resetToDefaults();
  }
  factory MockPatientRepository() => instance;

  final Map<String, Patient> _patients = {};

  void resetToDefaults() {
    _patients.clear();
    final defaultPatients = [
      Patient(
        patientId: 'AAYU-102938',
        name: 'Aarav Sharma',
        dateOfBirth: '14 May 1990',
        age: 34,
        gender: 'Male',
        phone: '+91 98765 43210',
        bloodGroup: 'O+',
        address: '104, Green Meadows, Pune, Maharashtra 411001',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      Patient(
        patientId: 'AAYU-482910',
        name: 'Priya Patil',
        dateOfBirth: '22 Sep 1996',
        age: 28,
        gender: 'Female',
        phone: '+91 98123 45678',
        bloodGroup: 'B+',
        address: 'Flat 12, Shivneri Apts, Dadar, Mumbai 400014',
        createdAt: DateTime(2026, 1, 2),
        updatedAt: DateTime(2026, 1, 2),
      ),
      Patient(
        patientId: 'AAYU-773829',
        name: 'Rajesh Kulkarni',
        dateOfBirth: '03 Nov 1962',
        age: 62,
        gender: 'Male',
        phone: '+91 99234 56789',
        bloodGroup: 'A+',
        address: 'Plot 45, Kothrud, Pune, Maharashtra 411038',
        createdAt: DateTime(2026, 1, 3),
        updatedAt: DateTime(2026, 1, 3),
      ),
      Patient(
        patientId: 'AAYU-918234',
        name: 'Sunita Deshmukh',
        dateOfBirth: '18 Jul 1979',
        age: 45,
        gender: 'Female',
        phone: '+91 97654 32109',
        bloodGroup: 'AB+',
        address: 'Bungalow 8, Ramdas Peth, Nagpur 440010',
        createdAt: DateTime(2026, 1, 4),
        updatedAt: DateTime(2026, 1, 4),
      ),
      Patient(
        patientId: 'PAT-MOCK-001',
        name: 'Aarav Sharma',
        dateOfBirth: '14 May 1990',
        age: 34,
        gender: 'Male',
        phone: '+91 98765 43210',
        bloodGroup: 'O+',
        address: '104, Green Meadows, Pune, Maharashtra 411001',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    ];

    for (final p in defaultPatients) {
      _patients[p.patientId.toUpperCase()] = p;
    }
  }

  @override
  Future<Patient?> getPatientById(String patientId) async {
    final clean = patientId.replaceAll(RegExp(r'\s+'), '').toUpperCase().trim();
    final normalized = clean.startsWith('AAYU-') ? clean : 'AAYU-$clean';
    return _patients[normalized] ?? _patients[clean];
  }

  @override
  Future<void> savePatient(Patient patient) async {
    _patients[patient.patientId.toUpperCase()] = patient;
  }

  @override
  Future<void> createPatient(Patient patient) async {
    final key = patient.patientId.toUpperCase();
    if (_patients.containsKey(key)) {
      throw BackendException(
        code: BackendException.duplicatePatient,
        message: 'Patient ID ${patient.patientId} already exists in mock repository.',
      );
    }
    _patients[key] = patient;
  }

  @override
  Future<bool> patientExists(String patientId) async {
    final p = await getPatientById(patientId);
    return p != null;
  }

  /// Exposes current count for test verification
  int get count => _patients.length;
}

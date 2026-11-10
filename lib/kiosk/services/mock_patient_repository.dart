import '../models/patient_identity.dart';

/// Controlled deterministic mock repository holding fictional patient identities
/// for AAYUSATHI Kiosk testing.
/// 
/// NOTE: Uses purely fictional test data. No real personal records or UIDAI integrations.
class MockPatientRepository {
  static final MockPatientRepository instance = MockPatientRepository._();
  MockPatientRepository._() {
    resetToDefaults();
  }
  factory MockPatientRepository() => instance;

  static const List<PatientIdentity> _defaultRegisteredPatients = [
    PatientIdentity(
      aadhaarNumber: '111122223333',
      patientId: 'AAYU-102938',
      fullName: 'Aarav Sharma',
      dob: '14 May 1990',
      age: 34,
      gender: 'Male',
      phone: '+91 98765 43210',
      address: '104, Green Meadows, Pune, Maharashtra 411001',
      bloodGroup: 'O+',
    ),
    PatientIdentity(
      aadhaarNumber: '444455556666',
      patientId: 'AAYU-482910',
      fullName: 'Priya Patil',
      dob: '22 Sep 1996',
      age: 28,
      gender: 'Female',
      phone: '+91 98123 45678',
      address: 'Flat 12, Shivneri Apts, Dadar, Mumbai 400014',
      bloodGroup: 'B+',
    ),
    PatientIdentity(
      aadhaarNumber: '777788889999',
      patientId: 'AAYU-773829',
      fullName: 'Rajesh Kulkarni',
      dob: '03 Nov 1962',
      age: 62,
      gender: 'Male',
      phone: '+91 99234 56789',
      address: 'Plot 45, Kothrud, Pune, Maharashtra 411038',
      bloodGroup: 'A+',
    ),
    PatientIdentity(
      aadhaarNumber: '123456789012',
      patientId: 'AAYU-918234',
      fullName: 'Sunita Deshmukh',
      dob: '18 Jul 1979',
      age: 45,
      gender: 'Female',
      phone: '+91 97654 32109',
      address: 'Bungalow 8, Ramdas Peth, Nagpur 440010',
      bloodGroup: 'AB+',
    ),
  ];

  static const List<PatientIdentity> _defaultDemoAadhaarRecords = [
    // 5 Fictional Demo Aadhaar Identity Records (Unregistered)
    PatientIdentity(
      aadhaarNumber: '111111111111',
      patientId: '',
      fullName: 'Aarav Patil',
      dob: '12 Jan 2002',
      age: 24,
      gender: 'Male',
      phone: '',
      address: '12 Demo Lane, Vengurla, Maharashtra',
      bloodGroup: 'B+',
      isNewRegistration: true,
    ),
    PatientIdentity(
      aadhaarNumber: '222222222222',
      patientId: '',
      fullName: 'Ananya Deshmukh',
      dob: '05 Mar 1995',
      age: 31,
      gender: 'Female',
      phone: '',
      address: '45 Test Road, Wadala, Mumbai',
      bloodGroup: 'O+',
      isNewRegistration: true,
    ),
    PatientIdentity(
      aadhaarNumber: '333333333333',
      patientId: '',
      fullName: 'Rohan Kulkarni',
      dob: '20 Jul 2007',
      age: 19,
      gender: 'Male',
      phone: '',
      address: '78 Sample Nagar, Pune, Maharashtra',
      bloodGroup: 'A+',
      isNewRegistration: true,
    ),
    PatientIdentity(
      aadhaarNumber: '444444444444',
      patientId: '',
      fullName: 'Meera Joshi',
      dob: '18 Nov 1983',
      age: 42,
      gender: 'Female',
      phone: '',
      address: '23 Prototype Street, Nashik, Maharashtra',
      bloodGroup: 'AB+',
      isNewRegistration: true,
    ),
    PatientIdentity(
      aadhaarNumber: '555555555555',
      patientId: '',
      fullName: 'Kabir Shahi',
      dob: '30 Apr 1970',
      age: 56,
      gender: 'Male',
      phone: '',
      address: '91 Mock Colony, Thane, Maharashtra',
      bloodGroup: 'O-',
      isNewRegistration: true,
    ),
    // Fictional Demo Test Record 1
    PatientIdentity(
      aadhaarNumber: '666666666666',
      patientId: '',
      fullName: 'Yatin Ugale',
      dob: '20 Oct 2000',
      age: 26,
      gender: 'Male',
      phone: '',
      address: 'Nirmala Nagar, Khar Road, Mumbai',
      bloodGroup: 'B+',
      isNewRegistration: true,
    ),
    // Fictional Demo Test Record 2
    PatientIdentity(
      aadhaarNumber: '777777777777',
      patientId: '',
      fullName: 'Urvi Sharma',
      dob: '10 Aug 2002',
      age: 24,
      gender: 'Female',
      phone: '',
      address: 'Ram Nagar, Haryana',
      bloodGroup: 'A+',
      isNewRegistration: true,
    ),
  ];

  static const List<PatientIdentity> _allDefaultRecords = [
    ..._defaultRegisteredPatients,
    ..._defaultDemoAadhaarRecords,
  ];

  final List<PatientIdentity> _database = [];

  /// Look up patient by 12-digit Aadhaar number (ignoring spaces).
  PatientIdentity? findByAadhaar(String rawAadhaar) {
    final clean = rawAadhaar.replaceAll(RegExp(r'\s+'), '').trim();
    try {
      return _database.firstWhere(
        (p) => p.aadhaarNumber == clean,
      );
    } catch (_) {
      return null;
    }
  }

  /// Checks if an Aadhaar number is already linked to an existing registered patient.
  bool isAadhaarRegistered(String rawAadhaar) {
    final clean = rawAadhaar.replaceAll(RegExp(r'\s+'), '').trim();
    final patient = findByAadhaar(clean);
    return patient != null && patient.patientId.trim().isNotEmpty;
  }

  /// Look up patient by AAYUSATHI Patient ID (e.g. "AAYU-102938" or "102938").
  PatientIdentity? findByPatientId(String rawId) {
    final clean = rawId.replaceAll(RegExp(r'\s+'), '').toUpperCase().trim();
    final normalized = clean.startsWith('AAYU-') ? clean : 'AAYU-$clean';

    try {
      return _database.firstWhere(
        (p) => p.patientId.toUpperCase() == normalized,
      );
    } catch (_) {
      return null;
    }
  }

  /// Registers or updates a patient in the mock database for the active runtime.
  /// Prevents duplicates based on aadhaarNumber or non-empty patientId.
  void savePatient(PatientIdentity patient) {
    final cleanAadhaar = patient.aadhaarNumber.replaceAll(RegExp(r'\s+'), '').trim();
    final cleanPatientId = patient.patientId.trim();

    // Remove if already exists to update idempotently
    _database.removeWhere((p) {
      if (cleanAadhaar.isNotEmpty && p.aadhaarNumber == cleanAadhaar) {
        return true;
      }
      if (cleanPatientId.isNotEmpty && p.patientId.trim() == cleanPatientId) {
        return true;
      }
      return false;
    });
    _database.add(patient);
  }

  /// Seeds or re-seeds demo fictional Aadhaar records idempotently without duplicates.
  void seedDemoAadhaarRecords([List<PatientIdentity>? records]) {
    final toSeed = records ?? _defaultDemoAadhaarRecords;
    for (final record in toSeed) {
      savePatient(record);
    }
  }

  /// Resets mock database back to default initial records for test isolation.
  void resetToDefaults() {
    _database.clear();
    _database.addAll(_allDefaultRecords);
  }

  /// Read-only snapshot of current patients for test inspection.
  List<PatientIdentity> get allPatients => List.unmodifiable(_database);
}

import 'package:flutter_test/flutter_test.dart';
import 'package:aayusathi/core/backend/backend_exception.dart';
import 'package:aayusathi/models/patient.dart';
import 'package:aayusathi/repositories/mock/mock_patient_repository.dart';

void main() {
  group('Phase 11: Patient Persistence & Duplicate Protection Tests', () {
    late MockPatientRepository repo;

    setUp(() {
      repo = MockPatientRepository();
      repo.resetToDefaults();
    });

    test('createPatient succeeds for a new patient ID', () async {
      final newPatient = Patient(
        patientId: 'AAYU-555555',
        name: 'Rohan Deshpande',
        dateOfBirth: '10 Jan 1995',
        age: 31,
        gender: 'Male',
        phone: '+91 91234 56789',
        bloodGroup: 'O+',
        address: 'Bavdhan, Pune',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.createPatient(newPatient);

      final retrieved = await repo.getPatientById('AAYU-555555');
      expect(retrieved, isNotNull);
      expect(retrieved?.name, 'Rohan Deshpande');
      expect(retrieved?.patientId, 'AAYU-555555');
    });

    test('createPatient blocks duplicate registration and throws duplicatePatient exception', () async {
      // 'AAYU-102938' is Aarav Sharma (pre-existing default patient)
      final duplicatePatient = Patient(
        patientId: 'AAYU-102938',
        name: 'Imposter Sharma',
        dateOfBirth: '14 May 1990',
        age: 34,
        gender: 'Male',
        phone: '+91 98765 00000',
        bloodGroup: 'O+',
        address: 'Fraud Lane, Mumbai',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        () => repo.createPatient(duplicatePatient),
        throwsA(
          isA<BackendException>().having(
            (e) => e.code,
            'code',
            BackendException.duplicatePatient,
          ),
        ),
      );

      // Verify original patient was not overwritten
      final original = await repo.getPatientById('AAYU-102938');
      expect(original?.name, 'Aarav Sharma');
      expect(original?.phone, '+91 98765 43210');
    });

    test('Patient toFirestore strictly excludes plain-text Aadhaar', () {
      final patient = Patient(
        patientId: 'AAYU-102938',
        name: 'Aarav Sharma',
        dateOfBirth: '14 May 1990',
        age: 34,
        gender: 'Male',
        phone: '+91 98765 43210',
        bloodGroup: 'O+',
        address: 'Pune',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final firestoreData = patient.toFirestore();
      expect(firestoreData.containsKey('aadhaarNumber'), isFalse);
      expect(firestoreData.containsKey('aadhaar'), isFalse);
      expect(firestoreData['patientId'], 'AAYU-102938');
      expect(firestoreData['name'], 'Aarav Sharma');
    });
  });
}

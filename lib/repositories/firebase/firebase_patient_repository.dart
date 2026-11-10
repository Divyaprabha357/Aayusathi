import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/backend/backend_exception.dart';
import '../../core/firebase/firebase_config.dart';
import '../../models/patient.dart';
import '../patient_repository.dart';

/// Cloud Firestore implementation of [PatientRepository].
///
/// Persistence Rules:
/// - Collection: `patients`
/// - Document ID: `patient.patientId` (e.g. `patients/AAYU-102938`)
/// - Aadhaar numbers are STRICTLY NEVER saved to Firestore.
class FirebasePatientRepository implements PatientRepository {
  final FirebaseFirestore? _customFirestore;

  FirebasePatientRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirebaseConfig.patientsCollection);

  @override
  Future<Patient?> getPatientById(String patientId) async {
    final clean = patientId.replaceAll(RegExp(r'\s+'), '').toUpperCase().trim();
    final docId = clean.startsWith('AAYU-') ? clean : 'AAYU-$clean';

    try {
      final doc = await _collection.doc(docId).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return Patient.fromFirestore(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      debugPrint('[FirebasePatientRepository] FirebaseException on getPatientById: ${e.code} - ${e.message}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not fetch patient record from cloud database.',
        originalError: e,
      );
    } catch (e) {
      debugPrint('[FirebasePatientRepository] Unexpected error on getPatientById: $e');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'An unexpected error occurred while retrieving patient record.',
        originalError: e,
      );
    }
  }

  @override
  Future<void> savePatient(Patient patient) async {
    if (patient.patientId.isEmpty) {
      throw const BackendException(
        code: BackendException.invalidData,
        message: 'Patient ID cannot be empty.',
      );
    }

    debugPrint('[AAYUSATHI] Firestore write: patients/${patient.patientId}');

    try {
      final data = patient.toFirestore();
      // Ensure Aadhaar is strictly never present in Firestore document
      data.remove('aadhaarNumber');
      data.remove('aadhaar');

      await _collection.doc(patient.patientId).set(
            data,
            SetOptions(merge: true),
          );
      debugPrint('[AAYUSATHI] Firestore write success: patients/${patient.patientId}');
    } on FirebaseException catch (e) {
      debugPrint('[AAYUSATHI] Firestore write failed: ${e.code}');
      debugPrint('[FirebasePatientRepository] FirebaseException on savePatient: ${e.code} - ${e.message}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not persist patient record to cloud database.',
        originalError: e,
      );
    } catch (e) {
      debugPrint('[AAYUSATHI] Firestore write failed: $e');
      debugPrint('[FirebasePatientRepository] Unexpected error on savePatient: $e');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'An unexpected error occurred while saving patient record.',
        originalError: e,
      );
    }
  }

  @override
  Future<void> createPatient(Patient patient) async {
    if (patient.patientId.isEmpty) {
      throw const BackendException(
        code: BackendException.invalidData,
        message: 'Patient ID cannot be empty.',
      );
    }

    final cleanId = patient.patientId.replaceAll(RegExp(r'\s+'), '').toUpperCase().trim();
    final docRef = _collection.doc(cleanId);

    try {
      final existingDoc = await docRef.get();
      if (existingDoc.exists) {
        debugPrint('[FirebasePatientRepository] Duplicate patient blocked: $cleanId already exists');
        throw BackendException(
          code: BackendException.duplicatePatient,
          message: 'Patient ID $cleanId already exists in cloud database. Cannot overwrite.',
        );
      }

      debugPrint('[AAYUSATHI] Firestore create patient: patients/$cleanId');
      final data = patient.toFirestore();
      data.remove('aadhaarNumber');
      data.remove('aadhaar');

      await docRef.set(data);
      debugPrint('[AAYUSATHI] Firestore create patient success: patients/$cleanId');
    } on BackendException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('[AAYUSATHI] Firestore write failed: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not create patient record in cloud database.',
        originalError: e,
      );
    } catch (e) {
      debugPrint('[AAYUSATHI] Firestore write failed: $e');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'An unexpected error occurred while creating patient record.',
        originalError: e,
      );
    }
  }

  @override
  Future<bool> patientExists(String patientId) async {
    final patient = await getPatientById(patientId);
    return patient != null;
  }
}

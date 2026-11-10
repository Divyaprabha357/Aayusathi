import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/backend/backend_exception.dart';
import '../../core/firebase/firebase_config.dart';
import '../../models/vital_reading.dart';
import '../vital_repository.dart';

/// Cloud Firestore implementation of [VitalRepository].
///
/// Handles persisting sensor and manual vital measurements to the `vitals` collection.
class FirebaseVitalRepository implements VitalRepository {
  final FirebaseFirestore? _customFirestore;

  FirebaseVitalRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirebaseConfig.vitalsCollection);

  @override
  Future<void> saveVitalReading({
    required String patientId,
    required VitalReading reading,
    String? appointmentId,
  }) async {
    final docId = reading.vitalId ??
        'VIT-${DateTime.now().millisecondsSinceEpoch}-${patientId.replaceAll(RegExp(r'\s+'), '')}';

    final data = reading.copyWith(
      vitalId: docId,
      patientId: patientId,
      appointmentId: appointmentId ?? reading.appointmentId,
    ).toFirestore();

    debugPrint('[AAYUSATHI] Firestore write: vitals/$docId');

    try {
      await _collection.doc(docId).set(data, SetOptions(merge: true));
      debugPrint('[AAYUSATHI] Firestore write success: vitals/$docId');
    } on FirebaseException catch (e) {
      debugPrint('[AAYUSATHI] Firestore write failed: ${e.code}');
      debugPrint('[FirebaseVitalRepository] FirebaseException on save: ${e.code}');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Could not persist vital reading to Firestore.',
        originalError: e,
      );
    } catch (e) {
      debugPrint('[AAYUSATHI] Firestore write failed: $e');
      debugPrint('[FirebaseVitalRepository] Unexpected error saving vitals: $e');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Failed to record vitals telemetry.',
        originalError: e,
      );
    }
  }

  @override
  Future<List<VitalReading>> getVitalsForPatient(String patientId) async {
    try {
      final query = await _collection
          .where('patientId', isEqualTo: patientId)
          .orderBy('timestamp', descending: true)
          .get();

      return query.docs
          .map((doc) => VitalReading.fromFirestore(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseVitalRepository] FirebaseException on query: ${e.code}');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Could not query patient vitals.',
        originalError: e,
      );
    }
  }

  @override
  Future<VitalReading?> getVitalsForAppointment(String appointmentId) async {
    try {
      final query = await _collection
          .where('appointmentId', isEqualTo: appointmentId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return VitalReading.fromFirestore(query.docs.first.data(), query.docs.first.id);
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseVitalRepository] FirebaseException on getVitalsForAppointment: ${e.code}');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Could not fetch appointment vitals.',
        originalError: e,
      );
    }
  }
}

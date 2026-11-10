import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/backend/backend_exception.dart';
import '../../core/firebase/firebase_config.dart';
import '../../models/previous_visit_record.dart';
import '../visit_repository.dart';

/// Cloud Firestore implementation of [VisitRepository].
///
/// Features:
/// - Persists consultation visit records to the `visits` collection (`visits/{visitId}`).
/// - Queries visits restricted strictly to the specified patient (`where('patientId', isEqualTo: patientId)`),
///   performing in-memory domain filtering and timestamp sorting to prevent composite index requirements.
/// - Conforms to security rules rejecting unauthenticated requests.
class FirebaseVisitRepository implements VisitRepository {
  final FirebaseFirestore? _customFirestore;

  FirebaseVisitRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirebaseConfig.visitsCollection);

  @override
  Future<void> saveVisit(PreviousVisitRecord visit) async {
    final docId = visit.visitId?.isNotEmpty == true
        ? visit.visitId!
        : 'VIS-${DateTime.now().millisecondsSinceEpoch}-${visit.patientId}';

    final data = visit.copyWith(visitId: docId).toFirestore();

    debugPrint('[AAYUSATHI] Firestore write: visits/$docId');

    try {
      await _collection.doc(docId).set(data, SetOptions(merge: true));
      debugPrint('[AAYUSATHI] Firestore write success: visits/$docId');
    } on FirebaseException catch (e) {
      debugPrint('[AAYUSATHI] Firestore write failed: ${e.code}');
      debugPrint('[FirebaseVisitRepository] FirebaseException on saveVisit: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not persist visit record to Firestore.',
        originalError: e,
      );
    } catch (e) {
      debugPrint('[AAYUSATHI] Firestore write failed: $e');
      debugPrint('[FirebaseVisitRepository] Unexpected error saving visit: $e');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Failed to record consultation visit.',
        originalError: e,
      );
    }
  }

  @override
  Future<PreviousVisitRecord?> getLatestVisitForPatientAndDomain({
    required String patientId,
    required String domainId,
  }) async {
    final cleanPatientId = patientId.replaceAll(RegExp(r'\s+'), '').toUpperCase().trim();
    final cleanDomainId = domainId.toLowerCase().trim();

    try {
      // Query restricted strictly to this patient
      final snapshot = await _collection
          .where('patientId', isEqualTo: cleanPatientId)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final records = snapshot.docs
          .map((doc) => PreviousVisitRecord.fromFirestore(doc.data(), doc.id))
          .where((r) => r.domainId.toLowerCase().trim() == cleanDomainId)
          .toList();

      if (records.isEmpty) return null;

      records.sort((a, b) => b.lastVisitDate.compareTo(a.lastVisitDate));
      return records.first;
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseVisitRepository] FirebaseException querying visits: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not query patient visit history.',
        originalError: e,
      );
    } catch (e) {
      debugPrint('[FirebaseVisitRepository] Unexpected error querying visits: $e');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Failed to retrieve patient visit record.',
        originalError: e,
      );
    }
  }

  @override
  Future<List<PreviousVisitRecord>> getVisitsForPatient(String patientId) async {
    final cleanPatientId = patientId.replaceAll(RegExp(r'\s+'), '').toUpperCase().trim();

    try {
      final snapshot = await _collection
          .where('patientId', isEqualTo: cleanPatientId)
          .get();

      final records = snapshot.docs
          .map((doc) => PreviousVisitRecord.fromFirestore(doc.data(), doc.id))
          .toList();

      records.sort((a, b) => b.lastVisitDate.compareTo(a.lastVisitDate));
      return records;
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseVisitRepository] FirebaseException on getVisitsForPatient: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not retrieve patient visits.',
        originalError: e,
      );
    }
  }
}

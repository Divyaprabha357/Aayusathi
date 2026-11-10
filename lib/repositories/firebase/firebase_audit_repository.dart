import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/backend/backend_exception.dart';
import '../../core/firebase/firebase_config.dart';
import '../../models/audit_log.dart';
import '../audit_repository.dart';

/// Cloud Firestore implementation of [AuditRepository].
///
/// Records and retrieves governance audit logs under the `auditLogs` collection.
class FirebaseAuditRepository implements AuditRepository {
  final FirebaseFirestore? _customFirestore;

  FirebaseAuditRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirebaseConfig.auditLogsCollection);

  @override
  Future<void> logEvent(AuditLog log) async {
    final docId = log.auditId.isNotEmpty
        ? log.auditId
        : 'AUD-${DateTime.now().millisecondsSinceEpoch}';

    debugPrint('[AAYUSATHI] Firestore write: auditLogs/$docId');

    try {
      await _collection.doc(docId).set(
            log.copyWith(auditId: docId).toFirestore(),
            SetOptions(merge: true),
          );
      debugPrint('[AAYUSATHI] Firestore write success: auditLogs/$docId');
    } on FirebaseException catch (e) {
      debugPrint('[AAYUSATHI] Firestore write failed: ${e.code}');
      debugPrint('[FirebaseAuditRepository] FirebaseException logging audit: ${e.code}');
      // Audit failures should not crash user-facing kiosk workflows, but log firmly
    } catch (e) {
      debugPrint('[AAYUSATHI] Firestore write failed: $e');
      debugPrint('[FirebaseAuditRepository] Unexpected error logging audit: $e');
    }
  }

  @override
  Future<List<AuditLog>> getLogsForEntity({
    required String entityType,
    required String entityId,
  }) async {
    try {
      final query = await _collection
          .where('entityType', isEqualTo: entityType)
          .where('entityId', isEqualTo: entityId)
          .orderBy('timestamp', descending: true)
          .get();

      return query.docs.map((doc) => AuditLog.fromFirestore(doc.data(), doc.id)).toList();
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseAuditRepository] FirebaseException querying audit logs: ${e.code}');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Could not fetch audit logs.',
        originalError: e,
      );
    }
  }
}

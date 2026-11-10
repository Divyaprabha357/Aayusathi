import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/backend/backend_exception.dart';
import '../../core/firebase/firebase_config.dart';
import '../../doctor/models/investigation_request.dart';
import '../investigation_repository.dart';

/// Cloud Firestore implementation of [InvestigationRepository].
///
/// Hierarchy:
/// `patients/{patientId}/cases/{caseId}/visits/{visitId}/investigations/{investigationId}`
class FirebaseInvestigationRepository implements InvestigationRepository {
  final FirebaseFirestore? _customFirestore;

  FirebaseInvestigationRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  String _normalizePatientId(String rawId) {
    final clean = rawId.replaceAll(RegExp(r'\s+'), '').toUpperCase().trim();
    if (clean.isEmpty) return clean;
    return clean.startsWith('AAYU-') ? clean : 'AAYU-$clean';
  }

  CollectionReference<Map<String, dynamic>> _getInvestigationsCollection({
    required String patientId,
    required String caseId,
    required String visitId,
  }) {
    final cleanPatientId = _normalizePatientId(patientId);
    return _firestore
        .collection(FirebaseConfig.patientsCollection)
        .doc(cleanPatientId)
        .collection('cases')
        .doc(caseId)
        .collection('visits')
        .doc(visitId)
        .collection('investigations');
  }

  @override
  Future<InvestigationRequest> createInvestigationRequest(
    InvestigationRequest request,
  ) async {
    if (request.patientId == null ||
        request.caseId == null ||
        request.visitId == null) {
      throw BackendException(
        code: BackendException.invalidData,
        message: 'Investigation request must contain patientId, caseId, and visitId.',
      );
    }

    final docId = request.requestId.isNotEmpty
        ? request.requestId
        : 'INV-${request.visitId}-${DateTime.now().millisecondsSinceEpoch}';

    final created = request.copyWith(
      requestId: docId,
      requestedAt: DateTime.now(),
      status: InvestigationStatus.pendingUpload,
    );

    try {
      await _getInvestigationsCollection(
        patientId: created.patientId!,
        caseId: created.caseId!,
        visitId: created.visitId!,
      ).doc(docId).set(created.toFirestore(), SetOptions(merge: true));

      return created;
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseInvestigationRepository] FirebaseException: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not create investigation request in Firestore.',
        originalError: e,
      );
    } catch (e) {
      debugPrint('[FirebaseInvestigationRepository] Unexpected error: $e');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Failed to create investigation request.',
        originalError: e,
      );
    }
  }

  @override
  Future<List<InvestigationRequest>> getInvestigationRequests({
    required String patientId,
    required String caseId,
    required String visitId,
  }) async {
    try {
      final snapshot = await _getInvestigationsCollection(
        patientId: patientId,
        caseId: caseId,
        visitId: visitId,
      ).get();

      final requests = snapshot.docs
          .map((doc) => InvestigationRequest.fromFirestore(doc.data(), doc.id))
          .toList();
      requests.sort((a, b) => a.requestedAt.compareTo(b.requestedAt));
      return requests;
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseInvestigationRepository] FirebaseException: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not fetch investigations from Firestore.',
        originalError: e,
      );
    } catch (e) {
      debugPrint('[FirebaseInvestigationRepository] Unexpected error: $e');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Failed to load investigation requests.',
        originalError: e,
      );
    }
  }

  @override
  Future<InvestigationRequest?> getInvestigationById({
    required String patientId,
    required String caseId,
    required String visitId,
    required String investigationId,
  }) async {
    try {
      final doc = await _getInvestigationsCollection(
        patientId: patientId,
        caseId: caseId,
        visitId: visitId,
      ).doc(investigationId).get();

      if (!doc.exists || doc.data() == null) return null;
      return InvestigationRequest.fromFirestore(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseInvestigationRepository] FirebaseException: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not fetch investigation record from Firestore.',
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateInvestigationStatus({
    required String patientId,
    required String caseId,
    required String visitId,
    required String investigationId,
    required InvestigationStatus status,
    String? doctorId,
    String? reportId,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status.name,
      };
      if (status == InvestigationStatus.uploaded) {
        updates['uploadedAt'] = FieldValue.serverTimestamp();
        if (reportId != null) updates['uploadedReportId'] = reportId;
      } else if (status == InvestigationStatus.reviewed) {
        updates['reviewedAt'] = FieldValue.serverTimestamp();
        if (doctorId != null) updates['reviewedByDoctorId'] = doctorId;
      }

      await _getInvestigationsCollection(
        patientId: patientId,
        caseId: caseId,
        visitId: visitId,
      ).doc(investigationId).update(updates);
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseInvestigationRepository] FirebaseException: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not update investigation status in Firestore.',
        originalError: e,
      );
    }
  }

  @override
  Future<void> markUploaded({
    required String patientId,
    required String caseId,
    required String visitId,
    required String investigationId,
    required String reportId,
  }) async {
    await updateInvestigationStatus(
      patientId: patientId,
      caseId: caseId,
      visitId: visitId,
      investigationId: investigationId,
      status: InvestigationStatus.uploaded,
      reportId: reportId,
    );
  }

  @override
  Future<void> markReviewed({
    required String patientId,
    required String caseId,
    required String visitId,
    required String investigationId,
    required String doctorId,
  }) async {
    await updateInvestigationStatus(
      patientId: patientId,
      caseId: caseId,
      visitId: visitId,
      investigationId: investigationId,
      status: InvestigationStatus.reviewed,
      doctorId: doctorId,
    );
  }

  @override
  Future<void> deleteInvestigation({
    required String patientId,
    required String caseId,
    required String visitId,
    required String investigationId,
  }) async {
    try {
      await _getInvestigationsCollection(
        patientId: patientId,
        caseId: caseId,
        visitId: visitId,
      ).doc(investigationId).delete();
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseInvestigationRepository] FirebaseException: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not delete investigation from Firestore.',
        originalError: e,
      );
    }
  }
}

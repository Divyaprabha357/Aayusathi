import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/backend/backend_exception.dart';
import '../../core/firebase/firebase_config.dart';
import '../../doctor/models/report_document.dart';
import '../report_repository.dart';

/// Cloud Firestore implementation of [ReportRepository].
///
/// Hierarchy:
/// `patients/{patientId}/cases/{caseId}/visits/{visitId}/reports/{reportId}`
class FirebaseReportRepository implements ReportRepository {
  final FirebaseFirestore? _customFirestore;

  FirebaseReportRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  String _normalizePatientId(String rawId) {
    final clean = rawId.replaceAll(RegExp(r'\s+'), '').toUpperCase().trim();
    if (clean.isEmpty) return clean;
    return clean.startsWith('AAYU-') ? clean : 'AAYU-$clean';
  }

  CollectionReference<Map<String, dynamic>> _getReportsCollection({
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
        .collection('reports');
  }

  @override
  Future<ReportDocument> saveReportDocument(ReportDocument report) async {
    final docId = report.reportId.isNotEmpty
        ? report.reportId
        : 'REP-${report.investigationId}-${DateTime.now().millisecondsSinceEpoch}';

    final now = DateTime.now();
    final toSave = report.copyWith(
      reportId: docId,
      uploadedAt: report.uploadedAt,
      reviewStatus: report.reviewStatus,
      createdAt: report.createdAt ?? now,
      updatedAt: now,
    );

    try {
      await _getReportsCollection(
        patientId: toSave.patientId,
        caseId: toSave.caseId,
        visitId: toSave.visitId,
      ).doc(docId).set(toSave.toFirestore(), SetOptions(merge: true));

      return toSave;
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseReportRepository] FirebaseException: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not save report document metadata to Firestore.',
        originalError: e,
      );
    } catch (e) {
      debugPrint('[FirebaseReportRepository] Unexpected error: $e');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Failed to save report document.',
        originalError: e,
      );
    }
  }

  @override
  Future<List<ReportDocument>> getReportsForVisit({
    required String patientId,
    required String caseId,
    required String visitId,
  }) async {
    try {
      final snapshot = await _getReportsCollection(
        patientId: patientId,
        caseId: caseId,
        visitId: visitId,
      ).get();

      final reports = snapshot.docs
          .map((doc) => ReportDocument.fromFirestore(doc.data(), doc.id))
          .toList();
      reports.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return reports;
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseReportRepository] FirebaseException: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not retrieve report documents from Firestore.',
        originalError: e,
      );
    } catch (e) {
      debugPrint('[FirebaseReportRepository] Unexpected error: $e');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Failed to load report documents.',
        originalError: e,
      );
    }
  }

  @override
  Stream<List<ReportDocument>> watchReportsForVisit({
    required String patientId,
    required String caseId,
    required String visitId,
  }) {
    return _getReportsCollection(
      patientId: patientId,
      caseId: caseId,
      visitId: visitId,
    ).snapshots().map((snapshot) {
      final reports = snapshot.docs
          .map((doc) => ReportDocument.fromFirestore(doc.data(), doc.id))
          .toList();
      reports.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return reports;
    });
  }

  @override
  Future<ReportDocument?> getReportById({
    required String patientId,
    required String caseId,
    required String visitId,
    required String reportId,
  }) async {
    try {
      final doc = await _getReportsCollection(
        patientId: patientId,
        caseId: caseId,
        visitId: visitId,
      ).doc(reportId).get();

      if (!doc.exists || doc.data() == null) return null;
      return ReportDocument.fromFirestore(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseReportRepository] FirebaseException: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not fetch report document from Firestore.',
        originalError: e,
      );
    }
  }

  @override
  Future<ReportDocument?> getReportForInvestigation({
    required String patientId,
    required String caseId,
    required String visitId,
    required String investigationId,
  }) async {
    try {
      final snapshot = await _getReportsCollection(
        patientId: patientId,
        caseId: caseId,
        visitId: visitId,
      ).where('investigationId', isEqualTo: investigationId).limit(1).get();

      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return ReportDocument.fromFirestore(doc.data(), doc.id);
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseReportRepository] FirebaseException: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not query report by investigation from Firestore.',
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateReportStatus({
    required String patientId,
    required String caseId,
    required String visitId,
    required String reportId,
    required ReportReviewStatus status,
    required String doctorId,
  }) async {
    try {
      final updates = <String, dynamic>{
        'reviewStatus': status.name,
      };
      if (status == ReportReviewStatus.reviewed) {
        updates['reviewedAt'] = FieldValue.serverTimestamp();
        updates['reviewedByDoctorId'] = doctorId;
      }

      await _getReportsCollection(
        patientId: patientId,
        caseId: caseId,
        visitId: visitId,
      ).doc(reportId).update(updates);
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseReportRepository] FirebaseException: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not update report status in Firestore.',
        originalError: e,
      );
    }
  }

  @override
  Future<void> saveReportAiSummary({
    required String patientId,
    required String caseId,
    required String visitId,
    required String reportId,
    required AiReportSummaryRecord summary,
  }) async {
    try {
      await _getReportsCollection(
        patientId: patientId,
        caseId: caseId,
        visitId: visitId,
      ).doc(reportId).update({
        'aiSummary': summary.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseReportRepository] FirebaseException updating AI summary: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not save report AI summary in Firestore.',
        originalError: e,
      );
    }
  }

  @override
  Future<AiReportSummaryRecord?> getReportAiSummary({
    required String patientId,
    required String caseId,
    required String visitId,
    required String reportId,
  }) async {
    final report = await getReportById(
      patientId: patientId,
      caseId: caseId,
      visitId: visitId,
      reportId: reportId,
    );
    return report?.aiSummary;
  }
}

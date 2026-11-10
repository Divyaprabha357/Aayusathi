import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/backend/backend_exception.dart';
import '../../core/firebase/firebase_config.dart';
import '../../doctor/models/clinical_visit.dart';
import '../../models/vital_reading.dart';
import '../clinical_visit_repository.dart';

/// Cloud Firestore implementation of [ClinicalVisitRepository].
///
/// Hierarchy:
/// `patients/{patientId}/cases/{caseId}/visits/{visitId}`
///
/// Rules:
/// - Scoped visit numbering.
/// - Duplicate visit prevention.
class FirebaseClinicalVisitRepository implements ClinicalVisitRepository {
  final FirebaseFirestore? _customFirestore;

  FirebaseClinicalVisitRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  String _normalizePatientId(String rawId) {
    final clean = rawId.replaceAll(RegExp(r'\s+'), '').toUpperCase().trim();
    if (clean.isEmpty) return clean;
    return clean.startsWith('AAYU-') ? clean : 'AAYU-$clean';
  }

  CollectionReference<Map<String, dynamic>> _getVisitsCollection({
    required String patientId,
    required String caseId,
  }) {
    final cleanPatientId = _normalizePatientId(patientId);
    return _firestore
        .collection(FirebaseConfig.patientsCollection)
        .doc(cleanPatientId)
        .collection('cases')
        .doc(caseId)
        .collection('visits');
  }

  @override
  Future<List<ClinicalVisit>> getVisitsForCase({
    required String patientId,
    required String caseId,
  }) async {
    try {
      final normalizedId = _normalizePatientId(patientId);
      var snapshot = await _getVisitsCollection(
        patientId: normalizedId,
        caseId: caseId,
      ).get();

      if (snapshot.docs.isEmpty && normalizedId.startsWith('AAYU-')) {
        final rawId = normalizedId.replaceFirst('AAYU-', '');
        if (rawId.isNotEmpty) {
          try {
            final fallbackSnapshot = await _firestore
                .collection(FirebaseConfig.patientsCollection)
                .doc(rawId)
                .collection('cases')
                .doc(caseId)
                .collection('visits')
                .get();
            if (fallbackSnapshot.docs.isNotEmpty) {
              snapshot = fallbackSnapshot;
            }
          } catch (_) {}
        }
      }

      final visits = snapshot.docs
          .map((doc) => ClinicalVisit.fromFirestore(doc.data(), doc.id))
          .toList();
      visits.sort((a, b) => a.visitNumber.compareTo(b.visitNumber));
      return visits;
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseClinicalVisitRepository] FirebaseException: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not fetch visits from Firestore.',
        originalError: e,
      );
    } catch (e) {
      debugPrint('[FirebaseClinicalVisitRepository] Unexpected error: $e');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Failed to load consultation visits.',
        originalError: e,
      );
    }
  }

  @override
  Future<ClinicalVisit?> getVisitById({
    required String patientId,
    required String caseId,
    required String visitId,
  }) async {
    try {
      final normalizedId = _normalizePatientId(patientId);
      var doc = await _getVisitsCollection(
        patientId: normalizedId,
        caseId: caseId,
      ).doc(visitId).get();

      if ((!doc.exists || doc.data() == null) && normalizedId.startsWith('AAYU-')) {
        final rawId = normalizedId.replaceFirst('AAYU-', '');
        if (rawId.isNotEmpty) {
          try {
            final fallbackDoc = await _firestore
                .collection(FirebaseConfig.patientsCollection)
                .doc(rawId)
                .collection('cases')
                .doc(caseId)
                .collection('visits')
                .doc(visitId)
                .get();
            if (fallbackDoc.exists && fallbackDoc.data() != null) {
              doc = fallbackDoc;
            }
          } catch (_) {}
        }
      }

      if (!doc.exists || doc.data() == null) return null;
      return ClinicalVisit.fromFirestore(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseClinicalVisitRepository] FirebaseException: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not fetch visit record from Firestore.',
        originalError: e,
      );
    }
  }

  @override
  Future<int> getNextVisitNumber({
    required String patientId,
    required String caseId,
  }) async {
    final visits = await getVisitsForCase(patientId: patientId, caseId: caseId);
    if (visits.isEmpty) return 1;
    final maxNum = visits
        .map((v) => v.visitNumber)
        .reduce((curr, next) => curr > next ? curr : next);
    return maxNum + 1;
  }

  @override
  Future<ClinicalVisit?> getActiveVisitForCase({
    required String patientId,
    required String caseId,
  }) async {
    final visits = await getVisitsForCase(patientId: patientId, caseId: caseId);
    try {
      return visits.firstWhere((v) => v.isActive);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ClinicalVisit> createNextVisit({
    required String patientId,
    required String caseId,
    required String doctorId,
    required String doctorName,
    String? doctorQualification,
    String? appointmentId,
    String? chiefComplaint,
    VitalReading? vitals,
    String? department,
  }) async {
    final activeVisit = await getActiveVisitForCase(
      patientId: patientId,
      caseId: caseId,
    );
    if (activeVisit != null) {
      throw StateError(
        'An active consultation already exists for this Case (${activeVisit.visitId}).',
      );
    }

    final nextNumber = await getNextVisitNumber(
      patientId: patientId,
      caseId: caseId,
    );

    String? resolvedDept = department;
    if (resolvedDept == null || resolvedDept.trim().isEmpty) {
      try {
        final cleanPatientId = _normalizePatientId(patientId);
        final caseDoc = await _firestore
            .collection(FirebaseConfig.patientsCollection)
            .doc(cleanPatientId)
            .collection('cases')
            .doc(caseId)
            .get();
        if (caseDoc.exists && caseDoc.data() != null) {
          final cData = caseDoc.data()!;
          final raw = cData['domain'] ?? cData['department'] ?? cData['domainId'] ?? cData['departmentId'];
          if (raw != null) {
            resolvedDept = raw.toString();
          }
        }
      } catch (_) {}
    }

    final now = DateTime.now();
    final docId = 'VIS-$caseId-$nextNumber-${now.millisecondsSinceEpoch}';
    final newVisit = ClinicalVisit(
      visitId: docId,
      caseId: caseId,
      patientId: patientId,
      doctorId: doctorId,
      doctorName: doctorName,
      doctorQualification: doctorQualification,
      appointmentId: appointmentId,
      department: resolvedDept,
      visitNumber: nextNumber,
      startedAt: now,
      status: ClinicalVisitStatus.active,
      chiefComplaint: chiefComplaint ?? '',
      vitals: vitals,
    );

    try {
      await _getVisitsCollection(
        patientId: patientId,
        caseId: caseId,
      ).doc(docId).set(newVisit.toFirestore(), SetOptions(merge: true));

      final cleanPatientId = _normalizePatientId(patientId);
      await _firestore
          .collection(FirebaseConfig.patientsCollection)
          .doc(cleanPatientId)
          .collection('cases')
          .doc(caseId)
          .update({
        'visitCount': nextNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return newVisit;
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseClinicalVisitRepository] FirebaseException: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not create next visit in Firestore.',
        originalError: e,
      );
    }
  }

  @override
  Future<ClinicalVisit> createVisit(ClinicalVisit visit) async {
    final visits = await getVisitsForCase(
      patientId: visit.patientId,
      caseId: visit.caseId,
    );

    int computedNumber = visit.visitNumber;
    if (visits.any((v) => v.visitNumber == computedNumber)) {
      final maxNum = visits
          .map((v) => v.visitNumber)
          .reduce((curr, next) => curr > next ? curr : next);
      computedNumber = maxNum + 1;
    }

    final docId = visit.visitId.isNotEmpty
        ? visit.visitId
        : 'VIS-${visit.caseId}-$computedNumber-${DateTime.now().millisecondsSinceEpoch}';

    final created = visit.copyWith(
      visitId: docId,
      visitNumber: computedNumber,
      startedAt: DateTime.now(),
      status: ClinicalVisitStatus.active,
    );

    try {
      await _getVisitsCollection(
        patientId: created.patientId,
        caseId: created.caseId,
      ).doc(docId).set(created.toFirestore(), SetOptions(merge: true));

      // Also update case visitCount
      final cleanPatientId = _normalizePatientId(visit.patientId);
      await _firestore
          .collection(FirebaseConfig.patientsCollection)
          .doc(cleanPatientId)
          .collection('cases')
          .doc(visit.caseId)
          .update({
        'visitCount': visits.length + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return created;
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseClinicalVisitRepository] FirebaseException: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not create visit record in Firestore.',
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateVisit(ClinicalVisit visit) async {
    try {
      await _getVisitsCollection(
        patientId: visit.patientId,
        caseId: visit.caseId,
      ).doc(visit.visitId).set(visit.toFirestore(), SetOptions(merge: true));
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseClinicalVisitRepository] FirebaseException: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Could not update visit in Firestore.',
        originalError: e,
      );
    }
  }

  @override
  Future<ClinicalVisit> completeVisit({
    required String patientId,
    required String caseId,
    required String visitId,
    required String doctorId,
  }) async {
    final visit = await getVisitById(
      patientId: patientId,
      caseId: caseId,
      visitId: visitId,
    );

    if (visit == null) {
      throw BackendException(
        code: BackendException.notFound,
        message: 'Consultation visit $visitId not found.',
      );
    }

    if (!visit.isActive) {
      throw BackendException(
        code: BackendException.invalidData,
        message: 'Only active visits can be completed.',
      );
    }

    final completedVisit = visit.copyWith(
      status: ClinicalVisitStatus.completed,
      completedAt: DateTime.now(),
      completedByDoctorId: doctorId,
    );

    try {
      final docRef = _getVisitsCollection(
        patientId: patientId,
        caseId: caseId,
      ).doc(visitId);

      await docRef.set({
        ...completedVisit.toFirestore(),
        'completedAt': FieldValue.serverTimestamp(),
        'completedByDoctorId': doctorId,
      }, SetOptions(merge: true));

      // Case remains OPEN, update timestamp
      final cleanPatientId = _normalizePatientId(patientId);
      await _firestore
          .collection(FirebaseConfig.patientsCollection)
          .doc(cleanPatientId)
          .collection('cases')
          .doc(caseId)
          .update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return completedVisit;
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseClinicalVisitRepository] FirebaseException on complete: ${e.code}');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.unavailable,
        message: 'Failed to complete visit in Firestore.',
        originalError: e,
      );
    }
  }
}

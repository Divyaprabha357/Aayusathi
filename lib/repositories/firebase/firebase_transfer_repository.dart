import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/backend/backend_exception.dart';
import '../../core/firebase/firebase_config.dart';
import '../../doctor/models/doctor_assignment_result.dart';
import '../../doctor/models/patient_transfer_request.dart';
import '../transfer_repository.dart';

/// Cloud Firestore implementation of [TransferRepository].
///
/// Hierarchy & Storage:
/// - Root collection: `transfers/{transferId}` for fast department queue queries.
/// - Hierarchical subcollection: `patients/{patientId}/cases/{caseId}/visits/{visitId}/transfers/{transferId}`
/// - Atomic first-doctor-wins transactions for claiming transfers.
class FirebaseTransferRepository implements TransferRepository {
  final FirebaseFirestore? _customFirestore;

  FirebaseTransferRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _transfersCollection =>
      _firestore.collection('transfers');

  CollectionReference<Map<String, dynamic>> _getSubcollection({
    required String patientId,
    required String caseId,
    required String visitId,
  }) {
    final cleanPatientId =
        patientId.replaceAll(RegExp(r'\s+'), '').toUpperCase().trim();
    return _firestore
        .collection(FirebaseConfig.patientsCollection)
        .doc(cleanPatientId)
        .collection('cases')
        .doc(caseId)
        .collection('visits')
        .doc(visitId)
        .collection('transfers');
  }

  @override
  Future<PatientTransferRequest> createTransfer(
      PatientTransferRequest transfer) async {
    try {
      final docRef = _transfersCollection.doc(transfer.transferId);
      final subRef = _getSubcollection(
        patientId: transfer.patientId,
        caseId: transfer.caseId,
        visitId: transfer.sourceVisitId,
      ).doc(transfer.transferId);

      final data = transfer.toFirestore();
      final batch = _firestore.batch();
      batch.set(docRef, data);
      batch.set(subRef, data);

      await batch.commit();
      debugPrint('[FirebaseTransferRepository] Created transfer: ${transfer.transferId}');
      return transfer;
    } catch (e) {
      debugPrint('[FirebaseTransferRepository] createTransfer error: $e');
      throw BackendException(
        code: BackendException.persistenceFailed,
        message: 'Failed to create transfer request: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<PatientTransferRequest?> getTransferById(String transferId) async {
    try {
      final doc = await _transfersCollection.doc(transferId).get();
      if (!doc.exists || doc.data() == null) return null;
      return PatientTransferRequest.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('[FirebaseTransferRepository] getTransferById error: $e');
      throw BackendException(
        code: BackendException.persistenceFailed,
        message: 'Failed to fetch transfer request: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<List<PatientTransferRequest>> getPendingTransfersForDepartment(
      String department) async {
    try {
      final snapshot = await _transfersCollection
          .where('destinationDepartment', isEqualTo: department)
          .where('status', isEqualTo: TransferStatus.pending.name)
          .get();

      final list = snapshot.docs
          .map((doc) => PatientTransferRequest.fromFirestore(doc.data(), doc.id))
          .toList();

      list.sort((a, b) => a.requestedAt.compareTo(b.requestedAt));
      return list;
    } catch (e) {
      debugPrint('[FirebaseTransferRepository] getPendingTransfersForDepartment error: $e');
      throw BackendException(
        code: BackendException.persistenceFailed,
        message: 'Failed to fetch department transfers: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<DoctorAssignmentResult> acceptTransfer({
    required String transferId,
    required String doctorId,
    required String doctorName,
    required String doctorDepartment,
  }) async {
    try {
      final rootDocRef = _transfersCollection.doc(transferId);

      return await _firestore.runTransaction<DoctorAssignmentResult>((transaction) async {
        final snapshot = await transaction.get(rootDocRef);

        if (!snapshot.exists || snapshot.data() == null) {
          return DoctorAssignmentResult.invalidRequest(
            requestId: transferId,
            message: 'Transfer request not found.',
          );
        }

        final data = snapshot.data()!;
        final currentStatus = data['status'] as String? ?? '';
        final currentDestDoctor = data['destinationDoctorId'] as String?;
        final destDept = data['destinationDepartment'] as String? ?? '';
        final queueNumber = data['queueNumber'] as String? ?? 'TRF';

        // 1. Department eligibility check
        if (destDept.toLowerCase() != doctorDepartment.toLowerCase()) {
          return DoctorAssignmentResult.ineligible(
            requestId: transferId,
            message: 'Doctor department does not match transfer destination department.',
          );
        }

        // 2. Race condition check: already claimed by another doctor
        if (currentStatus.toLowerCase() != TransferStatus.pending.name ||
            (currentDestDoctor != null && currentDestDoctor.isNotEmpty)) {
          return DoctorAssignmentResult.alreadyAssigned(
            requestId: transferId,
            queueNumber: queueNumber,
            message: 'Patient transfer has already been claimed by another doctor.',
          );
        }

        // 3. Atomically claim transfer
        final updates = {
          'status': TransferStatus.accepted.name,
          'destinationDoctorId': doctorId,
          'destinationDoctorName': doctorName,
          'acceptedAt': FieldValue.serverTimestamp(),
        };

        transaction.update(rootDocRef, updates);

        final patientId = data['patientId'] as String? ?? '';
        final caseId = data['caseId'] as String? ?? '';
        final sourceVisitId = data['sourceVisitId'] as String? ?? '';

        if (patientId.isNotEmpty && caseId.isNotEmpty && sourceVisitId.isNotEmpty) {
          final subDocRef = _getSubcollection(
            patientId: patientId,
            caseId: caseId,
            visitId: sourceVisitId,
          ).doc(transferId);
          transaction.update(subDocRef, updates);
        }

        return DoctorAssignmentResult.success(
          requestId: transferId,
          appointmentId: transferId,
          queueNumber: queueNumber,
          assignedDoctorId: doctorId,
        );
      });
    } catch (e) {
      debugPrint('[FirebaseTransferRepository] acceptTransfer error: $e');
      return DoctorAssignmentResult.error(
        requestId: transferId,
        message: 'Failed to accept transfer: $e',
      );
    }
  }

  @override
  Future<bool> cancelTransfer({
    required String transferId,
    required String doctorId,
  }) async {
    try {
      final docRef = _transfersCollection.doc(transferId);
      final snapshot = await docRef.get();

      if (!snapshot.exists || snapshot.data() == null) return false;
      final data = snapshot.data()!;
      final sourceDoctorId = data['sourceDoctorId'] as String? ?? '';
      final currentStatus = data['status'] as String? ?? '';

      // Only authorized source doctor can cancel while pending
      if (sourceDoctorId != doctorId ||
          currentStatus.toLowerCase() != TransferStatus.pending.name) {
        return false;
      }

      final updates = {
        'status': TransferStatus.cancelled.name,
        'cancelledAt': FieldValue.serverTimestamp(),
      };

      final batch = _firestore.batch();
      batch.update(docRef, updates);

      final patientId = data['patientId'] as String? ?? '';
      final caseId = data['caseId'] as String? ?? '';
      final sourceVisitId = data['sourceVisitId'] as String? ?? '';

      if (patientId.isNotEmpty && caseId.isNotEmpty && sourceVisitId.isNotEmpty) {
        final subDocRef = _getSubcollection(
          patientId: patientId,
          caseId: caseId,
          visitId: sourceVisitId,
        ).doc(transferId);
        batch.update(subDocRef, updates);
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('[FirebaseTransferRepository] cancelTransfer error: $e');
      return false;
    }
  }

  @override
  Future<List<PatientTransferRequest>> getTransfersForPatient(
      String patientId) async {
    try {
      final snapshot = await _transfersCollection
          .where('patientId', isEqualTo: patientId)
          .get();

      final list = snapshot.docs
          .map((doc) => PatientTransferRequest.fromFirestore(doc.data(), doc.id))
          .toList();

      list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return list;
    } catch (e) {
      debugPrint('[FirebaseTransferRepository] getTransfersForPatient error: $e');
      throw BackendException(
        code: BackendException.persistenceFailed,
        message: 'Failed to fetch patient transfers: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<List<PatientTransferRequest>> getTransfersForCase({
    required String patientId,
    required String caseId,
  }) async {
    try {
      final snapshot = await _transfersCollection
          .where('patientId', isEqualTo: patientId)
          .where('caseId', isEqualTo: caseId)
          .get();

      final list = snapshot.docs
          .map((doc) => PatientTransferRequest.fromFirestore(doc.data(), doc.id))
          .toList();

      list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return list;
    } catch (e) {
      debugPrint('[FirebaseTransferRepository] getTransfersForCase error: $e');
      throw BackendException(
        code: BackendException.persistenceFailed,
        message: 'Failed to fetch case transfers: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<List<PatientTransferRequest>> getTransfersForVisit({
    required String patientId,
    required String caseId,
    required String visitId,
  }) async {
    try {
      final snapshot = await _getSubcollection(
        patientId: patientId,
        caseId: caseId,
        visitId: visitId,
      ).get();

      return snapshot.docs
          .map((doc) => PatientTransferRequest.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('[FirebaseTransferRepository] getTransfersForVisit error: $e');
      throw BackendException(
        code: BackendException.persistenceFailed,
        message: 'Failed to fetch visit transfers: $e',
        originalError: e,
      );
    }
  }
}

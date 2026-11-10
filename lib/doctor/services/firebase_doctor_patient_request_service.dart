import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../core/backend/backend_mode.dart';
import '../../core/firebase/firebase_config.dart';
import '../../models/appointment_request.dart';
import '../../models/audit_log.dart';
import '../../models/vital_reading.dart';
import '../../repositories/audit_repository.dart';
import '../models/clinical_case.dart';
import '../models/doctor_assignment_result.dart';
import '../models/doctor_patient_request.dart';
import 'doctor_patient_request_service.dart';
import 'doctor_presence_service.dart';

/// Cloud Firestore implementation of [DoctorPatientRequestService].
///
/// Implements real-time consultation queue queries, FIFO ordering, domain filtering,
/// and atomic First-Doctor-Wins request assignment via Firestore transactions.
class FirebaseDoctorPatientRequestService implements DoctorPatientRequestService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AuditRepository? _customAuditRepository;

  FirebaseDoctorPatientRequestService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    AuditRepository? auditRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _customAuditRepository = auditRepository;

  AuditRepository get _auditRepo =>
      _customAuditRepository ?? BackendProvider.instance.auditRepository;

  CollectionReference<Map<String, dynamic>> get _appointmentsCollection =>
      _firestore.collection(FirebaseConfig.appointmentsCollection);

  CollectionReference<Map<String, dynamic>> get _vitalsCollection =>
      _firestore.collection(FirebaseConfig.vitalsCollection);

  bool _isEligibleRequest({
    required AppointmentRequest appointment,
    required Map<String, dynamic> data,
    String? domain,
  }) {
    // 1. Status verification: must be strictly waiting or pending
    final status = (data['status'] ?? appointment.status.name).toString().toLowerCase();
    if (status != 'waiting' && status != 'pending') {
      return false;
    }

    // 3. Unassigned verification: assignedDoctorId must be strictly null or empty
    final assignedDoc = data['assignedDoctorId'] ?? appointment.assignedDoctorId;
    if (assignedDoc != null && assignedDoc.toString().trim().isNotEmpty) {
      return false;
    }

    // 4. Domain eligibility check with normalization
    if (domain != null && domain.trim().isNotEmpty) {
      final apptDomain = ClinicalCase.normalizeDepartment(appointment.domainId);
      final doctorDomain = ClinicalCase.normalizeDepartment(domain);
      if (apptDomain != doctorDomain &&
          apptDomain.toLowerCase() != doctorDomain.toLowerCase() &&
          apptDomain != 'Department not available') {
        return false;
      }
    }

    return true;
  }

  DoctorPatientRequest _mapToDoctorPatientRequest(
    AppointmentRequest appointment,
    Map<String, dynamic> data,
  ) {
    VitalReading? vitals = appointment.vitals;
    if (vitals == null && data['vitals'] != null && data['vitals'] is Map) {
      try {
        vitals = VitalReading.fromMap(data['vitals'] as Map<dynamic, dynamic>);
      } catch (_) {}
    }

    final requestType = appointment.previousDoctorId != null &&
            appointment.previousDoctorId!.isNotEmpty
        ? PatientRequestType.previousDoctor
        : PatientRequestType.newVisit;

    return DoctorPatientRequest(
      requestId: appointment.requestId,
      appointmentId: appointment.requestId,
      patientId: appointment.patientId,
      queueNumber: appointment.queueNumber,
      age: (data['patientAge'] as num?)?.toInt() ?? 40,
      gender: (data['patientGender'] as String?) ?? 'Not specified',
      domain: ClinicalCase.normalizeDepartment(appointment.domainId),
      requestType: requestType,
      previousDoctorId: appointment.previousDoctorId,
      assignedDoctorId: appointment.assignedDoctorId,
      vitals: vitals,
      requestedAt: appointment.createdAt,
      status: PatientRequestStatus.waiting,
    );
  }

  @override
  Stream<List<DoctorPatientRequest>> watchPendingRequests({String? domain}) {
    return _appointmentsCollection
        .where('status', whereIn: ['waiting', 'pending'])
        .snapshots()
        .map((snapshot) {
      final List<DoctorPatientRequest> requests = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final appointment = AppointmentRequest.fromFirestore(data, doc.id);

        if (!_isEligibleRequest(appointment: appointment, data: data, domain: domain)) {
          continue;
        }

        requests.add(_mapToDoctorPatientRequest(appointment, data));
      }

      // FIFO Queue Ordering: oldest requestedAt first
      requests.sort((a, b) => a.requestedAt.compareTo(b.requestedAt));
      return requests;
    });
  }

  @override
  Future<List<DoctorPatientRequest>> getPendingRequests({String? domain}) async {
    try {
      final snapshot = await _appointmentsCollection
          .where('status', whereIn: ['waiting', 'pending'])
          .get();

      final List<DoctorPatientRequest> requests = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final appointment = AppointmentRequest.fromFirestore(data, doc.id);

        if (!_isEligibleRequest(appointment: appointment, data: data, domain: domain)) {
          continue;
        }

        // Fetch vitals fallback from collection if not embedded
        VitalReading? vitals = appointment.vitals;
        if (vitals == null && data['vitals'] != null && data['vitals'] is Map) {
          try {
            vitals = VitalReading.fromMap(data['vitals'] as Map<dynamic, dynamic>);
          } catch (_) {}
        }
        if (vitals == null) {
          try {
            final vitalSnap = await _vitalsCollection
                .where('appointmentId', isEqualTo: appointment.requestId)
                .limit(1)
                .get();
            if (vitalSnap.docs.isNotEmpty) {
              vitals = VitalReading.fromFirestore(
                vitalSnap.docs.first.data(),
                vitalSnap.docs.first.id,
              );
            }
          } catch (_) {}
        }

        final req = _mapToDoctorPatientRequest(appointment, data).copyWith(
          vitals: vitals,
        );
        requests.add(req);
      }
      // FIFO Queue Ordering: oldest requestedAt first
      requests.sort((a, b) => a.requestedAt.compareTo(b.requestedAt));
      return requests;
    } catch (e) {
      debugPrint('[FirebaseDoctorPatientRequestService] Error loading pending requests: $e');
      throw Exception('Unable to load incoming patient requests from clinical server.');
    }
  }

  @override
  Future<int> getPendingRequestCount({String? domain}) async {
    final list = await getPendingRequests(domain: domain);
    return list.length;
  }

  @override
  Future<void> refreshRequests() async {
    return;
  }

  @override
  Future<DoctorAssignmentResult> acceptPatientRequest({
    required String requestId,
    required String doctorId,
    required String doctorDomain,
  }) async {
    // 1. Presence Pre-condition Check
    if (!DoctorPresenceService.instance.isAvailable) {
      return DoctorAssignmentResult.unavailable(
        requestId: requestId,
        message: 'Doctor is not available to accept patient requests.',
      );
    }

    // 2. Authentication Check
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return DoctorAssignmentResult.unauthorized(
        requestId: requestId,
        message: 'Authenticated doctor session required.',
      );
    }

    final apptRef = _appointmentsCollection.doc(requestId);

    try {
      final result = await _firestore.runTransaction<DoctorAssignmentResult>(
        (transaction) async {
          final snapshot = await transaction.get(apptRef);

          if (!snapshot.exists) {
            return DoctorAssignmentResult.invalidRequest(
              requestId: requestId,
              message: 'Appointment request $requestId not found.',
            );
          }

          final data = snapshot.data() ?? {};
          final currentStatus = data['status']?.toString().toLowerCase();
          final currentAssignedDoc = data['assignedDoctorId']?.toString();
          final queueNumber = data['queueNumber']?.toString() ?? '';
          final apptDomain = data['domainId']?.toString() ?? '';
          final previousDoc = data['previousDoctorId']?.toString();

          // 3. First-Doctor-Wins Check: Must be waiting and unassigned
          final isWaiting = currentStatus == 'waiting' || currentStatus == 'pending';
          final isAlreadyClaimed = currentAssignedDoc != null &&
              currentAssignedDoc.isNotEmpty &&
              currentAssignedDoc != doctorId;

          if (!isWaiting || isAlreadyClaimed) {
            return DoctorAssignmentResult.alreadyAssigned(
              requestId: requestId,
              queueNumber: queueNumber,
              message: 'Patient request has already been assigned to another doctor.',
            );
          }

          // 4. Domain Eligibility Check
          if (apptDomain.isNotEmpty &&
              apptDomain.toLowerCase() != doctorDomain.toLowerCase()) {
            return DoctorAssignmentResult.ineligible(
              requestId: requestId,
              message: 'Domain mismatch: Request is for $apptDomain.',
            );
          }

          // 5. Previous Doctor Restriction Check
          if (previousDoc != null &&
              previousDoc.isNotEmpty &&
              previousDoc != doctorId) {
            return DoctorAssignmentResult.ineligible(
              requestId: requestId,
              message: 'Request is reserved for previous doctor $previousDoc.',
            );
          }

          // 6. Atomic Transaction Update
          final now = DateTime.now();
          transaction.update(apptRef, {
            'status': AppointmentStatus.accepted.name,
            'assignedDoctorId': doctorId,
            'assignedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          return DoctorAssignmentResult.success(
            requestId: requestId,
            appointmentId: requestId,
            queueNumber: queueNumber,
            assignedDoctorId: doctorId,
            assignedAt: now,
            message: 'Patient accepted successfully.',
          );
        },
      );

      // 7. Post-Transaction Audit Logging (Strictly Zero Aadhaar, Zero Passwords, Zero OTP)
      if (result.isSuccess) {
        try {
          await _auditRepo.logEvent(
            AuditLog(
              auditId: 'AUD-ASSIGN-${DateTime.now().millisecondsSinceEpoch}',
              actorType: AuditActorType.doctor.value,
              actorId: doctorId,
              action: 'DOCTOR_REQUEST_ACCEPTED',
              entityType: 'APPOINTMENT',
              entityId: requestId,
              timestamp: DateTime.now(),
              metadata: {
                'queueNumber': result.queueNumber ?? '',
                'domain': doctorDomain,
                'assignedDoctorId': doctorId,
              },
            ),
          );
        } catch (auditErr) {
          debugPrint('[FirebaseDoctorPatientRequestService] Non-fatal audit log error: $auditErr');
        }
      }

      return result;
    } on FirebaseException catch (fe) {
      debugPrint('[FirebaseDoctorPatientRequestService] FirebaseException during assignment: ${fe.code}');
      if (fe.code == 'failed-precondition' || fe.code == 'aborted') {
        return DoctorAssignmentResult.conflict(
          requestId: requestId,
          message: 'Request was modified concurrently. Please retry.',
        );
      }
      return DoctorAssignmentResult.error(
        requestId: requestId,
        message: 'Server error: ${fe.message ?? fe.code}',
      );
    } catch (e) {
      debugPrint('[FirebaseDoctorPatientRequestService] Unexpected error during assignment: $e');
      return DoctorAssignmentResult.error(
        requestId: requestId,
        message: 'Unable to accept this patient request. Please try again.',
      );
    }
  }
}

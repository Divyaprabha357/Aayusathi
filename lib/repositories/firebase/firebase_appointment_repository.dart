import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/backend/backend_exception.dart';
import '../../core/backend/backend_mode.dart';
import '../../core/firebase/firebase_config.dart';
import '../../doctor/models/doctor_assignment_result.dart';
import '../../doctor/models/doctor_profile.dart';
import '../../models/appointment_request.dart';
import '../../models/audit_log.dart';
import '../appointment_repository.dart';
import '../audit_repository.dart';

/// Cloud Firestore implementation of [AppointmentRepository].
///
/// Features:
/// - Persists appointment requests to the `appointments` collection.
/// - Implements Firestore transaction-safe queue counter incrementation under `system/queueCounter`.
/// - Strictly validates that all generated tickets match `^A-[0-9]{5}$`.
/// - Supports real-time appointment stream subscription across Kiosk, Doctor, and Admin portals.
/// - Implements atomic duplicate-protected SLA escalation transitions.
/// - Implements atomic First-Doctor-Wins administrative doctor assignment with live doctor presence checks.
class FirebaseAppointmentRepository implements AppointmentRepository {
  final FirebaseFirestore? _customFirestore;
  final AuditRepository? _customAuditRepository;

  FirebaseAppointmentRepository({
    FirebaseFirestore? firestore,
    AuditRepository? auditRepository,
  })  : _customFirestore = firestore,
        _customAuditRepository = auditRepository;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;
  AuditRepository get _auditRepo =>
      _customAuditRepository ?? BackendProvider.instance.auditRepository;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirebaseConfig.appointmentsCollection);

  CollectionReference<Map<String, dynamic>> get _doctorsCollection =>
      _firestore.collection(FirebaseConfig.doctorsCollection);

  DocumentReference<Map<String, dynamic>> get _counterDoc =>
      _firestore.collection('system').doc('queueCounter');

  @override
  Future<String> allocateNextQueueNumber() async {
    try {
      final nextNumber = await _firestore.runTransaction<int>((transaction) async {
        final snapshot = await transaction.get(_counterDoc);
        int current = 0;
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          current = (data['currentNumber'] ?? data['lastQueueNumber'] as num?)?.toInt() ?? 0;
        }

        if (current >= 99999) {
          throw const BackendException(
            code: BackendException.queueCapacityReached,
            message: 'Queue capacity limit of 99,999 has been reached.',
          );
        }

        final next = current + 1;
        transaction.set(
          _counterDoc,
          {
            'currentNumber': next,
            'lastQueueNumber': next,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        return next;
      });

      final formatted = 'A-${nextNumber.toString().padLeft(5, '0')}';
      return formatted;
    } on BackendException {
      rethrow;
    } catch (e) {
      debugPrint('[FirebaseAppointmentRepository] Firestore counter transaction failed: $e');
      throw BackendException(
        code: BackendException.queueAllocationFailed,
        message: 'Failed to allocate queue number from cloud counter.',
        originalError: e,
      );
    }
  }

  @override
  Future<AppointmentRequest> saveAppointmentWithAtomicQueue(AppointmentRequest request) async {
    debugPrint('[AAYUSATHI] Starting atomic queue allocation & appointment save for: ${request.requestId}');

    try {
      final finalAppointment = await _firestore.runTransaction<AppointmentRequest>((transaction) async {
        final counterSnapshot = await transaction.get(_counterDoc);
        int current = 0;
        if (counterSnapshot.exists && counterSnapshot.data() != null) {
          final data = counterSnapshot.data()!;
          current = (data['currentNumber'] ?? data['lastQueueNumber'] as num?)?.toInt() ?? 0;
        }

        if (current >= 99999) {
          throw const BackendException(
            code: BackendException.queueCapacityReached,
            message: 'Queue capacity limit of 99,999 tickets has been reached.',
          );
        }

        final next = current + 1;
        final formattedQueue = 'A-${next.toString().padLeft(5, '0')}';

        // 1. Commit incremented counter
        transaction.set(
          _counterDoc,
          {
            'currentNumber': next,
            'lastQueueNumber': next,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        // 2. Commit appointment with allocated queue number in the SAME transaction
        final updatedRequest = request.copyWith(queueNumber: formattedQueue);
        final apptDocRef = _collection.doc(updatedRequest.requestId);
        final apptData = updatedRequest.toFirestore();
        transaction.set(
          apptDocRef,
          apptData,
          SetOptions(merge: true),
        );

        return updatedRequest;
      });

      return finalAppointment;
    } on BackendException {
      rethrow;
    } on FirebaseException catch (e, stackTrace) {
      debugPrint('[FirebaseAppointmentRepository] FirebaseException in saveAppointmentWithAtomicQueue:');
      debugPrint('  code: ${e.code}');
      debugPrint('  message: ${e.message}');
      debugPrint('  stackTrace: $stackTrace');
      throw BackendException(
        code: e.code == 'permission-denied'
            ? BackendException.permissionDenied
            : BackendException.queueAllocationFailed,
        message: 'Could not allocate queue number or save appointment in Firestore: ${e.message}',
        originalError: e,
      );
    } catch (e, stackTrace) {
      debugPrint('[FirebaseAppointmentRepository] Unexpected error in saveAppointmentWithAtomicQueue: $e\n$stackTrace');
      throw BackendException(
        code: BackendException.queueAllocationFailed,
        message: 'An unexpected error occurred during queue allocation: $e',
        originalError: e,
      );
    }
  }

  @override
  void resetQueueCounter() {
    _counterDoc.set({
      'currentNumber': 0,
      'lastQueueNumber': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).catchError((err) {
      debugPrint('[FirebaseAppointmentRepository] Error resetting counter doc: $err');
    });
  }

  @override
  Future<void> saveAppointment(AppointmentRequest appointment) async {
    if (!appointment.hasValidQueueFormat) {
      throw const BackendException(
        code: BackendException.invalidData,
        message: 'Invalid queue format. Queue number must strictly match ^A-[0-9]{5}\$.',
      );
    }

    try {
      await _collection.doc(appointment.requestId).set(
            appointment.toFirestore(),
            SetOptions(merge: true),
          );
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseAppointmentRepository] FirebaseException on saveAppointment: ${e.code}');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Could not save appointment to Firestore.',
        originalError: e,
      );
    } catch (e) {
      debugPrint('[FirebaseAppointmentRepository] Error saving appointment: $e');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Failed to persist appointment request.',
        originalError: e,
      );
    }
  }

  @override
  Future<AppointmentRequest?> getAppointmentById(String requestId) async {
    try {
      final doc = await _collection.doc(requestId).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return AppointmentRequest.fromFirestore(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseAppointmentRepository] FirebaseException on getAppointmentById: ${e.code}');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Could not retrieve appointment from Firestore.',
        originalError: e,
      );
    }
  }

  @override
  Future<List<AppointmentRequest>> getAppointmentsForPatient(String patientId) async {
    final cleanId = patientId.replaceAll(RegExp(r'\s+'), '').toUpperCase().trim();
    if (cleanId.isEmpty) {
      return [];
    }
    final normalizedId = cleanId.startsWith('AAYU-') ? cleanId : 'AAYU-$cleanId';

    try {
      QuerySnapshot<Map<String, dynamic>> query;
      try {
        query = await _collection
            .where('patientId', isEqualTo: normalizedId)
            .orderBy('createdAt', descending: true)
            .get();
      } catch (orderError) {
        debugPrint('[FirebaseAppointmentRepository] Composite index fallback for getAppointmentsForPatient: $orderError');
        query = await _collection
            .where('patientId', isEqualTo: normalizedId)
            .get();
      }

      final List<AppointmentRequest> results = query.docs
          .map((doc) => AppointmentRequest.fromFirestore(doc.data(), doc.id))
          .toList();

      // If normalized ID returned no appointments and cleanId differs, check cleanId as fallback
      if (results.isEmpty && cleanId != normalizedId) {
        try {
          final fallbackQuery = await _collection
              .where('patientId', isEqualTo: cleanId)
              .get();
          results.addAll(fallbackQuery.docs
              .map((doc) => AppointmentRequest.fromFirestore(doc.data(), doc.id)));
        } catch (_) {}
      }

      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return results;
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseAppointmentRepository] FirebaseException on query: ${e.code} - ${e.message}');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Could not query patient appointments from Firestore.',
        originalError: e,
      );
    }
  }

  @override
  Future<List<AppointmentRequest>> getAllAppointments() async {
    try {
      final query = await _collection.orderBy('createdAt', descending: true).get();
      return query.docs
          .map((doc) => AppointmentRequest.fromFirestore(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseAppointmentRepository] FirebaseException on getAllAppointments: ${e.code}');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Could not retrieve appointments from Firestore.',
        originalError: e,
      );
    }
  }

  @override
  Stream<List<AppointmentRequest>> watchAllAppointments() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppointmentRequest.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<void> updateAppointmentStatus(String requestId, AppointmentStatus status) async {
    try {
      await _collection.doc(requestId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseAppointmentRepository] FirebaseException on update status: ${e.code}');
      throw BackendException(
        code: BackendException.unavailable,
        message: 'Could not update appointment status.',
        originalError: e,
      );
    }
  }

  @override
  Future<bool> markAppointmentEscalated(String requestId) async {
    final apptRef = _collection.doc(requestId);

    try {
      final didEscalate = await _firestore.runTransaction<bool>((transaction) async {
        final snapshot = await transaction.get(apptRef);
        if (!snapshot.exists || snapshot.data() == null) {
          return false;
        }

        final data = snapshot.data()!;
        final status = data['status']?.toString().toLowerCase();
        final assignedDoctorId = data['assignedDoctorId']?.toString();
        final currentEscalation = data['escalationStatus']?.toString().toLowerCase();

        // Must still be waiting/pending, unassigned, and not already escalated/resolved
        final isWaiting = status == 'waiting' || status == 'pending';
        final isUnassigned = assignedDoctorId == null || assignedDoctorId.isEmpty;
        final isNotEscalated = currentEscalation == null ||
            currentEscalation.isEmpty ||
            currentEscalation == 'none';

        if (!isWaiting || !isUnassigned || !isNotEscalated) {
          return false;
        }

        transaction.update(apptRef, {
          'escalationStatus': AppointmentEscalationStatus.escalated.name,
          'escalatedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });

      if (didEscalate) {
        // Post-transaction Audit Logging (Strictly Zero Aadhaar, Zero Passwords, Zero OTP)
        try {
          final now = DateTime.now();
          await _auditRepo.logEvent(
            AuditLog(
              auditId: 'AUD-ESC-${now.millisecondsSinceEpoch}',
              actorType: AuditActorType.admin.value,
              actorId: 'system',
              action: 'APPOINTMENT_ESCALATED',
              entityType: 'APPOINTMENT',
              entityId: requestId,
              timestamp: now,
              metadata: {
                'appointmentId': requestId,
                'escalationThreshold': '20_MINUTES',
                'status': AppointmentEscalationStatus.escalated.name,
              },
            ),
          );
        } catch (auditErr) {
          debugPrint('[FirebaseAppointmentRepository] Non-fatal audit log error: $auditErr');
        }
      }

      return didEscalate;
    } catch (e) {
      debugPrint('[FirebaseAppointmentRepository] Error marking appointment escalated: $e');
      return false;
    }
  }

  @override
  Future<DoctorAssignmentResult> adminAssignDoctor({
    required String requestId,
    required String doctorId,
    required String doctorDomain,
    required String adminId,
  }) async {
    final apptRef = _collection.doc(requestId);
    final docRef = _doctorsCollection.doc(doctorId);

    try {
      final result = await _firestore.runTransaction<DoctorAssignmentResult>((transaction) async {
        // 1. Read and verify Appointment
        final apptSnap = await transaction.get(apptRef);
        if (!apptSnap.exists || apptSnap.data() == null) {
          return DoctorAssignmentResult.invalidRequest(
            requestId: requestId,
            message: 'Appointment request $requestId not found.',
          );
        }

        final apptData = apptSnap.data()!;
        final currentStatus = apptData['status']?.toString().toLowerCase();
        final currentAssignedDoc = apptData['assignedDoctorId']?.toString();
        final queueNumber = apptData['queueNumber']?.toString() ?? '';
        final apptDomain = apptData['domainId']?.toString() ?? '';
        final previousDoc = apptData['previousDoctorId']?.toString();
        final prefMode = apptData['preferredDoctorMode']?.toString();

        final isWaiting = currentStatus == 'waiting' || currentStatus == 'pending';
        final isAlreadyClaimed = currentAssignedDoc != null && currentAssignedDoc.isNotEmpty;

        if (!isWaiting || isAlreadyClaimed) {
          return DoctorAssignmentResult.alreadyAssigned(
            requestId: requestId,
            queueNumber: queueNumber,
            message: 'Appointment request has already been assigned to another doctor.',
          );
        }

        // Previous Doctor check if explicitly locked
        if (previousDoc != null &&
            previousDoc.isNotEmpty &&
            prefMode == PreferredDoctorMode.sameDoctor.name &&
            previousDoc != doctorId) {
          return DoctorAssignmentResult.ineligible(
            requestId: requestId,
            message: 'This appointment is specifically requested for previous doctor $previousDoc.',
          );
        }

        // 2. Read and verify Doctor Profile & Live Presence
        final docSnap = await transaction.get(docRef);
        if (!docSnap.exists || docSnap.data() == null) {
          return DoctorAssignmentResult.invalidRequest(
            requestId: requestId,
            message: 'Doctor $doctorId was not found in registry.',
          );
        }

        final docData = docSnap.data()!;
        final isActive = (docData['isActive'] as bool?) ?? false;
        final availability = docData['availabilityStatus']?.toString().toLowerCase() ?? 'offline';
        final department = docData['department']?.toString() ?? '';

        if (!isActive) {
          return DoctorAssignmentResult.ineligible(
            requestId: requestId,
            message: 'Doctor account is deactivated.',
          );
        }

        if (availability != 'available' && availability != 'online') {
          return DoctorAssignmentResult.unavailable(
            requestId: requestId,
            message: 'Doctor is currently $availability and cannot be assigned.',
          );
        }

        if (apptDomain.isNotEmpty &&
            department.isNotEmpty &&
            department.toLowerCase() != apptDomain.toLowerCase()) {
          return DoctorAssignmentResult.ineligible(
            requestId: requestId,
            message: 'Domain mismatch: Doctor is in $department, request is for $apptDomain.',
          );
        }

        // 3. Atomically Commit Appointment and Doctor State
        final now = DateTime.now();

        transaction.update(apptRef, {
          'status': AppointmentStatus.accepted.name,
          'assignedDoctorId': doctorId,
          'assignedAt': FieldValue.serverTimestamp(),
          'escalationStatus': AppointmentEscalationStatus.resolved.name,
          'resolvedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.update(docRef, {
          'availabilityStatus': DoctorAvailabilityStatus.inConsultation.name,
          'isAvailable': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return DoctorAssignmentResult.success(
          requestId: requestId,
          appointmentId: requestId,
          queueNumber: queueNumber,
          assignedDoctorId: doctorId,
          assignedAt: now,
          message: 'Appointment successfully assigned to Dr. ${docData['name'] ?? doctorId}.',
        );
      });

      // 4. Post-Transaction Audit Logging (Strictly Zero Credentials/Tokens)
      if (result.isSuccess) {
        try {
          final now = DateTime.now();
          await _auditRepo.logEvent(
            AuditLog(
              auditId: 'AUD-ADMIN-ASSIGN-${now.millisecondsSinceEpoch}',
              actorType: AuditActorType.admin.value,
              actorId: adminId,
              action: 'ADMIN_APPOINTMENT_ASSIGNED',
              entityType: 'APPOINTMENT',
              entityId: requestId,
              timestamp: now,
              metadata: {
                'appointmentId': requestId,
                'queueNumber': result.queueNumber ?? '',
                'assignedDoctorId': doctorId,
                'domain': doctorDomain,
                'escalationResolved': true,
              },
            ),
          );

          await _auditRepo.logEvent(
            AuditLog(
              auditId: 'AUD-RESOLVE-${now.millisecondsSinceEpoch}',
              actorType: AuditActorType.admin.value,
              actorId: adminId,
              action: 'APPOINTMENT_ESCALATION_RESOLVED',
              entityType: 'APPOINTMENT',
              entityId: requestId,
              timestamp: now,
              metadata: {
                'appointmentId': requestId,
                'queueNumber': result.queueNumber ?? '',
                'assignedDoctorId': doctorId,
              },
            ),
          );
        } catch (auditErr) {
          debugPrint('[FirebaseAppointmentRepository] Non-fatal audit log error: $auditErr');
        }
      } else {
        try {
          final now = DateTime.now();
          await _auditRepo.logEvent(
            AuditLog(
              auditId: 'AUD-ADMIN-FAIL-${now.millisecondsSinceEpoch}',
              actorType: AuditActorType.admin.value,
              actorId: adminId,
              action: 'ADMIN_APPOINTMENT_ASSIGNMENT_FAILED',
              entityType: 'APPOINTMENT',
              entityId: requestId,
              timestamp: now,
              metadata: {
                'appointmentId': requestId,
                'targetDoctorId': doctorId,
                'reason': result.message ?? 'Unknown failure',
              },
            ),
          );
        } catch (_) {}
      }

      return result;
    } on FirebaseException catch (fe) {
      debugPrint('[FirebaseAppointmentRepository] FirebaseException during admin assignment: ${fe.code}');
      return DoctorAssignmentResult.error(
        requestId: requestId,
        message: 'Server error: ${fe.message ?? fe.code}',
      );
    } catch (e) {
      debugPrint('[FirebaseAppointmentRepository] Unexpected error during admin assignment: $e');
      return DoctorAssignmentResult.error(
        requestId: requestId,
        message: 'Unable to assign doctor. $e',
      );
    }
  }
}

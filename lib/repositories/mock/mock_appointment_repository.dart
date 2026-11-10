import 'dart:async';
import '../../core/backend/backend_exception.dart';
import '../../core/backend/backend_mode.dart';
import '../../doctor/models/doctor_assignment_result.dart';
import '../../doctor/models/doctor_profile.dart';
import '../../models/appointment_request.dart';
import '../../models/audit_log.dart';
import '../appointment_repository.dart';

/// In-memory mock implementation of [AppointmentRepository] with deterministic
/// sequential queue ticket allocation strictly matching `^A-[0-9]{5}$`, real-time
/// broadcast stream notifications, duplicate-safe escalation transitions, and atomic
/// admin doctor assignment.
class MockAppointmentRepository implements AppointmentRepository {
  static final MockAppointmentRepository instance = MockAppointmentRepository._();
  MockAppointmentRepository._();
  factory MockAppointmentRepository() => instance;

  final Map<String, AppointmentRequest> _appointments = {};
  int _queueCounter = 1;

  final StreamController<List<AppointmentRequest>> _streamController =
      StreamController<List<AppointmentRequest>>.broadcast();

  void _notifyListeners() {
    final list = _appointments.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _streamController.add(list);
  }

  @override
  Future<String> allocateNextQueueNumber() async {
    if (_queueCounter > 99999) {
      throw const BackendException(
        code: BackendException.queueCapacityReached,
        message: 'Queue capacity limit of 99,999 has been reached.',
      );
    }
    final ticket = 'A-${_queueCounter.toString().padLeft(5, '0')}';
    _queueCounter++;
    return ticket;
  }

  @override
  Future<AppointmentRequest> saveAppointmentWithAtomicQueue(AppointmentRequest request) async {
    if (_queueCounter > 99999) {
      throw const BackendException(
        code: BackendException.queueCapacityReached,
        message: 'Queue capacity limit of 99,999 tickets has been reached.',
      );
    }
    final ticket = 'A-${_queueCounter.toString().padLeft(5, '0')}';
    _queueCounter++;
    final updated = request.copyWith(queueNumber: ticket);
    _appointments[updated.requestId] = updated;
    _notifyListeners();
    return updated;
  }

  @override
  void resetQueueCounter() {
    _queueCounter = 1;
  }

  /// Direct queue counter control for testing capacity bounds
  void setQueueCounterForTesting(int value) {
    _queueCounter = value;
  }

  @override
  Future<void> saveAppointment(AppointmentRequest appointment) async {
    _appointments[appointment.requestId] = appointment;
    _notifyListeners();
  }

  @override
  Future<AppointmentRequest?> getAppointmentById(String requestId) async {
    return _appointments[requestId];
  }

  @override
  Future<List<AppointmentRequest>> getAppointmentsForPatient(String patientId) async {
    return _appointments.values
        .where((a) => a.patientId.toUpperCase() == patientId.toUpperCase())
        .toList();
  }

  List<AppointmentRequest> getAllAppointmentsSync() {
    final list = _appointments.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<List<AppointmentRequest>> getAllAppointments() async {
    return getAllAppointmentsSync();
  }

  @override
  Stream<List<AppointmentRequest>> watchAllAppointments() {
    return Stream.multi((controller) {
      controller.add(getAllAppointmentsSync());
      final subscription = _streamController.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = () {
        subscription.cancel();
      };
    });
  }

  @override
  Future<void> updateAppointmentStatus(String requestId, AppointmentStatus status) async {
    final existing = _appointments[requestId];
    if (existing != null) {
      _appointments[requestId] = existing.copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
      _notifyListeners();
    }
  }

  @override
  Future<bool> markAppointmentEscalated(String requestId) async {
    final existing = _appointments[requestId];
    if (existing == null) return false;

    // Check conditions: waiting/pending, unassigned, not already escalated/resolved
    final isWaiting = existing.status == AppointmentStatus.waiting ||
        existing.status == AppointmentStatus.pending;
    final isUnassigned = existing.assignedDoctorId == null ||
        existing.assignedDoctorId!.isEmpty;
    final isNotEscalated = existing.escalationStatus == AppointmentEscalationStatus.none;

    if (!isWaiting || !isUnassigned || !isNotEscalated) {
      return false;
    }

    final now = DateTime.now();
    _appointments[requestId] = existing.copyWith(
      escalationStatus: AppointmentEscalationStatus.escalated,
      escalatedAt: existing.escalatedAt ?? now,
      updatedAt: now,
    );
    _notifyListeners();

    // Audit Logging
    try {
      await BackendProvider.instance.auditRepository.logEvent(
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
    } catch (_) {}

    return true;
  }

  @override
  Future<DoctorAssignmentResult> adminAssignDoctor({
    required String requestId,
    required String doctorId,
    required String doctorDomain,
    required String adminId,
  }) async {
    final appt = _appointments[requestId];
    if (appt == null) {
      return DoctorAssignmentResult.invalidRequest(
        requestId: requestId,
        message: 'Appointment request $requestId not found.',
      );
    }

    final isWaiting = appt.status == AppointmentStatus.waiting ||
        appt.status == AppointmentStatus.pending;
    final isAlreadyAssigned = appt.assignedDoctorId != null &&
        appt.assignedDoctorId!.isNotEmpty;

    if (!isWaiting || isAlreadyAssigned) {
      return DoctorAssignmentResult.alreadyAssigned(
        requestId: requestId,
        queueNumber: appt.queueNumber,
        message: 'Appointment request has already been assigned to another doctor.',
      );
    }

    // Previous doctor constraint check
    if (appt.previousDoctorId != null &&
        appt.previousDoctorId!.isNotEmpty &&
        appt.preferredDoctorMode == PreferredDoctorMode.sameDoctor &&
        appt.previousDoctorId != doctorId) {
      return DoctorAssignmentResult.ineligible(
        requestId: requestId,
        message: 'This appointment is specifically requested for previous doctor ${appt.previousDoctorId}.',
      );
    }

    // Fetch Doctor Profile
    DoctorProfile? doctor;
    try {
      doctor = await BackendProvider.instance.doctorRepository.getDoctorProfileById(doctorId);
    } catch (_) {}

    if (doctor == null) {
      return DoctorAssignmentResult.invalidRequest(
        requestId: requestId,
        message: 'Doctor $doctorId was not found in registry.',
      );
    }

    if (!doctor.isActive) {
      return DoctorAssignmentResult.ineligible(
        requestId: requestId,
        message: 'Doctor account is deactivated.',
      );
    }

    if (doctor.availabilityStatus != DoctorAvailabilityStatus.available &&
        doctor.availabilityStatus != DoctorAvailabilityStatus.online) {
      return DoctorAssignmentResult.unavailable(
        requestId: requestId,
        message: 'Doctor is currently ${doctor.availabilityStatus.name} and cannot be assigned.',
      );
    }

    if (appt.domainId.isNotEmpty &&
        doctor.department.isNotEmpty &&
        doctor.department.toLowerCase() != appt.domainId.toLowerCase()) {
      return DoctorAssignmentResult.ineligible(
        requestId: requestId,
        message: 'Domain mismatch: Doctor is in ${doctor.department}, request is for ${appt.domainId}.',
      );
    }

    final now = DateTime.now();

    // 1. Commit Appointment
    _appointments[requestId] = appt.copyWith(
      status: AppointmentStatus.accepted,
      assignedDoctorId: doctorId,
      assignedAt: now,
      escalationStatus: AppointmentEscalationStatus.resolved,
      resolvedAt: now,
      updatedAt: now,
    );

    // 2. Commit Doctor Availability
    await BackendProvider.instance.doctorRepository.setDoctorAvailabilityStatus(
      doctorId: doctorId,
      availabilityStatus: DoctorAvailabilityStatus.inConsultation,
    );

    _notifyListeners();

    // 3. Log Audit Events
    try {
      await BackendProvider.instance.auditRepository.logEvent(
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
            'queueNumber': appt.queueNumber,
            'assignedDoctorId': doctorId,
            'domain': doctorDomain,
            'escalationResolved': true,
          },
        ),
      );

      await BackendProvider.instance.auditRepository.logEvent(
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
            'queueNumber': appt.queueNumber,
            'assignedDoctorId': doctorId,
          },
        ),
      );
    } catch (_) {}

    return DoctorAssignmentResult.success(
      requestId: requestId,
      appointmentId: requestId,
      queueNumber: appt.queueNumber,
      assignedDoctorId: doctorId,
      assignedAt: now,
      message: 'Appointment successfully assigned to Dr. ${doctor.name}.',
    );
  }

  /// Populate mock appointments directly for test fixtures
  void seedAppointments(List<AppointmentRequest> appointments) {
    _appointments.clear();
    for (final a in appointments) {
      _appointments[a.requestId] = a;
    }
    _notifyListeners();
  }

  /// Exposes current count for testing
  int get count => _appointments.length;

  /// Clear all appointments (for testing)
  void clear() {
    _appointments.clear();
    resetQueueCounter();
    _notifyListeners();
  }
}

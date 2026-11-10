import 'dart:async';
import '../../core/backend/backend_mode.dart';
import '../../models/appointment_request.dart';
import '../../models/audit_log.dart';
import '../../models/vital_reading.dart';
import '../models/doctor_assignment_result.dart';
import '../models/doctor_patient_request.dart';
import 'doctor_patient_request_service.dart';
import 'doctor_presence_service.dart';

/// In-memory development fixture implementation of [DoctorPatientRequestService].
///
/// Supplies realistic clinical OPD queue fixtures for UI development without
/// creating fake patient or request records in Cloud Firestore.
class MockDoctorPatientRequestService implements DoctorPatientRequestService {
  static final MockDoctorPatientRequestService instance =
      MockDoctorPatientRequestService();

  bool simulateError = false;
  List<DoctorPatientRequest>? _customRequests;

  MockDoctorPatientRequestService({
    List<DoctorPatientRequest>? customRequests,
  }) : _customRequests = customRequests != null ? List.from(customRequests) : null;

  /// Default development OPD queue fixtures for Cardiology.
  static List<DoctorPatientRequest> get defaultDemoRequests => [
        DoctorPatientRequest(
          requestId: 'REQ-D5-001',
          appointmentId: 'APT-D5-001',
          patientId: 'PAT-MOCK-001',
          queueNumber: 'A-00027',
          age: 42,
          gender: 'Male',
          domain: 'Cardiology',
          requestType: PatientRequestType.newVisit,
          vitals: VitalReading(
            vitalId: 'VIT-MOCK-001',
            patientId: 'PAT-MOCK-001',
            appointmentId: 'APT-D5-001',
            spo2: 97,
            heartRate: 78,
            temperature: 36.8,
            timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
            status: VitalStatus.valid,
            validationStatus: 'normal',
          ),
          requestedAt: DateTime.now().subtract(const Duration(minutes: 15)),
          status: PatientRequestStatus.waiting,
        ),
        DoctorPatientRequest(
          requestId: 'REQ-D5-002',
          appointmentId: 'APT-D5-002',
          patientId: 'PAT-MOCK-002',
          queueNumber: 'A-00028',
          age: 57,
          gender: 'Female',
          domain: 'Cardiology',
          requestType: PatientRequestType.newVisit,
          vitals: VitalReading(
            vitalId: 'VIT-MOCK-002',
            patientId: 'PAT-MOCK-002',
            appointmentId: 'APT-D5-002',
            spo2: 95,
            heartRate: 84,
            temperature: 37.0,
            timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
            status: VitalStatus.valid,
            validationStatus: 'normal',
          ),
          requestedAt: DateTime.now().subtract(const Duration(minutes: 10)),
          status: PatientRequestStatus.waiting,
        ),
        DoctorPatientRequest(
          requestId: 'REQ-D5-003',
          appointmentId: 'APT-D5-003',
          patientId: 'PAT-MOCK-003',
          queueNumber: 'A-00029',
          age: 35,
          gender: 'Male',
          domain: 'Cardiology',
          requestType: PatientRequestType.previousDoctor,
          previousDoctorId: 'DOC-101',
          vitals: VitalReading(
            vitalId: 'VIT-MOCK-003',
            patientId: 'PAT-MOCK-003',
            appointmentId: 'APT-D5-003',
            spo2: 98,
            heartRate: 72,
            temperature: 36.6,
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
            status: VitalStatus.valid,
            validationStatus: 'normal',
          ),
          requestedAt: DateTime.now().subtract(const Duration(minutes: 5)),
          status: PatientRequestStatus.waiting,
        ),
      ];

  final StreamController<void> _changeController = StreamController<void>.broadcast();

  void setRequests(List<DoctorPatientRequest> requests) {
    _customRequests = List.from(requests);
    _changeController.add(null);
  }

  void addRequest(DoctorPatientRequest request) {
    _customRequests ??= [];
    _customRequests!.add(request);
    _changeController.add(null);
  }

  void clearAllRequests() {
    _customRequests = [];
    _changeController.add(null);
  }

  void resetToDefault() {
    _customRequests = null;
    simulateError = false;
    _changeController.add(null);
  }

  @override
  Stream<List<DoctorPatientRequest>> watchPendingRequests({String? domain}) async* {
    if (simulateError) {
      throw Exception('Unable to load patient requests from clinical server.');
    }
    yield await getPendingRequests(domain: domain);
    yield* _changeController.stream.asyncMap((_) => getPendingRequests(domain: domain));
  }

  @override
  Future<List<DoctorPatientRequest>> getPendingRequests({String? domain}) async {
    if (simulateError) {
      throw Exception('Unable to load patient requests from clinical server.');
    }

    final rawList = _customRequests ?? defaultDemoRequests;
    var filtered = rawList.where((req) => req.isWaiting).toList();

    if (domain != null && domain.isNotEmpty) {
      filtered = filtered
          .where((req) => req.domain.toLowerCase() == domain.toLowerCase())
          .toList();
    }

    // Include pending inter-department transfer requests for this domain (Phase D13)
    if (_customRequests == null && domain != null && domain.isNotEmpty) {
      try {
        final transferRepo = BackendProvider.instance.transferRepository;
        final pendingTransfers = await transferRepo.getPendingTransfersForDepartment(domain);
        for (final trf in pendingTransfers) {
          if (!filtered.any((r) => r.requestId == trf.transferId)) {
            filtered.add(
              DoctorPatientRequest.fromTransferRequest(trf),
            );
          }
        }
      } catch (_) {}
    }

    // Queue ordering: FIFO based on requestedAt ascending
    filtered.sort((a, b) => a.requestedAt.compareTo(b.requestedAt));
    return filtered;
  }

  @override
  Future<int> getPendingRequestCount({String? domain}) async {
    final list = await getPendingRequests(domain: domain);
    return list.length;
  }

  @override
  Future<void> refreshRequests() async {
    // In mock mode, this is an instantaneous in-memory reload
    return;
  }

  /// Retrieves a patient request by its request ID or appointment ID regardless of status.
  DoctorPatientRequest? getRequestById(String requestId) {
    final list = _customRequests ?? defaultDemoRequests;
    try {
      return list.firstWhere(
        (r) => r.requestId == requestId || r.appointmentId == requestId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<DoctorAssignmentResult> acceptPatientRequest({
    required String requestId,
    required String doctorId,
    required String doctorDomain,
  }) async {
    if (simulateError) {
      return DoctorAssignmentResult.error(
        requestId: requestId,
        message: 'Mock server failure during patient assignment.',
      );
    }

    // 1. Presence Pre-condition Check
    if (!DoctorPresenceService.instance.isAvailable) {
      return DoctorAssignmentResult.unavailable(
        requestId: requestId,
        message: 'Doctor is not available to accept patient requests.',
      );
    }

    // Check if this is a transfer request (Phase D13)
    if (requestId.startsWith('TRF') || requestId.contains('TRF')) {
      final transferRepo = BackendProvider.instance.transferRepository;
      final trfResult = await transferRepo.acceptTransfer(
        transferId: requestId,
        doctorId: doctorId,
        doctorName: 'Dr. Rajesh Sharma',
        doctorDepartment: doctorDomain,
      );

      if (trfResult.isSuccess) {
        final now = DateTime.now();
        // Log Transfer Accepted Audit Event
        try {
          await BackendProvider.instance.auditRepository.logEvent(
            AuditLog(
              auditId: 'AUD-TRF-ACCEPT-${now.millisecondsSinceEpoch}',
              actorType: 'DOCTOR',
              actorId: doctorId,
              action: 'TRANSFER_ACCEPTED',
              entityType: 'TRANSFER_REQUEST',
              entityId: requestId,
              timestamp: now,
              metadata: {
                'transferId': requestId,
                'doctorId': doctorId,
                'destinationDepartment': doctorDomain,
              },
            ),
          );
        } catch (_) {}
      }
      return trfResult;
    }

    _customRequests ??= List.from(defaultDemoRequests);

    final index = _customRequests!.indexWhere((r) => r.requestId == requestId);
    if (index == -1) {
      return DoctorAssignmentResult.invalidRequest(
        requestId: requestId,
        message: 'Patient request not found in mock queue.',
      );
    }

    final target = _customRequests![index];

    // 2. First-Doctor-Wins Check: Must be waiting and unassigned
    if (!target.isWaiting ||
        (target.assignedDoctorId != null && target.assignedDoctorId != doctorId)) {
      return DoctorAssignmentResult.alreadyAssigned(
        requestId: requestId,
        queueNumber: target.queueNumber,
        message: 'Patient request has already been assigned to another doctor.',
      );
    }

    // 3. Domain Eligibility Check
    if (target.domain.toLowerCase() != doctorDomain.toLowerCase()) {
      return DoctorAssignmentResult.ineligible(
        requestId: requestId,
        message: 'Domain mismatch: Request is for ${target.domain}.',
      );
    }

    // 4. Previous Doctor Restriction Check
    if (target.previousDoctorId != null &&
        target.previousDoctorId!.isNotEmpty &&
        target.previousDoctorId != doctorId) {
      return DoctorAssignmentResult.ineligible(
        requestId: requestId,
        message: 'Request is reserved for previous doctor ${target.previousDoctorId}.',
      );
    }

    // 5. Atomic Update
    final now = DateTime.now();
    final updated = target.copyWith(
      status: PatientRequestStatus.assigned,
      assignedDoctorId: doctorId,
      assignedAt: now,
    );
    _customRequests![index] = updated;

    // Save corresponding appointment in appointment repository for immediate workspace resolution
    final appointment = AppointmentRequest(
      requestId: target.requestId,
      patientId: target.patientId,
      domainId: target.domain,
      preferredDoctorMode: target.isPreviousDoctorRequested
          ? PreferredDoctorMode.sameDoctor
          : PreferredDoctorMode.anyDoctor,
      previousDoctorId: target.previousDoctorId,
      assignedDoctorId: doctorId,
      status: AppointmentStatus.accepted,
      queueNumber: target.queueNumber,
      createdAt: target.requestedAt,
      updatedAt: now,
      sessionId: 'SES-DEV-${target.patientId}',
    );
    await BackendProvider.instance.appointmentRepository.saveAppointment(appointment);

    // 6. Audit Logging (Zero Aadhaar, Zero Passwords, Zero OTP)
    try {
      await BackendProvider.instance.auditRepository.logEvent(
        AuditLog(
          auditId: 'AUD-ASSIGN-${now.millisecondsSinceEpoch}',
          actorType: AuditActorType.doctor.value,
          actorId: doctorId,
          action: 'DOCTOR_REQUEST_ACCEPTED',
          entityType: 'APPOINTMENT',
          entityId: requestId,
          timestamp: now,
          metadata: {
            'queueNumber': target.queueNumber,
            'domain': doctorDomain,
            'assignedDoctorId': doctorId,
          },
        ),
      );
    } catch (_) {}

    return DoctorAssignmentResult.success(
      requestId: requestId,
      appointmentId: target.appointmentId,
      queueNumber: target.queueNumber,
      assignedDoctorId: doctorId,
      assignedAt: now,
      message: 'Patient accepted successfully.',
    );
  }

  void reset() {
    _customRequests = null;
    simulateError = false;
  }
}

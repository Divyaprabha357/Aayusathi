import '../core/backend/backend_mode.dart';
import '../models/appointment_request.dart';
import '../models/vital_reading.dart';
import 'doctor_availability_service.dart';

/// Abstract service managing appointment request creation and queue generation.
abstract class AppointmentService {
  /// Generates the next sequential queue ticket number (e.g. 'A-00001', 'A-00002').
  String generateNextQueueNumber();

  /// Creates and registers an appointment request.
  Future<AppointmentRequest> createAppointmentRequest({
    required String patientId,
    required String domainId,
    required String sessionId,
    String? previousDoctorId,
    required PreferredDoctorMode preferredDoctorMode,
    VitalReading? vitals,
  });

  /// Atomically creates, allocates queue ticket, and persists the appointment request via the active repository.
  Future<AppointmentRequest> createAndPersistAppointmentRequest({
    required String patientId,
    required String domainId,
    required String sessionId,
    String? previousDoctorId,
    required PreferredDoctorMode preferredDoctorMode,
    VitalReading? vitals,
  });

  /// Resets the sequential queue counter back to 1.
  void resetQueueCounter();
}

/// Mock implementation of [AppointmentService] with sequential queue tickets.
class MockAppointmentService implements AppointmentService {
  final DoctorAvailabilityService _doctorAvailabilityService;
  int _queueCounter = 1;

  MockAppointmentService({
    DoctorAvailabilityService? doctorAvailabilityService,
  }) : _doctorAvailabilityService =
            doctorAvailabilityService ?? MockDoctorAvailabilityService();

  @override
  String generateNextQueueNumber() {
    final number = 'A-${_queueCounter.toString().padLeft(5, '0')}';
    _queueCounter++;
    return number;
  }

  @override
  Future<AppointmentRequest> createAppointmentRequest({
    required String patientId,
    required String domainId,
    required String sessionId,
    String? previousDoctorId,
    required PreferredDoctorMode preferredDoctorMode,
    VitalReading? vitals,
  }) async {
    final queueNum = generateNextQueueNumber();
    final allBusy = await _doctorAvailabilityService.areAllDoctorsBusy(domainId);
    final status = allBusy ? AppointmentStatus.pending : AppointmentStatus.waiting;

    return AppointmentRequest(
      requestId: 'REQ-${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      domainId: domainId,
      previousDoctorId: previousDoctorId,
      assignedDoctorId: null, // STRICT: Unassigned until physician explicitly accepts
      preferredDoctorMode: preferredDoctorMode,
      status: status,
      queueNumber: queueNum,
      createdAt: DateTime.now(),
      source: 'KIOSK',
      sessionId: sessionId,
      vitals: vitals,
    );
  }

  @override
  Future<AppointmentRequest> createAndPersistAppointmentRequest({
    required String patientId,
    required String domainId,
    required String sessionId,
    String? previousDoctorId,
    required PreferredDoctorMode preferredDoctorMode,
    VitalReading? vitals,
  }) async {
    final allBusy = await _doctorAvailabilityService.areAllDoctorsBusy(domainId);
    final status = allBusy ? AppointmentStatus.pending : AppointmentStatus.waiting;

    final initial = AppointmentRequest(
      requestId: 'REQ-${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      domainId: domainId,
      previousDoctorId: previousDoctorId,
      assignedDoctorId: null, // STRICT: Unassigned until physician explicitly accepts
      preferredDoctorMode: preferredDoctorMode,
      status: status,
      queueNumber: 'A-00000',
      createdAt: DateTime.now(),
      source: 'KIOSK',
      sessionId: sessionId,
      vitals: vitals,
    );

    return BackendProvider.instance.appointmentRepository.saveAppointmentWithAtomicQueue(initial);
  }

  @override
  void resetQueueCounter() {
    _queueCounter = 1;
    BackendProvider.instance.appointmentRepository.resetQueueCounter();
  }
}

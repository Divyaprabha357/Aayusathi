import '../doctor/models/doctor_assignment_result.dart';
import '../models/appointment_request.dart';

/// Abstract contract for appointment persistence, real-time streaming,
/// queue allocation, and atomic administrative doctor assignment.
abstract class AppointmentRepository {
  /// Persists a new appointment request.
  Future<void> saveAppointment(AppointmentRequest appointment);

  /// Atomically allocates the next sequential queue number and persists the appointment.
  /// Guarantees that queue numbers and appointments are committed together without collision or loss.
  /// Throws [BackendException] if queue capacity (99,999) is reached or persistence fails.
  Future<AppointmentRequest> saveAppointmentWithAtomicQueue(AppointmentRequest request);

  /// Retrieves an appointment by its [requestId].
  Future<AppointmentRequest?> getAppointmentById(String requestId);

  /// Retrieves all consultation appointments for a given [patientId].
  Future<List<AppointmentRequest>> getAppointmentsForPatient(String patientId);

  /// Retrieves all appointment records from the repository.
  Future<List<AppointmentRequest>> getAllAppointments();

  /// Real-time stream of all appointment requests in the system.
  Stream<List<AppointmentRequest>> watchAllAppointments();

  /// Updates the lifecycle status of an appointment.
  Future<void> updateAppointmentStatus(String requestId, AppointmentStatus status);

  /// Atomically marks an unassigned, waiting appointment as ESCALATED if it has reached
  /// the 20-minute SLA threshold.
  /// Returns `true` if marked escalated, `false` if already escalated or assigned.
  Future<bool> markAppointmentEscalated(String requestId);

  /// Atomically assigns an eligible doctor to an escalated/waiting appointment by an Admin.
  /// Locks the appointment, changes doctor presence to IN_CONSULTATION, and logs an audit trail.
  Future<DoctorAssignmentResult> adminAssignDoctor({
    required String requestId,
    required String doctorId,
    required String doctorDomain,
    required String adminId,
  });

  /// Generates and reserves the next sequential queue ticket (strictly matching `^A-[0-9]{5}$`).
  Future<String> allocateNextQueueNumber();

  /// Resets the queue counter back to 1 (for testing and daily cycle).
  void resetQueueCounter();
}

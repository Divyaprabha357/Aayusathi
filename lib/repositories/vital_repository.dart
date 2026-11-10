import '../models/vital_reading.dart';

/// Abstract contract for sensor vital telemetry persistence and query.
abstract class VitalRepository {
  /// Persists a vital telemetry bundle for a patient.
  Future<void> saveVitalReading({
    required String patientId,
    required VitalReading reading,
    String? appointmentId,
  });

  /// Retrieves chronological vital telemetry history for a patient.
  Future<List<VitalReading>> getVitalsForPatient(String patientId);

  /// Retrieves the vital measurement associated with a specific appointment.
  Future<VitalReading?> getVitalsForAppointment(String appointmentId);
}

import '../../models/vital_reading.dart';
import '../vital_repository.dart';

/// In-memory mock implementation of [VitalRepository] for sensor telemetry storage.
class MockVitalRepository implements VitalRepository {
  static final MockVitalRepository instance = MockVitalRepository._();
  MockVitalRepository._();
  factory MockVitalRepository() => instance;

  final List<VitalReading> _readings = [];

  void reset() {
    _readings.clear();
  }

  @override
  Future<void> saveVitalReading({
    required String patientId,
    required VitalReading reading,
    String? appointmentId,
  }) async {
    final record = reading.copyWith(
      vitalId: reading.vitalId ?? 'VIT-${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      appointmentId: appointmentId ?? reading.appointmentId,
    );
    _readings.add(record);
  }

  @override
  Future<List<VitalReading>> getVitalsForPatient(String patientId) async {
    return _readings
        .where((r) => r.patientId?.toUpperCase() == patientId.toUpperCase())
        .toList();
  }

  @override
  Future<VitalReading?> getVitalsForAppointment(String appointmentId) async {
    try {
      return _readings.firstWhere((r) => r.appointmentId == appointmentId);
    } catch (_) {
      return null;
    }
  }

  /// Exposes count for test verification
  int get count => _readings.length;

  /// Clears stored readings
  void clear() {
    _readings.clear();
  }
}

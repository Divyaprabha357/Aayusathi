import '../../models/previous_visit_record.dart';
import '../visit_repository.dart';

/// Deterministic in-memory implementation of [VisitRepository] for testing and offline execution.
class MockVisitRepository implements VisitRepository {
  static final MockVisitRepository instance = MockVisitRepository._();
  MockVisitRepository._() {
    resetToDefaults();
  }
  factory MockVisitRepository() => instance;

  final List<PreviousVisitRecord> _records = [];

  void resetToDefaults() {
    _records
      ..clear()
      ..addAll([
        // Aarav Sharma (AAYU-102938)
        PreviousVisitRecord(
          visitId: 'VIS-MOCK-001',
          patientId: 'AAYU-102938',
          domainId: 'cardiology',
          previousDoctorId: 'DOC-CARD-01',
          lastVisitDate: DateTime(2026, 7, 15),
          status: 'completed',
        ),
        PreviousVisitRecord(
          visitId: 'VIS-MOCK-002',
          patientId: 'AAYU-102938',
          domainId: 'neurology',
          previousDoctorId: 'DOC-NEUR-01',
          lastVisitDate: DateTime(2026, 6, 20),
          status: 'completed',
        ),
        PreviousVisitRecord(
          visitId: 'VIS-MOCK-003',
          patientId: 'AAYU-102938',
          domainId: 'orthopedics',
          previousDoctorId: 'DOC-ORTH-01',
          lastVisitDate: DateTime(2026, 5, 10),
          status: 'completed',
        ),

        // Priya Patil (AAYU-482910)
        PreviousVisitRecord(
          visitId: 'VIS-MOCK-004',
          patientId: 'AAYU-482910',
          domainId: 'pediatrics',
          previousDoctorId: 'DOC-PED-01',
          lastVisitDate: DateTime(2026, 8, 1),
          status: 'completed',
        ),
      ]);
  }

  @override
  Future<void> saveVisit(PreviousVisitRecord visit) async {
    _records.removeWhere(
      (r) => r.visitId == visit.visitId ||
          (r.patientId == visit.patientId &&
              r.domainId == visit.domainId &&
              r.appointmentId != null &&
              r.appointmentId == visit.appointmentId),
    );
    _records.add(visit);
  }

  @override
  Future<PreviousVisitRecord?> getLatestVisitForPatientAndDomain({
    required String patientId,
    required String domainId,
  }) async {
    final matches = _records.where(
      (r) =>
          r.patientId.toUpperCase() == patientId.toUpperCase() &&
          r.domainId.toLowerCase() == domainId.toLowerCase(),
    ).toList();

    if (matches.isEmpty) return null;
    matches.sort((a, b) => b.lastVisitDate.compareTo(a.lastVisitDate));
    return matches.first;
  }

  @override
  Future<List<PreviousVisitRecord>> getVisitsForPatient(String patientId) async {
    final matches = _records
        .where((r) => r.patientId.toUpperCase() == patientId.toUpperCase())
        .toList();
    matches.sort((a, b) => b.lastVisitDate.compareTo(a.lastVisitDate));
    return matches;
  }

  void addRecord(PreviousVisitRecord record) {
    _records.add(record);
  }

  void clear() {
    _records.clear();
  }

  int get count => _records.length;
}

import '../core/backend/backend_mode.dart';
import '../models/previous_visit_record.dart';
import '../repositories/mock/mock_visit_repository.dart';
import '../repositories/visit_repository.dart';

/// Abstract contract for querying patient previous visit history by department.
abstract class PreviousVisitService {
  /// Checks whether a patient has a prior visit in the specified domain.
  Future<bool> hasPreviousVisit({
    required String patientId,
    required String domainId,
  });

  /// Retrieves the previous visit record for a patient in the specified domain.
  Future<PreviousVisitRecord?> getPreviousVisit({
    required String patientId,
    required String domainId,
  });
}

/// Production repository-backed previous visit service.
/// Dynamically queries [BackendProvider.instance.visitRepository]
/// to retrieve patient-scoped previous visit history from Firestore (in Firebase mode)
/// or from in-memory records (in Mock mode).
class RepositoryPreviousVisitService extends MockPreviousVisitService {
  final VisitRepository? _customRepository;

  RepositoryPreviousVisitService({VisitRepository? repository})
      : _customRepository = repository;

  VisitRepository get _repository =>
      _customRepository ?? BackendProvider.instance.visitRepository;

  @override
  Future<bool> hasPreviousVisit({
    required String patientId,
    required String domainId,
  }) async {
    hasPreviousVisitCallCount++;
    try {
      final record = await _repository.getLatestVisitForPatientAndDomain(
        patientId: patientId,
        domainId: domainId,
      );
      return record != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<PreviousVisitRecord?> getPreviousVisit({
    required String patientId,
    required String domainId,
  }) async {
    getPreviousVisitCallCount++;
    try {
      return await _repository.getLatestVisitForPatientAndDomain(
        patientId: patientId,
        domainId: domainId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void reset() {
    super.reset();
    if (BackendProvider.instance.visitRepository is MockVisitRepository) {
      (BackendProvider.instance.visitRepository as MockVisitRepository).resetToDefaults();
    }
  }

  @override
  void addVisit(PreviousVisitRecord record) {
    super.addVisit(record);
    if (BackendProvider.instance.visitRepository is MockVisitRepository) {
      BackendProvider.instance.visitRepository.saveVisit(record);
    }
  }
}

/// Deterministic mock implementation of [PreviousVisitService].
class MockPreviousVisitService implements PreviousVisitService {
  final List<PreviousVisitRecord> _records = [
    // Aarav Sharma (AAYU-102938) test records:
    PreviousVisitRecord(
      patientId: 'AAYU-102938',
      domainId: 'cardiology',
      previousDoctorId: 'DOC-CARD-01',
      lastVisitDate: DateTime(2026, 7, 15),
    ),
    PreviousVisitRecord(
      patientId: 'AAYU-102938',
      domainId: 'neurology',
      previousDoctorId: 'DOC-NEUR-01', // Note: DOC-NEUR-01 is unavailable in MockDoctorAvailabilityService
      lastVisitDate: DateTime(2026, 6, 20),
    ),
    PreviousVisitRecord(
      patientId: 'AAYU-102938',
      domainId: 'orthopedics',
      previousDoctorId: 'DOC-ORTH-01', // Note: orthopedics has all doctors busy in mock
      lastVisitDate: DateTime(2026, 5, 10),
    ),

    // Priya Patil (AAYU-482910) test record:
    PreviousVisitRecord(
      patientId: 'AAYU-482910',
      domainId: 'pediatrics',
      previousDoctorId: 'DOC-PED-01',
      lastVisitDate: DateTime(2026, 8, 1),
    ),
  ];

  int hasPreviousVisitCallCount = 0;
  int getPreviousVisitCallCount = 0;
  int get totalCallCount => hasPreviousVisitCallCount + getPreviousVisitCallCount;

  @override
  Future<bool> hasPreviousVisit({
    required String patientId,
    required String domainId,
  }) async {
    hasPreviousVisitCallCount++;
    return _records.any(
      (r) =>
          r.patientId.toUpperCase() == patientId.toUpperCase() &&
          r.domainId.toLowerCase() == domainId.toLowerCase(),
    );
  }

  @override
  Future<PreviousVisitRecord?> getPreviousVisit({
    required String patientId,
    required String domainId,
  }) async {
    getPreviousVisitCallCount++;
    try {
      return _records.firstWhere(
        (r) =>
            r.patientId.toUpperCase() == patientId.toUpperCase() &&
            r.domainId.toLowerCase() == domainId.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  // --- Test Helpers ---

  /// Adds a custom visit record for testing scenarios.
  void addVisit(PreviousVisitRecord record) {
    _records.removeWhere(
      (r) => r.patientId == record.patientId && r.domainId == record.domainId,
    );
    _records.add(record);
  }

  /// Clears all visit records.
  void clearVisits() {
    _records.clear();
  }

  /// Resets back to initial mock records.
  void reset() {
    hasPreviousVisitCallCount = 0;
    getPreviousVisitCallCount = 0;
    _records
      ..clear()
      ..addAll([
        PreviousVisitRecord(
          patientId: 'AAYU-102938',
          domainId: 'cardiology',
          previousDoctorId: 'DOC-CARD-01',
          lastVisitDate: DateTime(2026, 7, 15),
        ),
        PreviousVisitRecord(
          patientId: 'AAYU-102938',
          domainId: 'neurology',
          previousDoctorId: 'DOC-NEUR-01',
          lastVisitDate: DateTime(2026, 6, 20),
        ),
        PreviousVisitRecord(
          patientId: 'AAYU-102938',
          domainId: 'orthopedics',
          previousDoctorId: 'DOC-ORTH-01',
          lastVisitDate: DateTime(2026, 5, 10),
        ),
        PreviousVisitRecord(
          patientId: 'AAYU-482910',
          domainId: 'pediatrics',
          previousDoctorId: 'DOC-PED-01',
          lastVisitDate: DateTime(2026, 8, 1),
        ),
      ]);
  }
}

import 'dart:async';
import '../../core/backend/backend_mode.dart';
import 'doctor_patient_request_service.dart';
import 'firebase_doctor_dashboard_metrics_service.dart';

/// Abstract service providing operational metrics for the Doctor Clinical Dashboard.
///
/// Designed with a decoupled architecture so development/mock runs provide
/// local indicators without database dependencies, and production builds connect
/// directly to Cloud Firestore aggregations.
abstract class DoctorDashboardMetricsService {
  static DoctorDashboardMetricsService? _customInstance;

  /// Custom override for testing.
  static set instance(DoctorDashboardMetricsService? service) {
    _customInstance = service;
  }

  /// Resolves the active metrics service instance based on backend mode.
  static DoctorDashboardMetricsService get instance {
    if (_customInstance != null) return _customInstance!;
    if (BackendProvider.instance.isFirebaseMode) {
      return FirebaseDoctorDashboardMetricsService();
    }
    return MockDoctorDashboardMetricsService();
  }

  /// Retrieves the total count of patients attended/consulted by this doctor today.
  Future<int> getPatientsAttendedTodayCount({String? doctorId});

  /// Streams real-time updates for patients attended today.
  Stream<int> watchPatientsAttendedTodayCount({String? doctorId});

  /// Retrieves the count of pending incoming patient consultation requests.
  Future<int> getPendingRequestsCount({String? domain});

  /// Streams real-time updates for pending requests count.
  Stream<int> watchPendingRequestsCount({String? domain});
}

/// Development/Mock implementation of [DoctorDashboardMetricsService].
///
/// Provides static test metrics without writing or querying Cloud Firestore.
class MockDoctorDashboardMetricsService implements DoctorDashboardMetricsService {
  int mockAttendedCount;
  final int? _explicitMockPendingCount;
  final bool simulateError;
  final StreamController<int> _attendedController = StreamController<int>.broadcast();

  MockDoctorDashboardMetricsService({
    this.mockAttendedCount = 0,
    int? mockPendingCount,
    this.simulateError = false,
  }) : _explicitMockPendingCount = mockPendingCount;

  void setAttendedCount(int count) {
    mockAttendedCount = count;
    _attendedController.add(count);
  }

  @override
  Future<int> getPatientsAttendedTodayCount({String? doctorId}) async {
    if (simulateError) {
      throw Exception('Unable to load live dashboard data.');
    }
    return mockAttendedCount;
  }

  @override
  Stream<int> watchPatientsAttendedTodayCount({String? doctorId}) async* {
    if (simulateError) {
      throw Exception('Unable to load live dashboard data.');
    }
    yield mockAttendedCount;
    yield* _attendedController.stream;
  }

  @override
  Future<int> getPendingRequestsCount({String? domain}) async {
    if (simulateError) {
      throw Exception('Unable to load live dashboard data.');
    }
    final explicit = _explicitMockPendingCount;
    if (explicit != null) {
      return explicit;
    }
    return DoctorPatientRequestService.instance.getPendingRequestCount(domain: domain);
  }

  @override
  Stream<int> watchPendingRequestsCount({String? domain}) {
    if (simulateError) {
      return Stream.error(Exception('Unable to load live dashboard data.'));
    }
    final explicit = _explicitMockPendingCount;
    if (explicit != null) {
      return Stream.value(explicit);
    }
    return DoctorPatientRequestService.instance
        .watchPendingRequests(domain: domain)
        .map((requests) => requests.length);
  }
}

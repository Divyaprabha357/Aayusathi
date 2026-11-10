import '../../core/backend/backend_mode.dart';
import 'doctor_session_service.dart';
import 'firebase_doctor_patient_request_service.dart';
import '../models/doctor_assignment_result.dart';
import '../models/doctor_patient_request.dart';
import 'mock_doctor_patient_request_service.dart';

/// Abstract service defining doctor patient request query, stream, and refresh operations.
abstract class DoctorPatientRequestService {
  static DoctorPatientRequestService? _customInstance;

  /// Sets custom service override for testing.
  static set instance(DoctorPatientRequestService? service) {
    _customInstance = service;
  }

  /// Resolves the active request service based on doctor session and backend mode.
  static DoctorPatientRequestService get instance {
    if (_customInstance != null) return _customInstance!;
    if (DoctorSessionService.instance.isDevelopmentMode) {
      return MockDoctorPatientRequestService.instance;
    }
    if (BackendProvider.instance.isFirebaseMode) {
      return FirebaseDoctorPatientRequestService();
    }
    return MockDoctorPatientRequestService.instance;
  }

  /// Retrieves waiting incoming OPD consultation requests, optionally filtered by clinical domain.
  Future<List<DoctorPatientRequest>> getPendingRequests({String? domain});

  /// Streams real-time updates for waiting incoming OPD consultation requests.
  Stream<List<DoctorPatientRequest>> watchPendingRequests({String? domain});

  /// Retrieves the total count of waiting incoming OPD consultation requests.
  Future<int> getPendingRequestCount({String? domain});

  /// Forces a refresh of incoming requests from the backing data source.
  Future<void> refreshRequests();

  /// Atomically claims and assigns a waiting OPD consultation request to the specified doctor.
  /// Enforces first-doctor-wins semantics, domain eligibility, and presence verification.
  Future<DoctorAssignmentResult> acceptPatientRequest({
    required String requestId,
    required String doctorId,
    required String doctorDomain,
  });
}

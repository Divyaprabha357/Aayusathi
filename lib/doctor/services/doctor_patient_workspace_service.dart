import '../../core/backend/backend_mode.dart';
import '../../models/appointment_request.dart';
import '../../models/patient.dart';
import '../../models/vital_reading.dart';
import '../models/clinical_case.dart';
import '../models/clinical_visit.dart';
import '../models/patient_report.dart';
import 'doctor_session_service.dart';
import 'firebase_doctor_patient_workspace_service.dart';
import 'mock_doctor_patient_workspace_service.dart';

/// Access authorization status for opening a patient workspace.
enum WorkspaceAccessStatus {
  success,
  unauthorized,
  patientNotFound,
  appointmentNotFound,
  error,
}

/// Data bundle retrieved for an authorized Doctor Patient Workspace session.
class DoctorPatientWorkspaceData {
  final WorkspaceAccessStatus status;
  final Patient? patient;
  final AppointmentRequest? appointment;
  final VitalReading? vitals;
  final List<ClinicalCase> cases;
  final List<ClinicalVisit> visits;
  final List<PatientReport> reports;
  final String? message;

  const DoctorPatientWorkspaceData({
    required this.status,
    this.patient,
    this.appointment,
    this.vitals,
    this.cases = const [],
    this.visits = const [],
    this.reports = const [],
    this.message,
  });

  bool get isSuccess => status == WorkspaceAccessStatus.success;
  bool get isUnauthorized => status == WorkspaceAccessStatus.unauthorized;
  bool get isNotFound =>
      status == WorkspaceAccessStatus.patientNotFound ||
      status == WorkspaceAccessStatus.appointmentNotFound;
  bool get isError => status == WorkspaceAccessStatus.error;

  factory DoctorPatientWorkspaceData.success({
    required Patient patient,
    required AppointmentRequest appointment,
    VitalReading? vitals,
    List<ClinicalCase> cases = const [],
    List<ClinicalVisit> visits = const [],
    List<PatientReport> reports = const [],
  }) {
    return DoctorPatientWorkspaceData(
      status: WorkspaceAccessStatus.success,
      patient: patient,
      appointment: appointment,
      vitals: vitals,
      cases: cases,
      visits: visits,
      reports: reports,
    );
  }

  factory DoctorPatientWorkspaceData.unauthorized({String? message}) {
    return DoctorPatientWorkspaceData(
      status: WorkspaceAccessStatus.unauthorized,
      message: message ?? 'You are not authorized to access this patient workspace.',
    );
  }

  factory DoctorPatientWorkspaceData.patientNotFound({String? message}) {
    return DoctorPatientWorkspaceData(
      status: WorkspaceAccessStatus.patientNotFound,
      message: message ?? 'Patient record could not be found.',
    );
  }

  factory DoctorPatientWorkspaceData.appointmentNotFound({String? message}) {
    return DoctorPatientWorkspaceData(
      status: WorkspaceAccessStatus.appointmentNotFound,
      message: message ?? 'Appointment consultation record could not be found.',
    );
  }

  factory DoctorPatientWorkspaceData.error({required String message}) {
    return DoctorPatientWorkspaceData(
      status: WorkspaceAccessStatus.error,
      message: message,
    );
  }
}

/// Abstract contract for Doctor Patient Workspace data loading and authorization.
abstract class DoctorPatientWorkspaceService {
  static DoctorPatientWorkspaceService? _customInstance;

  /// Sets custom service override for testing.
  static set instance(DoctorPatientWorkspaceService? service) {
    _customInstance = service;
  }

  /// Resolves the active workspace service based on doctor session and backend mode.
  static DoctorPatientWorkspaceService get instance {
    if (_customInstance != null) return _customInstance!;
    if (DoctorSessionService.instance.isDevelopmentMode) {
      return MockDoctorPatientWorkspaceService.instance;
    }
    if (BackendProvider.instance.isFirebaseMode) {
      return FirebaseDoctorPatientWorkspaceService();
    }
    return MockDoctorPatientWorkspaceService.instance;
  }

  /// Securely loads authorized clinical patient workspace data.
  ///
  /// Strict Authorization:
  /// - Doctor must be authenticated.
  /// - Doctor account must be active.
  /// - Target appointment must exist.
  /// - Appointment `assignedDoctorId` must strictly match [doctorId].
  Future<DoctorPatientWorkspaceData> loadWorkspaceData({
    required String requestId,
    required String doctorId,
  });

  /// Loads reports for the given patient.
  Future<List<PatientReport>> getReportsForPatient(String patientId);
}

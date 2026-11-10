import '../../core/backend/backend_mode.dart';
import '../../models/appointment_request.dart';
import '../../models/patient.dart';
import '../../models/vital_reading.dart';
import '../models/clinical_case.dart';
import '../models/clinical_visit.dart';
import '../models/doctor_patient_request.dart';
import '../models/patient_report.dart';
import 'doctor_patient_request_service.dart';
import 'doctor_patient_workspace_service.dart';
import 'mock_doctor_patient_request_service.dart';

/// In-memory mock implementation of [DoctorPatientWorkspaceService] for development and testing.
class MockDoctorPatientWorkspaceService implements DoctorPatientWorkspaceService {
  static final MockDoctorPatientWorkspaceService instance =
      MockDoctorPatientWorkspaceService._();
  MockDoctorPatientWorkspaceService._();
  factory MockDoctorPatientWorkspaceService() => instance;

  bool simulateError = false;
  bool simulateUnauthorized = false;

  final Map<String, List<PatientReport>> _mockReports = {
    'PAT-MOCK-001': [
      PatientReport(
        reportId: 'REP-001',
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
        title: '12-Lead Electrocardiogram (ECG)',
        type: PatientReportType.diagnostic,
        status: PatientReportStatus.available,
        date: DateTime.now().subtract(const Duration(days: 7)),
        summary: 'Sinus rhythm, normal axis, no acute ST-T changes.',
      ),
      PatientReport(
        reportId: 'REP-002',
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
        title: 'Comprehensive Lipid Profile',
        type: PatientReportType.lab,
        status: PatientReportStatus.available,
        date: DateTime.now().subtract(const Duration(days: 7)),
        summary: 'Total Cholesterol: 210 mg/dL, LDL: 130 mg/dL, HDL: 48 mg/dL.',
      ),
      PatientReport(
        reportId: 'REP-003',
        patientId: 'PAT-MOCK-001',
        caseId: 'CASE-PAT-001-01',
        title: '2D Echocardiography',
        type: PatientReportType.diagnostic,
        status: PatientReportStatus.requested,
        date: DateTime.now().subtract(const Duration(days: 1)),
        summary: 'Pending acquisition.',
      ),
      PatientReport(
        reportId: 'REP-004',
        patientId: 'PAT-MOCK-001',
        title: 'Previous Hospital Discharge Summary',
        type: PatientReportType.other,
        status: PatientReportStatus.uploaded,
        date: DateTime.now().subtract(const Duration(days: 60)),
        summary: 'External hospital summary uploaded by patient.',
      ),
    ],
    'AAYU-102938': [
      PatientReport(
        reportId: 'REP-102938-1',
        patientId: 'AAYU-102938',
        caseId: 'CASE-102938-01',
        title: 'Routine Blood Chemistry (CBC + ESR)',
        type: PatientReportType.lab,
        status: PatientReportStatus.available,
        date: DateTime.now().subtract(const Duration(days: 10)),
        summary: 'All parameters within normal clinical limits.',
      ),
      PatientReport(
        reportId: 'REP-102938-2',
        patientId: 'AAYU-102938',
        caseId: 'CASE-102938-01',
        title: 'Renal Function Test (RFT)',
        type: PatientReportType.lab,
        status: PatientReportStatus.available,
        date: DateTime.now().subtract(const Duration(days: 10)),
        summary: 'Serum Creatinine: 0.9 mg/dL, Blood Urea: 22 mg/dL.',
      ),
    ],
  };

  /// Predefined mock patient identities for development queues.
  static final Map<String, Patient> _fallbackMockPatients = {
    'PAT-MOCK-001': Patient(
      patientId: 'PAT-MOCK-001',
      name: 'Aarav Sharma',
      dateOfBirth: '14 May 1984',
      age: 42,
      gender: 'Male',
      phone: '+91 98765 43210',
      bloodGroup: 'O+',
      address: '104, Green Meadows, Pune, Maharashtra',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    'PAT-MOCK-002': Patient(
      patientId: 'PAT-MOCK-002',
      name: 'Sunita Deshmukh',
      dateOfBirth: '18 Jul 1969',
      age: 57,
      gender: 'Female',
      phone: '+91 97654 32109',
      bloodGroup: 'AB+',
      address: 'Bungalow 8, Ramdas Peth, Nagpur',
      createdAt: DateTime(2026, 1, 4),
      updatedAt: DateTime(2026, 1, 4),
    ),
    'PAT-MOCK-003': Patient(
      patientId: 'PAT-MOCK-003',
      name: 'Vikram Joshi',
      dateOfBirth: '05 Mar 1991',
      age: 35,
      gender: 'Male',
      phone: '+91 98123 45678',
      bloodGroup: 'B+',
      address: 'Flat 12, Shivneri Apts, Dadar, Mumbai',
      createdAt: DateTime(2026, 1, 2),
      updatedAt: DateTime(2026, 1, 2),
    ),
  };

  @override
  Future<DoctorPatientWorkspaceData> loadWorkspaceData({
    required String requestId,
    required String doctorId,
  }) async {
    if (simulateError) {
      return DoctorPatientWorkspaceData.error(
        message: 'Unable to connect to clinical workspace server.',
      );
    }

    if (simulateUnauthorized) {
      return DoctorPatientWorkspaceData.unauthorized(
        message: 'You are not authorized to access this patient workspace.',
      );
    }

    // 1. Locate appointment / request
    AppointmentRequest? appointment;
    DoctorPatientRequest? docReq;

    // Check appointment repository first
    appointment = await BackendProvider.instance.appointmentRepository
        .getAppointmentById(requestId);

    // If not found in repo, inspect MockDoctorPatientRequestService
    if (appointment == null) {
      final reqService = DoctorPatientRequestService.instance;
      if (reqService is MockDoctorPatientRequestService) {
        docReq = reqService.getRequestById(requestId);
      }
      docReq ??= MockDoctorPatientRequestService.defaultDemoRequests
          .where((r) => r.requestId == requestId || r.appointmentId == requestId)
          .firstOrNull;

      if (docReq != null) {
        appointment = AppointmentRequest(
          requestId: docReq.requestId,
          patientId: docReq.patientId,
          domainId: docReq.domain,
          preferredDoctorMode: docReq.isPreviousDoctorRequested
              ? PreferredDoctorMode.sameDoctor
              : PreferredDoctorMode.anyDoctor,
          previousDoctorId: docReq.previousDoctorId,
          assignedDoctorId: docReq.assignedDoctorId ?? doctorId,
          status: AppointmentStatus.accepted,
          queueNumber: docReq.queueNumber,
          createdAt: docReq.requestedAt,
          sessionId: 'SES-MOCK-001',
        );
        // Persist to mock repo for subsequent workspace and visit operations
        await BackendProvider.instance.appointmentRepository.saveAppointment(appointment);
      }
    }

    if (appointment == null) {
      return DoctorPatientWorkspaceData.appointmentNotFound(
        message: 'No consultation request found for ID $requestId.',
      );
    }

    // 2. Authorization Verification:
    // If appointment is assigned to another doctor, reject access
    if (appointment.assignedDoctorId != null &&
        appointment.assignedDoctorId!.isNotEmpty &&
        appointment.assignedDoctorId != doctorId) {
      return DoctorPatientWorkspaceData.unauthorized(
        message: 'This patient is assigned to another attending physician.',
      );
    }

    // 3. Load Patient Identity
    Patient? patient = await BackendProvider.instance.patientRepository
        .getPatientById(appointment.patientId);

    patient ??= _fallbackMockPatients[appointment.patientId];
    patient ??= _fallbackMockPatients['PAT-MOCK-001'];

    if (patient == null) {
      return DoctorPatientWorkspaceData.patientNotFound(
        message: 'Patient profile could not be retrieved.',
      );
    }

    // 4. Load Current Vitals
    if (docReq == null) {
      final reqService = DoctorPatientRequestService.instance;
      if (reqService is MockDoctorPatientRequestService) {
        docReq = reqService.getRequestById(requestId);
      }
      docReq ??= MockDoctorPatientRequestService.defaultDemoRequests
          .where((r) => r.requestId == requestId || r.appointmentId == requestId)
          .firstOrNull;
    }
    VitalReading? vitals = docReq?.vitals;
    if (vitals == null) {
      final vitalHistory = await BackendProvider.instance.vitalRepository
          .getVitalsForPatient(patient.patientId);
      if (vitalHistory.isNotEmpty) {
        vitals = vitalHistory.last;
      }
    }

    // 5. Load Clinical Cases & Visits
    var cases = await BackendProvider.instance.caseRepository
        .getCasesForPatient(patient.patientId);

    if (cases.isEmpty) {
      final domain = appointment.domainId.isNotEmpty ? appointment.domainId : 'Cardiology';
      final initialCase = ClinicalCase(
        caseId: 'CASE-${patient.patientId}-01',
        patientId: patient.patientId,
        domain: domain,
        title: '$domain Consultation',
        status: ClinicalCaseStatus.open,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        visitCount: 1,
      );
      final createdCase =
          await BackendProvider.instance.caseRepository.createCase(initialCase);
      cases = [createdCase];
    }

    final visits = <ClinicalVisit>[];
    for (final c in cases) {
      final caseVisits = await BackendProvider.instance.clinicalVisitRepository
          .getVisitsForCase(
        patientId: patient.patientId,
        caseId: c.caseId,
      );
      visits.addAll(caseVisits);
    }

    // 6. Load Reports
    final reports = await getReportsForPatient(patient.patientId);

    return DoctorPatientWorkspaceData.success(
      patient: patient,
      appointment: appointment,
      vitals: vitals,
      cases: cases,
      visits: visits,
      reports: reports,
    );
  }

  @override
  Future<List<PatientReport>> getReportsForPatient(String patientId) async {
    final cleanId = patientId.trim().toUpperCase();
    return _mockReports[cleanId] ?? _mockReports['PAT-MOCK-001'] ?? [];
  }
}

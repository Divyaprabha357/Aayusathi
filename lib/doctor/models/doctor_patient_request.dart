import '../../models/vital_reading.dart';
import 'patient_transfer_request.dart';

/// Clinical type of incoming OPD consultation request.
enum PatientRequestType {
  newVisit,
  previousDoctor,
  transfer,
}

extension PatientRequestTypeExtension on PatientRequestType {
  String get label {
    switch (this) {
      case PatientRequestType.newVisit:
        return 'New Visit';
      case PatientRequestType.previousDoctor:
        return 'Previous Doctor Requested';
      case PatientRequestType.transfer:
        return 'Inter-Department Transfer';
    }
  }

  bool get isNewVisit => this == PatientRequestType.newVisit;
  bool get isPreviousDoctor => this == PatientRequestType.previousDoctor;
  bool get isTransfer => this == PatientRequestType.transfer;
}

/// Operational lifecycle state of an incoming consultation request.
enum PatientRequestStatus {
  waiting,
  assigned,
  inConsultation,
  completed,
  cancelled,
}

extension PatientRequestStatusExtension on PatientRequestStatus {
  String get label {
    switch (this) {
      case PatientRequestStatus.waiting:
        return 'Waiting';
      case PatientRequestStatus.assigned:
        return 'Assigned';
      case PatientRequestStatus.inConsultation:
        return 'In Consultation';
      case PatientRequestStatus.completed:
        return 'Completed';
      case PatientRequestStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isWaiting => this == PatientRequestStatus.waiting;
  bool get isAssigned => this == PatientRequestStatus.assigned;
  bool get isInConsultation => this == PatientRequestStatus.inConsultation;
  bool get isCompleted => this == PatientRequestStatus.completed;
  bool get isCancelled => this == PatientRequestStatus.cancelled;
}

/// Doctor workstation data model representing an incoming OPD consultation request.
///
/// STRICT PRIVACY ARCHITECTURE:
/// Pre-assignment request views omit patient name, Aadhaar, phone number,
/// and personal contact details to protect patient confidentiality before physician acceptance.
class DoctorPatientRequest {
  final String requestId;
  final String appointmentId;
  final String patientId;
  final String? patientName;
  final String queueNumber;
  final int age;
  final String gender;
  final String domain;
  final PatientRequestType requestType;
  final String? previousDoctorId;
  final String? assignedDoctorId;
  final DateTime? assignedAt;
  final VitalReading? vitals;
  final DateTime requestedAt;
  final PatientRequestStatus status;

  // Inter-Department Transfer Details (Phase D13)
  final String? transferId;
  final String? sourceDepartment;
  final String? sourceDoctorId;
  final String? sourceDoctorName;
  final String? transferReason;
  final String? caseId;
  final String? sourceVisitId;

  const DoctorPatientRequest({
    required this.requestId,
    this.appointmentId = '',
    required this.patientId,
    this.patientName,
    this.queueNumber = 'TRF',
    required this.age,
    required this.gender,
    this.domain = '',
    required this.requestType,
    this.previousDoctorId,
    this.assignedDoctorId,
    this.assignedAt,
    this.vitals,
    required this.requestedAt,
    this.status = PatientRequestStatus.waiting,
    this.transferId,
    this.sourceDepartment,
    this.sourceDoctorId,
    this.sourceDoctorName,
    this.transferReason,
    this.caseId,
    this.sourceVisitId,
  });

  bool get isWaiting => status == PatientRequestStatus.waiting;
  bool get isAssigned => status == PatientRequestStatus.assigned;
  bool get isInConsultation => status == PatientRequestStatus.inConsultation;
  bool get isNewVisit => requestType == PatientRequestType.newVisit;
  bool get isPreviousDoctorRequested => requestType == PatientRequestType.previousDoctor;
  bool get isTransferRequest => requestType == PatientRequestType.transfer;

  String get formattedAge => '$age yrs';
  String get formattedAgeGender => '$age yrs • $gender';
  String get opdDepartment => domain;

  factory DoctorPatientRequest.fromTransferRequest(PatientTransferRequest transfer) {
    return DoctorPatientRequest(
      requestId: transfer.transferId,
      appointmentId: transfer.transferId,
      patientId: transfer.patientId,
      patientName: transfer.patientName,
      queueNumber: transfer.queueNumber ?? 'TRF',
      age: transfer.patientAge ?? 0,
      gender: transfer.patientGender ?? 'Unknown',
      domain: transfer.destinationDepartment,
      requestType: PatientRequestType.transfer,
      vitals: transfer.vitals,
      requestedAt: transfer.requestedAt,
      status: transfer.isAccepted
          ? PatientRequestStatus.assigned
          : PatientRequestStatus.waiting,
      transferId: transfer.transferId,
      sourceDepartment: transfer.sourceDepartment,
      sourceDoctorId: transfer.sourceDoctorId,
      sourceDoctorName: transfer.sourceDoctorName,
      transferReason: transfer.reason,
      caseId: transfer.caseId,
      sourceVisitId: transfer.sourceVisitId,
    );
  }

  DoctorPatientRequest copyWith({
    String? requestId,
    String? appointmentId,
    String? patientId,
    String? patientName,
    String? queueNumber,
    int? age,
    String? gender,
    String? domain,
    PatientRequestType? requestType,
    String? previousDoctorId,
    String? assignedDoctorId,
    DateTime? assignedAt,
    VitalReading? vitals,
    DateTime? requestedAt,
    PatientRequestStatus? status,
    String? transferId,
    String? sourceDepartment,
    String? sourceDoctorId,
    String? sourceDoctorName,
    String? transferReason,
    String? caseId,
    String? sourceVisitId,
  }) {
    return DoctorPatientRequest(
      requestId: requestId ?? this.requestId,
      appointmentId: appointmentId ?? this.appointmentId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      queueNumber: queueNumber ?? this.queueNumber,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      domain: domain ?? this.domain,
      requestType: requestType ?? this.requestType,
      previousDoctorId: previousDoctorId ?? this.previousDoctorId,
      assignedDoctorId: assignedDoctorId ?? this.assignedDoctorId,
      assignedAt: assignedAt ?? this.assignedAt,
      vitals: vitals ?? this.vitals,
      requestedAt: requestedAt ?? this.requestedAt,
      status: status ?? this.status,
      transferId: transferId ?? this.transferId,
      sourceDepartment: sourceDepartment ?? this.sourceDepartment,
      sourceDoctorId: sourceDoctorId ?? this.sourceDoctorId,
      sourceDoctorName: sourceDoctorName ?? this.sourceDoctorName,
      transferReason: transferReason ?? this.transferReason,
      caseId: caseId ?? this.caseId,
      sourceVisitId: sourceVisitId ?? this.sourceVisitId,
    );
  }
}

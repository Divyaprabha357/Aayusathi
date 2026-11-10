import 'clinical_case.dart';
import 'clinical_visit.dart';
import 'patient_transfer_request.dart';

/// Milestone event types recorded on a patient's clinical case timeline.
enum CaseTimelineEventType {
  visitCreated,
  visitCompleted,
  transferRequested,
  transferAccepted,
  transferCancelled,
  caseClosed,
}

extension CaseTimelineEventTypeExtension on CaseTimelineEventType {
  String get value {
    switch (this) {
      case CaseTimelineEventType.visitCreated:
        return 'VISIT_CREATED';
      case CaseTimelineEventType.visitCompleted:
        return 'VISIT_COMPLETED';
      case CaseTimelineEventType.transferRequested:
        return 'TRANSFER_REQUESTED';
      case CaseTimelineEventType.transferAccepted:
        return 'TRANSFER_ACCEPTED';
      case CaseTimelineEventType.transferCancelled:
        return 'TRANSFER_CANCELLED';
      case CaseTimelineEventType.caseClosed:
        return 'CASE_CLOSED';
    }
  }

  static CaseTimelineEventType fromString(String val) {
    switch (val.toUpperCase()) {
      case 'VISIT_COMPLETED':
        return CaseTimelineEventType.visitCompleted;
      case 'TRANSFER_REQUESTED':
        return CaseTimelineEventType.transferRequested;
      case 'TRANSFER_ACCEPTED':
        return CaseTimelineEventType.transferAccepted;
      case 'TRANSFER_CANCELLED':
        return CaseTimelineEventType.transferCancelled;
      case 'CASE_CLOSED':
        return CaseTimelineEventType.caseClosed;
      case 'VISIT_CREATED':
      default:
        return CaseTimelineEventType.visitCreated;
    }
  }
}

/// Chronological event on a Case's historical timeline.
class CaseTimelineEvent {
  final String eventId;
  final String caseId;
  final String? visitId;
  final CaseTimelineEventType eventType;
  final DateTime timestamp;
  final String title;
  final String? description;
  final String department;
  final String? doctorName;
  final String? doctorQualification;
  final int? visitNumber;
  final String? statusLabel;
  final Map<String, dynamic>? metadata;

  const CaseTimelineEvent({
    required this.eventId,
    required this.caseId,
    this.visitId,
    required this.eventType,
    required this.timestamp,
    required this.title,
    this.description,
    required this.department,
    this.doctorName,
    this.doctorQualification,
    this.visitNumber,
    this.statusLabel,
    this.metadata,
  });

  /// Builds a timeline event from a [ClinicalVisit].
  factory CaseTimelineEvent.fromClinicalVisit(
    ClinicalVisit visit, {
    String defaultDepartment = 'General Medicine',
  }) {
    final isCompleted = visit.isCompleted;
    final isTransferred = visit.isTransferred;
    final dept = defaultDepartment.isNotEmpty ? defaultDepartment : 'General Medicine';

    final eventType = isCompleted
        ? CaseTimelineEventType.visitCompleted
        : isTransferred
            ? CaseTimelineEventType.transferRequested
            : CaseTimelineEventType.visitCreated;

    final statusText = isCompleted
        ? 'COMPLETED'
        : isTransferred
            ? 'TRANSFERRED'
            : 'ACTIVE';

    final eventTime = isCompleted
        ? (visit.completedAt ?? visit.startedAt)
        : visit.startedAt;

    return CaseTimelineEvent(
      eventId: 'EVT-VIS-${visit.visitId}',
      caseId: visit.caseId,
      visitId: visit.visitId,
      eventType: eventType,
      timestamp: eventTime,
      title: 'Visit ${visit.visitNumber} • $dept',
      description: (visit.summaryText != null && visit.summaryText!.isNotEmpty)
          ? visit.summaryText
          : ((visit.chiefComplaint != null && visit.chiefComplaint!.isNotEmpty)
              ? visit.chiefComplaint
              : null),
      department: dept,
      doctorName: (visit.doctorName != null && visit.doctorName!.isNotEmpty)
          ? visit.doctorName
          : null,
      doctorQualification: visit.doctorQualification,
      visitNumber: visit.visitNumber,
      statusLabel: statusText,
      metadata: {
        'prescriptionsCount': visit.prescriptions.length,
        'investigationsCount': visit.investigationRequests.length,
      },
    );
  }

  /// Builds a timeline event from a [PatientTransferRequest].
  factory CaseTimelineEvent.fromTransferRequest(PatientTransferRequest transfer) {
    CaseTimelineEventType eventType;
    String statusText;
    DateTime eventTime;

    switch (transfer.status) {
      case TransferStatus.accepted:
        eventType = CaseTimelineEventType.transferAccepted;
        statusText = 'ACCEPTED';
        eventTime = transfer.acceptedAt ?? transfer.requestedAt;
        break;
      case TransferStatus.cancelled:
        eventType = CaseTimelineEventType.transferCancelled;
        statusText = 'CANCELLED';
        eventTime = transfer.cancelledAt ?? transfer.requestedAt;
        break;
      case TransferStatus.declined:
        eventType = CaseTimelineEventType.transferCancelled;
        statusText = 'DECLINED';
        eventTime = transfer.declinedAt ?? transfer.requestedAt;
        break;
      case TransferStatus.pending:
      case TransferStatus.inConsultation:
      case TransferStatus.completed:
        eventType = CaseTimelineEventType.transferRequested;
        statusText = 'PENDING';
        eventTime = transfer.requestedAt;
        break;
    }

    return CaseTimelineEvent(
      eventId: 'EVT-TRF-${transfer.transferId}',
      caseId: transfer.caseId,
      visitId: transfer.sourceVisitId,
      eventType: eventType,
      timestamp: eventTime,
      title: 'Transfer: ${transfer.sourceDepartment} → ${transfer.destinationDepartment}',
      description: transfer.reason,
      department: transfer.destinationDepartment,
      doctorName: transfer.sourceDoctorName,
      statusLabel: statusText,
      metadata: {
        'sourceDepartment': transfer.sourceDepartment,
        'destinationDepartment': transfer.destinationDepartment,
        'destinationDoctorName': transfer.destinationDoctorName,
      },
    );
  }

  /// Builds a timeline milestone event from a closed [ClinicalCase].
  factory CaseTimelineEvent.fromCaseClosure(
    ClinicalCase clinicalCase, {
    String? doctorName,
    String? doctorQualification,
  }) {
    final closeTime = clinicalCase.closedAt ?? clinicalCase.updatedAt;
    final docName = doctorName ?? clinicalCase.closedByDoctorName ?? clinicalCase.closedByDoctorId;

    return CaseTimelineEvent(
      eventId: 'EVT-CLOSE-${clinicalCase.caseId}',
      caseId: clinicalCase.caseId,
      eventType: CaseTimelineEventType.caseClosed,
      timestamp: closeTime,
      title: 'Case Closed • ${clinicalCase.domain}',
      description: (clinicalCase.closureNote != null && clinicalCase.closureNote!.isNotEmpty)
          ? clinicalCase.closureNote
          : 'Clinical problem resolved / Case concluded by attending physician.',
      department: clinicalCase.domain,
      doctorName: docName,
      doctorQualification: doctorQualification,
      statusLabel: 'CASE CLOSED',
      metadata: {
        'closedAt': closeTime.toIso8601String(),
        'closedByDoctorId': clinicalCase.closedByDoctorId,
        if (clinicalCase.closureNote != null) 'closureNote': clinicalCase.closureNote,
      },
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'caseId': caseId,
      if (visitId != null) 'visitId': visitId,
      'eventType': eventType.value,
      'timestamp': timestamp.toIso8601String(),
      'title': title,
      if (description != null) 'description': description,
      'department': department,
      if (doctorName != null) 'doctorName': doctorName,
      if (doctorQualification != null) 'doctorQualification': doctorQualification,
      if (visitNumber != null) 'visitNumber': visitNumber,
      if (statusLabel != null) 'statusLabel': statusLabel,
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory CaseTimelineEvent.fromMap(Map<String, dynamic> map) {
    return CaseTimelineEvent(
      eventId: map['eventId'] as String? ?? '',
      caseId: map['caseId'] as String? ?? '',
      visitId: map['visitId'] as String?,
      eventType: CaseTimelineEventTypeExtension.fromString(
        map['eventType'] as String? ?? 'VISIT_CREATED',
      ),
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      department: map['department'] as String? ?? '',
      doctorName: map['doctorName'] as String?,
      doctorQualification: map['doctorQualification'] as String?,
      visitNumber: map['visitNumber'] as int?,
      statusLabel: map['statusLabel'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/vital_reading.dart';

/// Operational lifecycle state of an inter-department patient transfer request.
enum TransferStatus {
  pending,
  accepted,
  inConsultation,
  completed,
  cancelled,
  declined;

  String get label {
    switch (this) {
      case TransferStatus.pending:
        return 'Pending';
      case TransferStatus.accepted:
        return 'Accepted';
      case TransferStatus.inConsultation:
        return 'In Consultation';
      case TransferStatus.completed:
        return 'Completed';
      case TransferStatus.cancelled:
        return 'Cancelled';
      case TransferStatus.declined:
        return 'Declined';
    }
  }

  bool get isPending => this == TransferStatus.pending;
  bool get isAccepted => this == TransferStatus.accepted;
  bool get isInConsultation => this == TransferStatus.inConsultation;
  bool get isCompleted => this == TransferStatus.completed;
  bool get isCancelled => this == TransferStatus.cancelled;
  bool get isDeclined => this == TransferStatus.declined;
}

/// Clinical model representing a doctor-initiated inter-department referral/transfer.
///
/// Principles:
/// - A transfer is an inter-department routing request, NOT a diagnosis.
/// - The Case strictly remains OPEN and the historical visits are preserved.
/// - Zero Aadhaar, OTP, password, auth tokens, or Gemini API keys stored.
class PatientTransferRequest {
  final String transferId;
  final String patientId;
  final String? patientName;
  final String caseId;
  final String sourceVisitId;
  final String sourceDoctorId;
  final String? sourceDoctorName;
  final String sourceDepartment;
  final String destinationDepartment;
  final String reason;
  final DateTime requestedAt;
  final TransferStatus status;

  // Privacy-safe operational telemetry for pre-assignment queue display
  final String? queueNumber;
  final int? patientAge;
  final String? patientGender;
  final VitalReading? vitals;

  // Assignment details populated upon atomic acceptance
  final String? destinationDoctorId;
  final String? destinationDoctorName;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? declinedAt;

  const PatientTransferRequest({
    required this.transferId,
    required this.patientId,
    this.patientName,
    required this.caseId,
    required this.sourceVisitId,
    required this.sourceDoctorId,
    this.sourceDoctorName,
    required this.sourceDepartment,
    required this.destinationDepartment,
    required this.reason,
    required this.requestedAt,
    this.status = TransferStatus.pending,
    this.queueNumber,
    this.patientAge,
    this.patientGender,
    this.vitals,
    this.destinationDoctorId,
    this.destinationDoctorName,
    this.acceptedAt,
    this.completedAt,
    this.cancelledAt,
    this.declinedAt,
  });

  bool get isPending => status == TransferStatus.pending;
  bool get isAccepted => status == TransferStatus.accepted;
  bool get isInConsultation => status == TransferStatus.inConsultation;
  bool get isCompleted => status == TransferStatus.completed;
  bool get isCancelled => status == TransferStatus.cancelled;
  bool get isDeclined => status == TransferStatus.declined;

  String get transferReason => reason;
  DateTime get createdAt => requestedAt;

  /// Validates transfer reason requirements (1 to 1000 characters, non-empty).
  bool get isReasonValid =>
      reason.trim().isNotEmpty && reason.trim().length <= 1000;

  /// Checks if destination department is distinct from source department.
  bool get isDestinationValid =>
      destinationDepartment.trim().toLowerCase() !=
      sourceDepartment.trim().toLowerCase();

  /// Whether the transfer can be cancelled by the source doctor (must be pending).
  bool canCancelBy(String doctorId) =>
      status == TransferStatus.pending && sourceDoctorId == doctorId;

  Map<String, dynamic> toMap() => toJson();

  factory PatientTransferRequest.fromMap(Map<String, dynamic> map, [String? id]) {
    final copy = Map<String, dynamic>.from(map);
    if (id != null) {
      copy['transferId'] = id;
    }
    return PatientTransferRequest.fromJson(copy);
  }

  PatientTransferRequest copyWith({
    String? transferId,
    String? patientId,
    String? patientName,
    String? caseId,
    String? sourceVisitId,
    String? sourceDoctorId,
    String? sourceDoctorName,
    String? sourceDepartment,
    String? destinationDepartment,
    String? reason,
    DateTime? requestedAt,
    TransferStatus? status,
    String? queueNumber,
    int? patientAge,
    String? patientGender,
    VitalReading? vitals,
    String? destinationDoctorId,
    String? destinationDoctorName,
    DateTime? acceptedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    DateTime? declinedAt,
  }) {
    return PatientTransferRequest(
      transferId: transferId ?? this.transferId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      caseId: caseId ?? this.caseId,
      sourceVisitId: sourceVisitId ?? this.sourceVisitId,
      sourceDoctorId: sourceDoctorId ?? this.sourceDoctorId,
      sourceDoctorName: sourceDoctorName ?? this.sourceDoctorName,
      sourceDepartment: sourceDepartment ?? this.sourceDepartment,
      destinationDepartment:
          destinationDepartment ?? this.destinationDepartment,
      reason: reason ?? this.reason,
      requestedAt: requestedAt ?? this.requestedAt,
      status: status ?? this.status,
      queueNumber: queueNumber ?? this.queueNumber,
      patientAge: patientAge ?? this.patientAge,
      patientGender: patientGender ?? this.patientGender,
      vitals: vitals ?? this.vitals,
      destinationDoctorId: destinationDoctorId ?? this.destinationDoctorId,
      destinationDoctorName:
          destinationDoctorName ?? this.destinationDoctorName,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      declinedAt: declinedAt ?? this.declinedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transferId': transferId,
      'patientId': patientId,
      if (patientName != null) 'patientName': patientName,
      'caseId': caseId,
      'sourceVisitId': sourceVisitId,
      'sourceDoctorId': sourceDoctorId,
      'sourceDoctorName': sourceDoctorName,
      'sourceDepartment': sourceDepartment,
      'destinationDepartment': destinationDepartment,
      'reason': reason,
      'requestedAt': requestedAt.toIso8601String(),
      'status': status.name,
      'queueNumber': queueNumber,
      'patientAge': patientAge,
      'patientGender': patientGender,
      'vitals': vitals?.toMap(),
      'destinationDoctorId': destinationDoctorId,
      'destinationDoctorName': destinationDoctorName,
      'acceptedAt': acceptedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'declinedAt': declinedAt?.toIso8601String(),
    };
  }

  factory PatientTransferRequest.fromJson(Map<String, dynamic> json) {
    TransferStatus parsedStatus = TransferStatus.pending;
    final statusStr = (json['status'] as String?)?.toLowerCase();
    for (final s in TransferStatus.values) {
      if (s.name.toLowerCase() == statusStr) {
        parsedStatus = s;
        break;
      }
    }

    return PatientTransferRequest(
      transferId: json['transferId'] as String,
      patientId: json['patientId'] as String,
      patientName: json['patientName'] as String?,
      caseId: json['caseId'] as String,
      sourceVisitId: json['sourceVisitId'] as String,
      sourceDoctorId: json['sourceDoctorId'] as String,
      sourceDoctorName: json['sourceDoctorName'] as String?,
      sourceDepartment: json['sourceDepartment'] as String,
      destinationDepartment: json['destinationDepartment'] as String,
      reason: json['reason'] as String? ?? '',
      requestedAt: json['requestedAt'] != null
          ? DateTime.parse(json['requestedAt'] as String)
          : DateTime.now(),
      status: parsedStatus,
      queueNumber: json['queueNumber'] as String?,
      patientAge: json['patientAge'] as int?,
      patientGender: json['patientGender'] as String?,
      vitals: json['vitals'] != null
          ? VitalReading.fromMap(json['vitals'] as Map<String, dynamic>)
          : null,
      destinationDoctorId: json['destinationDoctorId'] as String?,
      destinationDoctorName: json['destinationDoctorName'] as String?,
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'] as String)
          : null,
      declinedAt: json['declinedAt'] != null
          ? DateTime.parse(json['declinedAt'] as String)
          : null,
    );
  }

  factory PatientTransferRequest.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    DateTime parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseNullableTimestamp(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    TransferStatus parsedStatus = TransferStatus.pending;
    final statusStr = (data['status'] as String?)?.toLowerCase();
    for (final s in TransferStatus.values) {
      if (s.name.toLowerCase() == statusStr) {
        parsedStatus = s;
        break;
      }
    }

    return PatientTransferRequest(
      transferId: id,
      patientId: data['patientId'] as String? ?? '',
      patientName: data['patientName'] as String?,
      caseId: data['caseId'] as String? ?? '',
      sourceVisitId: data['sourceVisitId'] as String? ?? '',
      sourceDoctorId: data['sourceDoctorId'] as String? ?? '',
      sourceDoctorName: data['sourceDoctorName'] as String?,
      sourceDepartment: data['sourceDepartment'] as String? ?? '',
      destinationDepartment: data['destinationDepartment'] as String? ?? '',
      reason: data['reason'] as String? ?? '',
      requestedAt: parseTimestamp(data['requestedAt']),
      status: parsedStatus,
      queueNumber: data['queueNumber'] as String?,
      patientAge: data['patientAge'] as int?,
      patientGender: data['patientGender'] as String?,
      vitals: data['vitals'] != null
          ? VitalReading.fromMap(data['vitals'] as Map<String, dynamic>)
          : null,
      destinationDoctorId: data['destinationDoctorId'] as String?,
      destinationDoctorName: data['destinationDoctorName'] as String?,
      acceptedAt: parseNullableTimestamp(data['acceptedAt']),
      completedAt: parseNullableTimestamp(data['completedAt']),
      cancelledAt: parseNullableTimestamp(data['cancelledAt']),
      declinedAt: parseNullableTimestamp(data['declinedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'transferId': transferId,
      'patientId': patientId,
      if (patientName != null) 'patientName': patientName,
      'caseId': caseId,
      'sourceVisitId': sourceVisitId,
      'sourceDoctorId': sourceDoctorId,
      'sourceDoctorName': sourceDoctorName,
      'sourceDepartment': sourceDepartment,
      'destinationDepartment': destinationDepartment,
      'reason': reason,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'status': status.name,
      'queueNumber': queueNumber,
      'patientAge': patientAge,
      'patientGender': patientGender,
      'vitals': vitals?.toMap(),
      'destinationDoctorId': destinationDoctorId,
      'destinationDoctorName': destinationDoctorName,
      'acceptedAt':
          acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'cancelledAt':
          cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'declinedAt':
          declinedAt != null ? Timestamp.fromDate(declinedAt!) : null,
    };
  }
}

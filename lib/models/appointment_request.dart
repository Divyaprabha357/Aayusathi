import 'package:cloud_firestore/cloud_firestore.dart';
import 'vital_reading.dart';

/// Lifecycle status of an appointment / consultation request.
enum AppointmentStatus {
  pending,
  waiting,
  accepted,
  completed,
  cancelled,
}

/// Operational escalation status of an appointment request (Phase A7).
enum AppointmentEscalationStatus {
  none,
  escalated,
  resolved,
}

/// Mode of doctor preference requested by the patient.
enum PreferredDoctorMode {
  sameDoctor,
  alternativeDoctor,
  anyDoctor,
}

/// Model representing a patient's consultation request generated at the physical Kiosk
/// and persisted to Cloud Firestore under the `appointments` collection.
class AppointmentRequest {
  final String requestId;
  final String patientId;
  final String domainId;
  final String? previousDoctorId;
  final String? assignedDoctorId; // Internal only — NEVER displayed on the kiosk screen
  final PreferredDoctorMode preferredDoctorMode;
  final AppointmentStatus status;
  final AppointmentEscalationStatus escalationStatus;
  final String queueNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? escalatedAt;
  final DateTime? resolvedAt;
  final DateTime? assignedAt;
  final String source;
  final String sessionId;
  final VitalReading? vitals;

  const AppointmentRequest({
    required this.requestId,
    required this.patientId,
    required this.domainId,
    this.previousDoctorId,
    this.assignedDoctorId,
    required this.preferredDoctorMode,
    required this.status,
    this.escalationStatus = AppointmentEscalationStatus.none,
    required this.queueNumber,
    required this.createdAt,
    DateTime? updatedAt,
    this.escalatedAt,
    this.resolvedAt,
    this.assignedAt,
    this.source = 'KIOSK',
    required this.sessionId,
    this.vitals,
  }) : updatedAt = updatedAt ?? createdAt;

  /// Strict verification that queue format matches `^A-[0-9]{5}$`
  bool get hasValidQueueFormat => RegExp(r'^A-[0-9]{5}$').hasMatch(queueNumber);

  /// Whether this request has reached or crossed the 20-minute SLA threshold
  bool get isEscalated => escalationStatus == AppointmentEscalationStatus.escalated;

  /// Whether this request was previously escalated and subsequently assigned/resolved
  bool get isEscalationResolved => escalationStatus == AppointmentEscalationStatus.resolved;

  AppointmentRequest copyWith({
    String? requestId,
    String? patientId,
    String? domainId,
    String? previousDoctorId,
    String? assignedDoctorId,
    PreferredDoctorMode? preferredDoctorMode,
    AppointmentStatus? status,
    AppointmentEscalationStatus? escalationStatus,
    String? queueNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? escalatedAt,
    DateTime? resolvedAt,
    DateTime? assignedAt,
    String? source,
    String? sessionId,
    VitalReading? vitals,
  }) {
    return AppointmentRequest(
      requestId: requestId ?? this.requestId,
      patientId: patientId ?? this.patientId,
      domainId: domainId ?? this.domainId,
      previousDoctorId: previousDoctorId ?? this.previousDoctorId,
      assignedDoctorId: assignedDoctorId ?? this.assignedDoctorId,
      preferredDoctorMode: preferredDoctorMode ?? this.preferredDoctorMode,
      status: status ?? this.status,
      escalationStatus: escalationStatus ?? this.escalationStatus,
      queueNumber: queueNumber ?? this.queueNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      escalatedAt: escalatedAt ?? this.escalatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      assignedAt: assignedAt ?? this.assignedAt,
      source: source ?? this.source,
      sessionId: sessionId ?? this.sessionId,
      vitals: vitals ?? this.vitals,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'patientId': patientId,
      'domainId': domainId,
      'previousDoctorId': previousDoctorId,
      'assignedDoctorId': assignedDoctorId,
      'preferredDoctorMode': preferredDoctorMode.name,
      'status': status.name,
      'escalationStatus': escalationStatus.name,
      'queueNumber': queueNumber,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'escalatedAt': escalatedAt?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'assignedAt': assignedAt?.toIso8601String(),
      'source': source,
      'sessionId': sessionId,
      if (vitals != null) 'vitals': vitals!.toMap(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'requestId': requestId,
      'patientId': patientId,
      'domainId': domainId,
      'previousDoctorId': previousDoctorId,
      'assignedDoctorId': assignedDoctorId,
      'preferredDoctorMode': preferredDoctorMode.name,
      'status': status.name,
      'escalationStatus': escalationStatus.name,
      'queueNumber': queueNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'escalatedAt': escalatedAt != null ? Timestamp.fromDate(escalatedAt!) : null,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'assignedAt': assignedAt != null ? Timestamp.fromDate(assignedAt!) : null,
      'source': source,
      'sessionId': sessionId,
      if (vitals != null) 'vitals': vitals!.toMap(),
    };
  }

  factory AppointmentRequest.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    final created = parseDate(map['createdAt']);
    final updated = map['updatedAt'] != null ? parseDate(map['updatedAt']) : created;

    VitalReading? parsedVitals;
    if (map['vitals'] != null && map['vitals'] is Map) {
      try {
        parsedVitals = VitalReading.fromMap(map['vitals'] as Map<dynamic, dynamic>);
      } catch (_) {
        parsedVitals = null;
      }
    }

    return AppointmentRequest(
      requestId: map['requestId'] as String? ?? '',
      patientId: map['patientId'] as String? ?? '',
      domainId: map['domainId'] as String? ?? '',
      previousDoctorId: map['previousDoctorId'] as String?,
      assignedDoctorId: map['assignedDoctorId'] as String?,
      preferredDoctorMode: PreferredDoctorMode.values.firstWhere(
        (e) => e.name == map['preferredDoctorMode'],
        orElse: () => PreferredDoctorMode.anyDoctor,
      ),
      status: AppointmentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      escalationStatus: AppointmentEscalationStatus.values.firstWhere(
        (e) => e.name == map['escalationStatus'],
        orElse: () => AppointmentEscalationStatus.none,
      ),
      queueNumber: map['queueNumber'] as String? ?? '',
      createdAt: created,
      updatedAt: updated,
      escalatedAt: parseNullableDate(map['escalatedAt']),
      resolvedAt: parseNullableDate(map['resolvedAt']),
      assignedAt: parseNullableDate(map['assignedAt']),
      source: map['source'] as String? ?? 'KIOSK',
      sessionId: map['sessionId'] as String? ?? '',
      vitals: parsedVitals,
    );
  }

  factory AppointmentRequest.fromFirestore(Map<String, dynamic> data, [String? documentId]) {
    final map = Map<String, dynamic>.from(data);
    if (documentId != null && !map.containsKey('requestId')) {
      map['requestId'] = documentId;
    }
    return AppointmentRequest.fromMap(map);
  }

  @override
  String toString() =>
      'AppointmentRequest(id: $requestId, patient: $patientId, domain: $domainId, queue: $queueNumber, status: $status, escalation: $escalationStatus)';
}

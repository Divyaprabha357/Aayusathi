import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a patient's historical consultation visit record in a medical domain,
/// persisted under the `visits` collection in Cloud Firestore.
/// 
/// Strict Rule:
/// - NEW USER: Never query previous visit history.
/// - EXISTING PATIENT: Previous visit service may query visit history.
class PreviousVisitRecord {
  final String? visitId;
  final String patientId;
  final String domainId;
  final String previousDoctorId;
  final DateTime lastVisitDate;
  final String? appointmentId;
  final String status;

  const PreviousVisitRecord({
    this.visitId,
    required this.patientId,
    required this.domainId,
    required this.previousDoctorId,
    required this.lastVisitDate,
    this.appointmentId,
    this.status = 'completed',
  });

  PreviousVisitRecord copyWith({
    String? visitId,
    String? patientId,
    String? domainId,
    String? previousDoctorId,
    DateTime? lastVisitDate,
    String? appointmentId,
    String? status,
  }) {
    return PreviousVisitRecord(
      visitId: visitId ?? this.visitId,
      patientId: patientId ?? this.patientId,
      domainId: domainId ?? this.domainId,
      previousDoctorId: previousDoctorId ?? this.previousDoctorId,
      lastVisitDate: lastVisitDate ?? this.lastVisitDate,
      appointmentId: appointmentId ?? this.appointmentId,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'visitId': visitId,
      'patientId': patientId,
      'domainId': domainId,
      'previousDoctorId': previousDoctorId,
      'lastVisitDate': lastVisitDate.toIso8601String(),
      'appointmentId': appointmentId,
      'status': status,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (visitId != null) 'visitId': visitId,
      'patientId': patientId,
      'domainId': domainId,
      'doctorId': previousDoctorId,
      'previousDoctorId': previousDoctorId,
      'visitDate': Timestamp.fromDate(lastVisitDate),
      'lastVisitDate': Timestamp.fromDate(lastVisitDate),
      if (appointmentId != null) 'appointmentId': appointmentId,
      'status': status,
    };
  }

  factory PreviousVisitRecord.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return PreviousVisitRecord(
      visitId: map['visitId'] as String?,
      patientId: map['patientId'] as String? ?? '',
      domainId: map['domainId'] as String? ?? map['domain'] as String? ?? '',
      previousDoctorId: map['previousDoctorId'] as String? ?? map['doctorId'] as String? ?? '',
      lastVisitDate: parseDate(map['lastVisitDate'] ?? map['visitDate']),
      appointmentId: map['appointmentId'] as String?,
      status: map['status'] as String? ?? 'completed',
    );
  }

  factory PreviousVisitRecord.fromFirestore(Map<String, dynamic> data, [String? documentId]) {
    final map = Map<String, dynamic>.from(data);
    if (documentId != null && !map.containsKey('visitId')) {
      map['visitId'] = documentId;
    }
    return PreviousVisitRecord.fromMap(map);
  }

  @override
  String toString() =>
      'PreviousVisitRecord(patientId: $patientId, domainId: $domainId, previousDoctorId: $previousDoctorId, lastVisitDate: $lastVisitDate)';
}

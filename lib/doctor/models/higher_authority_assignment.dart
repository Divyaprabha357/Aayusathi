import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a higher-authority clinical case assignment.
enum HigherAuthorityAssignmentStatus {
  none,
  pending,
  assigned,
  accepted,
  completed;

  static HigherAuthorityAssignmentStatus fromString(String? val) {
    if (val == null || val.trim().isEmpty) return HigherAuthorityAssignmentStatus.none;
    return HigherAuthorityAssignmentStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.trim().toLowerCase(),
      orElse: () => HigherAuthorityAssignmentStatus.none,
    );
  }
}

/// Metadata record for a higher-authority case assignment.
///
/// Crucial Boundaries:
/// - Represents governance assignment metadata only.
/// - Does NOT duplicate clinical notes, visits, or patient identity records.
/// - The original Case (`caseId`) remains the single source of clinical truth.
class HigherAuthorityAssignment {
  final String assignmentId;
  final String caseId;
  final String patientId;
  final String sourceDoctorId;
  final String? sourceDoctorName;
  final String sourceDepartment;
  final int sourceAuthorityLevel;
  final String targetDoctorId;
  final String? targetDoctorName;
  final String targetDepartment;
  final int targetAuthorityLevel;
  final bool isCrossDepartment;
  final String? reason;
  final String assignedByAdminId;
  final DateTime assignedAt;
  final HigherAuthorityAssignmentStatus status;
  final DateTime? acceptedAt;
  final DateTime? completedAt;

  const HigherAuthorityAssignment({
    required this.assignmentId,
    required this.caseId,
    required this.patientId,
    required this.sourceDoctorId,
    this.sourceDoctorName,
    required this.sourceDepartment,
    required this.sourceAuthorityLevel,
    required this.targetDoctorId,
    this.targetDoctorName,
    required this.targetDepartment,
    required this.targetAuthorityLevel,
    this.isCrossDepartment = false,
    this.reason,
    required this.assignedByAdminId,
    required this.assignedAt,
    this.status = HigherAuthorityAssignmentStatus.assigned,
    this.acceptedAt,
    this.completedAt,
  });

  bool get isAccepted => status == HigherAuthorityAssignmentStatus.accepted;
  bool get isCompleted => status == HigherAuthorityAssignmentStatus.completed;

  HigherAuthorityAssignment copyWith({
    String? assignmentId,
    String? caseId,
    String? patientId,
    String? sourceDoctorId,
    String? sourceDoctorName,
    String? sourceDepartment,
    int? sourceAuthorityLevel,
    String? targetDoctorId,
    String? targetDoctorName,
    String? targetDepartment,
    int? targetAuthorityLevel,
    bool? isCrossDepartment,
    String? reason,
    String? assignedByAdminId,
    DateTime? assignedAt,
    HigherAuthorityAssignmentStatus? status,
    DateTime? acceptedAt,
    DateTime? completedAt,
  }) {
    return HigherAuthorityAssignment(
      assignmentId: assignmentId ?? this.assignmentId,
      caseId: caseId ?? this.caseId,
      patientId: patientId ?? this.patientId,
      sourceDoctorId: sourceDoctorId ?? this.sourceDoctorId,
      sourceDoctorName: sourceDoctorName ?? this.sourceDoctorName,
      sourceDepartment: sourceDepartment ?? this.sourceDepartment,
      sourceAuthorityLevel: sourceAuthorityLevel ?? this.sourceAuthorityLevel,
      targetDoctorId: targetDoctorId ?? this.targetDoctorId,
      targetDoctorName: targetDoctorName ?? this.targetDoctorName,
      targetDepartment: targetDepartment ?? this.targetDepartment,
      targetAuthorityLevel: targetAuthorityLevel ?? this.targetAuthorityLevel,
      isCrossDepartment: isCrossDepartment ?? this.isCrossDepartment,
      reason: reason ?? this.reason,
      assignedByAdminId: assignedByAdminId ?? this.assignedByAdminId,
      assignedAt: assignedAt ?? this.assignedAt,
      status: status ?? this.status,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assignmentId': assignmentId,
      'caseId': caseId,
      'patientId': patientId,
      'sourceDoctorId': sourceDoctorId,
      if (sourceDoctorName != null) 'sourceDoctorName': sourceDoctorName,
      'sourceDepartment': sourceDepartment,
      'sourceAuthorityLevel': sourceAuthorityLevel,
      'targetDoctorId': targetDoctorId,
      if (targetDoctorName != null) 'targetDoctorName': targetDoctorName,
      'targetDepartment': targetDepartment,
      'targetAuthorityLevel': targetAuthorityLevel,
      'isCrossDepartment': isCrossDepartment,
      if (reason != null) 'reason': reason,
      'assignedByAdminId': assignedByAdminId,
      'assignedAt': assignedAt.toIso8601String(),
      'status': status.name,
      if (acceptedAt != null) 'acceptedAt': acceptedAt!.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'assignmentId': assignmentId,
      'caseId': caseId,
      'patientId': patientId,
      'sourceDoctorId': sourceDoctorId,
      if (sourceDoctorName != null) 'sourceDoctorName': sourceDoctorName,
      'sourceDepartment': sourceDepartment,
      'sourceAuthorityLevel': sourceAuthorityLevel,
      'targetDoctorId': targetDoctorId,
      if (targetDoctorName != null) 'targetDoctorName': targetDoctorName,
      'targetDepartment': targetDepartment,
      'targetAuthorityLevel': targetAuthorityLevel,
      'isCrossDepartment': isCrossDepartment,
      if (reason != null) 'reason': reason,
      'assignedByAdminId': assignedByAdminId,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'status': status.name,
      if (acceptedAt != null) 'acceptedAt': Timestamp.fromDate(acceptedAt!),
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
    };
  }

  factory HigherAuthorityAssignment.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return HigherAuthorityAssignment(
      assignmentId: docId ?? (map['assignmentId'] as String? ?? ''),
      caseId: map['caseId'] as String? ?? '',
      patientId: map['patientId'] as String? ?? '',
      sourceDoctorId: map['sourceDoctorId'] as String? ?? '',
      sourceDoctorName: map['sourceDoctorName'] as String?,
      sourceDepartment: map['sourceDepartment'] as String? ?? '',
      sourceAuthorityLevel: map['sourceAuthorityLevel'] as int? ?? 1,
      targetDoctorId: map['targetDoctorId'] as String? ?? '',
      targetDoctorName: map['targetDoctorName'] as String?,
      targetDepartment: map['targetDepartment'] as String? ?? '',
      targetAuthorityLevel: map['targetAuthorityLevel'] as int? ?? 2,
      isCrossDepartment: map['isCrossDepartment'] as bool? ?? false,
      reason: map['reason'] as String?,
      assignedByAdminId: map['assignedByAdminId'] as String? ?? '',
      assignedAt: parseDate(map['assignedAt']),
      status: HigherAuthorityAssignmentStatus.fromString(map['status'] as String?),
      acceptedAt: map['acceptedAt'] != null ? parseDate(map['acceptedAt']) : null,
      completedAt: map['completedAt'] != null ? parseDate(map['completedAt']) : null,
    );
  }

  factory HigherAuthorityAssignment.fromFirestore(Map<String, dynamic> data, [String? docId]) {
    return HigherAuthorityAssignment.fromMap(data, docId);
  }
}

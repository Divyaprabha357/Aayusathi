import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'higher_authority_assignment.dart';

/// Lifecycle status of a clinical case.
enum ClinicalCaseStatus {
  open,
  closed,
}

/// Administrative and clinical escalation state of a clinical case.
enum CaseEscalationStatus {
  none,
  escalated,
  underReview,
  resolved,
}

/// Controlled clinical reasons for doctor-initiated case escalation.
enum CaseEscalationReason {
  clinicalDeterioration,
  repeatedVisitsNoResolution,
  higherAuthorityReview,
  doctorConcern,
  other,
}

/// Clinical case record representing an episode of care for a specific patient
/// within a medical domain.
///
/// Hierarchy:
/// PATIENT -> CLINICAL CASE -> CLINICAL VISITS
///
/// Security Rules:
/// - Strictly NO Aadhaar numbers or raw personal credentials stored.
/// - Case status remains `open` across multiple consultation visits.
/// - Completing a visit does NOT close the Case.
/// - Case escalation does NOT close the case or interrupt ongoing consultations.
class ClinicalCase {
  final String caseId;
  final String patientId;
  final String domain;
  final String title;
  final ClinicalCaseStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int visitCount;
  final String? relevantHistory;

  final DateTime? closedAt;
  final String? closedByDoctorId;
  final String? closedByDoctorName;
  final String? closureNote;

  // Phase A8: Clinical Case Escalation Metadata
  final CaseEscalationStatus escalationStatus;
  final CaseEscalationReason? escalationReason;
  final String? escalationNote;
  final DateTime? escalatedAt;
  final String? escalatedByDoctorId;
  final String? escalatedByDoctorName;
  final String? escalationSourceVisitId;
  final DateTime? adminReviewStartedAt;
  final String? adminReviewStartedBy;

  // Phase A10: Higher-Authority Doctor Assignment Metadata
  final String? higherAuthorityDoctorId;
  final String? higherAuthorityDoctorName;
  final String? higherAuthorityDepartment;
  final DateTime? higherAuthorityAssignedAt;
  final String? higherAuthorityAssignedBy;
  final HigherAuthorityAssignmentStatus higherAuthorityAssignmentStatus;
  final String? higherAuthorityAssignmentReason;
  final DateTime? higherAuthorityAcceptedAt;

  const ClinicalCase({
    required this.caseId,
    required this.patientId,
    required this.domain,
    required this.title,
    this.status = ClinicalCaseStatus.open,
    required this.createdAt,
    DateTime? updatedAt,
    this.visitCount = 0,
    this.relevantHistory,
    this.closedAt,
    this.closedByDoctorId,
    this.closedByDoctorName,
    this.closureNote,
    this.escalationStatus = CaseEscalationStatus.none,
    this.escalationReason,
    this.escalationNote,
    this.escalatedAt,
    this.escalatedByDoctorId,
    this.escalatedByDoctorName,
    this.escalationSourceVisitId,
    this.adminReviewStartedAt,
    this.adminReviewStartedBy,
    this.higherAuthorityDoctorId,
    this.higherAuthorityDoctorName,
    this.higherAuthorityDepartment,
    this.higherAuthorityAssignedAt,
    this.higherAuthorityAssignedBy,
    this.higherAuthorityAssignmentStatus = HigherAuthorityAssignmentStatus.none,
    this.higherAuthorityAssignmentReason,
    this.higherAuthorityAcceptedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  bool get isOpen => status == ClinicalCaseStatus.open;
  bool get isClosed => status == ClinicalCaseStatus.closed;
  bool get isNewCase => visitCount <= 1;
  bool get isExistingCase => visitCount > 1;

  // Escalation status helpers
  bool get isEscalated =>
      escalationStatus == CaseEscalationStatus.escalated ||
      escalationStatus == CaseEscalationStatus.underReview;
  bool get isUnderReview => escalationStatus == CaseEscalationStatus.underReview;
  bool get isEscalationResolved => escalationStatus == CaseEscalationStatus.resolved;

  // Higher-Authority Assignment helpers (Phase A10)
  bool get isAssignedToHigherAuthority =>
      higherAuthorityAssignmentStatus == HigherAuthorityAssignmentStatus.assigned ||
      higherAuthorityAssignmentStatus == HigherAuthorityAssignmentStatus.accepted;
  bool get isHigherAuthorityAccepted =>
      higherAuthorityAssignmentStatus == HigherAuthorityAssignmentStatus.accepted;

  ClinicalCase copyWith({
    String? caseId,
    String? patientId,
    String? domain,
    String? title,
    ClinicalCaseStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? visitCount,
    String? relevantHistory,
    DateTime? closedAt,
    String? closedByDoctorId,
    String? closedByDoctorName,
    String? closureNote,
    CaseEscalationStatus? escalationStatus,
    CaseEscalationReason? escalationReason,
    String? escalationNote,
    DateTime? escalatedAt,
    String? escalatedByDoctorId,
    String? escalatedByDoctorName,
    String? escalationSourceVisitId,
    DateTime? adminReviewStartedAt,
    String? adminReviewStartedBy,
    String? higherAuthorityDoctorId,
    String? higherAuthorityDoctorName,
    String? higherAuthorityDepartment,
    DateTime? higherAuthorityAssignedAt,
    String? higherAuthorityAssignedBy,
    HigherAuthorityAssignmentStatus? higherAuthorityAssignmentStatus,
    String? higherAuthorityAssignmentReason,
    DateTime? higherAuthorityAcceptedAt,
  }) {
    return ClinicalCase(
      caseId: caseId ?? this.caseId,
      patientId: patientId ?? this.patientId,
      domain: domain ?? this.domain,
      title: title ?? this.title,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      visitCount: visitCount ?? this.visitCount,
      relevantHistory: relevantHistory ?? this.relevantHistory,
      closedAt: closedAt ?? this.closedAt,
      closedByDoctorId: closedByDoctorId ?? this.closedByDoctorId,
      closedByDoctorName: closedByDoctorName ?? this.closedByDoctorName,
      closureNote: closureNote ?? this.closureNote,
      escalationStatus: escalationStatus ?? this.escalationStatus,
      escalationReason: escalationReason ?? this.escalationReason,
      escalationNote: escalationNote ?? this.escalationNote,
      escalatedAt: escalatedAt ?? this.escalatedAt,
      escalatedByDoctorId: escalatedByDoctorId ?? this.escalatedByDoctorId,
      escalatedByDoctorName: escalatedByDoctorName ?? this.escalatedByDoctorName,
      escalationSourceVisitId:
          escalationSourceVisitId ?? this.escalationSourceVisitId,
      adminReviewStartedAt: adminReviewStartedAt ?? this.adminReviewStartedAt,
      adminReviewStartedBy: adminReviewStartedBy ?? this.adminReviewStartedBy,
      higherAuthorityDoctorId:
          higherAuthorityDoctorId ?? this.higherAuthorityDoctorId,
      higherAuthorityDoctorName:
          higherAuthorityDoctorName ?? this.higherAuthorityDoctorName,
      higherAuthorityDepartment:
          higherAuthorityDepartment ?? this.higherAuthorityDepartment,
      higherAuthorityAssignedAt:
          higherAuthorityAssignedAt ?? this.higherAuthorityAssignedAt,
      higherAuthorityAssignedBy:
          higherAuthorityAssignedBy ?? this.higherAuthorityAssignedBy,
      higherAuthorityAssignmentStatus:
          higherAuthorityAssignmentStatus ?? this.higherAuthorityAssignmentStatus,
      higherAuthorityAssignmentReason:
          higherAuthorityAssignmentReason ?? this.higherAuthorityAssignmentReason,
      higherAuthorityAcceptedAt:
          higherAuthorityAcceptedAt ?? this.higherAuthorityAcceptedAt,
    );
  }

  /// Normalizes and formats department/domain strings into canonical hospital department titles.
  /// Handles case variations ("dermatology", "DERMATOLOGY", "Dermatology" -> "Dermatology"),
  /// snake_case ("general_medicine" -> "General Medicine"), and provides a safe fallback
  /// of "Department not available" without ever defaulting to "General Medicine".
  static String normalizeDepartment(dynamic raw) {
    if (raw == null) return 'Department not available';
    final str = raw.toString().trim();
    if (str.isEmpty || str.toLowerCase() == 'null') {
      return 'Department not available';
    }

    final lower = str.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ').trim();

    switch (lower) {
      case 'dermatology':
        return 'Dermatology';
      case 'cardiology':
        return 'Cardiology';
      case 'pediatrics':
      case 'paediatrics':
        return 'Pediatrics';
      case 'neurology':
        return 'Neurology';
      case 'gastroenterology':
        return 'Gastroenterology';
      case 'orthopedics':
      case 'orthopaedics':
        return 'Orthopedics';
      case 'ent':
      case 'e.n.t.':
      case 'ear nose throat':
        return 'ENT';
      case 'general medicine':
        return 'General Medicine';
      case 'department not available':
      case 'not available':
        return 'Department not available';
      default:
        // Title-case other medical disciplines gracefully
        return lower
            .split(' ')
            .where((w) => w.isNotEmpty)
            .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ');
    }
  }

  /// Patient-facing display string for the case department.
  String get displayDepartment => normalizeDepartment(domain);

  Map<String, dynamic> toMap() {
    return {
      'caseId': caseId,
      'patientId': patientId,
      'domain': domain,
      'department': domain,
      'title': title,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'visitCount': visitCount,
      'relevantHistory': relevantHistory,
      if (closedAt != null) 'closedAt': closedAt!.toIso8601String(),
      if (closedByDoctorId != null) 'closedByDoctorId': closedByDoctorId,
      if (closedByDoctorName != null) 'closedByDoctorName': closedByDoctorName,
      if (closureNote != null) 'closureNote': closureNote,
      'escalationStatus': escalationStatus.name,
      if (escalationReason != null) 'escalationReason': escalationReason!.name,
      if (escalationNote != null) 'escalationNote': escalationNote,
      if (escalatedAt != null) 'escalatedAt': escalatedAt!.toIso8601String(),
      if (escalatedByDoctorId != null) 'escalatedByDoctorId': escalatedByDoctorId,
      if (escalatedByDoctorName != null)
        'escalatedByDoctorName': escalatedByDoctorName,
      if (escalationSourceVisitId != null)
        'escalationSourceVisitId': escalationSourceVisitId,
      if (adminReviewStartedAt != null)
        'adminReviewStartedAt': adminReviewStartedAt!.toIso8601String(),
      if (adminReviewStartedBy != null)
        'adminReviewStartedBy': adminReviewStartedBy,
      if (higherAuthorityDoctorId != null)
        'higherAuthorityDoctorId': higherAuthorityDoctorId,
      if (higherAuthorityDoctorName != null)
        'higherAuthorityDoctorName': higherAuthorityDoctorName,
      if (higherAuthorityDepartment != null)
        'higherAuthorityDepartment': higherAuthorityDepartment,
      if (higherAuthorityAssignedAt != null)
        'higherAuthorityAssignedAt': higherAuthorityAssignedAt!.toIso8601String(),
      if (higherAuthorityAssignedBy != null)
        'higherAuthorityAssignedBy': higherAuthorityAssignedBy,
      'higherAuthorityAssignmentStatus': higherAuthorityAssignmentStatus.name,
      if (higherAuthorityAssignmentReason != null)
        'higherAuthorityAssignmentReason': higherAuthorityAssignmentReason,
      if (higherAuthorityAcceptedAt != null)
        'higherAuthorityAcceptedAt': higherAuthorityAcceptedAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'caseId': caseId,
      'patientId': patientId,
      'domain': domain,
      'department': domain,
      'title': title,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'visitCount': visitCount,
      if (relevantHistory != null) 'relevantHistory': relevantHistory,
      if (closedAt != null) 'closedAt': Timestamp.fromDate(closedAt!),
      if (closedByDoctorId != null) 'closedByDoctorId': closedByDoctorId,
      if (closedByDoctorName != null) 'closedByDoctorName': closedByDoctorName,
      if (closureNote != null) 'closureNote': closureNote,
      'escalationStatus': escalationStatus.name,
      if (escalationReason != null) 'escalationReason': escalationReason!.name,
      if (escalationNote != null) 'escalationNote': escalationNote,
      if (escalatedAt != null) 'escalatedAt': Timestamp.fromDate(escalatedAt!),
      if (escalatedByDoctorId != null) 'escalatedByDoctorId': escalatedByDoctorId,
      if (escalatedByDoctorName != null)
        'escalatedByDoctorName': escalatedByDoctorName,
      if (escalationSourceVisitId != null)
        'escalationSourceVisitId': escalationSourceVisitId,
      if (adminReviewStartedAt != null)
        'adminReviewStartedAt': Timestamp.fromDate(adminReviewStartedAt!),
      if (adminReviewStartedBy != null)
        'adminReviewStartedBy': adminReviewStartedBy,
      if (higherAuthorityDoctorId != null)
        'higherAuthorityDoctorId': higherAuthorityDoctorId,
      if (higherAuthorityDoctorName != null)
        'higherAuthorityDoctorName': higherAuthorityDoctorName,
      if (higherAuthorityDepartment != null)
        'higherAuthorityDepartment': higherAuthorityDepartment,
      if (higherAuthorityAssignedAt != null)
        'higherAuthorityAssignedAt': Timestamp.fromDate(higherAuthorityAssignedAt!),
      if (higherAuthorityAssignedBy != null)
        'higherAuthorityAssignedBy': higherAuthorityAssignedBy,
      'higherAuthorityAssignmentStatus': higherAuthorityAssignmentStatus.name,
      if (higherAuthorityAssignmentReason != null)
        'higherAuthorityAssignmentReason': higherAuthorityAssignmentReason,
      if (higherAuthorityAcceptedAt != null)
        'higherAuthorityAcceptedAt': Timestamp.fromDate(higherAuthorityAcceptedAt!),
    };
  }

  factory ClinicalCase.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    DateTime? parseOptionalDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    final statusStr = map['status']?.toString() ?? 'open';
    final parsedStatus = (statusStr.toLowerCase() == 'closed' || statusStr == 'ClinicalCaseStatus.closed')
        ? ClinicalCaseStatus.closed
        : ClinicalCaseStatus.open;

    // Escalation Status parsing
    final escStatusStr = map['escalationStatus']?.toString() ?? 'none';
    CaseEscalationStatus parsedEscStatus = CaseEscalationStatus.none;
    for (final e in CaseEscalationStatus.values) {
      if (e.name.toLowerCase() == escStatusStr.toLowerCase()) {
        parsedEscStatus = e;
        break;
      }
    }

    // Escalation Reason parsing
    CaseEscalationReason? parsedReason;
    final reasonStr = map['escalationReason']?.toString();
    if (reasonStr != null && reasonStr.isNotEmpty) {
      for (final r in CaseEscalationReason.values) {
        if (r.name.toLowerCase() == reasonStr.toLowerCase()) {
          parsedReason = r;
          break;
        }
      }
    }

    // Higher-Authority Assignment Status parsing
    final haStatus = HigherAuthorityAssignmentStatus.fromString(
      map['higherAuthorityAssignmentStatus'] as String?,
    );

    final resolvedTitle = map['title'] as String? ??
        map['problemLabel'] as String? ??
        map['chiefComplaint'] as String? ??
        'Clinical Case';

    // Authoritative department / domain resolution across all schema variants
    final dynamic rawDomain = map['domain'] ??
        map['domainId'] ??
        map['department'] ??
        map['departmentId'] ??
        map['caseDepartment'] ??
        map['visitDepartment'] ??
        map['specialty'] ??
        map['speciality'];

    if (rawDomain == null || rawDomain.toString().trim().isEmpty) {
      debugPrint(
        '[ClinicalCase] Warning: Missing department in clinical case ${map["caseId"] ?? "unknown"}. Using safe fallback.',
      );
    }

    final resolvedDomain = normalizeDepartment(rawDomain);

    return ClinicalCase(
      caseId: map['caseId'] as String? ?? '',
      patientId: map['patientId'] as String? ?? '',
      domain: resolvedDomain,
      title: resolvedTitle.isNotEmpty ? resolvedTitle : 'Clinical Case',
      status: parsedStatus,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt'] ?? map['createdAt']),
      visitCount: (map['visitCount'] as num?)?.toInt() ?? 0,
      relevantHistory: map['relevantHistory'] as String?,
      closedAt: parseOptionalDate(map['closedAt']),
      closedByDoctorId: map['closedByDoctorId'] as String?,
      closedByDoctorName: map['closedByDoctorName'] as String?,
      closureNote: map['closureNote'] as String?,
      escalationStatus: parsedEscStatus,
      escalationReason: parsedReason,
      escalationNote: map['escalationNote'] as String?,
      escalatedAt: parseOptionalDate(map['escalatedAt']),
      escalatedByDoctorId: map['escalatedByDoctorId'] as String?,
      escalatedByDoctorName: map['escalatedByDoctorName'] as String?,
      escalationSourceVisitId: map['escalationSourceVisitId'] as String?,
      adminReviewStartedAt: parseOptionalDate(map['adminReviewStartedAt']),
      adminReviewStartedBy: map['adminReviewStartedBy'] as String?,
      higherAuthorityDoctorId: map['higherAuthorityDoctorId'] as String?,
      higherAuthorityDoctorName: map['higherAuthorityDoctorName'] as String?,
      higherAuthorityDepartment: map['higherAuthorityDepartment'] as String?,
      higherAuthorityAssignedAt: parseOptionalDate(map['higherAuthorityAssignedAt']),
      higherAuthorityAssignedBy: map['higherAuthorityAssignedBy'] as String?,
      higherAuthorityAssignmentStatus: haStatus,
      higherAuthorityAssignmentReason: map['higherAuthorityAssignmentReason'] as String?,
      higherAuthorityAcceptedAt: parseOptionalDate(map['higherAuthorityAcceptedAt']),
    );
  }

  factory ClinicalCase.fromFirestore(Map<String, dynamic> data, [String? documentId]) {
    final map = Map<String, dynamic>.from(data);
    if (documentId != null) {
      final existing = map['caseId'] as String?;
      if (existing == null || existing.trim().isEmpty) {
        map['caseId'] = documentId;
      }
    }
    return ClinicalCase.fromMap(map);
  }

  @override
  String toString() =>
      'ClinicalCase(id: $caseId, patient: $patientId, domain: $domain, title: $title, status: $status, visits: $visitCount, escalation: $escalationStatus, higherAuthority: $higherAuthorityAssignmentStatus)';
}


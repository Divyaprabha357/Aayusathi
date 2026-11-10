import 'package:cloud_firestore/cloud_firestore.dart';

/// Clinical category of a requested diagnostic investigation.
enum InvestigationCategory {
  lab,
  radiology,
  diagnostic,
  other;

  String get label {
    switch (this) {
      case InvestigationCategory.lab:
        return 'Lab';
      case InvestigationCategory.radiology:
        return 'Radiology';
      case InvestigationCategory.diagnostic:
        return 'Diagnostic';
      case InvestigationCategory.other:
        return 'Other';
    }
  }

  static InvestigationCategory fromString(String? val) {
    if (val == null) return InvestigationCategory.diagnostic;
    final lower = val.toLowerCase().trim();
    switch (lower) {
      case 'lab':
      case 'laboratory':
        return InvestigationCategory.lab;
      case 'radiology':
      case 'imaging':
        return InvestigationCategory.radiology;
      case 'diagnostic':
        return InvestigationCategory.diagnostic;
      default:
        return InvestigationCategory.other;
    }
  }
}

/// Priority of a requested diagnostic investigation.
enum InvestigationPriority {
  required,
  asAdvised;

  String get label {
    switch (this) {
      case InvestigationPriority.required:
        return 'Required';
      case InvestigationPriority.asAdvised:
        return 'As Advised';
    }
  }

  static InvestigationPriority fromString(String? val) {
    if (val == null) return InvestigationPriority.required;
    final lower = val.toLowerCase().trim();
    if (lower == 'asadvised' || lower == 'as_advised' || lower == 'as advised') {
      return InvestigationPriority.asAdvised;
    }
    return InvestigationPriority.required;
  }
}

/// Lifecycle status of an investigation request.
enum InvestigationStatus {
  pendingUpload,
  uploaded,
  reviewed,
  cancelled;

  String get label {
    switch (this) {
      case InvestigationStatus.pendingUpload:
        return 'Pending Upload';
      case InvestigationStatus.uploaded:
        return 'Uploaded';
      case InvestigationStatus.reviewed:
        return 'Reviewed';
      case InvestigationStatus.cancelled:
        return 'Cancelled';
    }
  }

  static InvestigationStatus fromString(String? val) {
    if (val == null) return InvestigationStatus.pendingUpload;
    final lower = val.toLowerCase().trim();
    switch (lower) {
      case 'uploaded':
        return InvestigationStatus.uploaded;
      case 'reviewed':
        return InvestigationStatus.reviewed;
      case 'cancelled':
      case 'canceled':
        return InvestigationStatus.cancelled;
      default:
        return InvestigationStatus.pendingUpload;
    }
  }
}

/// Model representing a doctor's request for diagnostic investigations (e.g. ECG, CBC, X-Ray)
/// within a clinical consultation encounter.
///
/// Hierarchy:
/// `patients/{patientId}/cases/{caseId}/visits/{visitId}/investigations/{investigationId}`
class InvestigationRequest {
  final String requestId;
  final String? patientId;
  final String? caseId;
  final String? visitId;
  final String? requestedByDoctorId;
  final String? department;
  final String name;
  final InvestigationCategory category;
  final InvestigationPriority priority;
  final InvestigationStatus status;
  final DateTime requestedAt;
  final DateTime? uploadedAt;
  final DateTime? reviewedAt;
  final String? reviewedByDoctorId;
  final String? uploadedReportId;
  final String? notes;

  const InvestigationRequest({
    required this.requestId,
    this.patientId,
    this.caseId,
    this.visitId,
    this.requestedByDoctorId,
    this.department,
    required this.name,
    this.category = InvestigationCategory.diagnostic,
    this.priority = InvestigationPriority.required,
    this.status = InvestigationStatus.pendingUpload,
    required this.requestedAt,
    this.uploadedAt,
    this.reviewedAt,
    this.reviewedByDoctorId,
    this.uploadedReportId,
    this.notes,
  });

  /// Alias for requestId to match D11 specification
  String get investigationId => requestId;

  bool get isRequired => priority == InvestigationPriority.required;
  bool get isAsAdvised => priority == InvestigationPriority.asAdvised;
  bool get isPendingUpload => status == InvestigationStatus.pendingUpload;
  bool get isUploaded => status == InvestigationStatus.uploaded;
  bool get isReviewed => status == InvestigationStatus.reviewed;
  bool get isCancelled => status == InvestigationStatus.cancelled;

  InvestigationRequest copyWith({
    String? requestId,
    String? patientId,
    String? caseId,
    String? visitId,
    String? requestedByDoctorId,
    String? department,
    String? name,
    InvestigationCategory? category,
    InvestigationPriority? priority,
    InvestigationStatus? status,
    DateTime? requestedAt,
    DateTime? uploadedAt,
    DateTime? reviewedAt,
    String? reviewedByDoctorId,
    String? uploadedReportId,
    String? notes,
  }) {
    return InvestigationRequest(
      requestId: requestId ?? this.requestId,
      patientId: patientId ?? this.patientId,
      caseId: caseId ?? this.caseId,
      visitId: visitId ?? this.visitId,
      requestedByDoctorId: requestedByDoctorId ?? this.requestedByDoctorId,
      department: department ?? this.department,
      name: name ?? this.name,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedByDoctorId: reviewedByDoctorId ?? this.reviewedByDoctorId,
      uploadedReportId: uploadedReportId ?? this.uploadedReportId,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'investigationId': requestId,
      if (patientId != null) 'patientId': patientId,
      if (caseId != null) 'caseId': caseId,
      if (visitId != null) 'visitId': visitId,
      if (requestedByDoctorId != null) 'requestedByDoctorId': requestedByDoctorId,
      if (department != null) 'department': department,
      'name': name,
      'category': category.name,
      'priority': priority.name,
      'status': status.name,
      'requestedAt': requestedAt.toIso8601String(),
      if (uploadedAt != null) 'uploadedAt': uploadedAt!.toIso8601String(),
      if (reviewedAt != null) 'reviewedAt': reviewedAt!.toIso8601String(),
      if (reviewedByDoctorId != null) 'reviewedByDoctorId': reviewedByDoctorId,
      if (uploadedReportId != null) 'uploadedReportId': uploadedReportId,
      if (notes != null) 'notes': notes,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'requestId': requestId,
      'investigationId': requestId,
      if (patientId != null) 'patientId': patientId,
      if (caseId != null) 'caseId': caseId,
      if (visitId != null) 'visitId': visitId,
      if (requestedByDoctorId != null) 'requestedByDoctorId': requestedByDoctorId,
      if (department != null) 'department': department,
      'name': name,
      'category': category.name,
      'priority': priority.name,
      'status': status.name,
      'requestedAt': Timestamp.fromDate(requestedAt),
      if (uploadedAt != null) 'uploadedAt': Timestamp.fromDate(uploadedAt!),
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      if (reviewedByDoctorId != null) 'reviewedByDoctorId': reviewedByDoctorId,
      if (uploadedReportId != null) 'uploadedReportId': uploadedReportId,
      if (notes != null) 'notes': notes,
    };
  }

  factory InvestigationRequest.fromMap(Map<String, dynamic> map) {
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

    final id = map['investigationId'] as String? ??
        map['requestId'] as String? ??
        '';

    return InvestigationRequest(
      requestId: id,
      patientId: map['patientId'] as String?,
      caseId: map['caseId'] as String?,
      visitId: map['visitId'] as String?,
      requestedByDoctorId: map['requestedByDoctorId'] as String?,
      department: map['department'] as String?,
      name: map['name'] as String? ?? '',
      category: InvestigationCategory.fromString(map['category'] as String?),
      priority: InvestigationPriority.fromString(map['priority'] as String?),
      status: InvestigationStatus.fromString(map['status'] as String?),
      requestedAt: parseDate(map['requestedAt']),
      uploadedAt: parseOptionalDate(map['uploadedAt']),
      reviewedAt: parseOptionalDate(map['reviewedAt']),
      reviewedByDoctorId: map['reviewedByDoctorId'] as String?,
      uploadedReportId: map['uploadedReportId'] as String?,
      notes: map['notes'] as String?,
    );
  }

  factory InvestigationRequest.fromFirestore(
      Map<String, dynamic> data, [String? documentId]) {
    final map = Map<String, dynamic>.from(data);
    if (documentId != null && !map.containsKey('requestId') && !map.containsKey('investigationId')) {
      map['requestId'] = documentId;
      map['investigationId'] = documentId;
    }
    return InvestigationRequest.fromMap(map);
  }

  @override
  String toString() =>
      'InvestigationRequest(id: $requestId, name: $name, category: ${category.name}, priority: ${priority.name}, status: ${status.name})';
}

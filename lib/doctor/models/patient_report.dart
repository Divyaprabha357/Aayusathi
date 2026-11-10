import 'package:cloud_firestore/cloud_firestore.dart';

/// Clinical category of a patient medical report.
enum PatientReportType {
  lab,
  radiology,
  diagnostic,
  other,
}

/// Workflow status of a patient diagnostic report.
enum PatientReportStatus {
  available,
  requested,
  uploaded,
}

/// Model representing a patient medical report or diagnostic test in the workspace.
///
/// Phase D7 establishes the foundation model for displaying available, requested,
/// and uploaded reports.
class PatientReport {
  final String reportId;
  final String patientId;
  final String? caseId;
  final String title;
  final PatientReportType type;
  final PatientReportStatus status;
  final DateTime date;
  final String? summary;

  const PatientReport({
    required this.reportId,
    required this.patientId,
    this.caseId,
    required this.title,
    this.type = PatientReportType.diagnostic,
    this.status = PatientReportStatus.available,
    required this.date,
    this.summary,
  });

  bool get isAvailable => status == PatientReportStatus.available;
  bool get isRequested => status == PatientReportStatus.requested;
  bool get isUploaded => status == PatientReportStatus.uploaded;

  PatientReport copyWith({
    String? reportId,
    String? patientId,
    String? caseId,
    String? title,
    PatientReportType? type,
    PatientReportStatus? status,
    DateTime? date,
    String? summary,
  }) {
    return PatientReport(
      reportId: reportId ?? this.reportId,
      patientId: patientId ?? this.patientId,
      caseId: caseId ?? this.caseId,
      title: title ?? this.title,
      type: type ?? this.type,
      status: status ?? this.status,
      date: date ?? this.date,
      summary: summary ?? this.summary,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'patientId': patientId,
      'caseId': caseId,
      'title': title,
      'type': type.name,
      'status': status.name,
      'date': date.toIso8601String(),
      'summary': summary,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reportId': reportId,
      'patientId': patientId,
      if (caseId != null) 'caseId': caseId,
      'title': title,
      'type': type.name,
      'status': status.name,
      'date': Timestamp.fromDate(date),
      if (summary != null) 'summary': summary,
    };
  }

  factory PatientReport.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return PatientReport(
      reportId: map['reportId'] as String? ?? '',
      patientId: map['patientId'] as String? ?? '',
      caseId: map['caseId'] as String?,
      title: map['title'] as String? ?? 'Medical Report',
      type: PatientReportType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => PatientReportType.diagnostic,
      ),
      status: PatientReportStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PatientReportStatus.available,
      ),
      date: parseDate(map['date']),
      summary: map['summary'] as String?,
    );
  }

  factory PatientReport.fromFirestore(Map<String, dynamic> data, [String? documentId]) {
    final map = Map<String, dynamic>.from(data);
    if (documentId != null && !map.containsKey('reportId')) {
      map['reportId'] = documentId;
    }
    return PatientReport.fromMap(map);
  }
}

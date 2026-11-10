import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/vital_reading.dart';
import '../../patient/services/patient_follow_up_parser.dart';
import 'clinical_case.dart';
import 'investigation_request.dart';
import 'prescription_item.dart';

/// Lifecycle status of a consultation encounter visit.
enum ClinicalVisitStatus {
  active,
  completed,
  cancelled,
  transferred,
}

/// Status of the doctor-approved clinical visit summary.
enum SummaryApprovalStatus {
  draft,
  reviewRequired,
  approvedByDoctor;

  String get label {
    switch (this) {
      case SummaryApprovalStatus.draft:
        return 'DRAFT';
      case SummaryApprovalStatus.reviewRequired:
        return 'REVIEW REQUIRED';
      case SummaryApprovalStatus.approvedByDoctor:
        return 'APPROVED BY DOCTOR';
    }
  }
}

/// Model representing a single consultation encounter visit under a [ClinicalCase].
///
/// Hierarchy:
/// PATIENT -> CLINICAL CASE -> CLINICAL VISITS
///
/// Rules:
/// - Visit numbers are strictly scoped to the parent Case (Visit 1, Visit 2, ...).
/// - Completing a visit does NOT close the parent Case.
/// - Strictly NO Aadhaar numbers or raw sensitive credentials stored.
/// - Encapsulates the official 9-section AAYUSATHI Doctor Visit Report + Prescriptions.
class ClinicalVisit {
  final String visitId;
  final String caseId;
  final String patientId;
  final String doctorId;
  final String? doctorName;
  final String? doctorQualification;
  final String? appointmentId;
  final String? department;
  final int visitNumber;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? completedByDoctorId;
  final ClinicalVisitStatus status;

  // Structured Consultation Documentation (8 Official Clinical Fields)
  final String? chiefComplaint;
  final String? onsetDuration;
  final String? associatedSymptoms;
  final String? medicalHistory;
  final String? currentMedication;
  final String? clinicalObservations;
  final String? assessment;
  final String? plan;

  // Prescriptions (Phase D9.1)
  final List<PrescriptionItem> prescriptions;

  // Doctor-Approved Visit Summary
  final String? summary; // Legacy & fallback alias for summaryText
  final String? summaryText;
  final SummaryApprovalStatus summaryApprovalStatus;
  final String? approvedByDoctorId;
  final DateTime? approvedAt;

  // Plan / Follow-up
  final String? followUp;
  final String? patientInstructions;

  // Diagnostic / Lab Investigation Requests
  final List<InvestigationRequest> investigationRequests;

  // Clinical Vitals Encounter Telemetry
  final VitalReading? vitals;

  const ClinicalVisit({
    required this.visitId,
    required this.caseId,
    required this.patientId,
    required this.doctorId,
    this.doctorName,
    this.doctorQualification,
    this.appointmentId,
    this.department,
    required this.visitNumber,
    required this.startedAt,
    this.completedAt,
    this.completedByDoctorId,
    this.status = ClinicalVisitStatus.active,
    this.chiefComplaint,
    this.onsetDuration,
    this.associatedSymptoms,
    this.medicalHistory,
    this.currentMedication,
    this.clinicalObservations,
    this.assessment,
    this.plan,
    this.prescriptions = const [],
    this.summary,
    this.summaryText,
    this.summaryApprovalStatus = SummaryApprovalStatus.draft,
    this.approvedByDoctorId,
    this.approvedAt,
    this.followUp,
    this.patientInstructions,
    this.investigationRequests = const [],
    this.vitals,
  });

  bool get isActive => status == ClinicalVisitStatus.active;
  bool get isCompleted => status == ClinicalVisitStatus.completed;
  bool get isCancelled => status == ClinicalVisitStatus.cancelled;
  bool get isTransferred => status == ClinicalVisitStatus.transferred;

  /// Scheduled clinical follow-up date parsed from the Doctor's follow-up instruction.
  DateTime? get followUpDate {
    if (followUp == null || followUp!.trim().isEmpty) return null;
    return PatientFollowUpParser.parse(
      followUp!,
      referenceDate: completedAt ?? startedAt,
    );
  }

  /// Effective clinical summary text
  String get effectiveSummary =>
      (summaryText != null && summaryText!.trim().isNotEmpty)
          ? summaryText!
          : (summary ?? '');

  /// Whether the summary has been explicitly approved by the attending doctor.
  bool get isSummaryApproved =>
      summaryApprovalStatus == SummaryApprovalStatus.approvedByDoctor;

  /// Canonical alias indicating whether this clinical visit is approved.
  bool get isApproved => isSummaryApproved;

  /// Validates that all 8 required structured consultation fields are non-empty.
  bool get areConsultationFieldsComplete {
    return (chiefComplaint?.trim().isNotEmpty == true) &&
        (onsetDuration?.trim().isNotEmpty == true) &&
        (associatedSymptoms?.trim().isNotEmpty == true) &&
        (medicalHistory?.trim().isNotEmpty == true) &&
        (currentMedication?.trim().isNotEmpty == true) &&
        (clinicalObservations?.trim().isNotEmpty == true) &&
        (assessment?.trim().isNotEmpty == true) &&
        (plan?.trim().isNotEmpty == true);
  }

  /// Whether all defined prescriptions are completely filled.
  bool get arePrescriptionsValid => prescriptions.every((p) => p.isComplete);

  /// Patient-facing display string for the visit department.
  String get displayDepartment {
    if (department != null && department!.trim().isNotEmpty) {
      return ClinicalCase.normalizeDepartment(department);
    }
    return 'Department not available';
  }

  /// Returns the human-readable list of missing requirements for visit completion.
  List<String> get missingRequirements {
    final missing = <String>[];
    if (chiefComplaint?.trim().isNotEmpty != true) {
      missing.add('Chief Complaint');
    }
    if (onsetDuration?.trim().isNotEmpty != true) {
      missing.add('Onset / Duration');
    }
    if (associatedSymptoms?.trim().isNotEmpty != true) {
      missing.add('Associated Symptoms');
    }
    if (medicalHistory?.trim().isNotEmpty != true) {
      missing.add('Medical History');
    }
    if (currentMedication?.trim().isNotEmpty != true) {
      missing.add('Current Medication');
    }
    if (clinicalObservations?.trim().isNotEmpty != true) {
      missing.add('Clinical Observations');
    }
    if (assessment?.trim().isNotEmpty != true) {
      missing.add('Assessment');
    }
    if (plan?.trim().isNotEmpty != true) {
      missing.add('Plan');
    }
    for (int i = 0; i < prescriptions.length; i++) {
      if (!prescriptions[i].isComplete) {
        final fields = prescriptions[i].missingFields.join(', ');
        missing.add('Medicine ${i + 1} ($fields)');
      }
    }
    if (effectiveSummary.trim().isEmpty) {
      missing.add('Visit Summary');
    } else if (!isSummaryApproved) {
      missing.add('Doctor Summary Approval');
    }
    return missing;
  }

  /// Whether the visit satisfies all requirements for completion.
  bool get canCompleteVisit =>
      areConsultationFieldsComplete &&
      arePrescriptionsValid &&
      effectiveSummary.trim().isNotEmpty &&
      isSummaryApproved;

  ClinicalVisit copyWith({
    String? visitId,
    String? caseId,
    String? patientId,
    String? doctorId,
    String? doctorName,
    String? doctorQualification,
    String? appointmentId,
    String? department,
    int? visitNumber,
    DateTime? startedAt,
    DateTime? completedAt,
    String? completedByDoctorId,
    ClinicalVisitStatus? status,
    String? chiefComplaint,
    String? onsetDuration,
    String? associatedSymptoms,
    String? medicalHistory,
    String? currentMedication,
    String? clinicalObservations,
    String? assessment,
    String? plan,
    List<PrescriptionItem>? prescriptions,
    String? summary,
    String? summaryText,
    SummaryApprovalStatus? summaryApprovalStatus,
    String? approvedByDoctorId,
    DateTime? approvedAt,
    String? followUp,
    String? patientInstructions,
    List<InvestigationRequest>? investigationRequests,
    VitalReading? vitals,
  }) {
    return ClinicalVisit(
      visitId: visitId ?? this.visitId,
      caseId: caseId ?? this.caseId,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorQualification: doctorQualification ?? this.doctorQualification,
      appointmentId: appointmentId ?? this.appointmentId,
      department: department ?? this.department,
      visitNumber: visitNumber ?? this.visitNumber,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      completedByDoctorId: completedByDoctorId ?? this.completedByDoctorId,
      status: status ?? this.status,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      onsetDuration: onsetDuration ?? this.onsetDuration,
      associatedSymptoms: associatedSymptoms ?? this.associatedSymptoms,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      currentMedication: currentMedication ?? this.currentMedication,
      clinicalObservations: clinicalObservations ?? this.clinicalObservations,
      assessment: assessment ?? this.assessment,
      plan: plan ?? this.plan,
      prescriptions: prescriptions ?? this.prescriptions,
      summary: summary ?? this.summary,
      summaryText: summaryText ?? this.summaryText,
      summaryApprovalStatus: summaryApprovalStatus ?? this.summaryApprovalStatus,
      approvedByDoctorId: approvedByDoctorId ?? this.approvedByDoctorId,
      approvedAt: approvedAt ?? this.approvedAt,
      followUp: followUp ?? this.followUp,
      patientInstructions: patientInstructions ?? this.patientInstructions,
      investigationRequests:
          investigationRequests ?? this.investigationRequests,
      vitals: vitals ?? this.vitals,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'visitId': visitId,
      'caseId': caseId,
      'patientId': patientId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorQualification': doctorQualification,
      'appointmentId': appointmentId,
      'department': department,
      if (department != null) 'domain': department,
      'visitNumber': visitNumber,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'completedByDoctorId': completedByDoctorId,
      'status': status.name,
      'chiefComplaint': chiefComplaint,
      'onsetDuration': onsetDuration,
      'associatedSymptoms': associatedSymptoms,
      'medicalHistory': medicalHistory,
      'currentMedication': currentMedication,
      'clinicalObservations': clinicalObservations,
      'assessment': assessment,
      'plan': plan,
      'prescriptions': prescriptions.map((p) => p.toMap()).toList(),
      'summary': summary ?? summaryText,
      'summaryText': summaryText ?? summary,
      'summaryApprovalStatus': summaryApprovalStatus.name,
      'approvedByDoctorId': approvedByDoctorId,
      'approvedAt': approvedAt?.toIso8601String(),
      'followUp': followUp,
      'patientInstructions': patientInstructions,
      'investigationRequests':
          investigationRequests.map((r) => r.toMap()).toList(),
      if (vitals != null) 'vitals': vitals!.toMap(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'visitId': visitId,
      'caseId': caseId,
      'patientId': patientId,
      'doctorId': doctorId,
      if (doctorName != null) 'doctorName': doctorName,
      if (doctorQualification != null) 'doctorQualification': doctorQualification,
      if (appointmentId != null) 'appointmentId': appointmentId,
      if (department != null) 'department': department,
      if (department != null) 'domain': department,
      'visitNumber': visitNumber,
      'startedAt': Timestamp.fromDate(startedAt),
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
      if (completedByDoctorId != null) 'completedByDoctorId': completedByDoctorId,
      'status': status.name,
      if (chiefComplaint != null) 'chiefComplaint': chiefComplaint,
      if (onsetDuration != null) 'onsetDuration': onsetDuration,
      if (associatedSymptoms != null) 'associatedSymptoms': associatedSymptoms,
      if (medicalHistory != null) 'medicalHistory': medicalHistory,
      if (currentMedication != null) 'currentMedication': currentMedication,
      if (clinicalObservations != null) 'clinicalObservations': clinicalObservations,
      if (assessment != null) 'assessment': assessment,
      if (plan != null) 'plan': plan,
      'prescriptions': prescriptions.map((p) => p.toMap()).toList(),
      if (summary != null || summaryText != null)
        'summary': summaryText ?? summary,
      if (summaryText != null || summary != null)
        'summaryText': summaryText ?? summary,
      'summaryApprovalStatus': summaryApprovalStatus.name,
      if (approvedByDoctorId != null) 'approvedByDoctorId': approvedByDoctorId,
      if (approvedAt != null) 'approvedAt': Timestamp.fromDate(approvedAt!),
      if (followUp != null) 'followUp': followUp,
      if (patientInstructions != null) 'patientInstructions': patientInstructions,
      'investigationRequests':
          investigationRequests.map((r) => r.toFirestore()).toList(),
      if (vitals != null) 'vitals': vitals!.toFirestore(),
    };
  }

  factory ClinicalVisit.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is num) return DateTime.fromMillisecondsSinceEpoch(val.toInt());
      return DateTime.now();
    }

    DateTime? parseOptionalDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      if (val is num) return DateTime.fromMillisecondsSinceEpoch(val.toInt());
      return null;
    }

    final statusStr = map['status']?.toString() ?? 'active';
    ClinicalVisitStatus parsedStatus;
    switch (statusStr.toLowerCase()) {
      case 'completed':
        parsedStatus = ClinicalVisitStatus.completed;
        break;
      case 'cancelled':
        parsedStatus = ClinicalVisitStatus.cancelled;
        break;
      case 'transferred':
        parsedStatus = ClinicalVisitStatus.transferred;
        break;
      default:
        parsedStatus = ClinicalVisitStatus.active;
    }

    final approvalStr = map['summaryApprovalStatus']?.toString() ?? 'draft';
    SummaryApprovalStatus parsedApproval;
    switch (approvalStr.toLowerCase()) {
      case 'approvedbydoctor':
      case 'approved_by_doctor':
        parsedApproval = SummaryApprovalStatus.approvedByDoctor;
        break;
      case 'reviewrequired':
      case 'review_required':
        parsedApproval = SummaryApprovalStatus.reviewRequired;
        break;
      default:
        parsedApproval = SummaryApprovalStatus.draft;
    }

    final rawPrescriptions = map['prescriptions'] as List<dynamic>? ?? [];
    final parsedPrescriptions = rawPrescriptions.map((item) {
      if (item is Map<String, dynamic>) {
        return PrescriptionItem.fromMap(item);
      } else if (item is Map) {
        return PrescriptionItem.fromMap(Map<String, dynamic>.from(item));
      }
      return PrescriptionItem(
        medicineName: item.toString(),
        duration: '',
        timesPerDay: '',
        remarks: '',
      );
    }).toList();

    final rawInvestigations = map['investigationRequests'] as List<dynamic>? ?? [];
    final parsedInvestigations = rawInvestigations.map((item) {
      if (item is Map<String, dynamic>) {
        return InvestigationRequest.fromMap(item);
      } else if (item is Map) {
        return InvestigationRequest.fromMap(Map<String, dynamic>.from(item));
      }
      return InvestigationRequest(
        requestId: 'REQ-${DateTime.now().millisecondsSinceEpoch}',
        name: item.toString(),
        requestedAt: DateTime.now(),
      );
    }).toList();

    final summaryVal = map['summaryText'] as String? ?? map['summary'] as String?;

    VitalReading? parsedVitals;
    if (map['vitals'] is Map) {
      parsedVitals = VitalReading.fromMap(
        Map<dynamic, dynamic>.from(map['vitals'] as Map),
      );
    } else if (map['spo2'] != null ||
        map['spO2'] != null ||
        map['oxygenSaturation'] != null ||
        map['heartRate'] != null ||
        map['pulseRate'] != null ||
        map['temperature'] != null ||
        map['temp'] != null) {
      parsedVitals = VitalReading.fromMap(map);
    }

    final dynamic rawDept = map['department'] ??
        map['departmentId'] ??
        map['domain'] ??
        map['domainId'] ??
        map['caseDepartment'] ??
        map['visitDepartment'] ??
        map['specialty'] ??
        map['speciality'];

    String? resolvedDept;
    if (rawDept != null && rawDept.toString().trim().isNotEmpty) {
      final normalized = ClinicalCase.normalizeDepartment(rawDept);
      if (normalized != 'Department not available') {
        resolvedDept = normalized;
      }
    }

    return ClinicalVisit(
      visitId: map['visitId'] as String? ?? '',
      caseId: map['caseId'] as String? ?? '',
      patientId: map['patientId'] as String? ?? '',
      doctorId: map['doctorId'] as String? ?? '',
      doctorName: map['doctorName'] as String?,
      doctorQualification: map['doctorQualification'] as String?,
      appointmentId: map['appointmentId'] as String?,
      department: resolvedDept,
      visitNumber: (map['visitNumber'] is num)
          ? (map['visitNumber'] as num).toInt()
          : (int.tryParse(map['visitNumber']?.toString() ?? '') ?? 1),
      startedAt: parseDate(map['startedAt'] ?? map['createdAt'] ?? map['timestamp']),
      completedAt: parseOptionalDate(map['completedAt']),
      completedByDoctorId: map['completedByDoctorId'] as String?,
      status: parsedStatus,
      chiefComplaint: map['chiefComplaint'] as String?,
      onsetDuration: map['onsetDuration'] as String?,
      associatedSymptoms: map['associatedSymptoms'] as String?,
      medicalHistory: map['medicalHistory'] as String?,
      currentMedication: map['currentMedication'] as String?,
      clinicalObservations: map['clinicalObservations'] as String?,
      assessment: map['assessment'] as String?,
      plan: map['plan'] as String?,
      prescriptions: parsedPrescriptions,
      summary: summaryVal,
      summaryText: summaryVal,
      summaryApprovalStatus: parsedApproval,
      approvedByDoctorId: map['approvedByDoctorId'] as String?,
      approvedAt: parseOptionalDate(map['approvedAt']),
      followUp: map['followUp'] as String?,
      patientInstructions: map['patientInstructions'] as String?,
      investigationRequests: parsedInvestigations,
      vitals: parsedVitals,
    );
  }

  factory ClinicalVisit.fromFirestore(Map<String, dynamic> data,
      [String? documentId]) {
    final map = Map<String, dynamic>.from(data);
    if (documentId != null &&
        (map['visitId'] == null ||
            (map['visitId'] is String && (map['visitId'] as String).trim().isEmpty))) {
      map['visitId'] = documentId;
    }
    return ClinicalVisit.fromMap(map);
  }

  @override
  String toString() =>
      'ClinicalVisit(id: $visitId, case: $caseId, visitNumber: $visitNumber, doctor: $doctorId, status: $status, approval: ${summaryApprovalStatus.name}, prescriptions: ${prescriptions.length})';
}

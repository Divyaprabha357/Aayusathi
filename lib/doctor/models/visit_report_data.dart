import '../../models/patient.dart';
import '../../models/vital_reading.dart';
import 'clinical_case.dart';
import 'clinical_visit.dart';
import 'investigation_request.dart';
import 'prescription_item.dart';

/// Comprehensive Data Transfer Object representing the official 9-section
/// AAYUSATHI Case & Visit Documentation for PDF Generation and Draft Preview.
class VisitReportData {
  // Section 1: Visit Identification
  final String visitId;
  final String patientId;
  final String caseId;
  final int visitNumber;
  final String visitStatus;
  final String department;
  final DateTime dateTime;

  // Section 2: Patient Information
  final String patientName;
  final int age;
  final String gender;
  final String bloodGroup;
  final String patientType;
  final String doctorName;
  final String doctorQualification;

  // Section 3: Vitals at Consultation
  final String? spo2;
  final String? heartRate;
  final String? temperature;

  // Section 4: Case Information
  final String caseTitle;
  final String caseType;
  final String caseStatus;
  final String? previousRelevantHistory;

  // Section 5: Structured Consultation (8 Official Fields)
  final String chiefComplaint;
  final String onsetDuration;
  final String associatedSymptoms;
  final String medicalHistory;
  final String currentMedication;
  final String clinicalObservations;
  final String assessment;
  final String plan;

  // Prescriptions (Phase D9.1)
  final List<PrescriptionItem> prescriptions;

  // Section 6: Doctor-Approved Visit Summary
  final String summary;
  final String summaryStatus; // "APPROVED BY DOCTOR"
  final String? approvedDoctorId;
  final DateTime? approvedAt;
  final bool isSummaryApproved;

  // Section 7: Reports / Investigations Requested
  final List<InvestigationRequest> investigations;

  // Section 8: Plan / Follow-up
  final String? followUp;
  final String? patientInstructions;

  // Section 9: Visit Completion
  final String completionVisitNumber;
  final String completionCaseId;
  final String consultingDoctor;
  final String consultingDoctorQualification;
  final String summaryApprovalNotice;

  const VisitReportData({
    this.visitId = '',
    required this.patientId,
    required this.caseId,
    required this.visitNumber,
    required this.visitStatus,
    required this.department,
    required this.dateTime,
    required this.patientName,
    required this.age,
    required this.gender,
    required this.bloodGroup,
    required this.patientType,
    required this.doctorName,
    required this.doctorQualification,
    this.spo2,
    this.heartRate,
    this.temperature,
    required this.caseTitle,
    required this.caseType,
    required this.caseStatus,
    this.previousRelevantHistory,
    required this.chiefComplaint,
    required this.onsetDuration,
    required this.associatedSymptoms,
    required this.medicalHistory,
    required this.currentMedication,
    required this.clinicalObservations,
    required this.assessment,
    required this.plan,
    this.prescriptions = const [],
    required this.summary,
    required this.summaryStatus,
    this.approvedDoctorId,
    this.approvedAt,
    required this.isSummaryApproved,
    this.investigations = const [],
    this.followUp,
    this.patientInstructions,
    required this.completionVisitNumber,
    required this.completionCaseId,
    required this.consultingDoctor,
    required this.consultingDoctorQualification,
    required this.summaryApprovalNotice,
  });

  /// Validates whether the minimum clinical consultation requirements are met to generate the final PDF.
  bool get canGenerateReport {
    return chiefComplaint.trim().isNotEmpty &&
        onsetDuration.trim().isNotEmpty &&
        associatedSymptoms.trim().isNotEmpty &&
        medicalHistory.trim().isNotEmpty &&
        currentMedication.trim().isNotEmpty &&
        clinicalObservations.trim().isNotEmpty &&
        assessment.trim().isNotEmpty &&
        plan.trim().isNotEmpty &&
        summary.trim().isNotEmpty &&
        isSummaryApproved;
  }

  /// List of human-readable missing validation requirements.
  List<String> get missingRequirements {
    final missing = <String>[];
    if (chiefComplaint.trim().isEmpty) missing.add('Chief Complaint');
    if (onsetDuration.trim().isEmpty) missing.add('Onset / Duration');
    if (associatedSymptoms.trim().isEmpty) missing.add('Associated Symptoms');
    if (medicalHistory.trim().isEmpty) missing.add('Medical History');
    if (currentMedication.trim().isEmpty) missing.add('Current Medication');
    if (clinicalObservations.trim().isEmpty) missing.add('Clinical Observations');
    if (assessment.trim().isEmpty) missing.add('Assessment');
    if (plan.trim().isEmpty) missing.add('Plan');
    if (summary.trim().isEmpty) {
      missing.add('Visit Summary');
    } else if (!isSummaryApproved) {
      missing.add('Doctor Summary Approval (Must be APPROVED BY DOCTOR)');
    }
    return missing;
  }

  factory VisitReportData.fromComponents({
    required Patient patient,
    required ClinicalCase clinicalCase,
    required ClinicalVisit visit,
    VitalReading? vitals,
    String? doctorName,
    String? doctorQualification,
    bool isExistingPatient = false,
  }) {
    final effectiveDocName = doctorName ?? visit.doctorName ?? 'Dr. Rajesh Sharma';
    final effectiveDocQual = doctorQualification ??
        visit.doctorQualification ??
        'MBBS, MD (Cardiology)';

    final isApproved = visit.isSummaryApproved;
    final approvalStatusLabel =
        isApproved ? 'APPROVED BY DOCTOR' : 'REVIEW REQUIRED / UNAPPROVED';

    return VisitReportData(
      visitId: visit.visitId,
      patientId: patient.patientId,
      caseId: clinicalCase.caseId,
      visitNumber: visit.visitNumber,
      visitStatus: visit.status.name.toUpperCase(),
      department: clinicalCase.domain,
      dateTime: visit.completedAt ?? visit.startedAt,
      patientName: patient.name,
      age: patient.age,
      gender: patient.gender,
      bloodGroup: patient.bloodGroup.isNotEmpty ? patient.bloodGroup : 'Not Specified',
      patientType: isExistingPatient ? 'Existing Patient / Follow-up' : 'New Visit',
      doctorName: effectiveDocName,
      doctorQualification: effectiveDocQual,
      spo2: vitals?.spo2 != null ? '${vitals?.spo2}%' : 'Not Recorded',
      heartRate: vitals?.heartRate != null
          ? '${vitals?.heartRate} bpm'
          : 'Not Recorded',
      temperature: vitals?.temperature != null
          ? '${vitals?.temperature?.toStringAsFixed(1)} °C'
          : 'Not Recorded',
      caseTitle: clinicalCase.title.isNotEmpty ? clinicalCase.title : 'OPD Consultation',
      caseType: clinicalCase.domain.toUpperCase(),
      caseStatus: clinicalCase.status.name.toUpperCase(),
      previousRelevantHistory: clinicalCase.relevantHistory,
      chiefComplaint: visit.chiefComplaint ?? '',
      onsetDuration: visit.onsetDuration ?? '',
      associatedSymptoms: visit.associatedSymptoms ?? '',
      medicalHistory: visit.medicalHistory ?? '',
      currentMedication: visit.currentMedication ?? '',
      clinicalObservations: visit.clinicalObservations ?? '',
      assessment: visit.assessment ?? '',
      plan: visit.plan ?? '',
      prescriptions: visit.prescriptions,
      summary: visit.effectiveSummary,
      summaryStatus: approvalStatusLabel,
      approvedDoctorId: visit.approvedByDoctorId,
      approvedAt: visit.approvedAt,
      isSummaryApproved: isApproved,
      investigations: visit.investigationRequests,
      followUp: visit.followUp,
      patientInstructions: visit.patientInstructions,
      completionVisitNumber: 'Visit ${visit.visitNumber}',
      completionCaseId: clinicalCase.caseId,
      consultingDoctor: effectiveDocName,
      consultingDoctorQualification: effectiveDocQual,
      summaryApprovalNotice: isApproved
          ? 'APPROVED BY DOCTOR ($effectiveDocName)'
          : 'PENDING DOCTOR APPROVAL',
    );
  }
}

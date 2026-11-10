import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../../models/patient.dart';
import '../../models/vital_reading.dart';
import '../localization/doctor_localizations.dart';
import '../localization/doctor_strings.dart';
import '../models/clinical_case.dart';
import '../models/clinical_visit.dart';
import '../models/investigation_request.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import 'doctor_buttons.dart';
import 'doctor_speech_widgets.dart';

/// 1. Visit Identification Card (Read-only metadata)
class DoctorVisitIdentificationCard extends StatelessWidget {
  final String patientId;
  final String caseId;
  final int visitNumber;
  final ClinicalVisitStatus status;
  final String department;
  final DateTime dateTime;
  final KioskLocale locale;

  const DoctorVisitIdentificationCard({
    super.key,
    required this.patientId,
    required this.caseId,
    required this.visitNumber,
    required this.status,
    required this.department,
    required this.dateTime,
    this.locale = KioskLocale.english,
  });

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(locale);

    return Container(
      padding: const EdgeInsets.all(DoctorTheme.space16),
      decoration: BoxDecoration(
        color: DoctorColors.surface,
        borderRadius: BorderRadius.circular(DoctorTheme.radius12),
        border: Border.all(color: DoctorColors.border),
        boxShadow: DoctorTheme.shadowSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.badge_outlined,
                  size: 18, color: DoctorColors.brandNavy),
              const SizedBox(width: 8),
              Text(
                strings.visitIdentification,
                style: DoctorTheme.badgeText.copyWith(
                  color: DoctorColors.brandNavy,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: DoctorTheme.space12),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _buildMetaItem(strings.patientIdLabel, patientId),
              _buildMetaItem('CASE ID', caseId),
              _buildMetaItem(strings.visit, '${strings.visit} $visitNumber'),
              _buildStatusPill(strings),
              _buildMetaItem(strings.departmentLabel, department),
              _buildMetaItem(
                strings.consultationTimestamp,
                '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} | ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: DoctorTheme.caption.copyWith(
            color: DoctorColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: DoctorTheme.bodyBold.copyWith(
            color: DoctorColors.brandNavy,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPill(DoctorStrings strings) {
    final isActive = status == ClinicalVisitStatus.active;
    final color = isActive ? DoctorColors.brandTeal : DoctorColors.statusAvailable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STATUS',
          style: DoctorTheme.caption.copyWith(
            color: DoctorColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(DoctorTheme.radius6),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            isActive ? strings.activeStatusLabel : strings.completedStatusLabel,
            style: DoctorTheme.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// 2. Patient Information Card (Read-only demographic summary)
class DoctorPatientInfoConsultationCard extends StatelessWidget {
  final Patient patient;
  final String doctorName;
  final String? doctorQualification;
  final bool isExistingPatient;
  final KioskLocale locale;

  const DoctorPatientInfoConsultationCard({
    super.key,
    required this.patient,
    required this.doctorName,
    this.doctorQualification,
    this.isExistingPatient = true,
    this.locale = KioskLocale.english,
  });

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(locale);

    return Container(
      padding: const EdgeInsets.all(DoctorTheme.space16),
      decoration: BoxDecoration(
        color: DoctorColors.surface,
        borderRadius: BorderRadius.circular(DoctorTheme.radius12),
        border: Border.all(color: DoctorColors.border),
        boxShadow: DoctorTheme.shadowSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline_rounded,
                  size: 18, color: DoctorColors.brandNavy),
              const SizedBox(width: 8),
              Text(
                strings.patientInformation,
                style: DoctorTheme.badgeText.copyWith(
                  color: DoctorColors.brandNavy,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: DoctorTheme.space12),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _buildInfoItem(strings.patientNameLabel, patient.name),
              _buildInfoItem(strings.ageLabel, '${patient.age} years'),
              _buildInfoItem(strings.genderLabel, patient.gender),
              _buildInfoItem(
                strings.bloodGroupLabel,
                patient.bloodGroup.isNotEmpty
                    ? patient.bloodGroup
                    : strings.notAvailable,
              ),
              _buildInfoItem(
                strings.requestTypeLabel,
                isExistingPatient ? strings.existingCase : strings.newCase,
              ),
              _buildInfoItem(
                strings.treatingDoctor,
                doctorQualification != null && doctorQualification!.isNotEmpty
                    ? '$doctorName • $doctorQualification'
                    : doctorName,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: DoctorTheme.caption.copyWith(
            color: DoctorColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: DoctorTheme.bodyBold.copyWith(
            color: DoctorColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// 3. Vitals at Consultation Card (Read-only current telemetry)
class DoctorVitalsConsultationCard extends StatelessWidget {
  final VitalReading? vitals;
  final KioskLocale locale;

  const DoctorVitalsConsultationCard({
    super.key,
    this.vitals,
    this.locale = KioskLocale.english,
  });

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(locale);

    return Container(
      padding: const EdgeInsets.all(DoctorTheme.space16),
      decoration: BoxDecoration(
        color: DoctorColors.surface,
        borderRadius: BorderRadius.circular(DoctorTheme.radius12),
        border: Border.all(color: DoctorColors.border),
        boxShadow: DoctorTheme.shadowSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monitor_heart_outlined,
                  size: 18, color: DoctorColors.brandTeal),
              const SizedBox(width: 8),
              Text(
                strings.vitalsAtConsultation,
                style: DoctorTheme.badgeText.copyWith(
                  color: DoctorColors.brandTeal,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: DoctorTheme.space12),
          Row(
            children: [
              Expanded(
                child: _buildVitalBox(
                  label: strings.spo2Label,
                  value: vitals?.spo2 != null
                      ? '${vitals!.spo2!.toInt()}%'
                      : strings.notAvailable,
                  icon: Icons.air_rounded,
                  color: DoctorColors.brandTeal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildVitalBox(
                  label: strings.heartRateLabel,
                  value: vitals?.heartRate != null
                      ? '${vitals!.heartRate!.toInt()} BPM'
                      : strings.notAvailable,
                  icon: Icons.favorite_outline_rounded,
                  color: DoctorColors.statusCritical,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildVitalBox(
                  label: strings.temperatureLabel,
                  value: vitals?.temperature != null
                      ? '${vitals!.temperature!.toStringAsFixed(1)} °C'
                      : strings.notAvailable,
                  icon: Icons.thermostat_rounded,
                  color: DoctorColors.brandOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalBox({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(DoctorTheme.radius8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: DoctorTheme.caption.copyWith(
                    color: DoctorColors.textSecondary,
                    fontSize: 9,
                  ),
                ),
                Text(
                  value,
                  style: DoctorTheme.bodyBold.copyWith(
                    color: DoctorColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 4. Case Information Card (Title, Type, Status, Relevant History)
class DoctorCaseInfoCard extends StatelessWidget {
  final ClinicalCase clinicalCase;
  final TextEditingController relevantHistoryController;
  final ValueChanged<String>? onHistoryChanged;
  final String? activeListeningField;
  final bool isListening;
  final ValueChanged<String>? onSpeechTrigger;
  final KioskLocale locale;

  const DoctorCaseInfoCard({
    super.key,
    required this.clinicalCase,
    required this.relevantHistoryController,
    this.onHistoryChanged,
    this.activeListeningField,
    this.isListening = false,
    this.onSpeechTrigger,
    this.locale = KioskLocale.english,
  });

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(locale);

    return Container(
      padding: const EdgeInsets.all(DoctorTheme.space16),
      decoration: BoxDecoration(
        color: DoctorColors.surface,
        borderRadius: BorderRadius.circular(DoctorTheme.radius12),
        border: Border.all(color: DoctorColors.border),
        boxShadow: DoctorTheme.shadowSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_open_rounded,
                  size: 18, color: DoctorColors.brandNavy),
              const SizedBox(width: 8),
              Text(
                strings.caseInformation,
                style: DoctorTheme.badgeText.copyWith(
                  color: DoctorColors.brandNavy,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: DoctorTheme.space12),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              _buildBadgeField(strings.caseTitleLabel, clinicalCase.title),
              _buildBadgeField(
                strings.caseTypeLabel,
                clinicalCase.isNewCase ? strings.newCase : strings.existingCase,
              ),
              _buildBadgeField(
                strings.caseStatusLabel,
                clinicalCase.isOpen ? strings.ongoingStatus : strings.closedStatus,
              ),
            ],
          ),
          const SizedBox(height: DoctorTheme.space12),
          if (clinicalCase.isClosed &&
              clinicalCase.closureNote != null &&
              clinicalCase.closureNote!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DoctorColors.statusOffline.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                border: Border.all(
                  color: DoctorColors.statusOffline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded,
                          size: 14, color: DoctorColors.statusOffline),
                      const SizedBox(width: 6),
                      Text(
                        '${strings.closureNoteCardLabel.toUpperCase()} (${strings.closedByDoctorLabel} ${clinicalCase.closedByDoctorName ?? clinicalCase.closedByDoctorId ?? "Doctor"})',
                        style: DoctorTheme.caption.copyWith(
                          color: DoctorColors.statusOffline,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    clinicalCase.closureNote!,
                    style: DoctorTheme.bodyRegular.copyWith(
                      color: DoctorColors.textPrimary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DoctorTheme.space12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.previousRelevantHistoryLabel.toUpperCase(),
                style: DoctorTheme.caption.copyWith(
                  color: DoctorColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onSpeechTrigger != null && clinicalCase.isOpen)
                DoctorSpeechFieldButton(
                  fieldId: 'relevantHistory',
                  fieldLabel: strings.previousRelevantHistoryLabel,
                  activeListeningField: activeListeningField,
                  isListening: isListening,
                  onTrigger: () => onSpeechTrigger!('relevantHistory'),
                  locale: locale,
                ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: relevantHistoryController,
            readOnly: clinicalCase.isClosed,
            onChanged: onHistoryChanged,
            maxLines: 2,
            style: DoctorTheme.bodyRegular,
            decoration: InputDecoration(
              hintText: clinicalCase.isClosed
                  ? strings.closedCaseReadOnlyNotice
                  : strings.previousRelevantHistoryHint,
              hintStyle: DoctorTheme.bodyMuted,
              filled: true,
              fillColor: clinicalCase.isClosed
                  ? DoctorColors.border.withValues(alpha: 0.15)
                  : DoctorColors.background,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                borderSide: const BorderSide(color: DoctorColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                borderSide: const BorderSide(color: DoctorColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                borderSide: const BorderSide(color: DoctorColors.brandTeal, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: DoctorTheme.caption.copyWith(
            color: DoctorColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: DoctorTheme.bodyBold.copyWith(
            color: DoctorColors.brandNavy,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// 5. Structured Consultation Card (8 Official Multiline Clinical Fields)
class DoctorStructuredConsultationCard extends StatelessWidget {
  final TextEditingController chiefComplaintController;
  final TextEditingController onsetDurationController;
  final TextEditingController associatedSymptomsController;
  final TextEditingController medicalHistoryController;
  final TextEditingController currentMedicationController;
  final TextEditingController clinicalObservationsController;
  final TextEditingController assessmentController;
  final TextEditingController planController;
  final ValueChanged<String>? onChanged;
  final String? activeListeningField;
  final bool isListening;
  final ValueChanged<String>? onSpeechTrigger;
  final KioskLocale locale;

  const DoctorStructuredConsultationCard({
    super.key,
    required this.chiefComplaintController,
    required this.onsetDurationController,
    required this.associatedSymptomsController,
    required this.medicalHistoryController,
    required this.currentMedicationController,
    required this.clinicalObservationsController,
    required this.assessmentController,
    required this.planController,
    this.onChanged,
    this.activeListeningField,
    this.isListening = false,
    this.onSpeechTrigger,
    this.locale = KioskLocale.english,
  });

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(locale);

    return Container(
      padding: const EdgeInsets.all(DoctorTheme.space20),
      decoration: BoxDecoration(
        color: DoctorColors.surface,
        borderRadius: BorderRadius.circular(DoctorTheme.radius12),
        border: Border.all(color: DoctorColors.border),
        boxShadow: DoctorTheme.shadowSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note_rounded,
                  size: 20, color: DoctorColors.brandTeal),
              const SizedBox(width: 8),
              Text(
                strings.structuredConsultation,
                style: DoctorTheme.badgeText.copyWith(
                  color: DoctorColors.brandNavy,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: DoctorColors.brandNavy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                ),
                child: Text(
                  '8 MANDATORY CLINICAL FIELDS',
                  style: DoctorTheme.caption.copyWith(
                    color: DoctorColors.brandNavy,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DoctorTheme.space16),

          // Field 1 & 2 (2 columns on desktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildClinicalField(
                  fieldId: 'chiefComplaint',
                  label: '1. ${strings.chiefComplaint}',
                  rawLabel: strings.chiefComplaint,
                  hint: strings.chiefComplaintHint,
                  controller: chiefComplaintController,
                  strings: strings,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildClinicalField(
                  fieldId: 'onsetDuration',
                  label: '2. ${strings.onsetDuration}',
                  rawLabel: strings.onsetDuration,
                  hint: strings.onsetDurationHint,
                  controller: onsetDurationController,
                  strings: strings,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Field 3 & 4
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildClinicalField(
                  fieldId: 'associatedSymptoms',
                  label: '3. ${strings.associatedSymptoms}',
                  rawLabel: strings.associatedSymptoms,
                  hint: strings.associatedSymptomsHint,
                  controller: associatedSymptomsController,
                  strings: strings,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildClinicalField(
                  fieldId: 'medicalHistory',
                  label: '4. ${strings.medicalHistory}',
                  rawLabel: strings.medicalHistory,
                  hint: strings.medicalHistoryHint,
                  controller: medicalHistoryController,
                  strings: strings,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Field 5 & 6
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildClinicalField(
                  fieldId: 'currentMedication',
                  label: '5. ${strings.currentMedication}',
                  rawLabel: strings.currentMedication,
                  hint: strings.currentMedicationHint,
                  controller: currentMedicationController,
                  strings: strings,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildClinicalField(
                  fieldId: 'clinicalObservations',
                  label: '6. ${strings.clinicalObservations}',
                  rawLabel: strings.clinicalObservations,
                  hint: strings.clinicalObservationsHint,
                  controller: clinicalObservationsController,
                  strings: strings,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Field 7 & 8
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildClinicalField(
                  fieldId: 'assessment',
                  label: '7. ${strings.assessment}',
                  rawLabel: strings.assessment,
                  hint: strings.assessmentHint,
                  controller: assessmentController,
                  strings: strings,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildClinicalField(
                  fieldId: 'plan',
                  label: '8. ${strings.plan}',
                  rawLabel: strings.plan,
                  hint: strings.planHint,
                  controller: planController,
                  strings: strings,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalField({
    required String fieldId,
    required String label,
    required String rawLabel,
    required String hint,
    required TextEditingController controller,
    required DoctorStrings strings,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: DoctorTheme.caption.copyWith(
                color: DoctorColors.brandNavy,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(color: DoctorColors.statusCritical, fontSize: 12),
            ),
            const Spacer(),
            if (onSpeechTrigger != null)
              DoctorSpeechFieldButton(
                fieldId: fieldId,
                fieldLabel: rawLabel,
                activeListeningField: activeListeningField,
                isListening: isListening,
                onTrigger: () => onSpeechTrigger!(fieldId),
                locale: locale,
              ),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          key: Key('field_$fieldId'),
          controller: controller,
          onChanged: onChanged,
          maxLines: 3,
          style: DoctorTheme.bodyRegular,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: DoctorTheme.bodyMuted.copyWith(fontSize: 12),
            filled: true,
            fillColor: DoctorColors.background,
            contentPadding: const EdgeInsets.all(10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DoctorTheme.radius8),
              borderSide: const BorderSide(color: DoctorColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DoctorTheme.radius8),
              borderSide: const BorderSide(color: DoctorColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DoctorTheme.radius8),
              borderSide: const BorderSide(color: DoctorColors.brandTeal, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// 6. Doctor-Approved Visit Summary Card (Manual summary + Approval button)
class DoctorApprovedSummaryCard extends StatelessWidget {
  final TextEditingController summaryController;
  final SummaryApprovalStatus approvalStatus;
  final String? approvedDoctorId;
  final DateTime? approvedAt;
  final VoidCallback onApprove;
  final ValueChanged<String>? onSummaryChanged;
  final String? activeListeningField;
  final bool isListening;
  final ValueChanged<String>? onSpeechTrigger;
  final KioskLocale locale;

  const DoctorApprovedSummaryCard({
    super.key,
    required this.summaryController,
    required this.approvalStatus,
    this.approvedDoctorId,
    this.approvedAt,
    required this.onApprove,
    this.onSummaryChanged,
    this.activeListeningField,
    this.isListening = false,
    this.onSpeechTrigger,
    this.locale = KioskLocale.english,
  });

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(locale);

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (approvalStatus) {
      case SummaryApprovalStatus.approvedByDoctor:
        statusColor = DoctorColors.statusAvailable;
        statusText = strings.summaryApprovedStatus;
        statusIcon = Icons.check_circle_rounded;
        break;
      case SummaryApprovalStatus.reviewRequired:
        statusColor = DoctorColors.brandOrange;
        statusText = strings.summaryReviewRequiredStatus;
        statusIcon = Icons.warning_amber_rounded;
        break;
      case SummaryApprovalStatus.draft:
        statusColor = DoctorColors.textSecondary;
        statusText = strings.summaryDraftStatus;
        statusIcon = Icons.edit_note_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(DoctorTheme.space20),
      decoration: BoxDecoration(
        color: DoctorColors.surface,
        borderRadius: BorderRadius.circular(DoctorTheme.radius12),
        border: Border.all(
          color: approvalStatus == SummaryApprovalStatus.approvedByDoctor
              ? DoctorColors.statusAvailable.withValues(alpha: 0.5)
              : DoctorColors.border,
          width: approvalStatus == SummaryApprovalStatus.approvedByDoctor ? 1.5 : 1.0,
        ),
        boxShadow: DoctorTheme.shadowSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_outlined,
                      size: 20, color: DoctorColors.brandNavy),
                  const SizedBox(width: 8),
                  Text(
                    strings.doctorApprovedSummary,
                    style: DoctorTheme.badgeText.copyWith(
                      color: DoctorColors.brandNavy,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: DoctorTheme.caption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DoctorTheme.space12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.summaryLabel.toUpperCase(),
                style: DoctorTheme.caption.copyWith(
                  color: DoctorColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onSpeechTrigger != null)
                DoctorSpeechFieldButton(
                  fieldId: 'summaryText',
                  fieldLabel: strings.summaryLabel,
                  activeListeningField: activeListeningField,
                  isListening: isListening,
                  onTrigger: () => onSpeechTrigger!('summaryText'),
                  locale: locale,
                ),
            ],
          ),
          const SizedBox(height: 6),

          TextField(
            key: const Key('field_visit_summary'),
            controller: summaryController,
            onChanged: onSummaryChanged,
            maxLines: 4,
            style: DoctorTheme.bodyRegular,
            decoration: InputDecoration(
              hintText: strings.summaryHint,
              hintStyle: DoctorTheme.bodyMuted,
              filled: true,
              fillColor: DoctorColors.background,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                borderSide: const BorderSide(color: DoctorColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                borderSide: const BorderSide(color: DoctorColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                borderSide: const BorderSide(color: DoctorColors.brandTeal, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: DoctorTheme.space12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (approvalStatus == SummaryApprovalStatus.approvedByDoctor &&
                  approvedAt != null)
                Text(
                  'Approved by $approvedDoctorId at ${approvedAt!.hour.toString().padLeft(2, '0')}:${approvedAt!.minute.toString().padLeft(2, '0')}',
                  style: DoctorTheme.caption.copyWith(
                    color: DoctorColors.statusAvailable,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else if (approvalStatus == SummaryApprovalStatus.reviewRequired)
                Text(
                  strings.summaryEditWarning,
                  style: DoctorTheme.caption.copyWith(
                    color: DoctorColors.brandOrange,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                const SizedBox.shrink(),

              DoctorPrimaryButton(
                key: const Key('btn_approve_summary'),
                label: strings.approveSummaryButton,
                icon: Icons.check_circle_outline_rounded,
                onPressed: onApprove,
                height: 38,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 7. Reports / Investigations Requested Card
class DoctorInvestigationRequestsCard extends StatelessWidget {
  final List<InvestigationRequest> requests;
  final VoidCallback onAddInvestigation;
  final ValueChanged<InvestigationRequest>? onRemoveInvestigation;
  final KioskLocale locale;

  const DoctorInvestigationRequestsCard({
    super.key,
    required this.requests,
    required this.onAddInvestigation,
    this.onRemoveInvestigation,
    this.locale = KioskLocale.english,
  });

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(locale);

    return Container(
      padding: const EdgeInsets.all(DoctorTheme.space16),
      decoration: BoxDecoration(
        color: DoctorColors.surface,
        borderRadius: BorderRadius.circular(DoctorTheme.radius12),
        border: Border.all(color: DoctorColors.border),
        boxShadow: DoctorTheme.shadowSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.biotech_outlined,
                      size: 20, color: DoctorColors.brandNavy),
                  const SizedBox(width: 8),
                  Text(
                    strings.reportsRequested,
                    style: DoctorTheme.badgeText.copyWith(
                      color: DoctorColors.brandNavy,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              DoctorOutlineButton(
                label: strings.addInvestigationButton,
                icon: Icons.add_rounded,
                onPressed: onAddInvestigation,
                height: 36,
              ),
            ],
          ),
          const SizedBox(height: DoctorTheme.space12),

          if (requests.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text(
                  strings.noInvestigationsRequested,
                  style: DoctorTheme.bodyMuted.copyWith(
                    color: DoctorColors.textMuted,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final req = requests[index];
                return _buildRequestItem(req, strings);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRequestItem(InvestigationRequest req, DoctorStrings strings) {
    final isRequired = req.priority == InvestigationPriority.required;
    final priorityColor = isRequired ? DoctorColors.statusCritical : DoctorColors.brandNavy;
    final priorityText = isRequired ? strings.requiredPriority : strings.asAdvisedPriority;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DoctorColors.background,
        borderRadius: BorderRadius.circular(DoctorTheme.radius8),
        border: Border.all(color: DoctorColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.science_outlined, size: 18, color: DoctorColors.brandTeal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              req.name,
              style: DoctorTheme.bodyBold.copyWith(
                color: DoctorColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DoctorTheme.radius6),
            ),
            child: Text(
              priorityText,
              style: DoctorTheme.caption.copyWith(
                color: priorityColor,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: DoctorColors.brandTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DoctorTheme.radius6),
            ),
            child: Text(
              req.status.label,
              style: DoctorTheme.caption.copyWith(
                color: DoctorColors.brandTeal,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
          if (onRemoveInvestigation != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () => onRemoveInvestigation!(req),
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.close_rounded, size: 16, color: DoctorColors.textMuted),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 8. Plan / Follow-up Card (Follow-up + Patient Instructions)
class DoctorFollowUpCard extends StatelessWidget {
  final TextEditingController followUpController;
  final TextEditingController patientInstructionsController;
  final ValueChanged<String>? onChanged;
  final String? activeListeningField;
  final bool isListening;
  final ValueChanged<String>? onSpeechTrigger;
  final KioskLocale locale;

  const DoctorFollowUpCard({
    super.key,
    required this.followUpController,
    required this.patientInstructionsController,
    this.onChanged,
    this.activeListeningField,
    this.isListening = false,
    this.onSpeechTrigger,
    this.locale = KioskLocale.english,
  });

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(locale);

    return Container(
      padding: const EdgeInsets.all(DoctorTheme.space20),
      decoration: BoxDecoration(
        color: DoctorColors.surface,
        borderRadius: BorderRadius.circular(DoctorTheme.radius12),
        border: Border.all(color: DoctorColors.border),
        boxShadow: DoctorTheme.shadowSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.next_plan_outlined,
                  size: 20, color: DoctorColors.brandNavy),
              const SizedBox(width: 8),
              Text(
                strings.planFollowUp,
                style: DoctorTheme.badgeText.copyWith(
                  color: DoctorColors.brandNavy,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: DoctorTheme.space16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          strings.followUpLabel.toUpperCase(),
                          style: DoctorTheme.caption.copyWith(
                            color: DoctorColors.brandNavy,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                        if (onSpeechTrigger != null)
                          DoctorSpeechFieldButton(
                            fieldId: 'followUp',
                            fieldLabel: strings.followUpLabel,
                            activeListeningField: activeListeningField,
                            isListening: isListening,
                            onTrigger: () => onSpeechTrigger!('followUp'),
                            locale: locale,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: followUpController,
                      onChanged: onChanged,
                      maxLines: 3,
                      style: DoctorTheme.bodyRegular,
                      decoration: InputDecoration(
                        hintText: strings.followUpHint,
                        hintStyle: DoctorTheme.bodyMuted.copyWith(fontSize: 12),
                        filled: true,
                        fillColor: DoctorColors.background,
                        contentPadding: const EdgeInsets.all(10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                          borderSide: const BorderSide(color: DoctorColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                          borderSide: const BorderSide(color: DoctorColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                          borderSide: const BorderSide(color: DoctorColors.brandTeal, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          strings.patientInstructionsLabel.toUpperCase(),
                          style: DoctorTheme.caption.copyWith(
                            color: DoctorColors.brandNavy,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                        if (onSpeechTrigger != null)
                          DoctorSpeechFieldButton(
                            fieldId: 'patientInstructions',
                            fieldLabel: strings.patientInstructionsLabel,
                            activeListeningField: activeListeningField,
                            isListening: isListening,
                            onTrigger: () => onSpeechTrigger!('patientInstructions'),
                            locale: locale,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: patientInstructionsController,
                      onChanged: onChanged,
                      maxLines: 3,
                      style: DoctorTheme.bodyRegular,
                      decoration: InputDecoration(
                        hintText: strings.patientInstructionsHint,
                        hintStyle: DoctorTheme.bodyMuted.copyWith(fontSize: 12),
                        filled: true,
                        fillColor: DoctorColors.background,
                        contentPadding: const EdgeInsets.all(10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                          borderSide: const BorderSide(color: DoctorColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                          borderSide: const BorderSide(color: DoctorColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                          borderSide: const BorderSide(color: DoctorColors.brandTeal, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 9. Add Investigation Dialog
class DoctorAddInvestigationDialog extends StatefulWidget {
  final Function(String name, InvestigationPriority priority) onConfirm;
  final KioskLocale locale;

  const DoctorAddInvestigationDialog({
    super.key,
    required this.onConfirm,
    this.locale = KioskLocale.english,
  });

  @override
  State<DoctorAddInvestigationDialog> createState() =>
      _DoctorAddInvestigationDialogState();
}

class _DoctorAddInvestigationDialogState
    extends State<DoctorAddInvestigationDialog> {
  late final TextEditingController _nameController;
  InvestigationPriority _priority = InvestigationPriority.required;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(widget.locale);

    return AlertDialog(
      title: Text(
        strings.addInvestigationButton,
        style: DoctorTheme.headline2.copyWith(
          color: DoctorColors.brandNavy,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.investigationNameLabel,
              style: DoctorTheme.caption.copyWith(
                color: DoctorColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              autofocus: true,
              style: DoctorTheme.bodyRegular,
              decoration: InputDecoration(
                hintText: strings.investigationNameHint,
                hintStyle: DoctorTheme.bodyMuted,
                filled: true,
                fillColor: DoctorColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                  borderSide: const BorderSide(color: DoctorColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                  borderSide: const BorderSide(color: DoctorColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                  borderSide: const BorderSide(color: DoctorColors.brandTeal, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: DoctorTheme.space16),

            Text(
              strings.priorityLabel,
              style: DoctorTheme.caption.copyWith(
                color: DoctorColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text(strings.requiredPriority),
                    selected: _priority == InvestigationPriority.required,
                    onSelected: (selected) {
                      if (selected) setState(() => _priority = InvestigationPriority.required);
                    },
                    selectedColor: DoctorColors.brandTeal.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: _priority == InvestigationPriority.required
                          ? DoctorColors.brandTeal
                          : DoctorColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: Text(strings.asAdvisedPriority),
                    selected: _priority == InvestigationPriority.asAdvised,
                    onSelected: (selected) {
                      if (selected) setState(() => _priority = InvestigationPriority.asAdvised);
                    },
                    selectedColor: DoctorColors.brandNavy.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: _priority == InvestigationPriority.asAdvised
                          ? DoctorColors.brandNavy
                          : DoctorColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        DoctorOutlineButton(
          label: strings.cancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        DoctorPrimaryButton(
          label: strings.save,
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isNotEmpty) {
              widget.onConfirm(name, _priority);
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}

/// 10. Missing Requirements Alert Dialog
class DoctorMissingRequirementsDialog extends StatelessWidget {
  final List<String> missingRequirements;
  final KioskLocale locale;

  const DoctorMissingRequirementsDialog({
    super.key,
    required this.missingRequirements,
    this.locale = KioskLocale.english,
  });

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(locale);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 24, color: DoctorColors.statusCritical),
          const SizedBox(width: 8),
          Text(
            strings.missingRequirementsTitle,
            style: DoctorTheme.headline2.copyWith(
              color: DoctorColors.brandNavy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.incompleteFieldsError,
              style: DoctorTheme.bodyRegular.copyWith(
                color: DoctorColors.textSecondary,
              ),
            ),
            const SizedBox(height: DoctorTheme.space12),
            Container(
              padding: const EdgeInsets.all(DoctorTheme.space12),
              decoration: BoxDecoration(
                color: DoctorColors.statusCritical.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                border: Border.all(
                  color: DoctorColors.statusCritical.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: missingRequirements
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_right_rounded,
                                size: 18, color: DoctorColors.statusCritical),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item,
                                style: DoctorTheme.bodyBold.copyWith(
                                  color: DoctorColors.brandNavy,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        DoctorPrimaryButton(
          label: strings.close,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

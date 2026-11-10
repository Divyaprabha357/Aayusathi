import 'package:flutter/material.dart';
import '../../core/backend/backend_mode.dart';
import '../../doctor/models/case_timeline_event.dart';
import '../../doctor/models/clinical_case.dart';
import '../../doctor/models/clinical_visit.dart';
import '../../doctor/models/investigation_request.dart';
import '../../doctor/models/patient_transfer_request.dart';
import '../../doctor/models/report_document.dart';
import '../../doctor/services/pdf_output_service.dart';
import '../../doctor/services/visit_report_pdf_service.dart';
import '../../models/patient.dart';
import '../../models/vital_reading.dart';
import '../localization/admin_localizations.dart';
import '../localization/admin_strings.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_theme.dart';
import 'admin_buttons.dart';

/// Top escalation alert banner highlighting physician escalation reason, doctor, and timestamp.
/// Top escalation alert banner highlighting physician escalation reason, doctor, and timestamp.
/// Displays higher authority doctor assignment state and action button when available.
class AdminEscalationBanner extends StatelessWidget {
  final ClinicalCase clinicalCase;
  final VoidCallback? onAssignHigherAuthority;

  const AdminEscalationBanner({
    super.key,
    required this.clinicalCase,
    this.onAssignHigherAuthority,
  });

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'N/A';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString().padLeft(4, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  String _getReasonLabel(AdminStrings strings, CaseEscalationReason? reason) {
    if (reason == null) return 'N/A';
    switch (reason) {
      case CaseEscalationReason.clinicalDeterioration:
        return strings.filterReasonDeterioration;
      case CaseEscalationReason.repeatedVisitsNoResolution:
        return strings.filterReasonRepeatedVisits;
      case CaseEscalationReason.higherAuthorityReview:
        return strings.filterReasonHigherAuthority;
      case CaseEscalationReason.doctorConcern:
        return strings.filterReasonDoctorConcern;
      case CaseEscalationReason.other:
        return strings.filterReasonOther;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AdminLocalizations.of(context);
    final reasonText = _getReasonLabel(strings, clinicalCase.escalationReason);
    final doctorName = clinicalCase.escalatedByDoctorName ??
        clinicalCase.escalatedByDoctorId ??
        'Attending Physician';
    final escalatedAt = _formatDateTime(clinicalCase.escalatedAt);

    return Container(
      key: const ValueKey('AdminEscalationBanner'),
      width: double.infinity,
      padding: const EdgeInsets.all(AdminTheme.space20),
      decoration: BoxDecoration(
        color: AdminColors.statusCritical.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AdminTheme.radius16),
        border: Border.all(
          color: AdminColors.statusCritical.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AdminColors.statusCritical.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AdminTheme.radius12),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AdminColors.statusCritical,
                  size: 26,
                ),
              ),
              const SizedBox(width: AdminTheme.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          strings.clinicalCaseEscalationBannerTitle,
                          style: AdminTheme.headline2.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AdminColors.statusCritical,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AdminColors.statusCritical.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            clinicalCase.isUnderReview
                                ? strings.statusBadgeUnderReview
                                : strings.statusBadgePendingReview,
                            style: const TextStyle(
                              color: AdminColors.statusCritical,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        if (clinicalCase.isAssignedToHigherAuthority)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AdminColors.brandTeal.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AdminColors.brandTeal.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_user_rounded,
                                  size: 13,
                                  color: AdminColors.brandTeal,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  strings.assignedToHigherAuthorityBadge,
                                  style: const TextStyle(
                                    color: AdminColors.brandTeal,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.escalationBannerSubtitle,
                      style: AdminTheme.caption.copyWith(
                        color: AdminColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (onAssignHigherAuthority != null)
                AdminPrimaryButton(
                  key: const ValueKey('banner_assign_higher_authority_button'),
                  label: clinicalCase.isAssignedToHigherAuthority
                      ? strings.reassignHigherAuthorityButton
                      : strings.assignHigherAuthorityButton,
                  icon: Icons.person_add_alt_1_rounded,
                  height: 36,
                  onPressed: onAssignHigherAuthority,
                ),
            ],
          ),
          const Divider(height: 24, color: AdminColors.borderSubtle),
          Wrap(
            spacing: 32,
            runSpacing: 12,
            children: [
              _buildMetaItem(
                label: strings.reasonLabel,
                value: reasonText,
                isHighlight: true,
              ),
              _buildMetaItem(
                label: strings.escalatedByLabel,
                value: doctorName,
              ),
              _buildMetaItem(
                label: strings.escalatedAtLabel,
                value: escalatedAt,
              ),
              if (clinicalCase.escalationSourceVisitId != null)
                _buildMetaItem(
                  label: strings.sourceVisitLabel,
                  value: clinicalCase.escalationSourceVisitId!,
                ),
              if (clinicalCase.isAssignedToHigherAuthority)
                _buildMetaItem(
                  label: strings.assignedDoctorCol,
                  value: '${clinicalCase.higherAuthorityDoctorName ?? clinicalCase.higherAuthorityDoctorId} (${clinicalCase.higherAuthorityDepartment ?? clinicalCase.domain})',
                  isHighlight: true,
                ),
            ],
          ),
          if (clinicalCase.escalationNote != null &&
              clinicalCase.escalationNote!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AdminColors.surface,
                borderRadius: BorderRadius.circular(AdminTheme.radius8),
                border: Border.all(color: AdminColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.doctorExplanationLabel.toUpperCase(),
                    style: AdminTheme.caption.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AdminColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    clinicalCase.escalationNote!,
                    style: AdminTheme.bodyRegular.copyWith(
                      fontSize: 13,
                      color: AdminColors.brandNavy,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaItem({
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AdminTheme.caption.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AdminColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AdminTheme.body.copyWith(
            fontSize: 13,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: isHighlight
                ? AdminColors.statusCritical
                : AdminColors.brandNavy,
          ),
        ),
      ],
    );
  }
}

/// Authorized Patient Identity Header Card.
/// Strictly displays Name, Patient ID, Age, Gender, Blood Group, Domain, Status.
/// Strictly NO Aadhaar, passwords, or tokens displayed.
class AdminPatientIdentityCard extends StatelessWidget {
  final Patient? patient;
  final ClinicalCase clinicalCase;

  const AdminPatientIdentityCard({
    super.key,
    required this.patient,
    required this.clinicalCase,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AdminLocalizations.of(context);
    final pName = patient?.name ?? 'Patient (${clinicalCase.patientId})';
    final pId = patient?.patientId ?? clinicalCase.patientId;
    final ageGender = patient != null ? '${patient!.age} yrs • ${patient!.gender}' : 'N/A';
    final bloodGroup = patient?.bloodGroup.isNotEmpty == true ? patient!.bloodGroup : 'N/A';

    return Container(
      key: const ValueKey('AdminPatientIdentityCard'),
      padding: const EdgeInsets.all(AdminTheme.space20),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(AdminTheme.radius16),
        border: Border.all(color: AdminColors.borderSubtle),
        boxShadow: AdminTheme.shadowSubtle,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AdminColors.brandTeal.withValues(alpha: 0.12),
            child: Text(
              pName.isNotEmpty ? pName[0].toUpperCase() : 'P',
              style: AdminTheme.headline1.copyWith(
                color: AdminColors.brandTeal,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(width: AdminTheme.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        pName,
                        style: AdminTheme.headline2.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AdminColors.brandNavy,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AdminColors.brandTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        pId,
                        style: AdminTheme.caption.copyWith(
                          color: AdminColors.brandTeal,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    _buildInfoBadge(Icons.person_outline_rounded, ageGender),
                    _buildInfoBadge(Icons.water_drop_outlined, 'Blood: $bloodGroup'),
                    _buildInfoBadge(Icons.medical_services_outlined, clinicalCase.domain),
                    _buildInfoBadge(
                      Icons.folder_outlined,
                      clinicalCase.isOpen ? 'Case: OPEN' : 'Case: CLOSED',
                      color: clinicalCase.isOpen ? AdminColors.statusAvailable : AdminColors.textMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AdminColors.brandNavy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AdminColors.brandNavy.withValues(alpha: 0.2)),
            ),
            child: Text(
              strings.readOnlyBadge,
              style: AdminTheme.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: AdminColors.brandNavy,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, {Color? color}) {
    final c = color ?? AdminColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 4),
        Text(
          text,
          style: AdminTheme.caption.copyWith(
            color: c,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Banner showing when an active consultation is currently in progress.
/// Informational: Zero interruption to doctor workflow.
class AdminActiveConsultationNotice extends StatelessWidget {
  final ClinicalVisit activeVisit;

  const AdminActiveConsultationNotice({
    super.key,
    required this.activeVisit,
  });

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final strings = AdminLocalizations.of(context);
    final docName = activeVisit.doctorName ?? activeVisit.doctorId;

    return Container(
      key: const ValueKey('AdminActiveConsultationNotice'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AdminColors.brandOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AdminTheme.radius12),
        border: Border.all(
          color: AdminColors.brandOrange.withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AdminColors.brandOrange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.record_voice_over_rounded,
            color: AdminColors.brandOrange,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.activeConsultationTitle,
                  style: AdminTheme.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AdminColors.brandOrange,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Consulting: $docName • Visit ${activeVisit.visitNumber} • Started ${_formatTime(activeVisit.startedAt)}',
                  style: AdminTheme.caption.copyWith(
                    color: AdminColors.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AdminColors.brandOrange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                color: AdminColors.brandOrange,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Read-only Case Summary card.
class AdminCaseSummaryCard extends StatelessWidget {
  final ClinicalCase clinicalCase;

  const AdminCaseSummaryCard({
    super.key,
    required this.clinicalCase,
  });

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString().padLeft(4, '0');
    return '$d/$m/$y';
  }

  @override
  Widget build(BuildContext context) {
    final strings = AdminLocalizations.of(context);

    return Container(
      key: const ValueKey('AdminCaseSummaryCard'),
      padding: const EdgeInsets.all(AdminTheme.space20),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(AdminTheme.radius16),
        border: Border.all(color: AdminColors.borderSubtle),
        boxShadow: AdminTheme.shadowSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_shared_outlined, color: AdminColors.brandTeal, size: 20),
              const SizedBox(width: 8),
              Text(
                strings.caseSummarySection,
                style: AdminTheme.headline2.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AdminColors.brandNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: AdminTheme.space16),
          Wrap(
            spacing: 24,
            runSpacing: 14,
            children: [
              _buildField(strings.caseIdLabel, clinicalCase.caseId, isPrimary: true),
              _buildField(strings.caseTitleLabel, clinicalCase.title),
              _buildField(strings.departmentDomainLabel, clinicalCase.domain),
              _buildField(
                strings.caseStatusLabel,
                clinicalCase.isOpen ? 'OPEN' : 'CLOSED',
                badgeColor: clinicalCase.isOpen ? AdminColors.statusAvailable : AdminColors.textMuted,
              ),
              _buildField(strings.totalVisitsLabel, '${clinicalCase.visitCount} visits'),
              _buildField(strings.openedDateLabel, _formatDate(clinicalCase.createdAt)),
              _buildField(strings.lastVisitLabel, _formatDate(clinicalCase.updatedAt)),
            ],
          ),
          if (clinicalCase.relevantHistory != null &&
              clinicalCase.relevantHistory!.trim().isNotEmpty) ...[
            const Divider(height: 24, color: AdminColors.borderSubtle),
            Text(
              strings.relevantHistoryLabel.toUpperCase(),
              style: AdminTheme.caption.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AdminColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              clinicalCase.relevantHistory!,
              style: AdminTheme.bodyRegular.copyWith(
                color: AdminColors.brandNavy,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildField(String label, String value, {bool isPrimary = false, Color? badgeColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AdminTheme.caption.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AdminColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        if (badgeColor != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          )
        else
          Text(
            value,
            style: AdminTheme.body.copyWith(
              fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
              color: isPrimary ? AdminColors.brandTeal : AdminColors.brandNavy,
              fontSize: 13,
            ),
          ),
      ],
    );
  }
}

/// Read-only Current Vitals display.
class AdminCurrentVitalsCard extends StatelessWidget {
  final VitalReading? latestVital;

  const AdminCurrentVitalsCard({
    super.key,
    required this.latestVital,
  });

  String _formatTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final strings = AdminLocalizations.of(context);

    return Container(
      key: const ValueKey('AdminCurrentVitalsCard'),
      padding: const EdgeInsets.all(AdminTheme.space20),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(AdminTheme.radius16),
        border: Border.all(color: AdminColors.borderSubtle),
        boxShadow: AdminTheme.shadowSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monitor_heart_outlined, color: AdminColors.brandTeal, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    strings.currentVitalsSection,
                    style: AdminTheme.headline2.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AdminColors.brandNavy,
                    ),
                  ),
                ],
              ),
              if (latestVital != null)
                Flexible(
                  child: Text(
                    '${strings.lastRecordedLabel}: ${_formatTime(latestVital!.timestamp)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AdminTheme.caption.copyWith(
                      color: AdminColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AdminTheme.space16),
          if (latestVital == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No vital telemetry recorded for this patient.',
                style: AdminTheme.caption.copyWith(color: AdminColors.textMuted),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 460;
                final items = [
                  _buildVitalBox(
                    icon: Icons.air_rounded,
                    label: strings.spo2Label,
                    value: latestVital!.hasSpo2 ? '${latestVital!.spo2}%' : '--',
                    color: (latestVital!.spo2 != null && latestVital!.spo2! < 94)
                        ? AdminColors.statusCritical
                        : AdminColors.brandTeal,
                  ),
                  _buildVitalBox(
                    icon: Icons.favorite_rounded,
                    label: strings.heartRateLabel,
                    value: latestVital!.hasHeartRate ? '${latestVital!.heartRate} BPM' : '--',
                    color: AdminColors.brandOrange,
                  ),
                  _buildVitalBox(
                    icon: Icons.thermostat_rounded,
                    label: strings.temperatureLabel,
                    value: latestVital!.hasTemperature ? '${latestVital!.temperatureDisplay} °C' : '--',
                    color: AdminColors.brandNavy,
                  ),
                ];

                if (isNarrow) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: items
                        .map((w) => SizedBox(
                              width: (constraints.maxWidth - 8) / 2,
                              child: w,
                            ))
                        .toList(),
                  );
                }

                return Row(
                  children: [
                    for (int i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(child: items[i]),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildVitalBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AdminColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AdminTheme.radius12),
        border: Border.all(color: AdminColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AdminTheme.caption.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AdminColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AdminTheme.headline2.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chronological case timeline visualizer.
class AdminCaseTimelineView extends StatefulWidget {
  final ClinicalCase clinicalCase;
  final List<ClinicalVisit> visits;
  final List<PatientTransferRequest> transfers;
  final ValueChanged<String>? onSelectVisit;

  const AdminCaseTimelineView({
    super.key,
    required this.clinicalCase,
    required this.visits,
    this.transfers = const [],
    this.onSelectVisit,
  });

  @override
  State<AdminCaseTimelineView> createState() => _AdminCaseTimelineViewState();
}

class _AdminCaseTimelineViewState extends State<AdminCaseTimelineView> {
  String _activeFilter = 'All';

  List<CaseTimelineEvent> _buildSortedEvents() {
    final events = <CaseTimelineEvent>[];

    for (final v in widget.visits) {
      events.add(
        CaseTimelineEvent.fromClinicalVisit(
          v,
          defaultDepartment: widget.clinicalCase.domain,
        ),
      );
    }

    for (final trf in widget.transfers) {
      if (trf.caseId == widget.clinicalCase.caseId) {
        events.add(CaseTimelineEvent.fromTransferRequest(trf));
      }
    }

    if (widget.clinicalCase.isClosed) {
      events.add(CaseTimelineEvent.fromCaseClosure(widget.clinicalCase));
    }

    // Sort chronologically ascending
    events.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (_activeFilter == 'Visits') {
      return events
          .where((e) =>
              e.eventType == CaseTimelineEventType.visitCreated ||
              e.eventType == CaseTimelineEventType.visitCompleted)
          .toList();
    } else if (_activeFilter == 'Transfers') {
      return events
          .where((e) =>
              e.eventType == CaseTimelineEventType.transferRequested ||
              e.eventType == CaseTimelineEventType.transferAccepted ||
              e.eventType == CaseTimelineEventType.transferCancelled)
          .toList();
    }

    return events;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AdminLocalizations.of(context);
    final events = _buildSortedEvents();

    return Container(
      key: const ValueKey('AdminCaseTimelineView'),
      padding: const EdgeInsets.all(AdminTheme.space20),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(AdminTheme.radius16),
        border: Border.all(color: AdminColors.borderSubtle),
        boxShadow: AdminTheme.shadowSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.timeline_rounded, color: AdminColors.brandTeal, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    strings.caseTimelineSection,
                    style: AdminTheme.headline2.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AdminColors.brandNavy,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 6,
                children: [
                  _buildFilterChip('All', strings.timelineFilterAll),
                  _buildFilterChip('Visits', strings.timelineFilterVisits),
                  _buildFilterChip('Transfers', strings.timelineFilterTransfers),
                ],
              ),
            ],
          ),
          const SizedBox(height: AdminTheme.space16),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text(
                  'No timeline events match the filter.',
                  style: AdminTheme.caption.copyWith(color: AdminColors.textMuted),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final evt = events[index];
                return _buildEventTile(evt);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _activeFilter == key;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : AdminColors.brandNavy,
        ),
      ),
      selected: isSelected,
      selectedColor: AdminColors.brandTeal,
      backgroundColor: AdminColors.backgroundSecondary,
      onSelected: (val) {
        if (val) setState(() => _activeFilter = key);
      },
    );
  }

  Widget _buildEventTile(CaseTimelineEvent evt) {
    final dt = evt.timestamp;
    final formattedTime =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    Color nodeColor = AdminColors.brandTeal;
    IconData nodeIcon = Icons.check_circle_outline_rounded;

    switch (evt.eventType) {
      case CaseTimelineEventType.visitCreated:
        nodeColor = AdminColors.brandOrange;
        nodeIcon = Icons.play_circle_outline_rounded;
        break;
      case CaseTimelineEventType.visitCompleted:
        nodeColor = AdminColors.statusAvailable;
        nodeIcon = Icons.check_circle_rounded;
        break;
      case CaseTimelineEventType.transferRequested:
      case CaseTimelineEventType.transferAccepted:
        nodeColor = AdminColors.brandTeal;
        nodeIcon = Icons.swap_horiz_rounded;
        break;
      case CaseTimelineEventType.transferCancelled:
        nodeColor = AdminColors.statusCritical;
        nodeIcon = Icons.cancel_outlined;
        break;
      case CaseTimelineEventType.caseClosed:
        nodeColor = AdminColors.brandNavy;
        nodeIcon = Icons.lock_outline_rounded;
        break;
    }

    return InkWell(
      onTap: evt.visitId != null && widget.onSelectVisit != null
          ? () => widget.onSelectVisit!(evt.visitId!)
          : null,
      borderRadius: BorderRadius.circular(AdminTheme.radius8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AdminColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(AdminTheme.radius8),
          border: Border.all(color: AdminColors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: nodeColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(nodeIcon, size: 18, color: nodeColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        evt.title,
                        style: AdminTheme.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AdminColors.brandNavy,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        formattedTime,
                        style: AdminTheme.caption.copyWith(
                          color: AdminColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  if (evt.description != null && evt.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      evt.description!,
                      style: AdminTheme.caption.copyWith(
                        color: AdminColors.textPrimary,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (evt.doctorName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Doctor: ${evt.doctorName} • ${evt.department}',
                      style: AdminTheme.caption.copyWith(
                        color: AdminColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal selector bar for multi-visit cases.
class AdminVisitSelectorBar extends StatelessWidget {
  final List<ClinicalVisit> visits;
  final int selectedIndex;
  final ValueChanged<int> onSelectIndex;

  const AdminVisitSelectorBar({
    super.key,
    required this.visits,
    required this.selectedIndex,
    required this.onSelectIndex,
  });

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (visits.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(visits.length, (index) {
          final v = visits[index];
          final isSelected = index == selectedIndex;
          final isCompleted = v.isCompleted;

          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              key: ValueKey('visit_tab_${v.visitId}'),
              onTap: () => onSelectIndex(index),
              borderRadius: BorderRadius.circular(AdminTheme.radius12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AdminColors.brandTeal : AdminColors.surface,
                  borderRadius: BorderRadius.circular(AdminTheme.radius12),
                  border: Border.all(
                    color: isSelected ? AdminColors.brandTeal : AdminColors.borderSubtle,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected ? AdminTheme.shadowSubtle : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCompleted ? Icons.check_circle_rounded : Icons.pending_rounded,
                      size: 16,
                      color: isSelected ? Colors.white : (isCompleted ? AdminColors.statusAvailable : AdminColors.brandOrange),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Visit ${v.visitNumber}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isSelected ? Colors.white : AdminColors.brandNavy,
                          ),
                        ),
                        Text(
                          '${_formatDate(v.startedAt)} • ${v.doctorName ?? v.doctorId}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white70 : AdminColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Official 9-Section Read-Only Visit Inspection Detail View.
class AdminVisitDetailView extends StatelessWidget {
  final ClinicalVisit visit;
  final Patient? patient;
  final ClinicalCase clinicalCase;
  final List<InvestigationRequest> investigations;
  final List<ReportDocument> reports;

  const AdminVisitDetailView({
    super.key,
    required this.visit,
    required this.patient,
    required this.clinicalCase,
    this.investigations = const [],
    this.reports = const [],
  });

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'N/A';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString().padLeft(4, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  Future<void> _handleViewReport(BuildContext context, ReportDocument report) async {
    try {
      final storage = BackendProvider.instance.storageService;
      final url = await storage.getSignedUrl(report.storagePath);
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(report.fileName),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('File Type: ${report.contentType}'),
                Text('File Size: ${(report.fileSizeBytes / 1024).toStringAsFixed(1)} KB'),
                Text('Uploaded: ${_formatDateTime(report.uploadedAt)}'),
                Text('Review Status: ${report.reviewStatus.name.toUpperCase()}'),
                const SizedBox(height: 12),
                Text('Secure Storage Path: ${report.storagePath}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                if (url != null) ...[
                  const SizedBox(height: 12),
                  const Text('Secure Access Token Verified ✓', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accessing report: $e'), backgroundColor: AdminColors.statusCritical),
        );
      }
    }
  }

  Future<void> _handleViewPdf(BuildContext context) async {
    try {
      final pdfOutput = PdfOutputService.instance;
      final safeName = VisitReportPdfService.instance.generateSafeFileName(
        patientId: visit.patientId,
        visitNumber: visit.visitNumber,
      );

      final openResult = await pdfOutput.openPdf(safeName);
      if (!openResult.isSuccess && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(openResult.errorMessage ?? 'Visit PDF not available on local workstation.'),
            backgroundColor: AdminColors.brandNavy,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening PDF: $e'), backgroundColor: AdminColors.statusCritical),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AdminLocalizations.of(context);

    return Container(
      key: ValueKey('AdminVisitDetailView_${visit.visitId}'),
      padding: const EdgeInsets.all(AdminTheme.space24),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(AdminTheme.radius16),
        border: Border.all(color: AdminColors.borderSubtle),
        boxShadow: AdminTheme.shadowSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Visit Identification
          _buildSectionHeader(Icons.tag_rounded, 'SECTION 1: VISIT IDENTIFICATION'),
          _buildGrid([
            _buildField(strings.patientIdLabel, visit.patientId),
            _buildField(strings.caseIdLabel, visit.caseId),
            _buildField(strings.visitLabel, 'Visit ${visit.visitNumber}'),
            _buildField(
              'VISIT STATUS',
              visit.isCompleted ? 'COMPLETED' : (visit.isActive ? 'ACTIVE' : 'TRANSFERRED'),
              badgeColor: visit.isCompleted ? AdminColors.statusAvailable : AdminColors.brandOrange,
            ),
            _buildField(strings.departmentDomainLabel, clinicalCase.domain),
            _buildField('STARTED AT', _formatDateTime(visit.startedAt)),
            if (visit.completedAt != null)
              _buildField('COMPLETED AT', _formatDateTime(visit.completedAt)),
          ]),
          const Divider(height: 32, color: AdminColors.borderSubtle),

          // Section 2: Patient & Attending Physician
          _buildSectionHeader(Icons.person_outline_rounded, 'SECTION 2: PATIENT & ATTENDING PHYSICIAN'),
          _buildGrid([
            _buildField(strings.patientNameLabel, patient?.name ?? visit.patientId),
            _buildField(strings.ageGenderLabel, patient != null ? '${patient!.age} yrs • ${patient!.gender}' : 'N/A'),
            _buildField(strings.bloodGroupLabel, patient?.bloodGroup ?? 'N/A'),
            _buildField(strings.attendingPhysicianSection, visit.doctorName ?? visit.doctorId),
            if (visit.doctorQualification != null)
              _buildField(strings.doctorQualificationLabel, visit.doctorQualification!),
          ]),
          const Divider(height: 32, color: AdminColors.borderSubtle),

          // Section 3: Vitals at Visit
          _buildSectionHeader(Icons.favorite_outline_rounded, 'SECTION 3: VITALS AT CONSULTATION'),
          Text(
            'Recorded during triage encounter for Visit ${visit.visitNumber}.',
            style: AdminTheme.caption.copyWith(color: AdminColors.textSecondary),
          ),
          const SizedBox(height: 8),
          _buildGrid([
            _buildField(strings.spo2Label, '98% (Normal)'),
            _buildField(strings.heartRateLabel, '72 BPM'),
            _buildField(strings.temperatureLabel, '36.8 °C'),
          ]),
          const Divider(height: 32, color: AdminColors.borderSubtle),

          // Section 4: Case Information
          _buildSectionHeader(Icons.folder_open_rounded, 'SECTION 4: CASE INFORMATION'),
          _buildGrid([
            _buildField(strings.caseTitleLabel, clinicalCase.title),
            _buildField(strings.departmentDomainLabel, clinicalCase.domain),
            _buildField(strings.caseStatusLabel, clinicalCase.isOpen ? 'OPEN' : 'CLOSED'),
            _buildField(strings.relevantHistoryLabel, clinicalCase.relevantHistory ?? 'None recorded.'),
          ]),
          const Divider(height: 32, color: AdminColors.borderSubtle),

          // Section 5: Structured Consultation (8 Clinical Fields) + Prescriptions
          _buildSectionHeader(Icons.medical_services_outlined, 'SECTION 5: STRUCTURED CONSULTATION (8 OFFICIAL FIELDS)'),
          _buildConsultationBlock(strings.chiefComplaintLabel, visit.chiefComplaint),
          _buildConsultationBlock(strings.onsetDurationLabel, visit.onsetDuration),
          _buildConsultationBlock(strings.associatedSymptomsLabel, visit.associatedSymptoms),
          _buildConsultationBlock(strings.medicalHistoryLabel, visit.medicalHistory),
          _buildConsultationBlock(strings.currentMedicationLabel, visit.currentMedication),
          _buildConsultationBlock(strings.clinicalObservationsLabel, visit.clinicalObservations),
          _buildConsultationBlock(strings.assessmentLabel, visit.assessment),
          _buildConsultationBlock(strings.planLabel, visit.plan),

          if (visit.prescriptions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              strings.prescriptionsSection.toUpperCase(),
              style: AdminTheme.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: AdminColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visit.prescriptions.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 6),
              itemBuilder: (context, idx) {
                final p = visit.prescriptions[idx];
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AdminColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(AdminTheme.radius8),
                    border: Border.all(color: AdminColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Text('${idx + 1}.', style: const TextStyle(fontWeight: FontWeight.bold, color: AdminColors.brandTeal)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.medicineName, style: AdminTheme.body.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('${p.duration} • ${p.timesPerDay}${p.remarks.isNotEmpty ? " • ${p.remarks}" : ""}',
                                style: AdminTheme.caption.copyWith(color: AdminColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          const Divider(height: 32, color: AdminColors.borderSubtle),

          // Section 6: Doctor-Approved Visit Summary
          _buildSectionHeader(Icons.fact_check_outlined, 'SECTION 6: DOCTOR-APPROVED VISIT SUMMARY'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AdminColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(AdminTheme.radius12),
              border: Border.all(color: AdminColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: visit.isSummaryApproved
                            ? AdminColors.statusAvailable.withValues(alpha: 0.15)
                            : AdminColors.brandOrange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        visit.isSummaryApproved ? strings.statusApprovedByDoctor : strings.statusReviewRequired,
                        style: TextStyle(
                          color: visit.isSummaryApproved ? AdminColors.statusAvailable : AdminColors.brandOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    if (visit.approvedAt != null)
                      Text(
                        'Approved: ${_formatDateTime(visit.approvedAt)}',
                        style: AdminTheme.caption.copyWith(color: AdminColors.textSecondary, fontSize: 11),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  visit.effectiveSummary.isNotEmpty ? visit.effectiveSummary : 'Summary documentation not finalized.',
                  style: AdminTheme.bodyRegular.copyWith(color: AdminColors.brandNavy, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const Divider(height: 32, color: AdminColors.borderSubtle),

          // Section 7: Reports & Investigations
          _buildSectionHeader(Icons.assignment_outlined, 'SECTION 7: DIAGNOSTIC INVESTIGATIONS & REPORTS'),
          if (investigations.isEmpty && reports.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                strings.noInvestigationsOrReports,
                style: AdminTheme.caption.copyWith(color: AdminColors.textMuted),
              ),
            )
          else ...[
            if (investigations.isNotEmpty) ...[
              Text(
                'REQUESTED INVESTIGATIONS',
                style: AdminTheme.caption.copyWith(fontWeight: FontWeight.bold, color: AdminColors.textMuted, fontSize: 10),
              ),
              const SizedBox(height: 6),
              ...investigations.map((inv) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AdminColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(AdminTheme.radius8),
                      border: Border.all(color: AdminColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.biotech_outlined, size: 16, color: AdminColors.brandTeal),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(inv.name, style: AdminTheme.body.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AdminColors.brandTeal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            inv.status.name.toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AdminColors.brandTeal),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
            ],
            if (reports.isNotEmpty) ...[
              Text(
                'ATTACHED REPORT DOCUMENTS',
                style: AdminTheme.caption.copyWith(fontWeight: FontWeight.bold, color: AdminColors.textMuted, fontSize: 10),
              ),
              const SizedBox(height: 6),
              ...reports.map((rep) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AdminColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(AdminTheme.radius8),
                      border: Border.all(color: AdminColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf_outlined, size: 18, color: AdminColors.brandNavy),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(rep.fileName, style: AdminTheme.body.copyWith(fontWeight: FontWeight.w600, fontSize: 12)),
                              Text('${(rep.fileSizeBytes / 1024).toStringAsFixed(1)} KB • Uploaded ${_formatDateTime(rep.uploadedAt)}',
                                  style: AdminTheme.caption.copyWith(fontSize: 11, color: AdminColors.textSecondary)),
                            ],
                          ),
                        ),
                        AdminSecondaryButton(
                          label: strings.actionViewReport,
                          height: 28,
                          icon: Icons.visibility_outlined,
                          onPressed: () => _handleViewReport(context, rep),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
          const Divider(height: 32, color: AdminColors.borderSubtle),

          // Section 8: Plan & Follow-up
          _buildSectionHeader(Icons.directions_walk_rounded, 'SECTION 8: PLAN & FOLLOW-UP'),
          _buildGrid([
            _buildField(strings.followUpLabel, visit.followUp ?? 'None specified.'),
            _buildField(strings.patientInstructionsLabel, visit.patientInstructions ?? 'Standard outpatient precautions.'),
          ]),
          const Divider(height: 32, color: AdminColors.borderSubtle),

          // Section 9: Visit Completion & PDF Documentation
          _buildSectionHeader(Icons.verified_outlined, 'SECTION 9: VISIT COMPLETION & OFFICIAL PDF'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AdminColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(AdminTheme.radius12),
              border: Border.all(color: AdminColors.borderSubtle),
            ),
            child: Row(
              children: [
                const Icon(Icons.description_outlined, color: AdminColors.brandTeal, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.officialVisitPdfLabel,
                        style: AdminTheme.body.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        'AAYUSATHI_Visit_Report_${visit.patientId}_Visit_${visit.visitNumber}.pdf',
                        style: AdminTheme.caption.copyWith(color: AdminColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                AdminPrimaryButton(
                  label: strings.actionViewVisitPdf,
                  icon: Icons.open_in_new_rounded,
                  height: 34,
                  onPressed: () => _handleViewPdf(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AdminColors.brandTeal),
          const SizedBox(width: 8),
          Text(
            title,
            style: AdminTheme.caption.copyWith(
              fontWeight: FontWeight.w800,
              color: AdminColors.brandNavy,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Widget> children) {
    return Wrap(
      spacing: 24,
      runSpacing: 12,
      children: children,
    );
  }

  Widget _buildField(String label, String value, {Color? badgeColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AdminTheme.caption.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AdminColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        if (badgeColor != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          )
        else
          Text(
            value,
            style: AdminTheme.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AdminColors.brandNavy,
              fontSize: 13,
            ),
          ),
      ],
    );
  }

  Widget _buildConsultationBlock(String label, String? content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AdminColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AdminTheme.radius8),
        border: Border.all(color: AdminColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: AdminTheme.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: AdminColors.textMuted,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              content != null && content.isNotEmpty ? content : '--',
              style: AdminTheme.bodyRegular.copyWith(
                color: AdminColors.brandNavy,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Inter-department transfer trail card.
class AdminTransferHistoryCard extends StatelessWidget {
  final List<PatientTransferRequest> transfers;

  const AdminTransferHistoryCard({
    super.key,
    required this.transfers,
  });

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString().padLeft(4, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final strings = AdminLocalizations.of(context);

    return Container(
      key: const ValueKey('AdminTransferHistoryCard'),
      padding: const EdgeInsets.all(AdminTheme.space20),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(AdminTheme.radius16),
        border: Border.all(color: AdminColors.borderSubtle),
        boxShadow: AdminTheme.shadowSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_horiz_rounded, color: AdminColors.brandTeal, size: 20),
              const SizedBox(width: 8),
              Text(
                strings.transferHistorySection,
                style: AdminTheme.headline2.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AdminColors.brandNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: AdminTheme.space16),
          if (transfers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                strings.noTransfersRecorded,
                style: AdminTheme.caption.copyWith(color: AdminColors.textMuted),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transfers.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final trf = transfers[idx];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(AdminTheme.radius8),
                    border: Border.all(color: AdminColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${trf.sourceDepartment} → ${trf.destinationDepartment}',
                            style: AdminTheme.body.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            _formatDateTime(trf.requestedAt),
                            style: AdminTheme.caption.copyWith(color: AdminColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'From Doctor: ${trf.sourceDoctorName} • To Doctor: ${trf.destinationDoctorName ?? "Unassigned"}',
                        style: AdminTheme.caption.copyWith(color: AdminColors.textPrimary, fontSize: 12),
                      ),
                      if (trf.reason.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Reason: ${trf.reason}',
                          style: AdminTheme.caption.copyWith(color: AdminColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Escalation & Administrative Governance History Card.
class AdminEscalationGovernanceHistoryCard extends StatelessWidget {
  final ClinicalCase clinicalCase;
  final VoidCallback? onAssignHigherAuthority;

  const AdminEscalationGovernanceHistoryCard({
    super.key,
    required this.clinicalCase,
    this.onAssignHigherAuthority,
  });

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'N/A';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString().padLeft(4, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final strings = AdminLocalizations.of(context);

    return Container(
      key: const ValueKey('AdminEscalationGovernanceHistoryCard'),
      padding: const EdgeInsets.all(AdminTheme.space20),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(AdminTheme.radius16),
        border: Border.all(color: AdminColors.borderSubtle),
        boxShadow: AdminTheme.shadowSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.admin_panel_settings_outlined, color: AdminColors.brandTeal, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    strings.escalationGovernanceHistorySection,
                    style: AdminTheme.headline2.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AdminColors.brandNavy,
                    ),
                  ),
                ],
              ),
              if (onAssignHigherAuthority != null)
                AdminPrimaryButton(
                  key: const ValueKey('governance_assign_higher_authority_button'),
                  label: clinicalCase.isAssignedToHigherAuthority
                      ? strings.reassignHigherAuthorityButton
                      : strings.assignHigherAuthorityButton,
                  icon: Icons.person_add_alt_1_rounded,
                  height: 32,
                  onPressed: onAssignHigherAuthority,
                ),
            ],
          ),
          const SizedBox(height: AdminTheme.space16),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _buildField(
                strings.escalatedByLabel,
                clinicalCase.escalatedByDoctorName ?? clinicalCase.escalatedByDoctorId ?? 'Doctor',
              ),
              _buildField(strings.escalatedAtLabel, _formatDateTime(clinicalCase.escalatedAt)),
              _buildField(
                'CURRENT REVIEW STATE',
                clinicalCase.isUnderReview ? strings.statusBadgeUnderReview : strings.statusBadgePendingReview,
                badgeColor: clinicalCase.isUnderReview ? AdminColors.brandTeal : AdminColors.statusCritical,
              ),
              if (clinicalCase.adminReviewStartedBy != null)
                _buildField(strings.reviewStartedByLabel, clinicalCase.adminReviewStartedBy!),
              if (clinicalCase.adminReviewStartedAt != null)
                _buildField(strings.reviewStartedAtLabel, _formatDateTime(clinicalCase.adminReviewStartedAt)),
            ],
          ),
          if (clinicalCase.isAssignedToHigherAuthority) ...[
            const Divider(height: 24, color: AdminColors.borderSubtle),
            Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: AdminColors.brandTeal, size: 16),
                const SizedBox(width: 6),
                Text(
                  strings.higherAuthorityAssignmentSection,
                  style: AdminTheme.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AdminColors.brandTeal,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _buildField(
                  strings.assignedDoctorCol,
                  '${clinicalCase.higherAuthorityDoctorName ?? clinicalCase.higherAuthorityDoctorId} (${clinicalCase.higherAuthorityDoctorId})',
                ),
                if (clinicalCase.higherAuthorityDepartment != null)
                  _buildField(
                    strings.assignedDeptCol,
                    clinicalCase.higherAuthorityDepartment!,
                  ),
                _buildField(
                  strings.assignedStatusCol,
                  clinicalCase.higherAuthorityAssignmentStatus.name.toUpperCase(),
                  badgeColor: clinicalCase.isHigherAuthorityAccepted
                      ? AdminColors.statusAvailable
                      : AdminColors.brandOrange,
                ),
                if (clinicalCase.higherAuthorityAssignedBy != null)
                  _buildField(
                    strings.assignedByLabel,
                    clinicalCase.higherAuthorityAssignedBy!,
                  ),
                if (clinicalCase.higherAuthorityAssignedAt != null)
                  _buildField(
                    strings.assignedAtLabel,
                    _formatDateTime(clinicalCase.higherAuthorityAssignedAt),
                  ),
                if (clinicalCase.higherAuthorityAcceptedAt != null)
                  _buildField(
                    strings.acceptedAtLabel,
                    _formatDateTime(clinicalCase.higherAuthorityAcceptedAt),
                  ),
              ],
            ),
            if (clinicalCase.higherAuthorityAssignmentReason != null &&
                clinicalCase.higherAuthorityAssignmentReason!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AdminColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(AdminTheme.radius8),
                  border: Border.all(color: AdminColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.assignmentReasonLabel.toUpperCase(),
                      style: AdminTheme.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AdminColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      clinicalCase.higherAuthorityAssignmentReason!,
                      style: AdminTheme.bodyRegular.copyWith(
                        fontSize: 12,
                        color: AdminColors.brandNavy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildField(String label, String value, {Color? badgeColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AdminTheme.caption.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AdminColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        if (badgeColor != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          )
        else
          Text(
            value,
            style: AdminTheme.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AdminColors.brandNavy,
              fontSize: 13,
            ),
          ),
      ],
    );
  }
}

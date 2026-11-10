import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../../models/patient.dart';
import '../../models/vital_reading.dart';
import '../localization/doctor_localizations.dart';
import '../localization/doctor_strings.dart';
import '../models/clinical_case.dart';
import '../models/clinical_visit.dart';
import '../models/patient_report.dart';
import '../models/patient_transfer_request.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import 'doctor_buttons.dart';
import 'doctor_case_timeline_view.dart';
import 'doctor_visit_detail_dialog.dart';

/// Top bar in Doctor Patient Workspace displaying physician identity, consultation
/// lock status, queue number, and previous doctor badges.
class DoctorPatientWorkspaceHeader extends StatelessWidget {
  final String doctorName;
  final String doctorDepartment;
  final String queueNumber;
  final bool isPreviousDoctorRequested;
  final VoidCallback onBackAttempt;
  final KioskLocale locale;

  const DoctorPatientWorkspaceHeader({
    super.key,
    required this.doctorName,
    required this.doctorDepartment,
    required this.queueNumber,
    this.isPreviousDoctorRequested = false,
    required this.onBackAttempt,
    this.locale = KioskLocale.english,
  });

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(locale);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DoctorTheme.space24,
        vertical: DoctorTheme.space16,
      ),
      decoration: const BoxDecoration(
        color: DoctorColors.surface,
        border: Border(
          bottom: BorderSide(
            color: DoctorColors.border,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button (triggers confirmation)
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: DoctorColors.textPrimary),
            tooltip: strings.back,
            onPressed: onBackAttempt,
          ),
          const SizedBox(width: DoctorTheme.space12),

          // Portal Branding & Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    strings.appName,
                    style: DoctorTheme.headline2.copyWith(
                      fontWeight: FontWeight.w800,
                      color: DoctorColors.brandTeal,
                      fontSize: 18,
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
                      strings.patientWorkspaceTitle,
                      style: DoctorTheme.badgeText.copyWith(
                        color: DoctorColors.brandTeal,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '$doctorName • $doctorDepartment',
                style: DoctorTheme.bodyMuted.copyWith(
                  color: DoctorColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Queue Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: DoctorColors.brandTeal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(DoctorTheme.radius8),
              border: Border.all(
                color: DoctorColors.brandTeal.withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.confirmation_number_outlined,
                    size: 16, color: DoctorColors.brandTeal),
                const SizedBox(width: 6),
                Text(
                  '${strings.queueNumberLabel}: $queueNumber',
                  style: DoctorTheme.badgeText.copyWith(
                    color: DoctorColors.brandTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DoctorTheme.space12),

          // Previous Doctor Requested Badge (if applicable)
          if (isPreviousDoctorRequested) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: DoctorColors.brandNavy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                border: Border.all(
                  color: DoctorColors.brandNavy.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history_edu_rounded,
                      size: 15, color: DoctorColors.brandNavy),
                  const SizedBox(width: 6),
                  Text(
                    strings.previousDoctorRequestBadge,
                    style: DoctorTheme.caption.copyWith(
                      color: DoctorColors.brandNavy,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DoctorTheme.space12),
          ],

          // Consultation Status Lock Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: DoctorColors.brandOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DoctorTheme.radius8),
              border: Border.all(
                color: DoctorColors.brandOrange.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: DoctorColors.brandOrange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  strings.statusInConsultation.toUpperCase(),
                  style: DoctorTheme.badgeText.copyWith(
                    color: DoctorColors.statusInConsultation,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Authorized Patient Identity Banner.
/// Strictly displays Name, Age, Gender, Blood Group, Patient ID.
/// Strictly NEVER displays Aadhaar number.
class DoctorPatientIdentityCard extends StatelessWidget {
  final Patient patient;
  final KioskLocale locale;

  const DoctorPatientIdentityCard({
    super.key,
    required this.patient,
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
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Patient Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: DoctorColors.brandTeal.withValues(alpha: 0.12),
              child: Text(
                patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
                style: DoctorTheme.headline1.copyWith(
                  color: DoctorColors.brandTeal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: DoctorTheme.space16),

            // Primary Name & ID
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    patient.name,
                    style: DoctorTheme.headline2.copyWith(
                      color: DoctorColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${strings.patientIdLabel}: ',
                        style: DoctorTheme.caption.copyWith(
                          color: DoctorColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        patient.patientId,
                        style: DoctorTheme.bodyBold.copyWith(
                          color: DoctorColors.brandNavy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const VerticalDivider(width: 24, thickness: 1, color: DoctorColors.border),

            // Age
            Expanded(
              flex: 2,
              child: _buildInfoItem(
                label: strings.ageLabel,
                value: '${patient.age} yrs',
                icon: Icons.cake_outlined,
              ),
            ),

            const VerticalDivider(width: 24, thickness: 1, color: DoctorColors.border),

            // Gender
            Expanded(
              flex: 2,
              child: _buildInfoItem(
                label: strings.genderLabel,
                value: patient.gender.isNotEmpty ? patient.gender : strings.notAvailable,
                icon: Icons.person_outline_rounded,
              ),
            ),

            const VerticalDivider(width: 24, thickness: 1, color: DoctorColors.border),

            // Blood Group
            Expanded(
              flex: 2,
              child: _buildInfoItem(
                label: strings.bloodGroupLabel,
                value: patient.bloodGroup.isNotEmpty ? patient.bloodGroup : strings.notAvailable,
                icon: Icons.bloodtype_outlined,
                valueColor: DoctorColors.brandOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: DoctorColors.textMuted),
            const SizedBox(width: 4),
            Text(
              label.toUpperCase(),
              style: DoctorTheme.caption.copyWith(
                color: DoctorColors.textMuted,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: DoctorTheme.bodyBold.copyWith(
            color: valueColor ?? DoctorColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Current Vitals Strip displaying validated telemetry.
class DoctorCurrentVitalsBar extends StatelessWidget {
  final VitalReading? vitals;
  final KioskLocale locale;

  const DoctorCurrentVitalsBar({
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
                strings.currentVitals,
                style: DoctorTheme.badgeText.copyWith(
                  color: DoctorColors.brandTeal,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (vitals != null)
                Text(
                  '${vitals!.timestamp.hour.toString().padLeft(2, '0')}:${vitals!.timestamp.minute.toString().padLeft(2, '0')}',
                  style: DoctorTheme.caption.copyWith(
                    color: DoctorColors.textMuted,
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
                  value: vitals?.spo2 != null ? '${vitals!.spo2}%' : strings.notAvailable,
                  icon: Icons.air_rounded,
                  color: DoctorColors.brandTeal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildVitalBox(
                  label: strings.heartRateLabel,
                  value: vitals?.heartRate != null
                      ? '${vitals!.heartRate} BPM'
                      : strings.notAvailable,
                  icon: Icons.favorite_rounded,
                  color: DoctorColors.statusBusy,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(DoctorTheme.radius8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(DoctorTheme.radius6),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: DoctorTheme.caption.copyWith(
                    color: DoctorColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
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

/// Clinical Cases & Visits Section (2-Column layout with Case Timeline support).
class DoctorClinicalRecordsSection extends StatefulWidget {
  final List<ClinicalCase> cases;
  final ClinicalCase? selectedCase;
  final List<ClinicalVisit> visits;
  final List<PatientTransferRequest> transfers;
  final ValueChanged<ClinicalCase> onSelectCase;
  final VoidCallback onStartNewCase;
  final VoidCallback onAddVisit;
  final VoidCallback? onCloseCase;
  final ValueChanged<ClinicalVisit>? onViewVisit;
  final KioskLocale locale;

  const DoctorClinicalRecordsSection({
    super.key,
    required this.cases,
    required this.selectedCase,
    required this.visits,
    this.transfers = const [],
    required this.onSelectCase,
    required this.onStartNewCase,
    required this.onAddVisit,
    this.onCloseCase,
    this.onViewVisit,
    this.locale = KioskLocale.english,
  });

  @override
  State<DoctorClinicalRecordsSection> createState() =>
      _DoctorClinicalRecordsSectionState();
}

class _DoctorClinicalRecordsSectionState
    extends State<DoctorClinicalRecordsSection> {
  int _activeTab = 0; // 0: Visit History, 1: Case Timeline

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(widget.locale);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Cases List
        Expanded(
          flex: 4,
          child: Container(
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.folder_open_rounded,
                            size: 18, color: DoctorColors.brandNavy),
                        const SizedBox(width: 8),
                        Text(
                          strings.myCases,
                          style: DoctorTheme.badgeText.copyWith(
                            color: DoctorColors.brandNavy,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    DoctorOutlineButton(
                      label: strings.startNewCase,
                      icon: Icons.add_rounded,
                      onPressed: widget.onStartNewCase,
                    ),
                  ],
                ),
                const SizedBox(height: DoctorTheme.space12),

                if (widget.cases.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text(
                        strings.noCasesFound,
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
                    itemCount: widget.cases.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final c = widget.cases[index];
                      final isSelected =
                          widget.selectedCase?.caseId == c.caseId;
                      return _buildCaseCard(c, isSelected, strings);
                    },
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(width: DoctorTheme.space16),

        // Right Column: Visits History & Case Timeline
        Expanded(
          flex: 6,
          child: Container(
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
                // Top Header Row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.folder_shared_rounded,
                          size: 18,
                          color: DoctorColors.brandTeal,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.selectedCase != null
                                ? '${widget.selectedCase!.domain.toUpperCase()} — ${widget.selectedCase!.title}'
                                : strings.visits,
                            style: DoctorTheme.badgeText.copyWith(
                              color: DoctorColors.brandTeal,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (widget.selectedCase != null &&
                        widget.selectedCase!.isOpen) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.onCloseCase != null) ...[
                            DoctorSecondaryButton(
                              label: strings.closeCaseButton,
                              icon: Icons.lock_outline_rounded,
                              onPressed: widget.onCloseCase,
                              height: 36,
                            ),
                            const SizedBox(width: 8),
                          ],
                          DoctorPrimaryButton(
                            label: strings.continueExistingCaseButton,
                            icon: Icons.add_rounded,
                            onPressed: widget.onAddVisit,
                            height: 36,
                          ),
                        ],
                      ),
                    ] else if (widget.selectedCase != null &&
                        widget.selectedCase!.isClosed) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: DoctorColors.statusOffline
                              .withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(DoctorTheme.radius6),
                          border: Border.all(
                            color: DoctorColors.statusOffline
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              size: 13,
                              color: DoctorColors.statusOffline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              strings.closedCasesTitle.toUpperCase(),
                              style: DoctorTheme.caption.copyWith(
                                color: DoctorColors.statusOffline,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: DoctorTheme.space12),

                if (widget.selectedCase == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(
                      child: Text(
                        strings.selectCasePrompt,
                        style: DoctorTheme.subtitle.copyWith(
                          color: DoctorColors.textMuted,
                        ),
                      ),
                    ),
                  )
                else ...[
                  // Case Information Card (Phase D14 & D15)
                  _buildCaseInfoCard(widget.selectedCase!, strings),
                  const SizedBox(height: DoctorTheme.space12),

                  // Stationary segmented Tab switcher: Visit History vs Case Timeline
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: DoctorColors.background,
                      borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                      border: Border.all(color: DoctorColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTabButton(0, strings.visitHistoryTab, Icons.list_alt_rounded),
                        const SizedBox(width: 4),
                        _buildTabButton(1, strings.caseTimelineTab, Icons.timeline_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: DoctorTheme.space12),

                  // Stable IndexedStack tab content to guarantee zero layout shake / jump
                  IndexedStack(
                    key: const ValueKey('DoctorClinicalRecords_IndexedStack'),
                    index: _activeTab,
                    children: [
                      // Tab 0: Visit History
                      KeyedSubtree(
                        key: const ValueKey('Tab_VisitHistory'),
                        child: widget.visits.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 32.0),
                                child: Center(
                                  child: Text(
                                    strings.noVisitsFound,
                                    style: DoctorTheme.bodyMuted.copyWith(
                                      color: DoctorColors.textMuted,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: widget.visits.length,
                                separatorBuilder: (ctx, i) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final v = widget.visits[index];
                                  return _buildVisitCard(context, v, strings);
                                },
                              ),
                      ),
                      // Tab 1: Case Timeline View (Phase D14 & D15)
                      KeyedSubtree(
                        key: const ValueKey('Tab_CaseTimeline'),
                        child: DoctorCaseTimelineView(
                          clinicalCase: widget.selectedCase!,
                          visits: widget.visits,
                          transfers: widget.transfers,
                          onViewVisit: widget.onViewVisit,
                          locale: widget.locale,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _activeTab == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (_activeTab != index) {
            setState(() {
              _activeTab = index;
            });
          }
        },
        borderRadius: BorderRadius.circular(DoctorTheme.radius6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? DoctorColors.surface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(DoctorTheme.radius6),
            border: Border.all(
              color: isSelected
                  ? DoctorColors.brandTeal.withValues(alpha: 0.35)
                  : Colors.transparent,
            ),
            boxShadow: isSelected ? DoctorTheme.shadowSubtle : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? DoctorColors.brandTeal : DoctorColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: DoctorTheme.caption.copyWith(
                  color: isSelected
                      ? DoctorColors.brandTeal
                      : DoctorColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaseInfoCard(ClinicalCase c, DoctorStrings strings) {
    final created = c.createdAt;
    final updated = c.updatedAt;
    final formattedCreated =
        '${created.day.toString().padLeft(2, '0')}/${created.month.toString().padLeft(2, '0')}/${created.year}';
    final formattedUpdated =
        '${updated.day.toString().padLeft(2, '0')}/${updated.month.toString().padLeft(2, '0')}/${updated.year}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DoctorColors.background,
        borderRadius: BorderRadius.circular(DoctorTheme.radius8),
        border: Border.all(color: DoctorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${strings.caseInformationTitle} (${c.caseId})',
                style: DoctorTheme.caption.copyWith(
                  color: DoctorColors.brandNavy,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: c.isOpen
                      ? DoctorColors.statusAvailable.withValues(alpha: 0.12)
                      : DoctorColors.statusOffline.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                ),
                child: Text(
                  c.isOpen ? strings.openCase : strings.closedCase,
                  style: DoctorTheme.caption.copyWith(
                    color: c.isOpen
                        ? DoctorColors.statusAvailable
                        : DoctorColors.statusOffline,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 12, color: DoctorColors.border),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.createdDateLabel,
                      style: DoctorTheme.caption.copyWith(
                        color: DoctorColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      formattedCreated,
                      style: DoctorTheme.caption.copyWith(
                        color: DoctorColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.lastUpdatedLabel,
                      style: DoctorTheme.caption.copyWith(
                        color: DoctorColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      formattedUpdated,
                      style: DoctorTheme.caption.copyWith(
                        color: DoctorColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.visits,
                      style: DoctorTheme.caption.copyWith(
                        color: DoctorColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      '${c.visitCount}',
                      style: DoctorTheme.caption.copyWith(
                        color: DoctorColors.brandNavy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (c.isClosed) ...[
            const Divider(height: 12, color: DoctorColors.border),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DoctorColors.statusOffline.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(DoctorTheme.radius6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded,
                      size: 14, color: DoctorColors.statusOffline),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${strings.closedByDoctorLabel}: ${c.closedByDoctorName ?? c.closedByDoctorId ?? "Doctor"} • ${c.closedAt != null ? "${c.closedAt!.day}/${c.closedAt!.month}/${c.closedAt!.year}" : ""}${c.closureNote != null && c.closureNote!.isNotEmpty ? " — \"${c.closureNote}\"" : ""}',
                      style: DoctorTheme.caption.copyWith(
                        color: DoctorColors.statusOffline,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildCaseCard(
    ClinicalCase c,
    bool isSelected,
    DoctorStrings strings,
  ) {
    return InkWell(
      onTap: () => widget.onSelectCase(c),
      borderRadius: BorderRadius.circular(DoctorTheme.radius8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? DoctorColors.brandTeal.withValues(alpha: 0.08)
              : DoctorColors.background,
          borderRadius: BorderRadius.circular(DoctorTheme.radius8),
          border: Border.all(
            color: isSelected ? DoctorColors.brandTeal : DoctorColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        c.domain,
                        style: DoctorTheme.caption.copyWith(
                          color: DoctorColors.brandNavy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: c.isOpen
                              ? DoctorColors.statusAvailable
                                  .withValues(alpha: 0.12)
                              : DoctorColors.statusOffline
                                  .withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(DoctorTheme.radius6),
                        ),
                        child: Text(
                          c.isOpen ? strings.openCase : strings.closedCase,
                          style: DoctorTheme.caption.copyWith(
                            color: c.isOpen
                                ? DoctorColors.statusAvailable
                                : DoctorColors.statusOffline,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${c.visitCount} ${strings.visits.toLowerCase()}',
                  style: DoctorTheme.caption.copyWith(
                    color: DoctorColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              c.title,
              style: DoctorTheme.bodyBold.copyWith(
                color: DoctorColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              c.caseId,
              style: DoctorTheme.caption.copyWith(
                color: DoctorColors.textMuted,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: c.isOpen
                        ? DoctorColors.brandTeal.withValues(alpha: 0.1)
                        : DoctorColors.border.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    c.isOpen
                        ? strings.continueCaseButton
                        : strings.viewHistoryButton,
                    style: DoctorTheme.caption.copyWith(
                      color: c.isOpen
                          ? DoctorColors.brandTeal
                          : DoctorColors.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: isSelected
                      ? DoctorColors.brandTeal
                      : DoctorColors.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitCard(
    BuildContext context,
    ClinicalVisit v,
    DoctorStrings strings,
  ) {
    Color statusColor;
    String statusText;

    if (v.isActive) {
      statusColor = DoctorColors.brandOrange;
      statusText = strings.activeStatusLabel;
    } else if (v.isTransferred) {
      statusColor = DoctorColors.brandTeal;
      statusText = strings.transferRequestBadge;
    } else {
      statusColor = DoctorColors.statusAvailable;
      statusText = strings.completedStatusLabel;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DoctorColors.background,
        borderRadius: BorderRadius.circular(DoctorTheme.radius8),
        border: Border.all(color: DoctorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${strings.visit} ${v.visitNumber}',
                style: DoctorTheme.bodyBold.copyWith(
                  color: DoctorColors.brandNavy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                    ),
                    child: Text(
                      statusText,
                      style: DoctorTheme.caption.copyWith(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (v.isCompleted || v.isTransferred) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        if (widget.onViewVisit != null) {
                          widget.onViewVisit!(v);
                        } else {
                          showDialog(
                            context: context,
                            builder: (ctx) => DoctorVisitDetailDialog(
                              visit: v,
                              domain: widget.selectedCase?.domain ?? '',
                              locale: widget.locale,
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.visibility_outlined,
                              size: 14,
                              color: DoctorColors.brandTeal,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              strings.viewVisitDetailsButton,
                              style: DoctorTheme.caption.copyWith(
                                color: DoctorColors.brandTeal,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${strings.attendingDoctorLabel}: ${(v.doctorName != null && v.doctorName!.isNotEmpty) ? v.doctorName! : v.doctorId}',
            style: DoctorTheme.bodyMuted.copyWith(
              color: DoctorColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${strings.visitStartedAtLabel}: ${v.startedAt.day}/${v.startedAt.month}/${v.startedAt.year} ${v.startedAt.hour.toString().padLeft(2, '0')}:${v.startedAt.minute.toString().padLeft(2, '0')}',
            style: DoctorTheme.caption.copyWith(
              color: DoctorColors.textMuted,
              fontSize: 10,
            ),
          ),
          if (v.summary != null && v.summary!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              v.summary!,
              style: DoctorTheme.bodyRegular.copyWith(
                color: DoctorColors.textPrimary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              strings.clinicalDocumentationNotice,
              style: DoctorTheme.caption.copyWith(
                color: DoctorColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Diagnostic Reports section with category filter tabs.
class DoctorReportsSection extends StatefulWidget {
  final List<PatientReport> reports;
  final KioskLocale locale;

  const DoctorReportsSection({
    super.key,
    required this.reports,
    this.locale = KioskLocale.english,
  });

  @override
  State<DoctorReportsSection> createState() => _DoctorReportsSectionState();
}

class _DoctorReportsSectionState extends State<DoctorReportsSection> {
  PatientReportStatus _selectedStatus = PatientReportStatus.available;

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(widget.locale);
    final filtered = widget.reports.where((r) => r.status == _selectedStatus).toList();

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
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.assignment_outlined,
                      size: 18, color: DoctorColors.brandNavy),
                  const SizedBox(width: 8),
                  Text(
                    strings.reportsTitle,
                    style: DoctorTheme.badgeText.copyWith(
                      color: DoctorColors.brandNavy,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildTabButton(
                    label: strings.availableReportsTab,
                    status: PatientReportStatus.available,
                  ),
                  _buildTabButton(
                    label: strings.requestedReportsTab,
                    status: PatientReportStatus.requested,
                  ),
                  _buildTabButton(
                    label: strings.uploadedReportsTab,
                    status: PatientReportStatus.uploaded,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: DoctorTheme.space12),

          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  strings.noReportsFound,
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
              itemCount: filtered.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final r = filtered[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DoctorColors.background,
                    borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                    border: Border.all(color: DoctorColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        r.type == PatientReportType.lab
                            ? Icons.biotech_rounded
                            : Icons.description_outlined,
                        size: 20,
                        color: DoctorColors.brandTeal,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.title,
                              style: DoctorTheme.bodyBold.copyWith(
                                color: DoctorColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (r.summary != null)
                              Text(
                                r.summary!,
                                style: DoctorTheme.bodyMuted.copyWith(
                                  color: DoctorColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '${r.date.day}/${r.date.month}/${r.date.year}',
                        style: DoctorTheme.caption.copyWith(
                          color: DoctorColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required PatientReportStatus status,
  }) {
    final isSelected = _selectedStatus == status;
    return InkWell(
      onTap: () => setState(() => _selectedStatus = status),
      borderRadius: BorderRadius.circular(DoctorTheme.radius6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? DoctorColors.brandNavy.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(DoctorTheme.radius6),
          border: Border.all(
            color: isSelected ? DoctorColors.brandNavy : DoctorColors.border,
          ),
        ),
        child: Text(
          label,
          style: DoctorTheme.caption.copyWith(
            color: isSelected ? DoctorColors.brandNavy : DoctorColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Clean placeholder for Phase D8 consultation workspace.
class DoctorConsultationPlaceholderCard extends StatelessWidget {
  final KioskLocale locale;

  const DoctorConsultationPlaceholderCard({
    super.key,
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
        border: Border.all(
          color: DoctorColors.brandTeal.withValues(alpha: 0.3),
        ),
        boxShadow: DoctorTheme.shadowSubtle,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DoctorColors.brandTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DoctorTheme.radius8),
            ),
            child: const Icon(
              Icons.medical_services_outlined,
              size: 28,
              color: DoctorColors.brandTeal,
            ),
          ),
          const SizedBox(width: DoctorTheme.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.navConsultation.toUpperCase(),
                  style: DoctorTheme.badgeText.copyWith(
                    color: DoctorColors.brandNavy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.consultationWorkspacePlaceholder,
                  style: DoctorTheme.bodyMuted.copyWith(
                    color: DoctorColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom Action Bar for Transfer / Escalation / Draft / Preview / Complete actions.
class DoctorWorkspaceBottomBar extends StatelessWidget {
  final VoidCallback? onSaveDraft;
  final VoidCallback? onPreviewReport;
  final VoidCallback? onEscalateCase;
  final VoidCallback onTransfer;
  final VoidCallback onComplete;
  final KioskLocale locale;

  const DoctorWorkspaceBottomBar({
    super.key,
    this.onSaveDraft,
    this.onPreviewReport,
    this.onEscalateCase,
    required this.onTransfer,
    required this.onComplete,
    this.locale = KioskLocale.english,
  });

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(locale);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DoctorTheme.space24,
        vertical: DoctorTheme.space16,
      ),
      decoration: const BoxDecoration(
        color: DoctorColors.surface,
        border: Border(
          top: BorderSide(
            color: DoctorColors.border,
            width: 1.0,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onSaveDraft != null) ...[
              DoctorSecondaryButton(
                label: strings.saveDraftButton,
                icon: Icons.save_outlined,
                onPressed: onSaveDraft,
                height: 40,
              ),
              const SizedBox(width: DoctorTheme.space12),
            ],
            if (onPreviewReport != null) ...[
              DoctorSecondaryButton(
                label: strings.previewVisitReportButton,
                icon: Icons.picture_as_pdf_outlined,
                onPressed: onPreviewReport,
                height: 40,
              ),
              const SizedBox(width: DoctorTheme.space12),
            ],
            if (onEscalateCase != null) ...[
              DoctorOutlineButton(
                key: const ValueKey('escalate_case_bottom_button'),
                label: strings.escalateCaseButton,
                icon: Icons.warning_amber_rounded,
                onPressed: onEscalateCase!,
              ),
              const SizedBox(width: DoctorTheme.space12),
            ],
            DoctorOutlineButton(
              label: strings.transferPatientButton,
              icon: Icons.swap_horiz_rounded,
              onPressed: onTransfer,
            ),
            const SizedBox(width: DoctorTheme.space12),
            DoctorPrimaryButton(
              label: strings.completeVisitButton,
              icon: Icons.check_circle_outline_rounded,
              onPressed: onComplete,
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal dialog for starting a new clinical Case.
class DoctorNewCaseDialog extends StatefulWidget {
  final String defaultDomain;
  final Function(String domain, String title) onConfirm;
  final KioskLocale locale;

  const DoctorNewCaseDialog({
    super.key,
    required this.defaultDomain,
    required this.onConfirm,
    this.locale = KioskLocale.english,
  });

  @override
  State<DoctorNewCaseDialog> createState() => _DoctorNewCaseDialogState();
}

class _DoctorNewCaseDialogState extends State<DoctorNewCaseDialog> {
  static const List<String> _allDomains = [
    'General Medicine',
    'Cardiology',
    'Pediatrics',
    'Dermatology',
    'Orthopedics',
    'Neurology',
    'Gastroenterology',
    'ENT',
  ];

  late final TextEditingController _titleController;
  late String _selectedDomain;
  late List<String> _domains;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    final normalized = widget.defaultDomain.isNotEmpty
        ? ClinicalCase.normalizeDepartment(widget.defaultDomain)
        : 'General Medicine';
    _selectedDomain = normalized == 'Department not available'
        ? 'General Medicine'
        : normalized;
    final domainSet = <String>{_selectedDomain, ..._allDomains};
    _domains = domainSet.toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(widget.locale);

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: DoctorColors.brandNavy.withValues(alpha: 0.20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DoctorTheme.radius16),
        side: const BorderSide(color: DoctorColors.border, width: 1.0),
      ),
      titlePadding: const EdgeInsets.fromLTRB(
        DoctorTheme.space24,
        DoctorTheme.space20,
        DoctorTheme.space16,
        DoctorTheme.space12,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: DoctorTheme.space24,
        vertical: DoctorTheme.space8,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        DoctorTheme.space24,
        DoctorTheme.space12,
        DoctorTheme.space24,
        DoctorTheme.space20,
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DoctorColors.brandTeal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(DoctorTheme.radius8),
            ),
            child: const Icon(
              Icons.folder_open_rounded,
              color: DoctorColors.brandTeal,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              strings.startNewCase,
              style: DoctorTheme.headline2.copyWith(
                color: DoctorColors.brandNavy,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 0.3,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              size: 20,
              color: DoctorColors.textSecondary,
            ),
            tooltip: strings.cancel,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 460,
          minWidth: 320,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.caseDomainLabel,
                style: DoctorTheme.bodyBold.copyWith(
                  color: DoctorColors.brandNavy,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                  border: Border.all(color: DoctorColors.border, width: 1.2),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    key: const Key('case_domain_dropdown'),
                    value: _selectedDomain,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: DoctorColors.brandNavy,
                      size: 22,
                    ),
                    items: _domains.map((d) {
                      return DropdownMenuItem<String>(
                        value: d,
                        child: Text(
                          d,
                          style: DoctorTheme.bodyBold.copyWith(
                            color: DoctorColors.brandNavy,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedDomain = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: DoctorTheme.space16),
              Text(
                strings.caseTitleLabel,
                style: DoctorTheme.bodyBold.copyWith(
                  color: DoctorColors.brandNavy,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                key: const Key('case_title_input'),
                controller: _titleController,
                style: DoctorTheme.bodyRegular.copyWith(
                  color: DoctorColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: strings.caseTitleHint,
                  hintStyle: DoctorTheme.bodyRegular.copyWith(
                    color: DoctorColors.textMuted,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                    borderSide: const BorderSide(
                      color: DoctorColors.border,
                      width: 1.2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                    borderSide: const BorderSide(
                      color: DoctorColors.border,
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                    borderSide: const BorderSide(
                      color: DoctorColors.brandTeal,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          key: const Key('cancel_new_case_button'),
          style: OutlinedButton.styleFrom(
            foregroundColor: DoctorColors.brandNavy,
            side: const BorderSide(color: DoctorColors.border, width: 1.2),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DoctorTheme.radius8),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            strings.cancel,
            style: DoctorTheme.caption.copyWith(
              color: DoctorColors.brandNavy,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          key: const Key('save_new_case_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: DoctorColors.brandTeal,
            foregroundColor: Colors.white,
            elevation: 1,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DoctorTheme.radius8),
            ),
          ),
          onPressed: () {
            final title = _titleController.text.trim();
            if (title.isNotEmpty) {
              widget.onConfirm(_selectedDomain, title);
              Navigator.of(context).pop();
            }
          },
          child: Text(
            strings.save,
            style: DoctorTheme.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// Confirmation Dialog when attempting to leave active workspace.
class DoctorLeaveWorkspaceDialog extends StatelessWidget {
  final KioskLocale locale;

  const DoctorLeaveWorkspaceDialog({
    super.key,
    this.locale = KioskLocale.english,
  });

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(locale);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: DoctorColors.brandOrange),
          const SizedBox(width: 8),
          Text(
            strings.consultationInProgressTitle,
            style: DoctorTheme.headline2.copyWith(
              color: DoctorColors.brandNavy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      content: Text(
        strings.consultationInProgressNotice,
        style: DoctorTheme.bodyRegular,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            strings.stayButton,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: DoctorColors.brandOrange,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(strings.leaveWorkspaceButton),
        ),
      ],
    );
  }
}

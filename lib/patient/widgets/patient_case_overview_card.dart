import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../../doctor/localization/doctor_localizations.dart';
import '../../doctor/localization/doctor_strings.dart';
import '../../doctor/models/clinical_visit.dart';
import '../../doctor/theme/doctor_colors.dart';
import '../../doctor/theme/doctor_theme.dart';
import '../services/patient_clinical_records_service.dart';

/// Integration-ready Patient module widget representing a clinical case with
/// its open/ongoing status, completed visit timeline, and diagnostic report states.
class PatientCaseOverviewCard extends StatelessWidget {
  final PatientCaseRecordBundle bundle;
  final ValueChanged<ClinicalVisit>? onVisitTapped;
  final KioskLocale locale;

  const PatientCaseOverviewCard({
    super.key,
    required this.bundle,
    this.onVisitTapped,
    this.locale = KioskLocale.english,
  });

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(locale);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
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
          // Case Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bundle.title,
                      style: DoctorTheme.cardTitle.copyWith(
                        color: DoctorColors.brandNavy,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${bundle.domain} • ${bundle.caseId}',
                      style: DoctorTheme.caption.copyWith(
                        color: DoctorColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: bundle.isOpen
                      ? DoctorColors.statusAvailable.withValues(alpha: 0.12)
                      : DoctorColors.statusOffline.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: bundle.isOpen
                        ? DoctorColors.statusAvailable.withValues(alpha: 0.3)
                        : DoctorColors.statusOffline.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  bundle.isOpen
                      ? strings.caseStatusOpenBadge
                      : strings.caseStatusClosedBadge,
                  style: TextStyle(
                    color: bundle.isOpen
                        ? DoctorColors.statusAvailable
                        : DoctorColors.statusOffline,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DoctorTheme.space12),
          const Divider(height: 1, color: DoctorColors.border),
          const SizedBox(height: DoctorTheme.space12),

          // Visits Timeline
          Text(
            '${strings.visits} (${bundle.visitCount})',
            style: DoctorTheme.badgeText.copyWith(
              color: DoctorColors.brandTeal,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: DoctorTheme.space8),

          if (bundle.visits.isEmpty)
            Text(
              strings.noVisitsFound,
              style: DoctorTheme.caption.copyWith(color: DoctorColors.textMuted),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bundle.visits.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final v = bundle.visits[index];
                final reports = bundle.visitReports[v.visitId] ?? const [];
                return _buildVisitRow(v, reports, strings);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildVisitRow(
    ClinicalVisit v,
    List<dynamic> reports,
    DoctorStrings strings,
  ) {
    return InkWell(
      onTap: onVisitTapped != null ? () => onVisitTapped!(v) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: DoctorColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: DoctorColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${strings.visit} ${v.visitNumber} — ${v.doctorName ?? v.doctorId}',
                  style: DoctorTheme.bodyBold.copyWith(
                    color: DoctorColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: v.isCompleted
                        ? DoctorColors.statusAvailable.withValues(alpha: 0.1)
                        : v.isTransferred
                            ? DoctorColors.brandTeal.withValues(alpha: 0.12)
                            : DoctorColors.brandOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    v.isCompleted
                        ? strings.completedStatusLabel
                        : v.isTransferred
                            ? strings.transferRequestBadge
                            : strings.activeStatusLabel,
                    style: TextStyle(
                      color: v.isCompleted
                          ? DoctorColors.statusAvailable
                          : v.isTransferred
                              ? DoctorColors.brandTeal
                              : DoctorColors.brandOrange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${v.startedAt.day}/${v.startedAt.month}/${v.startedAt.year} • ${v.doctorQualification ?? ""}',
              style: DoctorTheme.caption.copyWith(
                color: DoctorColors.textMuted,
                fontSize: 10,
              ),
            ),
            if (v.effectiveSummary.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                v.effectiveSummary,
                style: DoctorTheme.body.copyWith(
                  color: DoctorColors.textSecondary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (reports.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 12,
                    color: DoctorColors.brandTeal,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${reports.length} report(s) linked',
                    style: DoctorTheme.caption.copyWith(
                      color: DoctorColors.brandTeal,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

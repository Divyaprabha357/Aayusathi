import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../localization/doctor_localizations.dart';
import '../models/clinical_visit.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import 'doctor_buttons.dart';

/// Modal dialog presented upon successful backend completion of a consultation visit.
///
/// Prominently displays:
/// - Visit Number
/// - Case ID and Department
/// - Attending Doctor
/// - Completion Timestamp
/// - Confirmation that Case status remains OPEN / ONGOING
class DoctorVisitCompletedDialog extends StatelessWidget {
  final ClinicalVisit visit;
  final String domain;
  final VoidCallback onReturnToDashboard;
  final KioskLocale locale;

  const DoctorVisitCompletedDialog({
    super.key,
    required this.visit,
    required this.domain,
    required this.onReturnToDashboard,
    this.locale = KioskLocale.english,
  });

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(locale);
    final completedDate = visit.completedAt ?? DateTime.now();
    final formattedDate =
        '${completedDate.day.toString().padLeft(2, '0')}/${completedDate.month.toString().padLeft(2, '0')}/${completedDate.year} ${completedDate.hour.toString().padLeft(2, '0')}:${completedDate.minute.toString().padLeft(2, '0')}';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DoctorTheme.radius16),
      ),
      backgroundColor: DoctorColors.surface,
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 520,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DoctorTheme.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: DoctorColors.statusNormal.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: DoctorColors.statusNormal,
                  size: 40,
                ),
              ),
              const SizedBox(height: DoctorTheme.space16),

              // Title & Subtitle
              Text(
                strings.visitCompletedSuccessTitle,
                style: DoctorTheme.cardTitle.copyWith(
                  color: DoctorColors.brandNavy,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DoctorTheme.space8),
              Text(
                strings.visitCompletedSuccessSubtitle,
                style: DoctorTheme.bodyMuted.copyWith(
                  color: DoctorColors.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DoctorTheme.space20),

              // Details Summary Card
              Container(
                padding: const EdgeInsets.all(DoctorTheme.space16),
                decoration: BoxDecoration(
                  color: DoctorColors.background,
                  borderRadius: BorderRadius.circular(DoctorTheme.radius12),
                  border: Border.all(color: DoctorColors.border),
                ),
                child: Column(
                  children: [
                    _buildRow(
                      label: strings.visit,
                      value: '${strings.visit} ${visit.visitNumber}',
                      highlight: true,
                    ),
                    const Divider(height: 16, color: DoctorColors.border),
                    _buildRow(
                      label: 'Case',
                      value: visit.caseId,
                    ),
                    const Divider(height: 16, color: DoctorColors.border),
                    _buildRow(
                      label: strings.departmentLabel,
                      value: domain,
                    ),
                    const Divider(height: 16, color: DoctorColors.border),
                    _buildRow(
                      label: strings.attendingDoctorLabel,
                      value: visit.doctorName ?? visit.doctorId,
                    ),
                    const Divider(height: 16, color: DoctorColors.border),
                    _buildRow(
                      label: strings.completedAtLabel,
                      value: formattedDate,
                    ),
                    const Divider(height: 16, color: DoctorColors.border),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Case Status',
                          style: DoctorTheme.caption.copyWith(
                            color: DoctorColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: DoctorColors.statusAvailable.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: DoctorColors.statusAvailable.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            strings.caseStatusOpenBadge,
                            style: const TextStyle(
                              color: DoctorColors.statusAvailable,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DoctorTheme.space24),

              // Dashboard return button
              SizedBox(
                width: double.infinity,
                child: DoctorPrimaryButton(
                  label: strings.backToDashboardButton,
                  icon: Icons.dashboard_rounded,
                  onPressed: onReturnToDashboard,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow({
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: DoctorTheme.caption.copyWith(
            color: DoctorColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: DoctorTheme.bodyBold.copyWith(
            color: highlight ? DoctorColors.brandTeal : DoctorColors.textPrimary,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

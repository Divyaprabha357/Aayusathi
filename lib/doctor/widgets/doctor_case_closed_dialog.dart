import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../localization/doctor_localizations.dart';
import '../models/clinical_case.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import 'doctor_buttons.dart';

/// Success dialog displayed after a clinical Case has been closed.
class DoctorCaseClosedDialog extends StatelessWidget {
  final ClinicalCase clinicalCase;
  final String doctorName;
  final KioskLocale locale;

  const DoctorCaseClosedDialog({
    super.key,
    required this.clinicalCase,
    required this.doctorName,
    this.locale = KioskLocale.english,
  });

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(locale);
    final closeTime = clinicalCase.closedAt ?? DateTime.now();
    final formattedDate =
        '${closeTime.day.toString().padLeft(2, '0')}/${closeTime.month.toString().padLeft(2, '0')}/${closeTime.year} ${closeTime.hour.toString().padLeft(2, '0')}:${closeTime.minute.toString().padLeft(2, '0')}';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DoctorTheme.radius16),
      ),
      elevation: 8,
      child: Container(
        width: 540,
        padding: const EdgeInsets.all(DoctorTheme.space24),
        decoration: BoxDecoration(
          color: DoctorColors.surface,
          borderRadius: BorderRadius.circular(DoctorTheme.radius16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Success Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: DoctorColors.brandNavy.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.folder_off_rounded,
                  color: DoctorColors.brandNavy,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: DoctorTheme.space16),

            // Title
            Text(
              strings.caseClosedSuccessTitle,
              style: DoctorTheme.headline1.copyWith(
                color: DoctorColors.brandNavy,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: DoctorTheme.space4),

            // Subtitle
            Text(
              strings.caseClosedSuccessSubtitle,
              style: DoctorTheme.bodyRegular.copyWith(
                color: DoctorColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DoctorTheme.space20),

            // Details Container
            Container(
              padding: const EdgeInsets.all(DoctorTheme.space16),
              decoration: BoxDecoration(
                color: DoctorColors.background,
                borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                border: Border.all(color: DoctorColors.border),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    label: strings.cases,
                    value: '${clinicalCase.caseId} • ${clinicalCase.domain}',
                  ),
                  const Divider(height: 16, color: DoctorColors.border),
                  _buildDetailRow(
                    label: strings.caseStatusLabel,
                    value: strings.closedCase,
                    valueColor: DoctorColors.statusOffline,
                    badge: true,
                  ),
                  const Divider(height: 16, color: DoctorColors.border),
                  _buildDetailRow(
                    label: strings.closedByDoctorLabel,
                    value: doctorName,
                  ),
                  const Divider(height: 16, color: DoctorColors.border),
                  _buildDetailRow(
                    label: strings.closureDateLabel,
                    value: formattedDate,
                  ),
                  if (clinicalCase.closureNote != null &&
                      clinicalCase.closureNote!.isNotEmpty) ...[
                    const Divider(height: 16, color: DoctorColors.border),
                    _buildDetailRow(
                      label: strings.closureNoteCardLabel,
                      value: clinicalCase.closureNote!,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: DoctorTheme.space24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: DoctorSecondaryButton(
                    label: strings.viewCaseHistoryButton,
                    icon: Icons.history_rounded,
                    onPressed: () => Navigator.of(context).pop('view_history'),
                    height: 42,
                  ),
                ),
                const SizedBox(width: DoctorTheme.space12),
                Expanded(
                  child: DoctorPrimaryButton(
                    label: strings.backToDashboardButton,
                    icon: Icons.dashboard_rounded,
                    onPressed: () => Navigator.of(context).pop('dashboard'),
                    height: 42,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    Color? valueColor,
    bool badge = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: DoctorTheme.caption.copyWith(
            color: DoctorColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: badge
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: DoctorColors.statusOffline.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                  ),
                  child: Text(
                    value,
                    style: DoctorTheme.caption.copyWith(
                      color: valueColor ?? DoctorColors.statusOffline,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: DoctorTheme.bodyBold.copyWith(
                    color: valueColor ?? DoctorColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../localization/doctor_localizations.dart';
import '../models/clinical_visit.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import 'doctor_buttons.dart';

/// Modal dialog displayed when a physician attempts to create a new visit
/// on a case that already contains an active consultation encounter (Phase D14).
class DoctorActiveVisitExistsDialog extends StatelessWidget {
  final ClinicalVisit activeVisit;
  final String domain;
  final VoidCallback onReturnToActiveVisit;
  final KioskLocale locale;

  const DoctorActiveVisitExistsDialog({
    super.key,
    required this.activeVisit,
    required this.domain,
    required this.onReturnToActiveVisit,
    this.locale = KioskLocale.english,
  });

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(locale);
    final startedDate = activeVisit.startedAt;
    final formattedStarted =
        '${startedDate.day.toString().padLeft(2, '0')}/${startedDate.month.toString().padLeft(2, '0')}/${startedDate.year} ${startedDate.hour.toString().padLeft(2, '0')}:${startedDate.minute.toString().padLeft(2, '0')}';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DoctorTheme.radius16),
        side: const BorderSide(color: DoctorColors.dialogBorder, width: 1.0),
      ),
      backgroundColor: DoctorColors.dialogBg,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 520,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Warning Amber Theme
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DoctorTheme.space24,
                vertical: DoctorTheme.space16,
              ),
              decoration: const BoxDecoration(
                color: DoctorColors.brandOrange,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(DoctorTheme.radius16),
                  topRight: Radius.circular(DoctorTheme.radius16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: DoctorTheme.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.activeVisitExistsTitle.toUpperCase(),
                          style: DoctorTheme.cardTitle.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activeVisit.caseId,
                          style: DoctorTheme.caption.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(DoctorTheme.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.activeVisitExistsNotice,
                    style: DoctorTheme.bodyBold.copyWith(
                      color: DoctorColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: DoctorTheme.space12),

                  // Active Visit Details Card
                  Container(
                    padding: const EdgeInsets.all(DoctorTheme.space16),
                    decoration: BoxDecoration(
                      color: DoctorColors.background,
                      borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                      border: Border.all(color: DoctorColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${strings.visit} ${activeVisit.visitNumber} • $domain',
                              style: DoctorTheme.bodyBold.copyWith(
                                color: DoctorColors.brandNavy,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: DoctorColors.brandOrange
                                    .withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(DoctorTheme.radius6),
                              ),
                              child: Text(
                                strings.activeStatusLabel,
                                style: DoctorTheme.caption.copyWith(
                                  color: DoctorColors.brandOrange,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16, color: DoctorColors.border),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              strings.attendingDoctorLabel,
                              style: DoctorTheme.caption.copyWith(
                                color: DoctorColors.textMuted,
                              ),
                            ),
                            Text(
                              (activeVisit.doctorName != null && activeVisit.doctorName!.isNotEmpty)
                                  ? activeVisit.doctorName!
                                  : 'Attending Physician',
                              style: DoctorTheme.body.copyWith(
                                color: DoctorColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              strings.visitStartedAtLabel,
                              style: DoctorTheme.caption.copyWith(
                                color: DoctorColors.textMuted,
                              ),
                            ),
                            Text(
                              formattedStarted,
                              style: DoctorTheme.caption.copyWith(
                                color: DoctorColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DoctorTheme.space24,
                vertical: DoctorTheme.space16,
              ),
              decoration: const BoxDecoration(
                color: DoctorColors.background,
                border: Border(
                  top: BorderSide(color: DoctorColors.border),
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(DoctorTheme.radius16),
                  bottomRight: Radius.circular(DoctorTheme.radius16),
                ),
              ),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: DoctorTheme.space12,
                runSpacing: 8,
                children: [
                  DoctorSecondaryButton(
                    label: strings.stayButton,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  DoctorPrimaryButton(
                    label: strings.returnToActiveVisitButton,
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onReturnToActiveVisit();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

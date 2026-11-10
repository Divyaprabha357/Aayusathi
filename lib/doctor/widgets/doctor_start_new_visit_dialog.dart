import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../localization/doctor_localizations.dart';
import '../models/clinical_case.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import 'doctor_buttons.dart';

/// Modal dialog confirming the creation of a new consultation encounter visit
/// under an existing open clinical case (Phase D14).
class DoctorStartNewVisitDialog extends StatelessWidget {
  final ClinicalCase clinicalCase;
  final String? patientName;
  final int previousVisitsCount;
  final VoidCallback onConfirmStart;
  final KioskLocale locale;

  const DoctorStartNewVisitDialog({
    super.key,
    required this.clinicalCase,
    this.patientName,
    required this.previousVisitsCount,
    required this.onConfirmStart,
    this.locale = KioskLocale.english,
  });

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(locale);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DoctorTheme.radius16),
      ),
      backgroundColor: DoctorColors.surface,
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 540,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DoctorTheme.space24,
                vertical: DoctorTheme.space16,
              ),
              decoration: const BoxDecoration(
                color: DoctorColors.brandNavy,
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
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline_rounded,
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
                          strings.startNewVisitTitle.toUpperCase(),
                          style: DoctorTheme.cardTitle.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          patientName != null
                              ? '$patientName • ${clinicalCase.caseId}'
                              : clinicalCase.caseId,
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
                  // Case Details Card
                  Container(
                    padding: const EdgeInsets.all(DoctorTheme.space16),
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
                              clinicalCase.domain.toUpperCase(),
                              style: DoctorTheme.caption.copyWith(
                                color: DoctorColors.brandNavy,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: DoctorColors.statusAvailable
                                    .withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(DoctorTheme.radius6),
                              ),
                              child: Text(
                                strings.caseStatusOpenBadge,
                                style: DoctorTheme.caption.copyWith(
                                  color: DoctorColors.statusAvailable,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          clinicalCase.title,
                          style: DoctorTheme.bodyBold.copyWith(
                            color: DoctorColors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                        const Divider(height: 16, color: DoctorColors.border),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Previous Visits:',
                              style: DoctorTheme.caption.copyWith(
                                color: DoctorColors.textMuted,
                              ),
                            ),
                            Text(
                              '$previousVisitsCount ${strings.visits.toLowerCase()}',
                              style: DoctorTheme.bodyBold.copyWith(
                                color: DoctorColors.brandNavy,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DoctorTheme.space16),

                  // Explanatory Banner
                  Container(
                    padding: const EdgeInsets.all(DoctorTheme.space12),
                    decoration: BoxDecoration(
                      color: DoctorColors.brandTeal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                      border: Border.all(
                        color: DoctorColors.brandTeal.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: DoctorColors.brandTeal,
                        ),
                        const SizedBox(width: DoctorTheme.space8),
                        Expanded(
                          child: Text(
                            strings.startNewVisitSubtitle,
                            style: DoctorTheme.caption.copyWith(
                              color: DoctorColors.textPrimary,
                              height: 1.35,
                            ),
                          ),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  DoctorSecondaryButton(
                    label: strings.stayButton,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: DoctorTheme.space12),
                  DoctorPrimaryButton(
                    label: strings.confirmStartNewVisitButton,
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onConfirmStart();
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

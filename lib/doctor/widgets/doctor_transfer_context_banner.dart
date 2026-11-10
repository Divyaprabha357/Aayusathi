import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../localization/doctor_localizations.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';

/// Clinical workspace context banner displaying incoming transfer details.
///
/// Prominently yet non-diagnostically informs the accepting destination physician:
/// - Source department referral
/// - Authorizing source doctor reason
/// - Confirmation of active ongoing case continuity
class DoctorTransferContextBanner extends StatelessWidget {
  final String sourceDepartment;
  final String? sourceDoctorName;
  final String transferReason;
  final KioskLocale locale;

  const DoctorTransferContextBanner({
    super.key,
    required this.sourceDepartment,
    this.sourceDoctorName,
    required this.transferReason,
    this.locale = KioskLocale.english,
  });

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(locale);

    return Container(
      margin: const EdgeInsets.only(bottom: DoctorTheme.space16),
      padding: const EdgeInsets.all(DoctorTheme.space16),
      decoration: BoxDecoration(
        color: DoctorColors.brandOrange.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(DoctorTheme.radius12),
        border: Border.all(
          color: DoctorColors.brandOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DoctorColors.brandOrange.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: DoctorColors.brandOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: DoctorTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          Text(
                            '${strings.transferredFromBanner}: $sourceDepartment',
                            style: DoctorTheme.bodyBold.copyWith(
                              color: DoctorColors.brandNavy,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          if (sourceDoctorName != null &&
                              sourceDoctorName!.isNotEmpty)
                            Text(
                              '($sourceDoctorName)',
                              style: DoctorTheme.caption.copyWith(
                                color: DoctorColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: DoctorColors.brandOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: DoctorColors.brandOrange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        strings.transferAssignedBadge.toUpperCase(),
                        style: const TextStyle(
                          color: DoctorColors.brandOrange,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (transferReason.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${strings.transferReasonCardLabel}: "$transferReason"',
                    style: DoctorTheme.bodyMuted.copyWith(
                      color: DoctorColors.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

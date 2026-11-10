import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/kiosk_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Standard bottom footer for the AAYUSATHI Kiosk interface.
class AayusathiFooter extends StatelessWidget {
  final VoidCallback? onCancel;

  const AayusathiFooter({
    super.key,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final strings = KioskLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFD6EAE6), width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandNavy.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Hospital Helpdesk indication
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.support_agent_rounded,
                  color: AppColors.brandTeal,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Need assistance? Contact OPD Helpdesk or Staff Nurse.',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Center: Branding version
          Text(
            '${AppConstants.appName} Self-Service Kiosk • v${AppConstants.appVersion}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),

          // Right: Optional Cancel / Restart Session button
          if (onCancel != null)
            TextButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: Text(strings.cancel),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.statusCritical,
                textStyle: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const SizedBox(width: 20),
        ],
      ),
    );
  }
}

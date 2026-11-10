import 'package:flutter/material.dart';
import '../../core/localization/kiosk_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/vital_reading.dart';
import 'aayusathi_glass_card.dart';

/// Touchscreen vital measurement card displaying live sensor telemetry or waiting placeholders.
class AayusathiVitalCard extends StatelessWidget {
  final String title;
  final String valueDisplay;
  final String unit;
  final IconData icon;
  final Color iconColor;
  final VitalStatus status;
  final bool isAbnormal;
  final String? customStatusLabel;
  final String? sourceLabel;

  const AayusathiVitalCard({
    super.key,
    required this.title,
    required this.valueDisplay,
    required this.unit,
    required this.icon,
    this.iconColor = AppColors.brandTeal,
    this.status = VitalStatus.waiting,
    this.isAbnormal = false,
    this.customStatusLabel,
    this.sourceLabel,
  });


  @override
  Widget build(BuildContext context) {
    final strings = KioskLocalizations.of(context);
    final hasValue = valueDisplay != '--';

    return AayusathiGlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header: Icon + Status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isAbnormal
                      ? AppColors.statusCritical.withValues(alpha: 0.12)
                      : iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isAbnormal ? AppColors.statusCritical : iconColor,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _buildStatusBadge(context, strings),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Reading Title
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),

          // Large Reading Value & Unit
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                valueDisplay,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: isAbnormal
                      ? AppColors.statusCritical
                      : (hasValue ? AppColors.brandNavy : AppColors.textMuted),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                unit,
                style: AppTextStyles.caption.copyWith(
                  color: hasValue ? AppColors.brandTeal : AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (sourceLabel != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.brandNavy.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                sourceLabel!,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, dynamic strings) {
    Color bg;
    Color border;
    Color textColor;
    String label;
    IconData statusIcon;

    if (customStatusLabel != null) {
      bg = const Color(0xFFF1F5F9);
      border = const Color(0xFFCBD5E1);
      textColor = AppColors.textSecondary;
      label = customStatusLabel!;
      statusIcon = Icons.tune_rounded;
    } else if (isAbnormal) {
      bg = const Color(0xFFFDE8E8);
      border = const Color(0xFFF8B4B4);
      textColor = AppColors.statusCritical;
      label = 'Abnormal';
      statusIcon = Icons.warning_amber_rounded;
    } else {

      switch (status) {
        case VitalStatus.valid:
          bg = const Color(0xFFDEF7EC);
          border = const Color(0xFF84E1BC);
          textColor = AppColors.statusNormal;
          label = strings.sensorComplete;
          statusIcon = Icons.check_circle_rounded;
          break;
        case VitalStatus.reading:
          bg = const Color(0xFFE8F5F1);
          border = const Color(0xFFBBE5DC);
          textColor = AppColors.brandTeal;
          label = strings.readingInProgress;
          statusIcon = Icons.sync_rounded;
          break;
        case VitalStatus.error:
          bg = const Color(0xFFFFF8F1);
          border = const Color(0xFFFFD8B2);
          textColor = AppColors.brandOrange;
          label = strings.sensorUnavailable;
          statusIcon = Icons.error_outline_rounded;
          break;
        case VitalStatus.waiting:
        default:
          bg = const Color(0xFFF1F5F9);
          border = const Color(0xFFE2E8F0);
          textColor = AppColors.textMuted;
          label = strings.waitingForSensor;
          statusIcon = Icons.sensors_outlined;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 13, color: textColor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

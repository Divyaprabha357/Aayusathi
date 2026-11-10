import 'package:flutter/material.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';

/// Clinical vital measurement state for the doctor interface.
enum DoctorVitalState {
  normal,
  warning,
  critical;

  Color get color {
    switch (this) {
      case DoctorVitalState.normal:
        return DoctorColors.statusNormal;
      case DoctorVitalState.warning:
        return DoctorColors.statusWarning;
      case DoctorVitalState.critical:
        return DoctorColors.statusCritical;
    }
  }

  String get label {
    switch (this) {
      case DoctorVitalState.normal:
        return 'NORMAL';
      case DoctorVitalState.warning:
        return 'ATTENTION';
      case DoctorVitalState.critical:
        return 'CRITICAL';
    }
  }

  IconData get icon {
    switch (this) {
      case DoctorVitalState.normal:
        return Icons.check_circle_rounded;
      case DoctorVitalState.warning:
        return Icons.warning_amber_rounded;
      case DoctorVitalState.critical:
        return Icons.error_outline_rounded;
    }
  }
}

/// Information-dense desktop card for displaying clinical vital telemetry.
class DoctorVitalCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final DoctorVitalState state;
  final String? subtitle;

  const DoctorVitalCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    this.state = DoctorVitalState.normal,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 160, minHeight: 120),
      padding: const EdgeInsets.all(DoctorTheme.space16),
      decoration: BoxDecoration(
        color: DoctorColors.surface,
        borderRadius: BorderRadius.circular(DoctorTheme.radius12),
        border: Border.all(
          color: state == DoctorVitalState.normal
              ? DoctorColors.border
              : state.color.withValues(alpha: 0.5),
          width: state == DoctorVitalState.normal ? 1 : 1.5,
        ),
        boxShadow: DoctorTheme.shadowSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header: Icon + Title + Status Pill
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DoctorTheme.space6),
                decoration: BoxDecoration(
                  color: DoctorColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                ),
                child: Icon(icon, size: 16, color: DoctorColors.brandTeal),
              ),
              const SizedBox(width: DoctorTheme.space8),
              Expanded(
                child: Text(
                  title,
                  style: DoctorTheme.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: DoctorColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DoctorTheme.space6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: state.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(DoctorTheme.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(state.icon, size: 10, color: state.color),
                    const SizedBox(width: 3),
                    Text(
                      state.label,
                      style: DoctorTheme.badgeText.copyWith(
                        fontSize: 9,
                        color: state.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DoctorTheme.space12),

          // Value and Unit
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: DoctorTheme.displayTitle.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: state == DoctorVitalState.critical
                      ? DoctorColors.statusCritical
                      : DoctorColors.textPrimary,
                ),
              ),
              const SizedBox(width: DoctorTheme.space4),
              Text(
                unit,
                style: DoctorTheme.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: DoctorColors.textMuted,
                ),
              ),
            ],
          ),

          if (subtitle != null) ...[
            const SizedBox(height: DoctorTheme.space4),
            Text(
              subtitle!,
              style: DoctorTheme.caption.copyWith(
                fontSize: 10,
                color: DoctorColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

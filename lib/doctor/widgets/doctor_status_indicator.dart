import 'package:flutter/material.dart';
import '../models/doctor_profile.dart';
import '../models/doctor_ui_status.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';

/// Accessible status badge combining color, icon, and text.
/// Ensures information is never communicated through color alone.
class DoctorStatusBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isFilled;
  final VoidCallback? onTap;

  const DoctorStatusBadge({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.isFilled = false,
    this.onTap,
  });

  factory DoctorStatusBadge.fromOnlineStatus(DoctorOnlineStatus status) {
    return DoctorStatusBadge(
      label: status.label,
      icon: status.icon,
      color: status.color,
      isFilled: false,
    );
  }

  factory DoctorStatusBadge.fromWorkStatus(DoctorWorkStatus status) {
    return DoctorStatusBadge(
      label: status.label,
      icon: status.icon,
      color: status.color,
      isFilled: true,
    );
  }

  factory DoctorStatusBadge.fromAvailabilityStatus(
    DoctorAvailabilityStatus status, {
    VoidCallback? onTap,
    bool isFilled = true,
  }) {
    return DoctorStatusBadge(
      label: status.label,
      icon: status.icon,
      color: status.color,
      isFilled: isFilled,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBg = isFilled
        ? color.withValues(alpha: 0.12)
        : DoctorColors.surface;
    final effectiveBorder = color.withValues(alpha: 0.35);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DoctorTheme.radiusFull),
        child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DoctorTheme.space12,
          vertical: DoctorTheme.space6,
        ),
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: BorderRadius.circular(DoctorTheme.radiusFull),
          border: Border.all(color: effectiveBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: DoctorTheme.space8),
            // Icon
            Icon(icon, size: 14, color: color),
            const SizedBox(width: DoctorTheme.space6),
            // Label
            Text(
              label,
              style: DoctorTheme.badgeText.copyWith(
                color: DoctorColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

/// Compact circular status indicator dot.
class DoctorStatusDot extends StatelessWidget {
  final Color color;
  final double size;

  const DoctorStatusDot({
    super.key,
    required this.color,
    this.size = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

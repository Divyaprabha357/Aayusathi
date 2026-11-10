import 'package:flutter/material.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';

/// Reusable section header for doctor workspace layouts.
class DoctorSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? badgeText;
  final Color? badgeColor;
  final Widget? trailing;

  const DoctorSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.badgeText,
    this.badgeColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: DoctorTheme.headline2,
                  ),
                  if (badgeText != null) ...[
                    const SizedBox(width: DoctorTheme.space8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DoctorTheme.space8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (badgeColor ?? DoctorColors.brandTeal)
                            .withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(DoctorTheme.radiusFull),
                        border: Border.all(
                          color: (badgeColor ?? DoctorColors.brandTeal)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        badgeText!,
                        style: DoctorTheme.badgeText.copyWith(
                          fontSize: 10,
                          color: badgeColor ?? DoctorColors.brandTeal,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: DoctorTheme.space4),
                Text(
                  subtitle!,
                  style: DoctorTheme.subtitle,
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

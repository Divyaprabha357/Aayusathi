import 'package:flutter/material.dart';
import '../theme/patient_colors.dart';

/// Large, senior-friendly Quick Access Action card.
class PatientQuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? iconBgColor;

  const PatientQuickAccessCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.iconColor,
    this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? PatientColors.teal;
    final effectiveIconBgColor = iconBgColor ?? PatientColors.tealLight;

    return Material(
      color: PatientColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PatientColors.border, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: effectiveIconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: effectiveIconColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PatientColors.navy,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: PatientColors.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: PatientColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

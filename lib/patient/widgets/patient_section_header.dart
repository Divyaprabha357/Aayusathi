import 'package:flutter/material.dart';
import '../theme/patient_colors.dart';

/// Clean, senior-accessible section header.
class PatientSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onActionTap;

  const PatientSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: PatientColors.navy,
                    letterSpacing: 0.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: PatientColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionText != null && onActionTap != null)
            TextButton(
              onPressed: onActionTap,
              style: TextButton.styleFrom(
                foregroundColor: PatientColors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(48, 48), // Senior touch target
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionText!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

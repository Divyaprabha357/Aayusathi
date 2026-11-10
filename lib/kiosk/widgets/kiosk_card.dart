import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Touchscreen-optimized card button for Kiosk workflows.
class KioskCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? accentColor;

  const KioskCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accentColor ?? AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.kioskCardRadius),
        splashColor: effectiveAccent.withValues(alpha: 0.12),
        highlightColor: effectiveAccent.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(AppConstants.kioskCardRadius),
            border: Border.all(
              color: AppColors.borderLight,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Leading action icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: effectiveAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: effectiveAccent,
                ),
              ),
              const SizedBox(width: 18),

              // Title and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Trailing arrow indicator
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: effectiveAccent.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: effectiveAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

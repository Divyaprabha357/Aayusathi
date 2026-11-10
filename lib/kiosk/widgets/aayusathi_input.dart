import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Touch-friendly input display field for AAYUSATHI Kiosk.
/// Used in conjunction with AayusathiNumericKeypad or for read-only displays.
class AayusathiInput extends StatelessWidget {
  final String label;
  final String value;
  final String? placeholder;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool isFocused;
  final bool isReadOnly;
  final VoidCallback? onTap;

  const AayusathiInput({
    super.key,
    required this.label,
    required this.value,
    this.placeholder,
    this.errorText,
    this.prefixIcon,
    this.suffix,
    this.isFocused = false,
    this.isReadOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasError = errorText != null && errorText!.isNotEmpty;
    final bool isEmpty = value.isEmpty;

    final Color borderColor = hasError
        ? AppColors.statusCritical
        : (isFocused ? AppColors.brandTeal : AppColors.borderLight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: hasError ? AppColors.statusCritical : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        // Input Container
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: isReadOnly
                  ? const Color(0xFFF1F5F9)
                  : (isFocused ? Colors.white : const Color(0xFFFAFCFD)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: isFocused || hasError ? 2.2 : 1.5,
              ),
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: AppColors.brandTeal.withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                if (prefixIcon != null) ...[
                  Icon(
                    prefixIcon,
                    color: isFocused ? AppColors.brandTeal : AppColors.textSecondary,
                    size: 26,
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Text(
                    isEmpty ? (placeholder ?? '') : value,
                    style: isEmpty
                        ? AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textMuted,
                            letterSpacing: 1.0,
                          )
                        : AppTextStyles.inputDisplay.copyWith(
                            color: AppColors.brandNavy,
                            fontWeight: FontWeight.w700,
                          ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (suffix != null) ...[
                  const SizedBox(width: 12),
                  suffix!,
                ],
              ],
            ),
          ),
        ),

        // Error message
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.statusCritical,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  errorText!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.statusCritical,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

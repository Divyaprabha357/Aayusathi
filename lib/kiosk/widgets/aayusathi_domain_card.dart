import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/opd_domain.dart';

/// Large touchscreen-friendly card for selecting an OPD clinical domain.
/// Adheres to the AAYUSATHI Greenish-White / Light Medical Theme.
class AayusathiDomainCard extends StatefulWidget {
  final OpdDomain domain;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const AayusathiDomainCard({
    super.key,
    required this.domain,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<AayusathiDomainCard> createState() => _AayusathiDomainCardState();
}

class _AayusathiDomainCardState extends State<AayusathiDomainCard> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    final Color bgColor = isSelected
        ? const Color(0xFFEBF5F3) // Soft mint selected tint
        : Colors.white;

    final Color borderColor = isSelected
        ? AppColors.brandTeal
        : const Color(0xFFD6EAE6);

    final double borderWidth = isSelected ? 2.5 : 1.5;

    final Color iconColor = isSelected ? Colors.white : AppColors.brandTeal;
    final Color iconBg = isSelected ? AppColors.brandTeal : const Color(0xFFE2F1EE);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : (_isHovered ? 1.01 : 1.0),
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppConstants.kioskCardRadius),
              border: Border.all(
                color: borderColor,
                width: borderWidth,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: AppColors.brandTeal.withValues(alpha: 0.16),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Medical Icon Badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.brandTeal.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    widget.domain.icon,
                    size: 30,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 18),

                // Department Title and Patient-Friendly Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: AppTextStyles.headlineMedium.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.brandNavy : const Color(0xFF0A1E3F),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.description,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 13.5,
                          height: 1.35,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Selection Radio / Checkmark Indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.brandTeal : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.brandTeal : const Color(0xFFCBD5E1),
                      width: 2.0,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 20,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

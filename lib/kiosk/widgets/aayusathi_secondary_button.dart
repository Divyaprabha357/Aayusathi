import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Secondary / Outlined button for navigation actions (Back, Cancel, Options).
class AayusathiSecondaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final double? width;
  final Color? color;

  const AayusathiSecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.height = 54.0,
    this.width,
    this.color,
  });

  @override
  State<AayusathiSecondaryButton> createState() => _AayusathiSecondaryButtonState();
}

class _AayusathiSecondaryButtonState extends State<AayusathiSecondaryButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null;
    final bool isCustomColor = widget.color != null;
    final Color textColor = widget.color ?? AppColors.brandNavy;
    final Color borderColor = isCustomColor
        ? (_isHovered ? widget.color! : widget.color!.withValues(alpha: 0.45))
        : (_isHovered ? AppColors.brandTeal : const Color(0xFFD6EAE6));
    final Color bgColor = _isHovered
        ? (isCustomColor ? widget.color!.withValues(alpha: 0.08) : AppColors.brandTeal.withValues(alpha: 0.06))
        : Colors.white;

    return MouseRegion(
      onEnter: (_) {
        if (isEnabled) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (isEnabled) setState(() => _isHovered = false);
      },
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: (_) {
          if (isEnabled) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (isEnabled) setState(() => _isPressed = false);
        },
        onTapCancel: () {
          if (isEnabled) setState(() => _isPressed = false);
        },
        onTap: isEnabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : (_isHovered ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: widget.height,
            width: widget.width,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandNavy.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    color: textColor,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.text,
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

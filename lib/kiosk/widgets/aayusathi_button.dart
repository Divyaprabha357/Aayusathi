import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_text_styles.dart';

/// Premium custom button for AAYUSATHI Kiosk touchscreens.
/// Features brand gradient, subtle controlled glow, and tactile scale-down press feedback.
class AayusathiButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final Color? primaryColor;
  final double height;
  final double? width;

  const AayusathiButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.primaryColor,
    this.height = 58.0,
    this.width,
  });

  @override
  State<AayusathiButton> createState() => _AayusathiButtonState();
}

class _AayusathiButtonState extends State<AayusathiButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;
    final Color baseColor = widget.primaryColor ?? AppColors.brandTeal;

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
            duration: const Duration(milliseconds: 200),
            height: widget.height,
            width: widget.width,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            decoration: BoxDecoration(
              gradient: isEnabled
                  ? LinearGradient(
                      colors: [
                        baseColor,
                        baseColor == AppColors.brandTeal
                            ? AppColors.primaryDark
                            : baseColor.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFCBD5E1), Color(0xFF94A3B8)],
                    ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: isEnabled
                  ? (_isHovered
                      ? AppShadows.primaryGlow
                      : [
                          BoxShadow(
                            color: baseColor.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ])
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading) ...[
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                ] else if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                ],
                Flexible(
                  child: Text(
                    widget.text,
                    style: AppTextStyles.buttonLarge.copyWith(
                      color: Colors.white,
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

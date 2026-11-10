import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';

/// Premium glassmorphic tactile card surface for AAYUSATHI Kiosk.
/// Supports resting, hover, selected states with subtle controlled glows.
class AayusathiGlassCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isSelected;
  final Color? accentColor;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double? width;
  final double? height;
  final bool isDarkTheme;

  const AayusathiGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.isSelected = false,
    this.accentColor,
    this.padding,
    this.borderRadius = 22.0,
    this.width,
    this.height,
    this.isDarkTheme = false,
  });

  @override
  State<AayusathiGlassCard> createState() => _AayusathiGlassCardState();
}

class _AayusathiGlassCardState extends State<AayusathiGlassCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.accentColor ?? AppColors.brandTeal;
    final bool isClickable = widget.onTap != null;

    final Color normalBg = widget.isDarkTheme
        ? AppColors.surfaceDarkGlass
        : const Color(0xFFFFFFFF);
    final Color hoveredBg = widget.isDarkTheme
        ? AppColors.surfaceDark
        : Colors.white;
    final Color selectedBg = accent.withValues(alpha: widget.isDarkTheme ? 0.16 : 0.08);

    final Color normalBorder = widget.isDarkTheme
        ? AppColors.borderDark
        : const Color(0xFFD6EAE6);
    final Color hoveredBorder = accent.withValues(alpha: widget.isDarkTheme ? 0.6 : 0.5);

    return MouseRegion(
      onEnter: (_) {
        if (isClickable) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (isClickable) setState(() => _isHovered = false);
      },
      cursor: isClickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: (_) {
          if (isClickable) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (isClickable) setState(() => _isPressed = false);
        },
        onTapCancel: () {
          if (isClickable) setState(() => _isPressed = false);
        },
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : (_isHovered ? 1.015 : 1.0),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.width,
            height: widget.height,
            padding: widget.padding ?? const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? selectedBg
                  : (_isHovered ? hoveredBg : normalBg),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: widget.isSelected
                    ? accent
                    : (_isHovered ? hoveredBorder : normalBorder),
                width: widget.isSelected ? 2.5 : 1.5,
              ),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: widget.isDarkTheme ? 0.35 : 0.20),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : (_isHovered
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: widget.isDarkTheme ? 0.20 : 0.12),
                            blurRadius: 18,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : (widget.isDarkTheme ? AppShadows.darkCard : AppShadows.softCard)),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

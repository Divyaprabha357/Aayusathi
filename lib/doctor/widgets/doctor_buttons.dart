import 'package:flutter/material.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';

/// Primary action button for the AAYUSATHI Doctor Interface.
/// Medical teal gradient with subtle elevation, hover elevation, and keyboard focus indicator.
class DoctorPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double height;
  final FocusNode? focusNode;
  final bool autofocus;

  const DoctorPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 48.0,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<DoctorPrimaryButton> createState() => _DoctorPrimaryButtonState();
}

class _DoctorPrimaryButtonState extends State<DoctorPrimaryButton> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return FocusableActionDetector(
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DoctorTheme.radius12),
          gradient: isEnabled
              ? LinearGradient(
                  colors: _isHovered
                      ? const [Color(0xFF008E9B), Color(0xFF006772)]
                      : const [DoctorColors.brandTeal, Color(0xFF005E68)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFFB0C4CE), Color(0xFF90A4AE)],
                ),
          boxShadow: isEnabled
              ? (_isHovered ? DoctorTheme.shadowHover : DoctorTheme.shadowSubtle)
              : null,
          border: _isFocused
              ? Border.all(color: DoctorColors.brandOrange, width: 2)
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(DoctorTheme.radius12),
            onTap: isEnabled ? widget.onPressed : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DoctorTheme.space24),
              child: Row(
                mainAxisSize: widget.width != null ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isLoading) ...[
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: DoctorTheme.space12),
                  ] else if (widget.icon != null) ...[
                    Icon(widget.icon, size: 20, color: Colors.white),
                    const SizedBox(width: DoctorTheme.space8),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      style: DoctorTheme.buttonText.copyWith(
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
      ),
    );
  }
}

/// Secondary action button with soft mint surface and navy typography.
class DoctorSecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? width;
  final double height;

  const DoctorSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.width,
    this.height = 48.0,
  });

  @override
  State<DoctorSecondaryButton> createState() => _DoctorSecondaryButtonState();
}

class _DoctorSecondaryButtonState extends State<DoctorSecondaryButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: _isHovered
              ? DoctorColors.surfaceHover
              : DoctorColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(DoctorTheme.radius12),
          border: Border.all(
            color: _isHovered ? DoctorColors.brandTeal : DoctorColors.border,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(DoctorTheme.radius12),
            onTap: isEnabled ? widget.onPressed : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DoctorTheme.space20),
              child: Row(
                mainAxisSize: widget.width != null ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 18, color: DoctorColors.brandNavy),
                    const SizedBox(width: DoctorTheme.space8),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      style: DoctorTheme.buttonText.copyWith(
                        color: DoctorColors.brandNavy,
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
      ),
    );
  }
}

/// Outline action button with transparent background and crisp border.
class DoctorOutlineButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final double? width;
  final double height;

  const DoctorOutlineButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
    this.width,
    this.height = 40.0,
  });

  @override
  State<DoctorOutlineButton> createState() => _DoctorOutlineButtonState();
}

class _DoctorOutlineButtonState extends State<DoctorOutlineButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final mainColor = widget.color ?? DoctorColors.brandTeal;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: _isHovered
              ? mainColor.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(DoctorTheme.radius8),
          border: Border.all(color: mainColor.withValues(alpha: 0.4)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(DoctorTheme.radius8),
            onTap: widget.onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DoctorTheme.space16),
              child: Row(
                mainAxisSize: widget.width != null ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 16, color: mainColor),
                    const SizedBox(width: DoctorTheme.space8),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      style: DoctorTheme.badgeText.copyWith(
                        color: mainColor,
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
      ),
    );
  }
}

/// Compact icon button with tooltip and gentle hover state.
class DoctorIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;

  const DoctorIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.color,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Center(
              child: Icon(
                icon,
                size: size * 0.52,
                color: color ?? DoctorColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

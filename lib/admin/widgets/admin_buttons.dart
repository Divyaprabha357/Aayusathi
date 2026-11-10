import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_theme.dart';

/// Primary action button for the Admin Portal.
class AdminPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double height;
  final double? width;
  final FocusNode? focusNode;
  final bool autofocus;

  const AdminPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 48.0,
    this.width,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: ElevatedButton(
        focusNode: focusNode,
        autofocus: autofocus,
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AdminColors.brandTeal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AdminColors.brandTeal.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AdminTheme.radius12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AdminTheme.space12),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18),
                      const SizedBox(width: AdminTheme.space8),
                    ],
                    Text(
                      label,
                      style: AdminTheme.buttonText.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Secondary action button for the Admin Portal.
class AdminSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final double? width;

  const AdminSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 48.0,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AdminColors.brandNavy,
          side: const BorderSide(color: AdminColors.border, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AdminTheme.radius12),
          ),
          backgroundColor: AdminColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: AdminTheme.space12),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AdminColors.textSecondary),
                const SizedBox(width: AdminTheme.space8),
              ],
              Text(
                label,
                style: AdminTheme.buttonText.copyWith(
                  color: AdminColors.brandNavy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Outline button for contextual actions in cards/headers.
class AdminOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final double height;
  final double? width;

  const AdminOutlineButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color = AdminColors.brandTeal,
    this.height = 40.0,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.6), width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AdminTheme.radius8),
          ),
          backgroundColor: color.withValues(alpha: 0.04),
          padding: const EdgeInsets.symmetric(horizontal: AdminTheme.space16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: color),
              const SizedBox(width: AdminTheme.space6),
            ],
            Text(
              label,
              style: AdminTheme.badgeText.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

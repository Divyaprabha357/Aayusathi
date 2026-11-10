import 'package:flutter/material.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import 'doctor_buttons.dart';

/// Loading state view for doctor workspace sections.
class DoctorLoadingView extends StatelessWidget {
  final String? message;
  final String? subtitle;

  const DoctorLoadingView({
    super.key,
    this.message,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DoctorTheme.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(DoctorColors.brandTeal),
              ),
            ),
            const SizedBox(height: DoctorTheme.space20),
            Text(
              message ?? 'Loading clinical data...',
              style: DoctorTheme.headline2,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: DoctorTheme.space8),
              Text(
                subtitle!,
                style: DoctorTheme.subtitle,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state view for doctor queues and record lists.
class DoctorEmptyView extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const DoctorEmptyView({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DoctorTheme.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: DoctorColors.backgroundSecondary,
                shape: BoxShape.circle,
                border: Border.all(color: DoctorColors.border),
              ),
              child: Icon(icon, size: 36, color: DoctorColors.brandTeal),
            ),
            const SizedBox(height: DoctorTheme.space20),
            Text(
              title,
              style: DoctorTheme.headline2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DoctorTheme.space8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                subtitle,
                style: DoctorTheme.subtitle,
                textAlign: TextAlign.center,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: DoctorTheme.space24),
              DoctorPrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                height: 40,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state view with retry action.
class DoctorErrorView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const DoctorErrorView({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DoctorTheme.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: DoctorColors.statusCritical.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: DoctorColors.statusCritical.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: DoctorColors.statusCritical,
              ),
            ),
            const SizedBox(height: DoctorTheme.space20),
            Text(
              title,
              style: DoctorTheme.headline2.copyWith(
                color: DoctorColors.brandNavy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DoctorTheme.space8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Text(
                message,
                style: DoctorTheme.subtitle,
                textAlign: TextAlign.center,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: DoctorTheme.space24),
              DoctorSecondaryButton(
                label: 'Retry',
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
                height: 40,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Success state view with confirmation indicator.
class DoctorSuccessView extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const DoctorSuccessView({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DoctorTheme.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: DoctorColors.statusNormal.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: DoctorColors.statusNormal.withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 38,
                color: DoctorColors.statusNormal,
              ),
            ),
            const SizedBox(height: DoctorTheme.space20),
            Text(
              title,
              style: DoctorTheme.headline2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DoctorTheme.space8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Text(
                message,
                style: DoctorTheme.subtitle,
                textAlign: TextAlign.center,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: DoctorTheme.space24),
              DoctorPrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                height: 40,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

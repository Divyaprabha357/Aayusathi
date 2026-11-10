import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_theme.dart';

/// Reusable clean medical empty-state widget for escalations in the Admin Portal.
class AdminEscalationEmptyState extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;

  const AdminEscalationEmptyState({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.check_circle_outline_rounded,
    this.iconColor = AdminColors.statusNormal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AdminTheme.space24,
        vertical: AdminTheme.space32,
      ),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(AdminTheme.radius16),
        border: Border.all(color: AdminColors.borderSubtle),
        boxShadow: AdminTheme.shadowCard,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 28,
            ),
          ),
          const SizedBox(height: AdminTheme.space16),
          Text(
            title,
            style: AdminTheme.headline2.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AdminColors.brandNavy,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AdminTheme.space6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(
              description,
              style: AdminTheme.caption.copyWith(
                fontSize: 12,
                color: AdminColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

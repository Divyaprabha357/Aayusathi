import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_theme.dart';

/// Reusable clean medical card surface container for the Admin Interface.
class AdminCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const AdminCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(AdminTheme.space20),
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null || trailing != null) ...[
          Padding(
            padding: EdgeInsets.only(
              left: padding.horizontal > 0 ? 0 : AdminTheme.space20,
              right: padding.horizontal > 0 ? 0 : AdminTheme.space20,
              bottom: AdminTheme.space16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title!,
                          style: AdminTheme.cardTitle.copyWith(
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: AdminTheme.space4),
                          Text(
                            subtitle!,
                            style: AdminTheme.caption.copyWith(
                              color: AdminColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (trailing != null) ...[
                  const SizedBox(width: AdminTheme.space12),
                  trailing!,
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AdminColors.borderSubtle),
          const SizedBox(height: AdminTheme.space16),
        ],
        child,
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AdminColors.surface,
        borderRadius: BorderRadius.circular(AdminTheme.radius16),
        border: Border.all(color: AdminColors.borderSubtle),
        boxShadow: AdminTheme.shadowCard,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AdminTheme.radius16),
        child: InkWell(
          borderRadius: BorderRadius.circular(AdminTheme.radius16),
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: cardContent,
          ),
        ),
      ),
    );
  }
}

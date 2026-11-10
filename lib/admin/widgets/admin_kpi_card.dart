import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_theme.dart';

/// KPI metric card for the Admin System Overview section.
class AdminKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String? badgeText;
  final Color? badgeColor;
  final VoidCallback? onTap;
  final bool isLoading;

  const AdminKpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.accentColor = AdminColors.brandTeal,
    this.badgeText,
    this.badgeColor,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.surface,
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
            padding: const EdgeInsets.all(AdminTheme.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Title + Icon Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        style: AdminTheme.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AdminColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AdminTheme.radius10),
                      ),
                      child: Icon(
                        icon,
                        color: accentColor,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AdminTheme.space12),

                // Center Metric Value & Badge
                if (isLoading)
                  Container(
                    height: 38,
                    alignment: Alignment.centerLeft,
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(AdminColors.brandTeal),
                      ),
                    ),
                  )
                else
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AdminTheme.space8,
                    runSpacing: AdminTheme.space4,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AdminColors.brandNavy,
                          letterSpacing: -1.0,
                          fontFamily: AdminTheme.headline1.fontFamily,
                        ),
                      ),
                      if (badgeText != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AdminTheme.space8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (badgeColor ?? accentColor).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AdminTheme.radiusFull),
                          ),
                          child: Text(
                            badgeText!,
                            style: AdminTheme.badgeText.copyWith(
                              fontSize: 10,
                              color: badgeColor ?? accentColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: AdminTheme.space8),

                // Description Subtitle
                Text(
                  subtitle,
                  style: AdminTheme.caption.copyWith(
                    color: AdminColors.textMuted,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';

/// Reusable medical information card for the Doctor desktop interface.
class DoctorCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const DoctorCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(DoctorTheme.space20),
    this.width,
    this.height,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = child;

    if (title != null || subtitle != null || trailing != null) {
      cardContent = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(
                        title!,
                        style: DoctorTheme.headline2.copyWith(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (subtitle != null) ...[
                      const SizedBox(height: DoctorTheme.space4),
                      Text(
                        subtitle!,
                        style: DoctorTheme.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: DoctorTheme.space16),
          const Divider(height: 1, color: DoctorColors.borderSubtle),
          const SizedBox(height: DoctorTheme.space16),
          child,
        ],
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? DoctorColors.surface,
        borderRadius: BorderRadius.circular(DoctorTheme.radius16),
        border: Border.all(color: DoctorColors.border),
        boxShadow: DoctorTheme.shadowCard,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(DoctorTheme.radius16),
        child: InkWell(
          borderRadius: BorderRadius.circular(DoctorTheme.radius16),
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

/// Elevated variant of DoctorCard with prominent medical shadow for highlighted sections.
class DoctorElevatedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;

  const DoctorElevatedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DoctorTheme.space24),
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: DoctorColors.surfaceElevated,
        borderRadius: BorderRadius.circular(DoctorTheme.radius20),
        border: Border.all(color: DoctorColors.brandTeal.withValues(alpha: 0.15)),
        boxShadow: DoctorTheme.shadowHover,
      ),
      padding: padding,
      child: child,
    );
  }
}

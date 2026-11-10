import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/utils/date_utils.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_theme.dart';

/// Reusable persistent desktop header for the AAYUSATHI Administrative Portal.
///
/// Concept:
/// LEFT: AAYUSATHI logo & Admin Portal branding
/// CENTER: Current section title & subtitle
/// RIGHT: Live Digital Clock & Admin profile / menu placeholder
class AdminHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLogout;
  final String adminName;
  final String adminRole;

  const AdminHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.onProfileTap,
    this.onLogout,
    this.adminName = 'Admin',
    this.adminRole = 'System Administrator (Level 1)',
  });

  @override
  Size get preferredSize => const Size.fromHeight(68.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: AdminTheme.space16),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        border: const Border(
          bottom: BorderSide(color: AdminColors.border, width: 1),
        ),
        boxShadow: AdminTheme.shadowSubtle,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 1100;
          final isVeryCompact = constraints.maxWidth < 920;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // LEFT: AAYUSATHI Logo & Admin Portal Identity
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onBack != null) ...[
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: 'Go back',
                      color: AdminColors.brandNavy,
                      onPressed: onBack,
                    ),
                    const SizedBox(width: AdminTheme.space8),
                  ],
                  Image.asset(
                    AppAssets.logo,
                    height: 38,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: AdminColors.brandTeal,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AAYUSATHI',
                          style: AdminTheme.headline2.copyWith(
                            color: AdminColors.brandNavy,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isVeryCompact) ...[
                    const SizedBox(width: AdminTheme.space12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AdminTheme.space8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AdminColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(AdminTheme.radius6),
                        border: Border.all(
                          color: AdminColors.brandTeal.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        'ADMIN PORTAL',
                        style: AdminTheme.badgeText.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.brandTeal,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // CENTER: Current Page / Section Title
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AdminTheme.space12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: AdminTheme.headline2.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: isVeryCompact ? 15 : 18,
                          ),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (subtitle != null && !isVeryCompact) ...[
                        const SizedBox(height: 2),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            subtitle!,
                            textAlign: TextAlign.center,
                            style: AdminTheme.caption.copyWith(
                              color: AdminColors.textSecondary,
                            ),
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // RIGHT: Live Clock, Authority Badge & Admin Profile Menu
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Authority Level Badge
                  if (!isVeryCompact) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AdminTheme.space10,
                        vertical: AdminTheme.space6,
                      ),
                      decoration: BoxDecoration(
                        color: AdminColors.statusNormal.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AdminTheme.radius8),
                        border: Border.all(
                          color: AdminColors.statusNormal.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_user_rounded,
                            size: 14,
                            color: AdminColors.statusNormal,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Level 1 Authority',
                            style: AdminTheme.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AdminColors.statusNormal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AdminTheme.space12),
                  ],

                  if (!isCompact) ...[
                    const _AdminLiveClock(),
                    const SizedBox(width: AdminTheme.space12),
                  ],

                  // Admin Profile Menu
                  _AdminProfileMenu(
                    adminName: adminName,
                    adminRole: adminRole,
                    onProfileTap: onProfileTap,
                    onLogout: onLogout,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Isolated digital clock widget that ticks every second without rebuilding the header.
class _AdminLiveClock extends StatefulWidget {
  const _AdminLiveClock();

  @override
  State<_AdminLiveClock> createState() => _AdminLiveClockState();
}

class _AdminLiveClockState extends State<_AdminLiveClock> {
  late DateTime _currentTime;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminTheme.space12,
        vertical: AdminTheme.space6,
      ),
      decoration: BoxDecoration(
        color: AdminColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AdminTheme.radius8),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 14,
            color: AdminColors.brandTeal,
          ),
          const SizedBox(width: 6),
          Text(
            AppDateUtils.formatTime(_currentTime),
            style: AdminTheme.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AdminColors.brandNavy,
            ),
          ),
        ],
      ),
    );
  }
}

/// Admin profile area & menu placeholder
class _AdminProfileMenu extends StatelessWidget {
  final String adminName;
  final String adminRole;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLogout;

  const _AdminProfileMenu({
    required this.adminName,
    required this.adminRole,
    this.onProfileTap,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Admin Account Options',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminTheme.radius12),
        side: const BorderSide(color: AdminColors.border),
      ),
      onSelected: (value) {
        if (value == 'profile' && onProfileTap != null) {
          onProfileTap!();
        } else if (value == 'logout' && onLogout != null) {
          onLogout!();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              const Icon(Icons.account_circle_outlined, size: 18, color: AdminColors.brandTeal),
              const SizedBox(width: 8),
              Text('View Profile', style: AdminTheme.bodyRegular),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout_rounded, size: 18, color: AdminColors.statusCritical),
              const SizedBox(width: 8),
              Text(
                'Logout',
                style: AdminTheme.bodyRegular.copyWith(color: AdminColors.statusCritical),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AdminTheme.space12,
          vertical: AdminTheme.space6,
        ),
        decoration: BoxDecoration(
          color: AdminColors.surface,
          borderRadius: BorderRadius.circular(AdminTheme.radius12),
          border: Border.all(color: AdminColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AdminColors.brandTeal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: AdminTheme.space8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  adminName,
                  style: AdminTheme.bodyBold.copyWith(
                    fontSize: 12,
                    color: AdminColors.brandNavy,
                  ),
                ),
                Text(
                  adminRole,
                  style: AdminTheme.caption.copyWith(
                    fontSize: 10,
                    color: AdminColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AdminTheme.space4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: AdminColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

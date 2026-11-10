import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/date_utils.dart';
import '../../kiosk/widgets/aayusathi_ambient_ecg.dart';
import '../localization/admin_localizations.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_buttons.dart';
import '../widgets/admin_heartbeat_logo.dart';

/// The official AAYUSATHI Admin Standby Screen (Phase A1).
/// Welcomes administrative operators to the central hospital administrative portal.
/// Features clean greenish-white medical styling, subtle dual-pulse heartbeat animation,
/// accessible typography, and keyboard-activated login navigation.
class AdminStandbyScreen extends StatefulWidget {
  final VoidCallback? onTouchToBegin;
  final VoidCallback? onSwitchToDoctor;

  const AdminStandbyScreen({
    super.key,
    this.onTouchToBegin,
    this.onSwitchToDoctor,
  });

  @override
  State<AdminStandbyScreen> createState() => _AdminStandbyScreenState();
}

class _AdminStandbyScreenState extends State<AdminStandbyScreen> {
  late DateTime _currentTime;
  Timer? _clockTimer;
  final FocusNode _beginFocusNode = FocusNode();

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
    _beginFocusNode.dispose();
    super.dispose();
  }

  void _handleBegin() {
    if (widget.onTouchToBegin != null) {
      widget.onTouchToBegin!();
    } else {
      Navigator.of(context).pushNamed(AppRoutes.adminLogin);
    }
  }

  void _handleSwitchToDoctor() {
    if (widget.onSwitchToDoctor != null) {
      widget.onSwitchToDoctor!();
    } else {
      Navigator.of(context).pushNamed(AppRoutes.doctorStandby);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AdminLocalizations.of(context);

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.space): const ActivateIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _handleBegin();
              return null;
            },
          ),
        },
        child: Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.2),
                radius: 1.35,
                colors: [
                  AdminColors.standbyBgCenter,
                  AdminColors.standbyBgMid,
                  AdminColors.standbyBgVignette,
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // 1. Ambient ECG Trace Background
                const AayusathiAmbientEcg(isLightMode: true),

                // 2. Diffused Ambient Halo behind Logo
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 520,
                      height: 320,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AdminColors.standbyAuraCore,
                            Colors.transparent,
                          ],
                          stops: [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Foreground Content
                SafeArea(
                  child: Column(
                    children: [
                      // Top Bar: Terminal Identity & Live Clock
                      _buildTopBar(context, strings),

                      // Center Stage: Logo, Tagline, Title & Prominent Touch To Begin CTA
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AdminTheme.space32,
                              vertical: AdminTheme.space16,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 760),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Official Logo with dual-pulse medical heartbeat
                                  const AdminHeartbeatLogo(
                                    width: 380,
                                    height: 210,
                                  ),
                                  const SizedBox(height: AdminTheme.space16),

                                  // Official Tagline
                                  Text(
                                    AppConstants.appTagline,
                                    style: AdminTheme.badgeText.copyWith(
                                      color: AdminColors.brandOrange,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2.5,
                                      fontSize: 15,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AdminTheme.space12),

                                  // Administration Portal Heading
                                  Text(
                                    strings.administrationPortal,
                                    style: AdminTheme.displayTitle.copyWith(
                                      fontSize: 28,
                                      color: AdminColors.brandNavy,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AdminTheme.space8),

                                  // Subheading
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 580),
                                    child: Text(
                                      strings.healthcareManagementSystem,
                                      style: AdminTheme.subtitle.copyWith(
                                        fontSize: 14,
                                        color: AdminColors.textSecondary,
                                        height: 1.4,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: AdminTheme.space32),

                                  // Prominent TOUCH TO BEGIN CTA Button
                                  _buildBeginCta(strings),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Bottom Bar: Hospital Security & Mode Toggle
                      _buildBottomBar(context, strings),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Top workstation status bar with administrative identity and live clock.
  Widget _buildTopBar(BuildContext context, dynamic strings) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminTheme.space32,
        vertical: AdminTheme.space16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Administrative Terminal Identifier
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AdminColors.statusOnline,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AdminColors.statusOnline.withValues(alpha: 0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AdminTheme.space10),
              Text(
                strings.centralAdminConsole,
                style: AdminTheme.badgeText.copyWith(
                  color: AdminColors.brandNavy,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: AdminTheme.space12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AdminTheme.space8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(AdminTheme.radius6),
                  border: Border.all(
                    color: AdminColors.brandTeal.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  strings.terminalOnline,
                  style: AdminTheme.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    color: AdminColors.brandTeal,
                  ),
                ),
              ),
            ],
          ),

          // Live Clock
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AdminTheme.space16,
              vertical: AdminTheme.space8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(AdminTheme.radiusFull),
              border: Border.all(
                color: AdminColors.brandTeal.withValues(alpha: 0.2),
              ),
              boxShadow: AdminTheme.shadowSubtle,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: AdminColors.brandTeal,
                ),
                const SizedBox(width: AdminTheme.space8),
                Text(
                  AppDateUtils.formatTime(_currentTime),
                  style: AdminTheme.bodyBold.copyWith(
                    color: AdminColors.brandNavy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Prominent Touch to Begin CTA Container.
  Widget _buildBeginCta(dynamic strings) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(
        children: [
          AdminPrimaryButton(
            focusNode: _beginFocusNode,
            autofocus: true,
            label: strings.touchToBegin,
            icon: Icons.login_rounded,
            height: 54,
            width: double.infinity,
            onPressed: _handleBegin,
          ),
          const SizedBox(height: AdminTheme.space12),
          Text(
            strings.touchToBeginSubtitle,
            style: AdminTheme.caption.copyWith(
              color: AdminColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Bottom status bar with governance notice and portal switcher.
  Widget _buildBottomBar(BuildContext context, dynamic strings) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminTheme.space32,
        vertical: AdminTheme.space16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Security & Compliance Notice
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 16,
                  color: AdminColors.brandTeal,
                ),
                const SizedBox(width: AdminTheme.space8),
                Expanded(
                  child: Text(
                    strings.protectedAdminSession,
                    style: AdminTheme.caption.copyWith(
                      color: AdminColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AdminTheme.space16),

          // Right: Doctor Mode Switch & App Version
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: _handleSwitchToDoctor,
                icon: const Icon(
                  Icons.swap_horiz_rounded,
                  size: 16,
                  color: AdminColors.brandTeal,
                ),
                label: Text(
                  'Doctor Portal',
                  style: AdminTheme.caption.copyWith(
                    color: AdminColors.brandTeal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AdminTheme.space16),
              Text(
                '${AppConstants.appName} Admin • v${AppConstants.appVersion}',
                style: AdminTheme.caption.copyWith(
                  color: AdminColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

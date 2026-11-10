import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/date_utils.dart';
import '../../kiosk/widgets/aayusathi_ambient_ecg.dart';
import '../localization/doctor_localizations.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import '../widgets/doctor_buttons.dart';
import '../widgets/doctor_heartbeat_logo.dart';

/// The official AAYUSATHI Doctor Standby Screen (Phase D1).
/// Welcomes physicians to the hospital clinical workstation.
/// Features clean greenish-white medical styling, subtle dual-pulse heartbeat animation,
/// accessible typography, and keyboard-activated login navigation.
class DoctorStandbyScreen extends StatefulWidget {
  final VoidCallback? onLoginPressed;
  final VoidCallback? onSwitchToKiosk;

  const DoctorStandbyScreen({
    super.key,
    this.onLoginPressed,
    this.onSwitchToKiosk,
  });

  @override
  State<DoctorStandbyScreen> createState() => _DoctorStandbyScreenState();
}

class _DoctorStandbyScreenState extends State<DoctorStandbyScreen> {
  late DateTime _currentTime;
  Timer? _clockTimer;
  final FocusNode _loginFocusNode = FocusNode();

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
    _loginFocusNode.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (widget.onLoginPressed != null) {
      widget.onLoginPressed!();
    } else {
      Navigator.of(context).pushNamed(AppRoutes.doctorLogin);
    }
  }

  void _handleSwitchToKiosk() {
    if (widget.onSwitchToKiosk != null) {
      widget.onSwitchToKiosk!();
    } else {
      Navigator.of(context).pushNamed(AppRoutes.kioskHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.of(context);

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.space): const ActivateIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _handleLogin();
              return null;
            },
          ),
        },
        child: Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              // Greenish-White medical theme gradient
              gradient: RadialGradient(
                center: Alignment(0.0, -0.2),
                radius: 1.35,
                colors: [
                  DoctorColors.standbyBgCenter,
                  DoctorColors.standbyBgMid,
                  DoctorColors.standbyBgVignette,
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
                            DoctorColors.standbyAuraCore,
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
                      // Top Bar: Workstation ID & Status
                      _buildTopBar(context, strings),

                      // Center Stage: Logo, Tagline, Title & Prominent Login Button
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: DoctorTheme.space32,
                              vertical: DoctorTheme.space16,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 760),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Official Logo with dual-pulse medical heartbeat
                                  const DoctorHeartbeatLogo(
                                    width: 380,
                                    height: 210,
                                  ),
                                  const SizedBox(height: DoctorTheme.space16),

                                  // Official Tagline
                                  Text(
                                    AppConstants.appTagline,
                                    style: DoctorTheme.badgeText.copyWith(
                                      color: DoctorColors.brandOrange,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2.5,
                                      fontSize: 15,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: DoctorTheme.space12),

                                  // Professional Portal Heading
                                  Text(
                                    strings.doctorPortalTitle,
                                    style: DoctorTheme.displayTitle.copyWith(
                                      fontSize: 28,
                                      color: DoctorColors.brandNavy,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: DoctorTheme.space8),

                                  // Subheading
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 580),
                                    child: Text(
                                      strings.standbySubheadline,
                                      style: DoctorTheme.subtitle.copyWith(
                                        fontSize: 14,
                                        color: DoctorColors.textSecondary,
                                        height: 1.4,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: DoctorTheme.space32),

                                  // Prominent LOGIN CTA Button
                                  _buildLoginCta(strings),
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

  /// Top workstation status bar with hospital identity and live clock.
  Widget _buildTopBar(BuildContext context, dynamic strings) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DoctorTheme.space32,
        vertical: DoctorTheme.space16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Clinical Desk Identifier
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: DoctorColors.statusOnline,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: DoctorColors.statusOnline.withValues(alpha: 0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DoctorTheme.space10),
              Text(
                'OPD CLINICAL WORKSTATION',
                style: DoctorTheme.badgeText.copyWith(
                  color: DoctorColors.brandNavy,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: DoctorTheme.space12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DoctorTheme.space8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                  border: Border.all(
                    color: DoctorColors.brandTeal.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  'TERMINAL ONLINE',
                  style: DoctorTheme.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    color: DoctorColors.brandTeal,
                  ),
                ),
              ),
            ],
          ),

          // Live Clock
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DoctorTheme.space16,
              vertical: DoctorTheme.space8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(DoctorTheme.radiusFull),
              border: Border.all(
                color: DoctorColors.brandTeal.withValues(alpha: 0.2),
              ),
              boxShadow: DoctorTheme.shadowSubtle,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: DoctorColors.brandTeal,
                ),
                const SizedBox(width: DoctorTheme.space8),
                Text(
                  AppDateUtils.formatTime(_currentTime),
                  style: DoctorTheme.bodyBold.copyWith(
                    color: DoctorColors.brandNavy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Prominent Doctor Login CTA Container.
  Widget _buildLoginCta(dynamic strings) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(
        children: [
          DoctorPrimaryButton(
            focusNode: _loginFocusNode,
            autofocus: true,
            label: strings.loginButtonLabel,
            icon: Icons.login_rounded,
            height: 54,
            width: double.infinity,
            onPressed: _handleLogin,
          ),
          const SizedBox(height: DoctorTheme.space12),
          Text(
            strings.loginTooltip,
            style: DoctorTheme.caption.copyWith(
              color: DoctorColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Bottom status bar with compliance notice and portal switch.
  Widget _buildBottomBar(BuildContext context, dynamic strings) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DoctorTheme.space32,
        vertical: DoctorTheme.space16,
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
                  color: DoctorColors.brandTeal,
                ),
                const SizedBox(width: DoctorTheme.space8),
                Expanded(
                  child: Text(
                    strings.secureSessionNotice,
                    style: DoctorTheme.caption.copyWith(
                      color: DoctorColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DoctorTheme.space16),

          // Right: Mode switch & App version
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: _handleSwitchToKiosk,
                icon: const Icon(
                  Icons.swap_horiz_rounded,
                  size: 16,
                  color: DoctorColors.brandTeal,
                ),
                label: Text(
                  strings.switchToKiosk,
                  style: DoctorTheme.caption.copyWith(
                    color: DoctorColors.brandTeal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: DoctorTheme.space16),
              Text(
                '${AppConstants.appName} Doctor • v${AppConstants.appVersion}',
                style: DoctorTheme.caption.copyWith(
                  color: DoctorColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

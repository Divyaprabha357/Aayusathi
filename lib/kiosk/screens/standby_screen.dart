import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/kiosk_localizations.dart';
import '../../core/localization/kiosk_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_utils.dart';
import '../widgets/aayusathi_ambient_ecg.dart';
import '../widgets/aayusathi_heartbeat_logo.dart';

/// Premium AAYUSATHI Kiosk Standby / Idle Screen.
/// The primary visual welcome surface for the hospital OPD terminal.
/// Features center-stage ambient lighting for high logo contrast,
/// medically synchronized heartbeat animation, and full-screen touch-to-begin interaction.
class StandbyScreen extends StatefulWidget {
  final VoidCallback? onBegin;

  const StandbyScreen({
    super.key,
    this.onBegin,
  });

  @override
  State<StandbyScreen> createState() => _StandbyScreenState();
}

class _StandbyScreenState extends State<StandbyScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _currentTime;
  Timer? _clockTimer;
  bool _isPressed = false;
  late AnimationController _ctaPulseController;
  late Animation<double> _ctaPulseAnimation;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });

    // Gentle breathing pulse for the main CTA button
    _ctaPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _ctaPulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _ctaPulseController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _ctaPulseController.dispose();
    super.dispose();
  }

  void _handleBegin() {
    if (widget.onBegin != null) {
      widget.onBegin!();
    } else {
      Navigator.of(context).pushNamed(AppRoutes.language);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = KioskLocalizations.of(context);

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _handleBegin();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.99 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              // Greenish-White / Light Medical Theme background gradient:
              // Pale luminous medical teal center with calm mint transition and soft edge vignette.
              gradient: RadialGradient(
                center: Alignment(0.0, -0.15),
                radius: 1.25,
                colors: [
                  AppColors.standbyLightBgCenter,
                  AppColors.standbyLightBgMid,
                  AppColors.standbyLightBgVignette,
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ambient Subtle ECG Trace (Light Mode)
                const AayusathiAmbientEcg(isLightMode: true),

                // Center-Stage Diffused Ambient Light Spotlight behind Logo
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.18,
                  child: Container(
                    width: 580,
                    height: 360,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.standbyLightAuraCore,
                          Colors.transparent,
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),

                // Main Content Layout
                SafeArea(
                  child: Column(
                    children: [
                      // Top Bar: Terminal Status + Live Clock
                      _buildTopBar(context),

                      // Center Stage: Logo, Tagline, and Touch to Begin
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 820),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // 1. Official Logo with Heartbeat Pulse & Light Medical Ambient Illumination
                                  const AayusathiHeartbeatLogo(
                                    width: 400,
                                    height: 230,
                                    isLightMode: true,
                                  ),
                                  const SizedBox(height: 18),

                                  // 2. Tagline
                                  Text(
                                    AppConstants.appTagline,
                                    style: AppTextStyles.headlineMedium.copyWith(
                                      color: AppColors.brandOrange,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2.5,
                                      fontSize: 18,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 10),

                                  // 3. Welcoming Subtitle
                                  Text(
                                    strings.healthJourney,
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: AppColors.textPrimary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 44),

                                  // 4. Large Pulsing Touch to Begin CTA Card
                                  _buildTouchToBeginCta(strings),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Bottom Bar: Hospital Assistance & Version
                      _buildBottomBar(context),
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

  /// Top navigation bar with hospital status and live clock.
  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Kiosk Terminal Status Indicator
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.statusNormal,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.statusNormal.withValues(alpha: 0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'OPD SELF-SERVICE TERMINAL',
                style: AppTextStyles.tag.copyWith(
                  color: AppColors.brandNavy,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          // Live Clock
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.brandTeal.withValues(alpha: 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandTeal.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: AppColors.brandTeal,
                ),
                const SizedBox(width: 8),
                Text(
                  AppDateUtils.formatTime(_currentTime),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.brandNavy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Large Touch To Begin Interactive CTA.
  Widget _buildTouchToBeginCta(KioskStrings strings) {
    return ScaleTransition(
      scale: _ctaPulseAnimation,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF007E8A),
              Color(0xFF005861),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.secondaryLight.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandTeal.withValues(alpha: 0.30),
              blurRadius: 24,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.touch_app_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 18),
            Flexible(
              child: Text(
                strings.touchToBegin,
                style: AppTextStyles.buttonLarge.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 14),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom footer bar with assistance contact and versioning.
  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.support_agent_rounded,
                size: 18,
                color: AppColors.brandTeal,
              ),
              const SizedBox(width: 8),
              Text(
                'Need help? Touch screen or ask OPD Staff Nurse.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Text(
            '${AppConstants.appName} Kiosk • v${AppConstants.appVersion}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

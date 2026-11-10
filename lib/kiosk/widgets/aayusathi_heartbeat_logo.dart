import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';

/// Premium AAYUSATHI logo with a medically accurate dual-pulse heartbeat animation.
/// Sequence: REST -> SMALL PULSE -> STRONGER PULSE -> RETURN TO REST -> SHORT PAUSE -> repeat.
/// The logo image remains stable while ambient radial glow and ripple waves provide the heartbeat effect.
class AayusathiHeartbeatLogo extends StatefulWidget {
  final double width;
  final double height;
  final bool isLightMode;

  const AayusathiHeartbeatLogo({
    super.key,
    this.width = 340.0,
    this.height = 200.0,
    this.isLightMode = false,
  });

  @override
  State<AayusathiHeartbeatLogo> createState() => _AayusathiHeartbeatLogoState();
}

class _AayusathiHeartbeatLogoState extends State<AayusathiHeartbeatLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Typical resting human heartbeat ~60-70 bpm = ~1.6 seconds per cardiac cycle
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Calculates heartbeat pulse intensity [0.0 to 1.0] based on cardiac cycle time t [0.0 to 1.0].
  /// t in [0.00, 0.12] => Atrial Systole (Pulse 1: Small peak)
  /// t in [0.12, 0.22] => Diastolic dip (Rest)
  /// t in [0.22, 0.42] => Ventricular Systole (Pulse 2: Stronger peak)
  /// t in [0.42, 0.58] => Ventricular Repolarization (Return to rest)
  /// t in [0.58, 1.00] => Quiescent cardiac pause (Rest)
  double _calculatePulseIntensity(double t) {
    if (t < 0.12) {
      // Small pulse (sinusoidal half-wave up to 0.45)
      final p = t / 0.12;
      return 0.45 * math.sin(p * math.pi);
    } else if (t < 0.22) {
      return 0.0;
    } else if (t < 0.42) {
      // Stronger pulse (sinusoidal half-wave up to 1.0)
      final p = (t - 0.22) / 0.20;
      return 1.0 * math.sin(p * math.pi);
    } else if (t < 0.55) {
      // Gentle return to baseline
      final p = (t - 0.42) / 0.13;
      return (1.0 - p) * 0.15;
    } else {
      // Quiescent resting pause
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final intensity = _calculatePulseIntensity(t);

        // Logo experiences very subtle, elegant breathing scale (max 1.03x)
        final logoScale = 1.0 + (0.025 * intensity);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Ambient Heartbeat Radial Glow & Concentric Ripple Waves
            CustomPaint(
              size: Size(widget.width * 1.5, widget.height * 1.5),
              painter: _HeartbeatAuraPainter(
                intensity: intensity,
                cycleProgress: t,
                isLightMode: widget.isLightMode,
              ),
            ),

            // Transparent Official AAYUSATHI Logo
            Transform.scale(
              scale: logoScale,
              child: Image.asset(
                AppAssets.logo,
                width: widget.width,
                height: widget.height,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if asset is missing or during tests
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: AppColors.brandTeal,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_hospital_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'AAYUSATHI',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const Text(
                        'LIVE BETTER, TOGETHER',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandOrange,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Custom painter rendering the soft medical aura and synchronized dual-pulse wave.
class _HeartbeatAuraPainter extends CustomPainter {
  final double intensity;
  final double cycleProgress;
  final bool isLightMode;

  const _HeartbeatAuraPainter({
    required this.intensity,
    required this.cycleProgress,
    this.isLightMode = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.width, size.height) * 0.42;

    // 1. Persistent Ambient Soft Backlight
    // Dark mode: luminous teal-mist backlight for sharp navy silhouette.
    // Light mode: soft diffused white-teal halo behind logo for clean medical presence.
    final persistentBacklightPaint = Paint()
      ..shader = RadialGradient(
        colors: isLightMode
            ? [
                AppColors.standbyLightBacklight,
                AppColors.standbyLightAuraCore,
                Colors.transparent,
              ]
            : [
                AppColors.standbyBacklight,
                AppColors.standbyAuraCore,
                Colors.transparent,
              ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius * 1.15));

    canvas.drawCircle(center, baseRadius * 1.15, persistentBacklightPaint);

    // 2. Dynamic Heartbeat Radial Pulse
    if (intensity > 0.01) {
      final tealAlpha1 = isLightMode ? 0.22 * intensity : 0.40 * intensity;
      final tealAlpha2 = isLightMode ? 0.08 * intensity : 0.15 * intensity;

      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.brandTeal.withValues(alpha: tealAlpha1),
            AppColors.brandTeal.withValues(alpha: tealAlpha2),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: baseRadius * (1.0 + 0.35 * intensity)));

      canvas.drawCircle(center, baseRadius * (1.0 + 0.35 * intensity), glowPaint);

      // 3. Secondary Warm Orange Accent Glow (matching logo's heart accent)
      final orangeAlpha = isLightMode ? 0.15 * intensity : 0.25 * intensity;
      final accentGlow = Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.brandOrange.withValues(alpha: orangeAlpha),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: baseRadius * 0.85));

      canvas.drawCircle(center, baseRadius * 0.85, accentGlow);

      // 4. Subtle expanding ripple ring on strong systolic pulse
      if (intensity > 0.3) {
        final ringRadius = baseRadius * (0.8 + 0.4 * intensity);
        final ringAlpha = isLightMode ? 0.16 : 0.25;
        final ringPaint = Paint()
          ..color = AppColors.brandTeal.withValues(alpha: ringAlpha * (1.0 - (ringRadius / (baseRadius * 1.3))))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        canvas.drawCircle(center, ringRadius, ringPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_HeartbeatAuraPainter oldDelegate) {
    return oldDelegate.intensity != intensity ||
        oldDelegate.cycleProgress != cycleProgress ||
        oldDelegate.isLightMode != isLightMode;
  }
}

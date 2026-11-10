import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../theme/admin_colors.dart';

/// Medically accurate dual-pulse heartbeat animation for the AAYUSATHI Admin Interface.
/// Cardiac cycle sequence: REST -> SMALL PULSE -> STRONGER PULSE -> RETURN TO REST -> SHORT PAUSE -> repeat.
/// Subtle, non-distracting: centered and stable with subtle breathing scale (1.0 to 1.025)
/// and soft medical mint/teal radial illumination.
class AdminHeartbeatLogo extends StatefulWidget {
  final double width;
  final double height;
  final bool showTagline;

  const AdminHeartbeatLogo({
    super.key,
    this.width = 360.0,
    this.height = 200.0,
    this.showTagline = false,
  });

  @override
  State<AdminHeartbeatLogo> createState() => _AdminHeartbeatLogoState();
}

class _AdminHeartbeatLogoState extends State<AdminHeartbeatLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Resting cardiac rhythm ~60 bpm = ~1.7 seconds per complete cycle
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

  /// Calculates dual-pulse intensity [0.0 to 1.0] from normalized cycle time t [0.0 to 1.0].
  /// t in [0.00, 0.12] => Atrial Systole (Small pulse)
  /// t in [0.12, 0.22] => Diastolic pause (Rest)
  /// t in [0.22, 0.42] => Ventricular Systole (Strong pulse)
  /// t in [0.42, 0.55] => Ventricular Repolarization (Gentle descent)
  /// t in [0.55, 1.00] => Quiescent resting pause (Rest)
  double _calculatePulseIntensity(double t) {
    if (t < 0.12) {
      final p = t / 0.12;
      return 0.40 * math.sin(p * math.pi);
    } else if (t < 0.22) {
      return 0.0;
    } else if (t < 0.42) {
      final p = (t - 0.22) / 0.20;
      return 1.0 * math.sin(p * math.pi);
    } else if (t < 0.55) {
      final p = (t - 0.42) / 0.13;
      return (1.0 - p) * 0.15;
    } else {
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
        final scale = 1.0 + (0.025 * intensity);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Soft Medical Diffused Halo & Cardiac Ripple Waves
            CustomPaint(
              size: Size(widget.width * 1.4, widget.height * 1.4),
              painter: _AdminHeartbeatAuraPainter(
                intensity: intensity,
                cycleProgress: t,
              ),
            ),

            // Official AAYUSATHI Brand Logo
            Transform.scale(
              scale: scale,
              child: Image.asset(
                AppAssets.logo,
                width: widget.width,
                height: widget.height,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: AdminColors.brandTeal,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_hospital_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'AAYUSATHI',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AdminColors.brandNavy,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const Text(
                        'LIVE BETTER, TOGETHER.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AdminColors.brandOrange,
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

/// Custom painter for the admin interface medical aura and dual-pulse systolic wave.
class _AdminHeartbeatAuraPainter extends CustomPainter {
  final double intensity;
  final double cycleProgress;

  const _AdminHeartbeatAuraPainter({
    required this.intensity,
    required this.cycleProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.width, size.height) * 0.44;

    // 1. Luminous Diffused White-Teal Halo behind Logo
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: const [
          AdminColors.standbyBacklight,
          AdminColors.standbyAuraCore,
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius * 1.15));

    canvas.drawCircle(center, baseRadius * 1.15, haloPaint);

    // 2. Soft Medical Teal Systolic Pulse
    if (intensity > 0.01) {
      final tealPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            AdminColors.brandTeal.withValues(alpha: 0.18 * intensity),
            AdminColors.brandTeal.withValues(alpha: 0.06 * intensity),
            Colors.transparent,
          ],
          stops: const [0.0, 0.60, 1.0],
        ).createShader(
            Rect.fromCircle(center: center, radius: baseRadius * (1.0 + 0.30 * intensity)));

      canvas.drawCircle(center, baseRadius * (1.0 + 0.30 * intensity), tealPaint);

      // 3. Subtle Warm Care Orange Accent
      final orangePaint = Paint()
        ..shader = RadialGradient(
          colors: [
            AdminColors.brandOrange.withValues(alpha: 0.14 * intensity),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: baseRadius * 0.85));

      canvas.drawCircle(center, baseRadius * 0.85, orangePaint);

      // 4. Subtle expanding ripple stroke on strong systolic pulse
      if (intensity > 0.3) {
        final ringRadius = baseRadius * (0.8 + 0.35 * intensity);
        final ringAlpha = 0.14 * (1.0 - (ringRadius / (baseRadius * 1.25)));
        final ringPaint = Paint()
          ..color = AdminColors.brandTeal.withValues(alpha: ringAlpha.clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        canvas.drawCircle(center, ringRadius, ringPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_AdminHeartbeatAuraPainter oldDelegate) {
    return oldDelegate.intensity != intensity ||
        oldDelegate.cycleProgress != cycleProgress;
  }
}

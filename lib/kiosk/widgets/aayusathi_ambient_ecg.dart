import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Ambient clinical background painter displaying a subtle ECG rhythm trace.
class AayusathiAmbientEcg extends StatelessWidget {
  final bool isLightMode;

  const AayusathiAmbientEcg({
    super.key,
    this.isLightMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _AmbientEcgPainter(isLightMode: isLightMode),
        ),
      ),
    );
  }
}

class _AmbientEcgPainter extends CustomPainter {
  final bool isLightMode;

  const _AmbientEcgPainter({this.isLightMode = false});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.brandTeal.withValues(alpha: isLightMode ? 0.08 : 0.045)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final y = size.height * 0.52;
    final w = size.width;

    path.moveTo(0, y);

    // Repeated subtle ECG rhythm cycle
    const cycleWidth = 180.0;
    double currentX = 0;

    while (currentX < w) {
      path.lineTo(currentX + 40, y);
      // P wave
      path.quadraticBezierTo(currentX + 50, y - 6, currentX + 60, y);
      // PR segment
      path.lineTo(currentX + 75, y);
      // Q drop
      path.lineTo(currentX + 80, y + 8);
      // R peak
      path.lineTo(currentX + 90, y - 42);
      // S drop
      path.lineTo(currentX + 100, y + 16);
      // ST segment
      path.lineTo(currentX + 108, y);
      // T wave
      path.quadraticBezierTo(currentX + 125, y - 12, currentX + 142, y);
      // TP interval
      path.lineTo(currentX + cycleWidth, y);

      currentX += cycleWidth;
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

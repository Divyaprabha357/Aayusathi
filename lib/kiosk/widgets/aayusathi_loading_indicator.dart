import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Medical pulse loading indicator for AAYUSATHI.
class AayusathiLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;
  final String? message;

  const AayusathiLoadingIndicator({
    super.key,
    this.size = 48.0,
    this.color,
    this.message,
  });

  @override
  State<AayusathiLoadingIndicator> createState() => _AayusathiLoadingIndicatorState();
}

class _AayusathiLoadingIndicatorState extends State<AayusathiLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _opacityAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color tint = widget.color ?? AppColors.brandTeal;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tint.withValues(alpha: 0.12),
                  boxShadow: [
                    BoxShadow(
                      color: tint.withValues(alpha: 0.25 * _opacityAnimation.value),
                      blurRadius: 20 * _scaleAnimation.value,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.favorite_rounded,
                    color: tint.withValues(alpha: _opacityAnimation.value),
                    size: widget.size * 0.5,
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

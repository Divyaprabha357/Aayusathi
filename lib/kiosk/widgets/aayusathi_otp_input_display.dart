import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Touchscreen-optimized 6-digit OTP box display widget.
/// Renders 6 distinct rounded boxes with focused, filled, empty, and error states.
class AayusathiOtpInputDisplay extends StatefulWidget {
  final String otpValue;
  final int length;
  final bool hasError;
  final bool isKeypadDisabled;

  const AayusathiOtpInputDisplay({
    super.key,
    required this.otpValue,
    this.length = 6,
    this.hasError = false,
    this.isKeypadDisabled = false,
  });

  @override
  State<AayusathiOtpInputDisplay> createState() => _AayusathiOtpInputDisplayState();
}

class _AayusathiOtpInputDisplayState extends State<AayusathiOtpInputDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cursorController;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (index) {
        final bool isFilled = index < widget.otpValue.length;
        final bool isFocused = index == widget.otpValue.length && !widget.isKeypadDisabled;
        final String digit = isFilled ? widget.otpValue[index] : '';

        return Container(
          width: 54,
          height: 68,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: widget.hasError
                ? const Color(0xFFFDE8E8)
                : (isFocused
                    ? const Color(0xFFE8F5F1)
                    : (isFilled ? Colors.white : const Color(0xFFF9FBFA))),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.hasError
                  ? AppColors.statusCritical
                  : (isFocused
                      ? AppColors.brandTeal
                      : (isFilled
                          ? AppColors.brandTeal.withValues(alpha: 0.5)
                          : const Color(0xFFD3E7E2))),
              width: isFocused || widget.hasError ? 2.4 : 1.6,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: AppColors.brandTeal.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: isFilled
              ? Text(
                  digit,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: AppColors.brandNavy,
                  ),
                )
              : (isFocused
                  ? AnimatedBuilder(
                      animation: _cursorController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _cursorController.value > 0.5 ? 1.0 : 0.0,
                          child: Container(
                            width: 2.2,
                            height: 28,
                            color: AppColors.brandTeal,
                          ),
                        );
                      },
                    )
                  : const SizedBox.shrink()),
        );
      }),
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/patient_colors.dart';

/// Senior-accessible 6-digit OTP input widget.
///
/// Features:
/// - Six visually distinct interactive boxes (48–52dp touch targets)
/// - Visible 1.5px borders (#C8D8D1) on resting/empty boxes
/// - Highlighted medical teal focus border (#00897B) and background tint (#E0F2F1) on active box
/// - Bold, high-contrast navy digits (#142238)
/// - Responsive sizing ensuring clean fit on 360dp mobile screens up to desktop
/// - Backed by an integrated TextField for smooth keyboard input, paste, and testability
class PatientOtpField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  const PatientOtpField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
  });

  @override
  State<PatientOtpField> createState() => _PatientOtpFieldState();
}

class _PatientOtpFieldState extends State<PatientOtpField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChange);
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChange);
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleTextChange() {
    if (mounted) setState(() {});
  }

  void _handleFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final isFocused = _focusNode.hasFocus;
    final activeIndex = isFocused ? min(text.length, 5) : -1;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate box size dynamically (between 42 and 52dp)
        const int boxCount = 6;
        const double gap = 8.0;
        final totalGaps = gap * (boxCount - 1);
        final availableWidth = constraints.maxWidth;
        final calculatedBoxWidth = (availableWidth - totalGaps) / boxCount;
        final boxSize = calculatedBoxWidth.clamp(40.0, 52.0);

        return Stack(
          alignment: Alignment.center,
          children: [
            // 6 Visual Digit Boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(boxCount, (index) {
                final hasDigit = index < text.length;
                final digit = hasDigit ? text[index] : '';
                final isCurrentActive = isFocused && (index == activeIndex);

                Color borderColor = PatientColors.inputBorder;
                Color bgColor = PatientColors.inputFill;

                if (isCurrentActive) {
                  borderColor = PatientColors.inputBorderFocused;
                  bgColor = PatientColors.tealLight;
                } else if (hasDigit) {
                  borderColor = PatientColors.teal;
                  bgColor = Colors.white;
                }

                return GestureDetector(
                  onTap: () {
                    _focusNode.requestFocus();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: boxSize,
                    height: boxSize * 1.15,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor,
                        width: isCurrentActive ? 2.0 : 1.5,
                      ),
                      boxShadow: isCurrentActive
                          ? [
                              BoxShadow(
                                color: PatientColors.teal.withAlpha(40),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      digit,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: PatientColors.navy,
                      ),
                    ),
                  ),
                );
              }),
            ),

            // Underlying transparent TextField to capture keyboard, paste, and test input
            Opacity(
              opacity: 0.0,
              child: SizedBox(
                width: double.infinity,
                height: boxSize * 1.15,
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  autofocus: widget.autofocus,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (val) {
                    widget.onChanged?.call(val);
                    if (val.length == 6) {
                      widget.onSubmitted?.call(val);
                    }
                  },
                  onSubmitted: widget.onSubmitted,
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/localization/kiosk_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Large touchscreen-first numeric keypad designed specifically for hospital kiosks.
/// Accessible for elderly users, requiring zero physical keyboard interaction.
/// 
/// Layout:
/// 1  2  3
/// 4  5  6
/// 7  8  9
/// ⌫  0  CLEAR
class AayusathiNumericKeypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final bool isEnabled;

  const AayusathiNumericKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    required this.onClear,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final strings = KioskLocalizations.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: 1, 2, 3
          Row(
            children: [
              _buildKey(label: '1', onTap: () => onDigit('1')),
              const SizedBox(width: 14),
              _buildKey(label: '2', onTap: () => onDigit('2')),
              const SizedBox(width: 14),
              _buildKey(label: '3', onTap: () => onDigit('3')),
            ],
          ),
          const SizedBox(height: 14),

          // Row 2: 4, 5, 6
          Row(
            children: [
              _buildKey(label: '4', onTap: () => onDigit('4')),
              const SizedBox(width: 14),
              _buildKey(label: '5', onTap: () => onDigit('5')),
              const SizedBox(width: 14),
              _buildKey(label: '6', onTap: () => onDigit('6')),
            ],
          ),
          const SizedBox(height: 14),

          // Row 3: 7, 8, 9
          Row(
            children: [
              _buildKey(label: '7', onTap: () => onDigit('7')),
              const SizedBox(width: 14),
              _buildKey(label: '8', onTap: () => onDigit('8')),
              const SizedBox(width: 14),
              _buildKey(label: '9', onTap: () => onDigit('9')),
            ],
          ),
          const SizedBox(height: 14),

          // Row 4: BACKSPACE (⌫), 0, CLEAR
          Row(
            children: [
              // Backspace key
              _buildSpecialKey(
                key: const ValueKey('keypad_backspace'),
                icon: Icons.backspace_outlined,
                label: strings.delete,
                accentColor: AppColors.brandOrange,
                onTap: onBackspace,
              ),
              const SizedBox(width: 14),

              // 0 key
              _buildKey(label: '0', onTap: () => onDigit('0')),
              const SizedBox(width: 14),

              // Clear key
              _buildSpecialKey(
                key: const ValueKey('keypad_clear'),
                icon: Icons.delete_sweep_outlined,
                label: strings.clear,
                accentColor: AppColors.statusCritical,
                onTap: onClear,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey({
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: _KeypadButton(
        key: ValueKey('keypad_$label'),
        onTap: isEnabled ? onTap : null,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.brandNavy,
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKey({
    required Key key,
    required IconData icon,
    required String label,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: _KeypadButton(
        key: key,
        onTap: isEnabled ? onTap : null,
        accentColor: accentColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: accentColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: accentColor,
                letterSpacing: 0.8,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _KeypadButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? accentColor;

  const _KeypadButton({
    super.key,
    required this.child,
    this.onTap,
    this.accentColor,
  });

  @override
  State<_KeypadButton> createState() => _KeypadButtonState();
}

class _KeypadButtonState extends State<_KeypadButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onTap != null;
    final Color borderTint = widget.accentColor ?? AppColors.brandTeal;

    return MouseRegion(
      onEnter: (_) {
        if (isEnabled) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (isEnabled) setState(() => _isHovered = false);
      },
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: (_) {
          if (isEnabled) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (isEnabled) setState(() => _isPressed = false);
        },
        onTapCancel: () {
          if (isEnabled) setState(() => _isPressed = false);
        },
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.94 : (_isHovered ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            height: 68,
            decoration: BoxDecoration(
              color: _isPressed
                  ? borderTint.withValues(alpha: 0.14)
                  : (_isHovered ? const Color(0xFFF0F7F6) : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isHovered
                    ? borderTint.withValues(alpha: 0.7)
                    : const Color(0xFFD6EAE6),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandNavy.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}

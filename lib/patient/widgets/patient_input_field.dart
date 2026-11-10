import 'package:flutter/material.dart';
import '../theme/patient_colors.dart';

/// High-visibility, accessible input field for the AAYUSATHI Patient App.
///
/// Features:
/// - Light medical mint background (#F4F8F6) for clear contrast against white cards
/// - Clearly visible 1.5px border (#C8D8D1) in resting state
/// - Prominent 2.0px medical teal border (#00897B) in focused state
/// - Readable, high-contrast hint text (#5A6E65) that is never faint or invisible
/// - Deep navy entered text (#142238) with semibold weight
/// - Standard 56dp touch-friendly height and 14dp rounded corners
/// - Clear leading icon (badge/ID) in medical teal
class PatientInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? labelText;
  final IconData leadingIcon;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;
  final TextCapitalization textCapitalization;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool autofocus;
  final bool enabled;

  const PatientInputField({
    super.key,
    required this.controller,
    required this.hintText,
    this.labelText,
    this.leadingIcon = Icons.badge_outlined,
    this.onFieldSubmitted,
    this.validator,
    this.textCapitalization = TextCapitalization.characters,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.autofocus = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: PatientColors.navy,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          enabled: enabled,
          autofocus: autofocus,
          textCapitalization: textCapitalization,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: PatientColors.navy,
            letterSpacing: 0.5,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: PatientColors.inputFill,
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: PatientColors.hintColor,
            ),
            prefixIcon: Icon(
              leadingIcon,
              color: PatientColors.teal,
              size: 22,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: PatientColors.inputBorder,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: PatientColors.inputBorder,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: PatientColors.inputBorderFocused,
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: PatientColors.statusCritical,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: PatientColors.statusCritical,
                width: 2.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

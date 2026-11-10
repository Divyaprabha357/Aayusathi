import 'package:flutter/material.dart';
import '../controllers/patient_auth_controller.dart';
import '../localization/patient_localizations.dart';
import '../theme/patient_colors.dart';
import '../theme/patient_spacing.dart';
import '../widgets/patient_auth_scaffold.dart';
import '../widgets/patient_input_field.dart';

/// Senior-accessible Patient Login Screen (`/patient/login`).
///
/// Features:
/// - Unified top-aligned PatientAuthScaffold
/// - Official approved AAYUSATHI logo and tagline
/// - High-contrast, visible patient identification input field
/// - Clear validation & error feedback
/// - Direct navigation to OTP verification
class PatientLoginScreen extends StatefulWidget {
  final PatientAuthController? controller;

  const PatientLoginScreen({
    super.key,
    this.controller,
  });

  @override
  State<PatientLoginScreen> createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen> {
  late final PatientAuthController _controller;
  final TextEditingController _idController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? PatientAuthController();
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _idController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    setState(() {});
  }

  Future<void> _handleContinue() async {
    final rawInput = _idController.text.trim();
    final success = await _controller.submitPatientId(rawInput);
    if (success && mounted) {
      Navigator.of(context).pushNamed(
        '/patient/otp',
        arguments: {
          'patientId': _controller.pendingPatientId ?? rawInput,
          'maskedPhone': _controller.maskedPhone,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = PatientLocalizations.of(context);

    return PatientAuthScaffold(
      cardContent: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.loginHeading,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: PatientColors.navy,
              ),
            ),
            const SizedBox(height: PatientSpacing.smallGap),
            Text(
              strings.loginDescription,
              style: const TextStyle(
                fontSize: 14,
                color: PatientColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: PatientSpacing.largeGap),

            // High-visibility Patient ID Input Field
            PatientInputField(
              controller: _idController,
              labelText: strings.loginInputLabel,
              hintText: strings.loginInputHint,
              leadingIcon: Icons.badge_outlined,
              textCapitalization: TextCapitalization.characters,
              onFieldSubmitted: (_) => _handleContinue(),
            ),

            if (_controller.errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PatientColors.statusCriticalLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 18,
                      color: PatientColors.statusCritical,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _controller.errorMessage!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: PatientColors.statusCritical,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: PatientSpacing.largeGap),

            // Submit Button
            ElevatedButton(
              onPressed: _controller.isLoading ? null : _handleContinue,
              child: _controller.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(strings.loginButton),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

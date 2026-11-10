import 'package:flutter/material.dart';
import '../controllers/patient_auth_controller.dart';
import '../localization/patient_localizations.dart';
import '../theme/patient_colors.dart';
import '../theme/patient_spacing.dart';
import '../widgets/patient_auth_scaffold.dart';
import '../widgets/patient_otp_field.dart';

/// Senior-accessible Patient OTP Verification Screen (`/patient/otp`).
///
/// Privacy & Security Guardrails:
/// - Strictly NEVER displays the OTP code anywhere on the screen.
/// - Only displays the masked phone number (`+91 ******4321`).
/// - Enforces 30-second cooldown on resend attempts.
/// - Uses unified PatientAuthScaffold and 6-box PatientOtpField.
class PatientOtpScreen extends StatefulWidget {
  final String? patientId;
  final String? maskedPhone;
  final PatientAuthController? controller;

  const PatientOtpScreen({
    super.key,
    this.patientId,
    this.maskedPhone,
    this.controller,
  });

  @override
  State<PatientOtpScreen> createState() => _PatientOtpScreenState();
}

class _PatientOtpScreenState extends State<PatientOtpScreen> {
  late final PatientAuthController _controller;
  final TextEditingController _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? PatientAuthController();
    if (_controller.pendingPatientId == null && widget.patientId != null) {
      _controller.setPendingPatient(
        widget.patientId!,
        maskedPhone: widget.maskedPhone,
      );
    }
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _otpController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    setState(() {});
  }

  Future<void> _handleVerify() async {
    final code = _otpController.text.trim();
    final success = await _controller.verifyOtp(code);
    if (success && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/patient/dashboard',
        (route) => false,
      );
    }
  }

  Future<void> _handleResend() async {
    final strings = PatientLocalizations.of(context);
    final success = await _controller.resendOtp();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.otpSentSuccess),
          backgroundColor: PatientColors.teal,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = PatientLocalizations.of(context);
    final displayMaskedPhone = widget.maskedPhone ?? _controller.maskedPhone;

    return PatientAuthScaffold(
      onBackTap: () => Navigator.of(context).maybePop(),
      cardContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.otpHeading,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: PatientColors.navy,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: PatientSpacing.smallGap),
          Text(
            strings.otpDescription,
            style: const TextStyle(
              fontSize: 14,
              color: PatientColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: PatientSpacing.sectionGap),

          // Masked Phone Number Pill
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: PatientColors.inputFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PatientColors.border, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.phone_android_rounded,
                    size: 18,
                    color: PatientColors.teal,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      displayMaskedPhone,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: PatientColors.navy,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: PatientSpacing.largeGap),

          // 6-Digit Accessible OTP Input Field
          Text(
            strings.otpInputLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: PatientColors.navy,
            ),
          ),
          const SizedBox(height: PatientSpacing.smallGap),
          PatientOtpField(
            controller: _otpController,
            onSubmitted: (_) => _handleVerify(),
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

          // Verify Button
          ElevatedButton(
            onPressed: _controller.isLoading ? null : _handleVerify,
            child: _controller.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(strings.otpVerifyButton),
          ),
          const SizedBox(height: PatientSpacing.sectionGap),

          // Resend OTP Action with Cooldown
          if (_controller.cooldownRemaining > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  '${strings.resendInSeconds} ${_controller.cooldownRemaining}${strings.seconds}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: PatientColors.textMuted,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _controller.isLoading ? null : _handleResend,
              child: Text(strings.otpResendButton),
            ),
        ],
      ),
    );
  }
}

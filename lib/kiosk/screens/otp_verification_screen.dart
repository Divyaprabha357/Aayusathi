import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../../core/localization/kiosk_localizations.dart';
import '../../core/localization/kiosk_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/patient_identity.dart';
import '../services/kiosk_service.dart';
import '../services/mock_patient_repository.dart';
import '../services/otp_service.dart';
import '../widgets/aayusathi_button.dart';
import '../widgets/aayusathi_glass_card.dart';
import '../widgets/aayusathi_kiosk_scaffold.dart';
import '../widgets/aayusathi_numeric_keypad.dart';
import '../widgets/aayusathi_otp_input_display.dart';

/// Phase 6.5: Hardened OTP Mobile Verification Screen.
/// Provides touch-friendly 6-digit OTP entry, strict patient session guards,
/// duplicate tap prevention, 3-attempt lockout with session wipe, and 30s resend cooldown.
class OtpVerificationScreen extends StatefulWidget {
  final PatientIdentity? patient;
  final String? phoneNumber;
  final String? maskedPhone;
  final String? aadhaarNumber;

  const OtpVerificationScreen({
    super.key,
    this.patient,
    this.phoneNumber,
    this.maskedPhone,
    this.aadhaarNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  String _otpValue = '';
  String? _errorMessage;
  bool _isLoading = false;
  bool _isResending = false;
  bool _isLockedOut = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  String? _feedbackMessage;

  @override
  void initState() {
    super.initState();
    _checkLockoutAndCooldown();
  }

  void _checkLockoutAndCooldown() {
    final otpService = KioskService.instance.otpService;
    _isLockedOut = otpService.isLockedOut;
    _cooldownSeconds = otpService.cooldownRemainingSeconds;
    if (_cooldownSeconds > 0) {
      _startCooldownTimer();
    }
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining = KioskService.instance.otpService.cooldownRemainingSeconds;
      setState(() {
        _cooldownSeconds = remaining;
      });
      if (remaining <= 0) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_isLockedOut || _isLoading || _isResending || _otpValue.length >= 6) return;

    setState(() {
      _otpValue += digit;
      _errorMessage = null;
      _feedbackMessage = null;
    });

    if (_otpValue.length == 6) {
      _handleVerify(context);
    }
  }

  void _onBackspace() {
    if (_isLockedOut || _isLoading || _isResending || _otpValue.isEmpty) return;

    setState(() {
      _otpValue = _otpValue.substring(0, _otpValue.length - 1);
      _errorMessage = null;
      _feedbackMessage = null;
    });
  }

  void _onClear() {
    if (_isLockedOut || _isLoading || _isResending || _otpValue.isEmpty) return;

    setState(() {
      _otpValue = '';
      _errorMessage = null;
      _feedbackMessage = null;
    });
  }

  String? get _targetPhone {
    if (_isExistingPatientFlow && widget.patient != null && widget.patient!.phone.isNotEmpty) {
      return widget.patient!.phone;
    }
    if (widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty) {
      return widget.phoneNumber;
    }
    if (KioskService.instance.activeMobileInput.isNotEmpty) {
      return KioskService.instance.activeMobileInput;
    }
    return widget.patient?.phone ?? KioskService.instance.activeAadhaarPhone;
  }

  String get _displayMaskedPhone {
    if (_isExistingPatientFlow && widget.patient != null && widget.patient!.phone.isNotEmpty) {
      return widget.patient!.maskedPhone;
    }
    if (widget.maskedPhone != null && widget.maskedPhone!.isNotEmpty) {
      return widget.maskedPhone!;
    }
    final phone = _targetPhone;
    if (phone != null && phone.length >= 10) {
      final clean = phone.replaceAll(RegExp(r'\s+'), '');
      final suffix = clean.substring(clean.length - 4);
      return '+91 ••••• •$suffix';
    }
    if (KioskService.instance.activeAadhaarMaskedPhone != null &&
        KioskService.instance.activeAadhaarMaskedPhone!.isNotEmpty) {
      return KioskService.instance.activeAadhaarMaskedPhone!;
    }
    return '••••••';
  }

  String? get _targetAadhaar {
    return widget.patient?.aadhaarNumber ??
        widget.aadhaarNumber ??
        (KioskService.instance.activeAadhaarInput.isNotEmpty
            ? KioskService.instance.activeAadhaarInput
            : null);
  }

  bool get _isExistingPatientFlow {
    return widget.patient != null && !widget.patient!.isNewRegistration;
  }

  Future<void> _handleVerify(BuildContext context) async {
    // Guard: Prevent duplicate verify operations or invalid length
    if (_otpValue.length != 6 || _isLoading || _isResending || _isLockedOut) return;

    final strings = KioskStrings(KioskService.instance.activeLocale);
    final navigator = Navigator.of(context);

    // Guard: Validate active patient identity session exists
    final activePatient = KioskService.instance.identifiedPatient;
    final bool isExistingSession = activePatient != null && activePatient.patientId.isNotEmpty;
    final bool isNewPatientSession = KioskService.instance.activeAadhaarInput.length == 12;
    final bool hasValidDirectContext = widget.patient != null || (_targetPhone != null && _targetPhone!.isNotEmpty);

    if (!isExistingSession && !isNewPatientSession && !hasValidDirectContext) {
      setState(() {
        _errorMessage = strings.invalidSessionError;
      });
      return;
    }

    final phone = _targetPhone;
    if (phone == null || phone.isEmpty) {
      setState(() {
        _errorMessage = strings.invalidSessionError;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _feedbackMessage = null;
    });

    final otpService = KioskService.instance.otpService;
    final result = await otpService.verifyOtp(_otpValue, phoneNumber: phone);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess) {
      KioskService.instance.setOtpVerified(true);
      if (_isExistingPatientFlow && widget.patient != null) {
        navigator.pushReplacementNamed(
          AppRoutes.otpSuccess,
          arguments: widget.patient!,
        );
      } else {
        // New Patient flow: Patient creation happens ONLY AFTER:
        // 1. Aadhaar demographic verification
        // 2. Mobile number manual entry
        // 3. OTP verification
        final aadhaar = _targetAadhaar ?? widget.patient?.aadhaarNumber ?? KioskService.instance.activeAadhaarInput;

        // Atomic Duplicate Aadhaar Protection (prevents simultaneous creation)
        if (aadhaar.isNotEmpty) {
          final isDuplicate = await KioskService.instance.aadhaarService.isAadhaarRegistered(aadhaar);
          if (!mounted) return;
          if (isDuplicate) {
            setState(() {
              _errorMessage = strings.aadhaarAlreadyLinkedMessage;
            });
            return;
          }
        }

        final identitySource = widget.patient ?? KioskService.instance.temporaryAadhaarData;
        final baseIdentity = identitySource ??
            PatientIdentity(
              aadhaarNumber: aadhaar,
              patientId: '',
              fullName: '',
              dob: '',
              age: 0,
              gender: '',
              phone: phone,
              address: '',
              bloodGroup: '',
            );

        // Generate unique AAYUSATHI Patient ID
        final generatedId = KioskService.instance.patientIdService.generatePatientId(baseIdentity);

        // Construct final patient with manual mobile number and generated ID
        final createdPatient = baseIdentity.copyWith(
          aadhaarNumber: aadhaar,
          patientId: generatedId,
          phone: phone,
          isNewRegistration: true,
        );

        // Persist patient record
        KioskService.instance.setIdentifiedPatient(createdPatient);
        MockPatientRepository.instance.savePatient(createdPatient);

        // Navigate to Sensor Instructions Screen before Vitals
        navigator.pushReplacementNamed(
          AppRoutes.sensorInstructions,
          arguments: createdPatient,
        );
        return;
      }
    } else if (result.status == OtpStatus.tooManyAttempts) {
      setState(() {
        _isLockedOut = true;
        _otpValue = '';
        _errorMessage = strings.tooManyAttempts;
      });
    } else if (result.status == OtpStatus.inProgress) {
      // Ignored duplicate tap
    } else {
      setState(() {
        _otpValue = '';
        _errorMessage = '${strings.incorrectOtp} (${strings.attemptsRemaining(result.attemptsRemaining)})';
      });
    }
  }

  Future<void> _handleResend(BuildContext context) async {
    final strings = KioskStrings(KioskService.instance.activeLocale);
    final otpService = KioskService.instance.otpService;
    final phone = _targetPhone;

    // Guard: Duplicate tap, lockout, or cooldown active
    if (!otpService.canResend || _isLockedOut || _isResending || _isLoading || phone == null) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
      _feedbackMessage = strings.processingRequest;
    });

    final result = await otpService.resendOtp(phone);

    if (!mounted) return;

    setState(() {
      _isResending = false;
      _cooldownSeconds = otpService.cooldownRemainingSeconds;
      _otpValue = ''; // Clear existing OTP input on new resend
      if (result.isSuccess) {
        _feedbackMessage = strings.newOtpSent;
        _errorMessage = null;
      } else {
        _errorMessage = result.message ?? strings.tooManyAttempts;
        _feedbackMessage = null;
      }
    });

    _startCooldownTimer();
  }

  void _onBack(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _onCancel(BuildContext context) {
    KioskService.instance.resetSession();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final KioskLocale activeLocale = KioskService.instance.activeLocale;

    return KioskLocalizations.provider(
      locale: activeLocale,
      child: Builder(
        builder: (context) {
          final strings = KioskLocalizations.of(context);
          final bool isComplete = _otpValue.length == 6;

          // Session Guard Check
          final activePatient = KioskService.instance.identifiedPatient;
          final bool isExistingSession = activePatient != null && activePatient.patientId.isNotEmpty;
          final bool isNewPatientSession = KioskService.instance.activeAadhaarInput.length == 12;
          final bool hasValidSession = isExistingSession || isNewPatientSession;

          return AayusathiKioskScaffold(
            title: strings.verifyMobileNumber,
            subtitle: strings.enterOtpSubtitle,
            activeLocale: activeLocale,
            onBack: () => _onBack(context),
            onCancel: () => _onCancel(context),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1060),
                  child: !hasValidSession
                      ? _buildInvalidSessionCard(context, strings)
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 820;

                            final leftCard = AayusathiGlassCard(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Step Indicator Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandTeal.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.phonelink_lock_rounded,
                                          size: 16,
                                          color: AppColors.brandTeal,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'STEP 2: OTP VERIFICATION',
                                          style: AppTextStyles.tag.copyWith(
                                            color: AppColors.brandTeal,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Phone & Patient Card (Strictly Read-Only)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF4F9F8),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0xFFD6EAE6),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppColors.brandTeal.withValues(alpha: 0.12),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.phone_android_rounded,
                                                size: 20,
                                                color: AppColors.brandTeal,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    strings.otpSentToRegistered,
                                                    style: AppTextStyles.caption.copyWith(
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    _displayMaskedPhone,
                                                    style: const TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 1.2,
                                                      color: AppColors.brandNavy,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (_isExistingPatientFlow && widget.patient != null) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            '${widget.patient!.fullName} (${widget.patient!.patientId})',
                                            style: AppTextStyles.caption.copyWith(
                                              color: AppColors.textMuted,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // 6-digit OTP Box Input
                                  Center(
                                    child: AayusathiOtpInputDisplay(
                                      otpValue: _otpValue,
                                      hasError: _errorMessage != null,
                                      isKeypadDisabled: _isLockedOut || _isLoading || _isResending,
                                    ),
                                  ),

                                  // Error or Success banner
                                  if (_errorMessage != null) ...[
                                    const SizedBox(height: 14),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFDE8E8),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.statusCritical.withValues(alpha: 0.4)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.error_outline_rounded,
                                            size: 20,
                                            color: AppColors.statusCritical,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _errorMessage!,
                                              style: AppTextStyles.caption.copyWith(
                                                color: AppColors.statusCritical,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  if (_feedbackMessage != null && _errorMessage == null) ...[
                                    const SizedBox(height: 14),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDEF7EC),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.statusNormal.withValues(alpha: 0.4)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle_outline_rounded,
                                            size: 20,
                                            color: AppColors.statusNormal,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _feedbackMessage!,
                                              style: AppTextStyles.caption.copyWith(
                                                color: AppColors.statusNormal,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 20),

                                  // Resend OTP Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_cooldownSeconds > 0)
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.timer_outlined,
                                              size: 16,
                                              color: AppColors.textMuted,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              strings.resendOtpIn(_cooldownSeconds),
                                              style: AppTextStyles.caption.copyWith(
                                                color: AppColors.textMuted,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        TextButton.icon(
                                          onPressed: (_isLockedOut || _isLoading || _isResending)
                                              ? null
                                              : () => _handleResend(context),
                                          icon: const Icon(
                                            Icons.refresh_rounded,
                                            size: 18,
                                            color: AppColors.brandTeal,
                                          ),
                                          label: Text(
                                            strings.resendOtp,
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.brandTeal,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Lockout Start Again or Verify Button
                                  if (_isLockedOut)
                                    AayusathiButton(
                                      text: strings.startAgain,
                                      primaryColor: AppColors.statusCritical,
                                      icon: Icons.restart_alt_rounded,
                                      onPressed: () => _onCancel(context),
                                    )
                                  else
                                    AayusathiButton(
                                      text: strings.verifyOtp,
                                      isLoading: _isLoading,
                                      icon: Icons.arrow_forward_rounded,
                                      onPressed: isComplete && !_isLoading && !_isResending
                                          ? () => _handleVerify(context)
                                          : null,
                                    ),
                                ],
                              ),
                            );

                            final keypadSection = AayusathiGlassCard(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                              child: AayusathiNumericKeypad(
                                onDigit: _onDigit,
                                onBackspace: _onBackspace,
                                onClear: _onClear,
                                isEnabled: !_isLockedOut && !_isLoading && !_isResending,
                              ),
                            );

                            if (isWide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: leftCard,
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 5,
                                    child: keypadSection,
                                  ),
                                ],
                              );
                            } else {
                              return Column(
                                children: [
                                  leftCard,
                                  const SizedBox(height: 20),
                                  keypadSection,
                                ],
                              );
                            }
                          },
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInvalidSessionCard(BuildContext context, dynamic strings) {
    return AayusathiGlassCard(
      padding: const EdgeInsets.all(36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.statusCritical.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.lock_person_rounded,
              color: AppColors.statusCritical,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            strings.invalidSessionError,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.brandNavy,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          AayusathiButton(
            text: strings.startAgain,
            primaryColor: AppColors.brandTeal,
            icon: Icons.home_rounded,
            onPressed: () => _onCancel(context),
            width: 240,
          ),
        ],
      ),
    );
  }
}

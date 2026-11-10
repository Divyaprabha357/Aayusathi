import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../../core/localization/kiosk_localizations.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/patient_identity.dart';
import '../services/kiosk_service.dart';
import '../widgets/aayusathi_button.dart';
import '../widgets/aayusathi_glass_card.dart';
import '../widgets/aayusathi_kiosk_scaffold.dart';
import '../widgets/aayusathi_numeric_keypad.dart';
import '../widgets/aayusathi_secondary_button.dart';

/// Touch-first 10-digit Mobile Number Registration Screen for New Patients.
/// The mobile number is manually entered by the patient and is strictly not fetched
/// or prefilled from the Aadhaar record. Validating 10 digits enables OTP dispatch.
class MobileNumberInputScreen extends StatefulWidget {
  final PatientIdentity patient;

  const MobileNumberInputScreen({
    super.key,
    required this.patient,
  });

  @override
  State<MobileNumberInputScreen> createState() => _MobileNumberInputScreenState();
}

class _MobileNumberInputScreenState extends State<MobileNumberInputScreen> {
  String _digits = '';
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _digits = KioskService.instance.activeMobileInput;
  }

  void _onDigit(String digit) {
    if (_digits.length < 10) {
      setState(() {
        _digits += digit;
        _errorMessage = null;
      });
      KioskService.instance.setActiveMobileInput(_digits);
    }
  }

  void _onBackspace() {
    if (_digits.isNotEmpty) {
      setState(() {
        _digits = _digits.substring(0, _digits.length - 1);
        _errorMessage = null;
      });
      KioskService.instance.setActiveMobileInput(_digits);
    }
  }

  void _onClear() {
    if (_digits.isNotEmpty) {
      setState(() {
        _digits = '';
        _errorMessage = null;
      });
      KioskService.instance.setActiveMobileInput('');
    }
  }

  Future<void> _handleSendOtp(BuildContext context) async {
    final strings = KioskLocalizations.of(context);
    final navigator = Navigator.of(context);

    if (_digits.length != 10 || !RegExp(r'^\d{10}$').hasMatch(_digits)) {
      setState(() {
        _errorMessage = strings.invalidMobileNumberError;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final phone = _digits;
    final maskedPhone = '+91 ••••• •${phone.substring(6)}';

    // Store in session
    KioskService.instance.setActiveMobileInput(phone);
    KioskService.instance.setActiveAadhaarOtpData(
      phone: phone,
      maskedPhone: maskedPhone,
    );

    // Send OTP via OtpService abstraction
    await KioskService.instance.otpService.sendOtp(phone);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    navigator.pushNamed(
      AppRoutes.otpVerification,
      arguments: <String, dynamic>{
        'phoneNumber': phone,
        'maskedPhone': maskedPhone,
        'patient': widget.patient,
        'aadhaarNumber': widget.patient.aadhaarNumber,
      },
    );
  }

  void _onBack(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _onCancel(BuildContext context) {
    KioskService.instance.resetSession();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  String _formatPhoneDisplay(String raw) {
    if (raw.isEmpty) return '';
    if (raw.length <= 5) return raw;
    return '${raw.substring(0, 5)}  ${raw.substring(5)}';
  }

  @override
  Widget build(BuildContext context) {
    final KioskLocale activeLocale = KioskService.instance.activeLocale;

    return KioskLocalizations.provider(
      locale: activeLocale,
      child: Builder(
        builder: (context) {
          final strings = KioskLocalizations.of(context);
          final bool isComplete = _digits.length == 10;

          return AayusathiKioskScaffold(
            title: strings.enterMobileNumberTitle,
            subtitle: strings.enterMobileNumberSubtitle,
            activeLocale: activeLocale,
            onBack: () => _onBack(context),
            onCancel: () => _onCancel(context),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1060),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 800;

                          final inputSection = AayusathiGlassCard(
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
                                        Icons.phone_android_rounded,
                                        size: 16,
                                        color: AppColors.brandTeal,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'STEP 2: MOBILE REGISTRATION',
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

                                // Large Styled Touch-First Mobile Input
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      strings.mobileNumber,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: _errorMessage != null
                                            ? AppColors.statusCritical
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    Container(
                                      height: 64,
                                      padding: const EdgeInsets.symmetric(horizontal: 18),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: _errorMessage != null
                                              ? AppColors.statusCritical
                                              : AppColors.brandTeal,
                                          width: 2.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.brandTeal.withValues(alpha: 0.15),
                                            blurRadius: 14,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.phone_outlined,
                                            color: AppColors.brandTeal,
                                            size: 26,
                                          ),
                                          const SizedBox(width: 12),

                                          // Fixed Indian Country Code Prefix
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.brandTeal.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              '+91',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 20,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1.0,
                                                color: AppColors.brandTeal,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),

                                          // Numeric Digits or Placeholder
                                          Expanded(
                                            child: Text(
                                              _digits.isEmpty ? 'XXXXX XXXXX' : _formatPhoneDisplay(_digits),
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 22,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 2.5,
                                                color: _digits.isEmpty
                                                    ? AppColors.textMuted
                                                    : AppColors.brandNavy,
                                              ),
                                            ),
                                          ),

                                          // Digits Counter Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isComplete
                                                  ? AppColors.brandTeal.withValues(alpha: 0.12)
                                                  : const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '${_digits.length} / 10',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: isComplete
                                                    ? AppColors.brandTeal
                                                    : AppColors.textMuted,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    if (_errorMessage != null) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.error_outline_rounded,
                                            color: AppColors.statusCritical,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
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
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Information Notice
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4F9F8),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFD6EAE6),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.info_outline_rounded,
                                        size: 20,
                                        color: AppColors.brandTeal,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          strings.mobileRegistrationNotice,
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textSecondary,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );

                          final keypadSection = AayusathiGlassCard(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            child: AayusathiNumericKeypad(
                              onDigit: _onDigit,
                              onBackspace: _onBackspace,
                              onClear: _onClear,
                              isEnabled: !_isLoading,
                            ),
                          );

                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 6, child: inputSection),
                                const SizedBox(width: 28),
                                Expanded(flex: 5, child: keypadSection),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                inputSection,
                                const SizedBox(height: 20),
                                keypadSection,
                              ],
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 36),

                      // Navigation Action Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AayusathiSecondaryButton(
                            text: strings.back,
                            icon: Icons.arrow_back_rounded,
                            onPressed: () => _onBack(context),
                            width: 190,
                          ),
                          const SizedBox(width: 24),
                          AayusathiButton(
                            text: strings.sendOtp,
                            icon: Icons.arrow_forward_rounded,
                            isLoading: _isLoading,
                            onPressed: isComplete ? () => _handleSendOtp(context) : null,
                            width: 240,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

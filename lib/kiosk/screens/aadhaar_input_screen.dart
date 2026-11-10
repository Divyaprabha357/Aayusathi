import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../../core/localization/kiosk_localizations.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/kiosk_session.dart';
import '../services/aadhaar_service.dart';
import '../services/kiosk_service.dart';
import '../widgets/aayusathi_button.dart';
import '../widgets/aayusathi_glass_card.dart';
import '../widgets/aayusathi_input.dart';
import '../widgets/aayusathi_kiosk_scaffold.dart';
import '../widgets/aayusathi_numeric_keypad.dart';
import '../widgets/aayusathi_secondary_button.dart';

/// Phase 5: New Patient Aadhaar Input Screen.
/// Provides a 100% touch-first 12-digit Aadhaar entry via on-screen numeric keypad.
/// Validates length and calls MockAadhaarService to retrieve identity records.
class AadhaarInputScreen extends StatefulWidget {
  const AadhaarInputScreen({super.key});

  @override
  State<AadhaarInputScreen> createState() => _AadhaarInputScreenState();
}

class _AadhaarInputScreenState extends State<AadhaarInputScreen> {
  String _digits = '';
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Preserve any existing Aadhaar digits from the current session
    _digits = KioskService.instance.activeAadhaarInput;
  }

  void _onDigit(String digit) {
    if (_digits.length < 12) {
      setState(() {
        _digits += digit;
        _errorMessage = null;
      });
      KioskService.instance.setAadhaarInput(_digits);
    }
  }

  void _onBackspace() {
    if (_digits.isNotEmpty) {
      setState(() {
        _digits = _digits.substring(0, _digits.length - 1);
        _errorMessage = null;
      });
      KioskService.instance.setAadhaarInput(_digits);
    }
  }

  void _onClear() {
    if (_digits.isNotEmpty) {
      setState(() {
        _digits = '';
        _errorMessage = null;
      });
      KioskService.instance.setAadhaarInput('');
    }
  }

  Future<void> _handleVerifyAadhaar() async {
    final strings = KioskLocalizations.of(context);
    final navigator = Navigator.of(context);

    if (_digits.length != 12) {
      setState(() {
        _errorMessage = strings.invalidAadhaarError;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final AadhaarService service = KioskService.instance.aadhaarService;

    // 1. Immediate Duplicate Aadhaar Check
    final isRegistered = await service.isAadhaarRegistered(_digits);
    if (!mounted) return;

    if (isRegistered) {
      setState(() {
        _isLoading = false;
      });
      _showAlreadyRegisteredDialog();
      return;
    }

    // 2. Fetch demographic Aadhaar data (strictly zero phone)
    final result = await service.verifyAadhaar(_digits);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.isAlreadyRegistered) {
      _showAlreadyRegisteredDialog();
      return;
    }

    if (result.isSuccess && result.patient != null) {
      // Preserve Aadhaar input and verified demographic data in session state
      KioskService.instance.setAadhaarInput(_digits);
      KioskService.instance.setTemporaryAadhaarData(result.patient!);

      navigator.pushNamed(
        AppRoutes.patientDetailsConfirmation,
        arguments: result.patient!,
      );
    } else {
      setState(() {
        _errorMessage = strings.aadhaarNotFound;
      });
    }
  }

  void _showAlreadyRegisteredDialog() {
    if (!mounted) return;
    final strings = KioskLocalizations.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: AayusathiGlassCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brandOrange.withValues(alpha: 0.12),
                  ),
                  child: const Icon(
                    Icons.person_pin_rounded,
                    color: AppColors.brandOrange,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  strings.patientAlreadyRegisteredTitle,
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.brandNavy,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  strings.aadhaarAlreadyLinkedMessage,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  strings.useExistingPatientPrompt,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                AayusathiButton(
                  text: strings.goToExistingPatient,
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    KioskService.instance.setUserType(UserType.existingPatient);
                    Navigator.of(context).pushReplacementNamed(AppRoutes.existingPatient);
                  },
                  width: double.infinity,
                ),
                const SizedBox(height: 12),
                AayusathiSecondaryButton(
                  text: strings.backToNewUser,
                  icon: Icons.arrow_back_rounded,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                  width: double.infinity,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onBack(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _onCancel(BuildContext context) {
    KioskService.instance.resetSession();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  String _formatAadhaarDisplay(String raw) {
    if (raw.isEmpty) return '';
    final buffer = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write('  ');
      buffer.write(raw[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final KioskLocale activeLocale = KioskService.instance.activeLocale;

    return KioskLocalizations.provider(
      locale: activeLocale,
      child: Builder(
        builder: (context) {
          final strings = KioskLocalizations.of(context);
          final bool isComplete = _digits.length == 12;

          return AayusathiKioskScaffold(
            title: strings.newPatientRegTitle,
            subtitle: strings.enterAadhaarSubtitle,
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
                                        Icons.verified_user_rounded,
                                        size: 16,
                                        color: AppColors.brandTeal,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'STEP 1: AADHAAR VERIFICATION',
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

                                // Large Aadhaar Input Field
                                AayusathiInput(
                                  label: strings.aadhaarNumber,
                                  value: _formatAadhaarDisplay(_digits),
                                  placeholder: strings.aadhaarPlaceholder,
                                  errorText: _errorMessage,
                                  prefixIcon: Icons.fingerprint_rounded,
                                  isFocused: true,
                                  suffix: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isComplete
                                          ? AppColors.brandTeal.withValues(alpha: 0.12)
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${_digits.length} / 12',
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
                                ),
                                const SizedBox(height: 20),

                                // Hospital Privacy & Identity Notice
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
                                        Icons.shield_outlined,
                                        size: 20,
                                        color: AppColors.brandTeal,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          strings.readOnlyNotice,
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
                            text: strings.continueText,
                            icon: Icons.arrow_forward_rounded,
                            isLoading: _isLoading,
                            onPressed: isComplete ? _handleVerifyAadhaar : null,
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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../localization/doctor_localizations.dart';
import '../services/doctor_session_service.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import '../../kiosk/widgets/aayusathi_ambient_ecg.dart';
import '../widgets/doctor_buttons.dart';
import '../widgets/doctor_card.dart';
import '../widgets/doctor_desktop_scaffold.dart';
import '../widgets/doctor_header.dart';

/// Doctor OTP Verification Screen (Phase D2).
/// Desktop-optimized clinical workstation verification with 6-digit numeric input,
/// masked destination privacy, resend cooldown, and clean healthcare aesthetics.
class DoctorOtpScreen extends StatefulWidget {
  final VoidCallback? onVerified;
  final VoidCallback? onBack;

  const DoctorOtpScreen({
    super.key,
    this.onVerified,
    this.onBack,
  });

  @override
  State<DoctorOtpScreen> createState() => _DoctorOtpScreenState();
}

class _DoctorOtpScreenState extends State<DoctorOtpScreen> {
  static const int _otpLength = 6;
  static const int _initialCooldownSeconds = 30;

  final List<TextEditingController> _digitControllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _digitFocusNodes =
      List.generate(_otpLength, (_) => FocusNode());

  String? _errorMessage;
  String? _infoNotice;
  bool _isLoading = false;
  bool _isSuccess = false;

  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  Timer? _transitionTimer;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _otpLength; i++) {
      final index = i;
      _digitFocusNodes[i].onKeyEvent = (node, event) => _onDigitKeyEvent(index, event);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _digitFocusNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _transitionTimer?.cancel();
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final f in _digitFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownSeconds = _initialCooldownSeconds;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds > 0) {
        setState(() => _cooldownSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _clearOtpBoxes() {
    for (final c in _digitControllers) {
      c.clear();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _digitFocusNodes[0].requestFocus();
      }
    });
  }

  String get _currentOtp =>
      _digitControllers.map((controller) => controller.text.trim()).join();

  void _onDigitChanged(int index, String value) {
    if (value.isEmpty) return;

    setState(() {
      _errorMessage = null;
      _infoNotice = null;
    });

    if (value.length > 1) {
      // Handle paste of multiple characters
      final numericChars = value.replaceAll(RegExp(r'\D'), '');
      if (numericChars.isNotEmpty) {
        for (int i = 0; i < _otpLength && i < numericChars.length; i++) {
          _digitControllers[i].text = numericChars[i];
        }
        final nextFocusIndex = numericChars.length < _otpLength
            ? numericChars.length
            : _otpLength - 1;
        _digitFocusNodes[nextFocusIndex].requestFocus();
        return;
      }
    }

    if (value.isNotEmpty) {
      if (index < _otpLength - 1) {
        _digitFocusNodes[index + 1].requestFocus();
      } else {
        _digitFocusNodes[index].unfocus();
      }
    }
  }

  KeyEventResult _onDigitKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_digitControllers[index].text.isEmpty && index > 0) {
          _digitControllers[index - 1].clear();
          _digitFocusNodes[index - 1].requestFocus();
          return KeyEventResult.handled;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        _handleVerifyOtp();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  Future<void> _handleVerifyOtp() async {
    final strings = DoctorLocalizations.of(context);
    final otp = _currentOtp;

    if (otp.length != _otpLength || int.tryParse(otp) == null) {
      setState(() {
        _errorMessage = strings.invalidOtpFormatError;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoNotice = null;
    });

    final result = await DoctorSessionService.instance.verifyOtp(otp);

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });

      if (widget.onVerified != null) {
        widget.onVerified!();
      } else {
        _transitionTimer = Timer(const Duration(milliseconds: 350), () {
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed(AppRoutes.doctorDashboard);
        });
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result.errorMessage ?? strings.invalidOtp;
      });
      _clearOtpBoxes();
    }
  }

  Future<void> _handleResendOtp() async {
    if (_cooldownSeconds > 0) return;

    final strings = DoctorLocalizations.of(context);
    final success = await DoctorSessionService.instance.resendOtp();

    if (!mounted) return;
    if (success) {
      _startCooldownTimer();
      _clearOtpBoxes();
      setState(() {
        _infoNotice = strings.otpResentNotice;
        _errorMessage = null;
      });
    }
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.doctorLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.of(context);
    final maskedPhone =
        DoctorSessionService.instance.maskedPhoneNumber ?? '******4321';

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              _handleBack();
              return null;
            },
          ),
        },
        child: DoctorDesktopScaffold(
          header: DoctorHeader(
            title: strings.otpVerificationTitle,
            subtitle: strings.hospitalWorkstation,
            onBack: _handleBack,
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: DoctorColors.background,
            ),
            child: Stack(
              children: [
                // 1. Ambient ECG Trace Background
                const AayusathiAmbientEcg(isLightMode: true),

                // 2. Centered OTP Panel
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DoctorTheme.space24,
                      vertical: DoctorTheme.space32,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: DoctorCard(
                        padding: const EdgeInsets.all(DoctorTheme.space32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Official Brand Logo & Tagline
                            Center(
                              child: Column(
                                children: [
                                  Image.asset(
                                    'assets/images/aayusathi_logo.png',
                                    height: 48,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: DoctorTheme.space6),
                                  Text(
                                    AppConstants.appTagline,
                                    style: DoctorTheme.caption.copyWith(
                                      color: DoctorColors.brandTeal,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: DoctorTheme.space24),

                            // Heading
                            Text(
                              strings.otpVerificationTitle,
                              textAlign: TextAlign.center,
                              style: DoctorTheme.headline1.copyWith(
                                color: DoctorColors.brandNavy,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: DoctorTheme.space8),

                            // Subtitle
                            Text(
                              strings.otpVerificationSubtitle,
                              textAlign: TextAlign.center,
                              style: DoctorTheme.subtitle.copyWith(
                                color: DoctorColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: DoctorTheme.space20),

                            // Masked Phone Privacy Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: DoctorTheme.space16,
                                vertical: DoctorTheme.space12,
                              ),
                              decoration: BoxDecoration(
                                color: DoctorColors.backgroundSecondary,
                                borderRadius:
                                    BorderRadius.circular(DoctorTheme.radius12),
                                border: Border.all(color: DoctorColors.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.shield_outlined,
                                    color: DoctorColors.brandTeal,
                                    size: 20,
                                  ),
                                  const SizedBox(width: DoctorTheme.space10),
                                  Flexible(
                                    child: Text(
                                      '${strings.otpSentTo} $maskedPhone',
                                      style: DoctorTheme.bodyBold.copyWith(
                                        color: DoctorColors.brandNavy,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: DoctorTheme.space24),

                            // Inline Error Banner
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(DoctorTheme.space12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius:
                                      BorderRadius.circular(DoctorTheme.radius8),
                                  border: Border.all(color: const Color(0xFFFCA5A5)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: Color(0xFFDC2626),
                                      size: 20,
                                    ),
                                    const SizedBox(width: DoctorTheme.space10),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: DoctorTheme.bodyRegular.copyWith(
                                          color: const Color(0xFFB91C1C),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: DoctorTheme.space16),
                            ],

                            // Inline Info / Resent Banner
                            if (_infoNotice != null) ...[
                              Container(
                                padding: const EdgeInsets.all(DoctorTheme.space12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius:
                                      BorderRadius.circular(DoctorTheme.radius8),
                                  border: Border.all(color: const Color(0xFFBAE6FD)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline_rounded,
                                      color: DoctorColors.brandTeal,
                                      size: 20,
                                    ),
                                    const SizedBox(width: DoctorTheme.space10),
                                    Expanded(
                                      child: Text(
                                        _infoNotice!,
                                        style: DoctorTheme.bodyRegular.copyWith(
                                          color: DoctorColors.brandNavy,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: DoctorTheme.space16),
                            ],

                            // Success State Banner
                            if (_isSuccess) ...[
                              Container(
                                padding: const EdgeInsets.all(DoctorTheme.space16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius:
                                      BorderRadius.circular(DoctorTheme.radius12),
                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF059669),
                                      size: 24,
                                    ),
                                    const SizedBox(width: DoctorTheme.space12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            strings.authSuccessTitle,
                                            style: DoctorTheme.bodyBold.copyWith(
                                              color: const Color(0xFF065F46),
                                            ),
                                          ),
                                          Text(
                                            strings.authSuccessSubtitle,
                                            style: DoctorTheme.bodyMuted.copyWith(
                                              color: const Color(0xFF047857),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: DoctorTheme.space16),
                            ],

                            // 6-Digit OTP Boxes
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(_otpLength, (index) {
                                return _buildOtpBox(index);
                              }),
                            ),
                            const SizedBox(height: DoctorTheme.space24),

                            // Primary Action: VERIFY OTP
                            DoctorPrimaryButton(
                              label: strings.verifyOtpButton,
                              icon: Icons.verified_user_outlined,
                              width: double.infinity,
                              isLoading: _isLoading,
                              onPressed: _isLoading || _isSuccess
                                  ? null
                                  : _handleVerifyOtp,
                            ),
                            const SizedBox(height: DoctorTheme.space12),

                            // Resend OTP Action
                            Center(
                              child: TextButton.icon(
                                onPressed:
                                    _cooldownSeconds > 0 || _isLoading || _isSuccess
                                        ? null
                                        : _handleResendOtp,
                                icon: Icon(
                                  Icons.refresh_rounded,
                                  size: 18,
                                  color: _cooldownSeconds > 0
                                      ? DoctorColors.textMuted
                                      : DoctorColors.brandTeal,
                                ),
                                label: Text(
                                  _cooldownSeconds > 0
                                      ? strings.resendOtpCooldown(_cooldownSeconds)
                                      : strings.resendOtpButton,
                                  style: DoctorTheme.buttonText.copyWith(
                                    fontSize: 13,
                                    color: _cooldownSeconds > 0
                                        ? DoctorColors.textMuted
                                        : DoctorColors.brandTeal,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: DoctorTheme.space8),

                            // Secondary Action: BACK to Login
                            DoctorSecondaryButton(
                              label: strings.back,
                              icon: Icons.arrow_back_rounded,
                              width: double.infinity,
                              onPressed: _isLoading || _isSuccess ? null : _handleBack,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    final controller = _digitControllers[index];
    final focusNode = _digitFocusNodes[index];
    final hasFocus = focusNode.hasFocus;
    final isFilled = controller.text.isNotEmpty;

    return Container(
      width: 54,
      height: 62,
      decoration: BoxDecoration(
        color: hasFocus ? Colors.white : DoctorColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(DoctorTheme.radius12),
        border: Border.all(
          color: hasFocus
              ? DoctorColors.borderFocus
              : (isFilled ? DoctorColors.brandTeal : DoctorColors.border),
          width: hasFocus ? 2.0 : 1.5,
        ),
        boxShadow: hasFocus ? DoctorTheme.shadowSubtle : null,
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: DoctorTheme.headline1.copyWith(
          color: DoctorColors.brandNavy,
          fontWeight: FontWeight.w700,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          counterText: '',
        ),
        onChanged: (val) => _onDigitChanged(index, val),
      ),
    );
  }
}

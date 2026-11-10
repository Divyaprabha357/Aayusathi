import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../localization/doctor_localizations.dart';
import '../services/doctor_dev_workspace_controller.dart';
import '../services/doctor_session_service.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import '../../kiosk/widgets/aayusathi_ambient_ecg.dart';
import '../widgets/doctor_buttons.dart';
import '../widgets/doctor_card.dart';
import '../widgets/doctor_desktop_scaffold.dart';
import '../widgets/doctor_header.dart';

/// Doctor Login Screen (Phase D2).
/// Desktop-first clinical sign-in interface requiring Doctor Unique Code and password.
/// Integrates with DoctorSessionService for flow orchestration.
class DoctorLoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final VoidCallback? onBack;

  const DoctorLoginScreen({
    super.key,
    this.onLoginSuccess,
    this.onBack,
  });

  @override
  State<DoctorLoginScreen> createState() => _DoctorLoginScreenState();
}

class _DoctorLoginScreenState extends State<DoctorLoginScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _codeFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _codeFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final strings = DoctorLocalizations.of(context);
    final code = _codeController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _errorMessage = null;
    });

    if (code.isEmpty) {
      setState(() {
        _errorMessage = strings.emptyDoctorCodeError;
      });
      _codeFocusNode.requestFocus();
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _errorMessage = strings.emptyPasswordError;
      });
      _passwordFocusNode.requestFocus();
      return;
    }

    setState(() => _isLoading = true);

    final result = await DoctorSessionService.instance.validateCredentials(
      doctorCode: code,
      password: password,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.doctorOtp);
      }
    } else {
      setState(() {
        _errorMessage = result.errorMessage ?? strings.invalidLoginDetails;
      });
    }
  }

  void _handleBack() {
    DoctorSessionService.instance.resetSession();
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.doctorStandby);
    }
  }

  void _showForgotPasswordDialog() {
    final strings = DoctorLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DoctorTheme.radius16),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.contact_support_outlined,
              color: DoctorColors.brandTeal,
              size: 24,
            ),
            const SizedBox(width: DoctorTheme.space12),
            Expanded(
              child: Text(
                strings.forgotPasswordTitle,
                style: DoctorTheme.headline2,
              ),
            ),
          ],
        ),
        content: Text(
          strings.forgotPasswordNotice,
          style: DoctorTheme.bodyRegular.copyWith(
            color: DoctorColors.textSecondary,
          ),
        ),
        actions: [
          DoctorPrimaryButton(
            label: strings.close,
            height: 40,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.of(context);

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
            title: 'Doctor Authentication',
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
                // 1. Ambient Medical ECG Trace Background
                const AayusathiAmbientEcg(isLightMode: true),

                // 2. Centered Login Card
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
                              strings.doctorLoginTitle,
                              textAlign: TextAlign.center,
                              style: DoctorTheme.headline1.copyWith(
                                color: DoctorColors.brandNavy,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: DoctorTheme.space8),

                            // Subtitle
                            Text(
                              strings.doctorLoginSubtitle,
                              textAlign: TextAlign.center,
                              style: DoctorTheme.subtitle.copyWith(
                                color: DoctorColors.textSecondary,
                                height: 1.4,
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

                            // Field 1: Doctor Unique Code
                            Text(
                              strings.doctorUniqueCode,
                              style: DoctorTheme.bodyBold.copyWith(
                                color: DoctorColors.brandNavy,
                              ),
                            ),
                            const SizedBox(height: DoctorTheme.space8),
                            TextField(
                              controller: _codeController,
                              focusNode: _codeFocusNode,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) {
                                _passwordFocusNode.requestFocus();
                              },
                              style: DoctorTheme.bodyRegular.copyWith(
                                color: DoctorColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: strings.doctorUniqueCodeHint,
                                hintStyle: DoctorTheme.bodyMuted,
                                prefixIcon: const Icon(
                                  Icons.badge_outlined,
                                  color: DoctorColors.brandTeal,
                                  size: 20,
                                ),
                                filled: true,
                                fillColor: DoctorColors.backgroundSecondary,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(DoctorTheme.radius12),
                                  borderSide:
                                      const BorderSide(color: DoctorColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(DoctorTheme.radius12),
                                  borderSide:
                                      const BorderSide(color: DoctorColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(DoctorTheme.radius12),
                                  borderSide: const BorderSide(
                                    color: DoctorColors.borderFocus,
                                    width: 1.8,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: DoctorTheme.space16,
                                  vertical: DoctorTheme.space12,
                                ),
                              ),
                            ),
                            const SizedBox(height: DoctorTheme.space16),

                            // Field 2: Password
                            Text(
                              strings.password,
                              style: DoctorTheme.bodyBold.copyWith(
                                color: DoctorColors.brandNavy,
                              ),
                            ),
                            const SizedBox(height: DoctorTheme.space8),
                            TextField(
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _handleLogin(),
                              style: DoctorTheme.bodyRegular.copyWith(
                                color: DoctorColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: strings.passwordHint,
                                hintStyle: DoctorTheme.bodyMuted,
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: DoctorColors.brandTeal,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: DoctorColors.textMuted,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: DoctorColors.backgroundSecondary,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(DoctorTheme.radius12),
                                  borderSide:
                                      const BorderSide(color: DoctorColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(DoctorTheme.radius12),
                                  borderSide:
                                      const BorderSide(color: DoctorColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(DoctorTheme.radius12),
                                  borderSide: const BorderSide(
                                    color: DoctorColors.borderFocus,
                                    width: 1.8,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: DoctorTheme.space16,
                                  vertical: DoctorTheme.space12,
                                ),
                              ),
                            ),
                            const SizedBox(height: DoctorTheme.space8),

                            // Forgot Password Link
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _showForgotPasswordDialog,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  strings.forgotPassword,
                                  style: DoctorTheme.caption.copyWith(
                                    color: DoctorColors.brandTeal,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: DoctorTheme.space24),

                            // Primary Action: LOGIN
                            DoctorPrimaryButton(
                              label: strings.loginButton,
                              icon: Icons.login_rounded,
                              width: double.infinity,
                              isLoading: _isLoading,
                              onPressed: _isLoading ? null : _handleLogin,
                            ),
                            const SizedBox(height: DoctorTheme.space12),

                            // Secondary Action: BACK to Standby
                            DoctorSecondaryButton(
                              label: strings.back,
                              icon: Icons.arrow_back_rounded,
                              width: double.infinity,
                              onPressed: _isLoading ? null : _handleBack,
                            ),
                            const SizedBox(height: DoctorTheme.space20),

                            // Security Assurance Notice
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.lock_rounded,
                                  size: 14,
                                  color: DoctorColors.textMuted,
                                ),
                                const SizedBox(width: DoctorTheme.space6),
                                Flexible(
                                  child: Text(
                                    strings.secureSessionNotice,
                                    textAlign: TextAlign.center,
                                    style: DoctorTheme.caption.copyWith(
                                      color: DoctorColors.textMuted,
                                      fontSize: 10.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                            // Development Workspace Access (Only shown when DOCTOR_DEV_MODE=true)
                            if (DoctorDevWorkspaceController.isDevModeEnabled) ...[
                              const SizedBox(height: DoctorTheme.space20),
                              Row(
                                children: [
                                  const Expanded(child: Divider(color: DoctorColors.border)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: DoctorTheme.space12),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.code_rounded, size: 13, color: DoctorColors.brandOrange),
                                        const SizedBox(width: 4),
                                        Text(
                                          'DEVELOPMENT ACCESS ONLY',
                                          style: DoctorTheme.caption.copyWith(
                                            color: DoctorColors.brandOrange,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Expanded(child: Divider(color: DoctorColors.border)),
                                ],
                              ),
                              const SizedBox(height: DoctorTheme.space12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(DoctorTheme.space12),
                                decoration: BoxDecoration(
                                  color: DoctorColors.brandOrange.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(DoctorTheme.radius12),
                                  border: Border.all(
                                    color: DoctorColors.brandOrange.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Simulate Verified Workstation (Dr. Rajesh Sharma • DOC-101)',
                                      style: DoctorTheme.caption.copyWith(
                                        fontSize: 11,
                                        color: DoctorColors.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: DoctorTheme.space10),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 42,
                                      child: OutlinedButton.icon(
                                        key: const Key('enter_demo_workspace_button'),
                                        icon: const Icon(Icons.developer_mode_rounded, size: 16),
                                        label: const Text(
                                          'ENTER DEMO WORKSPACE',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: DoctorColors.brandOrange,
                                          side: const BorderSide(color: DoctorColors.brandOrange, width: 1.2),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                                          ),
                                        ),
                                        onPressed: () => DoctorDevWorkspaceController.enterDemoWorkspace(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
}

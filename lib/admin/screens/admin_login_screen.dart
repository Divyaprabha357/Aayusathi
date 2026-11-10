import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../kiosk/widgets/aayusathi_ambient_ecg.dart';
import '../localization/admin_localizations.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_buttons.dart';
import '../widgets/admin_card.dart';
import '../widgets/admin_desktop_scaffold.dart';
import '../widgets/admin_header.dart';

import '../services/admin_auth_service.dart';

/// Admin Login Screen (Phase A2 Real Authentication).
/// Desktop-first administrative sign-in interface with real credential validation.
class AdminLoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final VoidCallback? onBack;

  const AdminLoginScreen({
    super.key,
    this.onLoginSuccess,
    this.onBack,
  });

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _usernameFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    final strings = AdminLocalizations.of(context);
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _errorMessage = null;
    });

    if (username.isEmpty) {
      setState(() {
        _errorMessage = strings.emptyUsernameError;
      });
      _usernameFocusNode.requestFocus();
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _errorMessage = strings.emptyPasswordError;
      });
      _passwordFocusNode.requestFocus();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await AdminAuthService.instance.login(
      username: username,
      password: password,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess) {
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.adminDashboard);
      }
    } else {
      setState(() {
        _errorMessage = strings.invalidCredentialsError;
      });
    }
  }

  void _handleBack() {
    if (_isLoading) return;
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.adminStandby);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AdminLocalizations.of(context);

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
        child: AdminDesktopScaffold(
          header: AdminHeader(
            title: strings.adminLoginTitle,
            subtitle: strings.hospitalWorkstation,
            onBack: _handleBack,
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: AdminColors.background,
            ),
            child: Stack(
              children: [
                // 1. Ambient Medical ECG Trace Background
                const AayusathiAmbientEcg(isLightMode: true),

                // 2. Centered Login Card
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AdminTheme.space24,
                      vertical: AdminTheme.space32,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: AdminCard(
                        padding: const EdgeInsets.all(AdminTheme.space32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Official Brand Logo & Tagline
                            Center(
                              child: Column(
                                children: [
                                  Image.asset(
                                    AppAssets.logo,
                                    height: 48,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: AdminTheme.space6),
                                  Text(
                                    AppConstants.appTagline,
                                    style: AdminTheme.caption.copyWith(
                                      color: AdminColors.brandTeal,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AdminTheme.space24),

                            // Heading
                            Text(
                              strings.adminLoginTitle,
                              textAlign: TextAlign.center,
                              style: AdminTheme.headline1.copyWith(
                                color: AdminColors.brandNavy,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: AdminTheme.space8),

                            // Subtitle
                            Text(
                              strings.adminLoginSubtitle,
                              textAlign: TextAlign.center,
                              style: AdminTheme.subtitle.copyWith(
                                color: AdminColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: AdminTheme.space24),

                            // Inline Error Banner
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(AdminTheme.space12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius:
                                      BorderRadius.circular(AdminTheme.radius8),
                                  border: Border.all(color: const Color(0xFFFCA5A5)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: Color(0xFFDC2626),
                                      size: 20,
                                    ),
                                    const SizedBox(width: AdminTheme.space10),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: AdminTheme.bodyRegular.copyWith(
                                          color: const Color(0xFFB91C1C),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AdminTheme.space16),
                            ],

                            // Field 1: Username
                            Text(
                              strings.username,
                              style: AdminTheme.bodyBold.copyWith(
                                color: AdminColors.brandNavy,
                              ),
                            ),
                            const SizedBox(height: AdminTheme.space8),
                            TextField(
                              controller: _usernameController,
                              focusNode: _usernameFocusNode,
                              textInputAction: TextInputAction.next,
                              enabled: !_isLoading,
                              onSubmitted: (_) {
                                _passwordFocusNode.requestFocus();
                              },
                              style: AdminTheme.bodyRegular.copyWith(
                                color: AdminColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: strings.usernameHint,
                                hintStyle: AdminTheme.bodyMuted,
                                prefixIcon: const Icon(
                                  Icons.person_outline_rounded,
                                  color: AdminColors.brandTeal,
                                  size: 20,
                                ),
                                filled: true,
                                fillColor: AdminColors.backgroundSecondary,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AdminTheme.radius12),
                                  borderSide:
                                      const BorderSide(color: AdminColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AdminTheme.radius12),
                                  borderSide:
                                      const BorderSide(color: AdminColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AdminTheme.radius12),
                                  borderSide: const BorderSide(
                                    color: AdminColors.borderFocus,
                                    width: 1.8,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AdminTheme.space16,
                                  vertical: AdminTheme.space12,
                                ),
                              ),
                            ),
                            const SizedBox(height: AdminTheme.space16),

                            // Field 2: Password
                            Text(
                              strings.password,
                              style: AdminTheme.bodyBold.copyWith(
                                color: AdminColors.brandNavy,
                              ),
                            ),
                            const SizedBox(height: AdminTheme.space8),
                            TextField(
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              obscureText: _obscurePassword,
                              enabled: !_isLoading,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _handleLogin(),
                              style: AdminTheme.bodyRegular.copyWith(
                                color: AdminColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: strings.passwordHint,
                                hintStyle: AdminTheme.bodyMuted,
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: AdminColors.brandTeal,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AdminColors.textMuted,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: AdminColors.backgroundSecondary,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AdminTheme.radius12),
                                  borderSide:
                                      const BorderSide(color: AdminColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AdminTheme.radius12),
                                  borderSide:
                                      const BorderSide(color: AdminColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AdminTheme.radius12),
                                  borderSide: const BorderSide(
                                    color: AdminColors.borderFocus,
                                    width: 1.8,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AdminTheme.space16,
                                  vertical: AdminTheme.space12,
                                ),
                              ),
                            ),
                            const SizedBox(height: AdminTheme.space24),

                            // Primary Action: LOGIN (Phase A2 Real Auth)
                            AdminPrimaryButton(
                              label: _isLoading
                                  ? strings.authenticating
                                  : strings.loginButton,
                              icon: Icons.login_rounded,
                              isLoading: _isLoading,
                              width: double.infinity,
                              onPressed: _isLoading ? null : _handleLogin,
                            ),
                            const SizedBox(height: AdminTheme.space12),

                            // Secondary Action: BACK to Standby
                            AdminSecondaryButton(
                              label: strings.back,
                              icon: Icons.arrow_back_rounded,
                              width: double.infinity,
                              onPressed: _isLoading ? null : _handleBack,
                            ),
                            const SizedBox(height: AdminTheme.space20),

                            // Security Assurance Notice
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.security_rounded,
                                  size: 14,
                                  color: AdminColors.textMuted,
                                ),
                                const SizedBox(width: AdminTheme.space6),
                                Flexible(
                                  child: Text(
                                    strings.secureSessionNotice,
                                    textAlign: TextAlign.center,
                                    style: AdminTheme.caption.copyWith(
                                      color: AdminColors.textMuted,
                                      fontSize: 10.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
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
}

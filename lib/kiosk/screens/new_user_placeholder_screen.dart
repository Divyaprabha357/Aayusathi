import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../../core/localization/kiosk_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../services/kiosk_service.dart';
import '../widgets/aayusathi_button.dart';
import '../widgets/aayusathi_glass_card.dart';
import '../widgets/aayusathi_kiosk_scaffold.dart';
import '../widgets/aayusathi_secondary_button.dart';

/// Polished milestone placeholder screen for New User (Phase 5 Aadhaar onboarding destination).
/// Retains the established dark premium theme and active session language.
class NewUserPlaceholderScreen extends StatelessWidget {
  const NewUserPlaceholderScreen({super.key});

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

          return AayusathiKioskScaffold(
            title: strings.newPatientRegTitle,
            subtitle: strings.identityVerificationNext,
            activeLocale: activeLocale,
            onBack: () => _onBack(context),
            onCancel: () => _onCancel(context),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Central Feature Card
                      AayusathiGlassCard(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Healthcare / Biometric Registration Icon
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: AppColors.brandTeal.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.brandTeal.withValues(alpha: 0.35),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.fingerprint_rounded,
                                color: AppColors.primaryLight,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Main Title
                            Text(
                              strings.newPatientRegTitle,
                              style: AppTextStyles.headlineLarge.copyWith(
                                color: Colors.white,
                                fontSize: 32,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),

                            // Explanatory Subtitle
                            Text(
                              strings.identityVerificationNext,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 28),

                            // Integration Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.brandTeal.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.brandTeal.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.lock_clock_rounded,
                                    size: 16,
                                    color: AppColors.primaryLight,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'PHASE 5 AADHAAR VERIFICATION DESTINATION',
                                    style: AppTextStyles.tag.copyWith(
                                      color: AppColors.primaryLight,
                                      letterSpacing: 1.0,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),

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
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Aadhaar verification workflow scheduled for Phase 5.'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
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

import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../../core/localization/kiosk_localizations.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../services/kiosk_service.dart';
import '../widgets/aayusathi_button.dart';
import '../widgets/aayusathi_glass_card.dart';
import '../widgets/aayusathi_kiosk_scaffold.dart';
import '../widgets/aayusathi_secondary_button.dart';

/// Phase 3: Dedicated Full-Screen Language Selection Interface for AAYUSATHI Kiosk.
/// Displayed immediately after Standby touch and before New/Existing User routing.
class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  late KioskLocale _currentLocale;

  @override
  void initState() {
    super.initState();
    _currentLocale = KioskService.instance.activeLocale;
  }

  void _onLanguageSelected(KioskLocale locale) {
    setState(() {
      _currentLocale = locale;
    });
    // Binds language to the active kiosk session
    KioskService.instance.setLocale(locale);
  }

  void _onContinue() {
    Navigator.of(context).pushNamed(AppRoutes.userType);
  }

  void _onBackToStandby() {
    // Reset session and return to Standby
    KioskService.instance.resetSession();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return KioskLocalizations.provider(
      locale: _currentLocale,
      child: Builder(
        builder: (context) {
          final strings = KioskLocalizations.of(context);

          return AayusathiKioskScaffold(
            title: strings.selectLanguage,
            subtitle: strings.chooseLanguageSubtitle,
            activeLocale: _currentLocale,
            onBack: _onBackToStandby,
            onCancel: _onBackToStandby,
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1050),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Instructions badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandTeal.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppColors.brandTeal.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.touch_app_outlined,
                              size: 20,
                              color: AppColors.brandTeal,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Touch your preferred language to select',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.brandTeal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),

                      // 3 Large Touchscreen Language Cards
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isHorizontal = constraints.maxWidth > 780;

                          final cards = KioskLocale.values.map((locale) {
                            final isSelected = _currentLocale == locale;

                            return _buildLanguageCard(
                              locale: locale,
                              isSelected: isSelected,
                              onTap: () => _onLanguageSelected(locale),
                            );
                          }).toList();

                          if (isHorizontal) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: cards
                                  .map((card) => Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: card,
                                        ),
                                      ))
                                  .toList(),
                            );
                          } else {
                            return Column(
                              children: cards
                                  .map((card) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        child: card,
                                      ))
                                  .toList(),
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 48),

                      // Navigation Action Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AayusathiSecondaryButton(
                            text: strings.cancel,
                            icon: Icons.arrow_back_rounded,
                            onPressed: _onBackToStandby,
                            width: 190,
                          ),
                          const SizedBox(width: 24),
                          AayusathiButton(
                            text: strings.continueText,
                            icon: Icons.arrow_forward_rounded,
                            onPressed: _onContinue,
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

  /// Individual touch-friendly Language Selection Card.
  Widget _buildLanguageCard({
    required KioskLocale locale,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AayusathiGlassCard(
      isSelected: isSelected,
      onTap: onTap,
      padding: const EdgeInsets.all(28),
      height: 220,
      child: Stack(
        children: [
          // Active checkmark indicator in top right
          Align(
            alignment: Alignment.topRight,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.brandTeal : const Color(0xFFE2E8F0),
              ),
              child: Icon(
                Icons.check_rounded,
                color: isSelected ? Colors.white : Colors.transparent,
                size: 20,
              ),
            ),
          ),

          // Card Content: Icon, Native Script, Subtitle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon container
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.brandTeal.withValues(alpha: 0.15)
                      : const Color(0xFFF1F7F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.translate_rounded,
                  color: isSelected ? AppColors.brandTeal : AppColors.textSecondary,
                  size: 28,
                ),
              ),
              const Spacer(),

              // Native Script Language Name (English / हिन्दी / मराठी)
              Text(
                locale.nativeName,
                style: AppTextStyles.headlineLarge.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.brandTeal : AppColors.brandNavy,
                ),
              ),
              const SizedBox(height: 4),

              // Latin Subtitle (English / Hindi / Marathi)
              Text(
                locale.subtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 16,
                  color: isSelected
                      ? AppColors.brandTeal.withValues(alpha: 0.9)
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

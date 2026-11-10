import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../../core/localization/kiosk_localizations.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/kiosk_session.dart';
import '../services/kiosk_service.dart';
import '../widgets/aayusathi_glass_card.dart';
import '../widgets/aayusathi_kiosk_scaffold.dart';
import '../widgets/aayusathi_secondary_button.dart';

/// Production User Type Selection Screen (Phase 4).
/// Allows patient to choose between "NEW USER" and "EXISTING PATIENT".
/// Retains the established dark premium theme and active session language.
class UserTypeScreen extends StatefulWidget {
  const UserTypeScreen({super.key});

  @override
  State<UserTypeScreen> createState() => _UserTypeScreenState();
}

class _UserTypeScreenState extends State<UserTypeScreen> {
  String? _selectedOption;

  void _onBack(BuildContext context) {
    // Back navigation preserves session language
    Navigator.of(context).pop();
  }

  void _onCancel(BuildContext context) {
    // Full cancel/reset: clears session, resets language to default English, returns to Standby
    KioskService.instance.resetSession();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _onSelectNewUser(BuildContext context) {
    setState(() => _selectedOption = 'new_user');
    KioskService.instance.setUserType(UserType.newUser);
    Navigator.of(context).pushNamed(AppRoutes.newUser);
  }

  void _onSelectExistingPatient(BuildContext context) {
    setState(() => _selectedOption = 'existing_patient');
    KioskService.instance.setUserType(UserType.existingPatient);
    Navigator.of(context).pushNamed(AppRoutes.existingPatient);
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
            title: strings.howCanWeHelp,
            subtitle: strings.selectRegistrationType,
            activeLocale: activeLocale,
            onBack: () => _onBack(context),
            onCancel: () => _onCancel(context),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Active Language Status Indicator
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
                              Icons.translate_rounded,
                              size: 18,
                              color: AppColors.brandTeal,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Language: ${activeLocale.nativeName} (${activeLocale.code.toUpperCase()})',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.brandTeal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Two Large Touchscreen Option Cards
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isHorizontal = constraints.maxWidth > 720;

                          // Card 1: NEW USER
                          final newCard = _buildOptionCard(
                            title: strings.newUserOptionTitle,
                            subtitle: strings.newUserOptionSubtitle,
                            icon: Icons.person_add_rounded,
                            accentColor: AppColors.brandTeal,
                            isSelected: _selectedOption == 'new_user',
                            onTap: () => _onSelectNewUser(context),
                            badgeText: 'FIRST TIME VISIT',
                          );

                          // Card 2: EXISTING PATIENT
                          final existingCard = _buildOptionCard(
                            title: strings.existingPatientOptionTitle,
                            subtitle: strings.existingPatientOptionSubtitle,
                            icon: Icons.badge_rounded,
                            accentColor: AppColors.brandOrange,
                            isSelected: _selectedOption == 'existing_patient',
                            onTap: () => _onSelectExistingPatient(context),
                            badgeText: 'REGISTERED PATIENT',
                          );

                          if (isHorizontal) {
                            return Row(
                              children: [
                                Expanded(child: newCard),
                                const SizedBox(width: 28),
                                Expanded(child: existingCard),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                newCard,
                                const SizedBox(height: 20),
                                existingCard,
                              ],
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 48),

                      // Action Bar: Back and Cancel (Full Session Reset)
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
                          AayusathiSecondaryButton(
                            text: strings.cancel,
                            icon: Icons.close_rounded,
                            color: AppColors.statusCritical,
                            onPressed: () => _onCancel(context),
                            width: 190,
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

  /// Individual touch-friendly User Type Option Card.
  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isSelected,
    required VoidCallback onTap,
    required String badgeText,
  }) {
    return AayusathiGlassCard(
      isSelected: isSelected,
      accentColor: accentColor,
      onTap: onTap,
      padding: const EdgeInsets.all(32),
      height: 270,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Icon Container and Category Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 34,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: AppTextStyles.tag.copyWith(
                    color: accentColor,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),

          // Middle: Title and Subtitle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTextStyles.headlineLarge.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandNavy,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),

          // Bottom Action Cue Row
          Row(
            children: [
              Text(
                'TAP TO SELECT',
                style: AppTextStyles.caption.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_rounded,
                color: accentColor,
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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

/// Phase 5: Registration Success Screen displaying the generated AAYUSATHI Patient ID.
/// Features high-contrast typography, medical teal card highlight, and success indicators.
class RegistrationSuccessScreen extends StatelessWidget {
  final PatientIdentity patient;

  const RegistrationSuccessScreen({
    super.key,
    required this.patient,
  });

  void _onContinue(BuildContext context) {
    // Navigate to Phase 6 OTP Verification
    Navigator.of(context).pushNamed(
      AppRoutes.otpVerification,
      arguments: patient,
    );
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
            title: strings.registrationSuccessful,
            subtitle: strings.registrationSuccessSubtitle,
            activeLocale: activeLocale,
            onCancel: () => _onCancel(context),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 780),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Success Card
                      AayusathiGlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Success checkmark badge with radiant medical green aura
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.statusNormal.withValues(alpha: 0.14),
                                border: Border.all(
                                  color: AppColors.statusNormal.withValues(alpha: 0.4),
                                  width: 2.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 48,
                                color: AppColors.statusNormal,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Patient Name
                            Text(
                              patient.fullName,
                              style: AppTextStyles.headlineLarge.copyWith(
                                color: AppColors.brandNavy,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${patient.gender} • ${patient.dobWithAge}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 28),

                            // Patient ID Highlight Container
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                              decoration: BoxDecoration(
                                color: AppColors.brandTeal.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppColors.brandTeal.withValues(alpha: 0.4),
                                  width: 2.0,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    strings.yourPatientId.toUpperCase(),
                                    style: AppTextStyles.tag.copyWith(
                                      color: AppColors.brandTeal,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    patient.patientId,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 40,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 3.5,
                                      color: AppColors.brandNavy,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // "Please keep this ID safe" notice
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 18,
                                  color: AppColors.brandOrange,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    strings.pleaseKeepIdSafe,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.brandNavy,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Continue CTA
                      AayusathiButton(
                        text: strings.continueText,
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () => _onContinue(context),
                        width: 280,
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

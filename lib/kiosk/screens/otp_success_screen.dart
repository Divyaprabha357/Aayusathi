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

/// Phase 6: OTP Verification Success Screen.
/// Confirms the patient's registered mobile number is verified,
/// displaying patient identity summary and verified security badge.
class OtpSuccessScreen extends StatelessWidget {
  final PatientIdentity patient;

  const OtpSuccessScreen({
    super.key,
    required this.patient,
  });

  void _onContinue(BuildContext context) {
    // Navigate to Sensor Instructions Screen before Vital Collection
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.sensorInstructions,
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
            title: strings.mobileNumberVerified,
            subtitle: strings.identitySuccessfullyVerified,
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
                      AayusathiGlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Verified Success Aura & Icon
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.statusNormal.withValues(alpha: 0.14),
                                border: Border.all(
                                  color: AppColors.statusNormal.withValues(alpha: 0.4),
                                  width: 2.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.check_circle_rounded,
                                size: 52,
                                color: AppColors.statusNormal,
                              ),
                            ),
                            const SizedBox(height: 20),

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
                            const SizedBox(height: 24),

                            // Patient ID and Phone Details Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                              decoration: BoxDecoration(
                                color: AppColors.brandTeal.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.brandTeal.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        strings.patientIdLabel,
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textMuted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.brandNavy.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          patient.patientId,
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.brandNavy,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24, color: Color(0xFFD6EAE6)),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        strings.phoneNumber,
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textMuted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            patient.maskedPhone,
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.brandNavy,
                                              letterSpacing: 0.6,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDEF7EC),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFF84E1BC)),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.verified_rounded,
                                                  size: 13,
                                                  color: AppColors.statusNormal,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'VERIFIED',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.statusNormal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Continue Button
                            AayusathiButton(
                              text: strings.continueButton,
                              icon: Icons.arrow_forward_rounded,
                              onPressed: () => _onContinue(context),
                            ),
                          ],
                        ),
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

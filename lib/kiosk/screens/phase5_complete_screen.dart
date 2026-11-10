import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../../core/localization/kiosk_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/patient_identity.dart';
import '../services/kiosk_service.dart';
import '../widgets/aayusathi_button.dart';
import '../widgets/aayusathi_glass_card.dart';
import '../widgets/aayusathi_kiosk_scaffold.dart';

/// Phase 5 Milestone Completion Screen.
/// Displays confirmed identity, showing Phase 5 goals are fully met.
class Phase5CompleteScreen extends StatelessWidget {
  final PatientIdentity patient;

  const Phase5CompleteScreen({
    super.key,
    required this.patient,
  });

  void _onFinishSession(BuildContext context) {
    // Session completion / reset to Standby
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
            title: strings.phase5MilestoneTitle,
            subtitle: strings.phase5MilestoneSubtitle,
            activeLocale: activeLocale,
            onCancel: () => _onFinishSession(context),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AayusathiGlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Healthcare Verified Badge
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.brandTeal.withValues(alpha: 0.12),
                                border: Border.all(
                                  color: AppColors.brandTeal,
                                  width: 2.0,
                                ),
                              ),
                              child: const Icon(
                                Icons.health_and_safety_rounded,
                                color: AppColors.brandTeal,
                                size: 42,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Identification Headline
                            Text(
                              strings.phase5MilestoneTitle,
                              style: AppTextStyles.headlineLarge.copyWith(
                                color: AppColors.brandNavy,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),

                            Text(
                              'Patient: ${patient.fullName} (${patient.patientId})',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            // Phase Milestone Details
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F9F8),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFD6EAE6),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.statusNormal,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Phase 5 Patient Identification Completed',
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            color: AppColors.brandNavy,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Patient identification and verification records are ready. Phase 6 will handle Vitals & Hardware sensors.',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Finish Session Button
                      AayusathiButton(
                        text: 'COMPLETE CHECK-IN',
                        icon: Icons.check_rounded,
                        onPressed: () => _onFinishSession(context),
                        width: 260,
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

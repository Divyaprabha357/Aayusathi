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

/// Phase 7 Normal Milestone: Domain Selection Placeholder Screen (Phase 8).
/// Reached when patient's vitals are successfully validated within healthy normal bounds.
class DomainSelectionPlaceholderScreen extends StatelessWidget {
  final PatientIdentity patient;

  const DomainSelectionPlaceholderScreen({
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
    final reading = KioskService.instance.currentVitalReading;

    return KioskLocalizations.provider(
      locale: activeLocale,
      child: Builder(
        builder: (context) {
          final strings = KioskLocalizations.of(context);

          return AayusathiKioskScaffold(
            title: strings.domainSelectionTitle,
            subtitle: strings.domainSelectionSubtitle,
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
                        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 34),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Healthcare & Normal Vitals Verified Aura
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
                                Icons.verified_user_rounded,
                                color: AppColors.statusNormal,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 20),

                            Text(
                              strings.vitalsNormalTitle,
                              style: AppTextStyles.headlineLarge.copyWith(
                                color: AppColors.brandNavy,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),

                            Text(
                              strings.vitalsNormalSubtitle,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            // Patient & Normal Readings Snapshot
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
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
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        patient.fullName,
                                        style: AppTextStyles.bodyLarge.copyWith(
                                          color: AppColors.brandNavy,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        patient.patientId,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.brandTeal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (reading != null) ...[
                                    const Divider(height: 24, color: Color(0xFFD6EAE6)),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildVitalSummaryItem('SpO₂', '${reading.spo2Display} %'),
                                        _buildVitalSummaryItem('HR', '${reading.heartRateDisplay} BPM'),
                                        _buildVitalSummaryItem('Temp', '${reading.temperatureDisplay} °C'),
                                      ],
                                    ),
                                  ],
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

  Widget _buildVitalSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.brandNavy,
          ),
        ),
      ],
    );
  }
}

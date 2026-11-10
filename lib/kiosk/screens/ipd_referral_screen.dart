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

/// Phase 7: IPD Referral Screen for patients with abnormal vital measurements.
/// Communicates clinical priority with Care Orange alert accents, explains the safety requirement,
/// blocks outpatient OPD domain progression, and enables controlled session completion back to Standby.
class IpdReferralScreen extends StatelessWidget {
  final PatientIdentity patient;

  const IpdReferralScreen({
    super.key,
    required this.patient,
  });

  void _onFinishSession(BuildContext context) {
    // Privacy wipe and return to Standby
    KioskService.instance.resetSession();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final KioskLocale activeLocale = KioskService.instance.activeLocale;
    final validationResult = KioskService.instance.vitalValidationResult;
    final reading = validationResult?.reading ?? KioskService.instance.currentVitalReading;

    return KioskLocalizations.provider(
      locale: activeLocale,
      child: Builder(
        builder: (context) {
          final strings = KioskLocalizations.of(context);

          return AayusathiKioskScaffold(
            title: strings.ipdReferralTitle,
            subtitle: strings.ipdReferralMessage,
            activeLocale: activeLocale,
            onCancel: () => _onFinishSession(context),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AayusathiGlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Care Alert Badge (Care Orange)
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.brandOrange.withValues(alpha: 0.12),
                                border: Border.all(
                                  color: AppColors.brandOrange.withValues(alpha: 0.35),
                                  width: 2.2,
                                ),
                              ),
                              child: const Icon(
                                Icons.medical_services_rounded,
                                color: AppColors.brandOrange,
                                size: 44,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Main Headline
                            Text(
                              strings.ipdReferralMessage,
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

                            // Clinical Notice Card
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8F1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFFFD8B2),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppColors.brandOrange,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Immediate Inpatient Evaluation Recommended',
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            color: AppColors.brandNavy,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          strings.ipdReferralNotice,
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textSecondary,
                                            height: 1.45,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Vitals Recorded Snapshot
                            if (reading != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Recorded Vitals Snapshot',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 16,
                                      runSpacing: 8,
                                      children: [
                                        _buildSnapshotItem(
                                          'SpO₂',
                                          '${reading.spo2Display} %',
                                        ),
                                        _buildSnapshotItem(
                                          'HR',
                                          '${reading.heartRateDisplay} BPM',
                                        ),
                                        _buildSnapshotItem(
                                          'Temp',
                                          '${reading.temperatureDisplay} °C',
                                        ),
                                      ],
                                    ),
                                    if (validationResult != null &&
                                        validationResult.abnormalReasons.isNotEmpty) ...[
                                      const Divider(height: 20, color: Color(0xFFE2E8F0)),
                                      ...validationResult.abnormalReasons.map(
                                        (reason) => Padding(
                                          padding: const EdgeInsets.only(bottom: 4),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.circle,
                                                size: 6,
                                                color: AppColors.statusCritical,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  reason,
                                                  style: AppTextStyles.caption.copyWith(
                                                    color: AppColors.statusCritical,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Finish Session Button
                      AayusathiButton(
                        text: strings.finishSession,
                        primaryColor: AppColors.brandTeal,
                        icon: Icons.check_circle_outline_rounded,
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

  Widget _buildSnapshotItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.brandNavy,
        ),
      ),
    );
  }
}

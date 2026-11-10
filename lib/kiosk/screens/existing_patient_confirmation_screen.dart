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
import '../widgets/aayusathi_secondary_button.dart';

/// Phase 5: Existing Patient Identity Confirmation Screen.
/// Displays read-only identity record retrieved from Patient ID lookup.
/// Confirming identity completes Phase 5 patient identification.
class ExistingPatientConfirmationScreen extends StatelessWidget {
  final PatientIdentity patient;

  const ExistingPatientConfirmationScreen({
    super.key,
    required this.patient,
  });

  void _onConfirm(BuildContext context) {
    // Save identified patient into session state
    KioskService.instance.setIdentifiedPatient(patient);

    // Navigate to Phase 6 OTP Verification
    Navigator.of(context).pushNamed(
      AppRoutes.otpVerification,
      arguments: patient,
    );
  }

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
            title: strings.confirmIdentity,
            subtitle: strings.confirmDetailsSubtitle,
            activeLocale: activeLocale,
            onBack: () => _onBack(context),
            onCancel: () => _onCancel(context),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.brandTeal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.brandTeal.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 18,
                              color: AppColors.brandTeal,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'REGISTERED PATIENT • ${patient.patientId}',
                              style: AppTextStyles.tag.copyWith(
                                color: AppColors.brandTeal,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Read-Only Identity Card Grid
                      AayusathiGlassCard(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header row with Read-Only indicator
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  strings.fullName,
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.lock_outline_rounded,
                                        size: 14,
                                        color: AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'READ-ONLY RECORD',
                                        style: AppTextStyles.caption.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textMuted,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              patient.fullName,
                              style: AppTextStyles.headlineLarge.copyWith(
                                color: AppColors.brandNavy,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Divider(color: Color(0xFFE5F0EE), height: 1),
                            const SizedBox(height: 20),

                            // Detail Fields (2-Column Responsive Layout)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth > 580;

                                final fId = _buildDetailItem(
                                  label: strings.patientId,
                                  value: patient.patientId,
                                  icon: Icons.badge_outlined,
                                );
                                final fDob = _buildDetailItem(
                                  label: strings.dob,
                                  value: patient.dobWithAge,
                                  icon: Icons.calendar_today_rounded,
                                );
                                final fGender = _buildDetailItem(
                                  label: strings.gender,
                                  value: patient.gender,
                                  icon: Icons.person_outline_rounded,
                                );
                                final fPhone = _buildDetailItem(
                                  label: strings.mobileNumber,
                                  value: patient.phone,
                                  icon: Icons.phone_outlined,
                                );

                                if (isWide) {
                                  return Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(child: fId),
                                          const SizedBox(width: 24),
                                          Expanded(child: fDob),
                                        ],
                                      ),
                                      const SizedBox(height: 18),
                                      Row(
                                        children: [
                                          Expanded(child: fGender),
                                          const SizedBox(width: 24),
                                          Expanded(child: fPhone),
                                        ],
                                      ),
                                    ],
                                  );
                                } else {
                                  return Column(
                                    children: [
                                      fId,
                                      const SizedBox(height: 14),
                                      fDob,
                                      const SizedBox(height: 14),
                                      fGender,
                                      const SizedBox(height: 14),
                                      fPhone,
                                    ],
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Navigation Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AayusathiSecondaryButton(
                            text: strings.goBack,
                            icon: Icons.arrow_back_rounded,
                            onPressed: () => _onBack(context),
                            width: 190,
                          ),
                          const SizedBox(width: 24),
                          AayusathiButton(
                            text: strings.confirmIdentity,
                            icon: Icons.check_circle_outline_rounded,
                            onPressed: () => _onConfirm(context),
                            width: 260,
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

  Widget _buildDetailItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FCFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2EFEA),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.brandTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.brandTeal,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandNavy,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

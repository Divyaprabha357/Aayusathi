import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../../core/localization/kiosk_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/aayusathi_button.dart';
import '../widgets/aayusathi_kiosk_scaffold.dart';

/// Temporary milestone verification screen demonstrating successful touch from Standby.
/// Prepared for Phase 3 (Language Selection).
class StandbySuccessScreen extends StatelessWidget {
  final KioskLocale activeLocale;
  final VoidCallback onReturn;

  const StandbySuccessScreen({
    super.key,
    required this.activeLocale,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    return KioskLocalizations.provider(
      locale: activeLocale,
      child: AayusathiKioskScaffold(
        title: 'Standby Verification',
        subtitle: 'Kiosk Terminal Ready for Phase 3',
        activeLocale: activeLocale,
        onBack: onReturn,
        onCancel: onReturn,
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(40),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.brandTeal.withValues(alpha: 0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandTeal.withValues(alpha: 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.statusNormal.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.statusNormal,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Standby Interaction Successful',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.brandNavy,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'The patient touch was registered with smooth transition feedback. Active language: ${activeLocale.nativeName} (${activeLocale.code.toUpperCase()}).',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                AayusathiButton(
                  text: 'RETURN TO STANDBY',
                  icon: Icons.replay_rounded,
                  onPressed: onReturn,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

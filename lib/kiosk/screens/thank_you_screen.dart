import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../../core/localization/kiosk_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../services/kiosk_service.dart';
import '../widgets/aayusathi_button.dart';
import '../widgets/aayusathi_glass_card.dart';
import '../widgets/aayusathi_kiosk_scaffold.dart';

/// Dedicated Thank You Screen (Phase 8 Final Correction).
/// Displayed when an existing patient declines an alternative doctor.
/// Displays "Thank you, visit again." in active language (EN/HI/MR).
/// Strictly excludes doctor names, doctor IDs, cabins, queue numbers, and patient details.
/// Automatically resets session and language to English before returning to Standby.
class ThankYouScreen extends StatefulWidget {
  final int autoResetSeconds;

  const ThankYouScreen({
    super.key,
    this.autoResetSeconds = 4,
  });

  @override
  State<ThankYouScreen> createState() => _ThankYouScreenState();
}

class _ThankYouScreenState extends State<ThankYouScreen> {
  Timer? _countdownTimer;
  late int _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.autoResetSeconds;
    _startAutoResetTimer();
  }

  void _startAutoResetTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_remainingSeconds <= 1) {
        timer.cancel();
        _onCompleteAndReset();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  /// Complete session wipe, English language restoration, and return to Standby.
  void _onCompleteAndReset() {
    _countdownTimer?.cancel();
    KioskService.instance.resetSession();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
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
            title: strings.thankYouTitle,
            subtitle: strings.thankYouReturningToStandby,
            activeLocale: activeLocale,
            onCancel: _onCompleteAndReset,
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 780),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AayusathiGlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 44),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Medical Smile / Heart Icon
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.brandTeal.withValues(alpha: 0.12),
                                border: Border.all(
                                  color: AppColors.brandTeal.withValues(alpha: 0.35),
                                  width: 2.0,
                                ),
                              ),
                              child: const Icon(
                                Icons.volunteer_activism_rounded,
                                size: 48,
                                color: AppColors.brandTeal,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Prominent "Thank you, visit again."
                            Text(
                              strings.thankYouVisitAgain,
                              style: AppTextStyles.headlineLarge.copyWith(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppColors.brandNavy,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),

                            // Subtitle message
                            Text(
                              strings.thankYouReturningToStandby,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontSize: 17,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 28),

                            const Divider(color: Color(0xFFD6EAE6), height: 1.5),
                            const SizedBox(height: 20),

                            // Auto-returning countdown indicator
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  size: 18,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  strings.autoReturningIn(_remainingSeconds),
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 14,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Manual CTA to return immediately
                      AayusathiButton(
                        text: strings.back,
                        icon: Icons.home_rounded,
                        onPressed: _onCompleteAndReset,
                        width: 240,
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

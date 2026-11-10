import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../../core/localization/kiosk_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/appointment_request.dart';
import '../services/kiosk_service.dart';
import '../widgets/aayusathi_button.dart';
import '../widgets/aayusathi_glass_card.dart';
import '../widgets/aayusathi_kiosk_scaffold.dart';

/// Phase 8: Premium Queue Confirmation Screen.
/// Displays the sequential queue ticket and waiting instructions with strict privacy enforcement.
/// Automatically wipes the kiosk session and returns to Standby after a controlled countdown.
class QueueConfirmationScreen extends StatefulWidget {
  final AppointmentRequest appointment;
  final int autoResetSeconds;

  const QueueConfirmationScreen({
    super.key,
    required this.appointment,
    this.autoResetSeconds = 10,
  });

  @override
  State<QueueConfirmationScreen> createState() => _QueueConfirmationScreenState();
}

class _QueueConfirmationScreenState extends State<QueueConfirmationScreen> {
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

  /// Complete session wipe and return to Standby.
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
          final isPending = widget.appointment.status == AppointmentStatus.pending;

          return AayusathiKioskScaffold(
            title: strings.appointmentRequestedTitle,
            subtitle: strings.pleaseWaitForTurn,
            activeLocale: activeLocale,
            onCancel: _onCompleteAndReset,
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Main Ticket Card
                      AayusathiGlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 36),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Verified Ticket Icon
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.brandTeal.withValues(alpha: 0.12),
                                border: Border.all(
                                  color: AppColors.brandTeal.withValues(alpha: 0.35),
                                  width: 2.0,
                                ),
                              ),
                              child: const Icon(
                                Icons.confirmation_number_rounded,
                                size: 40,
                                color: AppColors.brandTeal,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Badge Header: APPOINTMENT REQUESTED
                            Text(
                              strings.appointmentRequestedTitle,
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.8,
                                color: AppColors.brandTeal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 18),

                            // Dominant Queue Number Display Box (e.g. A-27)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F9F8),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.brandTeal.withValues(alpha: 0.45),
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.brandTeal.withValues(alpha: 0.12),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    strings.yourQueueNumber,
                                    style: AppTextStyles.caption.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    widget.appointment.queueNumber,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 68,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.brandNavy,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Primary Instruction: "Please wait for your turn."
                            Text(
                              strings.pleaseWaitForTurn,
                              style: AppTextStyles.headlineLarge.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandNavy,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),

                            // Secondary Note: "Your request has been successfully registered."
                            Text(
                              strings.requestRegisteredSuccess,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            // Part 9: Pending Queue / All Doctors Busy notice
                            if (isPending) ...[
                              const SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF8F4),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.brandOrange.withValues(alpha: 0.35),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      color: AppColors.brandOrange,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        strings.allDoctorsBusyNotice,
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.brandNavy,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 22),
                            const Divider(color: Color(0xFFD6EAE6), height: 1.5),
                            const SizedBox(height: 18),

                            // Auto-returning countdown message
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
                      const SizedBox(height: 28),

                      // Manual FINISH SESSION CTA button
                      AayusathiButton(
                        text: strings.finishSession,
                        icon: Icons.check_circle_outline_rounded,
                        onPressed: _onCompleteAndReset,
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

import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/kiosk_card.dart';
import '../widgets/kiosk_header.dart';

/// Primary landing screen for the AAYUSATHI physical Kiosk.
class KioskHomeScreen extends StatelessWidget {
  const KioskHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const KioskHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.defaultPadding * 1.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    // Greeting & Tagline Banner
                    Text(
                      'Welcome to ${AppConstants.appName}',
                      style: AppTextStyles.displayMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please select an option below to begin your health session.',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Touch-Friendly Kiosk Workflow Actions
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 700;
                        final cards = [
                          KioskCard(
                            title: 'Quick Check-In',
                            description:
                                'Scan your patient QR code or enter your ID to begin.',
                            icon: Icons.qr_code_scanner_rounded,
                            accentColor: AppColors.primary,
                            onTap: () {
                              _showPlaceholderNotice(context, 'Quick Check-In');
                            },
                          ),
                          KioskCard(
                            title: 'Vital Signs Check',
                            description:
                                'Measure oxygen saturation, pulse rate, and body temperature.',
                            icon: Icons.monitor_heart_outlined,
                            accentColor: AppColors.secondary,
                            onTap: () {
                              _showPlaceholderNotice(context, 'Vital Signs Check');
                            },
                          ),
                          KioskCard(
                            title: 'Doctor Consultation',
                            description:
                                'Connect with an on-duty medical practitioner via video booth.',
                            icon: Icons.video_call_outlined,
                            accentColor: AppColors.statusInfo,
                            onTap: () {
                              _showPlaceholderNotice(context, 'Doctor Consultation');
                            },
                          ),
                          KioskCard(
                            title: 'Emergency Help',
                            description:
                                'Instantly alert clinic personnel and medical first responders.',
                            icon: Icons.emergency_outlined,
                            accentColor: AppColors.statusCritical,
                            onTap: () {
                              _showPlaceholderNotice(context, 'Emergency Help');
                            },
                          ),
                        ];

                        if (!isWide) {
                          return Column(
                            children: cards
                                .map(
                                  (card) => Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: card,
                                  ),
                                )
                                .toList(),
                          );
                        }

                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: cards[0]),
                                const SizedBox(width: 16),
                                Expanded(child: cards[1]),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: cards[2]),
                                const SizedBox(width: 16),
                                Expanded(child: cards[3]),
                              ],
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 32),
                    // Footer branding
                    Center(
                      child: Text(
                        '${AppConstants.appName} • ${AppConstants.appTagline} • v${AppConstants.appVersion}',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlaceholderNotice(BuildContext context, String moduleName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$moduleName flow ready for feature integration.'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

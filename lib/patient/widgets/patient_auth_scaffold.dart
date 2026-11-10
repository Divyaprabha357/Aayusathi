import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_assets.dart';
import '../localization/patient_localizations.dart';
import '../theme/patient_colors.dart';
import '../theme/patient_spacing.dart';

/// Unified Authentication Scaffold for Patient Login and OTP screens.
///
/// Enforces:
/// - Dark Android status-bar foreground icons on the light background
/// - Strict SafeArea adherence
/// - Standardized top alignment (no arbitrary vertical center drift)
/// - Consistent official AAYUSATHI logo dimensions and position
/// - Cohesive authentication card styling (white surface, subtle border, rounded corners)
class PatientAuthScaffold extends StatelessWidget {
  final Widget cardContent;
  final VoidCallback? onBackTap;
  final String? backTooltip;

  const PatientAuthScaffold({
    super.key,
    required this.cardContent,
    this.onBackTap,
    this.backTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final strings = PatientLocalizations.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: PatientColors.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: PatientSpacing.pageHorizontal,
                vertical: 16.0,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: PatientSpacing.maxAuthCardWidth,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Back Button or uniform spacer
                    SizedBox(
                      height: 44,
                      child: onBackTap != null
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  size: 28,
                                  color: PatientColors.navy,
                                ),
                                tooltip: backTooltip ?? strings.back,
                                onPressed: onBackTap,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 44,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 8),

                    // Official AAYUSATHI Brand Logo
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 80,
                          maxWidth: 240,
                        ),
                        child: Image.asset(
                          AppAssets.logo,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Text(
                                      'AAYU',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: PatientColors.navy,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      'SATHI',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: PatientColors.teal,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  strings.appTagline,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: PatientColors.textMuted,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: PatientSpacing.largeGap),

                    // Authentication Card Container
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 26,
                      ),
                      decoration: BoxDecoration(
                        color: PatientColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: PatientColors.border,
                          width: 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: PatientColors.shadow,
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: cardContent,
                    ),
                    const SizedBox(height: PatientSpacing.bottomSafeSpace),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

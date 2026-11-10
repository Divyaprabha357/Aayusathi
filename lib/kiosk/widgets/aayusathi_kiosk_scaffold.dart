import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../../core/theme/app_colors.dart';
import 'aayusathi_footer.dart';
import 'aayusathi_page_header.dart';

/// Reusable scaffold layout ensuring consistent headers, footers,
/// ambient medical backgrounds, and responsive sizing across all Kiosk steps.
class AayusathiKioskScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final VoidCallback? onBack;
  final VoidCallback? onCancel;
  final KioskLocale? activeLocale;
  final Widget? floatingAction;

  const AayusathiKioskScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.onBack,
    this.onCancel,
    this.activeLocale,
    this.floatingAction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.standbyLightBgCenter,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.2),
            radius: 1.35,
            colors: [
              AppColors.standbyLightBgCenter,
              AppColors.standbyLightBgMid,
              AppColors.standbyLightBgVignette,
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Page Header
              AayusathiPageHeader(
                title: title,
                subtitle: subtitle,
                onBack: onBack,
                activeLocale: activeLocale,
              ),

              // Main Body Content
              Expanded(
                child: body,
              ),

              // Bottom Footer
              AayusathiFooter(
                onCancel: onCancel,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: floatingAction,
    );
  }
}

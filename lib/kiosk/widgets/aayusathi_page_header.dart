import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/kiosk_locale.dart';
import '../../core/localization/kiosk_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_utils.dart';

/// Standardized top navigation and identity header across Kiosk workflow screens.
class AayusathiPageHeader extends StatefulWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final KioskLocale? activeLocale;

  const AayusathiPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.activeLocale,
  });

  @override
  State<AayusathiPageHeader> createState() => _AayusathiPageHeaderState();
}

class _AayusathiPageHeaderState extends State<AayusathiPageHeader> {
  late DateTime _currentTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = KioskLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFD6EAE6), width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandNavy.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Optional Back Button + Branding
          Row(
            children: [
              if (widget.onBack != null) ...[
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: strings.back,
                  color: AppColors.brandNavy,
                  iconSize: 28,
                ),
                const SizedBox(width: 12),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.brandTeal,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.local_hospital_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppConstants.appName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: AppColors.brandNavy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppConstants.appTagline,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.brandOrange,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Center: Screen Title & Subtitle
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.brandNavy,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle!,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Right: Active Language badge & Clock
          Row(
            children: [
              if (widget.activeLocale != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.brandTeal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.brandTeal.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.translate_rounded,
                        size: 16,
                        color: AppColors.brandTeal,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.activeLocale!.nativeName,
                        style: AppTextStyles.tag.copyWith(
                          color: AppColors.brandTeal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
              ],
              // Clock
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F7F6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFD6EAE6),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: AppColors.brandTeal,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppDateUtils.formatTime(_currentTime),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandNavy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

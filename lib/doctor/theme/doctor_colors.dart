import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Semantic colors tailored for the AAYUSATHI Doctor Desktop Interface.
/// Adheres strictly to the AAYUSATHI greenish-white medical design system.
class DoctorColors {
  DoctorColors._();

  // Core Brand Mapping
  static const Color brandNavy = AppColors.brandNavy;
  static const Color brandTeal = AppColors.brandTeal;
  static const Color brandOrange = AppColors.brandOrange;
  static const Color brandGreen = AppColors.brandGreen;

  // Medical Greenish-White Canvas & Surfaces
  static const Color background = Color(0xFFF5F9F9); // Clean pale clinical backdrop
  static const Color backgroundSecondary = Color(0xFFEAF3F2); // Soft mint transition
  static const Color surface = Color(0xFFFFFFFF); // Crisp clean card surface
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF0F6F5); // Very soft tint for headers/rows
  static const Color surfaceHover = Color(0xFFE2F0EE); // Interactive hover tint

  // Healthcare Dialog Palette (AAYUSATHI Standard System)
  static const Color dialogBg = Color(0xFFFFFFFF);
  static const Color pageTint = Color(0xFFF3F8F7);
  static const Color dialogPageTint = Color(0xFFF3F8F7);
  static const Color dialogPrimaryText = Color(0xFF102A43);
  static const Color dialogSecondaryText = Color(0xFF486581);
  static const Color dialogPrimaryTeal = Color(0xFF008C95);
  static const Color dialogDarkTeal = Color(0xFF075E63);
  static const Color dialogBorder = Color(0xFFD6E4E5);
  static const Color dialogWarningText = Color(0xFFB42318);
  static const Color dialogWarningBg = Color(0xFFFEF3F2);
  static const Color dialogWarningBorder = Color(0xFFFECDCA);

  // Medical Standby Lighting
  static const Color standbyBgCenter = Color(0xFFF3F9F8); // Luminous medical teal-tinted white
  static const Color standbyBgMid = Color(0xFFE5F2F0); // Subtle soft pale mint/teal transition
  static const Color standbyBgVignette = Color(0xFFD6EAE6); // Calm edge vignette
  static const Color standbyBacklight = Color(0x66FFFFFF); // Luminous halo
  static const Color standbyAuraCore = Color(0x2E007E8A); // Ambient medical teal aura

  // Typography Colors
  static const Color textPrimary = Color(0xFF0A1E3F); // High-contrast deep navy
  static const Color textSecondary = Color(0xFF4A6572); // Clinical slate grey
  static const Color textMuted = Color(0xFF8A9BA8); // Subdued metadata
  static const Color textLight = Color(0xFFFFFFFF); // Pure white on dark containers
  static const Color textTeal = Color(0xFF007E8A); // Teal accent text

  // Borders & Dividers
  static const Color border = Color(0xFFD9E6E5); // Gentle mint-grey border
  static const Color borderSubtle = Color(0xFFE8F0EF); // Extra soft divider
  static const Color borderFocus = Color(0xFF007E8A); // Focused field/button ring

  // Clinical Status Semantic Colors
  static const Color statusOnline = Color(0xFF10B981); // Emerald online
  static const Color statusOffline = Color(0xFF94A3B8); // Slate offline
  static const Color statusAvailable = Color(0xFF059669); // Green available
  static const Color statusInConsultation = Color(0xFFD97706); // Amber in-consultation
  static const Color statusBusy = Color(0xFFDC2626); // Crimson busy
  static const Color statusNormal = Color(0xFF10B981); // Normal telemetry
  static const Color statusWarning = Color(0xFFF59E0B); // Elevated telemetry
  static const Color statusCritical = Color(0xFFEF4444); // Critical telemetry
}

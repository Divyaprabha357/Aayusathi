import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Semantic color palette for the AAYUSATHI Administrative Desktop Interface (Phase A1).
/// Adheres strictly to the AAYUSATHI greenish-white medical design system.
class AdminColors {
  AdminColors._();

  // Core Brand Mapping
  static const Color brandNavy = AppColors.brandNavy; // Deep Navy (#0A1E3F)
  static const Color brandTeal = AppColors.brandTeal; // Medical Teal (#007E8A)
  static const Color brandOrange = AppColors.brandOrange; // Care Orange (#FF6B35)
  static const Color brandGreen = AppColors.brandGreen; // Wellness Green (#00A86B)

  // Primary & Accent Mappings
  static const Color primary = brandTeal;
  static const Color primaryLight = Color(0xFF33A3AE);
  static const Color primaryDark = Color(0xFF005861);

  // Medical Greenish-White Canvas & Surfaces
  static const Color background = Color(0xFFF5F9F8); // Clean pale clinical backdrop
  static const Color backgroundSecondary = Color(0xFFEAF3F2); // Soft mint transition
  static const Color surface = Color(0xFFFFFFFF); // Crisp clean card surface
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF0F6F5); // Very soft tint for headers/rows
  static const Color surfaceHover = Color(0xFFE2F0EE); // Interactive hover tint

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
  static const Color borderFocus = Color(0xFF007E8A); // Focused field ring

  // Administrative Status & Escalation Semantic Colors
  static const Color statusOnline = Color(0xFF10B981); // Emerald online
  static const Color statusOffline = Color(0xFF94A3B8); // Slate offline
  static const Color statusAvailable = Color(0xFF059669); // Green available
  static const Color statusWarning = Color(0xFFF59E0B); // Amber warning
  static const Color statusEscalated = Color(0xFFFF6B35); // Care orange for escalation alerts
  static const Color statusCritical = Color(0xFFEF4444); // Crimson critical
  static const Color statusNormal = Color(0xFF10B981); // Normal status
  static const Color statusInfo = Color(0xFF3B82F6); // Info blue
}

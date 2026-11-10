import 'package:flutter/material.dart';

/// Centralized color palette for AAYUSATHI, aligned with official brand identity.
class AppColors {
  AppColors._();

  // Official Logo & Brand Primary
  static const Color brandNavy = Color(0xFF0A1E3F); // Deep Navy ("AAYU" & primary structure)
  static const Color brandTeal = Color(0xFF007E8A); // Medical Teal ("SATHI" & health icon)
  static const Color brandOrange = Color(0xFFFF6B35); // Care Orange (accent curve)
  static const Color brandGreen = Color(0xFF00A86B); // Leaf Green (wellness symbol)

  // Primary & Secondary for Theme
  static const Color primary = brandTeal;
  static const Color primaryLight = Color(0xFF33A3AE);
  static const Color primaryDark = Color(0xFF005861);

  static const Color secondary = brandOrange;
  static const Color secondaryLight = Color(0xFFFF8E61);
  static const Color secondaryDark = Color(0xFFD64A15);

  // Standby Light Medical Theme (Isolated strictly to Standby Screen)
  static const Color standbyLightBgCenter = Color(0xFFF3F9F8); // Pale luminous medical teal-tinted white
  static const Color standbyLightBgMid = Color(0xFFE5F2F0); // Subtle soft pale mint/teal transition
  static const Color standbyLightBgVignette = Color(0xFFD6EAE6); // Calm medical pale teal edge vignette
  static const Color standbyLightAuraCore = Color(0x2E007E8A); // Very soft ambient medical glow
  static const Color standbyLightBacklight = Color(0x66FFFFFF); // Soft luminous diffused white backlight behind logo

  // Standby Ambient Background & Illumination (Legacy Dark / Alternate)
  static const Color standbyBgCenter = Color(0xFF144550); // Luminous medical teal core
  static const Color standbyBgMid = Color(0xFF092830); // Ambient teal transition
  static const Color standbyBgVignette = Color(0xFF031317); // Dark perimeter edges
  static const Color standbyAuraCore = Color(0x3D38B2AC); // Soft ambient teal mist
  static const Color standbyBacklight = Color(0x3AE0F2F1); // Luminous soft backlight for logo contrast
  static const Color standbyBgTop = Color(0xFF041419);
  static const Color standbyBgMiddle = Color(0xFF08272F);
  static const Color standbyBgBottom = Color(0xFF061A22);

  // Kiosk App Light Background & Surfaces
  static const Color backgroundLight = Color(0xFFF4F8FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceGlass = Color(0xCCFFFFFF);

  // Kiosk App Dark Surfaces
  static const Color backgroundDark = Color(0xFF07171C);
  static const Color surfaceDark = Color(0xFF0D2228);
  static const Color surfaceDarkGlass = Color(0xCC0D2228);

  // Text Colors
  static const Color textPrimary = Color(0xFF0A1E2F);
  static const Color textSecondary = Color(0xFF5A7184);
  static const Color textLight = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF8FA2B4);

  // Clinical Status
  static const Color statusNormal = Color(0xFF10B981); // Normal vitals / Safe
  static const Color statusWarning = Color(0xFFF59E0B); // Attention needed
  static const Color statusCritical = Color(0xFFEF4444); // Urgent / IPD Warning
  static const Color statusInfo = Color(0xFF3B82F6);

  // Borders & Dividers
  static const Color borderLight = Color(0xFFDCE5EC);
  static const Color borderDark = Color(0xFF1A3842);
  static const Color borderFocus = brandTeal;

  // Controlled Glows
  static const Color glowTeal = Color(0x33007E8A);
  static const Color glowOrange = Color(0x33FF6B35);
  static const Color glowPulse = Color(0x4D00ACC1);
}

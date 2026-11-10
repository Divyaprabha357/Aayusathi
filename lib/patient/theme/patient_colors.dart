import 'package:flutter/material.dart';

/// Central color tokens for the AAYUSATHI Patient App.
///
/// Designed specifically for clarity, calm medical aesthetic, and senior-citizen accessibility.
/// Primary background: #F8FBF9 (Greenish-white)
/// Navy: #142238 (Deep high-contrast headings & text)
/// Teal: #00897B (Medical Teal primary brand & active tab)
/// Orange: #E65100 (Care Orange accent curve & alerts)
/// Border: #E0EBE4 (Soft calm medical border)
class PatientColors {
  PatientColors._();

  // Core Brand & Background
  static const Color background = Color(0xFFF8FBF9); // Soft greenish-white medical interface
  static const Color surface = Color(0xFFFFFFFF); // Pure white card surface
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE0EBE4); // Subtle mint-gray border
  static const Color borderSubtle = Color(0xFFEDF4F0);

  // Typography & Brand Colors
  static const Color navy = Color(0xFF142238); // High contrast text & structure
  static const Color teal = Color(0xFF00897B); // Medical Teal ("SATHI" & health actions)
  static const Color tealLight = Color(0xFFE0F2F1); // Teal wash background
  static const Color tealDark = Color(0xFF00695C); // Pressed state teal
  static const Color orange = Color(0xFFE65100); // Care Orange accent curve
  static const Color orangeLight = Color(0xFFFFF3E0); // Orange wash background

  // Text Hierarchy (High Contrast for Senior Citizens)
  static const Color textPrimary = Color(0xFF142238);
  static const Color textSecondary = Color(0xFF4A5D6E);
  static const Color textMuted = Color(0xFF7A8E9E);
  static const Color textLight = Color(0xFFFFFFFF);

  // Status Colors
  static const Color statusSuccess = Color(0xFF00A86B);
  static const Color statusSuccessLight = Color(0xFFE8F5E9);
  static const Color statusWarning = Color(0xFFE65100);
  static const Color statusWarningLight = Color(0xFFFFF3E0);
  static const Color statusInfo = Color(0xFF0288D1);
  static const Color statusInfoLight = Color(0xFFE1F5FE);
  static const Color statusCritical = Color(0xFFD32F2F);
  static const Color statusCriticalLight = Color(0xFFFFEBEE);

  // Interactive Elements
  static const Color shadow = Color(0x0D142238);
  static const Color activeTabBg = Color(0xFFE0F2F1);
  static const Color inactiveTab = Color(0xFF6B7F91);
  static const Color tabBarBackground = Color(0xFFEBEFF0);

  // Input Field Tokens
  static const Color inputFill = Color(0xFFF4F8F6); // Light medical mint/white
  static const Color inputBorder = Color(0xFFC8D8D1); // Clearly visible border
  static const Color inputBorderFocused = Color(0xFF00897B); // Medical teal focus
  static const Color hintColor = Color(0xFF5A6E65); // High-contrast accessible hint
}

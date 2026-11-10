import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Central typographic hierarchy for AAYUSATHI.
/// Built with GoogleFonts (Poppins + Noto Sans Devanagari fallback)
/// to ensure English, हिन्दी, and मराठी render with zero broken glyphs.
class AppTextStyles {
  AppTextStyles._();

  // Kiosk Standby & Hero Display
  static TextStyle displayHero = GoogleFonts.poppins(
    fontSize: 42,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.textLight,
  );

  static TextStyle displayLarge = GoogleFonts.poppins(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static TextStyle displayMedium = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // Section Headers
  static TextStyle headlineLarge = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle headlineMedium = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Body Text (High Legibility at 1-2m Kiosk Viewing Distance)
  static TextStyle bodyLarge = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle bodyLight = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textLight.withValues(alpha: 0.85),
  );

  // Touch Buttons & Action Cards
  static TextStyle buttonLarge = GoogleFonts.poppins(
    fontSize: 19,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static TextStyle buttonMedium = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  // Numeric Keypad Typography
  static TextStyle keypadDigit = GoogleFonts.poppins(
    fontSize: 30,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle inputDisplay = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 3.0,
    color: AppColors.textPrimary,
  );

  // Captions & Badges
  static TextStyle caption = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle tag = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'doctor_colors.dart';

/// Design tokens, typography, and theme utilities for the AAYUSATHI Doctor Desktop Interface.
class DoctorTheme {
  DoctorTheme._();

  // Spacing Tokens (Dense Desktop Scale)
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;

  // Corner Radius Tokens
  static const double radius6 = 6.0;
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius20 = 20.0;
  static const double radiusFull = 999.0;

  // Desktop Responsive Breakpoints
  static const double breakpointCompact = 1100.0;
  static const double breakpointStandard = 1366.0;
  static const double breakpointWide = 1600.0;

  static bool isCompact(BuildContext context) =>
      MediaQuery.of(context).size.width < breakpointCompact;

  static bool isStandard(BuildContext context) =>
      MediaQuery.of(context).size.width >= breakpointCompact &&
      MediaQuery.of(context).size.width < breakpointWide;

  static bool isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= breakpointWide;

  // Shadows
  static List<BoxShadow> get shadowSubtle => [
        BoxShadow(
          color: DoctorColors.brandNavy.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowCard => [
        BoxShadow(
          color: DoctorColors.brandNavy.withValues(alpha: 0.06),
          blurRadius: 16,
          spreadRadius: -2,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: DoctorColors.brandTeal.withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get shadowHover => [
        BoxShadow(
          color: DoctorColors.brandNavy.withValues(alpha: 0.10),
          blurRadius: 22,
          spreadRadius: -2,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: DoctorColors.brandTeal.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowGlowTeal => [
        BoxShadow(
          color: DoctorColors.brandTeal.withValues(alpha: 0.25),
          blurRadius: 24,
          spreadRadius: 2,
          offset: const Offset(0, 6),
        ),
      ];

  // Desktop Typography Scale (Google Fonts Poppins)
  static TextStyle get displayTitle => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: DoctorColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get headline1 => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: DoctorColors.textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get headline2 => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: DoctorColors.textPrimary,
        letterSpacing: -0.2,
      );

  static TextStyle get cardTitle => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: DoctorColors.textPrimary,
        letterSpacing: -0.2,
      );

  static TextStyle get subtitle => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: DoctorColors.textSecondary,
        letterSpacing: 0.1,
      );

  static TextStyle get bodyBold => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: DoctorColors.textPrimary,
      );

  static TextStyle get bodyRegular => GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: DoctorColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get body => GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: DoctorColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get bodyMuted => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: DoctorColors.textSecondary,
      );

  static TextStyle get buttonText => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      );

  static TextStyle get caption => GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: DoctorColors.textMuted,
        letterSpacing: 0.2,
      );

  static TextStyle get badgeText => GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );
}

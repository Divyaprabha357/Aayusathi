import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'patient_colors.dart';

/// Senior-accessible, calm medical theme for the AAYUSATHI Patient App.
class PatientTheme {
  PatientTheme._();

  static ThemeData get theme {
    final baseTextTheme = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: PatientColors.teal,
      scaffoldBackgroundColor: PatientColors.background,
      colorScheme: const ColorScheme.light(
        primary: PatientColors.teal,
        onPrimary: Colors.white,
        secondary: PatientColors.orange,
        onSecondary: Colors.white,
        surface: PatientColors.surface,
        onSurface: PatientColors.textPrimary,
        error: PatientColors.statusCritical,
        onError: Colors.white,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: PatientColors.navy,
          letterSpacing: -0.5,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: PatientColors.navy,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: PatientColors.navy,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: PatientColors.navy,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: PatientColors.navy,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: PatientColors.textPrimary,
          height: 1.5,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: PatientColors.textSecondary,
          height: 1.4,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: PatientColors.surface,
        foregroundColor: PatientColors.navy,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: PatientColors.navy, size: 28),
      ),
      cardTheme: CardThemeData(
        color: PatientColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: PatientColors.border, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PatientColors.teal,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52), // Min 48px touch target
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PatientColors.teal,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: PatientColors.teal, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PatientColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: GoogleFonts.poppins(
          fontSize: 15,
          color: PatientColors.hintColor,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: PatientColors.inputBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: PatientColors.inputBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: PatientColors.inputBorderFocused, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: PatientColors.statusCritical, width: 1.5),
        ),
      ),
    );
  }
}

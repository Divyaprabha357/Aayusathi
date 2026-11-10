import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Central theme configuration for AAYUSATHI.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.brandTeal,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.brandTeal,
        onPrimary: Colors.white,
        secondary: AppColors.brandOrange,
        onSecondary: Colors.white,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimary,
        error: AppColors.statusCritical,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderLight, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandTeal,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.buttonLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFD6E4E5), width: 1.0),
        ),
        titleTextStyle: AppTextStyles.headlineMedium.copyWith(color: const Color(0xFF102A43)),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFF486581)),
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(Colors.white),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFD6E4E5), width: 1.0),
        ),
        textStyle: const TextStyle(color: Color(0xFF102A43)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.brandTeal,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.brandTeal,
        onPrimary: Colors.white,
        secondary: AppColors.brandOrange,
        onSecondary: Colors.white,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textLight,
        error: AppColors.statusCritical,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderDark, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandTeal,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.buttonLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderDark, width: 1.0),
        ),
        titleTextStyle: AppTextStyles.headlineMedium.copyWith(color: AppColors.textLight),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.surfaceDark),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderDark, width: 1.0),
        ),
        textStyle: const TextStyle(color: AppColors.textLight),
      ),
    );
  }
}

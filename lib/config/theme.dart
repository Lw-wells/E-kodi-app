import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      fontFamily: 'Poppins',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        displaySmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontFamily: 'Open Sans', fontWeight: FontWeight.normal),
        bodyMedium: TextStyle(fontFamily: 'Open Sans', fontWeight: FontWeight.normal),
        bodySmall: TextStyle(fontFamily: 'Open Sans', fontWeight: FontWeight.normal),
        labelLarge: TextStyle(fontFamily: 'Open Sans', fontWeight: FontWeight.w500),
        labelMedium: TextStyle(fontFamily: 'Open Sans', fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontFamily: 'Open Sans', fontWeight: FontWeight.w500),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.accent,
        surface: Color(0xFF1E1E1E),
        error: AppColors.error,
      ),
      fontFamily: 'Poppins',
      // We can expand dark theme properties further as needed
    );
  }
}

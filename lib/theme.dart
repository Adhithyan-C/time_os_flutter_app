import 'package:flutter/material.dart';

// This class holds all the colors for our app, centralizing them in one place.
class AppColors {
  // Neutral Colors
  static const Color background = Color(0xFFF9FAFB);
  static const Color primaryText = Color(0xFF374151);
  static const Color secondaryText = Color(0xFF6B7280);

  // Action Colors
  static const Color primary = Color(0xFF3B82F6);
  static const Color secondary = Color(0xFF93C5FD);
  static const Color tertiary = Color(0xFFDBEAFE);

  // Functional Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // High-Contrast Text for Buttons
  static const Color textOnPrimary = Color(0xFFFFFFFF);
}

// This class defines the overall theme of the app.
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      // --- GENERAL ---
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      fontFamily: 'Poppins', // We will add this font later
      // --- COLOR SCHEME ---
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.tertiary,
        background: AppColors.background,
        error: AppColors.danger,
      ),

      // --- TEXT THEME ---
      textTheme: const TextTheme(
        // For large titles
        headlineLarge: TextStyle(
          color: AppColors.primaryText,
          fontWeight: FontWeight.bold,
          fontSize: 28,
        ),
        // For standard body text
        bodyMedium: TextStyle(
          color: AppColors.primaryText,
          fontWeight: FontWeight.normal,
          fontSize: 16,
        ),
        // For button text
        labelLarge: TextStyle(
          color: AppColors.textOnPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

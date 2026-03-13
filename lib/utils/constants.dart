import 'package:flutter/material.dart';
import 'secrets.dart';

class AppColors {
  // Brand colors from OldTalkApp
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color primaryBlueHover = Color(0xFF2563EB);

  // Background and Surface (Light Theme from OldTalkApp)
  static const Color bgLight = Color(0xFFFFFFFF); // Pure White
  static const Color bgInput = Color(0xFFF9FAFB); // Light Gray for Inputs
  static const Color borderLight = Color(0xFFE5E7EB); // Border Gray
  static const Color surfaceLight = Color(
    0xFFF3F4F6,
  ); // Avatar/Bubble Background

  // Text Colors
  static const Color textDark = Color(0xFF111827); // Titles
  static const Color textGray = Color(0xFF6B7280); // Subtitles
  static const Color textLightGray = Color(0xFF9CA3AF); // Placeholder / Time

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
}

class ApiKeys {
  static const String groqApiKey = Secrets.groqApiKey;
}

final ThemeData appThemeData = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.bgLight,
  primaryColor: AppColors.primaryBlue,
  fontFamily: 'Inter', // Typical clean font
  colorScheme: const ColorScheme.light(
    primary: AppColors.primaryBlue,
    secondary: AppColors.primaryBlueHover,
    surface: AppColors.bgLight,
    background: AppColors.bgLight,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.bgLight,
    elevation: 0,
    iconTheme: IconThemeData(color: AppColors.textDark),
    titleTextStyle: TextStyle(
      color: AppColors.textDark,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.bgInput,
    hintStyle: const TextStyle(color: AppColors.textLightGray, fontSize: 16),
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.borderLight),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.borderLight),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primaryBlue),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(vertical: 0),
      elevation: 4, // To match the Shadow in XAML
      shadowColor: AppColors.primaryBlue.withOpacity(0.3),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  ),
);

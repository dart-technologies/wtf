import 'package:flutter/material.dart';

class AppColors {
  // Person palette
  static const personA = Color(0xFF4A9EFF); // Abby — blue
  static const personB = Color(0xFFFF6B6B); // Mike — coral

  // Block status
  static const unclaimed = Color(0xFFBDBDBD); // grey
  static const inProgress = Color(0xFFFFF176); // soft yellow
  static const decided = Color(0xFF81C784); // soft green

  // AI-owned
  static const ai = Color(0xFFCE93D8); // soft purple

  // Surface
  static const background = Color(0xFFF5F5F5);
  static const surface = Color(0xFFFFFFFF);
  static const divider = Color(0xFFE0E0E0);

  // Text
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF757575);

  static Color forPersonId(String personId) {
    switch (personId) {
      case 'person_a':
        return personA;
      case 'person_b':
        return personB;
      case 'ai':
        return ai;
      default:
        return unclaimed;
    }
  }
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.personA,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Inter',
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.divider),
          ),
          color: AppColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
          titleMedium: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
      );
}

import 'package:flutter/material.dart';

abstract class AppColors {
  static const background = Color(0xFF161622);
  static const surface = Color(0xFF1E1E2E);
  static const accent = Color(0xFFE68A00);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF9A9AB0);
  static const divider = Color(0xFF2C2C3E);
}

class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textSecondary,
      ),
    );
  }
}

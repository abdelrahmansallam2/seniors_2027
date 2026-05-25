import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';

abstract final class AppTheme {
  static ThemeData get retro {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.pink,
        primary: AppColors.ink,
        surface: AppColors.paper,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displayLarge: const TextStyle(
          color: AppColors.ink,
          fontSize: 51,
          fontWeight: FontWeight.w900,
          height: 1.1,
          letterSpacing: -1.4,
        ),
        headlineMedium: const TextStyle(
          color: AppColors.ink,
          fontSize: 28,
          fontWeight: FontWeight.w900,
          height: 1.1,
        ),
        titleLarge: const TextStyle(
          color: AppColors.ink,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          height: 1.1,
        ),
        labelLarge: const TextStyle(
          color: AppColors.ink,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
        bodySmall: const TextStyle(
          color: AppColors.ink,
          fontSize: 9,
          fontFamily: 'monospace',
          height: 1.5,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

enum AppColorTheme { financial }
enum ThemeMode { system, light, dark, amoled }

class AppColorSchemes {
  AppColorSchemes._();

  static final AppColorSchemes instance = AppColorSchemes._();

  // Financial green seed color for Material 3 dynamic theming
  static const Color financialSeedColor = Color(0xFF10B981);
}

extension AppColorThemeExtension on AppColorTheme {
  ColorScheme lightColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: AppColorSchemes.financialSeedColor,
      brightness: Brightness.light,
    ).copyWith(
      // Pixel-style light mode surface hierarchy
      surface: const Color(0xFFFEFBFF),
      surfaceContainer: const Color(0xFFF3F0F4),
      surfaceContainerLow: const Color(0xFFF9F6FA),
      surfaceContainerHigh: const Color(0xFFEDE9ED),
      surfaceContainerHighest: const Color(0xFFE7E4E8),
    );
  }

  ColorScheme darkColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: AppColorSchemes.financialSeedColor,
      brightness: Brightness.dark,
    );
  }

  ColorScheme amoledColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: AppColorSchemes.financialSeedColor,
      brightness: Brightness.dark,
    ).copyWith(
      // OLED-optimized pure black surface hierarchy
      surface: const Color(0xFF000000),
      surfaceContainer: const Color(0xFF0F0F0F),
      surfaceContainerLow: const Color(0xFF0A0A0A),
      surfaceContainerHigh: const Color(0xFF1A1A1A),
      surfaceContainerHighest: const Color(0xFF242424),
      onSurface: const Color(0xFFE6E1E5),
      onSurfaceVariant: const Color(0xFFCAC4D0),
      outline: const Color(0xFF938F99),
    );
  }

  ColorScheme colorScheme(Brightness brightness) {
    return brightness == Brightness.light
        ? lightColorScheme()
        : darkColorScheme();
  }
}

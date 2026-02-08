import 'package:flutter/material.dart';
import 'package:mudra_manager/theme/theme_provider.dart';

enum AppColorTheme { dynamic, finance }

class AppColorSchemes {
  AppColorSchemes._();
  static final AppColorSchemes instance = AppColorSchemes._();

  // Financial green seed color for Material 3 dynamic theming
  static const Color financialSeedColor = Color(0xFF10B981);

  ColorScheme buildScheme(
    Color seed,
    Brightness brightness, {
    bool isAmoled = false,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    if (isAmoled && brightness == Brightness.dark) {
      return scheme.copyWith(
        surface: Colors.black,
        surfaceContainer: Colors.black,
        surfaceContainerLow: Colors.black,
        surfaceContainerLowest: Colors.black,
        surfaceContainerHigh: const Color(0xFF1C1C1C),
        surfaceContainerHighest: const Color(0xFF2C2C2C),
      );
    }
    return scheme;
  }
}

extension AppColorThemeExtension on AppColorTheme {
  Color get seedColor {
    switch (this) {
      case AppColorTheme.dynamic:
        return AppColorSchemes.financialSeedColor;
      case AppColorTheme.finance:
        return AppColorSchemes.financialSeedColor;
    }
  }

  ColorScheme colorScheme(AppThemeMode mode) {
    final brightness =
        (mode == AppThemeMode.light) ? Brightness.light : Brightness.dark;
    final isAmoled = mode == AppThemeMode.amoled;

    return AppColorSchemes.instance.buildScheme(
      seedColor,
      brightness,
      isAmoled: isAmoled,
    );
  }

  // Helper methods for legacy compatibility if needed
  ColorScheme lightColorScheme() => colorScheme(AppThemeMode.light);
  ColorScheme darkColorScheme() => colorScheme(AppThemeMode.dark);
  ColorScheme amoledColorScheme() => colorScheme(AppThemeMode.amoled);
}

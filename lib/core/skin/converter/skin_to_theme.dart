import 'package:flutter/material.dart';
import 'package:mudra_manager/core/skin/model/skin.dart';
import 'package:mudra_manager/core/theme/theme_provider.dart';

/// Converts a resolved [Skin] into Flutter [ColorScheme] and integrates
/// with [AppThemeMode] (light/dark/amoled).
class SkinToTheme {
  SkinToTheme._();

  /// Builds a [ColorScheme] from the skin for the given mode.
  static ColorScheme colorScheme(Skin skin, AppThemeMode mode) {
    final brightness =
        (mode == AppThemeMode.light) ? Brightness.light : Brightness.dark;
    final isAmoled = mode == AppThemeMode.amoled;
    final colorSet =
        brightness == Brightness.light ? skin.palette.light : skin.palette.dark;

    // Start from seed, then apply overrides
    var scheme = ColorScheme.fromSeed(
      seedColor: colorSet.seed,
      brightness: brightness,
    );

    scheme = scheme.copyWith(
      primary: colorSet.primary,
      secondary: colorSet.secondary,
      tertiary: colorSet.tertiary,
      primaryContainer: colorSet.primaryContainer,
      secondaryContainer: colorSet.secondaryContainer,
      tertiaryContainer: colorSet.tertiaryContainer,
      surface: colorSet.surface,
      surfaceContainerLow: colorSet.surfaceContainerLow,
      surfaceContainerHighest: colorSet.surfaceContainerHigh,
      onSurface: colorSet.onSurface,
      onSurfaceVariant: colorSet.onSurfaceVariant,
      outline: colorSet.outline,
      outlineVariant: colorSet.outlineVariant,
    );

    // AMOLED: force pure black surfaces
    if (isAmoled) {
      scheme = scheme.copyWith(
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

  static ColorScheme lightScheme(Skin skin) => colorScheme(skin, AppThemeMode.light);
  static ColorScheme darkScheme(Skin skin) => colorScheme(skin, AppThemeMode.dark);
  static ColorScheme amoledScheme(Skin skin) => colorScheme(skin, AppThemeMode.amoled);
}

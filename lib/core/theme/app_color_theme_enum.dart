import 'package:flutter/material.dart';
import 'package:mudra_manager/core/theme/theme_provider.dart';

// ── Theme Catalog ──────────────────────────────────────────
enum AppColorTheme {
  // Free (Core)
  finance, // growth green — default
  classic, // trust blue-gray
  dark, // neutral dark

  // Pro (Professional)
  ocean, // calm blue
  forest, // deep green
  midnight, // dark premium
  graphite, // minimal gray

  // Pro (Fun)
  sunset,
  lavender,
  rose,
  amber,

  // Special
  dynamic, // device wallpaper
}

// ── Seed Colors ────────────────────────────────────────────
class AppColorSchemes {
  AppColorSchemes._();
  static final AppColorSchemes instance = AppColorSchemes._();

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

// ── Metadata ───────────────────────────────────────────────
extension AppColorThemeInfo on AppColorTheme {
  bool get isPro => switch (this) {
        AppColorTheme.finance ||
        AppColorTheme.classic ||
        AppColorTheme.dark =>
          false,
        _ => true,
      };

  String get label => switch (this) {
        AppColorTheme.finance => 'Finance',
        AppColorTheme.classic => 'Classic',
        AppColorTheme.dark => 'Dark',
        AppColorTheme.ocean => 'Ocean',
        AppColorTheme.forest => 'Forest',
        AppColorTheme.midnight => 'Midnight',
        AppColorTheme.graphite => 'Graphite',
        AppColorTheme.sunset => 'Sunset',
        AppColorTheme.lavender => 'Lavender',
        AppColorTheme.rose => 'Rose',
        AppColorTheme.amber => 'Amber',
        AppColorTheme.dynamic => 'Dynamic',
      };

  String get subtitle => switch (this) {
        AppColorTheme.finance => 'Growth & savings',
        AppColorTheme.classic => 'Trust & security',
        AppColorTheme.dark => 'Easy on the eyes',
        AppColorTheme.ocean => 'Calm & focused',
        AppColorTheme.forest => 'Deep & grounded',
        AppColorTheme.midnight => 'Premium dark',
        AppColorTheme.graphite => 'Clean & minimal',
        AppColorTheme.sunset => 'Warm & vibrant',
        AppColorTheme.lavender => 'Soft & elegant',
        AppColorTheme.rose => 'Bold & expressive',
        AppColorTheme.amber => 'Energetic & warm',
        AppColorTheme.dynamic => 'Matches your wallpaper',
      };
}

extension AppColorThemeExtension on AppColorTheme {
  Color get seedColor => switch (this) {
        AppColorTheme.finance => const Color(0xFF10B981), // emerald green
        AppColorTheme.classic => const Color(0xFF5B7FA5), // slate blue-gray
        AppColorTheme.dark => const Color(0xFF78909C), // blue-gray neutral
        AppColorTheme.ocean => const Color(0xFF0077B6), // calm blue
        AppColorTheme.forest => const Color(0xFF2D6A4F), // deep green
        AppColorTheme.midnight => const Color(0xFF1A237E), // deep indigo
        AppColorTheme.graphite => const Color(0xFF616161), // neutral gray
        AppColorTheme.sunset => const Color(0xFFE85D04), // warm orange
        AppColorTheme.lavender => const Color(0xFF7C3AED), // soft purple
        AppColorTheme.rose => const Color(0xFFE11D48), // bold pink
        AppColorTheme.amber => const Color(0xFFF59E0B), // warm yellow
        AppColorTheme.dynamic => AppColorSchemes.financialSeedColor, // fallback
      };

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

  ColorScheme lightColorScheme() => colorScheme(AppThemeMode.light);
  ColorScheme darkColorScheme() => colorScheme(AppThemeMode.dark);
  ColorScheme amoledColorScheme() => colorScheme(AppThemeMode.amoled);
}

// ── Semantic Finance Colors (NEVER change with theme) ──────
/// Fixed colors for financial meaning. Use these instead of
/// colorScheme.primary / colorScheme.error for money amounts.
class FinanceColors {
  FinanceColors._();

  // Income = always green (growth)
  static const Color income = Color(0xFF10B981);
  static const Color incomeDark = Color(0xFF34D399);

  // Expense = always red (spending)
  static const Color expense = Color(0xFFEF4444);
  static const Color expenseDark = Color(0xFFF87171);

  // Transfer = always blue (neutral movement)
  static const Color transfer = Color(0xFF3B82F6);
  static const Color transferDark = Color(0xFF60A5FA);

  /// Returns the correct income color for the current brightness.
  static Color incomeColor(Brightness brightness) =>
      brightness == Brightness.dark ? incomeDark : income;

  /// Returns the correct expense color for the current brightness.
  static Color expenseColor(Brightness brightness) =>
      brightness == Brightness.dark ? expenseDark : expense;

  /// Returns the correct transfer color for the current brightness.
  static Color transferColor(Brightness brightness) =>
      brightness == Brightness.dark ? transferDark : transfer;
}

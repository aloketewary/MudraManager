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
    Color? primary,
    Color? secondary,
    Color? tertiary,
    Color? primaryContainer,
    Color? secondaryContainer,
    Color? tertiaryContainer,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    final tuned = scheme.copyWith(
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      primaryContainer: primaryContainer,
      secondaryContainer: secondaryContainer,
      tertiaryContainer: tertiaryContainer,
    );

    if (isAmoled && brightness == Brightness.dark) {
      return tuned.copyWith(
        surface: Colors.black,
        surfaceContainer: Colors.black,
        surfaceContainerLow: Colors.black,
        surfaceContainerLowest: Colors.black,
        surfaceContainerHigh: const Color(0xFF1C1C1C),
        surfaceContainerHighest: const Color(0xFF2C2C2C),
      );
    }
    return tuned;
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
        AppColorTheme.finance => const Color(0xFF10B981),
        AppColorTheme.classic => const Color(0xFF5B7FA5),
        AppColorTheme.dark => const Color(0xFF78909C),
        AppColorTheme.ocean => const Color(0xFF0077B6),
        AppColorTheme.forest => const Color(0xFF2D6A4F),
        AppColorTheme.midnight => const Color(0xFF1A237E),
        AppColorTheme.graphite => const Color(0xFF616161),
        AppColorTheme.sunset => const Color(0xFFE85D04),
        AppColorTheme.lavender => const Color(0xFF7C3AED),
        AppColorTheme.rose => const Color(0xFFE11D48),
        AppColorTheme.amber => const Color(0xFFF59E0B),
        AppColorTheme.dynamic => AppColorSchemes.financialSeedColor,
      };

  /// Hand-tuned color overrides per theme.
  /// Returns null for free themes (pure fromSeed).
  _ThemeTuning? get _tuning => switch (this) {
        // Free themes — no overrides, pure Material 3
        AppColorTheme.finance || AppColorTheme.classic || AppColorTheme.dark || AppColorTheme.dynamic => null,

        // Ocean — deep navy + teal accent
        AppColorTheme.ocean => const _ThemeTuning(
          lightPrimary: Color(0xFF006494),
          lightSecondary: Color(0xFF0096C7),
          lightTertiary: Color(0xFF48CAE4),
          lightPrimaryContainer: Color(0xFFCAE9FF),
          lightSecondaryContainer: Color(0xFFD4F1F9),
          lightTertiaryContainer: Color(0xFFE0F7FA),
          darkPrimary: Color(0xFF48CAE4),
          darkSecondary: Color(0xFF90E0EF),
          darkTertiary: Color(0xFFADE8F4),
          darkPrimaryContainer: Color(0xFF003554),
          darkSecondaryContainer: Color(0xFF004E71),
          darkTertiaryContainer: Color(0xFF005F85),
        ),

        // Forest — rich emerald + warm earth
        AppColorTheme.forest => const _ThemeTuning(
          lightPrimary: Color(0xFF1B5E20),
          lightSecondary: Color(0xFF558B2F),
          lightTertiary: Color(0xFF8D6E63),
          lightPrimaryContainer: Color(0xFFC8E6C9),
          lightSecondaryContainer: Color(0xFFDCEDC8),
          lightTertiaryContainer: Color(0xFFD7CCC8),
          darkPrimary: Color(0xFF66BB6A),
          darkSecondary: Color(0xFF9CCC65),
          darkTertiary: Color(0xFFBCAAA4),
          darkPrimaryContainer: Color(0xFF1B3A1B),
          darkSecondaryContainer: Color(0xFF2E4A1E),
          darkTertiaryContainer: Color(0xFF3E2723),
        ),

        // Midnight — deep indigo + electric blue
        AppColorTheme.midnight => const _ThemeTuning(
          lightPrimary: Color(0xFF1A237E),
          lightSecondary: Color(0xFF283593),
          lightTertiary: Color(0xFF5C6BC0),
          lightPrimaryContainer: Color(0xFFC5CAE9),
          lightSecondaryContainer: Color(0xFFD1D9FF),
          lightTertiaryContainer: Color(0xFFE8EAF6),
          darkPrimary: Color(0xFF7986CB),
          darkSecondary: Color(0xFF9FA8DA),
          darkTertiary: Color(0xFF536DFE),
          darkPrimaryContainer: Color(0xFF0D1259),
          darkSecondaryContainer: Color(0xFF1A237E),
          darkTertiaryContainer: Color(0xFF1A1F6E),
        ),

        // Graphite — warm gray + subtle gold accent
        AppColorTheme.graphite => const _ThemeTuning(
          lightPrimary: Color(0xFF424242),
          lightSecondary: Color(0xFF757575),
          lightTertiary: Color(0xFFBFA76A),
          lightPrimaryContainer: Color(0xFFE0E0E0),
          lightSecondaryContainer: Color(0xFFEEEEEE),
          lightTertiaryContainer: Color(0xFFF5F0E1),
          darkPrimary: Color(0xFFBDBDBD),
          darkSecondary: Color(0xFF9E9E9E),
          darkTertiary: Color(0xFFD4AF37),
          darkPrimaryContainer: Color(0xFF2C2C2C),
          darkSecondaryContainer: Color(0xFF383838),
          darkTertiaryContainer: Color(0xFF3D3520),
        ),

        // Sunset — warm orange → coral gradient feel
        AppColorTheme.sunset => const _ThemeTuning(
          lightPrimary: Color(0xFFD84315),
          lightSecondary: Color(0xFFE65100),
          lightTertiary: Color(0xFFFF6D00),
          lightPrimaryContainer: Color(0xFFFFCCBC),
          lightSecondaryContainer: Color(0xFFFFE0B2),
          lightTertiaryContainer: Color(0xFFFFF3E0),
          darkPrimary: Color(0xFFFF8A65),
          darkSecondary: Color(0xFFFFAB40),
          darkTertiary: Color(0xFFFFD180),
          darkPrimaryContainer: Color(0xFF4E1A00),
          darkSecondaryContainer: Color(0xFF5D2E00),
          darkTertiaryContainer: Color(0xFF6D3F00),
        ),

        // Lavender — soft purple + pink accent
        AppColorTheme.lavender => const _ThemeTuning(
          lightPrimary: Color(0xFF6D28D9),
          lightSecondary: Color(0xFF7E57C2),
          lightTertiary: Color(0xFFEC407A),
          lightPrimaryContainer: Color(0xFFE1D5F5),
          lightSecondaryContainer: Color(0xFFEDE7F6),
          lightTertiaryContainer: Color(0xFFFCE4EC),
          darkPrimary: Color(0xFFB39DDB),
          darkSecondary: Color(0xFFCE93D8),
          darkTertiary: Color(0xFFF48FB1),
          darkPrimaryContainer: Color(0xFF311B92),
          darkSecondaryContainer: Color(0xFF4A148C),
          darkTertiaryContainer: Color(0xFF4A0E2E),
        ),

        // Rose — bold pink + warm red
        AppColorTheme.rose => const _ThemeTuning(
          lightPrimary: Color(0xFFC2185B),
          lightSecondary: Color(0xFFD81B60),
          lightTertiary: Color(0xFFFF5252),
          lightPrimaryContainer: Color(0xFFF8BBD0),
          lightSecondaryContainer: Color(0xFFFCE4EC),
          lightTertiaryContainer: Color(0xFFFFEBEE),
          darkPrimary: Color(0xFFF06292),
          darkSecondary: Color(0xFFFF80AB),
          darkTertiary: Color(0xFFFF8A80),
          darkPrimaryContainer: Color(0xFF5C0028),
          darkSecondaryContainer: Color(0xFF6E0033),
          darkTertiaryContainer: Color(0xFF5D1A1A),
        ),

        // Amber — rich gold + warm brown
        AppColorTheme.amber => const _ThemeTuning(
          lightPrimary: Color(0xFFF57F17),
          lightSecondary: Color(0xFFFF8F00),
          lightTertiary: Color(0xFF6D4C41),
          lightPrimaryContainer: Color(0xFFFFF8E1),
          lightSecondaryContainer: Color(0xFFFFF3E0),
          lightTertiaryContainer: Color(0xFFD7CCC8),
          darkPrimary: Color(0xFFFFCA28),
          darkSecondary: Color(0xFFFFD54F),
          darkTertiary: Color(0xFFBCAAA4),
          darkPrimaryContainer: Color(0xFF5D4200),
          darkSecondaryContainer: Color(0xFF6D5000),
          darkTertiaryContainer: Color(0xFF3E2723),
        ),
      };

  ColorScheme colorScheme(AppThemeMode mode) {
    final brightness =
        (mode == AppThemeMode.light) ? Brightness.light : Brightness.dark;
    final isAmoled = mode == AppThemeMode.amoled;
    final t = _tuning;
    final isLight = brightness == Brightness.light;

    return AppColorSchemes.instance.buildScheme(
      seedColor,
      brightness,
      isAmoled: isAmoled,
      primary: t == null ? null : (isLight ? t.lightPrimary : t.darkPrimary),
      secondary: t == null ? null : (isLight ? t.lightSecondary : t.darkSecondary),
      tertiary: t == null ? null : (isLight ? t.lightTertiary : t.darkTertiary),
      primaryContainer: t == null ? null : (isLight ? t.lightPrimaryContainer : t.darkPrimaryContainer),
      secondaryContainer: t == null ? null : (isLight ? t.lightSecondaryContainer : t.darkSecondaryContainer),
      tertiaryContainer: t == null ? null : (isLight ? t.lightTertiaryContainer : t.darkTertiaryContainer),
    );
  }

  ColorScheme lightColorScheme() => colorScheme(AppThemeMode.light);
  ColorScheme darkColorScheme() => colorScheme(AppThemeMode.dark);
  ColorScheme amoledColorScheme() => colorScheme(AppThemeMode.amoled);
}

class _ThemeTuning {
  final Color lightPrimary;
  final Color lightSecondary;
  final Color lightTertiary;
  final Color lightPrimaryContainer;
  final Color lightSecondaryContainer;
  final Color lightTertiaryContainer;
  final Color darkPrimary;
  final Color darkSecondary;
  final Color darkTertiary;
  final Color darkPrimaryContainer;
  final Color darkSecondaryContainer;
  final Color darkTertiaryContainer;

  const _ThemeTuning({
    required this.lightPrimary,
    required this.lightSecondary,
    required this.lightTertiary,
    required this.lightPrimaryContainer,
    required this.lightSecondaryContainer,
    required this.lightTertiaryContainer,
    required this.darkPrimary,
    required this.darkSecondary,
    required this.darkTertiary,
    required this.darkPrimaryContainer,
    required this.darkSecondaryContainer,
    required this.darkTertiaryContainer,
  });
}

// ── Semantic Finance Colors (NEVER change with theme) ──────
/// Fixed colors for financial meaning. Use these instead of
/// colorScheme.primary / colorScheme.error for money amounts.
class FinanceColors {
  FinanceColors._();

  // Income = always green (growth)
  static Color income = Color(0xFF10B981);
  static Color incomeDark = Color(0xFF34D399);

  // Expense = always red (spending)
  static Color expense = Color(0xFFEF4444);
  static Color expenseDark = Color(0xFFF87171);

  // Transfer = always blue (neutral movement)
  static Color transfer = Color(0xFF3B82F6);
  static Color transferDark = Color(0xFF60A5FA);

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

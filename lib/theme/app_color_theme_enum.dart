import 'package:flutter/material.dart';

enum AppColorTheme { ocean, sunset, forest, midnight }

class AppColorSchemes {
  AppColorSchemes._();

  static final AppColorSchemes instance = AppColorSchemes._();

  // Define your primary color scheme for Light Theme
  ColorScheme oceanLightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF633AD3),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFBFB1E6),
    onPrimaryContainer: Color(0xFF180E33),
    secondary: Color(0xFF727076),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE3E2E6),
    onSecondaryContainer: Color(0xFF313033),
    tertiary: Color(0xFF9D516A),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE6C3CE),
    onTertiaryContainer: Color(0xFF331B23),
    error: Color(0xFFBE1910),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFE6A6A3),
    onErrorContainer: Color(0xFF330704),
    background: Color(0xFFfcfcfc),
    onBackground: Color(0xFF323133),
    surface: Color(0xFFfcfcfc),
    onSurface: Color(0xFF323133),
    surfaceVariant: Color(0xFFdedbe6),
    onSurfaceVariant: Color(0xFF5b5766),
    outline: Color(0xFF898399),
  );

  ColorScheme oceanDarkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFAF9BE6),
    onPrimary: Color(0xFF24154C),
    primaryContainer: Color(0xFF301C66),
    onPrimaryContainer: Color(0xFFBFB1E6),
    secondary: Color(0xFFE2E0E6),
    onSecondary: Color(0xFF4A494C),
    secondaryContainer: Color(0xFF636166),
    onSecondaryContainer: Color(0xFFE3E2E6),
    tertiary: Color(0xFFE6B4C5),
    onTertiary: Color(0xFF4C2834),
    tertiaryContainer: Color(0xFF663545),
    onTertiaryContainer: Color(0xFFE6C3CE),
    error: Color(0xFFE68C87),
    onError: Color(0xFF4C0A06),
    errorContainer: Color(0xFF660D08),
    onErrorContainer: Color(0xFFE6A6A3),
    background: Color(0xFF323133),
    onBackground: Color(0xFFe4e3e6),
    surface: Color(0xFF323133),
    onSurface: Color(0xFFe4e3e6),
    surfaceVariant: Color(0xFF5b5766),
    onSurfaceVariant: Color(0xFFdbd7e6),
    outline: Color(0xFFa7a2b3),
  );

  ColorScheme sunsetLightColorScheme = const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFC05A01),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE6BF9E),
    onPrimaryContainer: Color(0xFF331801),
    secondary: Color(0xFF747775),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE3E6E4),
    onSecondaryContainer: Color(0xFF313332),
    tertiary: Color(0xFFFFD8EF),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE6DBE1),
    onTertiaryContainer: Color(0xFF332B30),
    error: Color(0xFF8F130D),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFE6A6A3),
    onErrorContainer: Color(0xFF330705),
    background: Color(0xFFfcfcfb),
    onBackground: Color(0xFF333230),
    surface: Color(0xFFfcfcfb),
    onSurface: Color(0xFF333230),
    surfaceVariant: Color(0xFFe6ded7),
    onSurfaceVariant: Color(0xFF665b52),
    outline: Color(0xFF99897b),
  );

  ColorScheme sunsetDarkColorScheme = const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFE6AF80),
    onPrimary: Color(0xFF4C2401),
    primaryContainer: Color(0xFF663001),
    onPrimaryContainer: Color(0xFFE6BF9E),
    secondary: Color(0xFFE2E6E3),
    onSecondary: Color(0xFF4A4C4B),
    secondaryContainer: Color(0xFF636664),
    onSecondaryContainer: Color(0xFFE3E6E4),
    tertiary: Color(0xFFE6D6DF),
    onTertiary: Color(0xFF4C4148),
    tertiaryContainer: Color(0xFF665760),
    onTertiaryContainer: Color(0xFFE6DBE1),
    error: Color(0xFFE68C88),
    onError: Color(0xFF4C0A07),
    errorContainer: Color(0xFF660D09),
    onErrorContainer: Color(0xFFE6A6A3),
    background: Color(0xFF333230),
    onBackground: Color(0xFFe6e4e2),
    surface: Color(0xFF333230),
    onSurface: Color(0xFFe6e4e2),
    surfaceVariant: Color(0xFF665b52),
    onSurfaceVariant: Color(0xFFe6dbd1),
    outline: Color(0xFFb3a79c),
  );

  ColorScheme forestLightColorScheme = const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF128937),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFA6E6BA),
    onPrimaryContainer: Color(0xFF073314),
    secondary: Color(0xFF777777),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE6E6E6),
    onSecondaryContainer: Color(0xFF333333),
    tertiary: Color(0xFFBEEFBB),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFD6E6D6),
    onTertiaryContainer: Color(0xFF283328),
    error: Color(0xFF8F130D),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFE6A6A3),
    onErrorContainer: Color(0xFF330705),
    background: Color(0xFFfbfcfc),
    onBackground: Color(0xFF313331),
    surface: Color(0xFFfbfcfc),
    onSurface: Color(0xFF313331),
    surfaceVariant: Color(0xFFd9e6dd),
    onSurfaceVariant: Color(0xFF54665a),
    outline: Color(0xFF7e9987),
  );

  ColorScheme forestDarkColorScheme = const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF8CE6A8),
    onPrimary: Color(0xFF0A4C1F),
    primaryContainer: Color(0xFF0D6629),
    onPrimaryContainer: Color(0xFFA6E6BA),
    secondary: Color(0xFFE6E6E6),
    onSecondary: Color(0xFF4C4C4C),
    secondaryContainer: Color(0xFF666666),
    onSecondaryContainer: Color(0xFFE6E6E6),
    tertiary: Color(0xFFD0E6CF),
    onTertiary: Color(0xFF3C4C3C),
    tertiaryContainer: Color(0xFF516650),
    onTertiaryContainer: Color(0xFFD6E6D6),
    error: Color(0xFFE68C88),
    onError: Color(0xFF4C0A07),
    errorContainer: Color(0xFF660D09),
    onErrorContainer: Color(0xFFE6A6A3),
    background: Color(0xFF313331),
    onBackground: Color(0xFFe2e6e3),
    surface: Color(0xFF313331),
    onSurface: Color(0xFFe2e6e3),
    surfaceVariant: Color(0xFF54665a),
    onSurfaceVariant: Color(0xFFd4e6d9),
    outline: Color(0xFF9fb3a5),
  );

  ColorScheme midnightLightColorScheme = const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF1A237E),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFC5CAE9),
    onPrimaryContainer: Color(0xFF0D1333),
    secondary: Color(0xFF536DFE),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD1C4E9),
    onSecondaryContainer: Color(0xFF1A237E),
    tertiary: Color(0xFF9FA8DA),
    onTertiary: Color(0xFF1A237E),
    tertiaryContainer: Color(0xFF7986CB),
    onTertiaryContainer: Color(0xFFE8EAF6),
    error: Color(0xFFD32F2F),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFCDD2),
    onErrorContainer: Color(0xFF3F0013),
    background: Color(0xFFE8EAF6),
    onBackground: Color(0xFF1A237E),
    surface: Color(0xFFE8EAF6),
    onSurface: Color(0xFF1A237E),
    surfaceVariant: Color(0xFFD1C4E9),
    onSurfaceVariant: Color(0xFF303F9F),
    outline: Color(0xFF7986CB),
  );

  ColorScheme midnightDarkColorScheme = const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF7986CB),
    onPrimary: Color(0xFF1A237E),
    primaryContainer: Color(0xFF303F9F),
    onPrimaryContainer: Color(0xFFC5CAE9),
    secondary: Color(0xFFB39DDB),
    onSecondary: Color(0xFF311B92),
    secondaryContainer: Color(0xFF512DA8),
    onSecondaryContainer: Color(0xFFD1C4E9),
    tertiary: Color(0xFF9575CD),
    onTertiary: Color(0xFFEDE7F6),
    tertiaryContainer: Color(0xFF512DA8),
    onTertiaryContainer: Color(0xFFD1C4E9),
    error: Color(0xFFEF9A9A),
    onError: Color(0xFF4A0000),
    errorContainer: Color(0xFFB71C1C),
    onErrorContainer: Color(0xFFFFCDD2),
    background: Color(0xFF1A237E),
    onBackground: Color(0xFFE8EAF6),
    surface: Color(0xFF1A237E),
    onSurface: Color(0xFFE8EAF6),
    surfaceVariant: Color(0xFF303F9F),
    onSurfaceVariant: Color(0xFFC5CAE9),
    outline: Color(0xFF7986CB),
  );
}

extension AppColorThemeExtension on AppColorTheme {
  ColorScheme lightColorScheme() {
    switch (this) {
      case AppColorTheme.ocean:
        return AppColorSchemes.instance.oceanLightColorScheme;
      case AppColorTheme.sunset:
        return AppColorSchemes.instance.sunsetLightColorScheme;
      case AppColorTheme.forest:
        return AppColorSchemes.instance.forestLightColorScheme;
      case AppColorTheme.midnight:
        return AppColorSchemes.instance.midnightLightColorScheme;
      default:
        return AppColorSchemes.instance.oceanLightColorScheme;
    }
  }

  ColorScheme darkColorScheme() {
    switch (this) {
      case AppColorTheme.ocean:
        return AppColorSchemes.instance.oceanDarkColorScheme;
      case AppColorTheme.sunset:
        return AppColorSchemes.instance.sunsetDarkColorScheme;
      case AppColorTheme.forest:
        return AppColorSchemes.instance.forestDarkColorScheme;
      case AppColorTheme.midnight:
        return AppColorSchemes.instance.midnightDarkColorScheme;
      default:
        return AppColorSchemes.instance.oceanDarkColorScheme;
    }
  }

  ColorScheme colorScheme(Brightness brightness) {
    return brightness == Brightness.light
        ? lightColorScheme()
        : darkColorScheme();
  }
}

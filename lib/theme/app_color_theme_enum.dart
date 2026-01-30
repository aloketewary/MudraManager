import 'package:flutter/material.dart';

enum AppColorTheme { ocean, sunset, forest, midnight }

class AppColorSchemes {
  AppColorSchemes._();

  static final AppColorSchemes instance = AppColorSchemes._();

  // Define your primary color scheme for Light Theme
  ColorScheme oceanLightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF0061A4),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD1E4FF),
    onPrimaryContainer: Color(0xFF001D36),
    secondary: Color(0xFF535F70),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD7E3F7),
    onSecondaryContainer: Color(0xFF101C2B),
    tertiary: Color(0xFF6B5778),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFF2DAFF),
    onTertiaryContainer: Color(0xFF251431),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    background: Color(0xFFFDFCFF),
    onBackground: Color(0xFF1A1C1E),
    surface: Color(0xFFFDFCFF),
    onSurface: Color(0xFF1A1C1E),
    surfaceVariant: Color(0xFFDFE2EB),
    onSurfaceVariant: Color(0xFF43474E),
    outline: Color(0xFF73777F),
  );

  ColorScheme oceanDarkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF9ECAFF),
    onPrimary: Color(0xFF003258),
    primaryContainer: Color(0xFF00497D),
    onPrimaryContainer: Color(0xFFD1E4FF),
    secondary: Color(0xFFBBC7DB),
    onSecondary: Color(0xFF253140),
    secondaryContainer: Color(0xFF3B4858),
    onSecondaryContainer: Color(0xFFD7E3F7),
    tertiary: Color(0xFFD6BEE4),
    onTertiary: Color(0xFF3B2948),
    tertiaryContainer: Color(0xFF523F5F),
    onTertiaryContainer: Color(0xFFF2DAFF),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    background: Color(0xFF1A1C1E),
    onBackground: Color(0xFFE2E2E6),
    surface: Color(0xFF1A1C1E),
    onSurface: Color(0xFFE2E2E6),
    surfaceVariant: Color(0xFF43474E),
    onSurfaceVariant: Color(0xFFC3C7CF),
    outline: Color(0xFF8D9199),
  );

  ColorScheme sunsetLightColorScheme = const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFB3261E),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFDAD6),
    onPrimaryContainer: Color(0xFF410002),
    secondary: Color(0xFF775652),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFFDAD6),
    onSecondaryContainer: Color(0xFF2C1512),
    tertiary: Color(0xFF705D00),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFE16F),
    onTertiaryContainer: Color(0xFF221B00),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    background: Color(0xFFFFFBFF),
    onBackground: Color(0xFF201A19),
    surface: Color(0xFFFFFBFF),
    onSurface: Color(0xFF201A19),
    surfaceVariant: Color(0xFFF5DDDA),
    onSurfaceVariant: Color(0xFF534341),
    outline: Color(0xFF857370),
  );

  ColorScheme sunsetDarkColorScheme = const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFFB4AB),
    onPrimary: Color(0xFF690005),
    primaryContainer: Color(0xFF93000A),
    onPrimaryContainer: Color(0xFFFFDAD6),
    secondary: Color(0xFFE7BDB7),
    onSecondary: Color(0xFF442925),
    secondaryContainer: Color(0xFF5D3F3B),
    onSecondaryContainer: Color(0xFFFFDAD6),
    tertiary: Color(0xFFE5C14B),
    onTertiary: Color(0xFF3B2F00),
    tertiaryContainer: Color(0xFF544600),
    onTertiaryContainer: Color(0xFFFFE16F),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    background: Color(0xFF201A19),
    onBackground: Color(0xFFEDE0DE),
    surface: Color(0xFF201A19),
    onSurface: Color(0xFFEDE0DE),
    surfaceVariant: Color(0xFF534341),
    onSurfaceVariant: Color(0xFFD8C2BE),
    outline: Color(0xFFA08C89),
  );

  ColorScheme forestLightColorScheme = const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF006E1C),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF96F990),
    onPrimaryContainer: Color(0xFF002204),
    secondary: Color(0xFF526350),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD5E8D0),
    onSecondaryContainer: Color(0xFF101F10),
    tertiary: Color(0xFF39656D),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFBCEBF4),
    onTertiaryContainer: Color(0xFF001F24),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    background: Color(0xFFFCFDF7),
    onBackground: Color(0xFF1A1C19),
    surface: Color(0xFFFCFDF7),
    onSurface: Color(0xFF1A1C19),
    surfaceVariant: Color(0xFFDEE5D9),
    onSurfaceVariant: Color(0xFF424940),
    outline: Color(0xFF72796F),
  );

  ColorScheme forestDarkColorScheme = const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF7BDC76),
    onPrimary: Color(0xFF00390A),
    primaryContainer: Color(0xFF005313),
    onPrimaryContainer: Color(0xFF96F990),
    secondary: Color(0xFFB9CCB4),
    onSecondary: Color(0xFF243424),
    secondaryContainer: Color(0xFF3A4B39),
    onSecondaryContainer: Color(0xFFD5E8D0),
    tertiary: Color(0xFFA1CED7),
    onTertiary: Color(0xFF00363D),
    tertiaryContainer: Color(0xFF1F4D54),
    onTertiaryContainer: Color(0xFFBCEBF4),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    background: Color(0xFF1A1C19),
    onBackground: Color(0xFFE2E3DD),
    surface: Color(0xFF1A1C19),
    onSurface: Color(0xFFE2E3DD),
    surfaceVariant: Color(0xFF424940),
    onSurfaceVariant: Color(0xFFC2C9BD),
    outline: Color(0xFF8C9388),
  );

  ColorScheme midnightLightColorScheme = const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF415F91),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD6E3FF),
    onPrimaryContainer: Color(0xFF001B3E),
    secondary: Color(0xFF565F71),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFDAE2F9),
    onSecondaryContainer: Color(0xFF131C2B),
    tertiary: Color(0xFF705575),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFAD8FD),
    onTertiaryContainer: Color(0xFF28132E),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    background: Color(0xFFFDFBFF),
    onBackground: Color(0xFF1A1B1F),
    surface: Color(0xFFFDFBFF),
    onSurface: Color(0xFF1A1B1F),
    surfaceVariant: Color(0xFFE0E2EC),
    onSurfaceVariant: Color(0xFF44474E),
    outline: Color(0xFF74777F),
  );

  ColorScheme midnightDarkColorScheme = const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFAAC7FF),
    onPrimary: Color(0xFF0A305F),
    primaryContainer: Color(0xFF284777),
    onPrimaryContainer: Color(0xFFD6E3FF),
    secondary: Color(0xFFBEC6DC),
    onSecondary: Color(0xFF283141),
    secondaryContainer: Color(0xFF3E4759),
    onSecondaryContainer: Color(0xFFDAE2F9),
    tertiary: Color(0xFFDDBCE0),
    onTertiary: Color(0xFF3F2844),
    tertiaryContainer: Color(0xFF573E5C),
    onTertiaryContainer: Color(0xFFFAD8FD),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    background: Color(0xFF1A1B1F),
    onBackground: Color(0xFFE3E2E6),
    surface: Color(0xFF1A1B1F),
    onSurface: Color(0xFFE3E2E6),
    surfaceVariant: Color(0xFF44474E),
    onSurfaceVariant: Color(0xFFC4C6D0),
    outline: Color(0xFF8E9099),
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

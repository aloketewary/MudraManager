import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mudra_manager/theme/app_color_theme_enum.dart';

class AppTheme {
  AppTheme._(this.extensions);

  static final AppTheme instance = AppTheme._([]);

  final Iterable<ThemeExtension<dynamic>>? extensions;

  // Build the TextTheme with Onest for both light and dark themes
  TextTheme _buildTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge!.copyWith(
        fontFamily: 'Onest',
        fontWeight: FontWeight.w900, // Black
        fontSize: 56.0,
      ),
      displayMedium: base.displayMedium!.copyWith(
        fontFamily: 'Onest',
        fontWeight: FontWeight.w800, // ExtraBold
        fontSize: 48.0,
      ),
      displaySmall: base.displaySmall!.copyWith(
        fontFamily: 'Onest',
        fontWeight: FontWeight.w700, // Bold
        fontSize: 40.0,
      ),
      headlineLarge: base.headlineLarge!.copyWith(
        fontFamily: 'Onest',
        fontWeight: FontWeight.w700, // Bold
        fontSize: 32.0,
      ),
      headlineMedium: base.headlineMedium!.copyWith(
        fontFamily: 'Onest',
        fontWeight: FontWeight.w600, // SemiBold
        fontSize: 28.0,
      ),
      headlineSmall: base.headlineSmall!.copyWith(
        fontFamily: 'Onest',
        fontWeight: FontWeight.w600, // SemiBold
        fontSize: 24.0,
      ),
      titleLarge: base.titleLarge!.copyWith(
        fontFamily: 'Onest',
        fontWeight: FontWeight.w500, // Medium
        fontSize: 22.0,
      ),
      titleMedium: base.titleMedium!.copyWith(
        fontFamily: 'Onest',
        fontWeight: FontWeight.w500, // Medium
        fontSize: 16.0,
      ),
      titleSmall: base.titleSmall!.copyWith(
        fontFamily: 'Onest',
        fontWeight: FontWeight.w400, // Regular
        fontSize: 14.0,
      ),
      bodyLarge: base.bodyLarge!.copyWith(
        fontFamily: 'Onest',
        fontWeight: FontWeight.w400, // Regular
        fontSize: 16.0,
      ),
      bodyMedium: base.bodyMedium!.copyWith(
        fontFamily: 'Onest',
        fontWeight: FontWeight.w400, // Regular
        fontSize: 14.0,
      ),
      bodySmall: base.bodySmall!.copyWith(
        fontFamily: 'Onest',
        fontWeight: FontWeight.w300, // Light
        fontSize: 12.0,
      ),
      labelLarge: base.labelLarge!.copyWith(
        fontFamily: 'Onest',
        fontWeight: FontWeight.w500, // Medium
        fontSize: 14.0,
      ),
      labelMedium: base.labelMedium!.copyWith(
        fontFamily: 'Onest',
        fontWeight: FontWeight.w400, // Regular
        fontSize: 12.0,
      ),
      labelSmall: base.labelSmall!.copyWith(
        fontFamily: 'Onest',
        fontWeight: FontWeight.w300, // Light
        fontSize: 10.0,
      ),
    );
  }

  // Build the Light Theme
  ThemeData buildLightTheme(AppColorTheme appTheme) {
    final ThemeData base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      extensions: extensions,
      colorScheme: appTheme.lightColorScheme(),
      textTheme: _buildTextTheme(base.textTheme),
      primaryTextTheme: _buildTextTheme(base.primaryTextTheme),
      appBarTheme: _appBarTheme(base, appTheme.lightColorScheme(), Brightness.light),
      buttonTheme: _buttonTheme(base, appTheme.lightColorScheme()),
      elevatedButtonTheme: _elevatedButtonTheme(base, appTheme.lightColorScheme()),
      outlinedButtonTheme: _outlinedButtonTheme(base, appTheme.lightColorScheme()),
      inputDecorationTheme: _inputDecorationTheme(base, appTheme.lightColorScheme()),
      cardTheme: _cardTheme(base, appTheme.lightColorScheme()),
      dialogTheme: _dialogTheme(base, appTheme.lightColorScheme()),
      chipTheme: _chipTheme(base, appTheme.lightColorScheme()),
      tabBarTheme: _tabBarTheme(base, appTheme.lightColorScheme()),
      tooltipTheme: _tooltipTheme(base, appTheme.lightColorScheme()),
    );
  }

  // Build the Dark Theme
  ThemeData buildDarkTheme(AppColorTheme appTheme) {
    final ThemeData base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      extensions: extensions,
      colorScheme: appTheme.darkColorScheme(),
      textTheme: _buildTextTheme(base.textTheme),
      primaryTextTheme: _buildTextTheme(base.primaryTextTheme),
      appBarTheme: _appBarTheme(base, appTheme.darkColorScheme(), Brightness.light),
      buttonTheme: _buttonTheme(base, appTheme.darkColorScheme()),
      elevatedButtonTheme: _elevatedButtonTheme(base, appTheme.darkColorScheme()),
      outlinedButtonTheme: _outlinedButtonTheme(base, appTheme.darkColorScheme()),
      inputDecorationTheme: _inputDecorationTheme(base, appTheme.darkColorScheme()),
      cardTheme: _cardTheme(base, appTheme.darkColorScheme()),
      dialogTheme: _dialogTheme(base, appTheme.darkColorScheme()),
      chipTheme: _chipTheme(base, appTheme.darkColorScheme()),
      tabBarTheme: _tabBarTheme(base, appTheme.darkColorScheme()),
      tooltipTheme: _tooltipTheme(base, appTheme.darkColorScheme()),
    );
  }

  // --- Component Theme Builders (Refactored to accept ColorScheme) ---

  AppBarTheme _appBarTheme(
    ThemeData baseTheme,
    ColorScheme colorScheme,
    Brightness brightness,
  ) {
    return baseTheme.appBarTheme.copyWith(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      titleTextStyle: baseTheme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onPrimary,
      ),
      centerTitle: false,
      elevation: 0,
      iconTheme: IconThemeData(color: colorScheme.onPrimary),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: colorScheme.primary,
        statusBarBrightness: brightness,
        statusBarIconBrightness: brightness,
      ),
    );
  }

  ButtonThemeData _buttonTheme(ThemeData baseTheme, ColorScheme colorScheme) {
    return baseTheme.buttonTheme.copyWith(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      buttonColor: colorScheme.primary,
      textTheme: ButtonTextTheme.primary,
    );
  }

  ElevatedButtonThemeData _elevatedButtonTheme(
    ThemeData baseTheme,
    ColorScheme colorScheme,
  ) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        textStyle: baseTheme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600, // SemiBold
        ),
      ).copyWith(
        elevation: WidgetStateProperty.resolveWith<double>((states) {
          if (states.contains(WidgetState.pressed)) {
            return 2;
          }
          return 4;
        }),
      ),
    );
  }

  OutlinedButtonThemeData _outlinedButtonTheme(
    ThemeData baseTheme,
    ColorScheme colorScheme,
  ) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.primary),
        textStyle: baseTheme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600, // SemiBold
        ),
      ),
    );
  }

  InputDecorationTheme _inputDecorationTheme(
    ThemeData baseTheme,
    ColorScheme colorScheme,
  ) {
    return InputDecorationTheme().copyWith(
      labelStyle: baseTheme.textTheme.bodyLarge?.copyWith(
        color: colorScheme.secondary,
      ),
      hintStyle: baseTheme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.secondary,
      ),
      errorStyle: baseTheme.textTheme.bodySmall?.copyWith(
        color: colorScheme.error,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.secondary, width: 1.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error, width: 2.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error, width: 2.0),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      filled: true,
      fillColor: colorScheme.surface,
    );
  }

  CardThemeData _cardTheme(ThemeData baseTheme, ColorScheme colorScheme) {
    return baseTheme.cardTheme.copyWith(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surface,
    );
  }

  DialogThemeData _dialogTheme(ThemeData baseTheme, ColorScheme colorScheme) {
    return baseTheme.dialogTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: colorScheme.surface,
      titleTextStyle: baseTheme.textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
      ),
      contentTextStyle: baseTheme.textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
      ),
    );
  }

  ChipThemeData _chipTheme(ThemeData baseTheme, ColorScheme colorScheme) {
    return baseTheme.chipTheme.copyWith(
      backgroundColor: colorScheme.secondaryContainer,
      labelStyle: baseTheme.textTheme.labelLarge?.copyWith(
        color: colorScheme.onSecondaryContainer,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  TabBarThemeData _tabBarTheme(ThemeData baseTheme, ColorScheme colorScheme) {
    return baseTheme.tabBarTheme.copyWith(
      labelColor: colorScheme.primary,
      unselectedLabelColor: colorScheme.onSurfaceVariant,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
      ),
    );
  }

  TooltipThemeData _tooltipTheme(ThemeData baseTheme, ColorScheme colorScheme) {
    return baseTheme.tooltipTheme.copyWith(
      decoration: BoxDecoration(
        color: colorScheme.onSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: baseTheme.textTheme.bodySmall?.copyWith(
        color: colorScheme.surface,
      ),
    );
  }
}


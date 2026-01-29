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
        fontWeight: FontWeight.w900, // Black
        fontSize: 56.0,
      ),
      displayMedium: base.displayMedium!.copyWith(
        fontWeight: FontWeight.w800, // ExtraBold
        fontSize: 48.0,
      ),
      displaySmall: base.displaySmall!.copyWith(
        fontWeight: FontWeight.w700, // Bold
        fontSize: 40.0,
      ),
      headlineLarge: base.headlineLarge!.copyWith(
        fontWeight: FontWeight.w700, // Bold
        fontSize: 32.0,
      ),
      headlineMedium: base.headlineMedium!.copyWith(
        fontWeight: FontWeight.w600, // SemiBold
        fontSize: 28.0,
      ),
      headlineSmall: base.headlineSmall!.copyWith(
        fontWeight: FontWeight.w600, // SemiBold
        fontSize: 24.0,
      ),
      titleLarge: base.titleLarge!.copyWith(
        fontWeight: FontWeight.w500, // Medium
        fontSize: 22.0,
      ),
      titleMedium: base.titleMedium!.copyWith(
        fontWeight: FontWeight.w500, // Medium
        fontSize: 16.0,
      ),
      titleSmall: base.titleSmall!.copyWith(
        fontWeight: FontWeight.w400, // Regular
        fontSize: 14.0,
      ),
      bodyLarge: base.bodyLarge!.copyWith(
        fontWeight: FontWeight.w400, // Regular
        fontSize: 16.0,
      ),
      bodyMedium: base.bodyMedium!.copyWith(
        fontWeight: FontWeight.w400, // Regular
        fontSize: 14.0,
      ),
      bodySmall: base.bodySmall!.copyWith(
        fontWeight: FontWeight.w300, // Light
        fontSize: 12.0,
      ),
      labelLarge: base.labelLarge!.copyWith(
        fontWeight: FontWeight.w500, // Medium
        fontSize: 14.0,
      ),
      labelMedium: base.labelMedium!.copyWith(
        fontWeight: FontWeight.w400, // Regular
        fontSize: 12.0,
      ),
      labelSmall: base.labelSmall!.copyWith(
        fontWeight: FontWeight.w300, // Light
        fontSize: 10.0,
      ),
    );
  }

  // Build the Light Theme
  ThemeData buildLightTheme(AppColorTheme appTheme) {
    final ThemeData base = ThemeData.light(useMaterial3: true);
    final colorScheme = appTheme.lightColorScheme();
    final textTheme = _buildTextTheme(
      base.textTheme,
    ).apply(fontFamily: 'Onest');

    return base.copyWith(
      extensions: extensions,
      colorScheme: colorScheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: _appBarTheme(base, colorScheme, textTheme, Brightness.light),
      buttonTheme: _buttonTheme(base, colorScheme),
      elevatedButtonTheme: _elevatedButtonTheme(base, colorScheme),
      outlinedButtonTheme: _outlinedButtonTheme(base, colorScheme),
      inputDecorationTheme: _inputDecorationTheme(base, colorScheme),
      cardTheme: _cardTheme(base, colorScheme),
      dialogTheme: _dialogTheme(base, colorScheme),
      chipTheme: _chipTheme(base, colorScheme),
      tabBarTheme: _tabBarTheme(base, colorScheme),
      tooltipTheme: _tooltipTheme(base, colorScheme),
      listTileTheme: _listTileTheme(base, colorScheme),
      scaffoldBackgroundColor: colorScheme.surface,
    );
  }

  // Build the Dark Theme
  ThemeData buildDarkTheme(AppColorTheme appTheme) {
    final ThemeData base = ThemeData.dark(useMaterial3: true);
    final colorScheme = appTheme.darkColorScheme();
    final textTheme = _buildTextTheme(
      base.textTheme,
    ).apply(fontFamily: 'Onest');

    return base.copyWith(
      extensions: extensions,
      colorScheme: colorScheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: _appBarTheme(base, colorScheme, textTheme, Brightness.dark),
      buttonTheme: _buttonTheme(base, colorScheme),
      elevatedButtonTheme: _elevatedButtonTheme(base, colorScheme),
      outlinedButtonTheme: _outlinedButtonTheme(base, colorScheme),
      inputDecorationTheme: _inputDecorationTheme(base, colorScheme),
      cardTheme: _cardTheme(base, colorScheme),
      dialogTheme: _dialogTheme(base, colorScheme),
      chipTheme: _chipTheme(base, colorScheme),
      tabBarTheme: _tabBarTheme(base, colorScheme),
      tooltipTheme: _tooltipTheme(base, colorScheme),
      listTileTheme: _listTileTheme(base, colorScheme),
      scaffoldBackgroundColor: colorScheme.surface,
    );
  }

  // --- Component Theme Builders (Refactored to accept ColorScheme) ---

  AppBarThemeData _appBarTheme(
    ThemeData baseTheme,
    ColorScheme colorScheme,
    TextTheme textTheme,
    Brightness brightness,
  ) {
    return baseTheme.appBarTheme.copyWith(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: colorScheme.surface,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      centerTitle: false,
      elevation: 0,
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness:
            brightness == Brightness.light ? Brightness.light : Brightness.dark,
        statusBarIconBrightness:
            brightness == Brightness.light ? Brightness.dark : Brightness.light,
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

  ListTileThemeData _listTileTheme(
    ThemeData baseTheme,
    ColorScheme colorScheme,
  ) {
    return baseTheme.listTileTheme.copyWith(
      titleTextStyle: baseTheme.textTheme.titleMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      subtitleTextStyle: baseTheme.textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      iconColor: colorScheme.secondary,
      textColor: colorScheme.onSurface,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mudra_manager/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/theme/theme_provider.dart';

class AppTheme {
  AppTheme._(this.extensions);

  static final AppTheme instance = AppTheme._([]);

  final Iterable<ThemeExtension<dynamic>>? extensions;

  // Build the TextTheme with Onest for both light and dark themes
  TextTheme _buildTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge!.copyWith(
        fontWeight: FontWeight.w900, // Black
      ),
      displayMedium: base.displayMedium!.copyWith(
        fontWeight: FontWeight.w800, // ExtraBold
      ),
      displaySmall: base.displaySmall!.copyWith(
        fontWeight: FontWeight.w700, // Bold
      ),
      headlineLarge: base.headlineLarge!.copyWith(
        fontWeight: FontWeight.w700, // Bold
      ),
      headlineMedium: base.headlineMedium!.copyWith(
        fontWeight: FontWeight.w600, // SemiBold
      ),
      headlineSmall: base.headlineSmall!.copyWith(
        fontWeight: FontWeight.w600, // SemiBold
      ),
      titleLarge: base.titleLarge!.copyWith(
        fontWeight: FontWeight.w500, // Medium
      ),
      titleMedium: base.titleMedium!.copyWith(
        fontWeight: FontWeight.w500, // Medium
      ),
      titleSmall: base.titleSmall!.copyWith(
        fontWeight: FontWeight.w400, // Regular
      ),
      bodyLarge: base.bodyLarge!.copyWith(
        fontWeight: FontWeight.w400, // Regular
      ),
      bodyMedium: base.bodyMedium!.copyWith(
        fontWeight: FontWeight.w400, // Regular
      ),
      bodySmall: base.bodySmall!.copyWith(
        fontWeight: FontWeight.w300, // Light
      ),
      labelLarge: base.labelLarge!.copyWith(
        fontWeight: FontWeight.w500, // Medium
      ),
      labelMedium: base.labelMedium!.copyWith(
        fontWeight: FontWeight.w400, // Regular
      ),
      labelSmall: base.labelSmall!.copyWith(
        fontWeight: FontWeight.w300, // Light
      ),
    );
  }

  // Build the Light Theme with custom ColorScheme
  ThemeData buildLightThemeWithScheme(ColorScheme colorScheme) {
    final ThemeData base = ThemeData.light(useMaterial3: true);
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
      floatingActionButtonTheme: _fabTheme(colorScheme),
      navigationBarTheme: _navigationBarTheme(colorScheme),
      bottomSheetTheme: _bottomSheetTheme(colorScheme),
      snackBarTheme: _snackBarTheme(colorScheme),
      scaffoldBackgroundColor: colorScheme.surface,
    );
  }

  // Build the Dark Theme with custom ColorScheme
  ThemeData buildDarkThemeWithScheme(ColorScheme colorScheme) {
    final ThemeData base = ThemeData.dark(useMaterial3: true);
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
      floatingActionButtonTheme: _fabTheme(colorScheme),
      navigationBarTheme: _navigationBarTheme(colorScheme),
      bottomSheetTheme: _bottomSheetTheme(colorScheme),
      snackBarTheme: _snackBarTheme(colorScheme),
      scaffoldBackgroundColor: colorScheme.surface,
    );
  }

  // Build theme based on app theme mode
  ThemeData buildThemeWithMode(AppColorTheme appTheme, AppThemeMode themeMode, Brightness systemBrightness) {
    switch (themeMode) {
      case AppThemeMode.light:
        return buildLightThemeWithScheme(appTheme.lightColorScheme());
      case AppThemeMode.dark:
        return buildDarkThemeWithScheme(appTheme.darkColorScheme());
      case AppThemeMode.amoled:
        return buildDarkThemeWithScheme(appTheme.amoledColorScheme());
      case AppThemeMode.system:
        return systemBrightness == Brightness.light
            ? buildLightThemeWithScheme(appTheme.lightColorScheme())
            : buildDarkThemeWithScheme(appTheme.darkColorScheme());
    }
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        textStyle: baseTheme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ).copyWith(
        elevation: WidgetStateProperty.resolveWith<double>((states) {
          if (states.contains(WidgetState.pressed)) {
            return 1;
          }
          return 3;
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.outline),
        backgroundColor: colorScheme.surface,
        textStyle: baseTheme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
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
        color: colorScheme.onSurfaceVariant,
      ),
      hintStyle: baseTheme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      errorStyle: baseTheme.textTheme.bodySmall?.copyWith(
        color: colorScheme.error,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error, width: 2.0),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
    );
  }

  CardThemeData _cardTheme(ThemeData baseTheme, ColorScheme colorScheme) {
    return baseTheme.cardTheme.copyWith(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      color: colorScheme.surfaceContainer,
      surfaceTintColor: colorScheme.surfaceTint,
    );
  }

  DialogThemeData _dialogTheme(ThemeData baseTheme, ColorScheme colorScheme) {
    return baseTheme.dialogTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: colorScheme.surfaceContainerHigh,
      surfaceTintColor: colorScheme.surfaceTint,
      titleTextStyle: baseTheme.textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: baseTheme.textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  ChipThemeData _chipTheme(ThemeData baseTheme, ColorScheme colorScheme) {
    return baseTheme.chipTheme.copyWith(
      backgroundColor: colorScheme.surfaceContainerLow,
      selectedColor: colorScheme.secondaryContainer,
      labelStyle: baseTheme.textTheme.labelLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.12)),
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
        fontWeight: FontWeight.w500,
      ),
      subtitleTextStyle: baseTheme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      iconColor: colorScheme.primary,
      textColor: colorScheme.onSurface,
    );
  }

  FloatingActionButtonThemeData _fabTheme(ColorScheme colorScheme) {
    return FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
    );
  }

  NavigationBarThemeData _navigationBarTheme(ColorScheme colorScheme) {
    return NavigationBarThemeData(
      backgroundColor: colorScheme.surfaceContainer,
      surfaceTintColor: colorScheme.surfaceTint,
      indicatorColor: colorScheme.secondaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w500);
        }
        return TextStyle(color: colorScheme.onSurfaceVariant);
      }),
    );
  }

  BottomSheetThemeData _bottomSheetTheme(ColorScheme colorScheme) {
    return BottomSheetThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    );
  }

  SnackBarThemeData _snackBarTheme(ColorScheme colorScheme) {
    return SnackBarThemeData(
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    );
  }
}
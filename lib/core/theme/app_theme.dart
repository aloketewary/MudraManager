import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  // Build the Theme based on ColorScheme
  ThemeData buildTheme(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final isAmoled = isDark && colorScheme.surface == Colors.black;

    final textTheme = _buildTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    ).apply(fontFamily: 'Onest');

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      fontFamily: 'Onest',
      appBarTheme: _appBarTheme(colorScheme, textTheme, colorScheme.brightness),
      elevatedButtonTheme: _elevatedButtonTheme(colorScheme, textTheme),
      outlinedButtonTheme: _outlinedButtonTheme(colorScheme, textTheme),
      filledButtonTheme: _filledButtonTheme(colorScheme, textTheme),
      textButtonTheme: _textButtonTheme(colorScheme, textTheme),
      inputDecorationTheme: _inputDecorationTheme(colorScheme, textTheme),
      cardTheme: _cardTheme(colorScheme),
      dialogTheme: _dialogTheme(colorScheme, textTheme),
      chipTheme: _chipTheme(colorScheme, textTheme),
      tabBarTheme: _tabBarTheme(colorScheme),
      tooltipTheme: _tooltipTheme(colorScheme, textTheme),
      listTileTheme: _listTileTheme(colorScheme, textTheme),
      floatingActionButtonTheme: _fabTheme(colorScheme),
      navigationBarTheme: _navigationBarTheme(colorScheme, textTheme),
      bottomNavigationBarTheme: _bottomNavTheme(colorScheme, textTheme),
      scaffoldBackgroundColor: isAmoled ? Colors.black : colorScheme.surface,
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      extensions: extensions,
    );
  }

  // --- Component Theme Builders (Refactored to accept ColorScheme) ---

  AppBarThemeData _appBarTheme(
    ColorScheme colorScheme,
    TextTheme textTheme,
    Brightness brightness,
  ) {
    return AppBarThemeData(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 22,
        color: colorScheme.onSurface,
        letterSpacing: 0,
      ),
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: colorScheme.onSurface, size: 24),
      actionsIconTheme: IconThemeData(color: colorScheme.onSurface, size: 24),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: brightness,
        statusBarIconBrightness:
            brightness == Brightness.light ? Brightness.dark : Brightness.light,
      ),
    );
  }

  FilledButtonThemeData _filledButtonTheme(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  TextButtonThemeData _textButtonTheme(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        foregroundColor: colorScheme.primary,
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  FloatingActionButtonThemeData _fabTheme(ColorScheme colorScheme) {
    return FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  NavigationBarThemeData _navigationBarTheme(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return NavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.secondaryContainer,
      labelTextStyle: WidgetStateProperty.all(
        textTheme.labelSmall?.copyWith(color: colorScheme.onSurface),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: colorScheme.onSecondaryContainer);
        }
        return IconThemeData(color: colorScheme.onSurfaceVariant);
      }),
    );
  }

  BottomNavigationBarThemeData _bottomNavTheme(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return BottomNavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
      selectedLabelStyle: textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: textTheme.labelSmall,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    );
  }

  ElevatedButtonThemeData _elevatedButtonTheme(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 1,
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  OutlinedButtonThemeData _outlinedButtonTheme(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.outline),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  InputDecorationTheme _inputDecorationTheme(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return InputDecorationTheme(
      labelStyle: textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      errorStyle: textTheme.bodySmall?.copyWith(color: colorScheme.error),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
    );
  }

  CardThemeData _cardTheme(ColorScheme colorScheme) {
    return CardThemeData(
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

  DialogThemeData _dialogTheme(ColorScheme colorScheme, TextTheme textTheme) {
    return DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: colorScheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.headlineSmall?.copyWith(
        color: colorScheme.onSurface,
      ),
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  ChipThemeData _chipTheme(ColorScheme colorScheme, TextTheme textTheme) {
    return ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      selectedColor: colorScheme.secondaryContainer,
      labelStyle: textTheme.labelLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide.none,
    );
  }

  TabBarThemeData _tabBarTheme(ColorScheme colorScheme) {
    return TabBarThemeData(
      labelColor: colorScheme.primary,
      unselectedLabelColor: colorScheme.onSurfaceVariant,
      indicatorSize: TabBarIndicatorSize.label,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: colorScheme.primary, width: 3),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  TooltipThemeData _tooltipTheme(ColorScheme colorScheme, TextTheme textTheme) {
    return TooltipThemeData(
      decoration: BoxDecoration(
        color: colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: textTheme.bodySmall?.copyWith(
        color: colorScheme.onInverseSurface,
      ),
    );
  }

  ListTileThemeData _listTileTheme(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return ListTileThemeData(
      titleTextStyle: textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      subtitleTextStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      iconColor: colorScheme.onSurfaceVariant,
      textColor: colorScheme.onSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}

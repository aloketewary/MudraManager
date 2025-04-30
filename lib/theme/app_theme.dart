import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._(this.extensions);

  static final AppTheme instance = AppTheme._([]);

  // static ThemeData get lightTheme {
  //   return ThemeData(
  //     useMaterial3: true,
  //     brightness: Brightness.light,
  //     fontFamily: 'Tuffy',
  //     colorScheme: ColorScheme.light(
  //       primary: Colors.blueGrey.shade800,
  //       secondary: Colors.teal.shade400,
  //       surface: Colors.white60,
  //       onPrimary: Colors.white,
  //       onSecondary: Colors.white,
  //       onSurface: Colors.black87,
  //     ),
  //     scaffoldBackgroundColor: Colors.white60,
  //     appBarTheme: AppBarTheme(
  //       backgroundColor: Colors.blueGrey.shade800,
  //       foregroundColor: Colors.white,
  //       elevation: 0,
  //     ),
  //     floatingActionButtonTheme: FloatingActionButtonThemeData(
  //       backgroundColor: Colors.teal.shade400,
  //       foregroundColor: Colors.white,
  //     ),
  //     bottomNavigationBarTheme: BottomNavigationBarThemeData(
  //       selectedItemColor: Colors.teal.shade400,
  //       unselectedItemColor: Colors.blueGrey.shade400,
  //       backgroundColor: Colors.white,
  //       showUnselectedLabels: true,
  //     ),
  //     textTheme: const TextTheme(
  //       headlineMedium: TextStyle(fontWeight: FontWeight.bold),
  //       bodyLarge: TextStyle(color: Colors.black87),
  //       bodyMedium: TextStyle(color: Colors.black54),
  //     ),
  //     inputDecorationTheme: InputDecorationTheme(
  //       filled: true,
  //       fillColor: const Color(0xFFF1F3F4),
  //       border: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(12),
  //         borderSide: BorderSide.none,
  //       ),
  //     ),
  //   );
  // }
  //
  // static ThemeData get darkTheme {
  //   return ThemeData(
  //     useMaterial3: true,
  //     brightness: Brightness.dark,
  //     fontFamily: 'Onest',
  //     colorScheme: ColorScheme.dark(
  //       primary: Colors.blueGrey.shade200,
  //       secondary: Colors.tealAccent.shade400,
  //       surface: Colors.blueGrey.shade900,
  //       onPrimary: Colors.black,
  //       onSecondary: Colors.black,
  //       onSurface: Colors.white70,
  //       onPrimaryContainer: Colors.white,
  //       onSecondaryContainer: Colors.white70,
  //     ),
  //     scaffoldBackgroundColor: Colors.blueGrey.shade900,
  //     appBarTheme: AppBarTheme(
  //       backgroundColor: Colors.blueGrey.shade900,
  //       foregroundColor: Colors.white,
  //       elevation: 0,
  //     ),
  //     floatingActionButtonTheme: FloatingActionButtonThemeData(
  //       backgroundColor: Colors.tealAccent.shade400,
  //       foregroundColor: Colors.black,
  //     ),
  //     bottomNavigationBarTheme: BottomNavigationBarThemeData(
  //       selectedItemColor: Colors.tealAccent.shade400,
  //       unselectedItemColor: Colors.blueGrey.shade300,
  //       backgroundColor: const Color(0xFF1E1E1E),
  //       showUnselectedLabels: true,
  //     ),
  //     textTheme: const TextTheme(
  //       headlineMedium: TextStyle(fontWeight: FontWeight.bold),
  //       bodyLarge: TextStyle(color: Colors.white70),
  //       bodyMedium: TextStyle(color: Colors.white38),
  //     ),
  //     inputDecorationTheme: InputDecorationTheme(
  //       filled: true,
  //       fillColor: const Color(0xFF2C2C2C),
  //       border: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(12),
  //         borderSide: BorderSide.none,
  //       ),
  //     ),
  //   );
  // }

  final Iterable<ThemeExtension<dynamic>>? extensions;

  // Define your primary color scheme for Light Theme
  ColorScheme lightColorScheme = ColorScheme(
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

  ColorScheme darkColorScheme = ColorScheme(
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
  ThemeData buildLightTheme() {
    final ThemeData base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: lightColorScheme,
      textTheme: _buildTextTheme(base.textTheme),
      primaryTextTheme: _buildTextTheme(base.primaryTextTheme),
      appBarTheme: _appBarTheme(base, lightColorScheme, Brightness.light),
      buttonTheme: _buttonTheme(base, lightColorScheme),
      elevatedButtonTheme: _elevatedButtonTheme(base, lightColorScheme),
      outlinedButtonTheme: _outlinedButtonTheme(base, lightColorScheme),
      inputDecorationTheme: _inputDecorationTheme(base, lightColorScheme),
      cardTheme: _cardTheme(base, lightColorScheme),
      dialogTheme: _dialogTheme(base, lightColorScheme),
    );
  }

  // Build the Dark Theme
  ThemeData buildDarkTheme() {
    final ThemeData base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: darkColorScheme,
      textTheme: _buildTextTheme(base.textTheme),
      primaryTextTheme: _buildTextTheme(base.primaryTextTheme),
      appBarTheme: _appBarTheme(base, darkColorScheme, Brightness.light),
      buttonTheme: _buttonTheme(base, darkColorScheme),
      elevatedButtonTheme: _elevatedButtonTheme(base, darkColorScheme),
      outlinedButtonTheme: _outlinedButtonTheme(base, darkColorScheme),
      inputDecorationTheme: _inputDecorationTheme(base, darkColorScheme),
      cardTheme: _cardTheme(base, darkColorScheme),
      dialogTheme: _dialogTheme(base, darkColorScheme),
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
}

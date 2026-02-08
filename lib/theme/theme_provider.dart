import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/theme/app_color_theme_enum.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dynamic_color/dynamic_color.dart';

final dynamicColorProvider = FutureProvider<dynamic>((ref) async {
  try {
    final corePalette = await DynamicColorPlugin.getCorePalette();
    return corePalette;
  } catch (e) {
    return null;
  }
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

final appThemeModeProvider = StateNotifierProvider<AppThemeModeNotifier, AppThemeMode>(
  (ref) => AppThemeModeNotifier(),
);

final themeNotifierProvider =
    StateNotifierProvider<ThemeNotifier, AppColorTheme>(
      (ref) => ThemeNotifier(),
    );

enum AppThemeMode { system, light, dark, amoled }

class AppThemeModeNotifier extends StateNotifier<AppThemeMode> {
  static const _key = 'app_theme_mode';

  AppThemeModeNotifier() : super(AppThemeMode.system) {
    _load();
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString(_key) ?? 'system';
    state = AppThemeMode.values.firstWhere(
      (mode) => mode.name == theme,
      orElse: () => AppThemeMode.system,
    );
  }

  Future<void> setTheme(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    state = mode;
    await prefs.setString(_key, mode.name);
  }
}

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _key = 'theme_mode';

  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString(_key);

    if (theme == 'light') {
      state = ThemeMode.light;
    } else if (theme == 'dark') {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.system;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    state = mode;
    await prefs.setString(_key, mode.name);
  }
}

class ThemeNotifier extends StateNotifier<AppColorTheme> {
  ThemeNotifier() : super(AppColorTheme.financial) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('selected_theme') ?? 0;
    if (index < AppColorTheme.values.length) {
      state = AppColorTheme.values[index];
    }
  }

  Future<void> setTheme(AppColorTheme theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_theme', theme.index);
  }
}

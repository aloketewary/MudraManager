import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/theme/app_color_theme_enum.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark, amoled }

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, AppThemeMode>(
      (ref) => ThemeModeNotifier(),
    );

final themeNotifierProvider =
    StateNotifierProvider<ThemeNotifier, AppColorTheme>(
      (ref) => ThemeNotifier(),
    );

class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  static const _key = 'theme_mode';

  ThemeModeNotifier() : super(AppThemeMode.system) {
    _load();
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString(_key);

    state = AppThemeMode.values.firstWhere(
      (e) => e.name == theme,
      orElse: () => AppThemeMode.system,
    );
  }

  Future<void> setTheme(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    state = mode;
    await prefs.setString(_key, mode.name);
  }
}

class ThemeNotifier extends StateNotifier<AppColorTheme> {
  ThemeNotifier() : super(AppColorTheme.dynamic) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('selected_theme') ?? 0;
    state = AppColorTheme.values[index];
  }

  Future<void> setTheme(AppColorTheme theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_theme', theme.index);
  }
}

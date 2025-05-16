import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/theme/app_color_theme_enum.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

final themeNotifierProvider =
    StateNotifierProvider<ThemeNotifier, AppColorTheme>(
      (ref) => ThemeNotifier(),
    );

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
    await prefs.setString(_key, mode.name); // 'light', 'dark', 'system'
  }
}

class ThemeNotifier extends StateNotifier<AppColorTheme> {
  ThemeNotifier() : super(AppColorTheme.ocean) {
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

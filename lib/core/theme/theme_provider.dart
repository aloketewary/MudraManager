import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';

enum AppThemeMode { system, light, dark, amoled }

final highContrastModeProvider =
    StateNotifierProvider<HighContrastNotifier, bool>(
  (ref) => HighContrastNotifier(),
);

class HighContrastNotifier extends StateNotifier<bool> {
  HighContrastNotifier() : super(false) {
    state = SharedPrefsUtil.instance.getHighContrastMode();
  }

  void toggle() {
    state = !state;
    SharedPrefsUtil.instance.setHighContrastMode(state);
  }

  void set(bool value) {
    state = value;
    SharedPrefsUtil.instance.setHighContrastMode(value);
  }
}

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
  static const _key = 'selected_theme';

  ThemeNotifier() : super(AppColorTheme.finance) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_key);
    if (name != null) {
      state = AppColorTheme.values.firstWhere(
        (e) => e.name == name,
        orElse: () => AppColorTheme.finance,
      );
    }
  }

  Future<void> setTheme(AppColorTheme theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, theme.name);
  }

  /// Revert to free theme when Pro expires.
  Future<void> enforceFreeTheme() async {
    if (state.isPro) {
      await setTheme(AppColorTheme.finance);
    }
  }
}

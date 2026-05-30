import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/skin/converter/skin_to_theme.dart';
import 'package:mudra_manager/core/skin/model/skin.dart';
import 'package:mudra_manager/core/skin/repository/skin_repository.dart';
import 'package:mudra_manager/core/theme/theme_provider.dart';

/// Provides the list of all available builtin skins.
final skinCatalogProvider = FutureProvider<List<Skin>>((ref) async {
  return SkinRepository.instance.loadBuiltinSkins();
});

/// Provides the currently active resolved skin (base + user overrides).
final activeSkinProvider = AsyncNotifierProvider<ActiveSkinNotifier, Skin>(
  ActiveSkinNotifier.new,
);

class ActiveSkinNotifier extends AsyncNotifier<Skin> {
  @override
  Future<Skin> build() async {
    return SkinRepository.instance.resolveActive();
  }

  /// Switch to a different skin.
  Future<void> setSkin(String skinId) async {
    await SkinRepository.instance.setActiveSkinId(skinId);
    state = AsyncData(await SkinRepository.instance.resolve(skinId));
  }

  /// Apply a user override to the current skin.
  Future<void> applyOverride(SkinOverride override) async {
    await SkinRepository.instance.saveOverride(override);
    state = AsyncData(await SkinRepository.instance.resolve(override.baseSkinId));
  }

  /// Reset current skin to its default (remove overrides).
  Future<void> resetToDefault() async {
    final skinId = SkinRepository.instance.getActiveSkinId();
    await SkinRepository.instance.clearOverride(skinId);
    state = AsyncData(await SkinRepository.instance.resolve(skinId));
  }

  /// Enforce free skin if user loses pro access.
  Future<void> enforceFree() async {
    final current = state.value;
    if (current != null && current.tier == SkinTier.pro) {
      await setSkin('finance');
    }
  }
}

/// Provides the resolved ColorScheme for the active skin + theme mode.
/// Use this in place of the old `appColorTheme.lightColorScheme()` etc.
final skinColorSchemeProvider = Provider.family<ColorScheme, AppThemeMode>(
  (ref, mode) {
    final skin = ref.watch(activeSkinProvider).value;
    if (skin == null) {
      // Fallback while loading
      return ColorScheme.fromSeed(
        seedColor: const Color(0xFF10B981),
        brightness:
            mode == AppThemeMode.light ? Brightness.light : Brightness.dark,
      );
    }
    return SkinToTheme.colorScheme(skin, mode);
  },
);

/// Provides the SkinStyle for the active skin (for components that need radii etc).
final skinStyleProvider = Provider<SkinStyle>((ref) {
  final skinAsync = ref.watch(activeSkinProvider);
  final style = skinAsync.value?.style ?? const SkinStyle();
  return style;
});

/// Whether the active skin supports "dynamic" (wallpaper-based) colors.
/// Only the special "dynamic" skin ID uses device colors.
final isDynamicSkinProvider = Provider<bool>((ref) {
  final skin = ref.watch(activeSkinProvider).value;
  return skin?.id == 'dynamic';
});

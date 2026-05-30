import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:mudra_manager/core/skin/model/skin.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';

/// Loads bundled skins from assets and persists user overrides.
class SkinRepository {
  SkinRepository._();
  static final instance = SkinRepository._();

  static const _overrideKey = 'skin_overrides';
  static const _activeSkinKey = 'active_skin_id';

  List<Skin>? _builtinCache;

  /// All bundled skin IDs (order matters for picker display).
  static const builtinSkinIds = [
    'finance',
    'classic',
    'bento',
    'paper',
    'ink',
    'sakura',
    'copper',
    'arctic',
    'vapor',
    'luminescent',
    'terminal',
    'calm',
    'brutalist',
    'noir',
  ];

  /// Loads all bundled skins from assets.
  Future<List<Skin>> loadBuiltinSkins() async {
    if (_builtinCache != null) return _builtinCache!;

    final skins = <Skin>[];
    for (final id in builtinSkinIds) {
      final jsonStr = await rootBundle.loadString('assets/skins/$id.json');
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      skins.add(Skin.fromJson(json));
    }
    _builtinCache = skins;
    return skins;
  }

  /// Gets a single builtin skin by ID.
  Future<Skin?> getBuiltinSkin(String id) async {
    final skins = await loadBuiltinSkins();
    return skins.where((s) => s.id == id).firstOrNull;
  }

  /// Gets the active skin ID from prefs.
  String getActiveSkinId() {
    return SharedPrefsUtil.instance.getString(_activeSkinKey) ?? 'finance';
  }

  /// Sets the active skin ID.
  Future<void> setActiveSkinId(String id) async {
    await SharedPrefsUtil.instance.setString(_activeSkinKey, id);
  }

  /// Gets the user override for a specific skin (if any).
  SkinOverride? getOverride(String skinId) {
    final raw = SharedPrefsUtil.instance.getString('${_overrideKey}_$skinId');
    if (raw == null || raw.isEmpty) return null;
    return SkinOverride.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Saves a user override for a skin.
  Future<void> saveOverride(SkinOverride override) async {
    await SharedPrefsUtil.instance.setString(
      '${_overrideKey}_${override.baseSkinId}',
      jsonEncode(override.toJson()),
    );
  }

  /// Removes user override (resets to default).
  Future<void> clearOverride(String skinId) async {
    await SharedPrefsUtil.instance.setString(
      '${_overrideKey}_$skinId',
      '',
    );
  }

  /// Resolves a skin: base + user override merged.
  Future<Skin> resolve(String skinId) async {
    final base = await getBuiltinSkin(skinId);
    if (base == null) {
      // Fallback to finance if skin not found
      return (await getBuiltinSkin('finance'))!;
    }

    final override = getOverride(skinId);
    if (override == null || override.isEmpty) return base;
    return base.merge(override);
  }

  /// Resolves the currently active skin.
  Future<Skin> resolveActive() async {
    return resolve(getActiveSkinId());
  }
}

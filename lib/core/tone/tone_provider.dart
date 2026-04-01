import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/tone/tone_pack.dart';
import 'package:mudra_manager/core/tone/tone_packs.dart';

const _prefKey = 'selected_tone_pack';

/// All available tone packs.
final allTonePacks = <TonePack>[
  BuddyTonePack(),
  ProfessionalTonePack(),
  PlayfulTonePack(),
  ZenTonePack(),
];

/// Currently selected tone pack provider.
final tonePackProvider = StateNotifierProvider<TonePackNotifier, TonePack>(
  (ref) => TonePackNotifier(),
);

class TonePackNotifier extends StateNotifier<TonePack> {
  TonePackNotifier() : super(_loadFromPrefs());

  static TonePack _loadFromPrefs() {
    final id = SharedPrefsUtil.instance.getString(_prefKey) ?? 'buddy';
    return allTonePacks.firstWhere(
      (t) => t.id == id,
      orElse: () => BuddyTonePack(),
    );
  }

  void select(TonePack pack) {
    SharedPrefsUtil.instance.setString(_prefKey, pack.id);
    state = pack;
  }
}

/// Static accessor for places that can't use ref (services, callbacks).
/// Falls back to Buddy if not initialized.
class Tone {
  Tone._();
  static TonePack _active = BuddyTonePack();

  static TonePack get current => _active;

  /// Call once from a top-level widget that has ref access.
  static void sync(TonePack pack) => _active = pack;
}

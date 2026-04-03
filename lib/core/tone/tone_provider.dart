import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/tone/tone_pack.dart';
import 'package:mudra_manager/core/tone/tone_packs.dart';

const _prefKey = 'selected_tone_pack';

/// All available tone packs.
final allTonePacks = <TonePack>[
  FriendlyTonePack(),
  ProfessionalTonePack(),
  MotivationalTonePack(),
  CalmTonePack(),
];

/// Currently selected tone pack provider.
final tonePackProvider = StateNotifierProvider<TonePackNotifier, TonePack>(
  (ref) => TonePackNotifier(),
);

class TonePackNotifier extends StateNotifier<TonePack> {
  TonePackNotifier() : super(_loadFromPrefs());

  static TonePack _loadFromPrefs() {
    var id = SharedPrefsUtil.instance.getString(_prefKey) ?? 'friendly';
    // Migrate old IDs
    const migration = {
      'buddy': 'friendly',
      'playful': 'motivational',
      'zen': 'calm',
    };
    if (migration.containsKey(id)) {
      id = migration[id]!;
      SharedPrefsUtil.instance.setString(_prefKey, id);
    }
    return allTonePacks.firstWhere(
      (t) => t.id == id,
      orElse: () => FriendlyTonePack(),
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
  static TonePack _active = FriendlyTonePack();

  static TonePack get current => _active;

  /// Call once from a top-level widget that has ref access.
  static void sync(TonePack pack) => _active = pack;
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/tone/tone_l10n.dart';
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
final tonePackProvider = NotifierProvider<TonePackNotifier, TonePack>(
  TonePackNotifier.new,
);

class TonePackNotifier extends Notifier<TonePack> {
  @override
  TonePack build() => _loadFromPrefs();

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
  static ToneL10n? _l10n;

  static TonePack get current => _active;
  static ToneL10n? get l10n => _l10n;
  static AppLocalizations? get appL10n => _l10n != null ? _appL10n : null;
  static AppLocalizations? _appL10n;

  /// Call once from a top-level widget that has ref access.
  static void sync(TonePack pack) => _active = pack;

  /// Call from a context that has AppLocalizations (e.g. MaterialApp builder).
  static void syncL10n(AppLocalizations l10n) {
    _appL10n = l10n;
    _l10n = ToneL10n(l10n, _active.id);
  }
}

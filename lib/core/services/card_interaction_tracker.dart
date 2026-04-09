import 'dart:convert';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';

class CardInteractionTracker {
  static const _key = 'card_interactions';

  static Map<String, _CardStats> _load() {
    final raw = SharedPrefsUtil.instance.getString(_key);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, _CardStats.fromJson(v)));
  }

  static void _save(Map<String, _CardStats> data) {
    SharedPrefsUtil.instance.setString(
      _key,
      jsonEncode(data.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  /// Call this when user taps a dashboard card
  static void recordTap(String widgetId) {
    final data = _load();
    final existing =
        data[widgetId] ?? _CardStats(taps: 0, lastTap: DateTime.now());
    data[widgetId] = _CardStats(
      taps: existing.taps + 1,
      lastTap: DateTime.now(),
    );
    _save(data);
  }

  /// Get tap count for a widget (last 30 days only)
  static int getTapCount(String widgetId) {
    final data = _load();
    final stats = data[widgetId];
    if (stats == null) return 0;
    // Decay: ignore taps older than 30 days
    final age = DateTime.now().difference(stats.lastTap).inDays;
    if (age > 30) return 0;
    return stats.taps;
  }

  /// Get all stats
  static Map<String, int> getAllTapCounts() {
    final data = _load();
    final now = DateTime.now();
    return Map.fromEntries(
      data.entries
          .where((e) => now.difference(e.value.lastTap).inDays <= 30)
          .map((e) => MapEntry(e.key, e.value.taps)),
    );
  }
}

class _CardStats {
  final int taps;
  final DateTime lastTap;

  _CardStats({required this.taps, required this.lastTap});

  factory _CardStats.fromJson(Map<String, dynamic> json) => _CardStats(
        taps: json['t'] as int,
        lastTap: DateTime.parse(json['d'] as String),
      );

  Map<String, dynamic> toJson() => {
        't': taps,
        'd': lastTap.toIso8601String(),
      };
}

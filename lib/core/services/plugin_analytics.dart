import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PluginAnalytics {
  static const _storageKey = 'plugin_analytics';

  final Map<String, int> _eventCounts = {};
  final Map<String, int> _errorCounts = {};
  final Map<String, String> _disabledReasons = {};
  bool _loaded = false;

  /// Load persisted analytics. Call once at startup.
  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      final data = json.decode(raw) as Map<String, dynamic>;
      _eventCounts.addAll(
        (data['events'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as int)) ??
            {},
      );
      _errorCounts.addAll(
        (data['errors'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as int)) ??
            {},
      );
      _disabledReasons.addAll(
        (data['disabled'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as String)) ??
            {},
      );
    }
    _loaded = true;
  }

  Future<void> _flush() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _storageKey,
        json.encode({
          'events': _eventCounts,
          'errors': _errorCounts,
          'disabled': _disabledReasons,
        }));
  }

  void trackEvent(String pluginId, String eventType) {
    final key = '$pluginId:$eventType';
    _eventCounts[key] = (_eventCounts[key] ?? 0) + 1;
    _flush(); // fire-and-forget
  }

  void trackError(String pluginId) {
    _errorCounts[pluginId] = (_errorCounts[pluginId] ?? 0) + 1;
    _flush();
  }

  void trackDisabled(String pluginId, String reason) {
    _disabledReasons[pluginId] = reason;
    _flush();
  }

  void clearDisabled(String pluginId) {
    _disabledReasons.remove(pluginId);
    _flush();
  }

  int getEventCount(String pluginId, String eventType) {
    return _eventCounts['$pluginId:$eventType'] ?? 0;
  }

  int getErrorCount(String pluginId) {
    return _errorCounts[pluginId] ?? 0;
  }

  String? getDisabledReason(String pluginId) {
    return _disabledReasons[pluginId];
  }

  Map<String, int> getPluginStats(String pluginId) {
    return {
      'sms': getEventCount(pluginId, 'sms'),
      'expense': getEventCount(pluginId, 'expense'),
      'budget': getEventCount(pluginId, 'budget'),
      'goal': getEventCount(pluginId, 'goal'),
      'income': getEventCount(pluginId, 'income'),
      'transfer': getEventCount(pluginId, 'transfer'),
      'recurring': getEventCount(pluginId, 'recurring'),
      'low_balance': getEventCount(pluginId, 'low_balance'),
      'daily_summary': getEventCount(pluginId, 'daily_summary'),
      'transaction_saved': getEventCount(pluginId, 'transaction_saved'),
      'errors': getErrorCount(pluginId),
    };
  }

  int getTotalEvents(String pluginId) {
    return _eventCounts.entries
        .where((e) => e.key.startsWith('$pluginId:'))
        .fold(0, (sum, e) => sum + e.value);
  }

  Future<void> resetPlugin(String pluginId) async {
    _eventCounts.removeWhere((k, _) => k.startsWith('$pluginId:'));
    _errorCounts.remove(pluginId);
    _disabledReasons.remove(pluginId);
    await _flush();
  }

  Future<void> reset() async {
    _eventCounts.clear();
    _errorCounts.clear();
    _disabledReasons.clear();
    await _flush();
  }
}

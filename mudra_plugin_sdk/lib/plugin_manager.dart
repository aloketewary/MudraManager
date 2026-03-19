import 'package:mudra_plugin_sdk/rule_engine.dart';

import 'plugin.dart';
import 'events.dart';

typedef PluginErrorCallback = void Function(String pluginId, Object error);
typedef PluginDisabledCallback = void Function(String pluginId, String reason);

enum PluginPriority { low, normal, high, critical }

class _CircuitBreaker {
  final int maxFailures;
  final Duration cooldown;

  int _failures = 0;
  DateTime? _trippedAt;

  _CircuitBreaker({
    this.maxFailures = 3,
    this.cooldown = const Duration(minutes: 5),
  });

  bool get isTripped => _trippedAt != null;

  bool get canRetry {
    if (_trippedAt == null) return true;
    return DateTime.now().difference(_trippedAt!) >= cooldown;
  }

  bool allowExecution() {
    if (!isTripped) return true;
    if (canRetry) return true;
    return false;
  }

  void recordSuccess() {
    _failures = 0;
    _trippedAt = null;
  }

  bool recordFailure() {
    _failures++;
    if (_failures >= maxFailures && !isTripped) {
      _trippedAt = DateTime.now();
      return true;
    }
    if (isTripped) {
      _trippedAt = DateTime.now();
    }
    return false;
  }

  void reset() {
    _failures = 0;
    _trippedAt = null;
  }

  int get failureCount => _failures;
}

class PluginManager {
  final Map<String, MudraPlugin> _plugins = {};
  final Map<String, bool> _pluginStatus = {};
  final Map<String, PluginPriority> _pluginPriorities = {};
  final Map<String, _CircuitBreaker> _breakers = {};

  PluginErrorCallback? onError;
  PluginDisabledCallback? onPluginDisabled;

  int maxFailures;
  Duration cooldown;

  PluginManager({
    this.maxFailures = 3,
    this.cooldown = const Duration(minutes: 5),
  });

  // --- register / unregister / start / stop / disposeAll ---
  void register(
    MudraPlugin plugin, {
    PluginPriority priority = PluginPriority.normal,
  }) {
    if (_plugins.containsKey(plugin.id)) {
      throw Exception('Plugin ${plugin.id} already registered');
    }
    _plugins[plugin.id] = plugin;
    _pluginStatus[plugin.id] = false;
    _pluginPriorities[plugin.id] = priority;
    _breakers[plugin.id] = _CircuitBreaker(
      maxFailures: maxFailures,
      cooldown: cooldown,
    );
    plugin.onLoad();
  }

  Future<void> unregister(String pluginId) async {
    final plugin = _plugins[pluginId];
    if (plugin != null) {
      if (_pluginStatus[pluginId] == true) {
        plugin.onStop();
      }
      await plugin.dispose();
    }
    _plugins.remove(pluginId);
    _pluginStatus.remove(pluginId);
    _pluginPriorities.remove(pluginId);
    _breakers.remove(pluginId);
  }

  void start() {
    for (final plugin in _plugins.values) {
      plugin.onStart();
      _pluginStatus[plugin.id] = true;
    }
  }

  void stop() {
    for (final plugin in _plugins.values) {
      if (_pluginStatus[plugin.id] == true) {
        plugin.onStop();
      }
      _pluginStatus[plugin.id] = false;
    }
  }

  Future<void> disposeAll() async {
    stop();
    for (final plugin in _plugins.values) {
      await plugin.dispose();
    }
    _plugins.clear();
    _pluginStatus.clear();
    _pluginPriorities.clear();
    _breakers.clear();
  }

  bool isPluginActive(String pluginId) => _pluginStatus[pluginId] ?? false;

  bool isPluginTripped(String pluginId) =>
      _breakers[pluginId]?.isTripped ?? false;

  void resetBreaker(String pluginId) => _breakers[pluginId]?.reset();

  Map<String, int> getFailureCounts() => {
    for (final entry in _breakers.entries) entry.key: entry.value.failureCount,
  };

  List<MudraPlugin> getActivePlugins() {
    final active = _plugins.values
        .where((p) => _pluginStatus[p.id] == true)
        .toList();
    active.sort((a, b) {
      final priorityA = _pluginPriorities[a.id] ?? PluginPriority.normal;
      final priorityB = _pluginPriorities[b.id] ?? PluginPriority.normal;
      return priorityB.index.compareTo(priorityA.index);
    });
    return active;
  }

  MudraPlugin? getPlugin(String pluginId) => _plugins[pluginId];

  int get pluginCount => _plugins.length;

  // ============================================================
  // GENERIC DISPATCH — replaces all individual emit* methods
  // ============================================================

  /// Emit any event to all active plugins. Collects PluginNotifications
  /// (only TransactionSavedEvent produces them).
  List<PluginNotification> emit(PluginEvent event) {
    final notifications = <PluginNotification>[];
    for (final p in getActivePlugins()) {
      final breaker = _breakers[p.id];
      if (breaker == null || !breaker.allowExecution()) continue;

      try {
        final notif = p.handleEvent(event);
        if (notif != null) notifications.add(notif);
        _processRules(p, event.eventType, event.toMap());
        breaker.recordSuccess();
      } catch (error) {
        onError?.call(p.id, error);
        final justTripped = breaker.recordFailure();
        if (justTripped) {
          onPluginDisabled?.call(
            p.id,
            'Auto-disabled after $maxFailures consecutive errors',
          );
        }
      }
    }
    return notifications;
  }

  /// Async variant for events that need await (e.g. SMS processing).
  Future<List<PluginNotification>> emitAsync(PluginEvent event) async {
    final notifications = <PluginNotification>[];
    for (final p in getActivePlugins()) {
      final breaker = _breakers[p.id];
      if (breaker == null || !breaker.allowExecution()) continue;

      try {
        final notif = p.handleEvent(event);
        if (notif != null) notifications.add(notif);
        _processRules(p, event.eventType, event.toMap());
        breaker.recordSuccess();
      } catch (error) {
        onError?.call(p.id, error);
        final justTripped = breaker.recordFailure();
        if (justTripped) {
          onPluginDisabled?.call(
            p.id,
            'Auto-disabled after $maxFailures consecutive errors',
          );
        }
      }
    }
    return notifications;
  }

  /// Run the plugin's rule engine for the given event.
  void _processRules(
    MudraPlugin plugin,
    String eventType,
    Map<String, dynamic> data,
  ) {
    if (plugin.ruleEngine.rules.isEmpty) return;

    plugin.ruleEngine.onAction ??= (action, params, eventData) {
      switch (action) {
        case RuleAction.notify:
          plugin.api.showNotification(params['text'] ?? 'Rule triggered');
          break;
        case RuleAction.addExpense:
          plugin.api.addExpense(
            (params['amount'] as num?)?.toDouble() ?? 0,
            category: params['category'],
            description: params['description'],
          );
          break;
        case RuleAction.addIncome:
          plugin.api.addIncome(
            (params['amount'] as num?)?.toDouble() ?? 0,
            source: params['source'],
            description: params['description'],
          );
          break;
        case RuleAction.log:
        case RuleAction.custom:
          break;
      }
    };

    plugin.ruleEngine.process(eventType, data);
  }
}

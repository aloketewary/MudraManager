import 'package:mudra_plugin_sdk/plugin_config.dart';

import 'plugin.dart';
import 'events.dart';

typedef PluginErrorCallback = void Function(String pluginId, Object error);

enum PluginPriority { low, normal, high, critical }

class PluginManager {
  final Map<String, MudraPlugin> _plugins = {};
  final Map<String, bool> _pluginStatus = {};
  final Map<String, PluginPriority> _pluginPriorities = {};
  PluginErrorCallback? onError;

  void register(MudraPlugin plugin, {PluginPriority priority = PluginPriority.normal}) {
    if (_plugins.containsKey(plugin.id)) {
      throw Exception('Plugin ${plugin.id} already registered');
    }
    _plugins[plugin.id] = plugin;
    _pluginStatus[plugin.id] = false;
    _pluginPriorities[plugin.id] = priority;
    plugin.onLoad();
  }

  void unregister(String pluginId) {
    final plugin = _plugins[pluginId];
    if (plugin != null) {
      plugin.setConfig(PluginConfig(pluginId, {})); // Clear config
    }
    _plugins.remove(pluginId);
    _pluginStatus.remove(pluginId);
    _pluginPriorities.remove(pluginId);
  }

  void start() {
    for (final plugin in _plugins.values) {
      plugin.onStart();
      _pluginStatus[plugin.id] = true;
    }
  }

  void stop() {
    for (final plugin in _plugins.values) {
      _pluginStatus[plugin.id] = false;
    }
  }

  bool isPluginActive(String pluginId) {
    return _pluginStatus[pluginId] ?? false;
  }

  List<MudraPlugin> getActivePlugins() {
    final active = _plugins.values
        .where((p) => _pluginStatus[p.id] == true)
        .toList();
    
    // Sort by priority
    active.sort((a, b) {
      final priorityA = _pluginPriorities[a.id] ?? PluginPriority.normal;
      final priorityB = _pluginPriorities[b.id] ?? PluginPriority.normal;
      return priorityB.index.compareTo(priorityA.index);
    });
    
    return active;
  }

  MudraPlugin? getPlugin(String pluginId) {
    return _plugins[pluginId];
  }

  int get pluginCount => _plugins.length;

  Future<void> emitSmsAsync(SmsEvent e) async {
    for (final p in getActivePlugins()) {
      try {
        await Future.microtask(() => p.onSms(e));
      } catch (error) {
        onError?.call(p.id, error);
      }
    }
  }

  void emitSms(SmsEvent e) {
    for (final p in getActivePlugins()) {
      try {
        p.onSms(e);
      } catch (error) {
        onError?.call(p.id, error);
      }
    }
  }

  void emitExpense(ExpenseEvent e) {
    for (final p in getActivePlugins()) {
      try {
        p.onExpense(e);
      } catch (error) {
        onError?.call(p.id, error);
      }
    }
  }

  void emitBudget(BudgetEvent e) {
    for (final p in getActivePlugins()) {
      try {
        p.onBudget(e);
      } catch (error) {
        onError?.call(p.id, error);
      }
    }
  }

  void emitGoal(GoalEvent e) {
    for (final p in getActivePlugins()) {
      try {
        p.onGoal(e);
      } catch (error) {
        onError?.call(p.id, error);
      }
    }
  }

  void emitIncome(IncomeEvent e) {
    for (final p in getActivePlugins()) {
      try {
        p.onIncome(e);
      } catch (error) {
        onError?.call(p.id, error);
      }
    }
  }

  void emitTransfer(TransferEvent e) {
    for (final p in getActivePlugins()) {
      try {
        p.onTransfer(e);
      } catch (error) {
        onError?.call(p.id, error);
      }
    }
  }

  void emitRecurring(RecurringEvent e) {
    for (final p in getActivePlugins()) {
      try {
        p.onRecurring(e);
      } catch (error) {
        onError?.call(p.id, error);
      }
    }
  }

  void emitLowBalance(LowBalanceEvent e) {
    for (final p in getActivePlugins()) {
      try {
        p.onLowBalance(e);
      } catch (error) {
        onError?.call(p.id, error);
      }
    }
  }
}

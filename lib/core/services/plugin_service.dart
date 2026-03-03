import 'package:mudra_manager/core/services/mudra_api_impl.dart';
import 'package:mudra_manager/core/services/plugin_analytics.dart';
import 'package:mudra_manager/core/sdk/rule_engine.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/plugins/low_balance_alert_plugin.dart';
import 'package:mudra_manager/plugins/sms_alert_plugin.dart';
import 'package:mudra_manager/plugins/budget_guard_plugin.dart';
import 'package:mudra_manager/plugins/goal_tracker_plugin.dart';
import 'package:mudra_manager/plugins/large_expense_plugin.dart';
import 'package:mudra_manager/plugins/daily_summary_plugin.dart';
import 'package:mudra_manager/plugins/bill_reminder_plugin.dart';
import 'package:mudra_manager/plugins/savings_milestone_plugin.dart';
import 'package:mudra_manager/plugins/category_alert_plugin.dart';
import 'package:mudra_manager/plugins/credit_card_reminder_plugin.dart';
import 'package:mudra_plugin_sdk/mudra_plugin_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mudra_manager/features/marketplace/services/marketplace_service.dart';

class PluginService {
  static final PluginService _instance = PluginService._();
  factory PluginService() => _instance;
  PluginService._();

  final _manager = PluginManager();
  final _ruleEngine = RuleEngine();
  final _api = MudraApiImpl();
  final _analytics = PluginAnalytics();
  final _log = AppLog(getLogger(), 'PluginService');
  final Map<String, MudraPlugin> _availablePlugins = {};
  final Map<String, MudraPlugin> _activePlugins = {}; // Cache active plugins
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return; // Prevent double initialization

    final prefs = await SharedPreferences.getInstance();
    final marketplaceService = MarketplaceService();

    // Set error callback
    _manager.onError = (pluginId, error) {
      _log.e('Plugin $pluginId error', error);
      _analytics.trackError(pluginId);
    };

    // Register all available plugins (lazy loading)
    _registerAvailablePlugins();

    // Load plugin metadata once
    final pluginMetadataList = await marketplaceService.fetchPlugins();

    // Only register enabled plugins
    await _loadEnabledPlugins(prefs, marketplaceService, pluginMetadataList);

    _manager.start();
    _initialized = true;
  }

  void _registerAvailablePlugins() {
    _availablePlugins['com.mudra.sms_alert'] = SmsAlertPlugin();
    _availablePlugins['com.mudra.budget_guard'] = BudgetGuardPlugin();
    _availablePlugins['com.mudra.goal_tracker'] = GoalTrackerPlugin();
    _availablePlugins['com.mudra.large_expense'] = LargeExpensePlugin();
    _availablePlugins['com.mudra.daily_summary'] = DailySummaryPlugin();
    _availablePlugins['com.mudra.bill_reminder'] = BillReminderPlugin();
    _availablePlugins['com.mudra.savings_milestone'] = SavingsMilestonePlugin();
    _availablePlugins['com.mudra.category_alert'] = CategoryAlertPlugin();
    _availablePlugins['com.mudra.low_balance_alert'] = LowBalanceAlertPlugin();
    _availablePlugins['com.mudra.credit_card_reminder'] = CreditCardReminderPlugin();
  }

  Future<void> _loadEnabledPlugins(
    SharedPreferences prefs,
    MarketplaceService marketplaceService,
    List<dynamic> pluginMetadataList,
  ) async {
    for (final entry in _availablePlugins.entries) {
      final enabled = prefs.getBool('plugin_${entry.key}') ?? true;
      if (enabled) {
        entry.value.setApi(_api);

        // Load and set config
        dynamic metadata;
        try {
          metadata = pluginMetadataList.firstWhere((p) => p.id == entry.key);
        } catch (e) {
          metadata = null;
        }

        if (metadata?.configOptions != null) {
          final configMap = <String, dynamic>{};
          for (final option in metadata.configOptions!) {
            final savedValue = await marketplaceService.getPluginConfig(
              entry.key,
              option.key,
            );
            configMap[option.key] = savedValue ?? option.defaultValue;
          }
          entry.value.setConfig(PluginConfig(entry.key, configMap));
        }

        _manager.register(entry.value);
        _activePlugins[entry.key] = entry.value; // Cache active plugins
      }
    }
  }

  void emitSms(String sender, String body) {
    if (_activePlugins.isEmpty) return; // Early exit if no active plugins

    _ruleEngine.process('sms', {'body': body, 'sender': sender});
    _manager.emitSms(SmsEvent(sender, body));

    // Track analytics for active plugins
    for (final pluginId in _activePlugins.keys) {
      _analytics.trackEvent(pluginId, 'sms');
    }
  }

  void emitExpense(String category, double amount, DateTime time) {
    if (_activePlugins.isEmpty) return;

    _ruleEngine.process('expense', {'category': category, 'amount': amount});
    _manager.emitExpense(ExpenseEvent(category, amount, time));

    for (final pluginId in _activePlugins.keys) {
      _analytics.trackEvent(pluginId, 'expense');
    }
  }

  void emitBudget(double used, double limit) {
    if (_activePlugins.isEmpty) return;

    _ruleEngine.process('budget', {'used': used, 'limit': limit});
    _manager.emitBudget(BudgetEvent(used, limit));

    for (final pluginId in _activePlugins.keys) {
      _analytics.trackEvent(pluginId, 'budget');
    }
  }

  void emitGoal(String goalId, bool achieved) {
    _manager.emitGoal(GoalEvent(goalId, achieved));
    for (final plugin in _manager.getActivePlugins()) {
      _analytics.trackEvent(plugin.id, 'goal');
    }
  }

  void emitIncome(String source, double amount, DateTime time) {
    _manager.emitIncome(IncomeEvent(source, amount, time));
    for (final plugin in _manager.getActivePlugins()) {
      _analytics.trackEvent(plugin.id, 'income');
    }
  }

  void emitTransfer(
    String fromAccount,
    String toAccount,
    double amount,
    DateTime time,
  ) {
    _manager.emitTransfer(TransferEvent(fromAccount, toAccount, amount, time));
    for (final plugin in _manager.getActivePlugins()) {
      _analytics.trackEvent(plugin.id, 'transfer');
    }
  }

  void emitRecurring(String name, double amount, String frequency) {
    _manager.emitRecurring(RecurringEvent(name, amount, frequency));
    for (final plugin in _manager.getActivePlugins()) {
      _analytics.trackEvent(plugin.id, 'recurring');
    }
  }

  void emitLowBalance(String accountName, double balance, double threshold) {
    _manager.emitLowBalance(LowBalanceEvent(accountName, balance, threshold));
    for (final plugin in _manager.getActivePlugins()) {
      _analytics.trackEvent(plugin.id, 'low_balance');
    }
  }

  Map<String, int> getPluginStats(String pluginId) {
    return _analytics.getPluginStats(pluginId);
  }

  int get activePluginCount => _activePlugins.length;
  int get totalPluginCount => _availablePlugins.length;
}

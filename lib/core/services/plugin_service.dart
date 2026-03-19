import 'package:mudra_manager/core/services/mudra_api_impl.dart';
import 'package:mudra_manager/core/services/permission_guarded_api.dart';
import 'package:mudra_manager/core/services/plugin_analytics.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/plugins/category_packs/business_pack.dart';
import 'package:mudra_manager/plugins/category_packs/category_pack.dart';
import 'package:mudra_manager/plugins/category_packs/couple_pack.dart';
import 'package:mudra_manager/plugins/category_packs/default_pack.dart';
import 'package:mudra_manager/plugins/category_packs/family_pack.dart';
import 'package:mudra_manager/plugins/category_packs/foodie_pack.dart';
import 'package:mudra_manager/plugins/category_packs/freelancer_pack.dart';
import 'package:mudra_manager/plugins/category_packs/health_pack.dart';
import 'package:mudra_manager/plugins/category_packs/indian_common_pack.dart';
import 'package:mudra_manager/plugins/category_packs/indian_east_pack.dart';
import 'package:mudra_manager/plugins/category_packs/indian_north_pack.dart';
import 'package:mudra_manager/plugins/category_packs/indian_south_pack.dart';
import 'package:mudra_manager/plugins/category_packs/indian_west_pack.dart';
import 'package:mudra_manager/plugins/category_packs/investor_pack.dart';
import 'package:mudra_manager/plugins/category_packs/pet_owner_pack.dart';
import 'package:mudra_manager/plugins/category_packs/student_pack.dart';
import 'package:mudra_manager/plugins/category_packs/traveller_pack.dart';
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
import 'package:mudra_manager/features/marketplace/services/marketplace_service.dart';

class PluginService {
  static final PluginService _instance = PluginService._();
  factory PluginService() => _instance;
  PluginService._();

  final _manager = PluginManager();
  final _marketplace = MarketplaceService();
  final _analytics = PluginAnalytics();
  final _log = AppLog(getLogger(), 'PluginService');
  final Map<String, MudraPlugin> _availablePlugins = {};
  final Map<String, MudraPlugin> _activePlugins = {};
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

// Register all category packs
    _registerCategoryPacks();

    await _analytics.load();
    await _marketplace.loadEnabledStates();

    _manager.onError = (pluginId, error) {
      _log.e('Plugin $pluginId error', error);
      _analytics.trackError(pluginId);
    };

    _manager.onPluginDisabled = (pluginId, reason) {
      _log.w('Plugin $pluginId auto-disabled: $reason');
      _activePlugins.remove(pluginId);
      _analytics.trackDisabled(pluginId, reason);
    };

    _registerAvailablePlugins();

    final pluginMetadataList = await _marketplace.fetchPlugins();
    await _loadEnabledPlugins(pluginMetadataList);

    _manager.start();
    _initialized = true;
  }

  void _registerCategoryPacks() {
    CategoryPackRegistry.register(DefaultPack.instance);
    CategoryPackRegistry.register(StudentPack.instance);
    CategoryPackRegistry.register(FamilyPack.instance);
    CategoryPackRegistry.register(FreelancerPack.instance);
    CategoryPackRegistry.register(FoodiePack.instance);
    CategoryPackRegistry.register(TravellerPack.instance);
    CategoryPackRegistry.register(HealthPack.instance);
    CategoryPackRegistry.register(IndianCommonPack.instance);
    CategoryPackRegistry.register(IndianNorthPack.instance);
    CategoryPackRegistry.register(IndianSouthPack.instance);
    CategoryPackRegistry.register(IndianEastPack.instance);
    CategoryPackRegistry.register(IndianWestPack.instance);
    CategoryPackRegistry.register(BusinessPack.instance);
    CategoryPackRegistry.register(InvestorPack.instance);
    CategoryPackRegistry.register(PetOwnerPack.instance);
    CategoryPackRegistry.register(CouplePack.instance);
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
    _availablePlugins['com.mudra.credit_card_reminder'] =
        CreditCardReminderPlugin();
  }

  Future<void> _loadEnabledPlugins(List<dynamic> pluginMetadataList) async {
    // ... unchanged ...
    for (final entry in _availablePlugins.entries) {
      final enabled = await _marketplace.isPluginEnabled(entry.key);
      if (enabled) {
        final rawApi = MudraApiImpl(entry.key);
        final guardedApi = PermissionGuardedApi(
          rawApi,
          entry.key,
          entry.value.permissions,
        );
        entry.value.setApi(guardedApi);

        dynamic metadata;
        try {
          metadata = pluginMetadataList.firstWhere((p) => p.id == entry.key);
        } catch (e) {
          metadata = null;
        }

        if (metadata?.configOptions != null) {
          final configMap = <String, dynamic>{};
          for (final option in metadata.configOptions!) {
            final savedValue = await _marketplace.getPluginConfig(
              entry.key,
              option.key,
            );
            configMap[option.key] = savedValue ?? option.defaultValue;
          }
          entry.value.setConfig(PluginConfig(entry.key, configMap));
        }

        _manager.register(entry.value);
        _activePlugins[entry.key] = entry.value;
      }
    }
  }

  Future<void> disablePlugin(String pluginId) async {
    if (!_activePlugins.containsKey(pluginId)) return;
    await _manager.unregister(pluginId);
    _activePlugins.remove(pluginId);
    await _marketplace.togglePlugin(pluginId, false);
    _log.i('Plugin $pluginId disabled');
  }

  Future<void> dispose() async {
    await _manager.disposeAll();
    _activePlugins.clear();
    _initialized = false;
    _log.i('All plugins disposed');
  }

  bool isPluginTripped(String pluginId) => _manager.isPluginTripped(pluginId);

  void resetPlugin(String pluginId) {
    _manager.resetBreaker(pluginId);
    _analytics.clearDisabled(pluginId);
    final plugin = _availablePlugins[pluginId];
    if (plugin != null && !_activePlugins.containsKey(pluginId)) {
      _activePlugins[pluginId] = plugin;
    }
    _log.i('Plugin $pluginId circuit breaker reset');
  }

  // ============================================================
  // GENERIC DISPATCH — single entry point
  // ============================================================

  /// Core dispatch. All typed convenience methods funnel through here.
  List<PluginNotification> _emit(PluginEvent event) {
    if (_activePlugins.isEmpty) return [];
    final result = _manager.emit(event);
    for (final pluginId in _activePlugins.keys) {
      _analytics.trackEvent(pluginId, event.eventType);
    }
    return result;
  }

  // --- Thin typed convenience methods (one-liners) ---

  void emitSms(String sender, String body) => _emit(SmsEvent(sender, body));

  void emitExpense(String category, double amount, DateTime time) =>
      _emit(ExpenseEvent(category, amount, time));

  void emitIncome(String source, double amount, DateTime time) =>
      _emit(IncomeEvent(source, amount, time));

  void emitBudget(double used, double limit) => _emit(BudgetEvent(used, limit));

  void emitGoal(String goalId, bool achieved) =>
      _emit(GoalEvent(goalId, achieved));

  void emitTransfer(String from, String to, double amount, DateTime time) =>
      _emit(TransferEvent(from, to, amount, time));

  void emitRecurring(String name, double amount, String frequency) =>
      _emit(RecurringEvent(name, amount, frequency));

  void emitLowBalance(String accountName, double balance, double threshold) =>
      _emit(LowBalanceEvent(accountName, balance, threshold));

  void emitDailySummary() => _emit(DailySummaryEvent(DateTime.now()));

  List<PluginNotification> emitTransactionSaved({
    required double amount,
    required bool isExpense,
    required DateTime date,
    String? category,
    String? account,
    String? description,
    bool isTransfer = false,
  }) =>
      _emit(
        TransactionSavedEvent(
          amount: amount,
          isExpense: isExpense,
          date: date,
          category: category,
          account: account,
          description: description,
          isTransfer: isTransfer,
        ),
      );

  Map<String, int> getPluginStats(String pluginId) =>
      _analytics.getPluginStats(pluginId);

  int get activePluginCount => _activePlugins.length;
  int get totalPluginCount => _availablePlugins.length;
}

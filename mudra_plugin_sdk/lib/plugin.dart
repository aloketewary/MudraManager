import 'events.dart';
import 'api.dart';
import 'plugin_config.dart';
import 'rule_engine.dart';

abstract class MudraPlugin {
  String get id;
  String get name;
  String get version;

  Set<PluginPermission> get permissions => {};

  MudraApi? _api;
  PluginConfig? _config;
  final RuleEngine _ruleEngine = RuleEngine();

  void setApi(MudraApi api) => _api = api;
  MudraApi get api => _api!;

  void setConfig(PluginConfig config) => _config = config;
  PluginConfig? get config => _config;

  RuleEngine get ruleEngine => _ruleEngine;

  void onLoad();
  void onStart();
  void onStop() {}
  Future<void> dispose() async {}

  // --- Typed handlers (plugins override these) ---
  void onSms(SmsEvent event) {}
  void onExpense(ExpenseEvent event) {}
  void onIncome(IncomeEvent event) {}
  void onBudget(BudgetEvent event) {}
  void onGoal(GoalEvent event) {}
  void onTransfer(TransferEvent event) {}
  void onRecurring(RecurringEvent event) {}
  void onLowBalance(LowBalanceEvent event) {}
  void onDailySummary(DailySummaryEvent event) {}
  PluginNotification? onTransactionSaved(TransactionSavedEvent event) => null;

  /// Generic dispatch — routes a PluginEvent to the correct typed handler.
  /// Returns a PluginNotification only for TransactionSavedEvent.
  PluginNotification? handleEvent(PluginEvent event) {
    switch (event) {
      case SmsEvent e:
        onSms(e);
      case ExpenseEvent e:
        onExpense(e);
      case IncomeEvent e:
        onIncome(e);
      case BudgetEvent e:
        onBudget(e);
      case GoalEvent e:
        onGoal(e);
      case TransferEvent e:
        onTransfer(e);
      case RecurringEvent e:
        onRecurring(e);
      case LowBalanceEvent e:
        onLowBalance(e);
      case DailySummaryEvent e:
        onDailySummary(e);
      case TransactionSavedEvent e:
        return onTransactionSaved(e);
    }
    return null;
  }
}

class PluginNotification {
  final String title;
  final String body;
  final int priority;

  PluginNotification({
    required this.title,
    required this.body,
    this.priority = 3,
  });
}

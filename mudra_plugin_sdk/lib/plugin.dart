import 'events.dart';
import 'api.dart';
import 'plugin_config.dart';

abstract class MudraPlugin {
  String get id;
  String get name;
  String get version;

  MudraApi? _api;
  PluginConfig? _config;

  void setApi(MudraApi api) => _api = api;
  MudraApi get api => _api!;

  void setConfig(PluginConfig config) => _config = config;
  PluginConfig? get config => _config;

  void onLoad();
  void onStart();

  void onSms(SmsEvent event) {}
  void onExpense(ExpenseEvent event) {}
  void onIncome(IncomeEvent event) {}
  void onBudget(BudgetEvent event) {}
  void onGoal(GoalEvent event) {}
  void onTransfer(TransferEvent event) {}
  void onRecurring(RecurringEvent event) {}
  void onLowBalance(LowBalanceEvent event) {}
  void onDailySummary(DailySummaryEvent event) {}
}

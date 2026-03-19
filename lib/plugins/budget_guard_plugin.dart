import 'package:mudra_plugin_sdk/mudra_plugin_sdk.dart';

class BudgetGuardPlugin extends MudraPlugin {
  @override
  String get id => 'com.mudra.budget_guard';

  @override
  String get name => 'Budget Guard';

  @override
  String get version => '1.2.0';

  @override
  void onBudget(BudgetEvent event) {
    final warningThreshold = config?.get<double>('warning_threshold') ?? 0.9;
    final percentage = event.used / event.limit;

    if (event.used > event.limit) {
      api.showNotification(
        '🚨 Budget exceeded by ₹${(event.used - event.limit).toStringAsFixed(0)}',
      );
    } else if (percentage >= warningThreshold) {
      api.showNotification(
        '⚠️ Budget at ${(percentage * 100).toStringAsFixed(0)}%',
      );
    }
  }

  @override
  void onExpense(ExpenseEvent event) {
    final largeExpenseThreshold =
        config?.get<double>('large_expense') ?? 5000.0;
    if (event.amount > largeExpenseThreshold) {
      api.showNotification(
        '💸 Large expense: ₹${event.amount.toStringAsFixed(0)}',
      );
    }
  }

  @override
  void onLoad() {}

  @override
  void onStart() {}

  @override
  Set<PluginPermission> get permissions => {
        PluginPermission.notifications,
      };
}

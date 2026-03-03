import 'package:mudra_plugin_sdk/mudra_plugin_sdk.dart';

class BudgetGuardPlugin extends MudraPlugin {
  @override
  String get id => 'com.mudra.budget_guard';

  @override
  String get name => 'Budget Guard';

  @override
  String get version => '1.2.0';

  @override
  void onBudget(BudgetEvent e) {
    final warningThreshold = config?.get<double>('warning_threshold') ?? 0.9;
    final percentage = e.used / e.limit;
    
    if (e.used > e.limit) {
      api.showNotification('🚨 Budget exceeded by ₹${(e.used - e.limit).toStringAsFixed(0)}');
    } else if (percentage >= warningThreshold) {
      api.showNotification('⚠️ Budget at ${(percentage * 100).toStringAsFixed(0)}%');
    }
  }

  @override
  void onExpense(ExpenseEvent e) {
    final largeExpenseThreshold = config?.get<double>('large_expense') ?? 5000.0;
    if (e.amount > largeExpenseThreshold) {
      api.showNotification('💸 Large expense: ₹${e.amount.toStringAsFixed(0)}');
    }
  }

  @override
  void onLoad() {}
  
  @override
  void onStart() {}
}

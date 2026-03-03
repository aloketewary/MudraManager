import 'package:mudra_plugin_sdk/mudra_plugin_sdk.dart';

class LargeExpensePlugin extends MudraPlugin {
  @override
  String get id => 'com.mudra.large_expense';

  @override
  String get name => 'Large Expense Alert';

  @override
  String get version => '1.1.0';

  @override
  void onExpense(ExpenseEvent event) {
    final threshold = config?.get<double>('threshold') ?? 1000.0;
    if (event.amount > threshold) {
      api.showNotification('💸 Large expense: ₹${event.amount.toStringAsFixed(0)} in ${event.category}');
    }
  }

  @override
  void onLoad() {}
  
  @override
  void onStart() {}
}

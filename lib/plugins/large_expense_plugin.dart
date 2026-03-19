import 'package:mudra_plugin_sdk/mudra_plugin_sdk.dart';

class LargeExpensePlugin extends MudraPlugin {
  @override
  String get id => 'com.mudra.large_expense';

  @override
  String get name => 'Large Expense Alert';

  @override
  String get version => '1.2.0';

  @override
  void onExpense(ExpenseEvent event) {
    final threshold = config?.get<double>('threshold') ?? 1000.0;
    if (event.amount > threshold) {
      api.showNotification(
        '💸 Large expense: ₹${event.amount.toStringAsFixed(0)} in ${event.category}',
      );
    }
  }

  @override
  PluginNotification? onTransactionSaved(TransactionSavedEvent event) {
    if (!event.isExpense) return null;
    final threshold = config?.get<double>('threshold') ?? 1000.0;
    if (event.amount < threshold) return null;
    return PluginNotification(
      title:
          '₹${event.amount.toStringAsFixed(2)} on ${event.category ?? "something"} — just making sure you meant to',
      body:
          'You spent ₹${event.amount.toStringAsFixed(2)} on ${event.category ?? "Unknown"}',
      priority: 4,
    );
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

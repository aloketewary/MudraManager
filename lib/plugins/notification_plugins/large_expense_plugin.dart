import 'package:mudra_manager/plugins/notification_plugin.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';

class LargeExpensePlugin extends NotificationPlugin {
  @override
  String get id => 'com.mudra.large_expense';

  @override
  String get name => 'Large Expense Alert';

  @override
  String get description => 'Get notified for expenses over threshold';

  @override
  String get version => '1.1.0';

  @override
  String get iconPath => 'assets/logo/file/default.svg';

  @override
  bool shouldTrigger(Transaction transaction) {
    if (!transaction.isExpense) return false;
    final threshold = _getThreshold();
    return transaction.amount >= threshold;
  }

  @override
  String getTitle(Transaction transaction) {
    return '₹${transaction.amount.toStringAsFixed(2)} on ${transaction.category.value?.name ?? "something"} — just making sure you meant to';
  }

  @override
  String getBody(Transaction transaction) {
    return 'You spent ₹${transaction.amount.toStringAsFixed(2)} on ${transaction.category.value?.name ?? "Unknown"}';
  }

  @override
  int getPriority() => 4;

  double _getThreshold() {
    // Get from plugin config, default to 1000
    return 1000.0;
  }
}

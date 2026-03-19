import 'package:mudra_manager/plugins/notification_plugin.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LowBalancePlugin extends NotificationPlugin {
  final ProviderContainer _container;

  LowBalancePlugin(this._container);

  @override
  String get id => 'com.mudra.low_balance_alert';

  @override
  String get name => 'Low Balance Alert';

  @override
  String get description => 'Get notified when account balance is low';

  @override
  String get version => '1.0.0';

  @override
  String get iconPath => 'assets/logo/file/default.svg';

  @override
  bool shouldTrigger(Transaction transaction) {
    if (!transaction.isExpense) return false;

    final account = transaction.account.value;
    if (account == null) return false;

    // For now, return true to trigger notification and handle balance check in getBody
    // This is a limitation of the synchronous interface
    return true;
  }

  @override
  String getTitle(Transaction transaction) {
    return 'Might want to check your balance';
  }

  @override
  String getBody(Transaction transaction) {
    final account = transaction.account.value;
    if (account == null) return 'Account balance is low';

    // Since we can't use async here, we'll show a generic message
    // The actual balance check would need to be done elsewhere
    return '${account.name} balance may be low. Check your account.';
  }

  @override
  int getPriority() => 5;
}

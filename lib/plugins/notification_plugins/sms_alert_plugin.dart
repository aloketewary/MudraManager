import 'package:mudra_manager/plugins/notification_plugin.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';

class SmsAlertPlugin extends NotificationPlugin {
  @override
  String get id => 'com.mudra.sms_alert';

  @override
  String get name => 'SMS Alert';

  @override
  String get description => 'Get notified when money is credited via SMS';

  @override
  String get version => '1.1.0';

  @override
  String get iconPath => 'assets/logo/file/default.svg';

  @override
  bool shouldTrigger(Transaction transaction) {
    // Only trigger for income from SMS
    return !transaction.isExpense && (transaction.isFromSms ?? false);
  }

  @override
  String getTitle(Transaction transaction) {
    return '₹${transaction.amount.toStringAsFixed(2)} just landed in ${transaction.account.value?.name ?? "your account"}';
  }

  @override
  String getBody(Transaction transaction) {
    return '₹${transaction.amount.toStringAsFixed(2)} credited to ${transaction.account.value?.name ?? "your account"}';
  }

  @override
  int getPriority() => 5;
}

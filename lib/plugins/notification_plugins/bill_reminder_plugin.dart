import 'package:mudra_manager/plugins/notification_plugin.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';

class BillReminderPlugin extends NotificationPlugin {
  @override
  String get id => 'com.mudra.bill_reminder';

  @override
  String get name => 'Bill Reminder';

  @override
  String get description => 'Never miss recurring bill payments';

  @override
  String get version => '1.0.0';

  @override
  String get iconPath => 'assets/logo/file/default.svg';

  @override
  bool shouldTrigger(Transaction transaction) {
    // This plugin is triggered by a scheduled job for recurring transactions
    return false;
  }

  @override
  String getTitle(Transaction transaction) {
    return 'You\'ve got a payment due soon';
  }

  @override
  String getBody(Transaction transaction) {
    return 'Upcoming bill payment reminder';
  }

  @override
  int getPriority() => 4;
}

import 'package:mudra_manager/plugins/notification_plugin.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';

class DailySummaryPlugin extends NotificationPlugin {
  @override
  String get id => 'com.mudra.daily_summary';

  @override
  String get name => 'Daily Summary';

  @override
  String get description => 'Daily spending summary notifications';

  @override
  String get version => '1.0.0';

  @override
  String get iconPath => 'assets/logo/file/default.svg';

  @override
  bool shouldTrigger(Transaction transaction) {
    // This plugin is triggered by a scheduled job, not per transaction
    return false;
  }

  @override
  String getTitle(Transaction transaction) {
    return '📊 Daily Summary';
  }

  @override
  String getBody(Transaction transaction) {
    return 'Your daily spending summary is ready';
  }

  @override
  int getPriority() => 2;
}

import 'notification_plugin.dart';
import 'notification_plugins/large_expense_plugin.dart';
import 'notification_plugins/sms_alert_plugin.dart';
import 'notification_plugins/daily_summary_plugin.dart';
import 'notification_plugins/bill_reminder_plugin.dart';
import 'notification_plugins/low_balance_plugin.dart';
import 'package:mudra_manager/features/marketplace/services/marketplace_service.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';

class NotificationPluginManager {
  static final NotificationPluginManager _instance = NotificationPluginManager._();
  static NotificationPluginManager get instance => _instance;

  final Map<String, NotificationPlugin> _allPlugins = {};
  final _marketplaceService = MarketplaceService();

  NotificationPluginManager._() {
    _registerAllPlugins();
  }

  void _registerAllPlugins() {
    final plugins = [
      SmsAlertPlugin(),
      LargeExpensePlugin(),
      DailySummaryPlugin(),
      BillReminderPlugin(),
      LowBalancePlugin(),
    ];

    for (final plugin in plugins) {
      _allPlugins[plugin.id] = plugin;
      plugin.onLoad();
      plugin.onStart();
    }
  }

  Future<List<NotificationPlugin>> _getEnabledPlugins() async {
    final enabled = <NotificationPlugin>[];
    for (final entry in _allPlugins.entries) {
      if (await _marketplaceService.isPluginEnabled(entry.key)) {
        enabled.add(entry.value);
      }
    }
    return enabled;
  }

  Future<List<NotificationData>> processTransaction(Transaction transaction) async {
    final enabledPlugins = await _getEnabledPlugins();
    final notifications = <NotificationData>[];

    for (final plugin in enabledPlugins) {
      if (plugin.shouldTrigger(transaction)) {
        notifications.add(NotificationData(
          title: plugin.getTitle(transaction),
          body: plugin.getBody(transaction),
          priority: plugin.getPriority(),
          pluginId: plugin.id,
        ));
      }
    }

    return notifications;
  }

  List<NotificationPlugin> getAllPlugins() {
    return List.unmodifiable(_allPlugins.values);
  }
}

class NotificationData {
  final String title;
  final String body;
  final int priority;
  final String pluginId;

  NotificationData({
    required this.title,
    required this.body,
    required this.priority,
    required this.pluginId,
  });
}

import 'package:flutter/foundation.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/features/account/data/balance_history_service.dart';
import 'package:mudra_manager/features/budget/data/bill_service.dart';
import 'package:mudra_manager/features/dashboard/data/summary_scheduler.dart';
import 'package:mudra_manager/features/gamification/services/gamification_service.dart';
import 'package:mudra_manager/features/notifications/data/smart_notification_service.dart';
import 'package:mudra_manager/features/sms/data/sms_cleanup_service.dart';
import 'package:mudra_manager/features/transactions/data/recurring_transaction_service.dart';
import 'package:workmanager/workmanager.dart';

class BackgroundTaskManager {
  static const String _dailyTaskName = 'dailyBackgroundTask';
  static final AppLog _log = AppLog(getLogger(), 'BackgroundTaskManager');

  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);
    await _scheduleDailyTask();
    await _runAllTasks();
  }

  static Future<void> _scheduleDailyTask() async {
    try {
      await Workmanager().registerPeriodicTask(
        _dailyTaskName,
        _dailyTaskName,
        frequency: const Duration(hours: 6),
        constraints: Constraints(
          networkType: NetworkType.notRequired,
        ),
      );
      _log.i('Daily background task scheduled');
    } catch (e) {
      _log.e('Failed to schedule background task', e);
    }
  }

  static Future<void> _runAllTasks() async {
    try {
      final isar = await IsarService().getInstance();
      final gamificationService = GamificationService(
        isar,
        AppLog(getLogger(), 'GamificationService'),
      );

      // Run sequentially to avoid concurrent write transaction stalls
      await RecurringTransactionService(IsarService(), gamificationService)
          .processRecurringTransactions();
      await SummaryScheduler.checkAndShowSummaries();
      // Bill reminders handled by SmartNotificationService.checkUpcomingBills()
      // with proper dedup — don't fire raw notifications here.
      await BillService.createPendingTransactionsForDueBills();
      await BalanceHistoryService.instance.recordDailySnapshots();
      await SmartNotificationService.instance.runSmartChecks();
      await SmsHashCleanupService.cleanupOldHashes();

      _log.i('All background tasks completed');
    } catch (e) {
      _log.e('Background tasks failed', e);
    }
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await BackgroundTaskManager._runAllTasks();
      return true;
    } catch (e) {
      debugPrint('Background task execution failed: $e');
      return false;
    }
  });
}

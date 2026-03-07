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
    // Run tasks immediately on app start
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
      final isarService = IsarService();
      final isar = await isarService.getInstance();
      final gamificationService = GamificationService(isar, AppLog(getLogger(), 'GamificationService'));

      await Future.wait([
        // Process recurring transactions
        RecurringTransactionService(isarService, gamificationService).processRecurringTransactions(),
        // Check and show summaries
        SummaryScheduler.checkAndShowSummaries(),
        // Bill reminders and pending transactions
        BillService.scheduleBillReminders(),
        BillService.createPendingTransactionsForDueBills(),
        // Record daily balance snapshots
        BalanceHistoryService.instance.recordDailySnapshots(),
        // Run smart notification checks
        SmartNotificationService.instance.runSmartChecks(),
        // Cleanup old SMS hashes
        SmsHashCleanupService.cleanupOldHashes(),
      ]);

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

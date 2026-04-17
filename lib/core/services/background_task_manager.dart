import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/services/category_rule_service.dart';
import 'package:mudra_manager/core/utils/error_tracker.dart';
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

  /// Call at app start — only schedules workmanager, no heavy work.
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);
    await _scheduleDailyTask();
    _log.i('Background task manager initialized');
  }

  /// Call after UI is visible — only notifications and cleanup, no heavy processing.
  static Future<void> runDeferredTasks() async {
    try {
      await BalanceHistoryService.instance.recordDailySnapshots();
      await SummaryScheduler.checkAndShowSummaries();
      await SmartNotificationService.instance.runSmartChecks();
      await SmsHashCleanupService.cleanupOldHashes();

      _log.i('Deferred tasks completed');
    } catch (e) {
      _log.e('Deferred tasks failed', e);
    }
  }

  /// Call when user opens recurring/bill screens — processes due items on demand.
  static Future<void> processRecurringNow() async {
    try {
      final isar = await IsarService().getInstance();
      final gamificationService = GamificationService(
        isar,
        AppLog(getLogger(), 'GamificationService'),
      );
      await RecurringTransactionService(IsarService(), gamificationService)
          .processRecurringTransactions();
      await BillService.createPendingTransactionsForDueBills();
      _log.i('On-demand recurring processing completed');
    } catch (e) {
      _log.e('On-demand recurring processing failed', e);
    }
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
    } catch (e) {
      _log.e('Failed to schedule background task', e);
    }
  }

  /// Full task run — used by workmanager callback only.
  static Future<void> _runAllTasks() async {
    try {
      final isar = await IsarService().getInstance();
      final gamificationService = GamificationService(
        isar,
        AppLog(getLogger(), 'GamificationService'),
      );

      await RecurringTransactionService(IsarService(), gamificationService)
          .processRecurringTransactions();
      await BillService.createPendingTransactionsForDueBills();
      await BalanceHistoryService.instance.recordDailySnapshots();
      await SummaryScheduler.checkAndShowSummaries();
      await SmartNotificationService.instance.runSmartChecks();
      await SmsHashCleanupService.cleanupOldHashes();
      await CategoryRuleService(isar).cleanupOldRules();

      _log.i('All background tasks completed');
    } catch (e) {
      _log.e('Background tasks failed', e);
      ErrorTracker.record('background_task', 'runAllTasks failed', e);
    }
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await BackgroundTaskManager._runAllTasks();
      return true;
    } catch (_) {
      return false;
    }
  });
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:isar/isar.dart';
import 'package:mudra_manager/db/isar_service.dart';
import 'package:mudra_manager/db/models/budget.dart';
import 'package:mudra_manager/db/models/notification_record.dart';
import 'package:mudra_manager/db/models/transaction.dart';

class BudgetAlertService {
  final IsarService isarService;
  final FlutterLocalNotificationsPlugin notificationsPlugin;

  BudgetAlertService(this.isarService, this.notificationsPlugin);

  Future<List<BudgetAlert>> checkBudgetsAfterTransaction(Transaction transaction) async {
    if (!transaction.isExpense || transaction.isTransfer) return [];

    final isar = await isarService.getInstance();
    final now = DateTime.now();
    final alerts = <BudgetAlert>[];

    final budgets = await isar.budgets
        .filter()
        .isArchivedEqualTo(false)
        .findAll();

    for (final budget in budgets) {
      await budget.categories.load();
      await budget.allocations.load();

      final categoryIds = budget.categories.map((c) => c.id).toList();
      if (transaction.category.value == null || 
          !categoryIds.contains(transaction.category.value!.id)) {
        continue;
      }

      final (start, end) = budget.getCurrentPeriodRange(now);
      final spent = await _calculateSpent(isar, budget, start, end);
      final percentage = (spent / budget.amount) * 100;

      final threshold = _getThreshold(percentage);
      if (threshold != null) {
        final alreadyNotified = await _hasNotified(isar, budget.id, threshold, start);
        if (!alreadyNotified) {
          final alert = BudgetAlert(
            budget: budget,
            spent: spent,
            percentage: percentage,
            threshold: threshold,
          );
          alerts.add(alert);
          await _sendNotification(alert);
          await _saveNotificationRecord(isar, budget.id, threshold, start, end);
        }
      }
    }

    return alerts;
  }

  Future<double> _calculateSpent(Isar isar, Budget budget, DateTime start, DateTime end) async {
    final categoryIds = budget.categories.map((c) => c.id).toList();
    final transactions = await isar.transactions
        .filter()
        .isExpenseEqualTo(true)
        .dateBetween(start, end)
        .findAll();

    return transactions
        .where((t) => t.category.value != null && categoryIds.contains(t.category.value!.id))
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  int? _getThreshold(double percentage) {
    if (percentage >= 100 && percentage < 105) return 100;
    if (percentage >= 90 && percentage < 100) return 90;
    if (percentage >= 80 && percentage < 90) return 80;
    return null;
  }

  Future<bool> _hasNotified(Isar isar, int budgetId, int threshold, DateTime periodStart) async {
    final existing = await isar.notificationRecords
        .filter()
        .typeContains('budget_alert_${budgetId}_$threshold')
        .timestampGreaterThan(periodStart)
        .findFirst();
    return existing != null;
  }

  Future<void> _sendNotification(BudgetAlert alert) async {
    final title = alert.threshold == 100
        ? '🚨 Budget Exceeded!'
        : alert.threshold == 90
            ? '⚠️ Budget Alert: 90%'
            : '⚠️ Budget Alert: 80%';

    final body = '${alert.budget.name}: ₹${alert.spent.toStringAsFixed(0)} / ₹${alert.budget.amount.toStringAsFixed(0)} (${alert.percentage.toStringAsFixed(1)}%)';

    await notificationsPlugin.show(
      alert.budget.id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'budget_alerts',
          'Budget Alerts',
          channelDescription: 'Notifications for budget thresholds',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> _saveNotificationRecord(Isar isar, int budgetId, int threshold, DateTime start, DateTime end) async {
    final record = NotificationRecord()
      ..title = 'Budget Alert'
      ..body = 'Budget threshold $threshold% reached'
      ..type = 'budget_alert_${budgetId}_$threshold'
      ..timestamp = DateTime.now()
      ..isRead = false;

    await isar.writeTxn(() async {
      await isar.notificationRecords.put(record);
    });
  }
}

class BudgetAlert {
  final Budget budget;
  final double spent;
  final double percentage;
  final int threshold;

  BudgetAlert({
    required this.budget,
    required this.spent,
    required this.percentage,
    required this.threshold,
  });
}

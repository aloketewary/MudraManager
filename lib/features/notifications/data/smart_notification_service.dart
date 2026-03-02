import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/sms_activity.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';

class SmartNotificationService {
  static final SmartNotificationService instance = SmartNotificationService._();
  static final AppLog _log = AppLog(getLogger(), 'SmartNotificationService');

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  SmartNotificationService._();

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notifications.initialize(settings);
    _initialized = true;
    _log.i('Smart notifications initialized');
  }

  Future<void> checkBudgetAlerts() async {
    final isar = await IsarService.initIsar();
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final budgets = await isar.budgets.where().findAll();
    final budgetsToUpdate = <Budget>[];

    for (final budget in budgets) {
      await budget.categories.load();
      final categoryList = budget.categories.toList();
      if (categoryList.isEmpty) continue;

      for (final category in categoryList) {
        final transactions = await isar.transactions
            .where()
            .filter()
            .dateBetween(startOfMonth, endOfMonth)
            .and()
            .isExpenseEqualTo(true)
            .and()
            .category((q) => q.idEqualTo(category.id))
            .findAll();

        final totalSpent =
            transactions.fold<double>(0, (sum, tx) => sum + tx.amount);
        final percentage = (totalSpent / budget.amount) * 100;

        if (percentage >= 100 && !budget.notifiedAt100) {
          await _sendBudgetAlert(category.name, totalSpent, budget.amount, 100);
          budget.notifiedAt100 = true;
          budgetsToUpdate.add(budget);
        } else if (percentage >= 90 && !budget.notifiedAt90) {
          await _sendBudgetAlert(category.name, totalSpent, budget.amount, 90);
          budget.notifiedAt90 = true;
          budgetsToUpdate.add(budget);
        } else if (percentage >= 80 && !budget.notifiedAt80) {
          await _sendBudgetAlert(category.name, totalSpent, budget.amount, 80);
          budget.notifiedAt80 = true;
          budgetsToUpdate.add(budget);
        }
      }
    }

    if (budgetsToUpdate.isNotEmpty) {
      await isar.writeTxn(() => isar.budgets.putAll(budgetsToUpdate));
    }
  }

  Future<void> _sendBudgetAlert(
      String category, double spent, double budget, int percentage) async {
    await _notifications.show(
      percentage.hashCode,
      '⚠️ Budget Alert: $category',
      'You\'ve spent ₹${spent.toStringAsFixed(0)} of ₹${budget.toStringAsFixed(0)} ($percentage%)',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'budget_alerts',
          'Budget Alerts',
          channelDescription: 'Notifications when budget limits are reached',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
    _log.i('Budget alert sent: $category at $percentage%');
  }

  Future<void> checkPendingSmsTransactions() async {
    final isar = await IsarService.initIsar();

    final pendingCount = await isar.smsActivitys
        .filter()
        .statusEqualTo(ActivityStatus.pending)
        .or()
        .statusEqualTo(ActivityStatus.needsReview)
        .or()
        .statusEqualTo(ActivityStatus.duplicate)
        .count();

    if (pendingCount > 0) {
      await _notifications.show(
        'pending_sms'.hashCode,
        '📱 $pendingCount Pending Transactions',
        'You have $pendingCount SMS transactions waiting for review',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'pending_transactions',
            'Pending Transactions',
            channelDescription: 'Notifications for pending SMS transactions',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
      _log.i('Pending SMS notification sent: $pendingCount transactions');
    }
  }

  Future<void> checkUpcomingBills() async {
    final isar = await IsarService.initIsar();
    final now = DateTime.now();
    final threeDaysFromNow = now.add(const Duration(days: 3));

    final recurringTransactions = await isar.recurringTransactions
        .filter()
        .isActiveEqualTo(true)
        .findAll();

    for (final recurring in recurringTransactions) {
      final dueDate = recurring.nextDueDate;
      if (dueDate.isAfter(now) && dueDate.isBefore(threeDaysFromNow)) {
        final daysUntil = dueDate.difference(now).inDays;
        await _sendBillReminder(
            recurring.description ?? 'Bill', recurring.amount, daysUntil);
      }
    }
  }

  Future<void> _sendBillReminder(
      String description, double amount, int daysUntil) async {
    await _notifications.show(
      description.hashCode,
      '📅 Upcoming Bill: $description',
      '₹${amount.toStringAsFixed(0)} due in $daysUntil day${daysUntil == 1 ? '' : 's'}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'bill_reminders',
          'Bill Reminders',
          channelDescription: 'Reminders for upcoming recurring bills',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
    _log.i('Bill reminder sent: $description');
  }

  Future<void> checkUnusualSpending() async {
    final isar = await IsarService.initIsar();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayTransactions = await isar.transactions
        .where()
        .filter()
        .dateBetween(today, now)
        .and()
        .isExpenseEqualTo(true)
        .findAll();

    final todaySpending =
        todayTransactions.fold<double>(0, (sum, tx) => sum + tx.amount);

    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final pastTransactions = await isar.transactions
        .where()
        .filter()
        .dateBetween(thirtyDaysAgo, yesterday)
        .and()
        .isExpenseEqualTo(true)
        .findAll();

    if (pastTransactions.isEmpty) return;

    final totalPastSpending =
        pastTransactions.fold<double>(0, (sum, tx) => sum + tx.amount);
    final avgDailySpending = totalPastSpending / 30;

    if (todaySpending > avgDailySpending * 2) {
      await _notifications.show(
        'unusual_spending'.hashCode,
        '💸 Unusual Spending Detected',
        'You\'ve spent ₹${todaySpending.toStringAsFixed(0)} today (avg: ₹${avgDailySpending.toStringAsFixed(0)})',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'unusual_spending',
            'Unusual Spending',
            channelDescription: 'Alerts for unusual spending patterns',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
      _log.i(
          'Unusual spending alert sent: ₹$todaySpending vs avg ₹$avgDailySpending');
    }
  }

  Future<void> runSmartChecks() async {
    await initialize();
    await checkBudgetAlerts();
    await checkPendingSmsTransactions();
    await checkUpcomingBills();
    await checkUnusualSpending();
    _log.i('All smart checks completed');
  }
}

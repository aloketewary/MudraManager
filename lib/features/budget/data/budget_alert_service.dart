import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/singleton_providers.dart';
import 'package:mudra_manager/features/notifications/data/smart_notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final budgetAlertServiceProvider = Provider<BudgetAlertService>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  final notificationService = ref.watch(smartNotificationServiceProvider);
  return BudgetAlertService(isarService, notificationService);
});

class BudgetAlertService {
  final IsarService isarService;
  final SmartNotificationService _notificationService;

  BudgetAlertService(this.isarService, this._notificationService);

  Future<List<BudgetAlert>> checkBudgetsOnDashboardLoad() async {
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

      final (start, end) = budget.getCurrentPeriodRange(now);
      final spent = await _calculateSpent(isar, budget, start, end);
      final percentage = (spent / budget.amount) * 100;

      // Check if alert thresholds exceeded
      if (percentage >= 100 && !budget.notifiedAt100) {
        alerts.add(BudgetAlert(
          budget: budget, spent: spent,
          percentage: percentage, threshold: 100,
        ),);
        budget.notifiedAt100 = true;
        await isar.writeTxn(() => isar.budgets.put(budget));
      } else if (percentage >= 90 && !budget.notifiedAt90 && !budget.notifiedAt100) {
        alerts.add(BudgetAlert(
          budget: budget, spent: spent,
          percentage: percentage, threshold: 90,
        ),);
        budget.notifiedAt90 = true;
        await isar.writeTxn(() => isar.budgets.put(budget));
      } else if (percentage >= 80 && !budget.notifiedAt80 && !budget.notifiedAt90) {
        alerts.add(BudgetAlert(
          budget: budget, spent: spent,
          percentage: percentage, threshold: 80,
        ),);
        budget.notifiedAt80 = true;
        await isar.writeTxn(() => isar.budgets.put(budget));
      }
    }

    return alerts;
  }

  Future<List<BudgetAlert>> checkBudgetsAfterTransaction(
    Transaction transaction,
  ) async {
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

      if (percentage >= 100 && !budget.notifiedAt100) {
        alerts.add(BudgetAlert(
          budget: budget, spent: spent,
          percentage: percentage, threshold: 100,
        ),);
        budget.notifiedAt100 = true;
        await isar.writeTxn(() => isar.budgets.put(budget));
      } else if (percentage >= 90 && !budget.notifiedAt90 && !budget.notifiedAt100) {
        alerts.add(BudgetAlert(
          budget: budget, spent: spent,
          percentage: percentage, threshold: 90,
        ),);
        budget.notifiedAt90 = true;
        await isar.writeTxn(() => isar.budgets.put(budget));
      } else if (percentage >= 80 && !budget.notifiedAt80 && !budget.notifiedAt90) {
        alerts.add(BudgetAlert(
          budget: budget, spent: spent,
          percentage: percentage, threshold: 80,
        ),);
        budget.notifiedAt80 = true;
        await isar.writeTxn(() => isar.budgets.put(budget));
      }
    }

    if (alerts.isNotEmpty) {
      await _sendNotification(alerts);
    }

    return alerts;
  }

  Future<double> _calculateSpent(
    Isar isar, Budget budget, DateTime start, DateTime end,
  ) async {
    final categoryIds = budget.categories.map((c) => c.id).toList();
    final transactions = await isar.transactions
        .filter()
        .isExpenseEqualTo(true)
        .dateBetween(start, end)
        .findAll();

    for (final t in transactions) {
      await t.category.load();
    }

    return transactions
        .where((t) =>
            t.category.value != null &&
            categoryIds.contains(t.category.value!.id),)
        .fold<double>(0.0, (sum, t) => sum + t.baseAmount);
  }

  /// Routes through SmartNotificationService for in-app record + OS notification.
  Future<void> _sendNotification(List<BudgetAlert> alerts) async {
    final exceeded = alerts.where((a) => a.threshold == 100).toList();
    final warnings = alerts.where((a) => a.threshold != 100).toList();

    if (exceeded.isNotEmpty) {
      await _notificationService.notifyBudgetExceeded(
        names: exceeded.map((a) => a.budget.name).toList(),
        spent: exceeded.first.spent,
        limit: exceeded.first.budget.amount,
      );
    }

    if (warnings.isNotEmpty) {
      await _notificationService.notifyBudgetWarning(
        names: warnings.map((a) => a.budget.name).toList(),
        percentage: warnings.first.percentage,
      );
    }
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

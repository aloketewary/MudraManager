import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/services/notification_service.dart';

class BudgetAlertService {
  final IsarService isarService;

  BudgetAlertService(this.isarService);

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

    return transactions
        .where((t) =>
            t.category.value != null &&
            categoryIds.contains(t.category.value!.id),)
        .fold<double>(0.0, (sum, t) => sum + t.baseAmount);
  }

  /// Routes through NotificationService gateway — single grouped notification.
  Future<void> _sendNotification(List<BudgetAlert> alerts) async {
    final exceeded = alerts.where((a) => a.threshold == 100).toList();
    final warnings = alerts.where((a) => a.threshold != 100).toList();

    if (exceeded.isNotEmpty) {
      final n = exceeded.length;
      final names = exceeded.map((a) => a.budget.name).join(', ');
      await NotificationService.showLocalNotification(
        id: 9000,
        title: '🚨 $n budget${n > 1 ? 's' : ''} exceeded!',
        body: n == 1
            ? '${exceeded.first.budget.name}: ${formatCurrency(exceeded.first.spent, code: BaseCurrency.code)} / ${formatCurrency(exceeded.first.budget.amount, code: BaseCurrency.code)}'
            : '$names are over budget',
        dedupKey: 'budget_exceeded',
      );
    }

    if (warnings.isNotEmpty) {
      final n = warnings.length;
      final names = warnings.map((a) => a.budget.name).join(', ');
      await NotificationService.showLocalNotification(
        id: 9001,
        title: '⚠️ $n budget${n > 1 ? 's' : ''} near limit',
        body: n == 1
            ? '${warnings.first.budget.name}: ${warnings.first.percentage.toStringAsFixed(0)}% used'
            : '$names are nearing their limits',
        dedupKey: 'budget_warning',
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

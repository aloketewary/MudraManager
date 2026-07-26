import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/budget_type.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/singleton_providers.dart';
import 'package:mudra_manager/core/utils/budget_spent_calculator.dart';
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
      final alert = await _evaluateBudget(isar, budget, now);
      if (alert != null) alerts.add(alert);
    }

    return alerts;
  }

  Future<List<BudgetAlert>> checkBudgetsAfterTransaction(
    Transaction transaction,
  ) async {
    if (!transaction.affectsStats || !transaction.isExpense) return [];

    final isar = await isarService.getInstance();
    final now = DateTime.now();
    final alerts = <BudgetAlert>[];

    final budgets = await isar.budgets
        .filter()
        .isArchivedEqualTo(false)
        .findAll();

    for (final budget in budgets) {
      await budget.categories.load();

      // Only re-check budgets this transaction could plausibly affect —
      // skip category-wise budgets that clearly don't include this
      // transaction's category (tag/day/festival/travel budgets are always
      // re-checked since matching requires loading tags/period anyway).
      if (budget.budgetType == BudgetType.categoryWise) {
        final categoryIds = budget.categories.map((c) => c.id).toSet();
        final catId = transaction.category.value?.id;
        if (catId == null || !categoryIds.contains(catId)) {
          // Could still match via parent category — check that before skipping.
          await transaction.category.value?.parentCategory.load();
          final parentId =
              transaction.category.value?.parentCategory.value?.id;
          if (parentId == null || !categoryIds.contains(parentId)) {
            continue;
          }
        }
      }

      final alert = await _evaluateBudget(isar, budget, now);
      if (alert != null) alerts.add(alert);
    }

    if (alerts.isNotEmpty) {
      await _sendNotification(alerts);
    }

    return alerts;
  }

  /// Evaluates a single budget's spend against alert thresholds, persists
  /// the notified-flag transitions (including resetting them once spend
  /// drops back under 80%, so recurring budgets can alert again next
  /// period), and returns an alert if a new threshold was just crossed.
  Future<BudgetAlert?> _evaluateBudget(
    Isar isar,
    Budget budget,
    DateTime now,
  ) async {
    if (budget.amount <= 0) return null;

    // Skip non-recurring budgets whose period has already ended.
    if (budget.recurrence == BudgetRecurrence.none &&
        budget.endDate
            .isBefore(DateTime(now.year, now.month, now.day, 23, 59, 59))) {
      return null;
    }

    final (start, end) = budget.getCurrentPeriodRange(now);
    final spent = await BudgetSpentCalculator.calculate(isar, budget, start, end);
    final percentage = (spent / budget.amount) * 100;

    // Reset flags once spend drops back below the lowest threshold — lets
    // a recurring budget alert again in a fresh period (or after a
    // limit increase).
    if (percentage < 80 &&
        (budget.notifiedAt80 || budget.notifiedAt90 || budget.notifiedAt100)) {
      budget.notifiedAt80 = false;
      budget.notifiedAt90 = false;
      budget.notifiedAt100 = false;
      await isar.writeTxn(() => isar.budgets.put(budget));
    }

    BudgetAlert? alert;
    int? threshold;
    if (percentage >= 100 && !budget.notifiedAt100) {
      threshold = 100;
      budget.notifiedAt100 = true;
    } else if (percentage >= 90 && !budget.notifiedAt90 && !budget.notifiedAt100) {
      threshold = 90;
      budget.notifiedAt90 = true;
    } else if (percentage >= 80 && !budget.notifiedAt80 && !budget.notifiedAt90) {
      threshold = 80;
      budget.notifiedAt80 = true;
    }

    if (threshold != null) {
      alert = BudgetAlert(
        budget: budget,
        spent: spent,
        percentage: percentage,
        threshold: threshold,
      );
      await isar.writeTxn(() => isar.budgets.put(budget));
    }

    return alert;
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

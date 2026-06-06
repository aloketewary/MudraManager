import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/domain/budget_constraint_snapshot.dart';
import 'package:mudra_manager/core/logic/budget_state_machine.dart';
import 'package:mudra_manager/core/providers/date_change_provider.dart';
import 'package:mudra_manager/core/providers/collection_watchers.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/utils/budget_spent_calculator.dart';
import 'package:mudra_manager/core/db/extensions/field_encryption_ext.dart';

/// Produces urgency-sorted BudgetConstraintSnapshots for the budget list screen.
/// UI reads this — never computes constraint logic itself.
final budgetConstraintsProvider =
    FutureProvider.autoDispose<List<BudgetConstraintSnapshot>>((ref) async {
  ref.watch(dateChangeProvider);
  ref.watch(transactionChangeProvider);
  ref.watch(budgetChangeProvider);

  final isarService = ref.watch(isarServiceProvider);
  final isar = await isarService.getInstance();
  final now = DateTime.now();

  final budgets = await isar.budgets
      .where()
      .isArchivedEqualTo(false)
      .findAll()
      .withDecryption();

  final snapshots = <BudgetConstraintSnapshot>[];

  for (final budget in budgets) {
    final (periodStart, periodEnd) = budget.getCurrentPeriodRange(now);

    // Skip non-recurring budgets whose period has ended
    if (budget.recurrence == BudgetRecurrence.none &&
        periodEnd.isBefore(DateTime(now.year, now.month, now.day, 23, 59, 59))) {
      continue;
    }

    // Total spent in current period
    final totalSpent = await BudgetSpentCalculator.calculate(
      isar,
      budget,
      periodStart,
      periodEnd,
    );

    // Rolling 7-day spend
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final rolling7Start = sevenDaysAgo.isBefore(periodStart)
        ? periodStart
        : sevenDaysAgo;
    final spentInLast7Days = await BudgetSpentCalculator.calculate(
      isar,
      budget,
      rolling7Start,
      now,
    );

    // Period math
    final totalDays = periodEnd.difference(periodStart).inDays + 1;
    final daysPassed = now.difference(periodStart).inDays.clamp(0, totalDays);
    final daysLeft = (periodEnd.difference(now).inDays + 1).clamp(0, totalDays);

    final input = BudgetConstraintInput(
      budgetId: budget.id,
      budgetName: budget.name,
      budgetAmount: budget.amount,
      totalSpent: totalSpent,
      spentInLast7Days: spentInLast7Days,
      daysPassed: daysPassed,
      daysLeft: daysLeft,
      totalDays: totalDays,
    );

    snapshots.add(BudgetStateMachine.computeSnapshot(input));
  }

  // Sort by constraint urgency (enum ordinal = priority)
  snapshots.sort((a, b) => a.urgency.index.compareTo(b.urgency.index));

  return snapshots;
});

/// Portfolio strip data — precomputed from snapshots.
final budgetPortfolioProvider =
    Provider.autoDispose<AsyncValue<BudgetPortfolio>>((ref) {
  return ref.watch(budgetConstraintsProvider).whenData((snapshots) {
    final totalRemaining = snapshots
        .where((s) => !s.isBreached)
        .fold(0.0, (sum, s) => sum + s.remaining);
    final breachedCount =
        snapshots.where((s) => s.isBreached).length;
    final paceRiskCount = snapshots
        .where((s) =>
            s.isForecastVisible &&
            !s.isBreached,)
        .length;

    return BudgetPortfolio(
      totalBudgets: snapshots.length,
      totalRemaining: totalRemaining,
      breachedCount: breachedCount,
      paceRiskCount: paceRiskCount,
    );
  });
});

/// Derived selector — picks a single snapshot from the computed list.
/// Detail screen watches this instead of holding a frozen snapshot.
final budgetConstraintByIdProvider =
    Provider.autoDispose.family<AsyncValue<BudgetConstraintSnapshot?>, int>(
        (ref, budgetId) {
  return ref.watch(budgetConstraintsProvider).whenData(
        (snapshots) =>
            snapshots.where((s) => s.budgetId == budgetId).firstOrNull,
      );
});

class BudgetPortfolio {
  final int totalBudgets;
  final double totalRemaining;
  final int breachedCount;
  final int paceRiskCount;

  const BudgetPortfolio({
    required this.totalBudgets,
    required this.totalRemaining,
    required this.breachedCount,
    required this.paceRiskCount,
  });
}

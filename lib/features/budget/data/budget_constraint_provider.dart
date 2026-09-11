import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/domain/budget_constraint_snapshot.dart';
import 'package:mudra_manager/core/logic/budget_state_machine.dart';
import 'package:mudra_manager/core/providers/budget_refresh_provider.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/utils/budget_spent_calculator.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';

/// Produces urgency-sorted BudgetConstraintSnapshots for the budget list screen.
/// UI reads this — never computes constraint logic itself.
///
/// Spend, limit, and period identity come from the same canonical snapshot used
/// by dashboard/detail/history. Only rolling spend remains constraint-specific.
final budgetConstraintsProvider =
    FutureProvider.autoDispose<List<BudgetConstraintSnapshot>>((ref) async {
  final refresh = ref.watch(budgetRefreshProvider);
  final isar = await ref.watch(isarServiceProvider).getInstance();
  final canonical = await ref.watch(budgetPeriodSnapshotsProvider.future);
  final snapshots = <BudgetConstraintSnapshot>[];

  for (final budgetSnapshot in canonical) {
    final budget = budgetSnapshot.budget;
    final periodStart = budgetSnapshot.periodStart;
    final periodEnd = budgetSnapshot.periodEnd;
    final now = budgetSnapshot.evaluationDate;

    // Rolling 7-day spend, using canonical inclusive period bounds.
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final rolling7Start =
        sevenDaysAgo.isBefore(periodStart) ? periodStart : sevenDaysAgo;
    final spentInLast7Days = await BudgetSpentCalculator.calculate(
      isar,
      budget,
      rolling7Start,
      DateTime(now.year, now.month, now.day, 23, 59, 59),
    );

    final totalDays = periodEnd.difference(periodStart).inDays + 1;
    final daysPassed = now.difference(periodStart).inDays.clamp(0, totalDays);
    final daysLeft = (periodEnd.difference(now).inDays + 1).clamp(0, totalDays);

    snapshots.add(
      BudgetStateMachine.computeSnapshot(
        BudgetConstraintInput(
          budgetId: budgetSnapshot.budgetId,
          budgetName: budgetSnapshot.budgetName,
          budgetAmount: budgetSnapshot.limit,
          totalSpent: budgetSnapshot.spent,
          spentInLast7Days: spentInLast7Days,
          daysPassed: daysPassed,
          daysLeft: daysLeft,
          totalDays: totalDays,
          budgetSnapshot: budgetSnapshot,
        ),
      ),
    );
  }

  snapshots.sort((a, b) => a.urgency.index.compareTo(b.urgency.index));

  if (!ref.mounted ||
      ref.read(budgetRefreshProvider).generation != refresh.generation) {
    return const <BudgetConstraintSnapshot>[];
  }

  return snapshots;
});

/// Portfolio strip data — precomputed from snapshots.
final budgetPortfolioProvider =
    Provider.autoDispose<AsyncValue<BudgetPortfolio>>((ref) {
  return ref.watch(budgetConstraintsProvider).whenData((snapshots) {
    final totalRemaining = snapshots
        .where((s) => !s.isBreached)
        .fold(0.0, (sum, s) => sum + s.remaining);
    final breachedCount = snapshots.where((s) => s.isBreached).length;
    final paceRiskCount = snapshots
        .where(
          (s) => s.isForecastVisible && !s.isBreached,
        )
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
final budgetConstraintByIdProvider = Provider.autoDispose
    .family<AsyncValue<BudgetConstraintSnapshot?>, int>((ref, budgetId) {
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

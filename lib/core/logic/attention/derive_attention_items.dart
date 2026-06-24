import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/domain/financial_states.dart';
import 'package:mudra_manager/core/logic/attention/attention_item.dart';
import 'package:mudra_manager/core/state/dashboard_state.dart';

/// Derives all attention-worthy conditions from current financial state.
///
/// Pure function — no Riverpod, no Isar, no UI, no side effects.
/// Returns ALL applicable items. Ordering and capping are presentation concerns.
///
/// Inputs:
///   - [state]: current dashboard truth snapshot
///   - [goals]: active goals with progress data
///   - [now]: current time (injectable for testing)
List<AttentionItem> deriveAttentionItems({
  required DashboardState state,
  required List<Goal> goals,
  DateTime? now,
}) {
  final items = <AttentionItem>[];
  final currentTime = now ?? DateTime.now();

  // ── Bill attention ──
  if (state.billState == BillState.dueSoon ||
      state.billState == BillState.dueToday ||
      state.billState == BillState.overdue) {
    if (state.nearestBillDate != null) {
      final daysUntil = state.nearestBillDate!.difference(currentTime).inDays;

      if (daysUntil <= 1) {
        items.add(BillDueTomorrow(
          count: state.billCount,
          billName: state.nearestBillName,
        ),);
      } else {
        items.add(BillDueSoon(
          count: state.billCount,
          daysUntil: daysUntil,
          billName: state.nearestBillName,
        ),);
      }
    }
  }

  // ── Budget attention ──
  if (state.budgetState == BudgetState.breach) {
    items.add(BudgetOverLimit(
      budgetName: state.budgetName ?? '',
      overCount: state.convergenceCount,
    ),);
  } else if (state.budgetState == BudgetState.warn) {
    items.add(BudgetNearLimit(
      budgetName: state.budgetName ?? '',
      nearCount: state.convergenceCount,
    ),);
  }

  // ── Goal attention ──
  final nearComplete = goals
      .where((g) =>
          g.isActive && g.progressPercent >= 0.80 && g.progressPercent < 1.0,)
      .length;

  if (nearComplete > 0) {
    items.add(GoalNearCompletion(count: nearComplete));
  }

  return items;
}

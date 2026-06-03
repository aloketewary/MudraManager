import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/engine/dashboard_engine.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/state/dashboard_state.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';

/// Module-level storage for previous state (persists across provider rebuilds).
DashboardState? _previousState;

/// V2 Dashboard State Provider.
/// Reads from existing dashboardDataProvider (raw data), runs new engine.
/// Runs in PARALLEL with old system until cutover.
final dashboardStateV2Provider = Provider.autoDispose<DashboardState?>((ref) {
  final data = ref.watch(dashboardDataProvider).value;
  if (data == null) return null;

  final prefs = SharedPrefsUtil.instance;
  final now = DateTime.now();

  // ── Map DashboardData → EngineInput ──
  final input = EngineInput(
    accounts: data.accounts
        .map((a) => EngineAccount(id: a.id),)
        .toList(),
    transactions: data.transactions
        .map((t) => EngineTransaction(date: t.date),)
        .toList(),
    budgets: data.budgets
        .map((b) => EngineBudget(
              name: b.budget.name,
              spent: b.spent,
              limit: b.budget.amount,
            ),)
        .toList(),
    bills: data.recurringExpenses
        .map((r) => EngineBill(
              nextDueDate: r.nextDueDate,
              name: r.description ?? r.category.value?.name,
              amount: r.amount,
            ),)
        .toList(),
    totalBalance: data.totalBalance,
    totalIncome: data.totalIncome,
    totalExpense: data.totalExpense,
    expenseLast7Days: _computeLast7DaysExpense(data, now),
    budgetSetupSkipped:
        prefs.getString('budget_setup_skipped') == 'true',
    recurringScanDone:
        prefs.getString('recurring_scan_completed') == 'true',
  );

  final state = DashboardEngine.compute(
    input,
    previous: _previousState,
    now: now,
    billActionRoute: AppRoutes.recurringTransactions,
    budgetActionRoute: AppRoutes.budgetDashboard,
  );

  // Store for next transition detection cycle
  _previousState = state;

  return state;
});

double _computeLast7DaysExpense(DashboardData data, DateTime now) {
  final cutoff = now.subtract(const Duration(days: 7));
  return data.transactions
      .where((t) => t.isExpense && !t.isTransfer && t.date.isAfter(cutoff))
      .fold<double>(0, (sum, t) => sum + t.baseAmount);
}

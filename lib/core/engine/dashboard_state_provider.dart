import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/engine/dashboard_engine.dart';
import 'package:mudra_manager/core/logic/generators/bill_insight_generator.dart';
import 'package:mudra_manager/core/logic/generators/budget_insight_generator.dart';
import 'package:mudra_manager/core/logic/generators/cashflow_insight_generator.dart';
import 'package:mudra_manager/core/logic/generators/comparison_insight_generator.dart';
import 'package:mudra_manager/core/logic/suppression_engine.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/state/dashboard_state.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';

/// Module-level storage for previous state (persists across provider rebuilds).
DashboardState? _previousState;

/// Module-level suppression history (persists across provider rebuilds).
List<SuppressionRecord> _suppressionHistory = [];

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
        .map((a) => EngineAccount(id: a.id))
        .toList(),
    transactions: data.transactions
        .map((t) => EngineTransaction(date: t.date))
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
    // categoryComparison: null for now — will be wired when
    // comparison fact extraction is added to dashboardDataProvider
  );

  // ── Generators ──
  final generators = [
    const BillInsightGenerator(billActionRoute: AppRoutes.recurringTransactions),
    const BudgetInsightGenerator(budgetActionRoute: AppRoutes.budgetDashboard),
    const CashflowInsightGenerator(actionRoute: AppRoutes.budgetDashboard),
    const ComparisonInsightGenerator(actionRoute: AppRoutes.statistics),
  ];

  final state = DashboardEngine.compute(
    input,
    previous: _previousState,
    now: now,
    generators: generators,
    suppressionHistory: _suppressionHistory,
    billActionRoute: AppRoutes.recurringTransactions,
    budgetActionRoute: AppRoutes.budgetDashboard,
  );

  // Record suppression if briefing fired
  if (state.briefing != null) {
    _suppressionHistory = SuppressionEngine.recordFiring(
      history: _suppressionHistory,
      fired: state.briefing!.insight,
      now: now,
    );
  }

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

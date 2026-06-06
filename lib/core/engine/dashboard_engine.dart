import 'package:mudra_manager/core/domain/financial_states.dart';
import 'package:mudra_manager/core/logic/bill_state_machine.dart';
import 'package:mudra_manager/core/logic/briefing_selector.dart';
import 'package:mudra_manager/core/logic/budget_state_machine.dart';
import 'package:mudra_manager/core/logic/cashflow_engine.dart';
import 'package:mudra_manager/core/logic/convergence_counter.dart';
import 'package:mudra_manager/core/logic/data_validity_gate.dart';
import 'package:mudra_manager/core/logic/insight_generator.dart';
import 'package:mudra_manager/core/logic/state_transition_engine.dart';
import 'package:mudra_manager/core/logic/suppression_engine.dart';
import 'package:mudra_manager/core/state/dashboard_state.dart';

/// Input contract for the engine. Keeps engine decoupled from Isar models.
class EngineInput {
  final List<EngineAccount> accounts;
  final List<EngineTransaction> transactions;
  final List<EngineBudget> budgets;
  final List<EngineBill> bills;
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;
  final double expenseLast7Days;
  final bool budgetSetupSkipped;
  final bool recurringScanDone;

  /// Optional: per-category comparison facts for ComparisonInsightGenerator.
  final Map<String, CategoryFact>? categoryComparison;

  const EngineInput({
    required this.accounts,
    required this.transactions,
    required this.budgets,
    required this.bills,
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.expenseLast7Days,
    required this.budgetSetupSkipped,
    required this.recurringScanDone,
    this.categoryComparison,
  });
}

class EngineAccount {
  final int id;
  const EngineAccount({required this.id});
}

class EngineTransaction {
  final DateTime date;
  const EngineTransaction({required this.date});
}

class EngineBudget {
  final String name;
  final double spent;
  final double limit;
  const EngineBudget({
    required this.name,
    required this.spent,
    required this.limit,
  });
}

class EngineBill {
  final DateTime nextDueDate;
  final String? name;
  final double amount;
  const EngineBill({
    required this.nextDueDate,
    this.name,
    required this.amount,
  });
}

/// Orchestrates all core/logic modules into a single DashboardState.
///
/// This is a PURE FUNCTION. No Riverpod. No Isar. No SharedPrefs.
/// Takes input data + previous state, returns new state.
abstract final class DashboardEngine {
  static DashboardState compute(
    EngineInput input, {
    DashboardState? previous,
    DateTime? now,
    List<InsightGenerator> generators = const [],
    List<SuppressionRecord> suppressionHistory = const [],
    String? billActionRoute,
    String? budgetActionRoute,
  }) {
    final today = now ?? DateTime.now();

    // ── Data Validity Gate ──
    final validity = DataValidity(
      accountLinked: input.accounts.isNotEmpty,
      transactionStreamActive: input.transactions.any(
        (t) => today.difference(t.date).inDays <= 14,
      ),
      budgetStateKnown:
          input.budgets.isNotEmpty || input.budgetSetupSkipped,
      recurringScanDone: input.recurringScanDone,
    );

    // ── Cashflow ──
    final cashflow = CashflowEngine.compute(
      incomeTotal: input.totalIncome,
      expenseTotal: input.totalExpense,
      expenseLast7Days: input.expenseLast7Days,
    );

    // ── Budget (worst case) ──
    BudgetState worstBudget = BudgetState.unset;
    double budgetSpent = 0;
    double budgetLimit = 0;
    String? budgetName;
    for (final b in input.budgets) {
      final s = BudgetStateMachine.classify(b.spent, b.limit);
      if (s.index > worstBudget.index) {
        worstBudget = s;
        budgetSpent = b.spent;
        budgetLimit = b.limit;
        budgetName = b.name;
      }
    }

    // ── Bill (worst case) ──
    BillState worstBill =
        input.recurringScanDone ? BillState.clear : BillState.unknown;
    int billCount = 0;
    DateTime? nearestDate;
    String? nearestName;
    double? nearestAmount;
    for (final bill in input.bills) {
      final s = BillStateMachine.classify(
        bill.nextDueDate,
        today,
        scanDone: input.recurringScanDone,
      );
      if (s.index > worstBill.index) {
        worstBill = s;
        nearestDate = bill.nextDueDate;
        nearestName = bill.name;
        nearestAmount = bill.amount;
      }
      if (s == BillState.dueToday ||
          s == BillState.overdue ||
          s == BillState.dueSoon) {
        billCount++;
      }
    }

    // ── Transitions ──
    final budgetTransition = StateTransitionEngine.detectBudget(
      previous?.budgetState,
      worstBudget,
    );
    final billTransition = StateTransitionEngine.detectBill(
      previous?.billState,
      worstBill,
    );
    final cashflowTransition = StateTransitionEngine.detectCashflow(
      previous?.cashflow.state,
      cashflow.state,
    );

    // ── Convergence ──
    final convergence = ConvergenceCounter.compute(
      budget: worstBudget,
      bill: worstBill,
      cashflow: cashflow.state,
    );

    // ── Insight Generation ──
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
    final facts = Facts(
      budgets: input.budgets,
      worstBudgetName: budgetName,
      worstBudgetSpent: budgetSpent,
      worstBudgetLimit: budgetLimit,
      bills: input.bills,
      recurringScanDone: input.recurringScanDone,
      totalIncome: input.totalIncome,
      totalExpense: input.totalExpense,
      categoryComparison: input.categoryComparison,
      dayOfMonth: today.day,
      daysInMonth: daysInMonth,
      daysRemaining: daysInMonth - today.day,
      now: today,
    );

    final insights = generators.expand((g) => g.generate(facts)).toList();

    // ── Briefing Selection (with suppression) ──
    final briefing = BriefingSelector.select(
      insights,
      suppressionHistory: suppressionHistory,
      now: today,
    );

    return DashboardState(
      gate: validity.level,
      balance: input.totalBalance,
      cashflow: cashflow,
      budgetState: worstBudget,
      budgetSpent: budgetSpent,
      budgetLimit: budgetLimit,
      budgetName: budgetName,
      billState: worstBill,
      billCount: billCount,
      nearestBillDate: nearestDate,
      nearestBillName: nearestName,
      nearestBillAmount: nearestAmount,
      convergenceCount: convergence,
      budgetTransition: budgetTransition,
      billTransition: billTransition,
      cashflowTransition: cashflowTransition,
      briefing: briefing,
    );
  }
}

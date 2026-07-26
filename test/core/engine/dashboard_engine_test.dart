import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/domain/financial_states.dart';
import 'package:mudra_manager/core/engine/dashboard_engine.dart';
import 'package:mudra_manager/features/insights/data/bill_insight_generator.dart';
import 'package:mudra_manager/features/insights/data/budget_insight_generator.dart';
import 'package:mudra_manager/features/insights/data/cashflow_insight_generator.dart';
import 'package:mudra_manager/core/logic/insight_generator.dart';

void main() {
  final today = DateTime(2025, 6, 15, 10, 0);
  final List<InsightGenerator> generators = [
    const BudgetInsightGenerator(),
    const BillInsightGenerator(),
    const CashflowInsightGenerator(),
  ];

  group('DashboardEngine.compute', () {
    test('cold start — no data → insufficient gate', () {
      final input = const EngineInput(
        accounts: [],
        transactions: [],
        budgets: [],
        bills: [],
        totalBalance: 0,
        totalIncome: 0,
        totalExpense: 0,
        expenseLast7Days: 0,
        budgetSetupSkipped: false,
        recurringScanDone: false,
      );

      final state = DashboardEngine.compute(input, now: today);

      expect(state.gate, DataValidityLevel.insufficient);
      expect(state.budgetState, BudgetState.unset);
      expect(state.billState, BillState.unknown);
      expect(state.convergenceCount, 0);
      expect(state.briefing, isNull);
    });

    test('partial data — account + recent txns but no budget/scan', () {
      final input = EngineInput(
        accounts: [const EngineAccount(id: 1)],
        transactions: [
          EngineTransaction(date: today.subtract(const Duration(days: 2))),
        ],
        budgets: [],
        bills: [],
        totalBalance: 50000,
        totalIncome: 30000,
        totalExpense: 20000,
        expenseLast7Days: 5000,
        budgetSetupSkipped: false,
        recurringScanDone: false,
      );

      final state = DashboardEngine.compute(input, now: today);

      expect(state.gate, DataValidityLevel.partial);
      expect(state.balance, 50000);
      expect(state.cashflow.state, CashflowState.positive);
    });

    test('full valid — all conditions met', () {
      final input = EngineInput(
        accounts: [const EngineAccount(id: 1)],
        transactions: [
          EngineTransaction(date: today.subtract(const Duration(days: 1))),
        ],
        budgets: [
          const EngineBudget(name: 'Food', spent: 5000, limit: 10000),
        ],
        bills: [
          EngineBill(
            nextDueDate: today.add(const Duration(days: 10)),
            name: 'Rent',
            amount: 15000,
          ),
        ],
        totalBalance: 100000,
        totalIncome: 50000,
        totalExpense: 30000,
        expenseLast7Days: 7000,
        budgetSetupSkipped: false,
        recurringScanDone: true,
      );

      final state = DashboardEngine.compute(input, now: today);

      expect(state.gate, DataValidityLevel.valid);
      expect(state.budgetState, BudgetState.ok);
      expect(state.billState, BillState.clear);
      expect(state.cashflow.state, CashflowState.positive);
      expect(state.convergenceCount, 0);
      expect(state.briefing, isNull);
      expect(state.isStable, true);
    });

    test('single alert — budget breach triggers briefing', () {
      final input = EngineInput(
        accounts: [const EngineAccount(id: 1)],
        transactions: [
          EngineTransaction(date: today.subtract(const Duration(days: 1))),
        ],
        budgets: [
          const EngineBudget(name: 'Food', spent: 12000, limit: 10000),
        ],
        bills: [],
        totalBalance: 80000,
        totalIncome: 50000,
        totalExpense: 40000,
        expenseLast7Days: 10000,
        budgetSetupSkipped: false,
        recurringScanDone: true,
      );

      final state = DashboardEngine.compute(input, now: today, generators: generators);

      expect(state.budgetState, BudgetState.breach);
      expect(state.convergenceCount, 1);
      expect(state.briefing, isNotNull);
      expect(state.briefing!.insight.trigger, BriefingTrigger.budgetBreach);
      expect(state.briefing!.params['name'], 'Food');
    });

    test('multiple alerts — bill overdue wins over budget breach', () {
      final input = EngineInput(
        accounts: [const EngineAccount(id: 1)],
        transactions: [
          EngineTransaction(date: today.subtract(const Duration(days: 1))),
        ],
        budgets: [
          const EngineBudget(name: 'Food', spent: 12000, limit: 10000),
        ],
        bills: [
          EngineBill(
            nextDueDate: today.subtract(const Duration(days: 2)),
            name: 'Insurance',
            amount: 5000,
          ),
        ],
        totalBalance: 50000,
        totalIncome: 30000,
        totalExpense: 40000,
        expenseLast7Days: 10000,
        budgetSetupSkipped: false,
        recurringScanDone: true,
      );

      final state = DashboardEngine.compute(input, now: today, generators: generators);

      expect(state.convergenceCount, 3); // breach + overdue + negative
      expect(state.briefing!.insight.trigger, BriefingTrigger.billOverdue);
      expect(state.briefing!.params['name'], 'Insurance');
    });

    test('transition detection — newlyViolated on first breach', () {
      // Previous state: budget ok
      final previousInput = EngineInput(
        accounts: [const EngineAccount(id: 1)],
        transactions: [
          EngineTransaction(date: today.subtract(const Duration(days: 1))),
        ],
        budgets: [
          const EngineBudget(name: 'Food', spent: 5000, limit: 10000),
        ],
        bills: [],
        totalBalance: 80000,
        totalIncome: 50000,
        totalExpense: 30000,
        expenseLast7Days: 5000,
        budgetSetupSkipped: false,
        recurringScanDone: true,
      );
      final previous = DashboardEngine.compute(previousInput, now: today);

      // Current state: budget breach
      final currentInput = EngineInput(
        accounts: [const EngineAccount(id: 1)],
        transactions: [
          EngineTransaction(date: today.subtract(const Duration(days: 1))),
        ],
        budgets: [
          const EngineBudget(name: 'Food', spent: 12000, limit: 10000),
        ],
        bills: [],
        totalBalance: 70000,
        totalIncome: 50000,
        totalExpense: 42000,
        expenseLast7Days: 12000,
        budgetSetupSkipped: false,
        recurringScanDone: true,
      );
      final current = DashboardEngine.compute(
        currentInput,
        previous: previous,
        now: today,
      );

      expect(current.budgetTransition, StateTransition.newlyViolated);
    });

    test('worst budget wins when multiple budgets exist', () {
      final input = EngineInput(
        accounts: [const EngineAccount(id: 1)],
        transactions: [
          EngineTransaction(date: today.subtract(const Duration(days: 1))),
        ],
        budgets: [
          const EngineBudget(name: 'Food', spent: 5000, limit: 10000), // ok
          const EngineBudget(name: 'Transport', spent: 9000, limit: 10000), // warn
          const EngineBudget(name: 'Shopping', spent: 15000, limit: 10000), // breach
        ],
        bills: [],
        totalBalance: 50000,
        totalIncome: 50000,
        totalExpense: 29000,
        expenseLast7Days: 7000,
        budgetSetupSkipped: false,
        recurringScanDone: true,
      );

      final state = DashboardEngine.compute(input, now: today);

      expect(state.budgetState, BudgetState.breach);
      expect(state.budgetName, 'Shopping');
      expect(state.budgetSpent, 15000);
    });

    test('bill count only counts critical states', () {
      final input = EngineInput(
        accounts: [const EngineAccount(id: 1)],
        transactions: [
          EngineTransaction(date: today.subtract(const Duration(days: 1))),
        ],
        budgets: [],
        bills: [
          EngineBill(
            nextDueDate: today, // dueToday
            name: 'Rent',
            amount: 15000,
          ),
          EngineBill(
            nextDueDate: today.add(const Duration(days: 1)), // dueSoon
            name: 'Electricity',
            amount: 2000,
          ),
          EngineBill(
            nextDueDate: today.add(const Duration(days: 10)), // clear
            name: 'Insurance',
            amount: 5000,
          ),
        ],
        totalBalance: 100000,
        totalIncome: 50000,
        totalExpense: 30000,
        expenseLast7Days: 7000,
        budgetSetupSkipped: true,
        recurringScanDone: true,
      );

      final state = DashboardEngine.compute(input, now: today);

      expect(state.billState, BillState.dueToday);
      expect(state.billCount, 2); // dueToday + dueSoon
      expect(state.nearestBillName, 'Rent');
    });

    test('stale data detection — no recent transactions', () {
      final input = EngineInput(
        accounts: [const EngineAccount(id: 1)],
        transactions: [
          // Only old transactions (>14 days)
          EngineTransaction(date: today.subtract(const Duration(days: 30))),
        ],
        budgets: [
          const EngineBudget(name: 'Food', spent: 5000, limit: 10000),
        ],
        bills: [],
        totalBalance: 80000,
        totalIncome: 50000,
        totalExpense: 30000,
        expenseLast7Days: 0,
        budgetSetupSkipped: false,
        recurringScanDone: true,
      );

      final state = DashboardEngine.compute(input, now: today);

      // transactionStreamActive is false → drops to partial
      expect(state.gate, DataValidityLevel.partial);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/domain/financial_states.dart';
import 'package:mudra_manager/features/insights/data/derive_attention_items.dart';
import 'package:mudra_manager/core/logic/cashflow_engine.dart';
import 'package:mudra_manager/core/state/dashboard_state.dart';
import 'package:mudra_manager/features/insights/domain/attention.dart';

DashboardState _makeState({
  BudgetState budgetState = BudgetState.ok,
  BillState billState = BillState.clear,
  int billCount = 0,
  DateTime? nearestBillDate,
  String? nearestBillName,
  String? budgetName,
  int convergenceCount = 0,
}) {
  return DashboardState(
    gate: DataValidityLevel.valid,
    balance: 50000,
    cashflow: const CashflowSnapshot(
      incomeTotal: 50000,
      expenseTotal: 40000,
      net: 10000,
      burnRate: 1000,
      state: CashflowState.positive,
    ),
    budgetState: budgetState,
    budgetSpent: 8000,
    budgetLimit: 10000,
    budgetName: budgetName,
    billState: billState,
    billCount: billCount,
    nearestBillDate: nearestBillDate,
    nearestBillName: nearestBillName,
    convergenceCount: convergenceCount,
    budgetTransition: StateTransition.stable,
    billTransition: StateTransition.stable,
    cashflowTransition: StateTransition.stable,
  );
}

Goal _makeGoal({required double progress, bool isActive = true}) {
  final goal = Goal()
    ..name = 'Test Goal'
    ..targetAmount = 100
    ..currentAmount = progress // progressPercent = currentAmount/targetAmount
    ..isActive = isActive;
  return goal;
}

void main() {
  final now = DateTime(2025, 6, 15, 10, 0);

  group('deriveAttentionItems', () {
    test('returns empty when nothing needs attention', () {
      final state = _makeState();
      final result = deriveAttentionItems(state: state, goals: [], now: now);
      expect(result, isEmpty);
    });

    // ── Bill rules ──

    test('bill due tomorrow produces BillDueTomorrow', () {
      final state = _makeState(
        billState: BillState.dueSoon,
        billCount: 2,
        nearestBillDate: DateTime(2025, 6, 16, 10, 0), // tomorrow
        nearestBillName: 'Netflix',
      );

      final result = deriveAttentionItems(state: state, goals: [], now: now);

      expect(result, hasLength(1));
      expect(result.first, isA<BillDueTomorrow>());
      final item = result.first as BillDueTomorrow;
      expect(item.count, 2);
      expect(item.billName, 'Netflix');
    });

    test('bill due today produces BillDueTomorrow (daysUntil <= 1)', () {
      final state = _makeState(
        billState: BillState.dueToday,
        billCount: 1,
        nearestBillDate: DateTime(2025, 6, 15, 18, 0), // same day
        nearestBillName: 'Rent',
      );

      final result = deriveAttentionItems(state: state, goals: [], now: now);

      expect(result.first, isA<BillDueTomorrow>());
    });

    test('bill due in 2+ days produces BillDueSoon', () {
      final state = _makeState(
        billState: BillState.dueSoon,
        billCount: 3,
        nearestBillDate: DateTime(2025, 6, 18, 10, 0), // 3 days
        nearestBillName: 'Electricity',
      );

      final result = deriveAttentionItems(state: state, goals: [], now: now);

      expect(result.first, isA<BillDueSoon>());
      final item = result.first as BillDueSoon;
      expect(item.daysUntil, 3);
      expect(item.count, 3);
    });

    test('bill state clear produces no bill attention', () {
      final state = _makeState(billState: BillState.clear);
      final result = deriveAttentionItems(state: state, goals: [], now: now);
      expect(result.whereType<BillDueTomorrow>(), isEmpty);
      expect(result.whereType<BillDueSoon>(), isEmpty);
    });

    // ── Budget rules ──

    test('budget breach produces BudgetOverLimit', () {
      final state = _makeState(
        budgetState: BudgetState.breach,
        budgetName: 'Food',
        convergenceCount: 2,
      );

      final result = deriveAttentionItems(state: state, goals: [], now: now);

      expect(result, hasLength(1));
      expect(result.first, isA<BudgetOverLimit>());
      final item = result.first as BudgetOverLimit;
      expect(item.overCount, 2);
    });

    test('budget warn produces BudgetNearLimit', () {
      final state = _makeState(
        budgetState: BudgetState.warn,
        budgetName: 'Shopping',
        convergenceCount: 1,
      );

      final result = deriveAttentionItems(state: state, goals: [], now: now);

      expect(result.first, isA<BudgetNearLimit>());
    });

    test('budget ok produces no budget attention', () {
      final state = _makeState(budgetState: BudgetState.ok);
      final result = deriveAttentionItems(state: state, goals: [], now: now);
      expect(result.whereType<BudgetOverLimit>(), isEmpty);
      expect(result.whereType<BudgetNearLimit>(), isEmpty);
    });

    // ── Goal rules ──

    test('goals at 80-99% produce GoalNearCompletion', () {
      final goals = [
        _makeGoal(progress: 85), // 0.85 = 85%
        _makeGoal(progress: 92), // 0.92 = 92%
        _makeGoal(progress: 50), // 0.50 = 50% — below threshold
      ];

      final state = _makeState();
      final result = deriveAttentionItems(state: state, goals: goals, now: now);

      expect(result, hasLength(1));
      expect(result.first, isA<GoalNearCompletion>());
      expect((result.first as GoalNearCompletion).count, 2);
    });

    test('completed goals (100%) do not produce attention', () {
      final goals = [_makeGoal(progress: 100)]; // 1.0 = 100%
      final state = _makeState();
      final result = deriveAttentionItems(state: state, goals: goals, now: now);
      expect(result.whereType<GoalNearCompletion>(), isEmpty);
    });

    test('inactive goals do not produce attention', () {
      final goals = [
        _makeGoal(progress: 90, isActive: false),
      ]; // 0.9 but inactive
      final state = _makeState();
      final result = deriveAttentionItems(state: state, goals: goals, now: now);
      expect(result.whereType<GoalNearCompletion>(), isEmpty);
    });

    // ── Combined ──

    test('multiple conditions produce multiple items', () {
      final state = _makeState(
        budgetState: BudgetState.breach,
        budgetName: 'Food',
        convergenceCount: 1,
        billState: BillState.dueToday,
        billCount: 1,
        nearestBillDate: DateTime(2025, 6, 15, 18, 0),
      );
      final goals = [_makeGoal(progress: 85)];

      final result = deriveAttentionItems(state: state, goals: goals, now: now);

      expect(result, hasLength(3));
      expect(result.whereType<BillDueTomorrow>(), hasLength(1));
      expect(result.whereType<BudgetOverLimit>(), hasLength(1));
      expect(result.whereType<GoalNearCompletion>(), hasLength(1));
    });
  });
}

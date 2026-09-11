import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/budget_category_allocation.dart';
import 'package:mudra_manager/core/db/models/budget_period_ledger_entry.dart';
import 'package:mudra_manager/core/db/models/budget_type.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/exchange_rate.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/domain/budget_period_snapshot.dart';
import 'package:mudra_manager/core/domain/financial_states.dart';
import 'package:mudra_manager/core/logic/budget_state_machine.dart';
import 'package:mudra_manager/core/utils/budget_spent_calculator.dart';
import 'package:mudra_manager/core/utils/date_arithmetic.dart';
import 'package:mudra_manager/features/budget/domain/budget_overview_aggregate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Budget makeBudget({
    int id = 1,
    double amount = 1000,
    DateTime? start,
    DateTime? end,
    BudgetRecurrence recurrence = BudgetRecurrence.none,
    BudgetType type = BudgetType.dayWise,
  }) {
    return Budget()
      ..id = id
      ..name = 'Domain budget $id'
      ..amount = amount
      ..startDate = start ?? DateTime(2024, 1, 1)
      ..endDate = end ?? DateTime(2024, 1, 31)
      ..budgetType = type
      ..recurrence = recurrence;
  }

  group('Property 4: canonical period and snapshot domain', () {
    test('generated supported recurrences contain evaluation date once', () {
      // Generated deterministic cases: 120 iterations, replacing an external
      // PBT package while keeping the required minimum iteration count.
      for (var i = 0; i < 120; i++) {
        final recurrence = switch (i % 4) {
          0 => BudgetRecurrence.daily,
          1 => BudgetRecurrence.weekly,
          2 => BudgetRecurrence.monthly,
          _ => BudgetRecurrence.yearly,
        };
        final budget = switch (recurrence) {
          BudgetRecurrence.daily => makeBudget(
              recurrence: recurrence,
              start: DateTime(2024, 1, 1),
              end: DateTime(2024, 1, 1),
            ),
          BudgetRecurrence.weekly => makeBudget(
              recurrence: recurrence,
              start: DateTime(2024, 1, 1),
              end: DateTime(2024, 1, 7),
            ),
          BudgetRecurrence.monthly => makeBudget(
              recurrence: recurrence,
              start: DateTime(2024, 1, 1),
              end: DateTime(2024, 1, 31),
            ),
          BudgetRecurrence.yearly => makeBudget(
              recurrence: recurrence,
              start: DateTime(2024, 1, 1),
              end: DateTime(2024, 12, 31),
            ),
          BudgetRecurrence.none => throw StateError('unreachable'),
        };
        final evaluationDate = switch (recurrence) {
          BudgetRecurrence.daily => DateTime(2024, 1, 1).add(
              Duration(days: i),
            ),
          BudgetRecurrence.weekly => DateTime(2024, 1, 4).add(
              Duration(days: i * 7),
            ),
          BudgetRecurrence.monthly => DateTime(
              2024 + i ~/ 12,
              i % 12 + 1,
              15,
            ),
          BudgetRecurrence.yearly => DateTime(2024 + i, 6, 15),
          BudgetRecurrence.none => throw StateError('unreachable'),
        };
        final (start, end) = budget.getCurrentPeriodRange(evaluationDate);
        final day = DateArithmetic.startOfDay(evaluationDate);

        expect(
          !day.isBefore(DateArithmetic.startOfDay(start)) &&
              !day.isAfter(DateArithmetic.startOfDay(end)),
          isTrue,
          reason: '$recurrence: $start..$end for $evaluationDate',
        );
        expect(
          budget.getCurrentPeriodRange(evaluationDate),
          budget.getCurrentPeriodRange(evaluationDate),
        );
      }
    });

    test('monthly anchor survives short month and leap year', () {
      final leap = makeBudget(
        recurrence: BudgetRecurrence.monthly,
        start: DateTime(2024, 1, 31),
        end: DateTime(2024, 1, 31),
      );
      final nonLeap = makeBudget(
        recurrence: BudgetRecurrence.monthly,
        start: DateTime(2023, 1, 31),
        end: DateTime(2023, 1, 31),
      );

      expect(
        leap.getCurrentPeriodRange(DateTime(2024, 3, 31)).$1,
        DateTime(2024, 3, 31),
      );
      expect(
        nonLeap.getCurrentPeriodRange(DateTime(2023, 3, 31)).$1,
        DateTime(2023, 3, 31),
      );
      expect(
        leap.getCurrentPeriodRange(DateTime(2024, 2, 29)).$1,
        DateTime(2024, 2, 29),
      );
    });

    test('snapshot normalizes inclusive bounds and derives safe status fields',
        () {
      for (var i = 0; i < 120; i++) {
        final limit = (i % 9) * 125.0;
        final spent = i.isEven ? limit : limit + 25;
        final budget = makeBudget(id: i + 1, amount: limit);
        final snapshot = BudgetPeriodSnapshot.fromBudget(
          budget: budget,
          evaluationDate: DateTime(2024, 3, 10, 18, 30),
          periodStart: DateTime(2024, 3, 1, 14),
          periodEnd: DateTime(2024, 3, 31, 8),
          spent: spent,
        );

        expect(snapshot.periodStart, DateTime(2024, 3, 1));
        expect(
          snapshot.periodEnd,
          DateArithmetic.endOfDay(DateTime(2024, 3, 31)),
        );
        expect(snapshot.remaining, limit - spent);
        expect(snapshot.percentage.isFinite, isTrue);
        expect(snapshot.percentage, inInclusiveRange(0, 1));
        expect(
          snapshot.status,
          spent <= limit ? BudgetPeriodStatus.met : BudgetPeriodStatus.exceeded,
        );
        expect(snapshot.occurrenceKey, contains('${i + 1}:'));
      }
    });

    test('state machine keeps canonical financial meaning at boundaries', () {
      for (var i = 0; i < 120; i++) {
        final limit = 100.0 + i;
        final spent = i % 3 == 0
            ? limit - 10
            : i % 3 == 1
                ? limit
                : limit + 10;
        final snapshot = BudgetStateMachine.computeSnapshot(
          BudgetConstraintInput(
            budgetId: i + 1,
            budgetName: 'Budget $i',
            budgetAmount: limit,
            totalSpent: spent,
            spentInLast7Days: spent,
            daysPassed: 10,
            daysLeft: 20,
            totalDays: 30,
          ),
        );
        expect(snapshot.remaining, limit - spent);
        expect(snapshot.isBreached, spent > limit);
        expect(snapshot.percentage, spent / limit);
        expect(
          snapshot.state,
          spent > limit ? BudgetState.breach : isNot(BudgetState.breach),
        );
      }
    });
  });

  group('Property 4: BudgetSpentCalculator inclusive boundaries', () {
    late Isar isar;
    late Directory tempDir;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('budget_domain_');
      final existing = Isar.getInstance();
      if (existing != null && existing.isOpen) await existing.close();
      isar = await Isar.open(
        [
          BudgetSchema,
          BudgetCategoryAllocationSchema,
          BudgetPeriodLedgerEntrySchema,
          CategorySchema,
          TagSchema,
          TransactionSchema,
          AccountSchema,
          RecurringTransactionSchema,
          ExchangeRateSchema,
        ],
        directory: tempDir.path,
      );
    });

    tearDown(() async {
      await isar.close();
      tempDir.deleteSync(recursive: true);
    });

    test('generated start/end transactions count once and exclusions stay zero',
        () async {
      // 120 generated periods. Every expected result is exactly start + end;
      // adjacent-day, income, transfer, and settlement records are excluded.
      final budgets = <(Budget, DateTime, DateTime, double)>[];
      for (var i = 0; i < 120; i++) {
        final day = DateTime(2024, 1, 1).add(Duration(days: i * 4));
        final start = DateArithmetic.startOfDay(day);
        final end = DateArithmetic.endOfDay(day);
        final budget = makeBudget(
          id: i + 1,
          start: start,
          end: start,
        );
        budgets.add((budget, start, end, 3));
        final transactions = [
          Transaction.create(date: start, amount: 1, isExpense: true),
          Transaction.create(date: end, amount: 2, isExpense: true),
          Transaction.create(
            date: end.add(const Duration(microseconds: 1)),
            amount: 100,
            isExpense: true,
          ),
          Transaction.create(date: start, amount: 100, isExpense: false),
          Transaction.create(
            date: start,
            amount: 100,
            isExpense: true,
            isTransfer: true,
          )..isSettlement = true,
        ];
        await isar.writeTxn(() async {
          await isar.budgets.put(budget);
          await isar.transactions.putAll(transactions);
        });
      }

      for (final (budget, start, end, expected) in budgets) {
        final spent = await BudgetSpentCalculator.calculate(
          isar,
          budget,
          start,
          end,
        );
        expect(spent, expected, reason: 'budget ${budget.id}');
      }
    });
  });

  group('Property 5: period-aware mini aggregate', () {
    test('generated mixed snapshots conserve totals and stay finite', () {
      // Generated deterministic cases: 120 iterations.
      for (var i = 0; i < 120; i++) {
        final snapshots = List<BudgetPeriodSnapshot>.generate(3, (index) {
          final limit = (i + 1) * (index + 1) * 10.0;
          final spent = (i * (index + 2)) % (limit.toInt() + 20);
          final start = DateTime(2024, 1, 1).add(Duration(days: index));
          final end = start.add(Duration(days: index + 1));
          final recurrence = index == 0
              ? BudgetRecurrence.daily
              : index == 1
                  ? BudgetRecurrence.weekly
                  : BudgetRecurrence.monthly;
          final budget = makeBudget(
            id: i * 3 + index + 1,
            amount: limit,
            recurrence: recurrence,
            start: start,
            end: end,
          );
          return BudgetPeriodSnapshot.fromBudget(
            budget: budget,
            evaluationDate: start,
            periodStart: start,
            periodEnd: end,
            spent: spent.toDouble(),
          );
        });
        final aggregate = BudgetOverviewAggregate.fromSnapshots(snapshots);
        final expectedLimit =
            snapshots.fold(0.0, (sum, item) => sum + item.limit);
        final expectedSpent =
            snapshots.fold(0.0, (sum, item) => sum + item.spent);
        final expectedRemaining =
            snapshots.fold(0.0, (sum, item) => sum + item.remaining);
        final expectedDaily = snapshots.fold(0.0, (sum, item) {
          if (item.remaining <= 0) return sum;
          final days =
              item.periodEnd.difference(item.evaluationDate).inDays + 1;
          return sum + item.remaining / days;
        });

        expect(aggregate.totalLimit, closeTo(expectedLimit, 0.000001));
        expect(aggregate.totalSpent, closeTo(expectedSpent, 0.000001));
        expect(aggregate.totalRemaining, closeTo(expectedRemaining, 0.000001));
        expect(aggregate.dailyAllowance, closeTo(expectedDaily, 0.000001));
        expect(aggregate.progress.isFinite, isTrue);
        expect(aggregate.progress, inInclusiveRange(0, 1));
        expect(aggregate.isCompatibleMonthly, isFalse);
      }
    });

    test('zero limit and compatible monthly groups are safe', () {
      final zero = BudgetPeriodSnapshot.fromBudget(
        budget: makeBudget(amount: 0),
        evaluationDate: DateTime(2024, 1, 1),
        periodStart: DateTime(2024, 1, 1),
        periodEnd: DateTime(2024, 1, 31),
        spent: 0,
      );
      final aggregate = BudgetOverviewAggregate.fromSnapshots([zero]);
      expect(aggregate.progress, 0);
      expect(aggregate.percent, 0);
      expect(aggregate.hasUsableLimit, isFalse);
      expect(aggregate.progress.isFinite, isTrue);

      final monthly = [
        BudgetPeriodSnapshot.fromBudget(
          budget: makeBudget(
            id: 1,
            amount: 100,
            recurrence: BudgetRecurrence.monthly,
          ),
          evaluationDate: DateTime(2024, 1, 15),
          periodStart: DateTime(2024, 1, 1),
          periodEnd: DateTime(2024, 1, 31),
          spent: 10,
        ),
        BudgetPeriodSnapshot.fromBudget(
          budget: makeBudget(
            id: 2,
            amount: 200,
            recurrence: BudgetRecurrence.monthly,
          ),
          evaluationDate: DateTime(2024, 1, 15),
          periodStart: DateTime(2024, 1, 1),
          periodEnd: DateTime(2024, 1, 31),
          spent: 20,
        ),
      ];
      expect(
        BudgetOverviewAggregate.fromSnapshots(monthly).isCompatibleMonthly,
        isTrue,
      );
    });
  });
}

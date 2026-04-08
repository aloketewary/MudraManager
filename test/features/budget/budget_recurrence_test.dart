import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/features/budget/domain/overspend_prediction.dart';

void main() {
  group('Budget getCurrentPeriodRange', () {
    Budget _makeBudget({
      required BudgetRecurrence recurrence,
      required DateTime start,
      required DateTime end,
    }) {
      return Budget()
        ..name = 'Test'
        ..amount = 10000
        ..startDate = start
        ..endDate = end
        ..recurrence = recurrence;
    }

    test('none recurrence returns original range', () {
      final budget = _makeBudget(
        recurrence: BudgetRecurrence.none,
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      );
      final (start, end) = budget.getCurrentPeriodRange(DateTime(2024, 1, 15));
      expect(start, DateTime(2024, 1, 1));
      expect(end, DateTime(2024, 1, 31));
    });

    test('monthly recurrence advances to current month', () {
      final budget = _makeBudget(
        recurrence: BudgetRecurrence.monthly,
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      );
      final (start, end) = budget.getCurrentPeriodRange(DateTime(2024, 3, 15));
      expect(start.month, 3);
      expect(end.month, 3);
    });

    test('weekly recurrence advances by 7 days', () {
      final budget = _makeBudget(
        recurrence: BudgetRecurrence.weekly,
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 7),
      );
      final (start, end) = budget.getCurrentPeriodRange(DateTime(2024, 1, 10));
      expect(start, DateTime(2024, 1, 8));
      expect(end, DateTime(2024, 1, 14));
    });

    test('daily recurrence advances by 1 day', () {
      final budget = _makeBudget(
        recurrence: BudgetRecurrence.daily,
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 1),
      );
      final (start, end) = budget.getCurrentPeriodRange(DateTime(2024, 1, 5));
      expect(start, DateTime(2024, 1, 5));
      expect(end, DateTime(2024, 1, 5));
    });

    test('yearly recurrence advances by year', () {
      final budget = _makeBudget(
        recurrence: BudgetRecurrence.yearly,
        start: DateTime(2023, 1, 1),
        end: DateTime(2023, 12, 31),
      );
      final (start, end) = budget.getCurrentPeriodRange(DateTime(2025, 6, 15));
      expect(start.year, 2025);
      expect(end.year, 2025);
    });

    test('returns initial range when now is before start', () {
      final budget = _makeBudget(
        recurrence: BudgetRecurrence.monthly,
        start: DateTime(2024, 6, 1),
        end: DateTime(2024, 6, 30),
      );
      final (start, end) = budget.getCurrentPeriodRange(DateTime(2024, 1, 1));
      expect(start, DateTime(2024, 6, 1));
      expect(end, DateTime(2024, 6, 30));
    });

    test('returns current range when now is exactly on start', () {
      final budget = _makeBudget(
        recurrence: BudgetRecurrence.monthly,
        start: DateTime(2024, 3, 1),
        end: DateTime(2024, 3, 31),
      );
      final (start, end) = budget.getCurrentPeriodRange(DateTime(2024, 3, 1));
      // now is within the initial range, so should return it
      expect(start, DateTime(2024, 3, 1));
    });
  });

  group('OverspendPrediction', () {
    test('on track prediction has correct message', () {
      final prediction = OverspendPrediction(
        budgetId: 1,
        budgetName: 'Food',
        budgetAmount: 10000,
        currentSpent: 3000,
        dailyAverage: 200,
        daysRemaining: 20,
        projectedTotal: 8000,
        overspendAmount: -2000,
        daysUntilOverspend: 35,
        willOverspend: false,
      );
      expect(prediction.willOverspend, false);
      expect(prediction.warningMessage, contains('On track'));
    });

    test('overspend prediction has correct message', () {
      final prediction = OverspendPrediction(
        budgetId: 1,
        budgetName: 'Food',
        budgetAmount: 10000,
        currentSpent: 8000,
        dailyAverage: 500,
        daysRemaining: 10,
        projectedTotal: 15000,
        overspendAmount: 5000,
        daysUntilOverspend: 4,
        willOverspend: true,
      );
      expect(prediction.willOverspend, true);
      expect(prediction.warningMessage, contains('exceed'));
      expect(prediction.warningMessage, contains('Food'));
      expect(prediction.warningMessage, contains('4'));
    });

    test('singular day in overspend message', () {
      final prediction = OverspendPrediction(
        budgetId: 1,
        budgetName: 'Transport',
        budgetAmount: 5000,
        currentSpent: 4800,
        dailyAverage: 300,
        daysRemaining: 2,
        projectedTotal: 6000,
        overspendAmount: 1000,
        daysUntilOverspend: 1,
        willOverspend: true,
      );
      expect(prediction.warningMessage, contains('1 day'));
      expect(prediction.warningMessage, isNot(contains('1 days')));
    });

    test('percentageOfBudget calculates correctly', () {
      final prediction = OverspendPrediction(
        budgetId: 1,
        budgetName: 'Test',
        budgetAmount: 10000,
        currentSpent: 7500,
        dailyAverage: 250,
        daysRemaining: 10,
        projectedTotal: 10000,
        overspendAmount: 0,
        daysUntilOverspend: 10,
        willOverspend: false,
      );
      expect(prediction.percentageOfBudget, 75.0);
    });

    test('100% spent', () {
      final prediction = OverspendPrediction(
        budgetId: 1,
        budgetName: 'Test',
        budgetAmount: 5000,
        currentSpent: 5000,
        dailyAverage: 500,
        daysRemaining: 5,
        projectedTotal: 7500,
        overspendAmount: 2500,
        daysUntilOverspend: 0,
        willOverspend: true,
      );
      expect(prediction.percentageOfBudget, 100.0);
      expect(prediction.daysUntilOverspend, 0);
    });
  });

  group('BudgetRecurrence enum', () {
    test('all recurrence types exist', () {
      expect(BudgetRecurrence.values, contains(BudgetRecurrence.none));
      expect(BudgetRecurrence.values, contains(BudgetRecurrence.daily));
      expect(BudgetRecurrence.values, contains(BudgetRecurrence.weekly));
      expect(BudgetRecurrence.values, contains(BudgetRecurrence.monthly));
      expect(BudgetRecurrence.values, contains(BudgetRecurrence.yearly));
    });
  });
}

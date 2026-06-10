import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/features/analytics/application/analytics_insight_engine.dart';
import 'package:mudra_manager/features/analytics/application/insight_rules.dart';
import 'package:mudra_manager/features/analytics/data/analytics_aggregation_service.dart';
import 'package:mudra_manager/features/analytics/domain/narrative_fact.dart';

AnalyticsAggregates _makeAggregates({
  double totalIncome = 50000,
  double totalExpense = 30000,
  Map<String, double>? categoryBreakdown,
  Map<String, List<double>>? monthlyExpenseTrends,
  Map<String, double>? spendingByDayOfWeek,
  double avgDailySpend = 1000,
  double? previousFullExpense,
}) {
  return AnalyticsAggregates(
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    incomeSpots: const [],
    expenseSpots: const [],
    savingsSpots: const [],
    categoryBreakdown: categoryBreakdown ?? {'Food': 15000, 'Transport': 10000, 'Shopping': 5000},
    incomeCategoryBreakdown: const {},
    monthlyExpenseTrends: monthlyExpenseTrends ?? {},
    spendingByDayOfWeek: spendingByDayOfWeek ?? {
      'Mon': 200,
      'Tue': 180,
      'Wed': 190,
      'Thu': 210,
      'Fri': 220,
      'Sat': 150,
      'Sun': 140,
    },
    savingsRate: 40,
    avgDailySpend: avgDailySpend,
    daysInPeriod: 30,
    previousFullExpense: previousFullExpense,
  );
}

void main() {
  group('TopCategoryRule', () {
    const rule = TopCategoryRule();

    test('returns fact when top category exceeds threshold', () {
      final aggregates = _makeAggregates();
      final fact = rule.evaluate(aggregates);

      expect(fact, isA<TopCategoryFact>());
      final f = fact! as TopCategoryFact;
      expect(f.category, 'Food');
      expect(f.percentage, 50.0);
    });

    test('returns null when category breakdown is empty', () {
      final aggregates = _makeAggregates(categoryBreakdown: {});
      expect(rule.evaluate(aggregates), isNull);
    });

    test('returns null when top category below threshold', () {
      final aggregates = _makeAggregates(
        categoryBreakdown: {'Snacks': 50},
        totalExpense: 50,
      );
      expect(rule.evaluate(aggregates), isNull);
    });
  });

  group('NewCategoryRule', () {
    const rule = NewCategoryRule();

    test('returns fact when category appeared this month', () {
      final aggregates = _makeAggregates(
        monthlyExpenseTrends: {
          'Gym': [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 500],
        },
      );
      final fact = rule.evaluate(aggregates, periodKey: 'Month');

      expect(fact, isA<NewSpendingCategoryFact>());
      final f = fact! as NewSpendingCategoryFact;
      expect(f.category, 'Gym');
      expect(f.amount, 500);
    });

    test('returns null for non-Month period', () {
      final aggregates = _makeAggregates(
        monthlyExpenseTrends: {
          'Gym': [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 500],
        },
      );
      expect(rule.evaluate(aggregates, periodKey: 'Week'), isNull);
    });

    test('returns null when amount below threshold', () {
      final aggregates = _makeAggregates(
        monthlyExpenseTrends: {
          'Gym': [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 50],
        },
      );
      expect(rule.evaluate(aggregates, periodKey: 'Month'), isNull);
    });
  });

  group('CategoryStoppedRule', () {
    const rule = CategoryStoppedRule();

    test('returns fact when category stopped this month', () {
      final aggregates = _makeAggregates(
        monthlyExpenseTrends: {
          'Gym': [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 500, 0],
        },
      );
      final fact = rule.evaluate(aggregates, periodKey: 'Month');

      expect(fact, isA<CategoryStoppedFact>());
      final f = fact! as CategoryStoppedFact;
      expect(f.category, 'Gym');
      expect(f.previousAmount, 500);
    });

    test('returns null when previous was below threshold', () {
      final aggregates = _makeAggregates(
        monthlyExpenseTrends: {
          'Gym': [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 50, 0],
        },
      );
      expect(rule.evaluate(aggregates, periodKey: 'Month'), isNull);
    });
  });

  group('SpendingPatternRule', () {
    const rule = SpendingPatternRule();

    test('returns WeekendPeakFact when weekend spending dominates', () {
      final aggregates = _makeAggregates(
        spendingByDayOfWeek: {
          'Mon': 100,
          'Tue': 100,
          'Wed': 100,
          'Thu': 100,
          'Fri': 100,
          'Sat': 800,
          'Sun': 700,
        },
      );
      final fact = rule.evaluate(aggregates);
      expect(fact, isA<WeekendPeakFact>());
    });

    test('returns WeekdayPeakFact when weekday spending dominates', () {
      final aggregates = _makeAggregates(
        spendingByDayOfWeek: {
          'Mon': 500,
          'Tue': 600,
          'Wed': 550,
          'Thu': 500,
          'Fri': 600,
          'Sat': 80,
          'Sun': 70,
        },
      );
      final fact = rule.evaluate(aggregates);
      expect(fact, isA<WeekdayPeakFact>());
    });

    test('returns null when spending is balanced', () {
      final aggregates = _makeAggregates(
        spendingByDayOfWeek: {
          'Mon': 200,
          'Tue': 200,
          'Wed': 200,
          'Thu': 200,
          'Fri': 200,
          'Sat': 200,
          'Sun': 200,
        },
      );
      expect(rule.evaluate(aggregates), isNull);
    });

    test('returns null when all spending below threshold', () {
      final aggregates = _makeAggregates(
        spendingByDayOfWeek: {
          'Mon': 10,
          'Tue': 10,
          'Wed': 10,
          'Thu': 10,
          'Fri': 10,
          'Sat': 10,
          'Sun': 10,
        },
      );
      expect(rule.evaluate(aggregates), isNull);
    });
  });

  group('SpendingForecastRule', () {
    const rule = SpendingForecastRule();

    test('returns fact when projected exceeds previous by >5%', () {
      // avgDailySpend=1500, 30 days = 45000 projected vs 30000 previous = +50%
      final aggregates = _makeAggregates(
        avgDailySpend: 1500,
        previousFullExpense: 30000,
      );
      final fact = rule.evaluate(aggregates, periodKey: 'Month');

      // This test is date-dependent (requires day >= 7)
      final now = DateTime.now();
      if (now.day >= 7) {
        expect(fact, isA<SpendingForecastFact>());
      } else {
        expect(fact, isNull);
      }
    });

    test('returns null for non-Month period', () {
      final aggregates = _makeAggregates(
        avgDailySpend: 1500,
        previousFullExpense: 30000,
      );
      expect(rule.evaluate(aggregates, periodKey: 'Week'), isNull);
    });

    test('returns null when no previous data', () {
      final aggregates = _makeAggregates(avgDailySpend: 1500);
      expect(rule.evaluate(aggregates, periodKey: 'Month'), isNull);
    });

    test('returns null when variance is within 5%', () {
      // avgDailySpend=1000, 30 days = 30000 vs 29500 previous = ~1.7%
      final aggregates = _makeAggregates(
        avgDailySpend: 1000,
        previousFullExpense: 29500,
      );
      final fact = rule.evaluate(aggregates, periodKey: 'Month');
      // Within 5% threshold
      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final projected = 1000.0 * daysInMonth;
      final variance = (projected - 29500).abs();
      if (variance <= 29500 * 0.05) {
        expect(fact, isNull);
      }
    });
  });

  group('AnalyticsInsightEngine', () {
    test('generates facts from all rules', () {
      final aggregates = _makeAggregates(
        spendingByDayOfWeek: {
          'Mon': 100,
          'Tue': 100,
          'Wed': 100,
          'Thu': 100,
          'Fri': 100,
          'Sat': 800,
          'Sun': 700,
        },
      );

      final facts = AnalyticsInsightEngine.standard.generate(
        aggregates,
        periodKey: 'Month',
      );

      // Should have at least TopCategoryFact + WeekendPeakFact
      expect(facts.whereType<TopCategoryFact>(), hasLength(1));
      expect(facts.whereType<WeekendPeakFact>(), hasLength(1));
    });

    test('returns empty list when no rules match', () {
      final aggregates = _makeAggregates(
        totalExpense: 0,
        categoryBreakdown: {},
        spendingByDayOfWeek: {
          'Mon': 0,
          'Tue': 0,
          'Wed': 0,
          'Thu': 0,
          'Fri': 0,
          'Sat': 0,
          'Sun': 0,
        },
      );

      final facts = AnalyticsInsightEngine.standard.generate(aggregates);
      expect(facts, isEmpty);
    });

    test('custom engine with subset of rules', () {
      const engine = AnalyticsInsightEngine([TopCategoryRule()]);
      final aggregates = _makeAggregates(
        spendingByDayOfWeek: {
          'Mon': 100,
          'Tue': 100,
          'Wed': 100,
          'Thu': 100,
          'Fri': 100,
          'Sat': 800,
          'Sun': 700,
        },
      );

      final facts = engine.generate(aggregates, periodKey: 'Month');

      // Only TopCategoryRule — no pattern facts
      expect(facts.whereType<TopCategoryFact>(), hasLength(1));
      expect(facts.whereType<WeekendPeakFact>(), isEmpty);
    });
  });
}

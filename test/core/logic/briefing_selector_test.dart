import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/domain/financial_states.dart';
import 'package:mudra_manager/core/domain/insight.dart';
import 'package:mudra_manager/core/logic/briefing_selector.dart';

void main() {
  group('BriefingSelector', () {
    test('returns null for empty candidates', () {
      expect(BriefingSelector.select([]), isNull);
    });

    test('returns the single candidate', () {
      final insight = Insight(
        trigger: BriefingTrigger.budgetBreach,
        source: 'budget',
        magnitude: 500,
        confidence: 1.0,
        context: {'name': 'Food', 'over': 500.0},
      );
      final result = BriefingSelector.select([insight]);
      expect(result, isNotNull);
      expect(result!.insight.trigger, BriefingTrigger.budgetBreach);
    });

    test('picks highest priority trigger', () {
      final candidates = [
        const Insight(
          trigger: BriefingTrigger.netNegative, // priority 50
          source: 'cashflow',
          magnitude: 2000,
          confidence: 1.0,
          context: {'deficit': 2000.0},
        ),
        const Insight(
          trigger: BriefingTrigger.billDueToday, // priority 90
          source: 'bill',
          magnitude: 15000,
          confidence: 1.0,
          context: {'name': 'Rent', 'amount': 15000.0},
        ),
        const Insight(
          trigger: BriefingTrigger.budgetBreach, // priority 80
          source: 'budget',
          magnitude: 500,
          confidence: 1.0,
          context: {'name': 'Food', 'over': 500.0},
        ),
      ];

      final result = BriefingSelector.select(candidates);
      expect(result?.insight.trigger, BriefingTrigger.billDueToday);
    });

    test('billOverdue beats billDueToday', () {
      final candidates = [
        const Insight(
          trigger: BriefingTrigger.billDueToday,
          source: 'bill',
          magnitude: 15000,
          confidence: 1.0,
          context: {'name': 'Rent', 'amount': 15000.0},
        ),
        const Insight(
          trigger: BriefingTrigger.billOverdue,
          source: 'bill',
          magnitude: 5000,
          confidence: 1.0,
          context: {'name': 'Insurance', 'amount': 5000.0},
        ),
      ];

      final result = BriefingSelector.select(candidates);
      expect(result?.insight.trigger, BriefingTrigger.billOverdue);
    });

    test('preserves params and actionRoute of winner', () {
      final candidates = [
        const Insight(
          trigger: BriefingTrigger.billOverdue,
          source: 'bill',
          magnitude: 5000,
          confidence: 1.0,
          context: {'name': 'Insurance', 'amount': 5000.0},
          actionRoute: '/bills',
        ),
      ];

      final result = BriefingSelector.select(candidates)!;
      expect(result.params['name'], 'Insurance');
      expect(result.params['amount'], 5000.0);
      expect(result.actionRoute, '/bills');
    });
  });
}

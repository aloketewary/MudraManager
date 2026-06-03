import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/domain/financial_states.dart';
import 'package:mudra_manager/core/logic/briefing_selector.dart';

void main() {
  group('BriefingSelector', () {
    test('returns null for empty candidates', () {
      expect(BriefingSelector.select([]), isNull);
    });

    test('returns the single candidate', () {
      final candidate = BriefingSelection(
        trigger: BriefingTrigger.budgetBreach,
        params: {'name': 'Food', 'over': 500.0},
      );
      expect(BriefingSelector.select([candidate]), candidate);
    });

    test('picks highest priority trigger', () {
      final candidates = [
        const BriefingSelection(
          trigger: BriefingTrigger.netNegative, // priority 50
          params: {'deficit': 2000.0},
        ),
        const BriefingSelection(
          trigger: BriefingTrigger.billDueToday, // priority 90
          params: {'name': 'Rent', 'amount': 15000.0},
        ),
        const BriefingSelection(
          trigger: BriefingTrigger.budgetBreach, // priority 80
          params: {'name': 'Food', 'over': 500.0},
        ),
      ];

      final result = BriefingSelector.select(candidates);
      expect(result?.trigger, BriefingTrigger.billDueToday);
    });

    test('billOverdue beats billDueToday', () {
      final candidates = [
        const BriefingSelection(
          trigger: BriefingTrigger.billDueToday,
          params: {'name': 'Rent', 'amount': 15000.0},
        ),
        const BriefingSelection(
          trigger: BriefingTrigger.billOverdue,
          params: {'name': 'Insurance', 'amount': 5000.0},
        ),
      ];

      final result = BriefingSelector.select(candidates);
      expect(result?.trigger, BriefingTrigger.billOverdue);
    });

    test('preserves params and actionRoute of winner', () {
      final candidates = [
        const BriefingSelection(
          trigger: BriefingTrigger.billOverdue,
          params: {'name': 'Insurance', 'amount': 5000.0},
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

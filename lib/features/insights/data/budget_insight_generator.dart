import 'package:mudra_manager/core/domain/financial_states.dart';
import 'package:mudra_manager/core/domain/insight.dart';
import 'package:mudra_manager/core/logic/budget_state_machine.dart';
import 'package:mudra_manager/core/logic/insight_generator.dart';

class BudgetInsightGenerator implements InsightGenerator {
  final String? budgetActionRoute;

  const BudgetInsightGenerator({this.budgetActionRoute});

  @override
  String get source => 'budget';

  @override
  List<Insight> generate(Facts facts) {
    final insights = <Insight>[];

    for (final b in facts.budgets) {
      final state = BudgetStateMachine.classify(b.spent, b.limit);
      if (state == BudgetState.breach) {
        insights.add(Insight(
          trigger: BriefingTrigger.budgetBreach,
          source: source,
          magnitude: b.spent - b.limit,
          confidence: 1.0,
          context: {'name': b.name, 'over': b.spent - b.limit},
          actionRoute: budgetActionRoute,
        ),);
      }
    }

    return insights;
  }
}

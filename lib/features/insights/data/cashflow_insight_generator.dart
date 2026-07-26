import 'package:mudra_manager/core/domain/financial_states.dart';
import 'package:mudra_manager/core/domain/insight.dart';
import 'package:mudra_manager/core/logic/insight_generator.dart';

class CashflowInsightGenerator implements InsightGenerator {
  final String? actionRoute;

  const CashflowInsightGenerator({this.actionRoute});

  @override
  String get source => 'cashflow';

  @override
  List<Insight> generate(Facts facts) {
    final net = facts.totalIncome - facts.totalExpense;
    if (net < 0) {
      return [
        Insight(
          trigger: BriefingTrigger.netNegative,
          source: source,
          magnitude: net.abs(),
          confidence: 1.0,
          context: {'deficit': net.abs()},
          actionRoute: actionRoute,
        ),
      ];
    }
    return [];
  }
}

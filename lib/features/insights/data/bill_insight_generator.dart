import 'package:mudra_manager/core/domain/financial_states.dart';
import 'package:mudra_manager/core/domain/insight.dart';
import 'package:mudra_manager/core/domain/metrics.dart';
import 'package:mudra_manager/core/logic/bill_state_machine.dart';
import 'package:mudra_manager/core/logic/insight_generator.dart';

class BillInsightGenerator implements InsightGenerator {
  final String? billActionRoute;

  const BillInsightGenerator({this.billActionRoute});

  @override
  String get source => 'bill';

  @override
  List<Insight> generate(Facts facts) {
    final insights = <Insight>[];

    for (final bill in facts.bills) {
      final state = BillStateMachine.classify(
        bill.nextDueDate,
        facts.now,
        scanDone: facts.recurringScanDone,
      );

      switch (state) {
        case BillState.overdue:
          insights.add(Insight(
            trigger: BriefingTrigger.billOverdue,
            source: source,
            magnitude: bill.amount,
            confidence: 1.0,
            context: {'name': bill.name ?? '', 'amount': bill.amount},
            actionRoute: billActionRoute,
          ),);
        case BillState.dueToday:
          insights.add(Insight(
            trigger: BriefingTrigger.billDueToday,
            source: source,
            magnitude: bill.amount,
            confidence: 1.0,
            context: {'name': bill.name ?? '', 'amount': bill.amount},
            actionRoute: billActionRoute,
          ),);
        case BillState.dueSoon:
          insights.add(Insight(
            trigger: BriefingTrigger.billDueSoon,
            source: source,
            magnitude: bill.amount,
            confidence: 1.0,
            context: {
              'name': bill.name ?? '',
              'days': Metrics.daysUntilDue(bill.nextDueDate, facts.now),
            },
            actionRoute: billActionRoute,
          ),);
        default:
          break;
      }
    }

    return insights;
  }
}

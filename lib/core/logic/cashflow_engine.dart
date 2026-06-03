import 'package:mudra_manager/core/domain/financial_states.dart';
import 'package:mudra_manager/core/domain/metrics.dart';

/// Cashflow computation. Pure function.
class CashflowSnapshot {
  final double incomeTotal;
  final double expenseTotal;
  final double net;
  final double burnRate;
  final CashflowState state;

  const CashflowSnapshot({
    required this.incomeTotal,
    required this.expenseTotal,
    required this.net,
    required this.burnRate,
    required this.state,
  });
}

abstract final class CashflowEngine {
  static CashflowSnapshot compute({
    required double incomeTotal,
    required double expenseTotal,
    required double expenseLast7Days,
  }) {
    final net = Metrics.netCashflow(incomeTotal, expenseTotal);
    return CashflowSnapshot(
      incomeTotal: incomeTotal,
      expenseTotal: expenseTotal,
      net: net,
      burnRate: Metrics.burnRate(expenseLast7Days),
      state: Metrics.classifyCashflow(net, incomeTotal),
    );
  }
}

import 'package:mudra_manager/core/domain/financial_states.dart';

/// Pure metric definitions. Deterministic. Testable. No side effects.
abstract final class Metrics {
  static double netCashflow(double income, double expense) => income - expense;

  static double burnRate(double expenseLast7Days) => expenseLast7Days / 7;

  static double budgetRatio(double spent, double limit) =>
      limit > 0 ? spent / limit : 0;

  static int daysUntilDue(DateTime dueDate, DateTime today) =>
      DateTime(dueDate.year, dueDate.month, dueDate.day)
          .difference(DateTime(today.year, today.month, today.day))
          .inDays;

  static CashflowState classifyCashflow(double net, double income) {
    if (income <= 0) return CashflowState.neutral;
    if (net >= 0) return CashflowState.positive;
    return CashflowState.negative;
  }
}

import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
class OverspendPrediction {
  final int budgetId;
  final String budgetName;
  final double budgetAmount;
  final double currentSpent;
  final double dailyAverage;
  final int daysRemaining;
  final double projectedTotal;
  final double overspendAmount;
  final int daysUntilOverspend;
  final bool willOverspend;

  OverspendPrediction({
    required this.budgetId,
    required this.budgetName,
    required this.budgetAmount,
    required this.currentSpent,
    required this.dailyAverage,
    required this.daysRemaining,
    required this.projectedTotal,
    required this.overspendAmount,
    required this.daysUntilOverspend,
    required this.willOverspend,
  });

  String get warningMessage {
    if (!willOverspend) {
      return 'On track! You have ${formatCurrency((budgetAmount - currentSpent), code: BaseCurrency.code)} remaining.';
    }
    return 'At this rate, you will exceed $budgetName budget in $daysUntilOverspend ${daysUntilOverspend == 1 ? 'day' : 'days'}';
  }

  double get percentageOfBudget => (currentSpent / budgetAmount) * 100;
}

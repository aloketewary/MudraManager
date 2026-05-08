import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/features/budget/domain/overspend_prediction.dart';

class OverspendPredictionService {
  final AppLog _log = AppLog(getLogger(), 'OverspendPredictionService');

  Future<OverspendPrediction> calculatePrediction(
    Budget budget,
    double currentSpent,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final now = DateTime.now();
    final totalDays = endDate.difference(startDate).inDays + 1;
    final daysElapsed = now.difference(startDate).inDays + 1;
    final daysRemaining = endDate.difference(now).inDays;

    final dailyAverage = daysElapsed > 0 ? currentSpent / daysElapsed : 0;
    final projectedTotal = dailyAverage * totalDays;
    final overspendAmount = projectedTotal - budget.amount;
    final willOverspend = projectedTotal > budget.amount;

    int daysUntilOverspend = daysRemaining;
    if (dailyAverage > 0) {
      final remainingBudget = budget.amount - currentSpent;
      daysUntilOverspend = (remainingBudget / dailyAverage).ceil();
      if (daysUntilOverspend < 0) daysUntilOverspend = 0;
    }

    _log.i(
      'Prediction for ${budget.name}: '
      'Spent: ${formatCurrency(currentSpent.toDouble(), decimals: 0)}, Daily Avg: ${formatCurrency(dailyAverage.toDouble(), decimals: 2)}, '
      'Projected: ${formatCurrency(projectedTotal.toDouble(), decimals: 0)}, '
      'Will Overspend: $willOverspend',
    );

    return OverspendPrediction(
      budgetId: budget.id,
      budgetName: budget.name,
      budgetAmount: budget.amount,
      currentSpent: currentSpent,
      dailyAverage: dailyAverage.toDouble(),
      daysRemaining: daysRemaining,
      projectedTotal: projectedTotal.toDouble(),
      overspendAmount: overspendAmount,
      daysUntilOverspend: daysUntilOverspend,
      willOverspend: willOverspend,
    );
  }

  Future<List<OverspendPrediction>> getAllPredictions(
    List<(Budget, double, DateTime, DateTime)> budgetsWithSpent,
  ) async {
    final predictions = <OverspendPrediction>[];
    for (final (budget, spent, start, end) in budgetsWithSpent) {
      final prediction = await calculatePrediction(budget, spent, start, end);
      predictions.add(prediction);
    }
    return predictions;
  }

  Future<List<OverspendPrediction>> getCriticalPredictions(
    List<OverspendPrediction> predictions,
  ) async {
    return predictions
        .where((p) => p.willOverspend && p.daysUntilOverspend <= 3)
        .toList();
  }
}

import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/features/budget/domain/overspend_prediction.dart';

class OverspendPredictionService {
  static final OverspendPredictionService instance =
      OverspendPredictionService._();
  static final AppLog _log = AppLog(getLogger(), 'OverspendPredictionService');

  OverspendPredictionService._();

  /// Calculate overspend prediction for a budget
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

    // Calculate daily average spending
    final dailyAverage = daysElapsed > 0 ? currentSpent / daysElapsed : 0;

    // Project total spending by end of period
    final projectedTotal = dailyAverage * totalDays;

    // Calculate overspend
    final overspendAmount = projectedTotal - budget.amount;
    final willOverspend = projectedTotal > budget.amount;

    // Calculate days until overspend
    int daysUntilOverspend = daysRemaining;
    if (dailyAverage > 0) {
      final remainingBudget = budget.amount - currentSpent;
      daysUntilOverspend = (remainingBudget / dailyAverage).ceil();
      if (daysUntilOverspend < 0) daysUntilOverspend = 0;
    }

    _log.i(
      'Prediction for ${budget.name}: '
      'Spent: ₹$currentSpent, Daily Avg: ₹${dailyAverage.toStringAsFixed(2)}, '
      'Projected: ₹${projectedTotal.toStringAsFixed(0)}, '
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

  /// Get all overspend predictions for active budgets
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

  /// Get critical predictions (will overspend within 3 days)
  Future<List<OverspendPrediction>> getCriticalPredictions(
    List<OverspendPrediction> predictions,
  ) async {
    return predictions
        .where((p) => p.willOverspend && p.daysUntilOverspend <= 3)
        .toList();
  }
}

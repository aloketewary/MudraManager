import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/features/analytics/data/analytics_aggregation_service.dart';
import 'package:mudra_manager/features/analytics/data/advanced_analytics_service.dart';
import 'package:mudra_manager/features/analytics/domain/analytics_aggregates.dart';
import 'package:mudra_manager/features/analytics/domain/analytics_period.dart';
import 'package:mudra_manager/features/insights/domain/ai_summary.dart';

/// Service that generates AI-style conversational financial summaries.
///
/// Combines data from multiple analytics sources to create a coaching experience.
class AiSummaryService {
  final AdvancedAnalyticsService _analyticsService;
  final AnalyticsAggregationService _aggregationService;

  const AiSummaryService({
    required AdvancedAnalyticsService analyticsService,
    required AnalyticsAggregationService aggregationService,
  })  : _analyticsService = analyticsService,
        _aggregationService = aggregationService;

  /// Generate a conversational financial summary
  AiSummary generateSummary({
    required List<Transaction> transactions,
    required DateTime start,
    required DateTime end,
    required double predictedSpending,
    required double predictedSavings,
    required int daysUntilPayday,
  }) {
    final aggregates = _aggregationService.compute(
      transactions: transactions,
      start: start,
      end: end,
      periodType: 'Month',
    );

    final netFlow = aggregates.totalIncome - aggregates.totalExpense;
    final savingsRate = aggregates.savingsRate;

    // Determine greeting based on time and financial state
    final hour = DateTime.now().hour;
    final greeting = switch (hour) {
      < 12 => 'Good morning! Let\'s check your finances',
      < 17 => 'Good afternoon! Here\'s your financial update',
      < 21 => 'Good evening! Time for a financial check-in',
      _ => 'Hey night owl! Let\'s review your day',
    };

    // Generate positive highlight
    final positiveHighlight = _generatePositiveHighlight(
      netFlow: netFlow,
      savingsRate: savingsRate,
      aggregates: aggregates,
    );

    // Generate concern highlight
    final (concernHighlight, hasConcerns) = _generateConcernHighlight(
      netFlow: netFlow,
      savingsRate: savingsRate,
      aggregates: aggregates,
      predictedSpending: predictedSpending,
    );

    // Generate prediction
    final prediction = _generatePrediction(
      predictedSavings: predictedSavings,
      predictedSpending: predictedSpending,
      netFlow: netFlow,
    );

    return AiSummary(
      greeting: greeting,
      positiveHighlight: positiveHighlight,
      concernHighlight: concernHighlight,
      prediction: prediction,
      predictedSavings: predictedSavings > 0 ? predictedSavings : null,
      predictedSpending: predictedSpending,
      daysUntilPayday: daysUntilPayday,
      hasConcerns: hasConcerns,
    );
  }

  String _generatePositiveHighlight({
    required double netFlow,
    required double savingsRate,
    required AnalyticsAggregates aggregates,
  }) {
    if (netFlow > 0) {
      if (savingsRate >= 20) {
        return 'You\'re saving ${savingsRate.toStringAsFixed(0)}% of your income — that\'s fantastic discipline!';
      } else if (savingsRate >= 10) {
        return 'You\'re building a ${savingsRate.toStringAsFixed(0)}% savings rate. Keep it up!';
      } else {
        return 'You\'re ending the period positive with net flow of ₹${(netFlow / 1000).toStringAsFixed(1)}k';
      }
    }

    // Net flow is negative or zero - look for other positives
    if (aggregates.totalIncome > aggregates.totalExpense * 2) {
      return 'Your income is strong — twice your expenses. Great foundation!';
    }

    // Check if any category is trending down (improving)
    return 'You\'re on track with your financial journey. Small steps matter!';
  }

  (String highlight, bool hasConcerns) _generateConcernHighlight({
    required double netFlow,
    required double savingsRate,
    required AnalyticsAggregates aggregates,
    required double predictedSpending,
  }) {
    final concerns = <String>[];

    if (netFlow < 0) {
      concerns.add('You spent more than you earned this period');
    }

    if (savingsRate < 10 && netFlow > 0) {
      concerns.add('Your savings rate is below 10% — aim for 20%');
    }

    // Check for top category increase
    if (aggregates.categoryBreakdown.isNotEmpty) {
      final topCategory = aggregates.categoryBreakdown.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      if (topCategory.value > aggregates.totalExpense * 0.3) {
        concerns.add('${topCategory.key} takes ${(topCategory.value / aggregates.totalExpense * 100).toStringAsFixed(0)}% of spending');
      }
    }

    if (concerns.isEmpty) {
      return ('No major concerns this period!', false);
    }

    return (concerns.first, true);
  }

  String _generatePrediction({
    required double predictedSavings,
    required double predictedSpending,
    required double netFlow,
  }) {
    if (predictedSavings > 0) {
      return 'You\'re likely to save ₹${(predictedSavings / 1000).toStringAsFixed(1)}k this month';
    } else if (predictedSavings < 0) {
      return 'You may need to adjust — projections show ₹${(predictedSpending / 1000).toStringAsFixed(1)}k in spending';
    } else {
      return 'Your spending is tracking at ₹${(predictedSpending / 1000).toStringAsFixed(1)}k this month';
    }
  }
}
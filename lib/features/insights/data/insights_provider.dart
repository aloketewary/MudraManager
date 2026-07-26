import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/features/analytics/data/advanced_analytics_service.dart';
import 'package:mudra_manager/features/analytics/data/analytics_aggregation_service.dart';
import 'package:mudra_manager/features/analytics/data/analytics_provider.dart';
import 'package:mudra_manager/features/analytics/domain/analytics_aggregates.dart';
import 'package:mudra_manager/features/analytics/domain/analytics_period.dart';
import 'package:mudra_manager/features/analytics/domain/narrative_fact.dart';
import 'package:mudra_manager/features/insights/data/ai_summary_service.dart';
import 'package:mudra_manager/features/insights/domain/ai_summary.dart';
import 'package:mudra_manager/features/insights/domain/health_metrics.dart';
import 'package:mudra_manager/features/insights/domain/recommendation.dart';
import 'package:mudra_manager/features/insights/domain/spending_pattern.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';

/// Unified insights data combining AI summary, recommendations, and patterns.
final class InsightsData {
  final AiSummary aiSummary;
  final List<Recommendation> quickWins;
  final List<Recommendation> recommendations;
  final HealthMetrics healthMetrics;
  final List<SpendingPattern> hiddenPatterns;
  final List<NarrativeFact> narrativeFacts;
  final AnalyticsAggregates aggregates;

  const InsightsData({
    required this.aiSummary,
    required this.quickWins,
    required this.recommendations,
    required this.healthMetrics,
    required this.hiddenPatterns,
    required this.narrativeFacts,
    required this.aggregates,
  });
}

/// Provider for AI summary service
final insightsServiceProvider = Provider.autoDispose<AiSummaryService>((ref) {
  return AiSummaryService(
    analyticsService: ref.watch(analyticsServiceProvider),
    aggregationService: ref.watch(analyticsAggregationServiceProvider),
  );
});

/// Combined insights data provider
final insightsProvider = FutureProvider.autoDispose<InsightsData>((ref) async {
  final transactions = await ref.watch(analyticsTransactionsProvider.future);
  final aggregates =
      await ref.watch(analyticsAggregatesProvider('Month').future);
  final narrativeFacts =
      await ref.watch(analyticsNarrativeFactsProvider('Month').future);
  final predictedSpending = await ref.watch(predictedSpendingProvider.future);
  final healthScore = await ref.watch(financialHealthProvider.future);
  final spendingByDay = await ref.watch(spendingByDayProvider.future);
  final risingCategories = await ref.watch(risingCategoriesProvider.future);
  final anomalies = await ref.watch(anomalyCategoriesProvider.future);

  final service = ref.watch(insightsServiceProvider);
  final period = AnalyticsPeriodParser.fromKey('Month');
  final periodDates = period.resolve();

  // Calculate days until payday from salary/income transactions
  final incomeTransactions = transactions.where((tx) => tx.isExpense == false).toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  final today = DateTime.now();
  final nextPayday = incomeTransactions.isNotEmpty
      ? incomeTransactions.firstWhere(
          (tx) => tx.date.isAfter(today) || tx.date.isAtSameMomentAs(today),
          orElse: () => incomeTransactions.last,
        ).date
      : today.add(const Duration(days: 30));
  final daysUntilPayday = nextPayday.difference(today).inDays.clamp(0, 31);

  // Generate AI summary
  final aiSummary = service.generateSummary(
    transactions: transactions,
    start: periodDates.start,
    end: periodDates.end,
    predictedSpending: predictedSpending,
    predictedSavings: aggregates.totalIncome - aggregates.totalExpense,
    daysUntilPayday: daysUntilPayday,
  );

  // Generate quick wins
  final quickWins = _generateQuickWins(
    healthScore: healthScore,
    aggregates: aggregates,
    predictedSpending: predictedSpending,
  );

  // Generate personalized recommendations
  final recommendations = _generateRecommendations(
    healthScore: healthScore,
    aggregates: aggregates,
    risingCategories: risingCategories,
    anomalies: anomalies,
  );

  // Generate health metrics breakdown
  final healthMetrics = _buildHealthMetrics(healthScore, aggregates);

  // Generate hidden patterns
  final hiddenPatterns = _detectHiddenPatterns(
    spendingByDay: spendingByDay,
    aggregates: aggregates,
    transactions: transactions,
  );

  return InsightsData(
    aiSummary: aiSummary,
    quickWins: quickWins,
    recommendations: recommendations,
    healthMetrics: healthMetrics,
    hiddenPatterns: hiddenPatterns,
    narrativeFacts: narrativeFacts,
    aggregates: aggregates,
  );
});

List<Recommendation> _generateQuickWins({
  required FinancialHealthScore healthScore,
  required AnalyticsAggregates aggregates,
  required double predictedSpending,
}) {
  final wins = <Recommendation>[];
  final brightness = Brightness.dark;

  // Savings opportunity
  if (healthScore.score < 60) {
    final potentialSavings = aggregates.totalIncome * 0.1;
    wins.add(
      Recommendation(
        id: 'boost_savings',
        title: 'Set up automatic savings',
        description: 'Transfer 10% of income to savings on payday',
        subtitle:
            'Could save ₹${(potentialSavings / 1000).toStringAsFixed(1)}k/month',
        category: RecommendationCategory.savings,
        icon: LucideIcons.piggyBank,
        iconColor: FinanceColors.incomeColor(brightness),
        priority: RecommendationPriority.high,
        potentialSavings: potentialSavings,
        actionRoute: '/budget/create',
        actionLabel: 'Create Budget',
      ),
    );
  }

  // Budget warning
  if (predictedSpending > aggregates.totalIncome) {
    wins.add(
      const Recommendation(
        id: 'reduce_spending',
        title: 'Review upcoming expenses',
        description: 'Your projected spending exceeds income',
        category: RecommendationCategory.budgeting,
        icon: LucideIcons.alertCircle,
        iconColor: FinanceColors.statusWarning,
        priority: RecommendationPriority.high,
        actionRoute: '/analytics/trends',
        actionLabel: 'See Trends',
      ),
    );
  }

  // Top category insight
  if (aggregates.categoryBreakdown.isNotEmpty) {
    final topCategory = aggregates.categoryBreakdown.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    if (topCategory.value > aggregates.totalExpense * 0.3) {
      wins.add(
        Recommendation(
          id: 'review_category',
          title: 'Review ${topCategory.key} spending',
          description:
              'This category is ${(topCategory.value / aggregates.totalExpense * 100).toStringAsFixed(0)}% of your spending',
          category: RecommendationCategory.lifestyle,
          icon: LucideIcons.chartPie,
          iconColor: FinanceColors.expenseColor(brightness),
          priority: RecommendationPriority.medium,
          actionRoute: '/category/${Uri.encodeComponent(topCategory.key)}',
          actionLabel: 'View Details',
        ),
      );
    }
  }

  return wins.take(3).toList();
}

List<Recommendation> _generateRecommendations({
  required FinancialHealthScore healthScore,
  required AnalyticsAggregates aggregates,
  required List<CategoryTrend> risingCategories,
  required List<CategoryTrend> anomalies,
}) {
  final recommendations = <Recommendation>[];
  final brightness = Brightness.dark;

  // Rising category warnings
  for (final category in risingCategories.take(2)) {
    recommendations.add(
      Recommendation(
        id: 'rising_${category.categoryName}',
        title: '${category.categoryName} spending is up',
        description:
            '${category.changePercent.toStringAsFixed(0)}% increase vs last month',
        category: RecommendationCategory.lifestyle,
        icon: LucideIcons.trendingUp,
        iconColor: FinanceColors.expenseColor(brightness),
        priority: RecommendationPriority.medium,
        actionRoute: '/category/${Uri.encodeComponent(category.categoryName)}',
        actionLabel: 'Review',
      ),
    );
  }

  // Subscription check
  recommendations.add(
    const Recommendation(
      id: 'subscription_review',
      title: 'Check your subscriptions',
      description: 'Review recurring payments and cancel unused services',
      category: RecommendationCategory.subscription,
      icon: LucideIcons.refreshCw,
      iconColor: FinanceColors.statusWarning,
      priority: RecommendationPriority.low,
      actionRoute: '/recurring',
      actionLabel: 'View Subscriptions',
    ),
  );

  return recommendations;
}

HealthMetrics _buildHealthMetrics(
  FinancialHealthScore healthScore,
  AnalyticsAggregates aggregates,
) {
  return HealthMetrics(
    overallScore: healthScore.score.toDouble(),
    savingsHealth: HealthScoreBreakdown(
      label: 'Savings Rate',
      description:
          '${healthScore.savingsRate.toStringAsFixed(0)}% of income saved',
      score: (healthScore.savingsRate).clamp(0, 100),
      maxScore: 100,
      tip: healthScore.savingsRate < 20 ? 'Aim to save 20% of income' : null,
    ),
    incomeStability: HealthScoreBreakdown(
      label: 'Income Stability',
      description: 'Income exceeds expenses',
      score: aggregates.totalIncome > aggregates.totalExpense ? 80 : 40,
      maxScore: 100,
      tip: null,
    ),
    emergencyFund: HealthScoreBreakdown(
      label: 'Emergency Fund',
      description: 'Based on monthly expenses',
      score: (healthScore.score * 0.3).clamp(0, 100),
      maxScore: 100,
      tip: 'Target 3-6 months of expenses',
    ),
    debtHealth: HealthScoreBreakdown(
      label: 'Debt Health',
      description: healthScore.score >= 60
          ? 'No high-interest debt'
          : 'Consider debt payoff',
      score: healthScore.score >= 60 ? 80 : 50,
      maxScore: 100,
      tip: null,
    ),
    budgetAdherence: HealthScoreBreakdown(
      label: 'Budget Discipline',
      description: 'Spending within means',
      score: aggregates.totalExpense < aggregates.totalIncome ? 90 : 30,
      maxScore: 100,
      tip: null,
    ),
  );
}

List<SpendingPattern> _detectHiddenPatterns({
  required Map<String, double> spendingByDay,
  required AnalyticsAggregates aggregates,
  required List<Transaction> transactions,
}) {
  final patterns = <SpendingPattern>[];

  // Weekend pattern
  final weekendTotal =
      ((spendingByDay['Sat'] ?? 0) + (spendingByDay['Sun'] ?? 0)).toDouble();
  final weekdayTotal = (aggregates.totalExpense - weekendTotal).toDouble();
  final weekendPercentage = aggregates.totalExpense > 0
      ? (weekendTotal / aggregates.totalExpense * 100)
      : 0.0;

  if (weekendPercentage > 30) {
    patterns.add(
      WeekendSpendingPattern(
        weekendTotal: weekendTotal,
        weekdayTotal: weekdayTotal,
        weekendPercentage: weekendPercentage,
        peakDay: (spendingByDay['Sat'] ?? 0) > (spendingByDay['Sun'] ?? 0)
            ? 'Saturday'
            : 'Sunday',
        isHighWeekendSpender: true,
      ),
    );
  }

  // Late-night pattern
  final nightTransactions = transactions.where((tx) {
    final hour = tx.date.hour;
    return tx.isExpense == true && hour >= 0 && hour < 5;
  }).toList();

  if (nightTransactions.isNotEmpty) {
    final nightTotal = nightTransactions.fold<double>(
      0,
      (sum, tx) => sum + (tx.effectiveAmount),
    );
    final percentageOfTotal = aggregates.totalExpense > 0
        ? (nightTotal / aggregates.totalExpense * 100)
        : 0;

    patterns.add(
      LateNightPattern(
        lateNightTransactionCount: nightTransactions.length,
        lateNightTotal: nightTotal,
        percentageOfTotal: percentageOfTotal.toDouble(),
      ),
    );
  }

  return patterns;
}

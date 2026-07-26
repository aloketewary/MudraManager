import 'package:flutter/material.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';

/// Detailed financial health metrics breakdown.
///
/// Individual components that contribute to the overall financial health score.
final class HealthMetrics {
  final double overallScore; // 0-100
  final HealthScoreBreakdown savingsHealth;
  final HealthScoreBreakdown incomeStability;
  final HealthScoreBreakdown emergencyFund;
  final HealthScoreBreakdown debtHealth;
  final HealthScoreBreakdown budgetAdherence;

  const HealthMetrics({
    required this.overallScore,
    required this.savingsHealth,
    required this.incomeStability,
    required this.emergencyFund,
    required this.debtHealth,
    required this.budgetAdherence,
  });

  /// Overall rating based on score
  String get rating => switch (overallScore) {
        >= 80 => 'Excellent',
        >= 60 => 'Good',
        >= 40 => 'Fair',
        _ => 'Needs Attention',
      };

  Color ratingColor(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return switch (overallScore) {
      >= 80 => FinanceColors.incomeColor(Theme.of(context).brightness),
      >= 60 => color.primary,
      >= 40 => FinanceColors.statusWarning,
      _ => FinanceColors.expenseColor(Theme.of(context).brightness),
    };
  }
}

/// Individual health score breakdown component
final class HealthScoreBreakdown {
  final String label;
  final String description;
  final double score; // 0-100 for this component
  final double maxScore;
  final String? tip; // Actionable tip for improvement

  const HealthScoreBreakdown({
    required this.label,
    required this.description,
    required this.score,
    required this.maxScore,
    this.tip,
  });

  double get percentage => maxScore > 0 ? score / maxScore : 0;

  bool get isHealthy => percentage >= 0.8;
  bool get isWarning => percentage >= 0.5 && percentage < 0.8;
  bool get isCritical => percentage < 0.5;
}
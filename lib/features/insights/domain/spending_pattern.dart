import 'package:flutter/material.dart';

/// Hidden spending patterns discovered from transaction analysis.
///
/// Represents behavioral insights like weekend spending, late-night purchases,
/// subscription growth, and seasonal patterns.
sealed class SpendingPattern {
  const SpendingPattern();
}

/// Weekend vs weekday spending pattern
final class WeekendSpendingPattern extends SpendingPattern {
  final double weekendTotal;
  final double weekdayTotal;
  final double weekendPercentage;
  final String peakDay; // e.g., "Saturday"
  final bool isHighWeekendSpender;

  const WeekendSpendingPattern({
    required this.weekendTotal,
    required this.weekdayTotal,
    required this.weekendPercentage,
    required this.peakDay,
    required this.isHighWeekendSpender,
  });
}

/// Late-night purchases pattern (midnight to 5am)
final class LateNightPattern extends SpendingPattern {
  final int lateNightTransactionCount;
  final double lateNightTotal;
  final double percentageOfTotal;
  final String? mostCommonCategory; // Category with most late-night spending

  const LateNightPattern({
    required this.lateNightTransactionCount,
    required this.lateNightTotal,
    required this.percentageOfTotal,
    this.mostCommonCategory,
  });
}

/// Subscription growth pattern
final class SubscriptionGrowthPattern extends SpendingPattern {
  final int activeSubscriptionCount;
  final double monthlySubscriptionTotal;
  final double monthOverMonthGrowth;
  final double yearOverYearGrowth;
  final bool isGrowingFasterThanIncome;

  const SubscriptionGrowthPattern({
    required this.activeSubscriptionCount,
    required this.monthlySubscriptionTotal,
    required this.monthOverMonthGrowth,
    required this.yearOverYearGrowth,
    required this.isGrowingFasterThanIncome,
  });
}

/// Category changes pattern
final class CategoryChangePattern extends SpendingPattern {
  final List<CategoryChange> newCategories;
  final List<CategoryChange> increasedCategories;
  final List<CategoryChange> decreasedCategories;

  const CategoryChangePattern({
    required this.newCategories,
    required this.increasedCategories,
    required this.decreasedCategories,
  });
}

final class CategoryChange {
  final String categoryName;
  final double amountChange;
  final double percentageChange;
  final bool isSignificant; // >20% change

  const CategoryChange({
    required this.categoryName,
    required this.amountChange,
    required this.percentageChange,
    required this.isSignificant,
  });
}

/// Salary week behavior pattern
final class SalaryWeekPattern extends SpendingPattern {
  final double averageSpendInSalaryWeek;
  final double averageSpendOtherWeek;
  final double salaryWeekMultiplier;
  final bool hasSalaryWeekSpendingSpike;

  const SalaryWeekPattern({
    required this.averageSpendInSalaryWeek,
    required this.averageSpendOtherWeek,
    required this.salaryWeekMultiplier,
    required this.hasSalaryWeekSpendingSpike,
  });
}

/// Seasonal spending pattern
final class SeasonalPattern extends SpendingPattern {
  final String seasonName; // e.g., "Holiday Season", "Summer"
  final double seasonAverage;
  final double baselineAverage;
  final double seasonalMultiplier;
  final bool isHighSeason;

  const SeasonalPattern({
    required this.seasonName,
    required this.seasonAverage,
    required this.baselineAverage,
    required this.seasonalMultiplier,
    required this.isHighSeason,
  });
}

/// UI presentation for spending pattern
final class SpendingPatternPresentation {
  final IconData icon;
  final String title;
  final String description;
  final String insight;
  final Color color;

  const SpendingPatternPresentation({
    required this.icon,
    required this.title,
    required this.description,
    required this.insight,
    required this.color,
  });
}
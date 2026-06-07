import 'package:flutter/material.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Sealed class representing types of narrative findings.
sealed class NarrativeFact {
  const NarrativeFact();
}

/// Spending in a category has significantly increased compared to baseline.
final class SpendingAccelerationFact extends NarrativeFact {
  final String category;
  final double percentage;
  final double amount;

  const SpendingAccelerationFact({
    required this.category,
    required this.percentage,
    required this.amount,
  });
}

/// Spending in a category has significantly decreased compared to baseline.
final class SpendingDecelerationFact extends NarrativeFact {
  final String category;
  final double percentage;

  const SpendingDecelerationFact({
    required this.category,
    required this.percentage,
  });
}

/// A specific category is the top driver of spending in the period.
final class TopCategoryFact extends NarrativeFact {
  final String category;
  final double percentage;

  const TopCategoryFact({
    required this.category,
    required this.percentage,
  });
}

/// A new category appeared that had no spending in the previous period.
final class NewSpendingCategoryFact extends NarrativeFact {
  final String category;
  final double amount;

  const NewSpendingCategoryFact({
    required this.category,
    required this.amount,
  });
}

/// A category that had spending in the previous period has no spending now.
final class CategoryStoppedFact extends NarrativeFact {
  final String category;
  final double previousAmount;

  const CategoryStoppedFact({
    required this.category,
    required this.previousAmount,
  });
}

/// Spending peaks on specific days (e.g., weekends).
final class WeekendPeakFact extends NarrativeFact {
  final String peakDay;

  const WeekendPeakFact({required this.peakDay});
}

/// Spending peaks on weekdays.
final class WeekdayPeakFact extends NarrativeFact {
  final String peakDay;

  const WeekdayPeakFact({required this.peakDay});
}

/// Identified peak and quiet days.
final class PeakAndQuietFact extends NarrativeFact {
  final String peakDay;
  final String quietDay;

  const PeakAndQuietFact({required this.peakDay, required this.quietDay});
}

/// Projection for the remainder of the month.
final class SpendingForecastFact extends NarrativeFact {
  final double projectedAmount;
  final double variance;
  final String? comparisonPeriod;

  const SpendingForecastFact({
    required this.projectedAmount,
    required this.variance,
    this.comparisonPeriod,
  });
}

/// Indicates insufficient historical data to make a comparison.
final class InsufficientHistoryFact extends NarrativeFact {
  const InsufficientHistoryFact();
}

/// UI-ready representation of a NarrativeFact.
class NarrativePresentation {
  final String text;
  final IconData icon;
  final Color color;

  const NarrativePresentation({
    required this.text,
    required this.icon,
    required this.color,
  });
}

/// Mapper that transforms domain Facts into localized UI presentations.
class NarrativeMapper {
  static NarrativePresentation map(
    NarrativeFact fact,
    AppLocalizations l10n,
    Brightness brightness,
    ColorScheme colorScheme,
  ) {
    return switch (fact) {
      final SpendingAccelerationFact f => NarrativePresentation(
          text: l10n.stats_trendUp(f.category, f.percentage.toStringAsFixed(0)),
          icon: LucideIcons.trendingUp,
          color: FinanceColors.expenseColor(brightness),
        ),
      final SpendingDecelerationFact f => NarrativePresentation(
          text: l10n.stats_trendDown(f.category),
          icon: LucideIcons.trendingDown,
          color: FinanceColors.incomeColor(brightness),
        ),
      final TopCategoryFact f => NarrativePresentation(
          text: l10n.stats_topCategory(
            f.category,
            f.percentage.toStringAsFixed(0),
          ),
          icon: LucideIcons.sparkles,
          color: colorScheme.primary,
        ),
      final NewSpendingCategoryFact f => NarrativePresentation(
          text: l10n.stats_newCategory(f.category),
          icon: LucideIcons.plusCircle,
          color: colorScheme.secondary,
        ),
      final CategoryStoppedFact f => NarrativePresentation(
          text: l10n.stats_categoryStopped(f.category),
          icon: LucideIcons.checkCircle,
          color: FinanceColors.incomeColor(brightness),
        ),
      final WeekendPeakFact f => NarrativePresentation(
          text: l10n.stats_weekendPeak(f.peakDay),
          icon: LucideIcons.calendarRange,
          color: FinanceColors.expenseColor(brightness),
        ),
      final WeekdayPeakFact f => NarrativePresentation(
          text: l10n.stats_weekdayPeak(f.peakDay),
          icon: LucideIcons.briefcase,
          color: FinanceColors.statusWarning,
        ),
      final PeakAndQuietFact f => NarrativePresentation(
          text: l10n.stats_peakAndQuiet(f.peakDay, f.quietDay),
          icon: LucideIcons.chartBar,
          color: colorScheme.primary,
        ),
      final SpendingForecastFact f => NarrativePresentation(
          text: f.variance > 0
              ? l10n.stats_forecastHigher(f.comparisonPeriod ?? "last month")
              : l10n.stats_forecastLower(f.comparisonPeriod ?? "last month"),
          icon: LucideIcons.trendingUp,
          color: f.variance > 0
              ? FinanceColors.expenseColor(brightness)
              : FinanceColors.incomeColor(brightness),
        ),
      InsufficientHistoryFact _ => NarrativePresentation(
          text: l10n.stats_spendingSteady,
          icon: LucideIcons.shieldCheck,
          color: colorScheme.primary,
        ),
    };
  }
}

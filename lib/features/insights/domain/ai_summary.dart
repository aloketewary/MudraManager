import 'package:flutter/material.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';

/// AI-generated conversational financial summary for the Insights page.
///
/// Represents a personal coach message that summarizes:
/// - Overall financial status (positive/concern)
/// - Key insight (e.g., "You're spending 23% more on dining")
/// - Prediction (e.g., "You likely will save ₹12,400 this month")
final class AiSummary {
  final String greeting; // e.g., "Hey! Let's look at your finances"
  final String positiveHighlight; // What's going well
  final String concernHighlight; // What needs attention
  final String prediction; // What's likely to happen
  final double? predictedSavings; // Expected savings amount
  final double predictedSpending; // Expected spending
  final int daysUntilPayday; // Next paycheck countdown
  final bool hasConcerns; // Whether there are issues to address

  const AiSummary({
    required this.greeting,
    required this.positiveHighlight,
    required this.concernHighlight,
    required this.prediction,
    this.predictedSavings,
    required this.predictedSpending,
    required this.daysUntilPayday,
    required this.hasConcerns,
  });
}

/// UI presentation model for AiSummary
final class AiSummaryPresentation {
  final String title;
  final String positiveText;
  final String? concernText;
  final String predictionText;
  final bool showConcern;

  const AiSummaryPresentation({
    required this.title,
    required this.positiveText,
    this.concernText,
    required this.predictionText,
    required this.showConcern,
  });

  static AiSummaryPresentation fromDomain(
    AiSummary summary,
    AppLocalizations l10n,
    Brightness brightness,
  ) {
    return AiSummaryPresentation(
      title: summary.greeting,
      positiveText: summary.positiveHighlight,
      concernText: summary.hasConcerns ? summary.concernHighlight : null,
      predictionText: summary.prediction,
      showConcern: summary.hasConcerns,
    );
  }
}
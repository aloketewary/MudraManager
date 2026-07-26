import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Actionable financial recommendation with clear CTA.
///
/// Represents a "Quick Win" or personalized recommendation
/// that users can act on immediately.
final class Recommendation {
  final String id;
  final String title;
  final String description;
  final String? subtitle; // Optional secondary text
  final RecommendationCategory category;
  final IconData icon;
  final Color iconColor;
  final RecommendationPriority priority;
  final double? potentialSavings; // Estimated savings amount
  final String actionRoute; // Deep link route when tapped
  final String actionLabel; // CTA button text

  const Recommendation({
    required this.id,
    required this.title,
    required this.description,
    this.subtitle,
    required this.category,
    required this.icon,
    required this.iconColor,
    required this.priority,
    this.potentialSavings,
    required this.actionRoute,
    required this.actionLabel,
  });
}

enum RecommendationCategory {
  savings,
  budgeting,
  debt,
  investment,
  subscription,
  lifestyle,
  alert,
}

enum RecommendationPriority {
  high, // Urgent - show prominently
  medium, // Important - show in list
  low, // Nice to have - show last
}

extension RecommendationCategoryX on RecommendationCategory {
  String get label => switch (this) {
        RecommendationCategory.savings => 'Savings',
        RecommendationCategory.budgeting => 'Budgeting',
        RecommendationCategory.debt => 'Debt Payoff',
        RecommendationCategory.investment => 'Investment',
        RecommendationCategory.subscription => 'Subscription',
        RecommendationCategory.lifestyle => 'Lifestyle',
        RecommendationCategory.alert => 'Alert',
      };

  IconData get icon => switch (this) {
        RecommendationCategory.savings => LucideIcons.piggyBank,
        RecommendationCategory.budgeting => LucideIcons.target,
        RecommendationCategory.debt => LucideIcons.creditCard,
        RecommendationCategory.investment => LucideIcons.trendingUp,
        RecommendationCategory.subscription => LucideIcons.refreshCw,
        RecommendationCategory.lifestyle => LucideIcons.badgeCheck,
        RecommendationCategory.alert => LucideIcons.alertTriangle,
      };
}
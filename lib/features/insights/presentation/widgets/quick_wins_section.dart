import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/features/insights/domain/recommendation.dart';
import 'package:mudra_manager/features/insights/presentation/widgets/recommendation_card.dart';
import 'package:mudra_manager/shared/widgets/type_section_header.dart';

/// Quick Wins section showing actionable recommendations.
///
/// Displays up to 3 prioritized recommendations with clear CTAs.
/// Users can act on these immediately to improve their finances.
class QuickWinsSection extends ConsumerWidget {
  final List<Recommendation> quickWins;
  final VoidCallback? onRecommendationTap;

  const QuickWinsSection({
    super.key,
    required this.quickWins,
    this.onRecommendationTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);


    if (quickWins.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TypeSectionHeader(
          label: 'Quick Wins',
          icon: LucideIcons.zap,
          accentColor: FinanceColors.statusWarning,
        ),
        SizedBox(height: spacing.sectionGap),
        ...quickWins.map(
          (recommendation) => Padding(
            padding: EdgeInsets.only(bottom: spacing.elementGap),
            child: RecommendationCard(
              recommendation: recommendation,
              onTap: onRecommendationTap,
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact horizontal scrolling Quick Wins for tight spaces
class QuickWinsChips extends ConsumerWidget {
  final List<Recommendation> quickWins;
  final VoidCallback? onTap;

  const QuickWinsChips({
    super.key,
    required this.quickWins,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);

    if (quickWins.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              LucideIcons.zap,
              size: 14,
              color: FinanceColors.statusWarning,
            ),
            SizedBox(width: spacing.elementGapMin),
            Text(
              'Quick Wins',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        SizedBox(height: spacing.elementGap),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: quickWins.length,
            separatorBuilder: (_, __) => SizedBox(width: spacing.elementGap),
            itemBuilder: (context, index) => RecommendationChip(
              recommendation: quickWins[index],
              onTap: onTap,
            ),
          ),
        ),
      ],
    );
  }
}
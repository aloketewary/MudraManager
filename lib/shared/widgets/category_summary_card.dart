import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Summary card showing category overview with counts and type breakdown.
///
/// Usage:
/// ```dart
/// CategorySummaryCard(
///   categoryCount: 12,
///   expenseCount: 8,
///   incomeCount: 4,
///   transactionCount: 156,
/// )
/// ```
class CategorySummaryCard extends ConsumerWidget {
  final int categoryCount;
  final int expenseCount;
  final int incomeCount;
  final int transactionCount;

  const CategorySummaryCard({
    super.key,
    required this.categoryCount,
    required this.expenseCount,
    required this.incomeCount,
    required this.transactionCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch<AppSpacing>(spacingProvider);
    final isDark = color.brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Semantics(
      label: 'Categories overview',
      container: true,
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.3),
            radius: 1.4,
            colors: [
              color.primary.withValues(alpha: isDark ? 0.18 : 0.12),
              color.primary.withValues(alpha: isDark ? 0.08 : 0.05),
              color.surface.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: RepaintBoundary(
          child: Stack(
            children: [
              // Ambient glow
              Positioned(
                right: -50,
                top: -50,
                child: RepaintBoundary(
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          color.primary.withValues(alpha: isDark ? 0.15 : 0.1),
                          color.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: EdgeInsets.all(spacing.cardInner + spacing.elementGap),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with icon
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(spacing.elementGap),
                          decoration: BoxDecoration(
                            color: color.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(spacing.radiusSmall),
                            border: Border.all(
                              color: color.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Icon(
                            LucideIcons.tags,
                            color: color.primary,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: spacing.sectionGap),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$categoryCount',
                                style: textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: color.onSurface,
                                ),
                                semanticsLabel: '$categoryCount total categories',
                              ),
                              Text(
                                AppLocalizations.of(context)!.categories_label,
                                style: textTheme.labelMedium?.copyWith(
                                  color: color.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing.sectionGap),
                    // Stats grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            context: context,
                            label: 'Expense',
                            icon: LucideIcons.arrowUpRight,
                            count: expenseCount,
                            color: color.error,
                            textTheme: textTheme,
                            spacing: spacing,
                            reduceMotion: reduceMotion,
                          ),
                        ),
                        SizedBox(width: spacing.elementGap),
                        Expanded(
                          child: _buildStatItem(
                            context: context,
                            label: 'Income',
                            icon: LucideIcons.arrowDownLeft,
                            count: incomeCount,
                            color: color.primary,
                            textTheme: textTheme,
                            spacing: spacing,
                            reduceMotion: reduceMotion,
                          ),
                        ),
                        SizedBox(width: spacing.elementGap),
                        Expanded(
                          child: _buildStatItem(
                            context: context,
                            label: 'Txn',
                            icon: LucideIcons.arrowUpDown,
                            count: transactionCount,
                            color: color.tertiary,
                            textTheme: textTheme,
                            spacing: spacing,
                            reduceMotion: reduceMotion,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
    required String label,
    required IconData icon,
    required int count,
    required Color color,
    required TextTheme textTheme,
    required AppSpacing spacing,
    required bool reduceMotion,
  }) {
    return AnimatedContainer(
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(
        horizontal: spacing.elementGap,
        vertical: spacing.elementGap,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 12,
                color: color.withValues(alpha: 0.8),
              ),
              SizedBox(width: spacing.elementGapMin),
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.elementGapMin),
          Text(
            '$count',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
            semanticsLabel: '$count $label',
          ),
        ],
      ),
    );
  }
}
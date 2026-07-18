import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/features/analytics/data/analytics_provider.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/shared/widgets/progress_ring.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class FinancialHealthCard extends ConsumerWidget {
  final double globalPadding;

  const FinancialHealthCard({super.key, required this.globalPadding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(financialHealthProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);

    return healthAsync.when(
      data: (health) {
        if (health.score == 0) return const SizedBox.shrink();

        final scoreColor = _scoreColor(health.score, color);
        final verdict = _verdict(health.score);
        final topInsight =
            health.insights.isNotEmpty ? health.insights.first : null;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: globalPadding),
          child: Card(
            elevation: 0,
            color: color.surfaceContainerLow,
            margin: const EdgeInsets.only(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              side: BorderSide(
                color: scoreColor.withValues(alpha: 0.2),
              ),
            ),
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                context.push(AppRoutes.financialHealth);
              },
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              child: Padding(
                padding: EdgeInsets.all(spacing.cardInner),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Ring + Score + Verdict
                    Row(
                      children: [
                        ProgressRing(
                          progress: health.score / 100,
                          color: scoreColor,
                          size: spacing.sectionGap * 2,
                          strokeWidth: 5,
                          insetPadding: spacing.cardVerticalMin,
                          duration: const Duration(milliseconds: 1200),
                          labelBuilder: (value) => Text(
                            '${(value * 100).toInt()}',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: scoreColor,
                            ),
                          ),
                        ),
                        SizedBox(width: spacing.elementGap * 1.5),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Financial Health',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: spacing.elementGapMin),
                              // Verdict badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: spacing.elementGap,
                                  vertical: spacing.elementGapUltraMin,
                                ),
                                decoration: BoxDecoration(
                                  color: scoreColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                    spacing.radiusSmall,
                                  ),
                                ),
                                child: Text(
                                  '${health.rating} — $verdict',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: scoreColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: color.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                      ],
                    ),

                    // Row 2: Key insight
                    if (topInsight != null) ...[
                      SizedBox(height: spacing.elementGap * 1.5),
                      Text(
                        topInsight,
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    SizedBox(height: spacing.elementGap),

                    // Row 3: Tap hint
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Tap to explore',
                          style: textTheme.labelSmall?.copyWith(
                            color:
                                color.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        SizedBox(width: spacing.elementGapMin),
                        Icon(
                          LucideIcons.arrowRight,
                          size: 12,
                          color: color.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOut).slideY(
              begin: 0.05,
              end: 0,
              duration: 400.ms,
              curve: Curves.easeOut,
            );
      },
      loading: () => Padding(
        padding: EdgeInsets.only(top: spacing.sectionGap),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: globalPadding),
          child: const DashboardCardSkeleton(),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _verdict(int score) {
    if (score >= 80) return 'great shape';
    if (score >= 60) return 'on track';
    if (score >= 40) return 'needs work';
    return 'needs attention';
  }

  Color _scoreColor(int score, ColorScheme color) {
    if (score >= 80) return FinanceColors.statusGood;
    if (score >= 60) return color.primary;
    if (score >= 40) return FinanceColors.statusWarning;
    return FinanceColors.statusDanger;
  }
}

import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/entitlement/entitlement_feature.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/features/analytics/data/spending_analyzer.dart';
import 'package:mudra_manager/features/analytics/data/personality_archetype.dart';
import 'package:mudra_manager/shared/widgets/pro_gate.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

final spendingPersonalityProvider =
    FutureProvider<SpendingPersonality?>((ref) async {
  return await SpendingAnalyzer.analyzePersonality();
});

class SpendingPersonalityCard extends ConsumerWidget {
  final double globalPadding;

  const SpendingPersonalityCard({super.key, required this.globalPadding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personality = ref.watch(spendingPersonalityProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);

    return personality.when(
      data: (data) {
        if (data == null) return const SizedBox.shrink();

        final archetype = PersonalityArchetype.fromSpendingPersonality(data);
        final status = _getStatus(data);

        return ProCardGate(
          feature: ProFeature.spendingPersonality,
          borderRadius: spacing.radiusMedium,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: globalPadding),
            child: Card(
              elevation: 0,
              margin: const EdgeInsets.only(),
              color: color.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
                side: BorderSide(
                  color: archetype.color.withValues(alpha: 0.2),
                ),
              ),
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  context.push(AppRoutes.spendingPersonality);
                },
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
                child: Padding(
                  padding: EdgeInsets.all(spacing.cardInner),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section header
                      Text(
                        'Spending Personality',
                        style: textTheme.labelMedium?.copyWith(
                          color: color.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: spacing.elementGap * 1.5),
                      // Row 1: Icon + Name + Status dot
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: archetype.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                spacing.radiusSmall,
                              ),
                            ),
                            child: Icon(
                              archetype.icon,
                              size: 22,
                              color: archetype.color,
                            ),
                          ),
                          SizedBox(width: spacing.elementGap * 1.5),
                          Expanded(
                            child: Text(
                              archetype.name,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Status dot
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: status.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: spacing.elementGapMin),
                          Text(
                            status.label,
                            style: textTheme.labelSmall?.copyWith(
                              color: status.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: spacing.elementGap),
                          Icon(
                            LucideIcons.chevronRight,
                            size: 16,
                            color:
                                color.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                        ],
                      ),

                      SizedBox(height: spacing.elementGap * 1.5),

                      // Row 2: Dynamic insight
                      Text(
                        status.insight,
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: spacing.elementGap),

                      // Row 3: Control level bar
                      Row(
                        children: [
                          Text(
                            'Control',
                            style: textTheme.labelSmall?.copyWith(
                              color:
                                  color.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                          ),
                          SizedBox(width: spacing.elementGap),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                spacing.radiusSmall,
                              ),
                              child: LinearProgressIndicator(
                                value: status.controlLevel,
                                minHeight: 4,
                                backgroundColor: color.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation(
                                  archetype.color,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: spacing.elementGap),
                          Text(
                            '${(status.controlLevel * 100).toInt()}%',
                            style: textTheme.labelSmall?.copyWith(
                              color: archetype.color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: spacing.elementGap),

                      // Row 4: Tap hint
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
                            color:
                                color.onSurfaceVariant.withValues(alpha: 0.5),
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
              ),
        );
      },
      loading: () => const PersonalityCardSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  _SpendingStatus _getStatus(SpendingPersonality data) {
    final trend = data.spendingTrend.toLowerCase();
    final isImpulse = data.behaviorType.toLowerCase().contains('impulse');
    final savingsOk = data.savingsRate > 15;

    // Control level: composite of savings rate + non-impulse + steady trend
    double control = 0.3; // base
    if (savingsOk) control += 0.25;
    if (!isImpulse) control += 0.25;
    if (trend.contains('steady') || trend.contains('decreasing')) {
      control += 0.2;
    }
    control = control.clamp(0.0, 1.0);

    if (trend.contains('increasing') && isImpulse) {
      return _SpendingStatus(
        label: 'Risk',
        color: FinanceColors.statusDanger,
        insight: 'Overspending trend detected this period',
        controlLevel: control,
      );
    }

    if (trend.contains('increasing') || isImpulse) {
      return _SpendingStatus(
        label: 'Drift',
        color: FinanceColors.statusWarning,
        insight: 'Spending slightly higher than usual',
        controlLevel: control,
      );
    }

    if (savingsOk && trend.contains('decreasing')) {
      return _SpendingStatus(
        label: 'Great',
        color: FinanceColors.statusGood,
        insight: 'Spending is trending down — nice work',
        controlLevel: control,
      );
    }

    return _SpendingStatus(
      label: 'Stable',
      color: FinanceColors.statusGood,
      insight: 'Balanced and in control',
      controlLevel: control,
    );
  }
}

class _SpendingStatus {
  final String label;
  final Color color;
  final String insight;
  final double controlLevel;

  const _SpendingStatus({
    required this.label,
    required this.color,
    required this.insight,
    required this.controlLevel,
  });
}

import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'dart:math' as math;

class GoalCard extends ConsumerWidget {
  const GoalCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final goals = ref.watch(dashboardGoalsProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (goals.isEmpty) return const SizedBox.shrink();

    final activeGoals = goals.where((g) => g.isActive).toList();
    if (activeGoals.isEmpty) return const SizedBox.shrink();

    final totalTarget = activeGoals.fold(0.0, (sum, g) => sum + g.targetAmount);
    final totalSaved = activeGoals.fold(0.0, (sum, g) => sum + g.currentAmount);
    final progress = totalTarget > 0 ? totalSaved / totalTarget : 0.0;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: color.surfaceContainerLow,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            context.push(AppRoutes.goalScreen);
          },
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          child: Padding(
            padding: EdgeInsets.all(spacing.cardInner),
            child: Row(
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                  tween: Tween(begin: 0.0, end: progress),
                  builder: (context, value, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: spacing.sectionGap * 2,
                          height: spacing.sectionGap * 2,
                          child: CustomPaint(
                            painter: _CompactRingPainter(
                              progress: value,
                              color: color.primary,
                              spacing: spacing,
                            ),
                          ),
                        ),
                        Text(
                          '${(value * 100).toInt()}%',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: color.primary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(width: spacing.sectionGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.title_goals,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: color.surfaceContainerHighest,
                          borderRadius:
                              BorderRadius.circular(spacing.radiusSmall),
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(spacing.radiusSmall),
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 1500),
                            curve: Curves.easeOutCubic,
                            tween: Tween(begin: 0.0, end: progress),
                            builder: (context, value, child) {
                              return FractionallySizedBox(
                                widthFactor: value,
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [color.primary, color.tertiary],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: spacing.elementGap),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricItem(
                              '${activeGoals.length} ${AppLocalizations.of(context)!.section_active.toLowerCase()}',
                              formatCurrency(totalSaved, decimals: 0),
                              LucideIcons.target,
                              color.primary,
                              color,
                              textTheme,
                              spacing,
                            ),
                          ),
                          SizedBox(width: spacing.radiusMedium),
                          Expanded(
                            child: _buildMetricItem(
                              AppLocalizations.of(context)!.budget_remaining,
                              formatCurrency((totalTarget - totalSaved),
                                  decimals: 0,),
                              LucideIcons.trendingUp,
                              color.tertiary,
                              color,
                              textTheme,
                              spacing,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  color: color.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem(
    String label,
    String value,
    IconData icon,
    Color itemColor,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Row(
      children: [
        Icon(icon, color: itemColor, size: 16),
        SizedBox(width: spacing.elementGapMin),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: color.onSurfaceVariant,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final AppSpacing spacing;

  _CompactRingPainter({
    required this.progress,
    required this.color,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - spacing.cardVerticalMin;
    const strokeWidth = 6.0;

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      colors: [color, color.withValues(alpha: 0.6), color],
      stops: const [0.0, 0.5, 1.0],
      transform: const GradientRotation(-math.pi / 2),
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CompactRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

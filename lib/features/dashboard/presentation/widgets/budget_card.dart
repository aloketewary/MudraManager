import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'dart:math' as math;

import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';

class BudgetCard extends ConsumerWidget {
  final double globalPadding;

  const BudgetCard({super.key, required this.globalPadding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(budgetsWithProgressProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);

    return budgetAsync.when(
      data: (budgets) {
        if (budgets.isEmpty) return const SizedBox.shrink();

        final totalBudget =
            budgets.fold(0.0, (sum, b) => sum + b.budget.amount);
        final totalSpent = budgets.fold(0.0, (sum, b) => sum + b.spent);
        final remaining = totalBudget - totalSpent;
        final percent = totalBudget > 0
            ? (totalSpent / totalBudget * 100).clamp(0.0, 100.0)
            : 0.0;

        final daysInMonth =
            DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
        final daysLeft = daysInMonth - DateTime.now().day + 1;
        final dailySafe = daysLeft > 0 ? remaining / daysLeft : 0;

        Color progressColor = color.tertiary;
        if (percent >= 100) {
          progressColor = color.error;
        } else if (percent >= 90) {
          progressColor = color.error;
        } else if (percent >= 80) {
          progressColor = color.tertiary;
        }

        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: SizedBox(
            width: double.infinity,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: globalPadding),
              child: Card(
                elevation: 0,
                color: color.surfaceContainerLow,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.push(AppRoutes.budgetDashboard);
                  },
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1500),
                          curve: Curves.easeOutCubic,
                          tween: Tween(begin: 0.0, end: percent / 100),
                          builder: (context, value, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: CustomPaint(
                                    painter: _CompactRingPainter(
                                      progress: value,
                                      color: progressColor,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(value * 100).toInt()}%',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: progressColor,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!
                                    .dashboard_mini_budget_text,
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
                                  borderRadius: BorderRadius.circular(
                                      spacing.radiusSmall),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      spacing.radiusSmall),
                                  child: TweenAnimationBuilder<double>(
                                    duration:
                                        const Duration(milliseconds: 1500),
                                    curve: Curves.easeOutCubic,
                                    tween:
                                        Tween(begin: 0.0, end: percent / 100),
                                    builder: (context, value, child) {
                                      return FractionallySizedBox(
                                        widthFactor: value,
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                progressColor,
                                                progressColor.withValues(
                                                    alpha: 0.7)
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetricItem(
                                      AppLocalizations.of(context)!
                                          .budget_remaining,
                                      formatCurrency(remaining, decimals: 0),
                                      LucideIcons.wallet,
                                      progressColor,
                                      color,
                                      textTheme,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildMetricItem(
                                      AppLocalizations.of(context)!
                                          .budget_safeToSpend,
                                      formatCurrency(dailySafe.toDouble(),
                                          decimals: 0),
                                      LucideIcons.calendar,
                                      color.primary,
                                      color,
                                      textTheme,
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
            ),
          ),
        );
      },
      loading: () => const BudgetCardSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMetricItem(
    String label,
    String value,
    IconData icon,
    Color itemColor,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        Icon(icon, color: itemColor, size: 16),
        const SizedBox(width: 6),
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

  _CompactRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
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

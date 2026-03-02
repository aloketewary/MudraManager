import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/features/analytics/data/analytics_provider.dart';

class FinancialHealthCard extends ConsumerWidget {
  final double globalPadding;

  const FinancialHealthCard({super.key, required this.globalPadding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(financialHealthProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return healthAsync.when(
      data: (health) {
        if (health.score == 0) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: globalPadding),
            child: Card(
              elevation: 0,
              color: color.surfaceContainerLow,
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  context.push('/statistics');
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.heart, color: color.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Financial Health',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            LucideIcons.chevronRight,
                            color: color.onSurfaceVariant,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                TweenAnimationBuilder<int>(
                                  duration: const Duration(milliseconds: 1500),
                                  curve: Curves.easeOutCubic,
                                  tween: IntTween(begin: 0, end: health.score),
                                  builder: (context, value, child) {
                                    return Text(
                                      '$value',
                                      style: textTheme.displayMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: _getScoreColor(
                                          health.score,
                                          color,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                Text(
                                  health.rating,
                                  style: textTheme.titleMedium?.copyWith(
                                    color: _getScoreColor(health.score, color),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildMetric(
                                  'Savings Rate',
                                  '${health.savingsRate.toStringAsFixed(1)}%',
                                  color,
                                  textTheme,
                                ),
                                const SizedBox(height: 8),
                                _buildMetric(
                                  'Expense Ratio',
                                  '${health.expenseRatio.toStringAsFixed(1)}%',
                                  color,
                                  textTheme,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (health.insights.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        ...health.insights
                            .take(2)
                            .map(
                              (insight) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      LucideIcons.lightbulb,
                                      size: 16,
                                      color: color.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        insight,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: color.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMetric(
    String label,
    String value,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
        ),
        Text(
          value,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Color _getScoreColor(int score, ColorScheme color) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }
}

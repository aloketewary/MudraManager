import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/features/goal/data/goal_provider.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

class GoalCard extends ConsumerWidget {
  final double globalPadding;

  const GoalCard({super.key, required this.globalPadding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return goalsAsync.when(
      data: (goals) {
        if (goals.isEmpty) return const SizedBox.shrink();

        final goal = goals.first;
        final percent = (goal.currentAmount / goal.targetAmount * 100).clamp(
          0.0,
          100.0,
        );
        final remaining = goal.targetAmount - goal.currentAmount;
        final isCompleted = goal.currentAmount >= goal.targetAmount;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: globalPadding),
          child: Card(
            elevation: 0,
            color: color.surfaceContainerLow,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                context.push('/goal-screen');
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.emoji_flags, color: color.primary),
                        const SizedBox(width: 8),
                        Text(
                          goal.name,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.chevron_right,
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
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 1500),
                                curve: Curves.easeOutCubic,
                                tween: Tween(begin: 0.0, end: percent),
                                builder: (context, value, child) {
                                  return Text(
                                    '${value.toInt()}%',
                                    style: textTheme.displayMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isCompleted
                                          ? Colors.green
                                          : Colors.blue,
                                    ),
                                  );
                                },
                              ),
                              Text(
                                isCompleted ? 'Completed' : 'Progress',
                                style: textTheme.titleMedium?.copyWith(
                                  color: isCompleted
                                      ? Colors.green
                                      : Colors.blue,
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
                                'Saved',
                                goal.currentAmount,
                                color,
                                textTheme,
                              ),
                              const SizedBox(height: 8),
                              _buildMetric(
                                'Target',
                                goal.targetAmount,
                                color,
                                textTheme,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          isCompleted
                              ? Icons.celebration
                              : Icons.lightbulb_outline,
                          size: 16,
                          color: color.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isCompleted
                                ? 'Congratulations! You achieved your goal'
                                : 'You need ${remaining.toStringAsFixed(0)} more to reach your goal',
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
    double value,
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
        CurrencyText(
          amount: value,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

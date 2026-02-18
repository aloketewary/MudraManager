import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/utils/app_logger.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/features/goal/data/goal_provider.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

class GoalCircularCard extends ConsumerWidget {
  final Goal goal;

  const GoalCircularCard({super.key, required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final progress = (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);
    final remaining = goal.targetAmount - goal.currentAmount;
    final isCompleted = progress >= 1.0;

    final cardColor = Color(goal.colorValue ?? 0xFF6366F1);

    return Dismissible(
      key: Key('goal_${goal.id}'),
      direction: DismissDirection.up,
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        return await DialogUtils.showDeleteConfirmation(
          context,
          title: 'Delete Goal?',
          message:
              "Are you sure you want to delete '${goal.name}'? This action cannot be undone.",
        );
      },
      onDismissed: (direction) async {
        AppLogger.info(
          'goal_deleted_circular, goal_id: ${goal.id}, goal_name: ${goal.name}',
          tag: 'goal',
        );
        await ref.read(goalServiceProvider).deleteGoal(goal.id);
      },
      background: Container(
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: color.error,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: color.onError, size: 32),
            const SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: color.onError,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: Card(
        elevation: 0,
        color: color.surfaceContainerHighest,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 180,
            height: 260,
            margin: const EdgeInsets.only(right: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Circular Progress
                  Center(
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background Circle
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator(
                              value: 1.0,
                              strokeWidth: 8,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation(
                                cardColor.withValues(alpha: 0.15),
                              ),
                            ),
                          ),
                          // Progress Circle
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeOutCubic,
                              tween: Tween(begin: 0.0, end: progress),
                              builder: (context, value, child) {
                                return CircularProgressIndicator(
                                  value: value,
                                  strokeWidth: 8,
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation(cardColor),
                                  strokeCap: StrokeCap.round,
                                );
                              },
                            ),
                          ),
                          // Percentage Text
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: cardColor,
                                  letterSpacing: -1,
                                ),
                              ),
                              if (isCompleted)
                                Icon(
                                  Icons.check_circle,
                                  color: cardColor,
                                  size: 16,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Goal Name
                  AdaptiveText(
                    goal.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color.onSurface,
                    ),
                    maxLines: 1,
                  ),

                  const SizedBox(height: 4),

                  // Current / Target
                  Row(
                    children: [
                      Flexible(
                        child: CurrencyText(
                          amount: goal.currentAmount,
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      Text(
                        ' / ',
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                      Flexible(
                        child: CurrencyText(
                          amount: goal.targetAmount,
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Remaining Amount
                  if (!isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cardColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.trending_up, size: 12, color: cardColor),
                          const SizedBox(width: 4),
                          Flexible(
                            child: CurrencyText(
                              amount: remaining,
                              style: textTheme.labelSmall?.copyWith(
                                color: cardColor,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                            ),
                          ),
                          Text(
                            ' left',
                            style: textTheme.labelSmall?.copyWith(
                              color: cardColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cardColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.celebration, size: 12, color: cardColor),
                          const SizedBox(width: 4),
                          AdaptiveText(
                            'Completed!',
                            style: textTheme.labelSmall?.copyWith(
                              color: cardColor,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

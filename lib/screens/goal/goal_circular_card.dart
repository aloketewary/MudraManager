import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/db/models/goal.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/util/icon_helper.dart';
import 'package:mudra_manager/util/localization_extension.dart';
import 'package:mudra_manager/util/dialog_utils.dart';
import 'package:mudra_manager/providers/goal_provider.dart';
import 'package:mudra_manager/util/app_logger.dart';

class GoalCircularCard extends ConsumerWidget {
  final Goal goal;

  const GoalCircularCard({super.key, required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

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
          title: "Delete Goal?",
          message: "Are you sure you want to delete '${goal.name}'? This action cannot be undone.",
        );
      },
      onDismissed: (direction) async {
        AppLogger.logAction('goal_deleted_circular', parameters: {
          'goal_id': goal.id,
          'goal_name': goal.name,
          'progress': goal.progressPercent,
        });
        await ref.read(goalServiceProvider).deleteGoal(goal.id);
      },
      background: Container(
        margin: EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: color.error,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: color.onError, size: 32),
            SizedBox(height: 4),
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
      child: Container(
      width: 180,
      margin: EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardColor.withValues(alpha: 0.15),
            cardColor.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: cardColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Icon Watermark
            Positioned(
              right: -15,
              top: -15,
              child: Transform.rotate(
                angle: 0.2,
                child: Icon(
                  IconHelper.getIconData(goal.iconName),
                  size: 80,
                  color: cardColor.withValues(alpha: 0.08),
                ),
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(16),
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
                              duration: Duration(milliseconds: 1000),
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

                  SizedBox(height: 16),

                  // Goal Name
                  Text(
                    goal.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 4),

                  // Current / Target
                  Text(
                    '${ctxt.formatCurrencyWithSign(2, goal.currentAmount)} / ${ctxt.formatCurrencyWithSign(2, goal.targetAmount)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  Spacer(),

                  // Remaining Amount
                  if (!isCompleted)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cardColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 12,
                            color: cardColor,
                          ),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${ctxt.formatCurrencyWithSign(2, remaining)} left',
                              style: textTheme.labelSmall?.copyWith(
                                color: cardColor,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cardColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.celebration,
                            size: 12,
                            color: cardColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Completed!',
                            style: textTheme.labelSmall?.copyWith(
                              color: cardColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
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
}

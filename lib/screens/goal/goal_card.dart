import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/db/models/goal.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/screens/reusable/animated_balance.dart';
import 'package:mudra_manager/util/icon_helper.dart';
import 'package:mudra_manager/util/localization_extension.dart';
import 'package:mudra_manager/util/dialog_utils.dart';
import 'package:mudra_manager/providers/goal_provider.dart';
import 'package:mudra_manager/util/app_logger.dart';

class GoalCard extends ConsumerWidget {
  final Goal goal;
  final VoidCallback? onTap;

  const GoalCard({super.key, required this.goal, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    final goalColor =
        goal.colorValue != null ? Color(goal.colorValue!) : color.primary;
    final progress = goal.progressPercent;

    return Dismissible(
      key: Key('goal_full_${goal.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        return await DialogUtils.showDeleteConfirmation(
          context,
          title: "Delete Goal?",
          message:
              "Are you sure you want to delete '${goal.name}'? This action cannot be undone.",
        );
      },
      onDismissed: (direction) async {
        AppLogger.info(
          'goal_deleted, goal_id: ${goal.id}, goal_name: ${goal.name}',
          tag: 'goal',
        );
        await ref.read(goalServiceProvider).deleteGoal(goal.id);
      },
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 24),
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
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 0,
        color: color.surfaceContainerHighest,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: goalColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        IconHelper.getIconData(goal.iconName),
                        color: goalColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (goal.targetDate != null)
                            Text(
                              "By ${DateFormat.yMMMd(ctxt.localeName).format(goal.targetDate!)}",
                              style: textTheme.labelSmall?.copyWith(
                                color: color.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: goalColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${(progress * 100).toStringAsFixed(0)}%",
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: goalColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: goalColor.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(goalColor),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 8,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Saved",
                          style: textTheme.labelSmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                        AnimatedBalance(
                          value: goal.currentAmount,
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: goalColor,
                          ),
                          fixedStringLength: 0,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Target",
                          style: textTheme.labelSmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          ctxt.formatCurrencyWithSign(0, goal.targetAmount),
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: goalColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

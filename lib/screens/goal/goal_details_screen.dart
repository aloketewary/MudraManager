import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/db/models/goal.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/providers/goal_provider.dart';
import 'package:mudra_manager/util/dialog_utils.dart';
import 'package:mudra_manager/components/currency_text.dart';
import 'package:mudra_manager/util/icon_helper.dart';
import 'package:mudra_manager/util/localization_extension.dart';

class GoalDetailsScreen extends ConsumerWidget {
  final Goal goal;

  const GoalDetailsScreen({super.key, required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctxt = AppLocalizations.of(context)!;
    final progress = goal.progressPercent;
    final remaining = goal.targetAmount - goal.currentAmount;
    var color = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    final formatter = DateFormat('dd MMM yy', ctxt.localeName);

    final goalColor = goal.colorValue != null ? Color(goal.colorValue!) : color.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                context.push('/add-goal', extra: {'goal': goal});
              } else if (value == 'delete') {
                final confirm = await DialogUtils.showDeleteConfirmation(
                  context,
                  title: 'Delete Goal?',
                  message: "Are you sure you want to delete '${goal.name}'? This action cannot be undone.",
                );
                if (confirm == true) {
                  await ref.read(goalServiceProvider).deleteGoal(goal.id);
                  ref.invalidate(goalsProvider);
                  if (context.mounted) context.pop();
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20, color: color.secondary),
                    const SizedBox(width: 12),
                    const Text('Edit Goal'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: color.error),
                    const SizedBox(width: 12),
                    Text('Delete Goal', style: TextStyle(color: color.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [goalColor.withValues(alpha: 0.1), color.surface],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: goalColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      IconHelper.getIconData(goal.iconName),
                      color: goalColor,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (goal.targetDate != null)
                    Text(
                      "Target: ${formatter.format(goal.targetDate!)}",
                      style: textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'TARGET'.toUpperCase(),
                              style: textTheme.labelSmall?.copyWith(
                                color: color.onSurfaceVariant,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            CurrencyText(
                              amount: goal.targetAmount,
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color.onSurface,
                              ),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: color.outlineVariant,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'SAVED'.toUpperCase(),
                              style: textTheme.labelSmall?.copyWith(
                                color: color.onSurfaceVariant,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            CurrencyText(
                              amount: goal.currentAmount,
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: goalColor,
                              ),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: goalColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${(progress * 100).toStringAsFixed(0)}%",
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: goalColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progress',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    color: color.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: goalColor.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(goalColor),
                            borderRadius: BorderRadius.circular(8),
                            minHeight: 16,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Remaining',
                                    style: textTheme.labelMedium?.copyWith(
                                      color: color.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  CurrencyText(
                                    amount: remaining > 0 ? remaining : 0,
                                    style: textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: color.onSurface,
                                    ),
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                              if (goal.targetDate != null && remaining > 0)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Days Left',
                                      style: textTheme.labelMedium?.copyWith(
                                        color: color.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      goal.targetDate!.difference(DateTime.now()).inDays.toString(),
                                      style: textTheme.titleLarge?.copyWith(
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
                  if (goal.description != null && goal.description!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Description',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      color: color.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          goal.description!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: color.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

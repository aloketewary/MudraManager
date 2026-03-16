import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/features/goal/data/goal_provider.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/shared/widgets/widgets.dart';

class GoalScreen extends ConsumerWidget {
  const GoalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final goalsAsync = ref.watch(goalsProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: color.surface,
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Goals'),
                actions: [
                  IconButton(
                    icon: const Icon(LucideIcons.plus),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      context.push('/add-goal');
                    },
                  ),
                ],
              ),
              body: const NoDataFound(
                message: 'No goals yet',
                iconData: LucideIcons.goal,
              ),
            );
          }

          final activeGoals = goals.where((g) => g.isActive).toList();
          final totalTarget =
              activeGoals.fold(0.0, (sum, g) => sum + g.targetAmount);
          final totalSaved =
              activeGoals.fold(0.0, (sum, g) => sum + g.currentAmount);
          final overallProgress =
              totalTarget > 0 ? totalSaved / totalTarget : 0.0;
          final totalRemaining = totalTarget - totalSaved;

          return CustomScrollView(
            slivers: [
              // Professional SliverAppBar
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                elevation: 0,
                title: LayoutBuilder(
                  builder: (context, constraints) {
                    final expandRatio = constraints.maxHeight > 80 ? 1.0 : 0.0;
                    return Opacity(
                      opacity: 1 - expandRatio,
                      child: Text(
                        'Goals',
                        style: textTheme.titleLarge?.copyWith(
                          color: color.onSurface,
                        ),
                      ),
                    );
                  },
                ),
                actions: [
                  IconButton(
                    icon: const Icon(LucideIcons.plus),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      context.push('/add-goal');
                    },
                  ),
                  SizedBox(width: spacing.cardHorizontal),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.primaryContainer,
                          color.secondaryContainer,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Opacity(
                            opacity: constraints.maxHeight > 100 ? 1.0 : 0.0,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                spacing.cardHorizontal,
                                spacing.sectionGap * 3,
                                spacing.cardHorizontal,
                                spacing.sectionGap,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding:
                                            EdgeInsets.all(spacing.elementGap),
                                        decoration: BoxDecoration(
                                          color: color.primary
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            spacing.radiusMedium,
                                          ),
                                        ),
                                        child: Icon(
                                          LucideIcons.target,
                                          color: color.primary,
                                          size: 24,
                                        ),
                                      ),
                                      SizedBox(width: spacing.elementGap * 1.5),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Your Goals',
                                              style: textTheme.headlineSmall
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: color.onPrimaryContainer,
                                              ),
                                            ),
                                            Text(
                                              '${activeGoals.length} active ${activeGoals.length == 1 ? 'goal' : 'goals'}',
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                color: color.onPrimaryContainer
                                                    .withValues(alpha: 0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: spacing.sectionGap),
                                  Container(
                                    padding: EdgeInsets.all(spacing.cardInner),
                                    decoration: BoxDecoration(
                                      color:
                                          color.surface.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(
                                        spacing.radiusMedium,
                                      ),
                                      border: Border.all(
                                        color: color.outline
                                            .withValues(alpha: 0.1),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Total Saved',
                                                  style: textTheme.bodySmall
                                                      ?.copyWith(
                                                    color:
                                                        color.onSurfaceVariant,
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: spacing.elementGap,
                                                ),
                                                CurrencyText(
                                                  amount: totalSaved,
                                                  fixedLength: 0,
                                                  compact: true,
                                                  style: textTheme
                                                      .headlineMedium
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: color.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              width: 1,
                                              height: 40,
                                              color: color.outlineVariant
                                                  .withValues(alpha: 0.5),
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'Target',
                                                  style: textTheme.bodySmall
                                                      ?.copyWith(
                                                    color:
                                                        color.onSurfaceVariant,
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: spacing.elementGap,
                                                ),
                                                CurrencyText(
                                                  amount: totalTarget,
                                                  fixedLength: 0,
                                                  compact: true,
                                                  style: textTheme
                                                      .headlineMedium
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: color.onSurface,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          height: spacing.elementGap,
                                        ),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            spacing.radiusSmall,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: overallProgress,
                                            minHeight: 8,
                                            backgroundColor: color.outline
                                                .withValues(alpha: 0.1),
                                            valueColor: AlwaysStoppedAnimation(
                                              color.primary,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: spacing.elementGap),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${(overallProgress * 100).toStringAsFixed(1)}% Complete',
                                              style:
                                                  textTheme.bodySmall?.copyWith(
                                                color: color.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            CurrencyText(
                                              amount: totalRemaining,
                                              fixedLength: 0,
                                              compact: true,
                                              suffixText: 'remaining',
                                              style:
                                                  textTheme.bodySmall?.copyWith(
                                                color: color.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    spacing.cardHorizontal,
                    spacing.sectionGap,
                    spacing.cardVertical,
                    spacing.elementGap,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.listChecks,
                        size: 20,
                        color: color.primary,
                      ),
                      SizedBox(width: spacing.elementGap),
                      Text(
                        'All Goals',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${activeGoals.length} ${activeGoals.length == 1 ? 'goal' : 'goals'}',
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Goals List
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontal,
                  vertical: spacing.cardVertical,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: EdgeInsets.only(bottom: spacing.elementGap),
                      child: _buildGoalCard(
                        activeGoals[index],
                        color,
                        textTheme,
                        spacing,
                        context,
                      ),
                    ),
                    childCount: activeGoals.length,
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: spacing.sectionGap,
                ),
              ),
            ],
          );
        },
        loading: () => Padding(
          padding: EdgeInsets.all(spacing.sectionGap),
          child: Column(
            children: [
              SizedBox(height: spacing.sectionGap * 3),
              SkeletonLoader(
                width: double.infinity,
                height: 200,
                borderRadius: BorderRadius.circular(spacing.radiusLarge),
              ),
              SizedBox(height: spacing.sectionGap),
              ...List.generate(
                4,
                (i) => Padding(
                  padding: EdgeInsets.only(bottom: spacing.elementGap),
                  child: SkeletonLoader(
                    width: double.infinity,
                    height: 120,
                    borderRadius: BorderRadius.circular(spacing.radiusLarge),
                  ),
                ),
              ),
            ],
          ),
        ),
        error: (_, __) => const Center(child: Text('Error loading goals')),
      ),
    );
  }

  Widget _buildGoalCard(
    Goal goal,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    BuildContext context,
  ) {
    final goalColor =
        goal.colorValue != null ? Color(goal.colorValue!) : color.primary;
    final progress = goal.progressPercent;
    final daysLeft = goal.targetDate?.difference(DateTime.now()).inDays ?? 0;
    final remaining = goal.remainingAmount;

    return Container(
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusLarge),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push('/goal-details', extra: {'goal': goal});
        },
        borderRadius: BorderRadius.circular(spacing.radiusLarge),
        child: Padding(
          padding: EdgeInsets.all(spacing.cardInner),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(spacing.elementGap),
                    decoration: BoxDecoration(
                      color: goalColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    ),
                    child: Icon(
                      IconHelper.getIconData(goal.iconName),
                      color: goalColor,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: spacing.elementGap * 1.5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (goal.targetDate != null)
                          Text(
                            'Target: ${DateFormat('dd MMM yyyy').format(goal.targetDate!)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CurrencyText(
                        amount: goal.currentAmount,
                        fixedLength: 0,
                        compact: false,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: goalColor,
                        ),
                      ),
                      CurrencyText(
                        amount: goal.targetAmount,
                        fixedLength: 0,
                        compact: false,
                        prefixText: 'of',
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: spacing.elementGap * 1.5),
              ClipRRect(
                borderRadius: BorderRadius.circular(spacing.radiusSmall),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: color.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(goalColor),
                ),
              ),
              SizedBox(height: spacing.elementGap),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.trendingUp,
                        size: 14,
                        color: goalColor,
                      ),
                      SizedBox(width: spacing.elementGap * 0.5),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}% Complete',
                        style: textTheme.bodySmall?.copyWith(
                          color: goalColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (daysLeft > 0)
                    Row(
                      children: [
                        Icon(
                          LucideIcons.calendar,
                          size: 14,
                          color: color.onSurfaceVariant,
                        ),
                        SizedBox(width: spacing.elementGap * 0.5),
                        Text(
                          '$daysLeft days left',
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (remaining > 0) ...[
                SizedBox(height: spacing.elementGap),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.elementGap,
                    vertical: spacing.elementGap * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: goalColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.target,
                        size: 12,
                        color: goalColor,
                      ),
                      SizedBox(width: spacing.elementGap * 0.5),
                      CurrencyText(
                        amount: remaining,
                        fixedLength: 0,
                        compact: false,
                        suffixText: 'remaining',
                        style: textTheme.bodySmall?.copyWith(
                          color: goalColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

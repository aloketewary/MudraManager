import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/utils/refresh_helper.dart';
import 'package:mudra_manager/features/goal/data/goal_provider.dart';
import 'package:mudra_manager/features/goal/domain/goal_health.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/shared/widgets/widgets.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

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
                      context.push(AppRoutes.addGoal);
                    },
                  ),
                ],
              ),
              body: NoDataFound(
                message: BuddyMessages.noGoals,
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

          // Find highlight goal (highest progress that's not complete)
          final incompleteGoals =
              activeGoals.where((g) => g.progressPercent < 1.0).toList();
          final highlightGoal = incompleteGoals.isNotEmpty
              ? (incompleteGoals..sort((a, b) =>
                  b.progressPercent.compareTo(a.progressPercent))).first
              : activeGoals.first;

          // Remaining goals (exclude highlight)
          final remainingGoals =
              activeGoals.where((g) => g.id != highlightGoal.id).toList();

          return RefreshIndicator(
            onRefresh: () => RefreshHelper.withMinDuration(() async {
              ref.invalidate(goalsProvider);
            }),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // App Bar
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  title: Text(
                    'Goals',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(LucideIcons.plus),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        context.push(AppRoutes.addGoal);
                      },
                    ),
                    SizedBox(width: spacing.cardHorizontal),
                  ],
                ),

                // 🥇 Hero Summary — Motivation First
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      spacing.cardHorizontal,
                      spacing.elementGap,
                      spacing.cardHorizontal,
                      spacing.cardVertical,
                    ),
                    child: _buildHeroSummary(
                      totalSaved,
                      totalTarget,
                      overallProgress,
                      activeGoals.length,
                      color,
                      textTheme,
                      spacing,
                    ),
                  ),
                ),

                // 🥈 Highlight Goal — Primary Focus
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.cardHorizontal,
                      vertical: spacing.cardVertical,
                    ),
                    child: _buildHighlightGoal(
                      highlightGoal,
                      color,
                      textTheme,
                      spacing,
                      context,
                    ),
                  ),
                ),

                // 🥉 Goals List Header
                if (remainingGoals.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        spacing.cardHorizontal,
                        spacing.elementGap,
                        spacing.cardHorizontal,
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
                            '${remainingGoals.length} more',
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Goals List
                if (remainingGoals.isNotEmpty)
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.cardHorizontal,
                      vertical: spacing.cardVertical,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding:
                              EdgeInsets.only(bottom: spacing.elementGap),
                          child: _buildGoalCard(
                            remainingGoals[index],
                            color,
                            textTheme,
                            spacing,
                            context,
                          ),
                        ),
                        childCount: remainingGoals.length,
                      ),
                    ),
                  ),

                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom +
                        kBottomNavigationBarHeight +
                        16,
                  ),
                ),
              ],
            ),
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
                    borderRadius:
                        BorderRadius.circular(spacing.radiusLarge),
                  ),
                ),
              ),
            ],
          ),
        ),
        error: (_, __) => Center(child: Text(BuddyMessages.genericError)),
      ),
    );
  }

  // ── Hero Summary ──
  Widget _buildHeroSummary(
    double totalSaved,
    double totalTarget,
    double overallProgress,
    int goalCount,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.primaryContainer,
            color.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(spacing.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(spacing.elementGap),
                decoration: BoxDecoration(
                  color: color.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                ),
                child: Icon(
                  LucideIcons.target,
                  color: color.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: spacing.elementGap),
              Text(
                '$goalCount active ${goalCount == 1 ? 'goal' : 'goals'}',
                style: textTheme.bodyMedium?.copyWith(
                  color: color.onPrimaryContainer.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.sectionGap),
          CurrencyText(
            amount: totalSaved,
            fixedLength: 0,
            compact: true,
            style: textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: color.onPrimaryContainer,
            ),
          ),
          SizedBox(height: spacing.elementGapMin),
          Row(
            children: [
              Text(
                'saved of ',
                style: textTheme.bodyMedium?.copyWith(
                  color: color.onPrimaryContainer.withValues(alpha: 0.7),
                ),
              ),
              CurrencyText(
                amount: totalTarget,
                fixedLength: 0,
                compact: true,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color.onPrimaryContainer,
                ),
              ),
              Text(
                ' goal 🎯',
                style: textTheme.bodyMedium?.copyWith(
                  color: color.onPrimaryContainer.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.elementGap * 1.5),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0.0, end: overallProgress),
            builder: (context, value, _) {
              return Column(
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(spacing.radiusSmall),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 10,
                      backgroundColor:
                          color.onPrimaryContainer.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(color.primary),
                    ),
                  ),
                  SizedBox(height: spacing.elementGap),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(value * 100).toStringAsFixed(0)}% overall',
                        style: textTheme.bodySmall?.copyWith(
                          color: color.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      CurrencyText(
                        amount: totalTarget - totalSaved,
                        fixedLength: 0,
                        compact: true,
                        suffixText: 'to go',
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onPrimaryContainer
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Highlight Goal ──
  Widget _buildHighlightGoal(
    Goal goal,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    BuildContext context,
  ) {
    final goalColor =
        goal.colorValue != null ? Color(goal.colorValue!) : color.primary;
    final health = GoalHealth.compute(goal);
    final statusColor = health.statusColor(color);
    final progress = goal.progressPercent;

    return Container(
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusLarge),
        border: Border.all(
          color: goalColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push(AppRoutes.goalDetails, extra: {'goal': goal});
        },
        borderRadius: BorderRadius.circular(spacing.radiusLarge),
        child: Padding(
          padding: EdgeInsets.all(spacing.cardInner),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status badge
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(spacing.elementGap),
                    decoration: BoxDecoration(
                      color: goalColor.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(spacing.radiusMedium),
                    ),
                    child: Icon(
                      IconHelper.getIconData(goal.iconName),
                      color: goalColor,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: spacing.elementGap * 1.5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(LucideIcons.star, size: 14, color: goalColor),
                            SizedBox(width: spacing.elementGapMin),
                            Text(
                              'Primary Goal',
                              style: textTheme.labelSmall?.copyWith(
                                color: goalColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: spacing.elementGapMin),
                        Text(
                          goal.name,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(health, statusColor, textTheme, spacing),
                ],
              ),
              SizedBox(height: spacing.sectionGap),

              // Amount row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CurrencyText(
                        amount: goal.currentAmount,
                        fixedLength: 0,
                        compact: true,
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: goalColor,
                        ),
                      ),
                      CurrencyText(
                        amount: goal.targetAmount,
                        fixedLength: 0,
                        compact: true,
                        prefixText: 'of',
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: goalColor.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing.elementGap * 1.5),

              // Animated progress bar
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0.0, end: progress),
                builder: (context, value, _) {
                  return ClipRRect(
                    borderRadius:
                        BorderRadius.circular(spacing.radiusSmall),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 10,
                      backgroundColor:
                          color.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(goalColor),
                    ),
                  );
                },
              ),
              SizedBox(height: spacing.elementGap),

              // Bottom info row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (health.daysLeft > 0)
                    Row(
                      children: [
                        Icon(LucideIcons.calendar, size: 14,
                            color: color.onSurfaceVariant),
                        SizedBox(width: spacing.elementGapMin),
                        Text(
                          _formatDaysLeft(health.daysLeft),
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  CurrencyText(
                    amount: goal.remainingAmount,
                    fixedLength: 0,
                    compact: true,
                    suffixText: 'to go',
                    style: textTheme.bodySmall?.copyWith(
                      color: goalColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              // Tone-aware smart insight
              SizedBox(height: spacing.elementGap),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.elementGap,
                  vertical: spacing.elementGapMin + 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
                child: Text(
                  health.insightMessage(goal),
                  style: textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Goal Card ──
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
    final health = GoalHealth.compute(goal);
    final statusColor = health.statusColor(color);

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
          context.push(AppRoutes.goalDetails, extra: {'goal': goal});
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
                      borderRadius:
                          BorderRadius.circular(spacing.radiusMedium),
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
                borderRadius:
                    BorderRadius.circular(spacing.radiusSmall),
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
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: spacing.elementGapMin),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: textTheme.bodySmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (health.daysLeft > 0)
                    Row(
                      children: [
                        Icon(
                          LucideIcons.calendar,
                          size: 14,
                          color: color.onSurfaceVariant,
                        ),
                        SizedBox(width: spacing.elementGapMin),
                        Text(
                          _formatDaysLeft(health.daysLeft),
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
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
    );
  }

  Widget _buildStatusBadge(
    GoalHealth health,
    Color statusColor,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    String label;
    switch (health.status) {
      case GoalStatus.ahead:
        label = 'Ahead';
      case GoalStatus.onTrack:
        label = 'On Track';
      case GoalStatus.behind:
        label = 'Behind';
      case GoalStatus.completed:
        label = 'Done!';
      case GoalStatus.noDeadline:
        label = 'Flexible';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.elementGap,
        vertical: spacing.elementGapMin,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _formatDaysLeft(int days) {
    if (days > 60) return '${(days / 30).round()} months left';
    return '$days days left';
  }
}

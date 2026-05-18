import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
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
    final ctxt = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: color.surface,
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return Scaffold(
              appBar: AppBar(
                title: Text(AppLocalizations.of(context)!.title_goals),
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

          final activeGoals = goals
              .where((g) => g.isActive && g.progressPercent < 1.0)
              .toList();
          final completedGoals =
              goals.where((g) => g.progressPercent >= 1.0).toList();
          final allActive = goals.where((g) => g.isActive).toList();
          final totalTarget =
              allActive.fold(0.0, (sum, g) => sum + g.targetAmount);
          final totalSaved =
              allActive.fold(0.0, (sum, g) => sum + g.currentAmount);
          final overallProgress =
              totalTarget > 0 ? totalSaved / totalTarget : 0.0;

          // Highlight = closest to completion (not done)
          Goal? highlightGoal;
          List<Goal> remainingGoals = activeGoals;
          if (activeGoals.length > 1) {
            final sorted = List<Goal>.from(activeGoals)
              ..sort((a, b) => b.progressPercent.compareTo(a.progressPercent));
            highlightGoal = sorted.first;
            remainingGoals = sorted.sublist(1);
          } else if (activeGoals.length == 1) {
            highlightGoal = activeGoals.first;
            remainingGoals = [];
          }

          return RefreshIndicator(
            onRefresh: () => RefreshHelper.withMinDuration(() async {
              ref.invalidate(goalsProvider);
            }),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  title: Text(
                    ctxt.title_goals,
                    style: textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
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

                // ── Hero Summary ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      spacing.cardHorizontal,
                      spacing.elementGap,
                      spacing.cardHorizontal,
                      spacing.cardVertical,
                    ),
                    child: _buildHeroSummary(
                      allActive,
                      totalSaved,
                      totalTarget,
                      overallProgress,
                      color,
                      textTheme,
                      spacing,
                      ctxt,
                    ),
                  ),
                ),

                // ── Highlight Goal ──
                if (highlightGoal != null)
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

                // ── In Progress ──
                if (remainingGoals.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        spacing.cardHorizontal,
                        spacing.sectionGap,
                        spacing.cardHorizontal,
                        spacing.elementGap,
                      ),
                      child: _sectionHeader(
                        ctxt.goal_goalsInProgress(remainingGoals.length),
                        LucideIcons.flame,
                        color,
                        textTheme,
                      ),
                    ),
                  ),
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
                            remainingGoals[index],
                            color,
                            textTheme,
                            spacing,
                            context,
                            ref,
                          ),
                        ),
                        childCount: remainingGoals.length,
                      ),
                    ),
                  ),
                ],

                // ── Completed ──
                if (completedGoals.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        spacing.cardHorizontal,
                        spacing.sectionGap,
                        spacing.cardHorizontal,
                        spacing.elementGap,
                      ),
                      child: _sectionHeader(
                        ctxt.goal_completedSection,
                        LucideIcons.trophy,
                        color,
                        textTheme,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.cardHorizontal,
                      vertical: spacing.cardVertical,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: EdgeInsets.only(bottom: spacing.elementGap),
                          child: _buildCompletedCard(
                            completedGoals[index],
                            color,
                            textTheme,
                            spacing,
                            context,
                          ),
                        ),
                        childCount: completedGoals.length,
                      ),
                    ),
                  ),
                ],

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
                    height: 80,
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
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

  // ── Section Header ──
  Widget _sectionHeader(
    String title,
    IconData icon,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700, color: color.primary),
        ),
      ],
    );
  }

  // ── Hero Summary (untouched) ──
  Widget _buildHeroSummary(
    List<Goal> activeGoals,
    double totalSaved,
    double totalTarget,
    double overallProgress,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final goalCount = activeGoals.length;

    final sections = activeGoals.map((g) {
      final goalColor =
          g.colorValue != null ? Color(g.colorValue!) : color.primary;
      return PieChartSectionData(
        value: g.currentAmount > 0 ? g.currentAmount : 0.01,
        color: goalColor,
        radius: 18,
        showTitle: false,
      );
    }).toList();

    final totalRemaining = totalTarget - totalSaved;
    if (totalRemaining > 0) {
      sections.add(
        PieChartSectionData(
          value: totalRemaining,
          color: color.onPrimaryContainer.withValues(alpha: 0.08),
          radius: 18,
          showTitle: false,
        ),
      );
    }

    // Emotional headline based on progress
    final emotionLine = overallProgress >= 0.75
        ? ctxt.goal_emotionAlmost
        : overallProgress >= 0.5
            ? ctxt.goal_emotionHalfway
            : overallProgress >= 0.25
                ? ctxt.goal_emotionProgress
                : ctxt.goal_emotionEvery;

    return Container(
      padding: EdgeInsets.all(spacing.cardInner + spacing.elementGap),
      decoration: BoxDecoration(
        color: color.primaryContainer,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            height: 104,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 32,
                    startDegreeOffset: -90,
                    sections: sections,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(overallProgress * 100).toStringAsFixed(0)}%',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: color.onPrimaryContainer,
                        height: 1,
                      ),
                    ),
                    Text(
                      ctxt.goal_suffixSaved,
                      style: textTheme.labelSmall?.copyWith(
                        color: color.onPrimaryContainer.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: spacing.sectionGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  emotionLine,
                  style: textTheme.bodyMedium?.copyWith(
                    color: color.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: spacing.elementGapMin),
                CurrencyText(
                  amount: totalSaved,
                  fixedLength: 0,
                  compact: false,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color.onPrimaryContainer,
                  ),
                ),
                SizedBox(height: spacing.elementGapMin),
                Row(
                  children: [
                    Text(
                      'of ',
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onPrimaryContainer.withValues(alpha: 0.6),
                      ),
                    ),
                    CurrencyText(
                      amount: totalTarget,
                      fixedLength: 0,
                      compact: false,
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      ' ${ctxt.goal_acrossGoals(goalCount)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onPrimaryContainer.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.elementGap),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.elementGap,
                    vertical: spacing.elementGapMin,
                  ),
                  decoration: BoxDecoration(
                    color: color.onPrimaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  ),
                  child: CurrencyText(
                    amount: totalTarget - totalSaved,
                    fixedLength: 0,
                    compact: false,
                    suffixText: ctxt.goal_suffixToGo,
                    style: textTheme.labelMedium?.copyWith(
                      color: color.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Highlight Goal — HERO card ──
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
    final remaining = goal.targetAmount - goal.currentAmount;
    final ctxt = AppLocalizations.of(context)!;

    // Emotional label based on progress
    final emotionLabel = progress >= 0.9
        ? ctxt.goal_emotionAlmost
        : progress >= 0.75
            ? ctxt.goal_emotionAlmost
            : progress >= 0.5
                ? ctxt.goal_emotionHalfwayDone
                : progress >= 0.25
                    ? ctxt.goal_emotionKeepPushing
                    : ctxt.goal_emotionJustStarted;

    return Container(
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: goalColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push(AppRoutes.goalDetails, extra: {'goal': goal});
        },
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        child: Padding(
          padding: EdgeInsets.all(spacing.cardInner + spacing.elementGapMin),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left — info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emotional context line
                    Text(
                      ctxt.goal_closestToCompletion,
                      style: textTheme.labelSmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: spacing.elementGapMin),
                    // Goal name
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(spacing.elementGap * 0.75),
                          decoration: BoxDecoration(
                            color: goalColor.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(spacing.radiusSmall),
                          ),
                          child: Icon(
                            IconHelper.getIconData(goal.iconName),
                            color: goalColor,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: spacing.elementGap),
                        Expanded(
                          child: Text(
                            goal.name,
                            style: textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing.elementGap * 1.2),
                    // Human-readable amounts
                    CurrencyText(
                      amount: goal.currentAmount,
                      fixedLength: 0,
                      compact: false,
                      suffixText: ctxt.goal_suffixSaved,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: goalColor,
                      ),
                    ),
                    SizedBox(height: spacing.elementGapUltraMin),
                    CurrencyText(
                      amount: remaining,
                      fixedLength: 0,
                      compact: false,
                      suffixText: ctxt.goal_suffixLeft,
                      style: textTheme.bodySmall
                          ?.copyWith(color: color.onSurfaceVariant),
                    ),
                    if (health.daysLeft > 0) ...[
                      SizedBox(height: spacing.elementGapUltraMin),
                      Text(
                        _formatDaysLeft(health.daysLeft, ctxt),
                        style: textTheme.bodySmall
                            ?.copyWith(color: color.onSurfaceVariant),
                      ),
                    ],
                    SizedBox(height: spacing.elementGap),
                    // Emotion + insight
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing.elementGap,
                        vertical: spacing.elementGapMin,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(spacing.radiusSmall),
                      ),
                      child: Text(
                        emotionLabel,
                        style: textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: spacing.elementGap),
              // Right — progress ring
              _buildProgressRing(
                progress,
                goalColor,
                color,
                textTheme,
                80,
                45,
                8,
                showLabel: true,
                doneLabel: ctxt.goal_suffixDone,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Goal Card — compact, human-readable ──
  Widget _buildGoalCard(
    Goal goal,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    BuildContext context,
    WidgetRef ref,
  ) {
    final goalColor =
        goal.colorValue != null ? Color(goal.colorValue!) : color.primary;
    final progress = goal.progressPercent;
    final health = GoalHealth.compute(goal);
    final statusColor = health.statusColor(color);
    final remaining = goal.targetAmount - goal.currentAmount;
    final ctxt = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push(AppRoutes.goalDetails, extra: {'goal': goal});
        },
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        child: Padding(
          padding: EdgeInsets.all(spacing.cardInner),
          child: Row(
            children: [
              // Left — icon
              Container(
                padding: EdgeInsets.all(spacing.elementGap * 0.75),
                decoration: BoxDecoration(
                  color: goalColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
                child: Icon(
                  IconHelper.getIconData(goal.iconName),
                  color: goalColor,
                  size: 20,
                ),
              ),
              SizedBox(width: spacing.elementGap),
              // Middle — info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: spacing.elementGapUltraMin),
                    // Human-readable: saved + left
                    Row(
                      children: [
                        CurrencyText(
                          amount: goal.currentAmount,
                          fixedLength: 0,
                          compact: true,
                          suffixText: ctxt.goal_suffixSaved,
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: goalColor,
                          ),
                        ),
                        Text(
                          '  •  ',
                          style: textTheme.labelSmall
                              ?.copyWith(color: color.outlineVariant),
                        ),
                        CurrencyText(
                          amount: remaining,
                          fixedLength: 0,
                          compact: true,
                          suffixText: ctxt.goal_suffixLeft,
                          style: textTheme.labelSmall
                              ?.copyWith(color: color.onSurfaceVariant),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing.elementGapUltraMin),
                    // Insight line
                    Text(
                      _shortInsight(
                        health,
                        goal,
                        ctxt,
                      ),
                      style: textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: spacing.elementGap),
              // Right — mini ring + quick deposit
              Column(
                children: [
                  _buildProgressRing(
                    progress,
                    goalColor,
                    color,
                    textTheme,
                    50,
                    24,
                    5,
                  ),
                  SizedBox(height: spacing.elementGapMin),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _showQuickDeposit(context, ref, goal);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing.elementGap,
                        vertical: spacing.elementGapMin,
                      ),
                      decoration: BoxDecoration(
                        color: goalColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(spacing.radiusSmall),
                      ),
                      child: Icon(LucideIcons.plus, size: 14, color: goalColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Completed Goal Card ──
  Widget _buildCompletedCard(
    Goal goal,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    BuildContext context,
  ) {
    final ctxt = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push(AppRoutes.goalDetails, extra: {'goal': goal});
        },
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        child: Padding(
          padding: EdgeInsets.all(spacing.cardInner),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(spacing.elementGap * 0.75),
                decoration: BoxDecoration(
                  color: FinanceColors.statusGood.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
                child: const Icon(
                  LucideIcons.check,
                  color: FinanceColors.statusGood,
                  size: 20,
                ),
              ),
              SizedBox(width: spacing.elementGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: spacing.elementGapUltraMin),
                    CurrencyText(
                      amount: goal.targetAmount,
                      fixedLength: 0,
                      compact: true,
                      suffixText: ctxt.goal_suffixAchieved,
                      style: textTheme.labelSmall?.copyWith(
                        color: FinanceColors.statusGood,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.trophy,
                size: 20,
                color: Colors.amber.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Progress Ring (shared) ──
  Widget _buildProgressRing(
    double progress,
    Color goalColor,
    ColorScheme color,
    TextTheme textTheme,
    double size,
    double radius,
    double ringWidth, {
    bool showLabel = false,
    String doneLabel = 'done',
  }) {
    final clamped = progress.clamp(0.0, 1.0);
    final filled = clamped > 0 ? clamped : 0.001;
    final remaining = 1.0 - clamped;
    final pctText = '${(clamped * 100).toStringAsFixed(0)}%';

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: radius - ringWidth,
              startDegreeOffset: -90,
              sections: [
                PieChartSectionData(
                  value: filled,
                  color: goalColor,
                  radius: ringWidth,
                  showTitle: false,
                ),
                if (remaining > 0)
                  PieChartSectionData(
                    value: remaining,
                    color: goalColor.withValues(alpha: 0.08),
                    radius: ringWidth,
                    showTitle: false,
                  ),
              ],
            ),
          ),
          showLabel
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pctText,
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: goalColor,
                        height: 1,
                      ),
                    ),
                    Text(
                      doneLabel,
                      style: textTheme.labelSmall?.copyWith(
                        color: goalColor.withValues(alpha: 0.6),
                        fontSize: 9,
                      ),
                    ),
                  ],
                )
              : Text(
                  pctText,
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: goalColor.withValues(alpha: 0.7),
                  ),
                ),
        ],
      ),
    );
  }

  // ── Short insight for list cards ──
  String _shortInsight(
    GoalHealth health,
    Goal goal,
    AppLocalizations ctxt,
  ) {
    if (health.daysLeft > 0) {
      final pct = goal.progressPercent;
      if (pct >= 0.75) return ctxt.goal_emotionAlmost;
      if (pct >= 0.5) return ctxt.goal_emotionProgress;
      if (health.status == GoalStatus.behind) return ctxt.goal_needsAttention;
      if (health.status == GoalStatus.ahead) return ctxt.goal_aheadOfSchedule;
      return _formatDaysLeft(health.daysLeft, ctxt);
    }
    if (health.status == GoalStatus.noDeadline) {
      return ctxt.goal_flexibleTimeline;
    }
    return health.insightMessage(goal);
  }

  String _formatDaysLeft(int days, AppLocalizations ctxt) {
    if (days > 60) return ctxt.goal_monthsLeft((days / 30).round());
    return ctxt.goal_daysLeft(days);
  }

  void _showQuickDeposit(BuildContext context, WidgetRef ref, Goal goal) {
    final controller = TextEditingController();
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.read(spacingProvider);
    final goalColor =
        goal.colorValue != null ? Color(goal.colorValue!) : color.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: spacing.cardHorizontalMax,
          right: spacing.cardHorizontalMax,
          top: spacing.cardHorizontalMax,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + spacing.cardHorizontalMax,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(IconHelper.getIconData(goal.iconName),
                    color: goalColor, size: 20),
                SizedBox(width: spacing.elementGap),
                Expanded(
                  child: Text(
                    goal.name,
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.sectionGap),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: goalColor,
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: goalColor.withValues(alpha: 0.2),
                ),
                border: InputBorder.none,
                filled: true,
                fillColor: goalColor.withValues(alpha: 0.06),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: spacing.sectionGap),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(
                    controller.text.replaceAll(',', ''));
                if (amount == null || amount <= 0) return;
                await ref
                    .read(goalServiceProvider)
                    .addContribution(goal.id, amount);
                ref.invalidate(goalsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: goalColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.goal_addToGoal,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

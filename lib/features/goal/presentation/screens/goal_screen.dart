import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/utils/refresh_helper.dart';
import 'package:mudra_manager/core/utils/safe_date_format.dart';
import 'package:mudra_manager/features/goal/data/goal_provider.dart';
import 'package:mudra_manager/features/goal/domain/goal_health.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/shared/widgets/safe_text.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';

class GoalScreen extends ConsumerWidget {
  const GoalScreen({super.key});

  /// Recent pace: contributions in last 90 days / 3 months.
  /// Fallback to lifetime average if < 90 days of history.
  double _recentPace(Goal goal) {
    final contributions = goal.contributions;
    if (contributions.isEmpty) return 0;

    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 90));
    final recent = contributions.where((c) => c.date.isAfter(cutoff)).toList();

    if (recent.isNotEmpty) {
      final total = recent.fold(0.0, (sum, c) => sum + c.amount);
      return total / 3; // 3 months
    }

    // Fallback: lifetime average
    final total = contributions.fold(0.0, (sum, c) => sum + c.amount);
    final first =
        contributions.reduce((a, b) => a.date.isBefore(b.date) ? a : b).date;
    final months = now.difference(first).inDays / 30;
    if (months < 1) return total;
    return total / months;
  }

  /// Needed per month to reach goal by target date.
  double _neededPerMonth(Goal goal) {
    if (goal.targetDate == null) return 0;
    final daysLeft = goal.targetDate!.difference(DateTime.now()).inDays;
    if (daysLeft <= 0) return goal.remainingAmount;
    final monthsLeft = daysLeft / 30;
    return goal.remainingAmount / monthsLeft;
  }

  /// Gap = recentPace - neededPerMonth. Positive = ahead, negative = behind.
  double _paceGap(Goal goal) {
    final needed = _neededPerMonth(goal);
    if (needed <= 0) return 0;
    return _recentPace(goal) - needed;
  }

  /// Whether a goal needs attention (raw failure conditions).
  bool _needsAttention(Goal goal) {
    if (goal.progressPercent >= 1.0) return false;
    final gap = _paceGap(goal);
    if (gap < 0) return true;
    final daysLeft = goal.targetDate?.difference(DateTime.now()).inDays ?? 9999;
    if (daysLeft < 90 && daysLeft > 0) return true;
    final health = GoalHealth.compute(goal);
    if (health.predictedDate != null &&
        goal.targetDate != null &&
        health.predictedDate!.isAfter(goal.targetDate!)) {
      return true;
    }
    return false;
  }

  /// Suggested one-tap deposit: last contribution, or neededPerMonth rounded.
  double _suggestedDeposit(Goal goal) {
    if (goal.contributions.isNotEmpty) {
      final sorted = goal.contributions.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return sorted.first.amount;
    }
    final needed = _neededPerMonth(goal);
    if (needed > 0) return (needed / 500).ceil() * 500;
    return 1000;
  }

  /// Priority sort score (lower = higher priority).
  int _sortPriority(Goal goal) {
    if (goal.progressPercent >= 1.0) return 100;
    final gap = _paceGap(goal);
    final daysLeft = goal.targetDate?.difference(DateTime.now()).inDays ?? 9999;

    // Behind schedule
    if (gap < 0) return 0;
    // Near deadline (< 90 days)
    if (daysLeft < 90 && daysLeft > 0) return 1;
    // On track with deadline
    if (goal.targetDate != null) return 2;
    // No deadline
    return 3;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final goalsAsync = ref.watch(goalsProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return ScreenShell(
      config: ScreenShellConfig(
        title: ctxt.title_goals,
        appBarMode: AppBarMode.standard,
        enableRefresh: true,
      ),
      actions: ScreenActions.build(
        appBar: [
          ScreenAction(
            id: 'add_goal',
            label: 'Add',
            icon: LucideIcons.plus,
            onTap: () {
              HapticFeedback.mediumImpact();
              context.push(AppRoutes.addGoal);
            },
          ),
        ],
      ),
      onRefresh: () => RefreshHelper.withMinDuration(
        () async {
          ref.invalidate(goalsProvider);
        },
      ),
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return NoDataFound(
              message: BuddyMessages.noGoals,
              iconData: LucideIcons.goal,
            );
          }

          final activeGoals = goals
              .where((g) => g.isActive && g.progressPercent < 1.0)
              .toList();
          final completedGoals =
              goals.where((g) => g.progressPercent >= 1.0).toList();
          final totalSaved =
              activeGoals.fold(0.0, (sum, g) => sum + g.currentAmount);
          final attentionCount = activeGoals.where(_needsAttention).length;

          // Priority sort
          activeGoals.sort(
            (a, b) => _sortPriority(a).compareTo(_sortPriority(b)),
          );

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Portfolio Status Strip ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    spacing.cardHorizontal,
                    spacing.elementGap,
                    spacing.cardHorizontal,
                    spacing.sectionGap,
                  ),
                  child: _buildStatusStrip(
                    activeGoals.length,
                    totalSaved,
                    attentionCount,
                    color,
                    textTheme,
                    spacing,
                    ctxt,
                  ),
                ),
              ),

              // ── Active Goals ──
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontal,
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
                        ref,
                        ctxt,
                      ),
                    ),
                    childCount: activeGoals.length,
                  ),
                ),
              ),

              // ── Completed (collapsed section) ──
              if (completedGoals.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      spacing.cardHorizontal,
                      spacing.sectionGap,
                      spacing.cardHorizontal,
                      spacing.elementGap,
                    ),
                    child: Text(
                      '${ctxt.goal_completedSection} (${completedGoals.length})',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.cardHorizontal,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: EdgeInsets.only(bottom: spacing.elementGapMin),
                        child: _buildCompletedCard(
                          completedGoals[index],
                          color,
                          textTheme,
                          spacing,
                          context,
                          ctxt,
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
          );
        },
        loading: () => Padding(
          padding: EdgeInsets.all(spacing.sectionGap),
          child: Column(
            children: [
              SizedBox(height: spacing.sectionGap),
              ...List.generate(
                5,
                (i) => Padding(
                  padding: EdgeInsets.only(bottom: spacing.elementGap),
                  child: SkeletonLoader(
                    width: double.infinity,
                    height: 140,
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

  // ── Portfolio Status Strip ──
  Widget _buildStatusStrip(
    int goalCount,
    double totalSaved,
    int attentionCount,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardInner,
        vertical: spacing.elementGap,
      ),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          _stripItem(
            ctxt.goal_goalsInProgress(goalCount),
            null,
            textTheme,
            color,
          ),
          _stripDot(color),
          Expanded(
            child: CurrencyText(
              amount: totalSaved,
              fixedLength: 0,
              compact: true,
              suffixText: ctxt.goal_suffixSaved,
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (attentionCount > 0) ...[
            _stripDot(color),
            Text(
              ctxt.goal_needAttention(attentionCount),
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: FinanceColors.statusWarning,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stripItem(
    String text,
    Color? textColor,
    TextTheme textTheme,
    ColorScheme color,
  ) {
    return Text(
      text,
      style: textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: textColor ?? color.onSurface,
      ),
    );
  }

  Widget _stripDot(ColorScheme color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '·',
        style: TextStyle(color: color.onSurfaceVariant),
      ),
    );
  }

  // ── Goal Card (decision-first) ──
  Widget _buildGoalCard(
    Goal goal,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    BuildContext context,
    WidgetRef ref,
    AppLocalizations ctxt,
  ) {
    final goalColor =
        goal.colorValue != null ? Color(goal.colorValue!) : color.primary;
    final remaining = goal.remainingAmount;
    final progress = goal.progressPercent;
    final pace = _recentPace(goal);
    final needed = _neededPerMonth(goal);
    final gap = needed > 0 ? pace - needed : 0.0;
    final hasDeadline = goal.targetDate != null;
    final deposit = _suggestedDeposit(goal);
    final gapColor = gap >= 0 ? goalColor : FinanceColors.statusWarning;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              Row(
                children: [
                  Icon(
                    IconHelper.getIconData(goal.iconName),
                    color: goalColor,
                    size: 18,
                  ),
                  SizedBox(width: spacing.elementGapMin),
                  Expanded(
                    child: Text(
                      goal.name.safe(),
                      style: textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              SizedBox(height: spacing.elementGap),

              // Remaining (hero metric on card)
              CurrencyText(
                currencyCode: goal.currencyCode,
                amount: remaining,
                fixedLength: 0,
                compact: false,
                suffixText: ctxt.goal_suffixLeft,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),

              SizedBox(height: spacing.elementGap),

              // Gap signal (neutral: +/-)
              if (needed > 0) ...[
                Row(
                  children: [
                    Text(
                      gap >= 0 ? '+' : '',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: gapColor,
                      ),
                    ),
                    CurrencyText(
                      currencyCode: goal.currencyCode,
                      amount: gap,
                      fixedLength: 0,
                      compact: true,
                      suffixText: '/mo',
                      showSign: gap < 0,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: gapColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.elementGap),
              ],

              // One-tap contribution (visible within 2nd glance)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _quickDeposit(context, ref, goal, deposit);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: goalColor,
                    side: BorderSide(
                      color: goalColor.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(spacing.radiusSmall),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: spacing.elementGapMin,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.plus, size: 14, color: goalColor),
                      const SizedBox(width: 4),
                      CurrencyText(
                        currencyCode: goal.currencyCode,
                        amount: deposit,
                        fixedLength: 0,
                        compact: true,
                        style: textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: goalColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: spacing.elementGap),

              // Evidence: pace vs needed (supporting detail)
              if (needed > 0) ...[
                Row(
                  children: [
                    Text(
                      ctxt.goal_currentAvgMonth,
                      style: textTheme.labelSmall
                          ?.copyWith(color: color.onSurfaceVariant),
                    ),
                    const SizedBox(width: 4),
                    CurrencyText(
                      currencyCode: goal.currencyCode,
                      amount: pace,
                      fixedLength: 0,
                      compact: true,
                      style: textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '  ·  ',
                      style: textTheme.labelSmall
                          ?.copyWith(color: color.outlineVariant),
                    ),
                    Text(
                      ctxt.goal_neededPerMonth,
                      style: textTheme.labelSmall
                          ?.copyWith(color: color.onSurfaceVariant),
                    ),
                    const SizedBox(width: 4),
                    CurrencyText(
                      currencyCode: goal.currencyCode,
                      amount: needed,
                      fixedLength: 0,
                      compact: true,
                      style: textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                SizedBox(height: spacing.elementGapMin),
              ],

              // Target date
              if (hasDeadline)
                Text(
                  safeDateFormat('MMM yyyy', ctxt.localeName)
                      .format(goal.targetDate!),
                  style: textTheme.labelSmall
                      ?.copyWith(color: color.onSurfaceVariant),
                ),

              SizedBox(height: spacing.elementGapMin),

              // Progress bar + % (subordinate, last glance)
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        backgroundColor: goalColor.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(goalColor),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  SizedBox(width: spacing.elementGap),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: textTheme.labelSmall?.copyWith(
                      color: color.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
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

  // ── Completed Card (minimal) ──
  Widget _buildCompletedCard(
    Goal goal,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    BuildContext context,
    AppLocalizations ctxt,
  ) {
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
              const Icon(
                LucideIcons.check,
                color: FinanceColors.statusGood,
                size: 18,
              ),
              SizedBox(width: spacing.elementGap),
              Expanded(
                child: Text(
                  goal.name.safe(),
                  style: textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              CurrencyText(
                currencyCode: goal.currencyCode,
                amount: goal.targetAmount,
                fixedLength: 0,
                compact: true,
                style: textTheme.labelMedium?.copyWith(
                  color: FinanceColors.statusGood,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Quick Deposit (one-tap) ──
  void _quickDeposit(
    BuildContext context,
    WidgetRef ref,
    Goal goal,
    double amount,
  ) async {
    await ref.read(goalServiceProvider).addContribution(goal.id, amount);
    ref.invalidate(goalsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${formatCurrency(amount, code: goal.currencyCode, decimals: 0)} → ${goal.name.safe()}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

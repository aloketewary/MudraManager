import 'package:mudra_manager/core/logic/goal_state_machine.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/utils/refresh_helper.dart';
import 'package:mudra_manager/features/goal/data/goal_provider.dart';
import 'package:mudra_manager/features/goal/presentation/widgets/quick_deposit_sheet.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/finance_v2/finance_progress_bar.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/shared/widgets/safe_text.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/shared/widgets/type_section_header.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';

class GoalScreen extends ConsumerWidget {
  const GoalScreen({super.key});

  /// Convert goal contributions to state machine input.
  List<GoalContributionData> _contributions(Goal goal) {
    return goal.contributions
        .map((c) => GoalContributionData(amount: c.amount, date: c.date))
        .toList();
  }

  /// Priority sort score (delegates to state machine).
  int _sortPriority(Goal goal) {
    final now = DateTime.now();
    final contribs = _contributions(goal);
    final pace = GoalStateMachine.recentPace(contribs, now);
    final needed = GoalStateMachine.neededPerMonth(
      goal.remainingAmount,
      goal.targetDate,
      now,
    );
    final gap = GoalStateMachine.paceGap(pace, needed);
    final daysLeft = GoalStateMachine.daysRemaining(goal.targetDate, now);
    return GoalStateMachine.sortPriority(
      progressPercent: goal.progressPercent,
      gap: gap,
      daysRemaining: daysLeft,
      hasDeadline: goal.targetDate != null,
    );
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
        appBarMode: AppBarMode.none,
        enableRefresh: true,
        customAppBar: _GoalHomeStyleAppBar(
          title: ctxt.title_goals,
          bottomHeight: spacing.cardInner * 3 + spacing.sectionGap,
          onAddGoal: () {
            HapticFeedback.mediumImpact();
            context.push(AppRoutes.addGoal);
          },
        ),
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

          // Priority sort
          activeGoals.sort(
            (a, b) => _sortPriority(a).compareTo(_sortPriority(b)),
          );

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    spacing.cardHorizontal,
                    spacing.cardVertical,
                    spacing.cardHorizontal,
                    spacing.elementGap,
                  ),
                  child: Text(
                    'My Goals',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
                    child: TypeSectionHeader(
                      label:
                          '${ctxt.goal_completedSection} (${completedGoals.length})',
                      icon: LucideIcons.check,
                      accentColor: FinanceColors.statusGood,
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
                        child: _buildGoalCard(
                          completedGoals[index],
                          color,
                          textTheme,
                          spacing,
                          context,
                          ref,
                          isCompleted: true,
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
        loading: () => ListView(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.cardHorizontal,
            vertical: spacing.cardVertical,
          ),
          children: List.generate(4, (_) => const DashboardCardSkeleton()),
        ),
        error: (_, __) => Center(child: Text(BuddyMessages.genericError)),
      ),
    );
  }

  // ── Goal Card (reference layout) ──
  Widget _buildGoalCard(
    Goal goal,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    BuildContext context,
    WidgetRef ref, {
    bool isCompleted = false,
  }) {
    final goalColor = isCompleted
        ? FinanceColors.statusGood
        : goal.colorValue == null
            ? color.primary
            : Color(goal.colorValue!);
    final progress =
        (isCompleted ? 1.0 : goal.progressPercent).clamp(0.0, 1.0).toDouble();
    final percent = (progress * 100).round();
    final cardRadius = spacing.radiusMedium + spacing.elementGapMin;

    return Container(
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push(AppRoutes.goalDetails, extra: {'goal': goal});
        },
        borderRadius: BorderRadius.circular(cardRadius),
        child: Padding(
          padding: EdgeInsets.all(spacing.elementGap),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGoalVisual(goal, goalColor, color, spacing),
              SizedBox(width: spacing.elementGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (goal.description?.trim().isNotEmpty ?? false)
                                Text(
                                  goal.description!.trim(),
                                  style: textTheme.bodySmall?.copyWith(
                                    color: color.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (goal.description?.trim().isNotEmpty ?? false)
                                SizedBox(height: spacing.elementGapMin),
                              Text(
                                goal.name.safe(),
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        _buildGoalActionsButton(
                          goal,
                          color,
                          spacing,
                          context,
                          ref,
                          isCompleted: isCompleted,
                        ),
                      ],
                    ),
                    SizedBox(height: spacing.elementGapMin),
                    Text(
                      '$percent%',
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: spacing.elementGapMin),
                    FinanceProgressBar(
                      value: progress,
                      fillColor: goalColor,
                      trackColor: color.surfaceContainerHighest,
                      showStripeRemainder: false,
                      height: spacing.progressThin,
                      semanticLabel: '${goal.name} progress',
                    ),
                    SizedBox(height: spacing.elementGapMin),
                    Row(
                      children: [
                        CurrencyText(
                          amount: goal.currentAmount,
                          currencyCode: goal.currencyCode,
                          fixedLength: 0,
                          compact: true,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: color.onSurface,
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
                            currencyCode: goal.currencyCode,
                            fixedLength: 0,
                            compact: true,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalVisual(
    Goal goal,
    Color goalColor,
    ColorScheme color,
    AppSpacing spacing,
  ) {
    return Container(
      width: spacing.cardInner * 5,
      height: spacing.cardInner * 4,
      decoration: BoxDecoration(
        color: goalColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: goalColor.withValues(alpha: 0.18)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            goalColor.withValues(alpha: 0.18),
            color.surfaceContainerHighest,
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        IconHelper.resolveIcon(
          iconName: goal.iconName,
          text: '${goal.name} ${goal.description ?? ''}',
          fallback: goal.goalType.icon,
        ),
        color: goalColor,
        size: spacing.iconXL,
      ),
    );
  }

  Widget _buildGoalActionsButton(
    Goal goal,
    ColorScheme color,
    AppSpacing spacing,
    BuildContext context,
    WidgetRef ref, {
    required bool isCompleted,
  }) {
    return IconButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        _showGoalActions(
          context,
          ref,
          goal,
          spacing,
          isCompleted: isCompleted,
        );
      },
      tooltip: 'Goal actions',
      icon: Icon(
        LucideIcons.ellipsis,
        size: spacing.iconMD,
        color: color.onSurfaceVariant,
      ),
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(
        minWidth: spacing.touchTargetSmall,
        minHeight: spacing.touchTargetSmall,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  Future<void> _showGoalActions(
    BuildContext context,
    WidgetRef ref,
    Goal goal,
    AppSpacing spacing, {
    required bool isCompleted,
  }) async {
    final ctxt = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          padding: EdgeInsets.fromLTRB(
            spacing.cardInner,
            spacing.elementGap,
            spacing.cardInner,
            spacing.cardInner,
          ),
          decoration: BoxDecoration(
            color: color.surfaceContainerHigh,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(spacing.radiusLarge),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: spacing.cardInner * 2,
                height: spacing.elementGapMin,
                decoration: BoxDecoration(
                  color: color.primary,
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
              ),
              SizedBox(height: spacing.elementGap),
              Row(
                children: [
                  _buildGoalVisual(goal, color.primary, color, spacing),
                  SizedBox(width: spacing.elementGap),
                  Expanded(
                    child: Text(
                      goal.name.safe(),
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              Divider(height: spacing.sectionGap),
              _goalAction(
                icon: LucideIcons.goal,
                label: ctxt.common_viewDetails,
                color: color,
                spacing: spacing,
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(AppRoutes.goalDetails, extra: {'goal': goal});
                },
              ),
              if (!isCompleted)
                _goalAction(
                  icon: LucideIcons.plus,
                  label: ctxt.goal_quickDeposit,
                  color: color,
                  spacing: spacing,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    HapticFeedback.mediumImpact();
                    showQuickDepositSheet(
                      context: context,
                      ref: ref,
                      goal: goal,
                      goalColor: goal.colorValue == null
                          ? color.primary
                          : Color(goal.colorValue!),
                    );
                  },
                ),
              _goalAction(
                icon: LucideIcons.pencil,
                label: ctxt.goal_editGoal,
                color: color,
                spacing: spacing,
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(AppRoutes.editGoal, extra: {'goal': goal});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _goalAction({
    required IconData icon,
    required String label,
    required ColorScheme color,
    required AppSpacing spacing,
    required VoidCallback onTap,
  }) {
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: spacing.touchTargetSmall,
          height: spacing.touchTargetSmall,
          decoration: BoxDecoration(
            color: color.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(spacing.radiusSmall),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: spacing.iconSM, color: color.primary),
        ),
        title: Text(label),
        trailing: Icon(
          LucideIcons.chevronRight,
          size: spacing.iconSM,
          color: color.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _GoalHomeStyleAppBar extends ConsumerWidget
    implements PreferredSizeWidget {
  const _GoalHomeStyleAppBar({
    required this.title,
    required this.bottomHeight,
    required this.onAddGoal,
  });

  final String title;
  final double bottomHeight;
  final VoidCallback onAddGoal;

  @override
  Size get preferredSize => Size.fromHeight(80 + bottomHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;
    final goals = ref.watch(goalsProvider).asData?.value ?? const <Goal>[];
    final savedAmount = goals.fold<double>(
      0,
      (sum, goal) => sum + goal.currentAmount,
    );
    final targetAmount = goals.fold<double>(
      0,
      (sum, goal) => sum + goal.targetAmount,
    );

    return AppBar(
      automaticallyImplyLeading: true,
      backgroundColor: color.surfaceContainerHigh,
      foregroundColor: color.onSurface,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.surfaceContainerHigh,
              color.primaryContainer.withValues(alpha: 0.72),
            ],
          ),
        ),
      ),
      scrolledUnderElevation: 0,
      toolbarHeight: 80,
      titleSpacing: spacing.cardInner,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(spacing.radiusLarge + spacing.elementGap),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      title: Text(
        title,
        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(bottomHeight),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            spacing.cardInner,
            0,
            spacing.cardInner,
            spacing.cardInner,
          ),
          child: Container(
            padding: EdgeInsets.all(spacing.elementGap),
            child: Row(
              children: [
                Expanded(
                  child: _GoalHeaderAmount(
                    label: ctxt.goal_suffixSaved,
                    amount: savedAmount,
                    color: color,
                    textTheme: textTheme,
                    spacing: spacing,
                  ),
                ),
                SizedBox(width: spacing.elementGap * 2),
                Expanded(
                  child: _GoalHeaderAmount(
                    label: ctxt.goal_target,
                    amount: targetAmount,
                    color: color,
                    textTheme: textTheme,
                    spacing: spacing,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: spacing.cardInner),
          child: IconButton(
            onPressed: onAddGoal,
            tooltip: 'Add goal',
            icon: const Icon(LucideIcons.plus),
            style: IconButton.styleFrom(
              foregroundColor: color.onPrimary,
              backgroundColor: color.primary,
              minimumSize: Size.square(spacing.touchTargetSmall),
              maximumSize: Size.square(spacing.touchTargetSmall),
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalHeaderAmount extends StatelessWidget {
  const _GoalHeaderAmount({
    required this.label,
    required this.amount,
    required this.color,
    required this.textTheme,
    required this.spacing,
  });

  final String label;
  final double amount;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: color.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: spacing.elementGapMin),
        CurrencyText(
          amount: amount,
          compact: false,
          fixedLength: 0,
          style: textTheme.headlineMedium?.copyWith(
            color: color.onSurface,
            fontWeight: FontWeight.w500,
            height: 1,
          ),
        ),
      ],
    );
  }
}

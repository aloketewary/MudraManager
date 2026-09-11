import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/utils/safe_date_format.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/goal/data/goal_provider.dart';
import 'package:mudra_manager/features/goal/presentation/widgets/contribution_history_sheet.dart';
import 'package:mudra_manager/features/goal/presentation/widgets/quick_deposit_sheet.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/finance_v2/finance_progress_bar.dart';
import 'package:mudra_manager/shared/widgets/safe_text.dart';

class GoalDetailsScreen extends ConsumerStatefulWidget {
  final Goal goal;

  const GoalDetailsScreen({super.key, required this.goal});

  @override
  ConsumerState<GoalDetailsScreen> createState() => _GoalDetailsScreenState();
}

class _GoalDetailsScreenState extends ConsumerState<GoalDetailsScreen> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    if (widget.goal.progressPercent >= 1.0) {
      Future.delayed(
        const Duration(milliseconds: 500),
        () => _confettiController.play(),
      );
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _deleteGoal(AppSpacing spacing) async {
    final ctxt = AppLocalizations.of(context)!;
    final confirmed = await DialogUtils.showDeleteConfirmation(
      context,
      spacing,
      title: ctxt.goal_deleteGoalTitle,
    );
    if (confirmed != true || !mounted) return;

    var undone = false;
    Future.delayed(const Duration(seconds: 6), () async {
      if (undone || !mounted) return;
      await ref.read(goalServiceProvider).deleteGoal(widget.goal.id);
      ref.invalidate(goalsProvider);
      if (mounted) context.pop();
    });

    SnackbarService.success(
      BuddyMessages.goalDeleted,
      spacing,
      actionLabel: ctxt.common_undo,
      onAction: () {
        undone = true;
        ref.invalidate(goalsProvider);
      },
    );
  }

  void _openQuickDeposit(Color goalColor) {
    HapticFeedback.mediumImpact();
    showQuickDepositSheet(
      context: context,
      ref: ref,
      goal: widget.goal,
      goalColor: goalColor,
      onCompleted: () => _confettiController.play(),
    );
  }

  void _openHistory(
    List<GoalContribution> contributions,
    Color goalColor,
    AppSpacing spacing,
  ) {
    HapticFeedback.lightImpact();
    showContributionHistorySheet(
      context: context,
      contributions: contributions,
      goal: widget.goal,
      goalColor: goalColor,
      spacing: spacing,
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isGuestMode = ref.watch(guestModeProvider);
    final progress = widget.goal.progressPercent.clamp(0.0, 1.0).toDouble();
    final isCompleted = progress >= 1.0;
    final goalColor = widget.goal.colorValue == null
        ? color.primary
        : Color(widget.goal.colorValue!);
    final savedAmount = GuestModeUtil.applyGuestMode(
      widget.goal.currentAmount,
      isGuestMode,
    );
    final targetAmount = GuestModeUtil.applyGuestMode(
      widget.goal.targetAmount,
      isGuestMode,
    );
    final sortedContribs = widget.goal.contributions.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return ScreenShell(
      config: ScreenShellConfig(
        customAppBar: _GoalDetailsAppBar(
          title: widget.goal.name.safe(),
          savedAmount: savedAmount,
          targetAmount: targetAmount,
          currencyCode: widget.goal.currencyCode,
          spacing: spacing,
          onBack: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
          editLabel: ctxt.goal_editGoal,
          deleteLabel: ctxt.goal_deleteGoal,
          onEdit: () {
            HapticFeedback.mediumImpact();
            context.push(AppRoutes.editGoal, extra: {'goal': widget.goal});
          },
          onDelete: () {
            HapticFeedback.mediumImpact();
            _deleteGoal(spacing);
          },
        ),
      ),
      body: Stack(
        children: [
          ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              spacing.cardHorizontalMax,
              spacing.sectionGap,
              spacing.cardHorizontalMax,
              spacing.cardInner * 5 +
                  MediaQuery.of(context).padding.bottom +
                  spacing.sectionGap,
            ),
            children: [
              _buildProgressCard(
                goalColor,
                color,
                textTheme,
                spacing,
                progress,
                isGuestMode,
                isCompleted,
                ctxt,
              ),
              SizedBox(height: spacing.sectionGap * 1.5),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      ctxt.goal_recentActivity,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (sortedContribs.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _openHistory(
                        sortedContribs,
                        goalColor,
                        spacing,
                      ),
                      icon: const Icon(LucideIcons.chevronRight, size: 16),
                      label: Text(ctxt.dashboard_viewAllLabel),
                      style: TextButton.styleFrom(
                        foregroundColor: goalColor,
                        padding: EdgeInsets.symmetric(
                          horizontal: spacing.elementGapMin,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: spacing.elementGap),
              if (sortedContribs.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: spacing.sectionGap),
                  child: Text(
                    ctxt.goal_recentActivity,
                    style: textTheme.bodyMedium?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ...sortedContribs.take(3).map(
                      (contribution) => _buildContributionTile(
                        contribution,
                        goalColor,
                        color,
                        textTheme,
                        spacing,
                        ctxt,
                        isGuestMode,
                      ),
                    ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                spacing.cardHorizontal,
                spacing.elementGap,
                spacing.cardHorizontal,
                MediaQuery.of(context).padding.bottom + spacing.elementGap,
              ),
              decoration: BoxDecoration(
                color: color.surface.withValues(alpha: 0.96),
                border: Border(
                  top: BorderSide(
                    color: color.outlineVariant.withValues(alpha: 0.25),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                        isCompleted ? null : () => _openQuickDeposit(goalColor),
                    style: FilledButton.styleFrom(
                      backgroundColor: goalColor,
                      foregroundColor: color.onPrimary,
                      disabledBackgroundColor: color.surfaceContainerHighest,
                      disabledForegroundColor: color.onSurfaceVariant,
                      minimumSize: Size(double.infinity, spacing.touchTarget),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(spacing.radiusLarge),
                      ),
                    ),
                    child: const Text('Top up goal balance'),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: math.pi / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.3,
              colors: [
                goalColor,
                Colors.amber,
                FinanceColors.statusGood,
                Colors.pink,
                Colors.blue,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
    Color goalColor,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    double progress,
    bool isGuestMode,
    bool isCompleted,
    AppLocalizations ctxt,
  ) {
    final isDark = color.brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            goalColor.withValues(alpha: isDark ? 0.22 : 0.12),
            color.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(spacing.radiusLarge),
        border: Border.all(
          color: goalColor.withValues(alpha: isDark ? 0.32 : 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: goalColor.withValues(alpha: isDark ? 0.16 : 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGoalVisual(goalColor, color, spacing),
          SizedBox(height: spacing.elementGap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: CurrencyText(
                  currencyCode: widget.goal.currencyCode,
                  amount: GuestModeUtil.applyGuestMode(
                    widget.goal.currentAmount,
                    isGuestMode,
                  ),
                  fixedLength: 0,
                  compact: false,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                ' / ',
                style: textTheme.bodyMedium?.copyWith(
                  color: color.onSurfaceVariant,
                ),
              ),
              CurrencyText(
                currencyCode: widget.goal.currencyCode,
                amount: GuestModeUtil.applyGuestMode(
                  widget.goal.targetAmount,
                  isGuestMode,
                ),
                fixedLength: 0,
                compact: true,
                style: textTheme.bodyMedium?.copyWith(
                  color: color.onSurfaceVariant,
                ),
              ),
              SizedBox(width: spacing.elementGap),
              Text(
                '${(progress * 100).round()}%',
                style: textTheme.titleSmall?.copyWith(
                  color: goalColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.elementGap),
          FinanceProgressBar(
            value: progress,
            fillColor: goalColor,
            trackColor: color.surfaceContainerHighest,
            stripeColor: goalColor.withValues(alpha: 0.20),
            height: spacing.progressNormal,
            semanticLabel: '${widget.goal.name.safe()} progress',
          ),
          SizedBox(height: spacing.sectionGap),
          _buildMilestoneRail(progress, goalColor, color, textTheme, spacing),
          if (isCompleted) ...[
            SizedBox(height: spacing.elementGap),
            Text(
              ctxt.goal_completedSection,
              style: textTheme.bodyMedium?.copyWith(
                color: FinanceColors.statusGood,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMilestoneRail(
    double progress,
    Color goalColor,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    const milestones = [0, 25, 50, 75, 100];
    const milestoneIcons = [
      LucideIcons.flag,
      LucideIcons.chartBar,
      LucideIcons.target,
      LucideIcons.sparkles,
      LucideIcons.trophy,
    ];
    final currentIndex = milestones.lastIndexWhere(
      (milestone) => milestone / 100 <= progress,
    );

    return Column(
      children: [
        SizedBox(
          height: spacing.elementGap * 3.5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: spacing.elementGap,
                right: spacing.elementGap,
                child: Container(
                  height: spacing.progressThin,
                  decoration: BoxDecoration(
                    color: color.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  ),
                ),
              ),
              Positioned(
                left: spacing.elementGap,
                right: spacing.elementGap,
                child: FractionallySizedBox(
                  widthFactor: progress,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: spacing.progressThin,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          goalColor,
                          goalColor.withValues(alpha: 0.72),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(spacing.radiusSmall),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var index = 0; index < milestones.length; index++)
                    _milestoneDot(
                      reached: index <= currentIndex,
                      isCurrent: index == currentIndex && progress < 1,
                      icon: milestoneIcons[index],
                      goalColor: goalColor,
                      color: color,
                      spacing: spacing,
                    ),
                ],
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var index = 0; index < milestones.length; index++)
              Text(
                '${milestones[index]}%',
                style: textTheme.labelSmall?.copyWith(
                  color: index <= currentIndex
                      ? goalColor
                      : color.onSurfaceVariant,
                  fontWeight:
                      index == currentIndex ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _milestoneDot({
    required bool reached,
    required bool isCurrent,
    required IconData icon,
    required Color goalColor,
    required ColorScheme color,
    required AppSpacing spacing,
  }) {
    final markerSize = spacing.elementGap * (isCurrent ? 2.75 : 2.25);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      width: markerSize,
      height: markerSize,
      decoration: BoxDecoration(
        color: isCurrent
            ? goalColor.withValues(alpha: 0.14)
            : reached
                ? goalColor
                : color.surfaceContainerHigh,
        shape: BoxShape.circle,
        border: Border.all(
          color: isCurrent || reached
              ? goalColor
              : color.outlineVariant.withValues(alpha: 0.7),
          width: isCurrent ? spacing.strokeThin * 1.5 : spacing.strokeThin,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        reached ? LucideIcons.check : icon,
        size: isCurrent ? spacing.iconSM : spacing.iconXS,
        color: isCurrent
            ? goalColor
            : reached
                ? color.onPrimary
                : color.onSurfaceVariant,
      ),
    );
  }

  Widget _buildGoalVisual(
    Color goalColor,
    ColorScheme color,
    AppSpacing spacing,
  ) {
    return Container(
      width: double.infinity,
      height: spacing.sectionGap * 7,
      decoration: BoxDecoration(
        color: goalColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
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
          iconName: widget.goal.iconName,
          text: '${widget.goal.name} ${widget.goal.description ?? ''}',
          fallback: widget.goal.goalType.icon,
        ),
        color: goalColor,
        size: spacing.iconXL * 2.2,
      ),
    );
  }

  Widget _buildContributionTile(
    GoalContribution contribution,
    Color goalColor,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
    bool isGuestMode,
  ) {
    final dateLabel = safeDateFormat('dd MMM yyyy', ctxt.localeName)
        .format(contribution.date);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.elementGap),
      child: Row(
        children: [
          Text(
            dateLabel,
            style: textTheme.bodyMedium?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          CurrencyText(
            currencyCode: widget.goal.currencyCode,
            amount: GuestModeUtil.applyGuestMode(
              contribution.amount,
              isGuestMode,
            ),
            fixedLength: 0,
            compact: true,
            showSign: true,
            style: textTheme.bodyMedium?.copyWith(
              color: goalColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalDetailsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _GoalDetailsAppBar({
    required this.title,
    required this.savedAmount,
    required this.targetAmount,
    required this.currencyCode,
    required this.spacing,
    required this.onBack,
    required this.editLabel,
    required this.deleteLabel,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final double savedAmount;
  final double targetAmount;
  final String? currencyCode;
  final AppSpacing spacing;
  final VoidCallback onBack;
  final String editLabel;
  final String deleteLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Size get preferredSize => Size.fromHeight(80 + spacing.cardInner * 2.5);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      automaticallyImplyLeading: false,
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
      leading: Padding(
        padding: EdgeInsets.only(left: spacing.cardHorizontal),
        child: IconButton(
          onPressed: onBack,
          tooltip: 'Back',
          icon: const Icon(LucideIcons.arrowLeft),
        ),
      ),
      title: Text(
        title,
        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Goal actions',
          onSelected: (value) {
            HapticFeedback.mediumImpact();
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(LucideIcons.pen, size: 18),
                  SizedBox(width: spacing.elementGap),
                  Text(editLabel),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(LucideIcons.trash2, size: 18, color: color.error),
                  SizedBox(width: spacing.elementGap),
                  Text(deleteLabel),
                ],
              ),
            ),
          ],
          icon: const Icon(LucideIcons.ellipsis),
        ),
        SizedBox(width: spacing.cardHorizontal),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(spacing.cardInner * 2.5),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            spacing.cardInner,
            0,
            spacing.cardInner,
            spacing.cardInner,
          ),
          child: Row(
            children: [
              Expanded(
                child: _headerAmount(
                  context,
                  'Saved',
                  savedAmount,
                  currencyCode,
                ),
              ),
              SizedBox(width: spacing.elementGap * 2),
              Expanded(
                child: _headerAmount(
                  context,
                  'Target',
                  targetAmount,
                  currencyCode,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerAmount(
    BuildContext context,
    String label,
    double amount,
    String? currencyCode,
  ) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
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
          currencyCode: currencyCode,
          compact: false,
          fixedLength: 0,
          style: textTheme.titleLarge?.copyWith(
            color: color.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

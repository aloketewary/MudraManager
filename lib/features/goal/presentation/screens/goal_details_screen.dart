import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/utils/safe_date_format.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_provider.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/features/goal/data/goal_provider.dart';
import 'package:mudra_manager/features/goal/domain/goal_health.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math;
import 'package:mudra_manager/core/router/app_routes.dart';

class GoalDetailsScreen extends ConsumerStatefulWidget {
  final Goal goal;
  const GoalDetailsScreen({super.key, required this.goal});

  @override
  ConsumerState<GoalDetailsScreen> createState() => _GoalDetailsScreenState();
}

class _GoalDetailsScreenState extends ConsumerState<GoalDetailsScreen> {
  late ConfettiController _confettiController;

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

  Future<void> _deleteGoal() async {
    final confirmed = await DialogUtils.showDeleteConfirmation(
      context,
      title: AppLocalizations.of(context)!.goal_deleteGoalTitle,
    );
    if (confirmed == true && mounted) {
      bool undone = false;
      final ctxt = AppLocalizations.of(context)!;

      // Schedule actual delete after undo window
      Future.delayed(const Duration(seconds: 6), () async {
        if (undone || !mounted) return;
        await ref.read(goalServiceProvider).deleteGoal(widget.goal.id);
        ref.invalidate(goalsProvider);
        context.pop();
      });

      SnackbarService.success(
        BuddyMessages.goalDeleted,
        actionLabel: ctxt.common_undo,
        onAction: () {
          undone = true;
          ref.invalidate(goalsProvider);
        },
      );
    }
  }

  // ── Emotional headline ──
  String _emotionLine(
    double progress,
    GoalHealth health,
    AppLocalizations ctxt,
  ) {
    if (progress >= 1.0) return ctxt.goal_emotionDidIt;
    if (progress >= 0.9) return ctxt.goal_emotionAlmost;
    if (progress >= 0.75) return ctxt.goal_emotionSoClose;
    if (progress >= 0.5) return ctxt.goal_emotionHalfwayDone;
    if (progress >= 0.25) return ctxt.goal_emotionMomentum;
    if (health.status == GoalStatus.behind) return ctxt.goal_emotionCatchUp;
    return ctxt.goal_emotionEvery;
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;
    final progress = widget.goal.progressPercent;
    final remaining = widget.goal.remainingAmount;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isGuestMode = ref.watch(guestModeProvider);
    final goalColor = widget.goal.colorValue != null
        ? Color(widget.goal.colorValue!)
        : color.primary;
    final health = GoalHealth.compute(widget.goal);
    final statusColor = health.statusColor(color);
    final daysLeft =
        widget.goal.targetDate?.difference(DateTime.now()).inDays ?? 0;
    final monthsLeft = daysLeft > 0 ? daysLeft / 30 : 0;
    final suggestedMonthly = monthsLeft > 0 ? remaining / monthsLeft : 0;
    final currentAmount =
        GuestModeUtil.applyGuestMode(widget.goal.currentAmount, isGuestMode);

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        title: Text(
          widget.goal.name,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          PopupMenuButton(
            icon: const Icon(LucideIcons.ellipsisVertical),
            onSelected: (value) {
              if (value == 'edit') {
                context.push(AppRoutes.addGoal, extra: {'goal': widget.goal});
              } else if (value == 'delete') {
                _deleteGoal();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(LucideIcons.pen, size: 18),
                    SizedBox(width: spacing.elementGap),
                    Text(ctxt.goal_editGoal),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(LucideIcons.trash2, size: 18, color: color.error),
                    SizedBox(width: spacing.elementGap),
                    Text(
                      ctxt.goal_deleteGoal,
                      style: TextStyle(color: color.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(width: spacing.cardHorizontal),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.symmetric(vertical: spacing.cardVertical),
            children: [
              // ── Hero Card ──
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontal,
                  vertical: spacing.cardVertical,
                ),
                child: Container(
                  padding:
                      EdgeInsets.all(spacing.cardInner + spacing.elementGapMin),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        goalColor.withValues(alpha: 0.15),
                        goalColor.withValues(alpha: 0.03),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    border:
                        Border.all(color: goalColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left — info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Emotional headline
                            Text(
                              _emotionLine(progress, health, ctxt),
                              style: textTheme.bodyMedium?.copyWith(
                                color: goalColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: spacing.elementGap),
                            // Icon + name
                            Row(
                              children: [
                                Container(
                                  padding:
                                      EdgeInsets.all(spacing.elementGap * 0.75),
                                  decoration: BoxDecoration(
                                    color: goalColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                      spacing.radiusSmall,
                                    ),
                                  ),
                                  child: Icon(
                                    IconHelper.getIconData(
                                      widget.goal.iconName,
                                    ),
                                    color: goalColor,
                                    size: 22,
                                  ),
                                ),
                                SizedBox(width: spacing.elementGap),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.goal.name,
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (widget.goal.description != null)
                                        Text(
                                          widget.goal.description!,
                                          style: textTheme.bodySmall?.copyWith(
                                            color: color.onSurfaceVariant,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing.elementGap * 1.2),
                            // Human-readable amounts
                            CurrencyText(
                              currencyCode: widget.goal.currencyCode,
                              amount: currentAmount,
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
                              currencyCode: widget.goal.currencyCode,
                              amount: remaining,
                              fixedLength: 0,
                              compact: false,
                              suffixText: ctxt.goal_suffixLeft,
                              style: textTheme.bodySmall
                                  ?.copyWith(color: color.onSurfaceVariant),
                            ),
                            if (daysLeft > 0) ...[
                              SizedBox(height: spacing.elementGapUltraMin),
                              Text(
                                _formatDaysLeft(daysLeft),
                                style: textTheme.bodySmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                            ],
                            SizedBox(height: spacing.elementGap),
                            // Status badge
                            _buildStatusBadge(
                              health,
                              statusColor,
                              textTheme,
                              spacing,
                              ctxt,
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
                        ctxt,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Smart Insight (promoted — right after hero) ──
              _buildSmartInsight(
                goalColor,
                color,
                textTheme,
                spacing,
                ctxt,
              ),

              // ── Quick Deposit ──
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontal,
                  vertical: spacing.cardVertical,
                ),
                child: FilledButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _showQuickDepositSheet(context, goalColor, spacing);
                  },
                  icon: const Icon(LucideIcons.plus, size: 20),
                  label: Text(
                    progress >= 0.9
                        ? ctxt.goal_finishGoal
                        : ctxt.goal_quickDeposit,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: goalColor,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    ),
                  ),
                ),
              ),

              // ── Target Date ──
              if (widget.goal.targetDate != null)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.cardHorizontal,
                    vertical: spacing.cardVertical,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(spacing.cardInner),
                    decoration: BoxDecoration(
                      color: color.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                      border: Border.all(
                        color: color.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(spacing.elementGap * 0.75),
                          decoration: BoxDecoration(
                            color: color.primary.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(spacing.radiusSmall),
                          ),
                          child: Icon(
                            LucideIcons.calendar,
                            color: color.primary,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: spacing.elementGap),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                safeDateFormat('dd MMMM yyyy', ctxt.localeName)
                                    .format(widget.goal.targetDate!),
                                style: textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              if (daysLeft > 0 && suggestedMonthly > 0)
                                Text(
                                  'Save ${formatCurrency(suggestedMonthly.toDouble(), code: widget.goal.currencyCode, decimals: 0)}/month to reach on time',
                                  style: textTheme.bodySmall
                                      ?.copyWith(color: color.onSurfaceVariant),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Milestones ──
              Padding(
                padding: EdgeInsets.fromLTRB(
                  spacing.cardHorizontal,
                  spacing.sectionGap,
                  spacing.cardHorizontal,
                  spacing.elementGap,
                ),
                child: _sectionHeader(
                  ctxt.goal_milestones,
                  LucideIcons.award,
                  color,
                  textTheme,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontal,
                  vertical: spacing.cardVertical,
                ),
                child: Container(
                  padding: EdgeInsets.all(spacing.cardInner),
                  decoration: BoxDecoration(
                    color: color.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    border: Border.all(
                      color: color.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildMilestone(
                        ctxt.goal_milestoneStarted,
                        ctxt.goal_milestoneStartedDesc,
                        widget.goal.currentAmount >= 0,
                        goalColor,
                        textTheme,
                        color,
                        spacing,
                      ),
                      _buildMilestone(
                        '25%',
                        ctxt.goal_milestone25Desc,
                        progress >= 0.25,
                        goalColor,
                        textTheme,
                        color,
                        spacing,
                      ),
                      _buildMilestone(
                        '50%',
                        ctxt.goal_emotionHalfwayDone,
                        progress >= 0.50,
                        goalColor,
                        textTheme,
                        color,
                        spacing,
                      ),
                      _buildMilestone(
                        '75%',
                        ctxt.goal_milestone75Desc,
                        progress >= 0.75,
                        goalColor,
                        textTheme,
                        color,
                        spacing,
                      ),
                      _buildMilestone(
                        '100%',
                        ctxt.goal_emotionReached,
                        progress >= 1.0,
                        goalColor,
                        textTheme,
                        color,
                        spacing,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Contributions ──
              if (widget.goal.contributions.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    spacing.cardHorizontal,
                    spacing.sectionGap,
                    spacing.cardHorizontal,
                    spacing.elementGap,
                  ),
                  child: _sectionHeader(
                    ctxt.goal_recentActivity,
                    LucideIcons.history,
                    color,
                    textTheme,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.cardHorizontal,
                    vertical: spacing.cardVertical,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                      border: Border.all(
                        color: color.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: () {
                        final sorted = widget.goal.contributions.toList()
                          ..sort((a, b) => b.date.compareTo(a.date));
                        final items = sorted.take(10).toList();
                        return items.asMap().entries.map((entry) {
                          final isLast = entry.key == items.length - 1;
                          return Column(
                            children: [
                              _buildContributionTile(
                                entry.value,
                                goalColor,
                                color,
                                textTheme,
                                spacing,
                                ctxt,
                              ),
                              if (!isLast)
                                Divider(
                                  height: 1,
                                  indent: 52,
                                  endIndent: spacing.cardInner,
                                  color: color.outlineVariant
                                      .withValues(alpha: 0.3),
                                ),
                            ],
                          );
                        }).toList();
                      }(),
                    ),
                  ),
                ),
              ],

              SizedBox(height: spacing.sectionGap * 5),
            ],
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

  // ── Status Badge ──
  Widget _buildStatusBadge(
    GoalHealth health,
    Color statusColor,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final label = switch (health.status) {
      GoalStatus.ahead => ctxt.goal_aheadOfSchedule,
      GoalStatus.onTrack => ctxt.goal_onTrack,
      GoalStatus.behind => ctxt.goal_behindPace,
      GoalStatus.completed => ctxt.goal_completedSection,
      GoalStatus.noDeadline => ctxt.goal_flexibleTimeline,
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.elementGap,
        vertical: spacing.elementGapMin,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall
            ?.copyWith(color: statusColor, fontWeight: FontWeight.w600),
      ),
    );
  }

  // ── Progress Ring ──
  Widget _buildProgressRing(
    double progress,
    Color goalColor,
    ColorScheme color,
    TextTheme textTheme,
    AppLocalizations ctxt,
  ) {
    final clamped = progress.clamp(0.0, 1.0);
    final filled = clamped > 0 ? clamped : 0.001;
    final rem = 1.0 - clamped;

    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 40,
              startDegreeOffset: -90,
              sections: [
                PieChartSectionData(
                  value: filled,
                  color: goalColor,
                  radius: 8,
                  showTitle: false,
                ),
                if (rem > 0)
                  PieChartSectionData(
                    value: rem,
                    color: goalColor.withValues(alpha: 0.08),
                    radius: 8,
                    showTitle: false,
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(clamped * 100).toStringAsFixed(0)}%',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: goalColor,
                  height: 1,
                ),
              ),
              Text(
                ctxt.goal_suffixDone,
                style: textTheme.labelSmall?.copyWith(
                  color: goalColor.withValues(alpha: 0.6),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Smart Insight ──
  Widget _buildSmartInsight(
    Color goalColor,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final health = GoalHealth.compute(widget.goal);
    final statusColor = health.statusColor(color);
    final primary = health.insightMessage(widget.goal);
    final secondary = health.secondaryInsight(widget.goal);
    final monthContrib = GoalHealth.contributionThisMonth(widget.goal);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      child: Container(
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          color: color.surfaceContainerLow,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacing.elementGap * 0.75),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  ),
                  child:
                      Icon(LucideIcons.sparkles, size: 18, color: statusColor),
                ),
                SizedBox(width: spacing.elementGap),
                Text(
                  ctxt.goal_smartInsight,
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: spacing.elementGap),
            Text(
              primary,
              style: textTheme.bodyMedium?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (secondary != null) ...[
              SizedBox(height: spacing.elementGapMin),
              Text(
                secondary,
                style: textTheme.bodySmall
                    ?.copyWith(color: color.onSurfaceVariant),
              ),
            ],
            if (monthContrib > 0) ...[
              SizedBox(height: spacing.elementGap),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.elementGap,
                  vertical: spacing.elementGapMin,
                ),
                decoration: BoxDecoration(
                  color: goalColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
                child: Text(
                  Tone.current.goalContributionThisMonth(
                    formatCurrency(
                      monthContrib,
                      code: widget.goal.currencyCode,
                      decimals: 0,
                    ),
                  ),
                  style: textTheme.labelMedium
                      ?.copyWith(color: goalColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Milestone (connected timeline) ──
  Widget _buildMilestone(
    String title,
    String subtitle,
    bool achieved,
    Color goalColor,
    TextTheme textTheme,
    ColorScheme color,
    AppSpacing spacing, {
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        children: [
          // Timeline column — dot + line
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: achieved ? goalColor : color.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: achieved
                          ? goalColor
                          : color.outlineVariant.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: achieved
                      ? const Icon(
                          LucideIcons.check,
                          color: Colors.white,
                          size: 12,
                        )
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: achieved
                          ? goalColor.withValues(alpha: 0.3)
                          : color.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: spacing.elementGap),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : spacing.elementGap * 1.5,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: achieved ? FontWeight.bold : FontWeight.w500,
                      color:
                          achieved ? color.onSurface : color.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: textTheme.labelSmall?.copyWith(
                      color: achieved
                          ? goalColor.withValues(alpha: 0.7)
                          : color.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Contribution Tile ──
  Widget _buildContributionTile(
    GoalContribution c,
    Color goalColor,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final diff = DateTime.now().difference(c.date);
    final timeLabel = diff.inDays == 0
        ? ctxt.common_today
        : diff.inDays == 1
            ? ctxt.common_yesterday
            : diff.inDays < 7
                ? ctxt.goal_daysAgo(diff.inDays)
                : safeDateFormat('dd MMM', ctxt.localeName).format(c.date);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardInner,
        vertical: spacing.elementGap * 1.2,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: goalColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.plus, size: 16, color: goalColor),
          ),
          SizedBox(width: spacing.elementGap),
          Expanded(
            child: CurrencyText(
              currencyCode: widget.goal.currencyCode,
              amount: c.amount,
              fixedLength: 0,
              style:
                  textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            timeLabel,
            style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // ── Quick Deposit Sheet ──
  void _showQuickDepositSheet(
    BuildContext context,
    Color goalColor,
    AppSpacing spacing,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + spacing.sectionGap,
          left: spacing.sectionGap,
          right: spacing.sectionGap,
          top: spacing.sectionGap,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacing.elementGap),
                  decoration: BoxDecoration(
                    color: goalColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  ),
                  child:
                      Icon(LucideIcons.piggyBank, color: goalColor, size: 24),
                ),
                SizedBox(width: spacing.elementGap * 1.5),
                Text(
                  ctxt.goal_quickDeposit,
                  style: textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: spacing.sectionGap),
            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: ctxt.common_amount,
                prefixIcon: Icon(ref.watch(baseCurrencyIconProvider)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                ),
              ),
            ),
            SizedBox(height: spacing.sectionGap),
            FilledButton.icon(
              onPressed: () async {
                final amount = double.tryParse(amountController.text.trim());
                if (amount != null && amount > 0) {
                  HapticFeedback.mediumImpact();
                  final wasComplete = widget.goal.progressPercent >= 1.0;
                  widget.goal.currentAmount += amount;
                  widget.goal.contributions = [
                    ...widget.goal.contributions,
                    GoalContribution.create(amount),
                  ];
                  final isNowComplete = widget.goal.progressPercent >= 1.0;
                  await ref.read(goalServiceProvider).updateGoal(widget.goal);
                  ref.invalidate(goalsProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                    setState(() {});
                    SnackbarService.success(
                      '${formatCurrency(amount, code: widget.goal.currencyCode, decimals: 0)} added to ${widget.goal.name}',
                    );
                    if (!wasComplete && isNowComplete) {
                      _confettiController.play();
                      SnackbarService.success(
                        Tone.current.goalMilestone100(widget.goal.name),
                      );
                    }
                  }
                }
              },
              icon: const Icon(LucideIcons.plus, size: 20),
              style: FilledButton.styleFrom(
                backgroundColor: goalColor,
                minimumSize: const Size(double.infinity, 56),
              ),
              label: Text(ctxt.goal_addToGoal),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDaysLeft(int days) {
    final ctxt = AppLocalizations.of(context)!;
    if (days > 60) return ctxt.goal_monthsLeft((days / 30).round());
    return ctxt.goal_daysLeft(days);
  }
}

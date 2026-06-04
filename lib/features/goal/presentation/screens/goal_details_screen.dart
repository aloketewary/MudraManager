import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/utils/safe_date_format.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
import 'package:mudra_manager/shared/widgets/safe_text.dart';
import 'dart:math' as math;
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/shared/widgets/milestone_share_sheet.dart';

class GoalDetailsScreen extends ConsumerStatefulWidget {
  final Goal goal;
  const GoalDetailsScreen({super.key, required this.goal});

  @override
  ConsumerState<GoalDetailsScreen> createState() => _GoalDetailsScreenState();
}

class _GoalDetailsScreenState extends ConsumerState<GoalDetailsScreen> {
  late ConfettiController _confettiController;
  bool _milestonesExpanded = false;

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
    final ctxt = AppLocalizations.of(context)!;
    final confirmed = await DialogUtils.showDeleteConfirmation(
      context,
      title: ctxt.goal_deleteGoalTitle,
    );
    if (confirmed == true && mounted) {
      bool undone = false;

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

  /// Average monthly contribution from actual deposit history only.
  double _avgMonthlyContribution() {
    final contributions = widget.goal.contributions;
    if (contributions.isEmpty) return 0;
    final total = contributions.fold(0.0, (sum, c) => sum + c.amount);
    final first =
        contributions.reduce((a, b) => a.date.isBefore(b.date) ? a : b).date;
    final months = DateTime.now().difference(first).inDays / 30;
    if (months < 1) return total;
    return total / months;
  }

  /// Number of milestones reached (out of 5).
  int _milestonesReached() {
    final p = widget.goal.progressPercent;
    int count = 0;
    if (widget.goal.currentAmount > 0) count++;
    if (p >= 0.25) count++;
    if (p >= 0.50) count++;
    if (p >= 0.75) count++;
    if (p >= 1.0) count++;
    return count;
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
    final daysLeft =
        widget.goal.targetDate?.difference(DateTime.now()).inDays ?? 0;
    final monthsLeft = daysLeft > 0 ? daysLeft / 30 : 0.0;
    final neededPerMonth = monthsLeft > 0 ? remaining / monthsLeft : 0.0;
    final avgPerMonth = _avgMonthlyContribution();
    final isAheadOfPace = avgPerMonth >= neededPerMonth && neededPerMonth > 0;
    final isCompleted = progress >= 1.0;

    // Last contribution
    final sortedContribs = widget.goal.contributions.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final lastContrib = sortedContribs.isNotEmpty ? sortedContribs.first : null;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        elevation: 0,
        actions: [
          PopupMenuButton(
            icon: const Icon(LucideIcons.ellipsisVertical),
            onSelected: (value) {
              if (value == 'edit') {
                context.push(AppRoutes.editGoal, extra: {'goal': widget.goal});
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
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
            children: [
              // ── 1. Identity (small, orientation only) ──
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(spacing.elementGapMin),
                    decoration: BoxDecoration(
                      color: goalColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(spacing.radiusSmall),
                    ),
                    child: Icon(
                      IconHelper.getIconData(widget.goal.iconName),
                      color: goalColor,
                      size: spacing.iconSM,
                    ),
                  ),
                  SizedBox(width: spacing.elementGap),
                  Expanded(
                    child: Text(
                      widget.goal.name.safe(),
                      style: textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.goal.targetDate != null)
                    Text(
                      safeDateFormat('MMM yyyy', ctxt.localeName)
                          .format(widget.goal.targetDate!),
                      style: textTheme.bodySmall
                          ?.copyWith(color: color.onSurfaceVariant),
                    ),
                ],
              ),

              SizedBox(height: spacing.sectionGap * 1.5),

              // ── 2. Hero Number (largest element, no label) ──
              CurrencyText(
                currencyCode: widget.goal.currencyCode,
                amount: GuestModeUtil.applyGuestMode(
                  widget.goal.currentAmount, isGuestMode,
                ),
                fixedLength: 0,
                compact: false,
                style: textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 44,
                  color: color.onSurface,
                  height: 1.1,
                ),
              ),

              SizedBox(height: spacing.elementGap),

              // ── 3. Completion Context (gap first, then %) ──
              if (isCompleted)
                Text(
                  ctxt.goal_completedSection,
                  style: textTheme.bodyLarge?.copyWith(
                    color: FinanceColors.statusGood,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Row(
                  children: [
                    CurrencyText(
                      currencyCode: widget.goal.currencyCode,
                      amount: GuestModeUtil.applyGuestMode(
                        remaining, isGuestMode,
                      ),
                      fixedLength: 0,
                      compact: true,
                      suffixText: ctxt.goal_suffixLeft,
                      style: textTheme.bodyLarge
                          ?.copyWith(color: color.onSurfaceVariant),
                    ),
                    Text(
                      '  ·  ${(progress * 100).toStringAsFixed(0)}%',
                      style: textTheme.bodyLarge
                          ?.copyWith(color: color.onSurfaceVariant),
                    ),
                  ],
                ),

              SizedBox(height: spacing.sectionGap * 1.5),

              // ── 4. Pace Assessment (user's avg dominant) ──
              if (!isCompleted && neededPerMonth > 0)
                _buildPaceAssessment(
                  neededPerMonth,
                  avgPerMonth,
                  isAheadOfPace,
                  goalColor,
                  color,
                  textTheme,
                  spacing,
                  ctxt,
                  isGuestMode,
                ),

              if (!isCompleted && neededPerMonth > 0)
                SizedBox(height: spacing.sectionGap),

              // ── 4b. Last Contribution Signal ──
              if (lastContrib != null)
                _buildLastContribution(
                  lastContrib,
                  goalColor,
                  color,
                  textTheme,
                  spacing,
                  ctxt,
                ),

              if (lastContrib != null)
                SizedBox(height: spacing.sectionGap),

              // ── 5. Progress Visualization (thin, subordinate) ──
              if (!isCompleted)
                ClipRRect(
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: goalColor.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(goalColor),
                    minHeight: 6,
                  ),
                ),

              if (!isCompleted) SizedBox(height: spacing.sectionGap * 1.5),

              // ── 6. Primary Action ──
              if (!isCompleted)
                FilledButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _showQuickDepositSheet(context, goalColor, spacing, ctxt);
                  },
                  icon: const Icon(LucideIcons.plus, size: 20),
                  label: Text(ctxt.goal_quickDeposit),
                  style: FilledButton.styleFrom(
                    backgroundColor: goalColor,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(spacing.radiusMedium),
                    ),
                  ),
                ),

              if (!isCompleted) SizedBox(height: spacing.sectionGap * 2),

              // ── 7. Forecast (visually demoted — prediction, not fact) ──
              if (health.predictedDate != null && !isCompleted) ...[
                Text(
                  ctxt.goal_forecastLabel,
                  style: textTheme.labelSmall?.copyWith(
                    color: color.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  safeDateFormat('MMMM yyyy', ctxt.localeName)
                      .format(health.predictedDate!),
                  style: textTheme.bodyMedium?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ctxt.goal_basedOnRecent,
                  style: textTheme.labelSmall?.copyWith(
                    color: color.onSurfaceVariant.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: spacing.sectionGap * 2),
              ],

              // ── 8. Metrics Grid (facts only) ──
              Container(
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
                    _metricRow(
                      ctxt.goal_suffixLeft,
                      remaining,
                      ctxt.goal_timeLeft,
                      daysLeft > 0 ? _formatDaysLeft(daysLeft, ctxt) : '—',
                      isGuestMode,
                      textTheme,
                      color,
                    ),
                    Divider(
                      height: spacing.elementGap * 2,
                      color: color.outlineVariant.withValues(alpha: 0.3),
                    ),
                    _metricRow(
                      ctxt.goal_suffixSaved,
                      widget.goal.currentAmount,
                      ctxt.goal_target,
                      null,
                      isGuestMode,
                      textTheme,
                      color,
                      rightAmount: widget.goal.targetAmount,
                    ),
                  ],
                ),
              ),

              SizedBox(height: spacing.sectionGap * 2),

              // ── 9. Milestones (compressed, expandable) ──
              if (!isCompleted) ...[
                _buildMilestonesSection(
                  goalColor, color, textTheme, spacing, ctxt,
                ),
                SizedBox(height: spacing.sectionGap * 2),
              ],

              // ── 10. Contribution History (3 entries, view all) ──
              if (sortedContribs.isNotEmpty) ...[
                Text(
                  ctxt.goal_recentActivity,
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: spacing.elementGap),
                Container(
                  decoration: BoxDecoration(
                    color: color.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    border: Border.all(
                      color: color.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ...sortedContribs.take(3).map(
                            (c) => _buildContributionTile(
                              c, goalColor, color, textTheme, spacing, ctxt,
                            ),
                          ),
                      if (sortedContribs.length > 3)
                        InkWell(
                          onTap: () => _showFullHistory(
                            context, sortedContribs, goalColor,
                            color, textTheme, spacing, ctxt,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(spacing.cardInner),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.chevronDown,
                                  size: 16,
                                  color: color.onSurfaceVariant,
                                ),
                                SizedBox(width: spacing.elementGapMin),
                                Text(
                                  ctxt.dashboard_viewAllLabel,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: color.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
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

  // ── Pace Assessment (comparison block with evidence) ──
  Widget _buildPaceAssessment(
    double needed,
    double current,
    bool isAhead,
    Color goalColor,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
    bool isGuestMode,
  ) {
    final paceColor = isAhead ? goalColor : FinanceColors.statusWarning;
    final diff = (current - needed).abs();
    final sign = isAhead ? '+' : '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Your pace (dominant)
        Text(
          ctxt.goal_currentAvgMonth,
          style: textTheme.labelSmall
              ?.copyWith(color: color.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        CurrencyText(
          currencyCode: widget.goal.currencyCode,
          amount: GuestModeUtil.applyGuestMode(current, isGuestMode),
          fixedLength: 0,
          compact: true,
          suffixText: '/mo',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: paceColor,
          ),
        ),
        SizedBox(height: spacing.elementGap),
        // Required (secondary)
        Text(
          ctxt.goal_neededPerMonth,
          style: textTheme.labelSmall
              ?.copyWith(color: color.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        CurrencyText(
          currencyCode: widget.goal.currencyCode,
          amount: GuestModeUtil.applyGuestMode(needed, isGuestMode),
          fixedLength: 0,
          compact: true,
          suffixText: '/mo',
          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: spacing.elementGap),
        // Evidence line (the difference)
        Row(
          children: [
            Text(
              sign,
              style: textTheme.bodySmall?.copyWith(
                color: paceColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            CurrencyText(
              currencyCode: widget.goal.currencyCode,
              amount: GuestModeUtil.applyGuestMode(diff, isGuestMode),
              fixedLength: 0,
              compact: true,
              suffixText: isAhead
                  ? '/mo ${ctxt.goal_aheadOfPace.toLowerCase()}'
                  : '/mo ${ctxt.goal_behindPace.toLowerCase()}',
              style: textTheme.bodySmall?.copyWith(
                color: paceColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Last Contribution Signal ──
  Widget _buildLastContribution(
    GoalContribution last,
    Color goalColor,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final diff = DateTime.now().difference(last.date);
    final timeLabel = diff.inDays == 0
        ? ctxt.common_today
        : diff.inDays == 1
            ? ctxt.common_yesterday
            : ctxt.goal_daysAgo(diff.inDays);

    return Row(
      children: [
        Icon(
          LucideIcons.circlePlus,
          size: 14,
          color: color.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        SizedBox(width: spacing.elementGapMin),
        CurrencyText(
          currencyCode: widget.goal.currencyCode,
          amount: last.amount,
          fixedLength: 0,
          compact: true,
          style: textTheme.bodySmall?.copyWith(
            color: color.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '  ·  $timeLabel',
          style: textTheme.bodySmall
              ?.copyWith(color: color.onSurfaceVariant.withValues(alpha: 0.7)),
        ),
      ],
    );
  }

  // ── Milestones (compressed with expand) ──
  Widget _buildMilestonesSection(
    Color goalColor,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final reached = _milestonesReached();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _milestonesExpanded = !_milestonesExpanded),
          child: Row(
            children: [
              Text(
                ctxt.goal_milestones,
                style: textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '$reached / 5',
                style: textTheme.labelSmall?.copyWith(
                  color: goalColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: spacing.elementGapMin),
              Icon(
                _milestonesExpanded
                    ? LucideIcons.chevronUp
                    : LucideIcons.chevronDown,
                size: 16,
                color: color.onSurfaceVariant,
              ),
            ],
          ),
        ),
        if (_milestonesExpanded) ...[
          SizedBox(height: spacing.elementGap),
          Container(
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
                  widget.goal.currentAmount > 0,
                  goalColor, color, textTheme, spacing,
                ),
                _buildMilestone(
                  '25%',
                  widget.goal.progressPercent >= 0.25,
                  goalColor, color, textTheme, spacing,
                ),
                _buildMilestone(
                  '50%',
                  widget.goal.progressPercent >= 0.50,
                  goalColor, color, textTheme, spacing,
                ),
                _buildMilestone(
                  '75%',
                  widget.goal.progressPercent >= 0.75,
                  goalColor, color, textTheme, spacing,
                ),
                _buildMilestone(
                  '100%',
                  widget.goal.progressPercent >= 1.0,
                  goalColor, color, textTheme, spacing,
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Metric Row ──
  Widget _metricRow(
    String leftLabel,
    double leftAmount,
    String rightLabel,
    String? rightText,
    bool isGuestMode,
    TextTheme textTheme,
    ColorScheme color, {
    double? rightAmount,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                leftLabel,
                style: textTheme.labelSmall
                    ?.copyWith(color: color.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              CurrencyText(
                currencyCode: widget.goal.currencyCode,
                amount: GuestModeUtil.applyGuestMode(leftAmount, isGuestMode),
                fixedLength: 0,
                compact: true,
                style:
                    textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rightLabel,
                style: textTheme.labelSmall
                    ?.copyWith(color: color.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              if (rightAmount != null)
                CurrencyText(
                  currencyCode: widget.goal.currencyCode,
                  amount:
                      GuestModeUtil.applyGuestMode(rightAmount, isGuestMode),
                  fixedLength: 0,
                  compact: true,
                  style: textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                )
              else
                Text(
                  rightText ?? '—',
                  style: textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Milestone ──
  Widget _buildMilestone(
    String title,
    bool achieved,
    Color goalColor,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing, {
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
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
                          size: 10,
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
          Padding(
            padding: EdgeInsets.only(
              bottom: isLast ? 0 : spacing.elementGap,
            ),
            child: Text(
              title,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: achieved ? FontWeight.w600 : FontWeight.w400,
                color: achieved ? color.onSurface : color.onSurfaceVariant,
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
        vertical: spacing.elementGap,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: goalColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.plus, size: 14, color: goalColor),
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
            style:
                textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // ── Full History Sheet ──
  void _showFullHistory(
    BuildContext context,
    List<GoalContribution> contributions,
    Color goalColor,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: EdgeInsets.all(spacing.sectionGap),
              child: Text(
                ctxt.goal_recentActivity,
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: EdgeInsets.symmetric(horizontal: spacing.cardHorizontal),
                itemCount: contributions.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  indent: 48,
                  color: color.outlineVariant.withValues(alpha: 0.3),
                ),
                itemBuilder: (_, i) => _buildContributionTile(
                  contributions[i], goalColor, color,
                  textTheme, spacing, ctxt,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick Deposit Sheet ──
  void _showQuickDepositSheet(
    BuildContext context,
    Color goalColor,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final textTheme = Theme.of(context).textTheme;
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
            Text(
              ctxt.goal_quickDeposit,
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                    SnackbarService.success(
                      Tone.current.goalContributionThisMonth(
                        formatCurrency(
                          amount,
                          code: widget.goal.currencyCode,
                          decimals: 0,
                        ),
                      ),
                    );
                    if (!wasComplete && isNowComplete) {
                      _confettiController.play();
                      SnackbarService.success(
                        Tone.current
                            .goalMilestone100(widget.goal.name.safe()),
                      );
                      if (context.mounted) {
                        final ctxt = AppLocalizations.of(context)!;
                        Future.delayed(
                          const Duration(milliseconds: 1500),
                          () {
                            if (!context.mounted) return;
                            showMilestoneShareSheet(
                              context,
                              MilestoneData(
                                emoji: '🎯',
                                title: ctxt.milestone_goalReachedTitle,
                                stat: widget.goal.name.safe(),
                                description: ctxt.milestone_goalReachedDesc(
                                  formatCurrency(
                                    widget.goal.targetAmount,
                                    code: widget.goal.currencyCode,
                                    decimals: 0,
                                  ),
                                ),
                                icon: LucideIcons.goal,
                                accent: const Color(0xFF4CAF50),
                              ),
                            );
                          },
                        );
                      }
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

  String _formatDaysLeft(int days, AppLocalizations ctxt) {
    if (days > 60) return ctxt.goal_monthsLeft((days / 30).round());
    return ctxt.goal_daysLeft(days);
  }
}

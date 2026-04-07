import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
      Future.delayed(const Duration(milliseconds: 500), () {
        _confettiController.play();
      });
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
      title: 'Delete Goal?',
    );
    if (confirmed == true && mounted) {
      await ref.read(goalServiceProvider).deleteGoal(widget.goal.id);
      if (mounted) {
        SnackbarService.success(BuddyMessages.goalDeleted);
        context.pop();
      }
    }
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
                    const Text('Edit Goal'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(LucideIcons.trash2, size: 18, color: color.error),
                    SizedBox(width: spacing.elementGap),
                    Text('Delete Goal', style: TextStyle(color: color.error)),
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
              // 🥇 Hero Card
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontal,
                  vertical: spacing.cardVertical,
                ),
                child: Container(
                  padding: EdgeInsets.all(spacing.cardInner),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        goalColor.withValues(alpha: 0.15),
                        goalColor.withValues(alpha: 0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(spacing.radiusLarge),
                    border: Border.all(
                      color: goalColor.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Icon + Name + Status
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(spacing.elementGap),
                            decoration: BoxDecoration(
                              color: goalColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(spacing.radiusMedium),
                            ),
                            child: Icon(
                              IconHelper.getIconData(widget.goal.iconName),
                              color: goalColor,
                              size: 28,
                            ),
                          ),
                          SizedBox(width: spacing.elementGap),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.goal.name,
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                          _buildHeaderStatusBadge(health, statusColor, textTheme, spacing),
                        ],
                      ),
                      SizedBox(height: spacing.sectionGap),

                      // Current / Target amounts
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Saved', style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant)),
                                SizedBox(height: spacing.elementGapMin),
                                CurrencyText(
                                  currencyCode: widget.goal.currencyCode,
                                  amount: GuestModeUtil.applyGuestMode(widget.goal.currentAmount, isGuestMode),
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: goalColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 36, color: color.outlineVariant.withValues(alpha: 0.4)),
                          SizedBox(width: spacing.sectionGap),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Target', style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant)),
                                SizedBox(height: spacing.elementGapMin),
                                CurrencyText(
                                  currencyCode: widget.goal.currencyCode,
                                  amount: widget.goal.targetAmount,
                                  fixedLength: 0,
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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
                          return Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(spacing.radiusSmall),
                                child: LinearProgressIndicator(
                                  value: value,
                                  minHeight: 10,
                                  backgroundColor: color.outline.withValues(alpha: 0.1),
                                  valueColor: AlwaysStoppedAnimation(goalColor),
                                ),
                              ),
                              SizedBox(height: spacing.elementGap),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${(value * 100).toStringAsFixed(1)}% complete',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: goalColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  CurrencyText(
                                    currencyCode: widget.goal.currencyCode,
                                    amount: remaining,
                                    fixedLength: 0,
                                    compact: true,
                                    suffixText: 'to go',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: color.onSurfaceVariant,
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
                ),
              ),

              // Quick Stats Cards
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontal,
                  vertical: spacing.cardVertical,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Remaining',
                        remaining,
                        LucideIcons.target,
                        color,
                        textTheme,
                        spacing,
                        isLeft: true,
                      ),
                    ),
                    SizedBox(width: spacing.elementGap),
                    Expanded(
                      child: _buildStatCard(
                        daysLeft > 0 ? 'Days Left' : 'No Deadline',
                        daysLeft > 0 ? daysLeft.toDouble() : -1,
                        LucideIcons.calendar,
                        color,
                        textTheme,
                        spacing,
                        isRight: true,
                      ),
                    ),
                  ],
                ),
              ),

              // Quick Deposit Button
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
                  label: const Text('Quick Deposit'),
                  style: FilledButton.styleFrom(
                    backgroundColor: goalColor,
                    minimumSize: const Size(double.infinity, 56),
                  ),
                ),
              ),

              // 🧠 Smart Insight Section
              _buildSmartInsight(goalColor, color, textTheme, spacing),

              // Target Date Card
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
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(spacing.elementGap),
                          decoration: BoxDecoration(
                            color: color.primaryContainer,
                            borderRadius: BorderRadius.circular(spacing.radiusMedium),
                          ),
                          child: Icon(LucideIcons.calendar, color: color.primary, size: 24),
                        ),
                        SizedBox(width: spacing.elementGap),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Target Date', style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant)),
                              SizedBox(height: spacing.elementGap * 0.5),
                              Text(
                                DateFormat('dd MMMM yyyy', ctxt.localeName).format(widget.goal.targetDate!),
                                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (daysLeft > 0 && suggestedMonthly > 0)
                                Text(
                                  'Save ${formatCurrency(suggestedMonthly.toDouble(), code: widget.goal.currencyCode, decimals: 0)}/month to reach on time',
                                  style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Milestones Header
              Padding(
                padding: EdgeInsets.fromLTRB(
                  spacing.sectionGap, spacing.elementGap,
                  spacing.sectionGap, spacing.elementGap,
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.award, size: 20, color: color.primary),
                    SizedBox(width: spacing.elementGap),
                    Text('Milestones', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              // Milestones List
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontal,
                  vertical: spacing.cardVertical,
                ),
                child: Container(
                  padding: EdgeInsets.all(spacing.cardInner),
                  decoration: BoxDecoration(
                    color: color.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(spacing.radiusLarge),
                    border: Border.all(
                      color: color.outlineVariant.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildMilestone('Started', widget.goal.currentAmount >= 0, goalColor, textTheme, color, spacing),
                      _buildMilestone('25% Complete', progress >= 0.25, goalColor, textTheme, color, spacing),
                      _buildMilestone('50% Complete', progress >= 0.50, goalColor, textTheme, color, spacing),
                      _buildMilestone('75% Complete', progress >= 0.75, goalColor, textTheme, color, spacing),
                      _buildMilestone('Goal Reached!', progress >= 1.0, goalColor, textTheme, color, spacing, isLast: true),
                    ],
                  ),
                ),
              ),

              // 📝 Contribution Timeline
              if (widget.goal.contributions.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    spacing.sectionGap, spacing.elementGap,
                    spacing.sectionGap, spacing.elementGap,
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.history, size: 20, color: color.primary),
                      SizedBox(width: spacing.elementGap),
                      Text('Recent Activity', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.cardHorizontal,
                    vertical: spacing.cardVertical,
                  ),
                  child: Column(
                    children: (widget.goal.contributions.toList()
                          ..sort((a, b) => b.date.compareTo(a.date)))
                        .take(10)
                        .map((c) => _buildContributionTile(c, goalColor, color, textTheme, spacing))
                        .toList(),
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
                Colors.green,
                Colors.pink,
                Colors.blue,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStatusBadge(
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
        color: statusColor.withValues(alpha: 0.15),
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

  Widget _buildStatCard(
    String label,
    double value,
    IconData icon,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing, {
    bool isLeft = false,
    bool isRight = false,
  }) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.horizontal(
          left: isLeft
              ? Radius.circular(
                  spacing.radiusMedium,
                )
              : Radius.zero,
          right: isRight
              ? Radius.circular(
                  spacing.radiusMedium,
                )
              : Radius.zero,
        ),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(spacing.elementGap * 0.75),
            decoration: BoxDecoration(
              color: color.primaryContainer,
              borderRadius: BorderRadius.circular(spacing.radiusSmall),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color.primary,
            ),
          ),
          SizedBox(height: spacing.elementGap),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
          SizedBox(height: spacing.elementGap),
          if (isLeft)
            CurrencyText(
              currencyCode: widget.goal.currencyCode,
              amount: value,
              fixedLength: 0,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          if (isRight)
            Text(
              value >= 0 ? value.toStringAsFixed(0) : '--',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMilestone(
    String label,
    bool achieved,
    Color goalColor,
    TextTheme textTheme,
    ColorScheme color,
    AppSpacing spacing, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : spacing.elementGap),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
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
                ? const Icon(LucideIcons.check, color: Colors.white, size: 16)
                : null,
          ),
          SizedBox(width: spacing.elementGap * 1.5),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: achieved ? FontWeight.bold : FontWeight.normal,
                color: achieved ? color.onSurface : color.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartInsight(
    Color goalColor,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
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
          borderRadius: BorderRadius.circular(spacing.radiusLarge),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.3),
            width: 1,
          ),
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
                  child: Icon(LucideIcons.sparkles, size: 18, color: statusColor),
                ),
                SizedBox(width: spacing.elementGap),
                Text(
                  'Smart Insight',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                style: textTheme.bodySmall?.copyWith(
                  color: color.onSurfaceVariant,
                ),
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
                    formatCurrency(monthContrib, code: widget.goal.currencyCode, decimals: 0),
                  ),
                  style: textTheme.labelMedium?.copyWith(
                    color: goalColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContributionTile(
    GoalContribution contribution,
    Color goalColor,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final now = DateTime.now();
    final diff = now.difference(contribution.date);
    String timeLabel;
    if (diff.inDays == 0) {
      timeLabel = 'Today';
    } else if (diff.inDays == 1) {
      timeLabel = 'Yesterday';
    } else if (diff.inDays < 7) {
      timeLabel = '${diff.inDays} days ago';
    } else {
      timeLabel = DateFormat('dd MMM').format(contribution.date);
    }

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.elementGap),
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
              amount: contribution.amount,
              fixedLength: 0,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            timeLabel,
            style: textTheme.bodySmall?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickDepositSheet(
    BuildContext context,
    Color goalColor,
    AppSpacing spacing,
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
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacing.elementGap),
                  decoration: BoxDecoration(
                    color: goalColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  ),
                  child: Icon(
                    LucideIcons.piggyBank,
                    color: goalColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: spacing.elementGap * 1.5),
                Text(
                  'Quick Deposit',
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
                labelText: 'Amount',
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
                  widget.goal.contributions.add(GoalContribution.create(amount));
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
              label: const Text('Add to Goal'),
            ),
          ],
        ),
      ),
    );
  }
}

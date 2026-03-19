import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/goal/data/goal_provider.dart';
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
      message:
          'This will permanently delete this goal. This action cannot be undone.',
    );
    if (confirmed == true && mounted) {
      await ref.read(goalServiceProvider).deleteGoal(widget.goal.id);
      if (mounted) {
        SnackbarService.success('Goal deleted successfully');
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

    final daysLeft =
        widget.goal.targetDate?.difference(DateTime.now()).inDays ?? 0;
    final monthsLeft = daysLeft > 0 ? daysLeft / 30 : 0;
    final suggestedMonthly = monthsLeft > 0 ? remaining / monthsLeft : 0;

    return Scaffold(
      backgroundColor: color.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Modern SliverAppBar with Gradient Header
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                elevation: 0,
                title: LayoutBuilder(
                  builder: (context, constraints) {
                    final expandRatio = constraints.maxHeight > 80 ? 1.0 : 0.0;
                    return Opacity(
                      opacity: 1 - expandRatio,
                      child: Text(
                        widget.goal.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
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
                            Icon(
                              LucideIcons.trash2,
                              size: 18,
                              color: color.error,
                            ),
                            SizedBox(width: spacing.elementGap),
                            Text(
                              'Delete Goal',
                              style: TextStyle(color: color.error),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                          goalColor.withValues(alpha: 0.2),
                          goalColor.withValues(alpha: 0.05),
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
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(
                                          spacing.elementGap,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              goalColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            spacing.radiusMedium,
                                          ),
                                        ),
                                        child: Icon(
                                          IconHelper.getIconData(
                                            widget.goal.iconName,
                                          ),
                                          color: goalColor,
                                          size: 32,
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
                                              style: textTheme.headlineSmall
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: color.onSurface,
                                              ),
                                            ),
                                            if (widget.goal.description != null)
                                              Text(
                                                widget.goal.description!,
                                                style: textTheme.bodyMedium
                                                    ?.copyWith(
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
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Current',
                                              style:
                                                  textTheme.bodySmall?.copyWith(
                                                color: color.onSurfaceVariant,
                                              ),
                                            ),
                                            SizedBox(
                                              height: spacing.elementGap,
                                            ),
                                            CurrencyText(
                                              amount:
                                                  GuestModeUtil.applyGuestMode(
                                                widget.goal.currentAmount,
                                                isGuestMode,
                                              ),
                                              style: textTheme.headlineMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: goalColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 40,
                                        color: color.outlineVariant
                                            .withValues(alpha: 0.5),
                                      ),
                                      SizedBox(width: spacing.sectionGap),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Target',
                                              style:
                                                  textTheme.bodySmall?.copyWith(
                                                color: color.onSurfaceVariant,
                                              ),
                                            ),
                                            SizedBox(
                                              height: spacing.elementGap,
                                            ),
                                            CurrencyText(
                                              amount: widget.goal.targetAmount,
                                              fixedLength: 0,
                                              style: textTheme.headlineMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: color.onSurface,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: spacing.elementGap),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      spacing.radiusSmall,
                                    ),
                                    child: TweenAnimationBuilder<double>(
                                      duration:
                                          const Duration(milliseconds: 1500),
                                      curve: Curves.easeOutCubic,
                                      tween: Tween(begin: 0.0, end: progress),
                                      builder: (context, value, child) {
                                        return LinearProgressIndicator(
                                          value: value,
                                          minHeight: 8,
                                          backgroundColor: color.outline
                                              .withValues(alpha: 0.1),
                                          valueColor:
                                              AlwaysStoppedAnimation(goalColor),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(height: spacing.elementGap),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${(progress * 100).toStringAsFixed(1)}% Complete',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: goalColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      CurrencyText(
                                        amount: remaining,
                                        fixedLength: 0,
                                        suffixText: 'remaining',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: color.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
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

              // Quick Stats Cards
              SliverToBoxAdapter(
                child: Padding(
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
              ),

              // Quick Deposit Button
              SliverToBoxAdapter(
                child: Padding(
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
              ),

              // Target Date Card
              if (widget.goal.targetDate != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: spacing.cardHorizontal,
                        vertical: spacing.cardVertical),
                    child: Container(
                      padding: EdgeInsets.all(spacing.cardInner),
                      decoration: BoxDecoration(
                        color: color.surfaceContainerLow,
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
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
                              borderRadius:
                                  BorderRadius.circular(spacing.radiusMedium),
                            ),
                            child: Icon(
                              LucideIcons.calendar,
                              color: color.primary,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: spacing.elementGap),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Target Date',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: color.onSurfaceVariant,
                                  ),
                                ),
                                SizedBox(height: spacing.elementGap * 0.5),
                                Text(
                                  DateFormat('dd MMMM yyyy', ctxt.localeName)
                                      .format(widget.goal.targetDate!),
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (daysLeft > 0 && suggestedMonthly > 0)
                                  Text(
                                    'Save ₹${suggestedMonthly.toStringAsFixed(0)}/month to reach on time',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: color.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Milestones Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    spacing.sectionGap,
                    spacing.elementGap,
                    spacing.sectionGap,
                    spacing.elementGap,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.award,
                        size: 20,
                        color: color.primary,
                      ),
                      SizedBox(width: spacing.elementGap),
                      Text(
                        'Milestones',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Milestones List
              SliverToBoxAdapter(
                child: Padding(
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
                        _buildMilestone(
                          'Started',
                          widget.goal.currentAmount >= 0,
                          goalColor,
                          textTheme,
                          color,
                          spacing,
                        ),
                        _buildMilestone(
                          '25% Complete',
                          progress >= 0.25,
                          goalColor,
                          textTheme,
                          color,
                          spacing,
                        ),
                        _buildMilestone(
                          '50% Complete',
                          progress >= 0.50,
                          goalColor,
                          textTheme,
                          color,
                          spacing,
                        ),
                        _buildMilestone(
                          '75% Complete',
                          progress >= 0.75,
                          goalColor,
                          textTheme,
                          color,
                          spacing,
                        ),
                        _buildMilestone(
                          'Goal Reached!',
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
              ),

              SliverToBoxAdapter(
                  child: SizedBox(height: spacing.sectionGap * 5)),
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
                prefixIcon: const Icon(LucideIcons.indianRupee),
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
                  final isNowComplete = widget.goal.progressPercent >= 1.0;

                  await ref.read(goalServiceProvider).updateGoal(widget.goal);
                  ref.invalidate(goalsProvider);

                  if (context.mounted) {
                    Navigator.pop(context);
                    setState(() {});

                    SnackbarService.success(
                      '₹${amount.toStringAsFixed(0)} added to ${widget.goal.name}',
                    );

                    if (!wasComplete && isNowComplete) {
                      _confettiController.play();
                      SnackbarService.success(
                          '🎉 Goal completed! Congratulations!');
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

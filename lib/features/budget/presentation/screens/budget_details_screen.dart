import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class BudgetDetailsScreen extends ConsumerWidget {
  final BudgetWithProgress data;

  const BudgetDetailsScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final isGuestMode = ref.watch(guestModeProvider);
    final b = data.budget;
    final spent = data.spent;
    final total = b.amount;
    final displaySpent = GuestModeUtil.applyGuestMode(spent, isGuestMode);
    final displayTotal = GuestModeUtil.applyGuestMode(total, isGuestMode);
    final remaining = displayTotal - displaySpent;
    final pct = displayTotal > 0 ? (displaySpent / displayTotal) : 0;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Calculate days and daily allowance
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = daysInMonth - now.day + 1;
    final dailyAllowance = daysLeft > 0 ? remaining / daysLeft : 0;
    final burnRate = displaySpent / now.day;
    final projectedSpend = burnRate * daysInMonth;
    final projectedOverage = projectedSpend - displayTotal;

    // Status color based on health
    final statusColor = pct >= 1.0
        ? color.error
        : pct >= 0.8
            ? color.tertiary
            : color.primary;

    // Sort categories: over 80% first
    final List<CategorySpending> sortedCategories =
        List.from(data.categorySpendings)
          ..sort((a, b) {
            final aPct = a.allocated > 0 ? a.spent / a.allocated : 0;
            final bPct = b.allocated > 0 ? b.spent / b.allocated : 0;
            if (aPct >= 0.8 && bPct < 0.8) return -1;
            if (aPct < 0.8 && bPct >= 0.8) return 1;
            return bPct.compareTo(aPct);
          });

    return Scaffold(
      backgroundColor: color.surface,
      body: CustomScrollView(
        slivers: [
          // Modern SliverAppBar
          _buildSliverAppBar(b.name, remaining, displayTotal, pct.toDouble(),
              statusColor, color, textTheme, context, spacing, ref),

          // Quick Stats Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontal,
                vertical: spacing.cardVertical,
              ),
              child: _buildQuickStats(
                displaySpent,
                dailyAllowance.toDouble(),
                daysLeft,
                statusColor,
                color,
                textTheme,
                spacing,
              ),
            ),
          ),

          // Burn Rate Alert
          if (pct >= 0.8 && projectedOverage > 0)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: spacing.cardHorizontal),
                child: _buildBurnRateAlert(
                  projectedOverage,
                  burnRate,
                  daysInMonth,
                  now.day,
                  color,
                  textTheme,
                  spacing,
                ),
              ),
            ),

          SliverToBoxAdapter(child: SizedBox(height: spacing.elementGap)),

          // Budget Health Indicator
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing.cardHorizontal),
              child: _buildHealthIndicator(
                pct.toDouble(),
                statusColor,
                color,
                textTheme,
                spacing,
              ),
            ),
          ),

          // Category Breakdown Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                spacing.sectionGap,
                spacing.sectionGap * 1.5,
                spacing.sectionGap,
                spacing.elementGap * 1.5,
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.chartPie, size: 20, color: color.primary),
                  SizedBox(width: spacing.elementGap),
                  Text(
                    'Category Breakdown',
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // Category List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final cat = sortedCategories[index];
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.cardHorizontal,
                    vertical: spacing.cardVertical,
                  ),
                  child: _buildCategoryCard(
                    cat,
                    isGuestMode,
                    color,
                    textTheme,
                    spacing,
                  ),
                );
              },
              childCount: sortedCategories.length,
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: spacing.sectionGap * 5)),
        ],
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () {
      //     HapticFeedback.mediumImpact();
      //     context.push(AppRoutes.addBudget, extra: {'budget': b});
      //   },
      //   icon: const Icon(LucideIcons.settings),
      //   label: const Text('Edit Budget'),
      // ),
    );
  }

  Widget _buildSliverAppBar(
    String budgetName,
    double remaining,
    double total,
    double pct,
    Color statusColor,
    ColorScheme color,
    TextTheme textTheme,
    BuildContext context,
    AppSpacing spacing,
    WidgetRef ref,
  ) {
    final now = DateTime.now();

    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      elevation: 0,
      backgroundColor: color.surface,
      title: Text(
        budgetName,
        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.pencil),
          tooltip: 'Edit Budget',
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push(AppRoutes.addBudget, extra: {'budget': data.budget});
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(LucideIcons.ellipsisVertical),
          onSelected: (value) async {
            if (value == 'delete') {
              HapticFeedback.mediumImpact();
              final confirmed = await DialogUtils.showDeleteConfirmation(
                context,
                title: 'Delete \'$budgetName\'',
                message: 'Are you sure you want to delete this budget?',
              );
              if (confirmed == true && context.mounted) {
                await _deleteBudget(context, ref);
              }
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(LucideIcons.trash2, size: 18, color: color.error),
                  const SizedBox(width: 12),
                  Text(
                    'Delete Budget',
                    style: TextStyle(color: color.error),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final expandRatio =
              (constraints.maxHeight - kToolbarHeight) / (320 - kToolbarHeight);
          final opacity = expandRatio.clamp(0.0, 1.0);

          return FlexibleSpaceBar(
            background: Opacity(
              opacity: opacity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      statusColor,
                      statusColor.withValues(alpha: 0.8),
                      statusColor.withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      spacing.sectionGap * 1.5,
                      56,
                      spacing.sectionGap * 1.5,
                      spacing.elementGap,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('MMMM yyyy').format(now),
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: spacing.elementGap),
                        CurrencyText(
                          amount: remaining > 0 ? remaining : 0,
                          compact: false,
                          fixedLength: 0,
                          style: textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        SizedBox(height: spacing.elementGap),
                        Text(
                          'Remaining to spent',
                          style: textTheme.titleSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: spacing.elementGap),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: spacing.cardHorizontal,
                            vertical: spacing.cardVertical,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(spacing.radiusMedium),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${(pct * 100).toStringAsFixed(0)}% spent',
                            style: textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: spacing.elementGap),
                        // Progress bar
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(spacing.radiusSmall),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: pct.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(spacing.radiusSmall),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickStats(
    double spent,
    double dailyAllowance,
    int daysLeft,
    Color statusColor,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(spacing.cardInner),
            decoration: BoxDecoration(
              color: color.primaryContainer,
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(spacing.radiusSmall),
              ),
              border: Border.all(
                color: color.primaryContainer.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(spacing.elementGap),
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      spacing.radiusSmall,
                    ),
                  ),
                  child: Icon(
                    LucideIcons.trendingUp,
                    color: color.primary,
                    size: 20,
                  ),
                ),
                SizedBox(height: spacing.elementGap),
                CurrencyText(
                  amount: spent,
                  fixedLength: 0,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: spacing.elementGap),
                Text(
                  'Total Spent',
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: spacing.elementGap),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(spacing.cardInner),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.horizontal(
                right: Radius.circular(spacing.radiusSmall),
              ),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(spacing.elementGap),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  ),
                  child:
                      Icon(LucideIcons.calendar, color: statusColor, size: 20),
                ),
                SizedBox(height: spacing.elementGap),
                CurrencyText(
                  amount: dailyAllowance > 0 ? dailyAllowance : 0,
                  fixedLength: 0,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                SizedBox(height: spacing.elementGap),
                Text(
                  'Per Day ($daysLeft left)',
                  style: textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBurnRateAlert(
    double overage,
    double burnRate,
    int daysInMonth,
    int currentDay,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final projectedDay =
        (currentDay * 1.0 / (burnRate * daysInMonth / 100)).round();

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.errorContainer,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(
          color: color.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(spacing.elementGap * 1.5),
            decoration: BoxDecoration(
              color: color.error,
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
            ),
            child:
                Icon(LucideIcons.triangleAlert, color: color.onError, size: 24),
          ),
          SizedBox(width: spacing.sectionGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overspending Alert',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color.onErrorContainer,
                  ),
                ),
                SizedBox(height: spacing.elementGap * 0.5),
                Text(
                  'At this pace, you\'ll exceed budget by ₹${overage.toStringAsFixed(0)}',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: color.onErrorContainer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthIndicator(
    double pct,
    Color statusColor,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    String healthStatus;
    String healthMessage;
    IconData healthIcon;

    if (pct >= 1.0) {
      healthStatus = 'Over Budget';
      healthMessage = 'You\'ve exceeded your budget limit';
      healthIcon = LucideIcons.circleAlert;
    } else if (pct >= 0.8) {
      healthStatus = 'Approaching Limit';
      healthMessage = 'Slow down spending to stay on track';
      healthIcon = LucideIcons.triangleAlert;
    } else if (pct >= 0.5) {
      healthStatus = 'On Track';
      healthMessage = 'You\'re managing your budget well';
      healthIcon = LucideIcons.circleCheck;
    } else {
      healthStatus = 'Excellent';
      healthMessage = 'Great job staying under budget!';
      healthIcon = LucideIcons.sparkles;
    }

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: 0.15),
            statusColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(spacing.radiusLarge),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(spacing.elementGap * 1.5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
            ),
            child: Icon(healthIcon, color: statusColor, size: 24),
          ),
          SizedBox(width: spacing.sectionGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  healthStatus,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                SizedBox(height: spacing.elementGap * 0.5),
                Text(
                  healthMessage,
                  style: textTheme.bodyMedium?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    CategorySpending cat,
    bool isGuestMode,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final catPct = cat.allocated > 0 ? cat.spent / cat.allocated : 0;
    final catColor = catPct >= 1.0
        ? color.error
        : catPct >= 0.8
            ? color.tertiary
            : color.tertiary;
    final isOverBudget = catPct >= 0.8;
    final catRemaining = cat.allocated - cat.spent;

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(
          color: isOverBudget
              ? catColor.withValues(alpha: 0.5)
              : color.outlineVariant.withValues(alpha: 0.5),
          width: isOverBudget ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(spacing.radiusSmall),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                ),
                child: Icon(
                  IconHelper.getIconData(cat.category.iconName),
                  color: catColor,
                  size: 20,
                ),
              ),
              SizedBox(width: spacing.elementGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.category.name,
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: spacing.elementGap * 0.25),
                    Text(
                      '₹${GuestModeUtil.applyGuestMode(cat.spent, isGuestMode).toStringAsFixed(0)} of ₹${GuestModeUtil.applyGuestMode(cat.allocated, isGuestMode).toStringAsFixed(0)}',
                      style: textTheme.bodySmall
                          ?.copyWith(color: color.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              SizedBox(width: spacing.elementGap),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontal,
                  vertical: spacing.cardVertical,
                ),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                ),
                child: Text(
                  '${(catPct * 100).toStringAsFixed(0)}%',
                  style: textTheme.labelLarge?.copyWith(
                    color: catColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.elementGap),
          ClipRRect(
            borderRadius: BorderRadius.circular(spacing.radiusSmall),
            child: LinearProgressIndicator(
              value: catPct.toDouble().clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: color.outline.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(catColor),
            ),
          ),
          SizedBox(height: spacing.elementGap),
          Row(
            children: [
              if (catRemaining > 0) ...[
                Row(
                  children: [
                    Icon(LucideIcons.trendingDown, size: 14, color: catColor),
                    SizedBox(width: spacing.elementGap),
                    Text(
                      '₹${GuestModeUtil.applyGuestMode(catRemaining, isGuestMode).toStringAsFixed(0)} remaining',
                      style: textTheme.bodySmall?.copyWith(
                        color: catColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              const Spacer(),
              if (isOverBudget)
                Padding(
                  padding: EdgeInsets.zero,
                  child: Row(
                    children: [
                      Icon(
                        catPct >= 1.0
                            ? LucideIcons.circleAlert
                            : LucideIcons.triangleAlert,
                        size: 14,
                        color: catColor,
                      ),
                      SizedBox(width: spacing.elementGap),
                      Text(
                        catPct >= 1.0 ? 'Over budget!' : 'Approaching limit',
                        style: textTheme.labelSmall?.copyWith(
                          color: catColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBudget(BuildContext context, WidgetRef ref) async {
    try {
      final budgetService = ref.read(budgetServiceProvider);
      await budgetService.deleteBudget(data.budget.id);
      // Show success message
      SnackbarService.success(
        'Budget "${data.budget.name}" deleted',
      );
      if (context.mounted) {
        // Navigate back
        context.pop();
      }
    } catch (e) {
      SnackbarService.success(
        'Budget "${data.budget.name}" deleted',
      );
      if (context.mounted) {
        SnackbarService.error(
          'Failed to delete budget',
        );
      }
    }
  }
}

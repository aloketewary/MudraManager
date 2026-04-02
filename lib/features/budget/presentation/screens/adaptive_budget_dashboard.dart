import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/refresh_helper.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class AdaptiveBudgetDashboard extends ConsumerStatefulWidget {
  const AdaptiveBudgetDashboard({super.key});

  @override
  ConsumerState<AdaptiveBudgetDashboard> createState() =>
      _AdaptiveBudgetDashboardState();
}

class _AdaptiveBudgetDashboardState
    extends ConsumerState<AdaptiveBudgetDashboard> {
  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final budgetsAsync = ref.watch(budgetsWithProgressProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: color.surface,
      body: budgetsAsync.when(
        data: (budgets) {
          if (budgets.isEmpty) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Budget'),
                actions: [
                  IconButton(
                    icon: const Icon(LucideIcons.plus),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      context.push(AppRoutes.addBudget);
                    },
                  ),
                ],
              ),
              body: NoDataFound(
                message: BuddyMessages.noBudgets,
                iconData: Icons.pie_chart_outline,
              ),
            );
          }

          final totalBudget =
              budgets.fold(0.0, (sum, b) => sum + b.budget.amount);
          final totalSpent = budgets.fold(0.0, (sum, b) => sum + b.spent);
          final remaining = totalBudget - totalSpent;
          final daysInMonth =
              DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
          final daysLeft = daysInMonth - DateTime.now().day + 1;
          final safeToSpendDaily = daysLeft > 0 ? remaining / daysLeft : 0;
          final burnRate = totalSpent / DateTime.now().day;
          final projectedSpend = burnRate * daysInMonth;

          // Categorize budgets
          final fixed = budgets.where((b) => _isFixed(b.budget.name)).toList();
          final variable =
              budgets.where((b) => _isVariable(b.budget.name)).toList();
          final goals = budgets.where((b) => _isGoal(b.budget.name)).toList();
          final other = budgets
              .where(
                (b) =>
                    !_isFixed(b.budget.name) &&
                    !_isVariable(b.budget.name) &&
                    !_isGoal(b.budget.name),
              )
              .toList();

          return RefreshIndicator(
            onRefresh: () => RefreshHelper.withMinDuration(() async {
              ref.invalidate(budgetsWithProgressProvider);
            }),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Modern SliverAppBar
                _buildSliverAppBar(
                  remaining,
                  totalBudget,
                  color,
                  textTheme,
                  context,
                  spacing,
                ),

                // Quick Stats Cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.cardHorizontal,
                      vertical: spacing.cardVertical,
                    ),
                    child: _buildQuickStats(
                      totalSpent,
                      safeToSpendDaily.toDouble(),
                      daysLeft,
                      color,
                      textTheme,
                      spacing,
                    ),
                  ),
                ),

                // Burn Rate Alert
                if (projectedSpend > totalBudget)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing.cardHorizontal,
                      ),
                      child: _buildBurnRateAlert(
                        projectedSpend,
                        totalBudget,
                        color,
                        textTheme,
                        spacing,
                      ),
                    ),
                  ),

                SliverToBoxAdapter(child: SizedBox(height: spacing.elementGap)),

                // Budget Tiers
                if (fixed.isNotEmpty) ...[
                  _buildSectionHeader(
                    'Fixed (Essential)',
                    LucideIcons.shield,
                    color.primary,
                    textTheme,
                    spacing,
                  ),
                  _buildBudgetList(
                    fixed,
                    color,
                    textTheme,
                    spacing,
                  ),
                ],

                if (variable.isNotEmpty) ...[
                  _buildSectionHeader(
                    'Variable (Discretionary)',
                    LucideIcons.trendingUp,
                    Colors.orange,
                    textTheme,
                    spacing,
                  ),
                  _buildBudgetList(
                    variable,
                    color,
                    textTheme,
                    spacing,
                  ),
                ],

                if (goals.isNotEmpty) ...[
                  _buildSectionHeader(
                    'Goals (Savings)',
                    LucideIcons.goal,
                    Colors.green,
                    textTheme,
                    spacing,
                  ),
                  _buildBudgetList(
                    goals,
                    color,
                    textTheme,
                    spacing,
                  ),
                ],

                if (other.isNotEmpty) ...[
                  _buildSectionHeader(
                    'Other',
                    LucideIcons.octagon,
                    color.primary,
                    textTheme,
                    spacing,
                  ),
                  _buildBudgetList(
                    other,
                    color,
                    textTheme,
                    spacing,
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(BuddyMessages.genericError)),
      ),
    );
  }

  Widget _buildSliverAppBar(
    double remaining,
    double total,
    ColorScheme color,
    TextTheme textTheme,
    BuildContext context,
    AppSpacing spacing,
  ) {
    final percentage = total > 0 ? (remaining / total).clamp(0.0, 1.0) : 0.0;
    final gaugeColor = percentage > 0.3
        ? color.tertiary
        : percentage > 0.1
            ? Colors.orange
            : color.error;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      elevation: 0,
      backgroundColor: color.surface,
      title: Text(
        'Budget Command Center',
        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.push(AppRoutes.addBudget);
          },
          icon: const Icon(LucideIcons.plus),
        ),
        SizedBox(
          width: spacing.cardHorizontal,
        ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final expandRatio =
              (constraints.maxHeight - kToolbarHeight) / (280 - kToolbarHeight);
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
                      color.primaryContainer,
                      color.primaryContainer.withValues(alpha: 0.8),
                      color.tertiaryContainer.withValues(alpha: 0.6),
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
                        CurrencyText(
                          amount: remaining,
                          fixedLength: 0,
                          compact: false,
                          showSign: true,
                          style: textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: color.onPrimaryContainer,
                            letterSpacing: -1,
                          ),
                        ),
                        SizedBox(height: spacing.elementGap * 1.5),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: spacing.sectionGap,
                            vertical: spacing.elementGap,
                          ),
                          decoration: BoxDecoration(
                            color: color.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: color.primary.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${(percentage * 100).toStringAsFixed(0)}% of budget left',
                            style: textTheme.labelLarge?.copyWith(
                              color: color.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: spacing.sectionGap),
                        // Progress bar
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: gaugeColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 1 - percentage,
                            child: Container(
                              decoration: BoxDecoration(
                                color: color.onPrimaryContainer,
                                borderRadius: BorderRadius.circular(4),
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
    double dailySafe,
    int daysLeft,
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
                  left: Radius.circular(spacing.radiusMedium)),
              border: Border.all(
                color: color.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(spacing.elementGap),
                  decoration: BoxDecoration(
                    color: color.onPrimaryContainer.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(spacing.radiusSmall + 2),
                  ),
                  child: Icon(
                    LucideIcons.trendingUp,
                    color: color.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                SizedBox(height: spacing.elementGap * 1.5),
                CurrencyText(
                  amount: spent,
                  fixedLength: 0,
                  compact: true,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: spacing.elementGap * 0.5),
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
              color: color.tertiaryContainer,
              borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(spacing.radiusMedium)),
              border: Border.all(
                color: color.tertiary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(spacing.elementGap),
                  decoration: BoxDecoration(
                    color: color.onTertiaryContainer.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(spacing.radiusSmall + 2),
                  ),
                  child: Icon(
                    LucideIcons.calendar,
                    color: color.onTertiaryContainer,
                    size: 20,
                  ),
                ),
                SizedBox(height: spacing.elementGap * 1.5),
                CurrencyText(
                  amount: dailySafe,
                  fixedLength: 0,
                  compact: true,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color.onTertiaryContainer,
                  ),
                ),
                SizedBox(height: spacing.elementGap * 0.5),
                Text(
                  'Safe Per Day',
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onTertiaryContainer,
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
    double projected,
    double total,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final overage = projected - total;
    final day = DateTime.now().day;
    final daysInMonth =
        DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
    final projectedDay = (day * total / projected).round();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
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
                  'Burn Rate Alert',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color.onErrorContainer,
                  ),
                ),
                SizedBox(height: spacing.elementGap * 0.5),
                Text(
                  'At this pace, you\'ll exceed budget by day $projectedDay',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: color.onErrorContainer),
                ),
                SizedBox(height: spacing.elementGap),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.elementGap * 1.5,
                    vertical: spacing.elementGap * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: color.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  ),
                  child: Text(
                    '₹${overage.toStringAsFixed(0)} over budget',
                    style: textTheme.labelMedium?.copyWith(
                      color: color.error,
                      fontWeight: FontWeight.bold,
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

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    Color iconColor,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          spacing.sectionGap,
          spacing.sectionGap * 1.5,
          spacing.sectionGap,
          spacing.elementGap * 1.5,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            SizedBox(width: spacing.elementGap),
            Text(
              title,
              style:
                  textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetList(
    List<dynamic> budgets,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.cardHorizontal,
            vertical: spacing.cardVertical,
          ),
          child: _buildBudgetCard(budgets[index], color, textTheme, spacing),
        ),
        childCount: budgets.length,
      ),
    );
  }

  Widget _buildBudgetCard(
    dynamic budgetWithProgress,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final spent = budgetWithProgress.spent;
    final budget = budgetWithProgress.budget.amount;
    final percentage =
        budget > 0 ? (spent / budget * 100).clamp(0.0, 100.0) : 0.0;
    final remaining = budget - spent;

    Color progressColor = color.tertiary;
    Color bgColor = color.tertiaryContainer;
    if (percentage >= 90) {
      progressColor = color.error;
      bgColor = color.errorContainer;
    } else if (percentage >= 80) {
      progressColor = Colors.orange;
      bgColor = Colors.orange.withValues(alpha: 0.2);
    }

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
        borderRadius: BorderRadius.circular(spacing.radiusLarge),
        onTap: () {
          HapticFeedback.lightImpact();
          context.push(AppRoutes.budgetDetails, extra: budgetWithProgress);
        },
        child: Padding(
          padding: EdgeInsets.all(spacing.cardInner),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(spacing.radiusSmall + 2),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    ),
                    child: Icon(
                      LucideIcons.chartPie,
                      color: progressColor,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: spacing.elementGap * 1.5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budgetWithProgress.budget.name,
                          style: textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: spacing.elementGap * 0.25),
                        Text(
                          '₹${spent.toStringAsFixed(0)} of ₹${budget.toStringAsFixed(0)}',
                          style: textTheme.bodySmall
                              ?.copyWith(color: color.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.cardHorizontal,
                      vertical: spacing.cardVertical,
                    ),
                    decoration: BoxDecoration(
                      color: progressColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: textTheme.labelLarge?.copyWith(
                        color: progressColor,
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
                  value: (percentage / 100).clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: color.outline.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(progressColor),
                ),
              ),
              SizedBox(height: spacing.elementGap),
              Row(
                children: [
                  if (remaining > 0) ...[
                    Row(
                      children: [
                        Icon(
                          LucideIcons.trendingDown,
                          size: 14,
                          color: color.tertiary,
                        ),
                        SizedBox(width: spacing.elementGap),
                        Text(
                          '₹${remaining.toStringAsFixed(0)} remaining',
                          style: textTheme.bodySmall?.copyWith(
                            color: color.tertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Spacer(),
                  if (percentage >= 80)
                    Padding(
                      padding: EdgeInsets.zero,
                      child: Row(
                        children: [
                          Icon(
                            percentage >= 90
                                ? LucideIcons.circleAlert
                                : LucideIcons.triangleAlert,
                            size: 14,
                            color: progressColor,
                          ),
                          SizedBox(width: spacing.elementGap),
                          Text(
                            percentage >= 90
                                ? 'Budget exceeded!'
                                : 'Approaching limit',
                            style: textTheme.labelSmall?.copyWith(
                              color: progressColor,
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
        ),
      ),
    );
  }

  bool _isFixed(String budgetName) {
    final fixed = [
      'rent',
      'utilities',
      'subscription',
      'insurance',
      'loan',
      'emi',
      'fixed',
      'essential',
    ];
    return fixed.any((f) => budgetName.toLowerCase().contains(f));
  }

  bool _isVariable(String budgetName) {
    final variable = [
      'groceries',
      'food',
      'dining',
      'entertainment',
      'shopping',
      'transport',
      'variable',
      'discretionary',
    ];
    return variable.any((v) => budgetName.toLowerCase().contains(v));
  }

  bool _isGoal(String budgetName) {
    final goals = ['savings', 'investment', 'travel', 'emergency', 'goal'];
    return goals.any((g) => budgetName.toLowerCase().contains(g));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';

class MonthlyComparisonScreen extends ConsumerStatefulWidget {
  const MonthlyComparisonScreen({super.key});

  @override
  ConsumerState<MonthlyComparisonScreen> createState() => _MonthlyComparisonScreenState();
}

class _MonthlyComparisonScreenState extends ConsumerState<MonthlyComparisonScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isar = ref.watch(isarServiceProvider);
    final isGuestMode = ref.watch(guestModeProvider);
    final l10n = AppLocalizations.of(context)!;

    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final currentMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Comparison'),
      ),
      body: FutureBuilder<Map<String, double>>(
        future: _getComparisonData(
          isar,
          currentMonthStart,
          currentMonthEnd,
          lastMonthStart,
          lastMonthEnd,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildComparisonCardSkeleton(context),
                const SizedBox(height: 12),
                _buildComparisonCardSkeleton(context),
                const SizedBox(height: 12),
                _buildComparisonCardSkeleton(context),
              ],
            );
          }

          final data = snapshot.data!;
          final rawCurrentIncome = data['currentIncome']!;
          final rawCurrentExpense = data['currentExpense']!;
          final rawLastIncome = data['lastIncome']!;
          final rawLastExpense = data['lastExpense']!;
          final currentIncome = GuestModeUtil.applyGuestMode(rawCurrentIncome, isGuestMode);
          final currentExpense = GuestModeUtil.applyGuestMode(rawCurrentExpense, isGuestMode);
          final lastIncome = GuestModeUtil.applyGuestMode(rawLastIncome, isGuestMode);
          final lastExpense = GuestModeUtil.applyGuestMode(rawLastExpense, isGuestMode);

          final incomeChange = lastIncome > 0
              ? ((currentIncome - lastIncome) / lastIncome * 100)
              : 0.0;
          final expenseChange = lastExpense > 0
              ? ((currentExpense - lastExpense) / lastExpense * 100)
              : 0.0;
          final currentBalance = currentIncome - currentExpense;
          final lastBalance = lastIncome - lastExpense;
          final balanceChange = lastBalance != 0
              ? ((currentBalance - lastBalance) / lastBalance.abs() * 100)
              : 0.0;
          final variance = currentExpense - lastExpense;
          final variancePercent = lastExpense > 0 ? (variance / lastExpense * 100) : 0.0;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeroDelta(variance, variancePercent, colorScheme, textTheme),
              ),
              SliverToBoxAdapter(
                child: _buildSpendingVelocity(colorScheme, textTheme),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Overview',
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _ComparisonCard(
                      title: 'Income',
                      icon: Icons.trending_up,
                      color: colorScheme.primary,
                      currentAmount: currentIncome,
                      lastAmount: lastIncome,
                      percentageChange: incomeChange,
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                      l10n: l10n,
                    ),
                    const SizedBox(height: 12),
                    _ComparisonCard(
                      title: 'Expense',
                      icon: Icons.trending_down,
                      color: colorScheme.error,
                      currentAmount: currentExpense,
                      lastAmount: lastExpense,
                      percentageChange: expenseChange,
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                      l10n: l10n,
                    ),
                    const SizedBox(height: 12),
                    _ComparisonCard(
                      title: 'Balance',
                      icon: Icons.account_balance_wallet,
                      color: colorScheme.tertiary,
                      currentAmount: currentBalance,
                      lastAmount: lastBalance,
                      percentageChange: balanceChange,
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                      l10n: l10n,
                    ),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildInsightFooter(colorScheme, textTheme, variance < 0),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  Future<Map<String, double>> _getComparisonData(
    IsarService isar,
    DateTime currentStart,
    DateTime currentEnd,
    DateTime lastStart,
    DateTime lastEnd,
  ) async {
    final db = await isar.getInstance();

    final currentTxns = await db.transactions
        .where()
        .dateBetween(currentStart, currentEnd)
        .findAll();

    final lastTxns = await db.transactions
        .where()
        .dateBetween(lastStart, lastEnd)
        .findAll();

    double currentIncome = 0, currentExpense = 0;
    double lastIncome = 0, lastExpense = 0;

    for (var txn in currentTxns) {
      if (!txn.isExpense && !txn.isTransfer) {
        currentIncome += txn.amount;
      } else if (txn.isExpense && !txn.isTransfer) {
        currentExpense += txn.amount;
      }
    }

    for (var txn in lastTxns) {
      if (!txn.isExpense && !txn.isTransfer) {
        lastIncome += txn.amount;
      } else if (txn.isExpense && !txn.isTransfer) {
        lastExpense += txn.amount;
      }
    }

    return {
      'currentIncome': currentIncome,
      'currentExpense': currentExpense,
      'lastIncome': lastIncome,
      'lastExpense': lastExpense,
    };
  }

  Widget _buildHeroDelta(double variance, double variancePercent, ColorScheme color, TextTheme textTheme) {
    final isPositive = variance < 0;
    final deltaColor = isPositive ? const Color(0xFFA8E6CF) : const Color(0xFFFFAB91);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: deltaColor.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPositive ? LucideIcons.trendingDown : LucideIcons.trendingUp,
              color: deltaColor,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${isPositive ? '' : '+'}₹${variance.abs().toStringAsFixed(0)}',
            style: textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: deltaColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'vs last month',
            style: textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: deltaColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? LucideIcons.arrowDown : LucideIcons.arrowUp,
                  color: deltaColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${variancePercent.abs().toStringAsFixed(1)}% ${isPositive ? 'decrease' : 'increase'}',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: deltaColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingVelocity(ColorScheme color, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.activity, color: color.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Spending Velocity',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 0),
                      FlSpot(5, 12),
                      FlSpot(10, 20),
                      FlSpot(15, 28),
                      FlSpot(20, 35),
                      FlSpot(25, 42),
                      FlSpot(30, 48),
                    ],
                    isCurved: true,
                    color: color.tertiary.withValues(alpha: 0.5),
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 0),
                      FlSpot(5, 10),
                      FlSpot(10, 18),
                      FlSpot(15, 24),
                      FlSpot(20, 30),
                      FlSpot(25, 38),
                      FlSpot(30, 45),
                    ],
                    isCurved: true,
                    color: color.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('This month', color.primary, textTheme),
              const SizedBox(width: 20),
              _buildLegendItem('Last month', color.tertiary.withValues(alpha: 0.5), textTheme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, TextTheme textTheme) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: textTheme.bodySmall),
      ],
    );
  }

  Widget _buildInsightFooter(ColorScheme color, TextTheme textTheme, bool isPositive) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.primaryContainer, color.tertiaryContainer],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.sparkles, color: color.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isPositive
                  ? 'Great job! You\'ve been more mindful with your spending this month. Keep it up!'
                  : 'Your spending increased this month. Review your expenses to identify areas for improvement.',
              style: textTheme.bodyMedium?.copyWith(
                color: color.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildComparisonCardSkeleton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonLoader(
                  width: 52,
                  height: 52,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(width: 12),
                const SkeletonLoader(
                  width: 100,
                  height: 24,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(width: 100, height: 14),
                    SizedBox(height: 8),
                    SkeletonLoader(width: 120, height: 24),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SkeletonLoader(width: 100, height: 14),
                    SizedBox(height: 8),
                    SkeletonLoader(width: 100, height: 18),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SkeletonLoader(
              width: 150,
              height: 32,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final double currentAmount;
  final double lastAmount;
  final double percentageChange;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final AppLocalizations l10n;

  const _ComparisonCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.currentAmount,
    required this.lastAmount,
    required this.percentageChange,
    required this.colorScheme,
    required this.textTheme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = percentageChange >= 0;
    final color = Theme.of(context).colorScheme;
    final changeColor = title == 'Expense'
        ? (isPositive ? const Color(0xFFFFAB91) : const Color(0xFFA8E6CF))
        : (isPositive ? const Color(0xFFA8E6CF) : const Color(0xFFFFAB91));

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color.primary, size: 28),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Month',
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.formatCurrencyWithSign(0, currentAmount),
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Last Month',
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.formatCurrencyWithSign(0, lastAmount),
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: changeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    color: changeColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${percentageChange.abs().toStringAsFixed(1)}%',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'vs last month',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

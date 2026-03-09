import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';

class AdaptiveBudgetDashboard extends ConsumerStatefulWidget {
  const AdaptiveBudgetDashboard({super.key});

  @override
  ConsumerState<AdaptiveBudgetDashboard> createState() => _AdaptiveBudgetDashboardState();
}

class _AdaptiveBudgetDashboardState extends ConsumerState<AdaptiveBudgetDashboard> {
  @override
  Widget build(BuildContext context) {
    final budgetsAsync = ref.watch(budgetsWithProgressProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        title: const Text('Budget Command Center'),
        elevation: 0,
      ),
      body: budgetsAsync.when(
        data: (budgets) {
          if (budgets.isEmpty) {
            return const NoDataFound(
              message: 'No budgets yet',
              iconData: Icons.pie_chart_outline,
            );
          }

          final totalBudget = budgets.fold(0.0, (sum, b) => sum + b.budget.amount);
          final totalSpent = budgets.fold(0.0, (sum, b) => sum + b.spent);
          final remaining = totalBudget - totalSpent;
          final daysInMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
          final daysLeft = daysInMonth - DateTime.now().day + 1;
          final safeToSpendDaily = daysLeft > 0 ? remaining / daysLeft : 0;
          final burnRate = totalSpent / DateTime.now().day;
          final projectedSpend = burnRate * daysInMonth;

          // Categorize budgets
          final fixed = budgets.where((b) => _isFixed(b.budget.name)).toList();
          final variable = budgets.where((b) => _isVariable(b.budget.name)).toList();
          final goals = budgets.where((b) => _isGoal(b.budget.name)).toList();
          final other = budgets.where((b) => !_isFixed(b.budget.name) && !_isVariable(b.budget.name) && !_isGoal(b.budget.name)).toList();

          return CustomScrollView(
            slivers: [
              // Hero: Left-to-Spend Gauge
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildHeroGauge(remaining, totalBudget, safeToSpendDaily.toDouble(), color, textTheme),
                ),
              ),

              // Burn Rate Alert
              if (projectedSpend > totalBudget)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildBurnRateAlert(projectedSpend, totalBudget, color, textTheme),
                  ),
                ),

              // Budget Tiers
              if (fixed.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Row(
                      children: [
                        Icon(LucideIcons.shield, size: 20, color: color.primary),
                        const SizedBox(width: 8),
                        Text('Fixed (Essential)', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: _buildBudgetCard(fixed[index], color, textTheme),
                    ),
                    childCount: fixed.length,
                  ),
                ),
              ],

              if (variable.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Row(
                      children: [
                        Icon(LucideIcons.trendingUp, size: 20, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text('Variable (Discretionary)', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: _buildBudgetCard(variable[index], color, textTheme),
                    ),
                    childCount: variable.length,
                  ),
                ),
              ],

              if (goals.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Row(
                      children: [
                        Icon(LucideIcons.target, size: 20, color: Colors.green),
                        const SizedBox(width: 8),
                        Text('Goals (Savings)', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: _buildBudgetCard(goals[index], color, textTheme),
                    ),
                    childCount: goals.length,
                  ),
                ),
              ],

              if (other.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Row(
                      children: [
                        Icon(LucideIcons.folder, size: 20, color: color.primary),
                        const SizedBox(width: 8),
                        Text('Other', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: _buildBudgetCard(other[index], color, textTheme),
                    ),
                    childCount: other.length,
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading budgets')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.push('/add-budget');
        },
        icon: const Icon(LucideIcons.plus),
        label: const Text('Add Budget'),
      ),
    );
  }

  Widget _buildHeroGauge(double remaining, double total, double dailySafe, ColorScheme color, TextTheme textTheme) {
    final percentage = total > 0 ? (remaining / total).clamp(0.0, 1.0) : 0.0;
    final spent = total - remaining;
    final gaugeColor = percentage > 0.3 ? color.tertiary : percentage > 0.1 ? color.error : color.error;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.primaryContainer,
            color.secondaryContainer.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(
                painter: _SparklinePainter(
                  dataPoints: _generateSparklineData(spent, total),
                  sparkColor: gaugeColor,
                  backgroundColor: color.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '₹${remaining.toStringAsFixed(0)}',
                        style: textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color.onPrimaryContainer,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: gaugeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${(percentage * 100).toStringAsFixed(0)}% remaining',
                          style: textTheme.labelLarge?.copyWith(
                            color: gaugeColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: color.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(LucideIcons.trendingUp, size: 24, color: color.primary),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '₹${spent.toStringAsFixed(0)}',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Spent',
                          style: textTheme.bodyMedium?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: color.tertiaryContainer.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.onTertiaryContainer.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(LucideIcons.calendar, size: 24, color: color.onTertiaryContainer),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '₹${dailySafe.toStringAsFixed(0)}',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color.onTertiaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Per Day',
                          style: textTheme.bodyMedium?.copyWith(
                            color: color.onTertiaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBurnRateAlert(double projected, double total, ColorScheme color, TextTheme textTheme) {
    final overage = projected - total;
    final day = DateTime.now().day;
    final daysInMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
    final projectedDay = (day * total / projected).round();

    return Card(
      elevation: 0,
      color: color.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(LucideIcons.triangleAlert, color: color.onError, size: 24),
            ),
            const SizedBox(width: 16),
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
                  const SizedBox(height: 4),
                  Text(
                    'At this pace, you\'ll exceed budget by day $projectedDay',
                    style: textTheme.bodyMedium?.copyWith(color: color.onErrorContainer),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.error.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
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
      ),
    );
  }

  Widget _buildBudgetCard(dynamic budgetWithProgress, ColorScheme color, TextTheme textTheme) {
    final spent = budgetWithProgress.spent;
    final budget = budgetWithProgress.budget.amount;
    final percentage = budget > 0 ? (spent / budget * 100).clamp(0.0, 100.0) : 0.0;
    final remaining = budget - spent;

    Color progressColor = color.tertiary;
    Color bgColor = color.tertiaryContainer;
    if (percentage >= 90) {
      progressColor = color.error;
      bgColor = color.errorContainer;
    } else if (percentage >= 80) {
      progressColor = color.error;
      bgColor = color.errorContainer.withValues(alpha: 0.5);
    }

    return Card(
      elevation: 0,
      color: color.surfaceContainerHigh,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/budget-details', extra: budgetWithProgress),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.chartPie,
                      color: progressColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budgetWithProgress.budget.name,
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₹${spent.toStringAsFixed(0)} of ₹${budget.toStringAsFixed(0)}',
                          style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: progressColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  if (percentage > 0)
                    Expanded(
                      flex: percentage.toInt().clamp(1, 100),
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: progressColor,
                          borderRadius: BorderRadius.horizontal(
                            left: const Radius.circular(8),
                            right: percentage >= 100 ? const Radius.circular(8) : Radius.zero,
                          ),
                        ),
                      ),
                    ),
                  if (percentage < 100)
                    Expanded(
                      flex: (100 - percentage).toInt().clamp(1, 100),
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: color.surfaceContainerHighest,
                          borderRadius: BorderRadius.horizontal(
                            left: percentage == 0 ? const Radius.circular(8) : Radius.zero,
                            right: const Radius.circular(8),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (remaining > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(LucideIcons.trendingDown, size: 14, color: color.tertiary),
                    const SizedBox(width: 4),
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
              if (percentage >= 80)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        percentage >= 90 ? LucideIcons.circleAlert : LucideIcons.triangleAlert,
                        size: 14,
                        color: progressColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        percentage >= 90 ? 'Budget exceeded!' : 'Approaching limit',
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
        ),
      ),
    );
  }

  bool _isFixed(String budgetName) {
    final fixed = ['rent', 'utilities', 'subscription', 'insurance', 'loan', 'emi', 'fixed', 'essential'];
    return fixed.any((f) => budgetName.toLowerCase().contains(f));
  }

  bool _isVariable(String budgetName) {
    final variable = ['groceries', 'food', 'dining', 'entertainment', 'shopping', 'transport', 'variable', 'discretionary'];
    return variable.any((v) => budgetName.toLowerCase().contains(v));
  }

  bool _isGoal(String budgetName) {
    final goals = ['savings', 'investment', 'travel', 'emergency', 'goal'];
    return goals.any((g) => budgetName.toLowerCase().contains(g));
  }

  List<double> _generateSparklineData(double spent, double budget) {
    final random = spent / budget;
    return List.generate(30, (i) {
      final progress = (i + 1) / 30;
      return (random * progress * budget).clamp(0.0, budget);
    });
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> dataPoints;
  final Color sparkColor;
  final Color backgroundColor;

  _SparklinePainter({
    required this.dataPoints,
    required this.sparkColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;
    final maxValue = dataPoints.reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) return;

    final padding = 0.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;
    final stepX = chartWidth / (dataPoints.length - 1);

    final areaPath = Path()..moveTo(padding, size.height - padding);
    for (int i = 0; i < dataPoints.length; i++) {
      final x = padding + i * stepX;
      final y = size.height - padding - (dataPoints[i] / maxValue * chartHeight);
      areaPath.lineTo(x, y);
    }
    areaPath.lineTo(size.width - padding, size.height - padding);
    areaPath.close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [sparkColor.withValues(alpha: 0.3), sparkColor.withValues(alpha: 0.05)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(areaPath, areaPaint);

    final linePath = Path();
    for (int i = 0; i < dataPoints.length; i++) {
      final x = padding + i * stepX;
      final y = size.height - padding - (dataPoints[i] / maxValue * chartHeight);
      i == 0 ? linePath.moveTo(x, y) : linePath.lineTo(x, y);
    }
    canvas.drawPath(linePath, Paint()..color = sparkColor..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);

    for (int i = 0; i < dataPoints.length; i += 5) {
      final x = padding + i * stepX;
      final y = size.height - padding - (dataPoints[i] / maxValue * chartHeight);
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = sparkColor..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(x, y), 2, Paint()..color = backgroundColor..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.dataPoints != dataPoints ||
      oldDelegate.sparkColor != sparkColor ||
      oldDelegate.backgroundColor != backgroundColor;
}

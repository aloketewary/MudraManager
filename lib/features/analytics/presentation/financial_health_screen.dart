import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/features/analytics/data/advanced_analytics_service.dart';
import 'package:mudra_manager/features/analytics/data/analytics_provider.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'dart:math' as math;

class FinancialHealthScreen extends ConsumerWidget {
  const FinancialHealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final healthAsync = ref.watch(financialHealthProvider);
    final predictionAsync = ref.watch(predictedSpendingProvider);
    final categoryTrendsAsync = ref.watch(categoryTrendsProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: color.surface,
      body: healthAsync.when(
        data: (health) => CustomScrollView(
          slivers: [
            // Gradient hero app bar
            SliverAppBar(
              expandedHeight: 380,
              pinned: true,
              backgroundColor: color.surface,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeroSection(health, color, textTheme, isDark),
              ),
              title: const Text('Financial Health'),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontal,
                vertical: spacing.cardVertical,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Bento stat pills
                  _buildBentoStats(health, color, textTheme),
                  SizedBox(height: spacing.sectionGap),

                  // Score breakdown
                  _buildScoreBreakdown(health, color, textTheme, spacing),
                  SizedBox(height: spacing.sectionGap),

                  // Category health
                  categoryTrendsAsync.maybeWhen(
                    data: (trends) => _buildCategoryHealth(
                      trends,
                      color,
                      textTheme,
                      spacing,
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                  SizedBox(height: spacing.sectionGap),

                  // Liquidity runway
                  predictionAsync.maybeWhen(
                    data: (predicted) => _buildLiquidityRunway(
                      health,
                      predicted,
                      color,
                      textTheme,
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                  SizedBox(height: spacing.sectionGap),

                  // Smart insights
                  if (health.insights.isNotEmpty)
                    _buildInsights(health, color, textTheme),
                  SizedBox(height: spacing.sectionGap * 2),
                ]),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Unable to load health data')),
      ),
    );
  }

  // ── HERO SECTION ──
  Widget _buildHeroSection(
    FinancialHealthScore health,
    ColorScheme color,
    TextTheme textTheme,
    bool isDark,
  ) {
    final scoreColor = _getScoreColor(health.score);
    final progress = health.score / 100;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scoreColor.withValues(alpha: isDark ? 0.15 : 0.08),
            color.surface,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Radial glow blob
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: scoreColor.withValues(alpha: isDark ? 0.2 : 0.12),
                      blurRadius: 80,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Score ring
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 100),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1800),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0.0, end: progress),
                builder: (context, value, child) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: CustomPaint(
                              painter: _GradientRingPainter(
                                progress: value,
                                color: scoreColor,
                                isDark: isDark,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(value * 100).toInt()}',
                                style: textTheme.displayLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                  color: scoreColor,
                                  fontSize: 56,
                                ),
                              ),
                              Text(
                                'of 100',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── BENTO STAT PILLS ──
  Widget _buildBentoStats(
    FinancialHealthScore health,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    final scoreColor = _getScoreColor(health.score);

    return Row(
      children: [
        Expanded(
          child: _bentoPill(
            icon: LucideIcons.shield,
            label: health.rating,
            subtitle: 'Rating',
            pillColor: scoreColor,
            color: color,
            textTheme: textTheme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _bentoPill(
            icon: LucideIcons.piggyBank,
            label: '${health.savingsRate.toStringAsFixed(1)}%',
            subtitle: 'Savings',
            pillColor: const Color(0xFF4CAF50),
            color: color,
            textTheme: textTheme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _bentoPill(
            icon: LucideIcons.shoppingCart,
            label: '${health.expenseRatio.toStringAsFixed(1)}%',
            subtitle: 'Spending',
            pillColor: health.expenseRatio > 80
                ? const Color(0xFFF44336)
                : const Color(0xFFFF9800),
            color: color,
            textTheme: textTheme,
          ),
        ),
      ],
    );
  }

  Widget _bentoPill({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color pillColor,
    required ColorScheme color,
    required TextTheme textTheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: pillColor),
          const SizedBox(height: 8),
          Text(
            label,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: pillColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: textTheme.labelSmall?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── SCORE BREAKDOWN ──
  Widget _buildScoreBreakdown(
    FinancialHealthScore health,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    // Derive component scores from the health calculation logic
    final savingsRate = health.savingsRate;
    final expenseRatio = health.expenseRatio;

    final savingsPoints = savingsRate >= 30
        ? 30
        : savingsRate >= 20
            ? 25
            : savingsRate >= 10
                ? 15
                : 5;
    final budgetPoints = expenseRatio <= 50
        ? 30
        : expenseRatio <= 70
            ? 20
            : expenseRatio <= 90
                ? 10
                : 0;
    // Remaining points from total
    final knownPoints = savingsPoints + budgetPoints;
    final remainingPoints = health.score - knownPoints;
    final debtPoints = remainingPoints.clamp(0, 20);
    final emergencyPoints = (remainingPoints - debtPoints).clamp(0, 20);

    final components = [
      _ScoreComponent(
        'Savings Rate',
        savingsPoints,
        30,
        LucideIcons.piggyBank,
        const Color(0xFF4CAF50),
      ),
      _ScoreComponent(
        'Budget Discipline',
        budgetPoints,
        30,
        LucideIcons.shieldCheck,
        const Color(0xFF2196F3),
      ),
      _ScoreComponent(
        'Debt Factor',
        debtPoints,
        20,
        LucideIcons.landmark,
        const Color(0xFF9C27B0),
      ),
      _ScoreComponent(
        'Emergency Fund',
        emergencyPoints,
        20,
        LucideIcons.heartPulse,
        const Color(0xFFFF9800),
      ),
    ];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(),
      color: color.surfaceContainerLow,
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacing.elementGap),
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  ),
                  child: Icon(
                    LucideIcons.chartBar,
                    color: color.primary,
                    size: 20,
                  ),
                ),
                SizedBox(width: spacing.elementGap),
                Text(
                  'Score Breakdown',
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: spacing.cardHorizontal),
            ...components.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildComponentBar(c, color, textTheme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComponentBar(
    _ScoreComponent component,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(component.icon, size: 16, color: component.barColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                component.label,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '${component.earned}/${component.max}',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: component.barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            tween: Tween(
              begin: 0.0,
              end: (component.earned / component.max).clamp(0.0, 1.0),
            ),
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: component.barColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(component.barColor),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── CATEGORY HEALTH ──
  Widget _buildCategoryHealth(
    Map<String, CategoryTrend> trends,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    if (trends.isEmpty) return const SizedBox.shrink();

    final sorted = trends.values.toList()
      ..sort((a, b) => b.thisMonth.compareTo(a.thisMonth));
    final top = sorted.take(5).toList();
    final maxAmount = top.first.thisMonth;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(),
      color: color.surfaceContainerLow,
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(LucideIcons.layers, color: color.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Category Health',
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...top.map(
              (trend) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        trend.categoryName,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOutCubic,
                          tween: Tween(
                            begin: 0.0,
                            end: maxAmount > 0
                                ? (trend.thisMonth / maxAmount).clamp(0.0, 1.0)
                                : 0.0,
                          ),
                          builder: (context, value, child) {
                            return LinearProgressIndicator(
                              value: value,
                              minHeight: 8,
                              backgroundColor: color.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation(color.primary),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 72,
                      child: CurrencyText(
                        amount: trend.thisMonth,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildTrendBadge(trend.changePercent, textTheme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendBadge(double changePercent, TextTheme textTheme) {
    if (changePercent == 0) {
      return SizedBox(
        width: 48,
        child: Text(
          '—',
          textAlign: TextAlign.center,
          style: textTheme.labelSmall,
        ),
      );
    }

    final isUp = changePercent > 0;
    final trendColor = isUp ? const Color(0xFFF44336) : const Color(0xFF4CAF50);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: trendColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? LucideIcons.trendingUp : LucideIcons.trendingDown,
            size: 10,
            color: trendColor,
          ),
          const SizedBox(width: 2),
          Text(
            '${changePercent.abs().toStringAsFixed(0)}%',
            style: textTheme.labelSmall?.copyWith(
              color: trendColor,
              fontWeight: FontWeight.w600,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  // ── LIQUIDITY RUNWAY ──
  Widget _buildLiquidityRunway(
    FinancialHealthScore health,
    double predicted,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    final daysOfCover =
        predicted > 0 ? (30 * (100 - health.expenseRatio) / 100).round() : 0;
    final runwayProgress = (daysOfCover / 90).clamp(0.0, 1.0);
    final runwayColor = daysOfCover >= 60
        ? const Color(0xFF4CAF50)
        : daysOfCover >= 30
            ? const Color(0xFFFF9800)
            : const Color(0xFFF44336);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(),
      color: color.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: runwayColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(LucideIcons.droplet, color: runwayColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Liquidity Runway',
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'If income stops today',
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$daysOfCover',
                  style: textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: runwayColor,
                  ),
                ),
                Text(
                  ' days',
                  style: textTheme.bodyMedium?.copyWith(
                    color: runwayColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Runway gauge
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1400),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0.0, end: runwayProgress),
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 12,
                    backgroundColor: runwayColor.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(runwayColor),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '0 days',
                  style: textTheme.labelSmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
                Text(
                  '90 days',
                  style: textTheme.labelSmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── SMART INSIGHTS ──
  Widget _buildInsights(
    FinancialHealthScore health,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(),
      color: color.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.sparkles,
                    color: color.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Smart Insights',
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...health.insights.map(
              (insight) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        LucideIcons.lightbulb,
                        color: color.primary,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        insight,
                        style: textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFF2196F3);
    if (score >= 40) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }
}

// ── HELPER CLASSES ──

class _ScoreComponent {
  final String label;
  final int earned;
  final int max;
  final IconData icon;
  final Color barColor;

  _ScoreComponent(this.label, this.earned, this.max, this.icon, this.barColor);
}

class _GradientRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isDark;

  _GradientRingPainter({
    required this.progress,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 16.0;

    final bgPaint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.15 : 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    final rect =
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);
    final gradient = SweepGradient(
      colors: [
        color,
        color.withValues(alpha: 0.7),
        color.withValues(alpha: 0.5),
        color,
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
      transform: const GradientRotation(-math.pi / 2),
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (isDark) {
      final glowPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        glowPaint,
      );
    }

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_GradientRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.isDark != isDark;
}

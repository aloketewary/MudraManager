import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/features/analytics/data/advanced_analytics_service.dart';
import 'package:mudra_manager/features/analytics/data/analytics_provider.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:visibility_detector/visibility_detector.dart';
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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.title_financialHealth),
        elevation: 0,
      ),
      body: healthAsync.when(
        data: (health) {
          final scoreColor = _scoreColor(health.score, color);

          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
            children: [
              // 1. Hero — Score + Verdict
              _buildHero(health, scoreColor, color, textTheme, spacing, isDark),
              SizedBox(height: spacing.sectionGap),

              // 2. Key Insight (top 1)
              if (health.insights.isNotEmpty)
                _buildKeyInsight(
                    health.insights.first, scoreColor, color, textTheme, spacing),
              if (health.insights.isNotEmpty)
                SizedBox(height: spacing.sectionGap),

              // 3. Score Breakdown
              _buildScoreBreakdown(health, color, textTheme, spacing),
              SizedBox(height: spacing.sectionGap),

              // 4. Liquidity Runway
              predictionAsync.maybeWhen(
                data: (predicted) => _buildLiquidityRunway(
                    health, predicted, color, textTheme, spacing),
                orElse: () => const SizedBox.shrink(),
              ),
              SizedBox(height: spacing.sectionGap),

              // 5. Category Health
              categoryTrendsAsync.maybeWhen(
                data: (trends) =>
                    _buildCategoryHealth(trends, color, textTheme, spacing),
                orElse: () => const SizedBox.shrink(),
              ),
              SizedBox(height: spacing.sectionGap),

              // 6. What You Can Do
              if (health.insights.length > 1)
                _buildActions(health.insights.skip(1).toList(), color,
                    textTheme, spacing),
              SizedBox(height: spacing.sectionGap * 3),
            ],
          );
        },
        loading: () => ListView(
            children:
                List.generate(3, (_) => const DashboardCardSkeleton())),
        error: (_, __) =>
            const Center(child: Text('Unable to load health data')),
      ),
    );
  }

  // ── 1. HERO ──
  Widget _buildHero(
    FinancialHealthScore health,
    Color scoreColor,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    bool isDark,
  ) {
    final verdict = _verdict(health.score);

    return Column(
      children: [
        SizedBox(height: spacing.sectionGap),
        _AnimatedScoreRing(
          score: health.score / 100,
          scoreColor: scoreColor,
          textTheme: textTheme,
          isDark: isDark,
        ),
        SizedBox(height: spacing.sectionGap),
        // Verdict badge
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.cardInner,
            vertical: spacing.elementGap,
          ),
          decoration: BoxDecoration(
            color: scoreColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(spacing.radiusLarge),
          ),
          child: Text(
            '${health.rating} — $verdict',
            style: textTheme.titleSmall?.copyWith(
              color: scoreColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  String _verdict(int score) {
    if (score >= 80) return "you're in great shape";
    if (score >= 60) return "you're on track";
    if (score >= 40) return 'room for improvement';
    return 'needs attention';
  }

  // ── 2. KEY INSIGHT ──
  Widget _buildKeyInsight(
    String insight,
    Color scoreColor,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: scoreColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: scoreColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.lightbulb, size: 18, color: scoreColor),
          SizedBox(width: spacing.elementGap * 1.5),
          Expanded(
            child: Text(
              insight,
              style: textTheme.bodyMedium?.copyWith(
                color: color.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. SCORE BREAKDOWN ──
  Widget _buildScoreBreakdown(
    FinancialHealthScore health,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
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
    final knownPoints = savingsPoints + budgetPoints;
    final remainingPoints = health.score - knownPoints;
    final debtPoints = remainingPoints.clamp(0, 20);
    final emergencyPoints = (remainingPoints - debtPoints).clamp(0, 20);

    final components = [
      _Component('Savings', savingsPoints, 30, LucideIcons.piggyBank),
      _Component('Spending', budgetPoints, 30, LucideIcons.shieldCheck),
      _Component('Debt', debtPoints, 20, LucideIcons.landmark),
      _Component('Emergency', emergencyPoints, 20, LucideIcons.heartPulse),
    ];

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(
            color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Score Breakdown', LucideIcons.chartBar, color,
                textTheme, spacing),
            SizedBox(height: spacing.sectionGap),
            ...components.map(
              (c) => Padding(
                padding: EdgeInsets.only(bottom: spacing.elementGap * 1.5),
                child: _buildComponentRow(c, color, textTheme, spacing),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComponentRow(
    _Component c,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final ratio = c.max > 0 ? c.earned / c.max : 0.0;
    final isGood = ratio >= 0.7;
    final statusColor = isGood ? FinanceColors.statusGood : FinanceColors.statusWarning;
    final statusIcon = isGood ? LucideIcons.circleCheck : LucideIcons.circleAlert;

    return Row(
      children: [
        Icon(c.icon, size: 16, color: color.onSurfaceVariant),
        SizedBox(width: spacing.elementGap),
        SizedBox(
          width: 80,
          child: Text(
            c.label,
            style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: _AnimatedBar(
            progress: ratio.clamp(0.0, 1.0),
            barColor: statusColor,
            radius: spacing.radiusSmall,
          ),
        ),
        SizedBox(width: spacing.elementGap),
        Text(
          '${c.earned}/${c.max}',
          style: textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
        SizedBox(width: spacing.elementGapMin),
        Icon(statusIcon, size: 14, color: statusColor),
      ],
    );
  }

  // ── 4. LIQUIDITY RUNWAY ──
  Widget _buildLiquidityRunway(
    FinancialHealthScore health,
    double predicted,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final daysOfCover =
        predicted > 0 ? (30 * (100 - health.expenseRatio) / 100).round() : 0;
    final months = (daysOfCover / 30).toStringAsFixed(1);
    final runwayProgress = (daysOfCover / 90).clamp(0.0, 1.0);

    final Color runwayColor;
    final String statusLabel;
    if (daysOfCover >= 60) {
      runwayColor = FinanceColors.statusGood;
      statusLabel = 'Safe';
    } else if (daysOfCover >= 30) {
      runwayColor = FinanceColors.statusWarning;
      statusLabel = 'Moderate';
    } else {
      runwayColor = FinanceColors.statusDanger;
      statusLabel = 'Risk';
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(
            color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
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
                    color: runwayColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  ),
                  child: Icon(LucideIcons.droplet,
                      color: runwayColor, size: 20),
                ),
                SizedBox(width: spacing.elementGap * 1.5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Liquidity Runway',
                        style: textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Your balance covers $months months of expenses',
                        style: textTheme.bodySmall
                            ?.copyWith(color: color.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.elementGap,
                    vertical: spacing.elementGapMin,
                  ),
                  decoration: BoxDecoration(
                    color: runwayColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  ),
                  child: Text(
                    statusLabel,
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: runwayColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.sectionGap),
            // Days + bar
            Row(
              children: [
                Text(
                  '$daysOfCover',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: runwayColor,
                  ),
                ),
                SizedBox(width: spacing.elementGapMin),
                Text(
                  'days',
                  style: textTheme.bodyMedium?.copyWith(
                    color: runwayColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.elementGap),
            _AnimatedBar(
              progress: runwayProgress,
              barColor: runwayColor,
              radius: spacing.radiusSmall,
              height: 10,
            ),
            SizedBox(height: spacing.elementGapMin),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0',
                    style: textTheme.labelSmall
                        ?.copyWith(color: color.onSurfaceVariant)),
                Text('90 days',
                    style: textTheme.labelSmall
                        ?.copyWith(color: color.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 5. CATEGORY HEALTH ──
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

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(
            color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Category Health', LucideIcons.layers, color,
                textTheme, spacing),
            SizedBox(height: spacing.sectionGap),
            ...top.map(
              (trend) => Padding(
                padding: EdgeInsets.only(bottom: spacing.elementGap * 1.5),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        trend.categoryName,
                        style: textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: spacing.elementGap),
                    // Trend label
                    _trendLabel(trend.changePercent, textTheme, color),
                    SizedBox(width: spacing.elementGap),
                    SizedBox(
                      width: 64,
                      child: CurrencyText(
                        amount: trend.thisMonth,
                        fixedLength: 0,
                        style: textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
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

  Widget _trendLabel(
      double changePercent, TextTheme textTheme, ColorScheme color) {
    if (changePercent.abs() < 5) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Stable →',
          style: textTheme.labelSmall?.copyWith(
            color: color.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final isUp = changePercent > 0;
    final trendColor = isUp ? FinanceColors.statusDanger : FinanceColors.statusGood;
    final label = isUp ? 'High ↑' : 'Reduced ↓';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: trendColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          color: trendColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── 6. WHAT YOU CAN DO ──
  Widget _buildActions(
    List<String> insights,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(
            color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('What You Can Do', LucideIcons.rocket, color,
                textTheme, spacing),
            SizedBox(height: spacing.sectionGap),
            ...insights.map(
              (insight) => Padding(
                padding: EdgeInsets.only(bottom: spacing.elementGap),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: spacing.elementGapUltraMin),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: spacing.elementGap * 1.5),
                    Expanded(
                      child: Text(
                        insight,
                        style: textTheme.bodyMedium?.copyWith(
                          height: 1.4,
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

  // ── Helpers ──

  Widget _sectionHeader(String title, IconData icon, ColorScheme color,
      TextTheme textTheme, AppSpacing spacing) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color.primary),
        SizedBox(width: spacing.elementGap),
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Color _scoreColor(int score, ColorScheme color) {
    if (score >= 80) return FinanceColors.statusGood;
    if (score >= 60) return color.primary;
    if (score >= 40) return FinanceColors.statusWarning;
    return FinanceColors.statusDanger;
  }
}

// ── Data helpers ──

class _Component {
  final String label;
  final int earned;
  final int max;
  final IconData icon;
  _Component(this.label, this.earned, this.max, this.icon);
}

// ── Animated Score Ring (visibility-aware) ──

class _AnimatedScoreRing extends StatefulWidget {
  final double score;
  final Color scoreColor;
  final TextTheme textTheme;
  final bool isDark;

  const _AnimatedScoreRing({
    required this.score,
    required this.scoreColor,
    required this.textTheme,
    required this.isDark,
  });

  @override
  State<_AnimatedScoreRing> createState() => _AnimatedScoreRingState();
}

class _AnimatedScoreRingState extends State<_AnimatedScoreRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const ValueKey('health_score_ring'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.3 && !_started) {
          _started = true;
          _ctrl.forward();
        }
      },
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          final value = _anim.value * widget.score;
          return SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(200, 200),
                  painter: _GradientRingPainter(
                    progress: value,
                    color: widget.scoreColor,
                    isDark: widget.isDark,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(value * 100).toInt()}',
                      style: widget.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1,
                        color: widget.scoreColor,
                        fontSize: 56,
                      ),
                    ),
                    Text(
                      'of 100',
                      style: widget.textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Animated Bar (visibility-aware) ──

class _AnimatedBar extends StatefulWidget {
  final double progress;
  final Color barColor;
  final double radius;
  final double height;

  const _AnimatedBar({
    required this.progress,
    required this.barColor,
    required this.radius,
    this.height = 8,
  });

  @override
  State<_AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<_AnimatedBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: ValueKey(
          'bar_${widget.progress}_${widget.barColor.toARGB32()}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.3 && !_started) {
          _started = true;
          _ctrl.forward();
        }
      },
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => ClipRRect(
          borderRadius: BorderRadius.circular(widget.radius),
          child: LinearProgressIndicator(
            value: _anim.value * widget.progress,
            minHeight: widget.height,
            backgroundColor: widget.barColor.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(widget.barColor),
          ),
        ),
      ),
    );
  }
}

// ── Gradient Ring Painter ──

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
          rect, -math.pi / 2, 2 * math.pi * progress, false, glowPaint);
    }

    canvas.drawArc(
        rect, -math.pi / 2, 2 * math.pi * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(_GradientRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.isDark != isDark;
}

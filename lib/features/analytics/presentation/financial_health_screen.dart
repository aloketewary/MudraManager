import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/features/analytics/data/advanced_analytics_service.dart';
import 'package:mudra_manager/features/analytics/data/analytics_provider.dart';
import 'dart:math' as math;

class FinancialHealthScreen extends ConsumerWidget {
  const FinancialHealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(financialHealthProvider);
    final predictionAsync = ref.watch(predictedSpendingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        title: const Text('Financial Health'),
        elevation: 0,
      ),
      body: healthAsync.when(
        data: (health) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeroScoreRing(health, color, textTheme, Theme.of(context).brightness == Brightness.dark),
              const SizedBox(height: 24),
              _buildCategorizedWellness(health, color, textTheme, Theme.of(context).brightness == Brightness.dark),
              const SizedBox(height: 16),
              predictionAsync.maybeWhen(
                data: (predicted) => _buildLiquidityTracker(health, predicted, color, textTheme, Theme.of(context).brightness == Brightness.dark),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              if (health.insights.isNotEmpty)
                _buildActionableAdvice(health, color, textTheme, Theme.of(context).brightness == Brightness.dark),
              const SizedBox(height: 16),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Unable to load health data')),
      ),
    );
  }

  Widget _buildHeroScoreRing(
    FinancialHealthScore health,
    ColorScheme color,
    TextTheme textTheme,
    bool isDark,
  ) {
    final scoreColor = _getScoreColor(health.score, color);
    final progress = health.score / 100;

    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 0,
        color: color.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0.0, end: progress),
            builder: (context, value, child) {
              return Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 240,
                        height: 240,
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
                              fontSize: 64,
                            ),
                          ),
                          Text(
                            '/100',
                            style: textTheme.titleMedium?.copyWith(
                              color: color.onSurfaceVariant,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      health.rating,
                      style: textTheme.titleLarge?.copyWith(
                        color: scoreColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategorizedWellness(
    FinancialHealthScore health,
    ColorScheme color,
    TextTheme textTheme,
    bool isDark,
  ) {
    final categories = [
      _WellnessCategory('Spending', health.expenseRatio, LucideIcons.shoppingCart),
      _WellnessCategory('Savings', health.savingsRate, LucideIcons.piggyBank),
    ];

    return Row(
      children: categories.asMap().entries.map((entry) {
        final cat = entry.value;
        final index = entry.key;
        final status = cat.value >= 20 ? 'Healthy' : cat.value >= 10 ? 'Caution' : 'Critical';
        final statusColor = cat.value >= 20 ? const Color(0xFF4CAF50) : cat.value >= 10 ? const Color(0xFFFF9800) : const Color(0xFFF44336);
        
        return Expanded(
          child: TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 800 + (index * 200)),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0.0, end: cat.value / 100),
            builder: (context, progress, child) {
              return Card(
                elevation: 0,
                color: color.surfaceContainerLow,
                margin: EdgeInsets.only(left: index == 0 ? 0 : 6, right: index == 1 ? 0 : 6),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(cat.icon, color: statusColor, size: 20),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        cat.name,
                        style: textTheme.bodyMedium?.copyWith(
                          color: color.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${cat.value.toStringAsFixed(1)}%',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLiquidityTracker(
    FinancialHealthScore health,
    double predicted,
    ColorScheme color,
    TextTheme textTheme,
    bool isDark,
  ) {
    final daysOfCover = predicted > 0 ? (30 * (100 - health.expenseRatio) / 100).round() : 0;
    
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 0,
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
                    child: Icon(LucideIcons.droplet, color: color.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Liquidity',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Days of Cover',
                          style: textTheme.bodyMedium?.copyWith(
                            color: color.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'If income stops today',
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$daysOfCover',
                    style: textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: color.primary,
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



  Widget _buildActionableAdvice(
    FinancialHealthScore health,
    ColorScheme color,
    TextTheme textTheme,
    bool isDark,
  ) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 0,
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
                    child: Icon(LucideIcons.sparkles, color: color.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Smart Insights',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...health.insights.asMap().entries.map(
                (entry) => Container(
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
                          entry.value,
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
      ),
    );
  }

  Color _getScoreColor(int score, ColorScheme color) {
    if (score >= 80) return const Color(0xFF4CAF50); // Green - Excellent
    if (score >= 60) return const Color(0xFF2196F3); // Blue - Good
    if (score >= 40) return const Color(0xFFFF9800); // Orange - Fair
    return const Color(0xFFF44336); // Red - Poor
  }
}

class _GradientRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isDark;

  _GradientRingPainter({required this.progress, required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 18.0;

    final bgPaint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.15 : 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);
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
      oldDelegate.progress != progress || oldDelegate.color != color || oldDelegate.isDark != isDark;
}

class _WellnessCategory {
  final String name;
  final double value;
  final IconData icon;

  _WellnessCategory(this.name, this.value, this.icon);
}

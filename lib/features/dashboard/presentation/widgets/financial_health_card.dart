import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/features/analytics/data/analytics_provider.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'dart:math' as math;

class FinancialHealthCard extends ConsumerWidget {
  final double globalPadding;

  const FinancialHealthCard({super.key, required this.globalPadding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(financialHealthProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);

    return healthAsync.when(
      data: (health) {
        if (health.score == 0) return const SizedBox.shrink();

        final scoreColor = _scoreColor(health.score, color);
        final verdict = _verdict(health.score);
        final topInsight =
            health.insights.isNotEmpty ? health.insights.first : null;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: globalPadding),
          child: Card(
            elevation: 0,
            color: color.surfaceContainerLow,
            margin: const EdgeInsets.only(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              side: BorderSide(
                color: scoreColor.withValues(alpha: 0.2),
              ),
            ),
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                context.push(AppRoutes.financialHealth);
              },
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              child: Padding(
                padding: EdgeInsets.all(spacing.cardInner),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Ring + Score + Verdict
                    Row(
                      children: [
                        _AnimatedMiniRing(
                          score: health.score / 100,
                          scoreColor: scoreColor,
                          textTheme: textTheme,
                        ),
                        SizedBox(width: spacing.elementGap * 1.5),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Financial Health',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: spacing.elementGapMin),
                              // Verdict badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: spacing.elementGap,
                                  vertical: spacing.elementGapUltraMin,
                                ),
                                decoration: BoxDecoration(
                                  color: scoreColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                    spacing.radiusSmall,
                                  ),
                                ),
                                child: Text(
                                  '${health.rating} — $verdict',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: scoreColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: color.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                      ],
                    ),

                    // Row 2: Key insight
                    if (topInsight != null) ...[
                      SizedBox(height: spacing.elementGap * 1.5),
                      Text(
                        topInsight,
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    SizedBox(height: spacing.elementGap),

                    // Row 3: Tap hint
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Tap to explore',
                          style: textTheme.labelSmall?.copyWith(
                            color:
                                color.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        SizedBox(width: spacing.elementGapMin),
                        Icon(
                          LucideIcons.arrowRight,
                          size: 12,
                          color: color.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOut).slideY(
              begin: 0.05,
              end: 0,
              duration: 400.ms,
              curve: Curves.easeOut,
            );
      },
      loading: () => Padding(
        padding: EdgeInsets.only(top: spacing.sectionGap),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: globalPadding),
          child: const DashboardCardSkeleton(),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _verdict(int score) {
    if (score >= 80) return 'great shape';
    if (score >= 60) return 'on track';
    if (score >= 40) return 'needs work';
    return 'needs attention';
  }

  Color _scoreColor(int score, ColorScheme color) {
    if (score >= 80) return FinanceColors.statusGood;
    if (score >= 60) return color.primary;
    if (score >= 40) return FinanceColors.statusWarning;
    return FinanceColors.statusDanger;
  }
}

// ── Visibility-aware mini score ring ──

class _AnimatedMiniRing extends StatefulWidget {
  final double score;
  final Color scoreColor;
  final TextTheme textTheme;

  const _AnimatedMiniRing({
    required this.score,
    required this.scoreColor,
    required this.textTheme,
  });

  @override
  State<_AnimatedMiniRing> createState() => _AnimatedMiniRingState();
}

class _AnimatedMiniRingState extends State<_AnimatedMiniRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
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
      key: const ValueKey('health_mini_ring'),
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
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(52, 52),
                  painter: _CompactRingPainter(
                    progress: value,
                    color: widget.scoreColor,
                  ),
                ),
                Text(
                  '${(value * 100).toInt()}',
                  style: widget.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: widget.scoreColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CompactRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CompactRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const strokeWidth = 5.0;

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      colors: [color, color.withValues(alpha: 0.6), color],
      stops: const [0.0, 0.5, 1.0],
      transform: const GradientRotation(-math.pi / 2),
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CompactRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

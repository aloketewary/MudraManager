import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/widgets/dashboard_widget_plugin.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/ai_insight_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';

class AiInsightWidgetPlugin extends DashboardWidgetPlugin {
  @override
  String get id => 'ai_insight';

  @override
  String get title => 'AI Insights';

  @override
  IconData get icon => LucideIcons.sparkles;

  @override
  int get defaultOrder => 1;

  @override
  WidgetCategory get category => WidgetCategory.ai;

  @override
  WidgetSize get defaultSize => WidgetSize.medium;

  @override
  String get description => 'AI-powered financial insights and recommendations';

  @override
  bool isVisible(WidgetRef ref) {
    final insights = ref.watch(aiInsightProvider);
    return insights.isNotEmpty;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final insights = ref.watch(aiInsightProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (insights.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: color.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          side: BorderSide(
            color: color.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(spacing.cardInner),
              child: Row(
                children: [
                  Icon(LucideIcons.sparkles, color: color.primary, size: 20),
                  SizedBox(width: spacing.cardHorizontal),
                  Text(
                    'Smart Insights',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.primary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.cardHorizontalMin,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.primary, color.tertiary],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.sparkles,
                          color: color.onPrimary,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        AdaptiveText(
                          'AI',
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Rotating insight
            _InsightCarousel(insights: insights),
          ],
        ),
      ),
    );
  }

  @override
  Future<void> refresh(WidgetRef ref) async {
    ref.invalidate(dashboardDataProvider);
  }
}

// ── AUTO-ROTATING CAROUSEL ──

class _InsightCarousel extends StatefulWidget {
  final List<AiInsight> insights;
  const _InsightCarousel({required this.insights});

  @override
  State<_InsightCarousel> createState() => _InsightCarouselState();
}

class _InsightCarouselState extends State<_InsightCarousel> {
  int _current = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _InsightCarousel old) {
    super.didUpdateWidget(old);
    if (old.insights.length != widget.insights.length) {
      _current = 0;
      _restartTimer();
    }
  }

  void _startTimer() {
    if (widget.insights.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      setState(() => _current = (_current + 1) % widget.insights.length);
    });
  }

  void _restartTimer() {
    _timer?.cancel();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final insight = widget.insights[_current];

    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: _InsightTile(
            key: ValueKey(insight.title),
            insight: insight,
          ),
        ),

        // Dot indicators
        if (widget.insights.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.insights.length, (i) {
                final isActive = i == _current;
                return GestureDetector(
                  onTap: () {
                    setState(() => _current = i);
                    _restartTimer();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: isActive
                          ? color.primary
                          : color.onSurfaceVariant.withValues(alpha: 0.2),
                    ),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

// ── INSIGHT TILE ──

class _InsightTile extends StatelessWidget {
  final AiInsight insight;
  const _InsightTile({super.key, required this.insight});

  Color _typeColor(ColorScheme color) {
    switch (insight.type) {
      case 'warning':
        return color.error;
      case 'tip':
        return const Color(0xFFFF9800);
      case 'success':
        return const Color(0xFF4CAF50);
      default:
        return color.primary;
    }
  }

  IconData _icon() {
    switch (insight.iconType) {
      case IconType.warning:
        return LucideIcons.triangleAlert;
      case IconType.tip:
        return LucideIcons.lightbulb;
      case IconType.success:
        return LucideIcons.circleCheck;
      case IconType.budget:
        return LucideIcons.chartPie;
      case IconType.goal:
        return LucideIcons.target;
      case IconType.savings:
        return LucideIcons.piggyBank;
      case IconType.spending:
        return LucideIcons.trendingUp;
      case IconType.sms:
        return LucideIcons.messageSquareWarning;
      default:
        return LucideIcons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = _typeColor(color);

    return InkWell(
      onTap: insight.actionRoute != null
          ? () {
              HapticFeedback.lightImpact();
              context.push(insight.actionRoute!);
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_icon(), color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.title,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    insight.message,
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (insight.actionRoute != null)
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: color.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:auto_skeleton/auto_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/refresh_helper.dart';
import 'package:mudra_manager/core/widgets/skeleton_loader.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/daily_briefing_card.dart';
import 'package:mudra_manager/features/insights/data/insights_provider.dart';
import 'package:mudra_manager/features/insights/domain/health_metrics.dart';
import 'package:mudra_manager/features/insights/domain/recommendation.dart';
import 'package:mudra_manager/features/statistics/data/adaptive_utility_provider.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';
import 'package:mudra_manager/shared/widgets/amount_glow.dart';
import 'package:mudra_manager/shared/widgets/finance_v2/finance_progress_bar.dart';
import 'package:mudra_manager/shared/widgets/inline_error.dart';

/// Focused advice destination for dashboard insights.
///
/// The screen reads providers directly so advice stays current after an action
/// is completed and the user returns from a bill or budget screen.
class FinancialAdviceScreen extends ConsumerStatefulWidget {
  final String? source;
  final String? focusId;

  const FinancialAdviceScreen({
    super.key,
    this.source,
    this.focusId,
  });

  @override
  ConsumerState<FinancialAdviceScreen> createState() =>
      _FinancialAdviceScreenState();
}

class _FinancialAdviceScreenState extends ConsumerState<FinancialAdviceScreen> {
  final _focusedAttentionKey = GlobalKey();
  bool _hasFocusedAttention = false;

  @override
  void didUpdateWidget(covariant FinancialAdviceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusId != widget.focusId) {
      _hasFocusedAttention = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final adviceAsync = ref.watch(insightsProvider);
    final briefing = ref.watch(todayCardProvider);
    final advisoryAsync = ref.watch(adaptiveUtilityProvider);

    return ScreenShell(
      config: const ScreenShellConfig(
        title: 'Financial Advice',
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      body: adviceAsync.when(
        loading: () => _buildLoadingState(spacing),
        error: (error, _) => _buildErrorState(context, ref, spacing),
        data: (advice) {
          final quickWinIds = advice.quickWins.map((item) => item.id).toSet();
          final additionalRecommendations = advice.recommendations
              .where((item) => !quickWinIds.contains(item.id))
              .take(2)
              .toList();

          return RefreshIndicator(
            onRefresh: () => RefreshHelper.withMinDuration(() async {
              ref.invalidate(insightsProvider);
              ref.invalidate(dashboardDataProvider);
              ref.invalidate(todayCardProvider);
              ref.invalidate(adaptiveUtilityProvider);
              await Future.wait([
                ref.read(dashboardDataProvider.future),
                ref.read(insightsProvider.future),
                ref.read(adaptiveUtilityProvider.future),
              ]);
            }),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final contentWidth =
                    constraints.maxWidth > 760 ? 760.0 : constraints.maxWidth;

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(
                        left: spacing.cardHorizontal,
                        right: spacing.cardHorizontal,
                        top: spacing.cardVertical,
                        bottom: spacing.cardVertical +
                            MediaQuery.of(context).padding.bottom,
                      ),
                      children: [
                        _buildPremiumHero(context, spacing, advice),
                        if (briefing != null) ...[
                          SizedBox(height: spacing.sectionGap),
                          _buildBriefingAdvice(context, spacing, briefing),
                        ],
                        if (advice.quickWins.isNotEmpty) ...[
                          SizedBox(height: spacing.sectionGap),
                          _buildAdviceSection(
                            context,
                            spacing,
                            icon: LucideIcons.zap,
                            title: 'Recommended next steps',
                            children: advice.quickWins
                                .map(
                                  (recommendation) => _buildRecommendationRow(
                                    context,
                                    spacing,
                                    recommendation,
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        if (additionalRecommendations.isNotEmpty) ...[
                          SizedBox(height: spacing.sectionGap),
                          _buildAdviceSection(
                            context,
                            spacing,
                            icon: LucideIcons.layers,
                            title: 'More ways to improve',
                            children: additionalRecommendations
                                .map(
                                  (recommendation) => _buildRecommendationRow(
                                    context,
                                    spacing,
                                    recommendation,
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        SizedBox(height: spacing.sectionGap),
                        _buildAdvisoryState(context, spacing, advisoryAsync),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumHero(
    BuildContext context,
    AppSpacing spacing,
    InsightsData advice,
  ) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final metrics = advice.healthMetrics;
    final summary = advice.aiSummary;
    final scoreColor = metrics.ratingColor(context);
    final isDark = color.brightness == Brightness.dark;
    final breakdowns = [
      metrics.savingsHealth,
      metrics.incomeStability,
      metrics.emergencyFund,
      metrics.debtHealth,
      metrics.budgetAdherence,
    ];

    return Semantics(
      container: true,
      label:
          'Financial picture. ${metrics.rating}. Score ${metrics.overallScore.round()} out of 100.',
      child: AnimatedContainer(
        duration: MediaQuery.of(context).disableAnimations
            ? Duration.zero
            : spacing.animNormal,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.primaryContainer.withValues(alpha: isDark ? 0.45 : 0.14),
              color.surfaceContainerHighest,
            ],
          ),
          borderRadius: spacing.borderRadiusLarge,
          border: Border.all(color: color.primary.withValues(alpha: 0.24)),
        ),
        child: Padding(
          padding: EdgeInsets.all(spacing.cardInner),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: spacing.iconXL + spacing.elementGap,
                    height: spacing.iconXL + spacing.elementGap,
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: 0.14),
                      borderRadius: spacing.borderRadiusMedium,
                      border: Border.all(
                        color: color.primary.withValues(alpha: 0.20),
                      ),
                    ),
                    child: Icon(
                      widget.source == 'advisory'
                          ? LucideIcons.lightbulb
                          : LucideIcons.sparkles,
                      color: color.primary,
                      size: spacing.iconMD,
                    ),
                  ),
                  SizedBox(width: spacing.elementGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Financial picture',
                          style: textTheme.labelLarge?.copyWith(
                            color: color.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                        SizedBox(height: spacing.elementGapMin),
                        Text(
                          metrics.rating,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AmountGlow(
                        color: scoreColor,
                        child: Text(
                          '${metrics.overallScore.round()}',
                          style: textTheme.headlineLarge?.copyWith(
                            color: scoreColor,
                            fontWeight: FontWeight.w900,
                            height: 0.95,
                          ),
                        ),
                      ),
                      Text(
                        'out of 100',
                        style: textTheme.labelSmall?.copyWith(
                          color: color.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: spacing.cardInner),
              FinanceProgressBar(
                value: metrics.overallScore / 100,
                fillColor: scoreColor,
                trackColor: color.onSurface.withValues(alpha: 0.10),
                stripeColor: color.onSurface.withValues(alpha: 0.14),
                semanticLabel: 'Financial health score',
              ),
              SizedBox(height: spacing.elementGap),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 520 ? 3 : 2;
                  final itemWidth = (constraints.maxWidth -
                          (spacing.elementGap * (columns - 1))) /
                      columns;

                  return Wrap(
                    spacing: spacing.elementGap,
                    runSpacing: spacing.elementGap,
                    children: [
                      for (final metric in breakdowns)
                        SizedBox(
                          width: itemWidth,
                          child: _buildPremiumMetric(
                            context,
                            spacing,
                            metric,
                          ),
                        ),
                    ],
                  );
                },
              ),
              SizedBox(height: spacing.cardInner),
              Container(
                padding: EdgeInsets.only(top: spacing.cardInner),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: color.outlineVariant.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.activity,
                      color: color.primary,
                      size: spacing.iconMD,
                    ),
                    SizedBox(width: spacing.elementGap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summary.greeting,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: spacing.elementGapMin),
                          Text(
                            summary.hasConcerns
                                ? summary.concernHighlight
                                : summary.positiveHighlight,
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                          SizedBox(height: spacing.elementGap),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                LucideIcons.trendingUp,
                                color: color.primary,
                                size: spacing.iconSM,
                              ),
                              SizedBox(width: spacing.elementGapMin),
                              Expanded(
                                child: Text(
                                  summary.prediction,
                                  style: textTheme.labelMedium?.copyWith(
                                    color: color.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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

  Widget _buildBriefingAdvice(
    BuildContext context,
    AppSpacing spacing,
    TodayCardState state,
  ) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isImprovement = state.signalType == BriefingSignalType.improvement;
    final isPositive = state.isHealthy || isImprovement;
    final statusColor = isPositive ? color.primary : color.error;
    final title =
        state.isHealthy ? 'You are on track' : _formatBriefMessage(state);
    final detail = state.isHealthy
        ? _formatHealthyDetail(state)
        : isImprovement
            ? 'Good progress. Keep this momentum going.'
            : 'Review this insight to keep your plan on track.';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardInner,
        vertical: spacing.elementGap,
      ),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: spacing.borderRadiusMedium,
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? LucideIcons.circleCheck : LucideIcons.circleAlert,
            color: statusColor,
            size: spacing.iconMD,
          ),
          SizedBox(width: spacing.elementGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    color: color.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: spacing.elementGapMin),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (!isPositive && state.actionRoute != null)
            IconButton(
              tooltip: _formatActionLabel(state),
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.push(state.actionRoute!);
              },
              icon: Icon(
                LucideIcons.arrowUpRight,
                color: statusColor,
                size: spacing.iconMD,
              ),
              visualDensity: VisualDensity.compact,
              constraints: BoxConstraints(
                minWidth: spacing.touchTargetSmall,
                minHeight: spacing.touchTargetSmall,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumMetric(
    BuildContext context,
    AppSpacing spacing,
    HealthScoreBreakdown metric,
  ) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final metricColor = metric.isCritical
        ? color.error
        : metric.isWarning
            ? color.tertiary
            : color.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          metric.label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelSmall?.copyWith(
            color: color.onSurfaceVariant,
          ),
        ),
        SizedBox(height: spacing.elementGapMin),
        Text(
          '${(metric.percentage * 100).round()}%',
          style: textTheme.titleSmall?.copyWith(
            color: metricColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildAdvisoryState(
    BuildContext context,
    AppSpacing spacing,
    AsyncValue<AdaptiveUtilityState> advisoryAsync,
  ) {
    return advisoryAsync.when(
      loading: () => _buildAdviceSection(
        context,
        spacing,
        icon: LucideIcons.lightbulb,
        title: 'Financial advisory',
        children: const [DashboardCardSkeleton()],
      ),
      error: (_, __) => _buildAdviceSection(
        context,
        spacing,
        icon: LucideIcons.lightbulb,
        title: 'Financial advisory',
        children: [
          const InlineError(
            message: 'Advisory insights are unavailable right now.',
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.invalidate(adaptiveUtilityProvider);
              },
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Try again'),
            ),
          ),
        ],
      ),
      data: (state) {
        final hasFocusedItem = widget.focusId != null &&
            state.attentionItems.any((item) => item.id == widget.focusId);
        if (hasFocusedItem && !_hasFocusedAttention) {
          _hasFocusedAttention = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final targetContext = _focusedAttentionKey.currentContext;
            if (targetContext != null) {
              Scrollable.ensureVisible(
                targetContext,
                duration: MediaQuery.of(context).disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                alignment: 0.15,
              );
            }
          });
        }

        if (state.attentionItems.isEmpty) {
          return _buildAdviceSection(
            context,
            spacing,
            icon: LucideIcons.circleCheck,
            title: 'Financial advisory',
            children: [
              _buildQuietAdvisory(context, spacing),
            ],
          );
        }

        return _buildAdviceSection(
          context,
          spacing,
          icon: LucideIcons.lightbulb,
          title: 'Financial advisory',
          children: state.attentionItems
              .map(
                (item) => _buildAttentionItem(
                  context,
                  spacing,
                  item,
                  item.id == widget.focusId,
                  key: item.id == widget.focusId ? _focusedAttentionKey : null,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.push(item.actionRoute);
                  },
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildQuietAdvisory(BuildContext context, AppSpacing spacing) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.elementGap),
      child: Row(
        children: [
          Icon(LucideIcons.circleCheck, color: color.primary),
          SizedBox(width: spacing.elementGap),
          Expanded(
            child: Text(
              'Nothing needs your attention right now.',
              style: textTheme.bodyMedium?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationRow(
    BuildContext context,
    AppSpacing spacing,
    Recommendation recommendation,
  ) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: '${recommendation.title}. ${recommendation.actionLabel}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            context.push(recommendation.actionRoute);
          },
          borderRadius: spacing.borderRadiusMedium,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: spacing.elementGap),
            child: Row(
              children: [
                Container(
                  width: spacing.touchTargetSmall,
                  height: spacing.touchTargetSmall,
                  decoration: BoxDecoration(
                    color: recommendation.iconColor.withValues(alpha: 0.12),
                    borderRadius: spacing.borderRadiusSmall,
                  ),
                  child: Icon(
                    recommendation.icon,
                    color: recommendation.iconColor,
                    size: spacing.iconMD,
                  ),
                ),
                SizedBox(width: spacing.elementGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: spacing.elementGapMin),
                      Text(
                        recommendation.subtitle ?? recommendation.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: spacing.elementGap),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 104),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(
                        LucideIcons.arrowUpRight,
                        color: color.primary,
                        size: spacing.iconSM,
                      ),
                      SizedBox(height: spacing.elementGapMin),
                      Text(
                        recommendation.actionLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: textTheme.labelSmall?.copyWith(
                          color: color.primary,
                          fontWeight: FontWeight.w800,
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
    );
  }

  Widget _buildAdviceSection(
    BuildContext context,
    AppSpacing spacing, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: spacing.elementGapMin,
              height: spacing.iconMD,
              decoration: BoxDecoration(
                color: color.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: spacing.elementGap),
            Icon(icon, size: spacing.iconSM, color: color.primary),
            SizedBox(width: spacing.elementGapMin),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.elementGapMin,
                vertical: spacing.elementGapUltraMin,
              ),
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${children.length}',
                style: textTheme.labelSmall?.copyWith(
                  color: color.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: spacing.elementGap),
        Container(
          clipBehavior: Clip.antiAlias,
          padding: EdgeInsets.symmetric(horizontal: spacing.cardInner),
          decoration: BoxDecoration(
            color: color.surfaceContainerLow,
            borderRadius: spacing.borderRadiusLarge,
            border: Border.all(
              color: color.outlineVariant.withValues(alpha: 0.26),
            ),
            boxShadow: [
              BoxShadow(
                color: color.onSurface.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1)
                  Divider(
                    height: 1,
                    color: color.outlineVariant.withValues(alpha: 0.22),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttentionItem(
    BuildContext context,
    AppSpacing spacing,
    AttentionItem item,
    bool isFocused, {
    Key? key,
    required VoidCallback onTap,
  }) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final itemColor = _attentionColor(item.type, color);

    return Semantics(
      button: true,
      label: '${item.title}. ${item.message}. ${item.actionLabel}',
      child: Material(
        key: key,
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: spacing.borderRadiusMedium,
          child: AnimatedContainer(
            duration: MediaQuery.of(context).disableAnimations
                ? Duration.zero
                : spacing.animFast,
            padding: EdgeInsets.symmetric(vertical: spacing.elementGap),
            decoration: BoxDecoration(
              color: isFocused
                  ? itemColor.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: spacing.borderRadiusMedium,
            ),
            child: Row(
              children: [
                Container(
                  width: spacing.touchTargetSmall,
                  height: spacing.touchTargetSmall,
                  decoration: BoxDecoration(
                    color: itemColor.withValues(alpha: 0.12),
                    borderRadius: spacing.borderRadiusSmall,
                  ),
                  child: Icon(
                    _attentionIcon(item.type),
                    color: itemColor,
                    size: spacing.iconSM,
                  ),
                ),
                SizedBox(width: spacing.elementGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (item.message.isNotEmpty) ...[
                        SizedBox(height: spacing.elementGapMin),
                        Text(
                          item.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: spacing.elementGap),
                Icon(
                  LucideIcons.arrowUpRight,
                  color: itemColor,
                  size: spacing.iconSM,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(AppSpacing spacing) {
    final color = Theme.of(context).colorScheme;
    final enabled = !MediaQuery.of(context).disableAnimations;

    Widget bone({double? width, required double height}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color.surfaceContainerHighest,
          borderRadius: spacing.borderRadiusSmall,
        ),
      );
    }

    Widget skeletonRow() {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: spacing.elementGap),
        child: Row(
          children: [
            bone(
              width: spacing.touchTargetSmall,
              height: spacing.touchTargetSmall,
            ),
            SizedBox(width: spacing.elementGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bone(height: spacing.elementGap),
                  SizedBox(height: spacing.elementGapMin),
                  bone(width: 164, height: spacing.elementGapMin),
                ],
              ),
            ),
            SizedBox(width: spacing.elementGap),
            bone(width: 56, height: spacing.elementGap),
          ],
        ),
      );
    }

    Widget groupedSkeleton(int rows) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: spacing.cardInner),
        decoration: BoxDecoration(
          color: color.surfaceContainerLow,
          borderRadius: spacing.borderRadiusLarge,
          border: Border.all(
            color: color.outlineVariant.withValues(alpha: 0.26),
          ),
        ),
        child: Column(
          children: [
            for (var index = 0; index < rows; index++) ...[
              skeletonRow(),
              if (index < rows - 1)
                Divider(
                  height: 1,
                  color: color.outlineVariant.withValues(alpha: 0.22),
                ),
            ],
          ],
        ),
      );
    }

    return AutoSkeleton(
      enabled: enabled,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: spacing.cardHorizontal,
          right: spacing.cardHorizontal,
          top: spacing.cardVertical,
          bottom: spacing.cardVertical + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          Container(
            padding: EdgeInsets.all(spacing.cardInner),
            decoration: BoxDecoration(
              color: color.surfaceContainerHighest,
              borderRadius: spacing.borderRadiusLarge,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    bone(
                      width: spacing.iconXL + spacing.elementGap,
                      height: spacing.iconXL + spacing.elementGap,
                    ),
                    SizedBox(width: spacing.elementGap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          bone(width: 124, height: spacing.elementGap),
                          SizedBox(height: spacing.elementGapMin),
                          bone(width: 88, height: spacing.elementGap),
                        ],
                      ),
                    ),
                    bone(width: 52, height: spacing.iconLG),
                  ],
                ),
                SizedBox(height: spacing.cardInner),
                bone(height: spacing.progressNormal),
                SizedBox(height: spacing.cardInner),
                Wrap(
                  spacing: spacing.elementGap,
                  runSpacing: spacing.elementGap,
                  children: [
                    for (var index = 0; index < 5; index++)
                      bone(width: 92, height: spacing.touchTargetSmall),
                  ],
                ),
                SizedBox(height: spacing.cardInner),
                bone(height: 56),
              ],
            ),
          ),
          SizedBox(height: spacing.sectionGap),
          bone(height: 72),
          SizedBox(height: spacing.sectionGap),
          groupedSkeleton(2),
          SizedBox(height: spacing.sectionGap),
          groupedSkeleton(2),
          SizedBox(height: spacing.sectionGap),
          groupedSkeleton(2),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    AppSpacing spacing,
  ) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertCircle, size: 44, color: color.error),
            SizedBox(height: spacing.elementGap),
            Text(
              'Financial advice is unavailable right now.',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium,
            ),
            SizedBox(height: spacing.elementGap),
            FilledButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                ref.invalidate(insightsProvider);
                ref.invalidate(dashboardDataProvider);
                ref.invalidate(todayCardProvider);
                ref.invalidate(adaptiveUtilityProvider);
              },
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBriefMessage(TodayCardState state) {
    return switch (state.signalType!) {
      BriefingSignalType.billDueToday =>
        '${state.signalParams['name']} due today',
      BriefingSignalType.budgetExceeded =>
        '${state.signalParams['name']} over budget',
      BriefingSignalType.spendingDrift =>
        '${state.signalParams['category']} spending high',
      BriefingSignalType.billDueSoon =>
        '${state.signalParams['name']} due in ${state.signalParams['days']} days',
      BriefingSignalType.overspending => 'Spending exceeds income',
      BriefingSignalType.improvement =>
        'Spending is down ${state.signalParams['percent']}%',
    };
  }

  String _formatHealthyDetail(TodayCardState state) {
    if (state.nextBillName == null || state.nextBillDays == null) {
      return 'No urgent issues found today.';
    }

    final days = state.nextBillDays!;
    final timing = days <= 0
        ? 'today'
        : days == 1
            ? 'tomorrow'
            : 'in $days days';
    return 'Next up: ${state.nextBillName} $timing.';
  }

  String _formatActionLabel(TodayCardState state) {
    return switch (state.signalType!) {
      BriefingSignalType.billDueToday => 'Review bills',
      BriefingSignalType.budgetExceeded => 'Review budget',
      BriefingSignalType.spendingDrift => 'View spending pattern',
      BriefingSignalType.billDueSoon => 'View bills',
      BriefingSignalType.overspending => 'View budget',
      BriefingSignalType.improvement => 'Review insight',
    };
  }

  Color _attentionColor(AttentionType type, ColorScheme color) {
    return switch (type) {
      AttentionType.critical => color.error,
      AttentionType.warning => color.tertiary,
      AttentionType.info => color.primary,
      AttentionType.insight => color.primary,
    };
  }

  IconData _attentionIcon(AttentionType type) {
    return switch (type) {
      AttentionType.critical => LucideIcons.alertCircle,
      AttentionType.warning => LucideIcons.alertTriangle,
      AttentionType.info => LucideIcons.info,
      AttentionType.insight => LucideIcons.checkCircle2,
    };
  }
}

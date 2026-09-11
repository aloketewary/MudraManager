import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/field_encryption_service.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/refresh_helper.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/analytics/data/analytics_provider.dart';
import 'package:mudra_manager/features/analytics/data/net_worth_service.dart';
import 'package:mudra_manager/features/analytics/domain/analytics_period.dart';
import 'package:mudra_manager/features/budget/data/budget_alert_provider.dart';
import 'package:mudra_manager/features/category/data/category_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/dashboard_banners.dart';
import 'package:mudra_manager/features/import_export/data/export_plugin.dart';
import 'package:mudra_manager/features/insights/data/insights_provider.dart';
import 'package:mudra_manager/features/insights/domain/recommendation.dart';
import 'package:mudra_manager/features/insights/presentation/widgets/insights_overview.dart';
import 'package:mudra_manager/features/profile/data/user_profile_provider.dart';
import 'package:mudra_manager/features/statistics/presentation/screens/export_options_screen.dart';
import 'package:mudra_manager/features/transactions/data/tag_analytics_provider.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/shared/widgets/period_calendar_selector.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/shared/widgets/type_section_header.dart';

/// Insights Screen - Personal Financial Coach Experience
///
/// UX Journey: Understand → Discover → Predict → Improve → Explore
///
/// Sections:
/// 1. AI Summary - Conversational financial overview
/// 2. Quick Wins - Actionable recommendations (3 max)
/// 3. Financial Health - Score with detailed breakdown
/// 4. Predictions - Cash flow forecast and risk alerts
/// 5. Spending Personality - Behavioral archetype
/// 6. Hidden Patterns - Weekend, late-night, subscription patterns
/// 7. Recommendations - Personalized improvements
/// 8. Deep Dive Analytics - Charts and detailed breakdown
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  PeriodType _selectedPeriod = PeriodType.month;
  DateTime? _customStart;
  DateTime? _customEnd;

  AnalyticsPeriod get _period {
    if (_selectedPeriod == PeriodType.custom &&
        _customStart != null &&
        _customEnd != null) {
      return CustomPeriod(start: _customStart!, end: _customEnd!);
    }
    return switch (_selectedPeriod) {
      PeriodType.day => const TodayPeriod(),
      PeriodType.week => const WeekPeriod(),
      PeriodType.month => const MonthPeriod(),
      PeriodType.year => const YearPeriod(),
      _ => const MonthPeriod(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final alerts = ref.watch(budgetAlertsNotifierProvider);

    return ScreenShell(
      config: ScreenShellConfig(
        appBarMode: AppBarMode.none,
        customAppBar: _InsightsHomeStyleHeader(
          title: l10n.nav_insights,
          periodLabel: periodLabel(
            l10n,
            _selectedPeriod,
            _customStart,
            _customEnd,
          ),
          exportLabel: l10n.common_download,
          spacing: spacing,
          onPeriodTap: () {
            showPeriodPickerSheet(
              context: context,
              spacing: spacing,
              selectedPeriod: _selectedPeriod,
              customStart: _customStart,
              customEnd: _customEnd,
              onChanged: (period, start, end) {
                setState(() {
                  _selectedPeriod = period;
                  _customStart = start;
                  _customEnd = end;
                });
              },
            );
          },
          onExport: () => _showExportDialog(spacing),
        ),
        enableRefresh: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => RefreshHelper.withMinDuration(() async {
          ref.invalidate(dashboardDataProvider);
          ref.invalidate(analyticsAggregatesProvider(_period.key));
          ref.invalidate(analyticsTransferTransactionsProvider(_period.key));
          ref.invalidate(analyticsMetricsProvider(_period.key));
          ref.invalidate(analyticsChartProvider(_period.key));
          ref.invalidate(analyticsNarrativeFactsProvider(_period.key));
          ref.invalidate(categoryTrendsProvider);
          ref.invalidate(
            tagSpendingProvider(
              _period.key.contains('_') ? 'Month' : _period.key,
            ),
          );
          ref.invalidate(predictedSpendingProvider);
          ref.invalidate(netWorthProvider);
          ref.invalidate(netWorthHistoryProvider);
          ref.invalidate(insightsProvider);
        }),
        child: ref.watch(insightsProvider).when(
              data: (insights) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.cardHorizontal,
                    vertical: spacing.cardVertical,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PrioritizedBanner(
                        hasSeenHelp: true,
                        alerts: alerts,
                        pendingSmsCount:
                            dashboardAsync.asData?.value.pendingSmsCount,
                      ),
                      InsightsOverview(
                        insights: insights,
                        periodKey: _period.key,
                        onRecommendationTap: _handleRecommendationTap,
                        onPatternTap: _handlePatternTap,
                      ),
                      const AmbientBrandSection(),
                      SizedBox(
                        height: MediaQuery.of(context).padding.bottom +
                            kBottomNavigationBarHeight,
                      ),
                    ],
                  ),
                );
              },
              loading: () => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontal,
                  vertical: spacing.cardVertical,
                ),
                child: _buildLoadingState(spacing),
              ),
              error: (e, _) => _buildErrorState(
                e,
                color,
                textTheme,
                spacing,
                l10n,
              ),
            ),
      ),
    );
  }

  Widget _buildLoadingState(AppSpacing spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Summary skeleton
        const TypeSectionHeader(
          label: 'Insights',
          icon: LucideIcons.sparkles,
          accentColor: Colors.grey,
        ),
        SizedBox(height: spacing.sectionGap),
        SkeletonLoader(
          width: double.infinity,
          height: 180,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
        ),
        SizedBox(height: spacing.sectionGap),
        // Health score skeleton
        SkeletonLoader(
          width: double.infinity,
          height: 140,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
        ),
        SizedBox(height: spacing.sectionGap),
        // Forecast skeleton
        SkeletonLoader(
          width: double.infinity,
          height: 120,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
        ),
        SizedBox(height: spacing.sectionGap),
        // Analytics skeleton
        SkeletonLoader(
          width: double.infinity,
          height: 200,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
        ),
      ],
    );
  }

  Widget _buildErrorState(
    Object error,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations l10n,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(spacing.cardHorizontalMax),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.circleAlert,
                      size: spacing.iconXL,
                      color: color.error,
                    ),
                    SizedBox(height: spacing.elementGap),
                    Text(
                      l10n.stats_unableToLoad,
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: spacing.elementGapMin),
                    Text(
                      BuddyMessages.errorWith('$error'),
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: color.onSurfaceVariant),
                    ),
                    SizedBox(height: spacing.sectionGap),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        services.HapticFeedback.mediumImpact();
                        ref.invalidate(insightsProvider);
                      },
                      icon: const Icon(LucideIcons.refreshCw, size: 16),
                      label: Text(l10n.common_retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleRecommendationTap(Recommendation recommendation) {
    final target = recommendation.actionRoute;
    final current = GoRouterState.of(context).matchedLocation;

    if (target == current) {
      context.push(
        AppRoutes.financialAdvice,
        extra: {
          'source': 'next_move',
          'focusId': recommendation.id,
        },
      );
      return;
    }

    context.push(target);
  }

  void _handlePatternTap() {
    // Show pattern details
  }

  Future<void> _showExportDialog(AppSpacing spacing) async {
    try {
      // Read the currently selected period on demand. These providers may not
      // be cached yet when the user taps export immediately after screen load.
      final aggregates =
          await ref.read(analyticsAggregatesProvider(_period.key).future);
      final transactions = await ref.read(analyticsTransactionsProvider.future);
      final categories = await ref.read(categoryListProvider.future);
      final profile = await ref.read(userProfileProvider.future);

      if (!mounted) return;

      final periodDates = _period.resolve();
      final periodTransactions = transactions.where((tx) {
        return !tx.date.isBefore(periodDates.start) &&
            !tx.date.isAfter(periodDates.end);
      }).toList();

      final categoryDataMap = {for (final c in categories) c.name: c};

      await showDialog<void>(
        context: context,
        builder: (_) => Dialog.fullscreen(
          child: ExportOptionsScreen(
            exportData: ExportData(
              income: aggregates.totalIncome,
              expense: aggregates.totalExpense,
              savingsRate: aggregates.savingsRate,
              avgDailySpend: aggregates.avgDailySpend,
              transactions: periodTransactions,
              categoryData: aggregates.categoryBreakdown,
              categoryDataMap: categoryDataMap,
              startDate: periodDates.start,
              endDate: periodDates.end,
              userName: FieldEncryptionService.safeDisplay(profile?.name),
            ),
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        SnackbarService.error(BuddyMessages.errorWith('$error'), spacing);
      }
    }
  }
}

class _InsightsHomeStyleHeader extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final String periodLabel;
  final String exportLabel;
  final AppSpacing spacing;
  final VoidCallback onPeriodTap;
  final VoidCallback onExport;

  const _InsightsHomeStyleHeader({
    required this.title,
    required this.periodLabel,
    required this.exportLabel,
    required this.spacing,
    required this.onPeriodTap,
    required this.onExport,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: color.surfaceContainerHigh,
      foregroundColor: color.onSurface,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.surfaceContainerHigh,
              color.primaryContainer.withValues(alpha: 0.72),
            ],
          ),
        ),
      ),
      scrolledUnderElevation: 0,
      toolbarHeight: 80,
      titleSpacing: spacing.cardInner,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(spacing.radiusLarge + spacing.elementGap),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: spacing.elementGapMin),
          Material(
            color: color.surface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            child: InkWell(
              onTap: () {
                services.HapticFeedback.mediumImpact();
                onPeriodTap();
              },
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.elementGap,
                  vertical: spacing.elementGapMin,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.58,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.calendarDays,
                        size: spacing.iconXS,
                        color: color.primary,
                      ),
                      SizedBox(width: spacing.elementGapMin),
                      Flexible(
                        child: Text(
                          periodLabel,
                          style: textTheme.labelMedium?.copyWith(
                            color: color.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: spacing.elementGapMin),
                      Icon(
                        LucideIcons.chevronDown,
                        size: spacing.iconXS,
                        color: color.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: spacing.cardInner),
          child: IconButton(
            tooltip: exportLabel,
            onPressed: () {
              services.HapticFeedback.mediumImpact();
              onExport();
            },
            icon: const Icon(LucideIcons.download),
            style: IconButton.styleFrom(
              foregroundColor: color.onSurface,
              backgroundColor: color.surfaceContainerHighest,
              minimumSize: Size.square(spacing.touchTargetSmall),
              maximumSize: Size.square(spacing.touchTargetSmall),
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
            ),
          ),
        ),
      ],
    );
  }
}

// Extension for PeriodType
extension PeriodTypeExtension on PeriodType {
  static const _values = {
    PeriodType.day: 'Today',
    PeriodType.week: 'Week',
    PeriodType.month: 'Month',
    PeriodType.year: 'Year',
    PeriodType.custom: 'Custom',
  };

  String get key => _values[this] ?? 'Month';
}

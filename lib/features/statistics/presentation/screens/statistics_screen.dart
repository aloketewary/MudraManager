import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/field_encryption_service.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/refresh_helper.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/analytics/data/analytics_provider.dart';
import 'package:mudra_manager/features/analytics/data/net_worth_service.dart';
import 'package:mudra_manager/features/analytics/domain/analytics_period.dart';
import 'package:mudra_manager/features/category/data/category_provider.dart';
import 'package:mudra_manager/features/import_export/data/export_plugin.dart';
import 'package:mudra_manager/features/insights/data/insights_provider.dart';
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

    return ScreenShell(
      config: ScreenShellConfig(
        title: l10n.nav_insights,
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      actions: ScreenActions.build(
        appBar: [
          ScreenAction(
            id: 'export',
            label: l10n.common_download,
            icon: LucideIcons.download,
            onTap: () {
              HapticFeedback.mediumImpact();
              _showExportDialog(spacing, l10n);
            },
          ),
        ],
        trailing: ScreenTextAction(
          id: 'period_selector',
          label: periodLabel(l10n, _selectedPeriod, _customStart, _customEnd),
          onTap: () {
            HapticFeedback.mediumImpact();
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
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => RefreshHelper.withMinDuration(() async {
          ref.invalidate(analyticsAggregatesProvider(_period.key));
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
                        HapticFeedback.mediumImpact();
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

  void _handleRecommendationTap() {
    // Navigate to recommendation action
  }

  void _handlePatternTap() {
    // Show pattern details
  }

  void _showExportDialog(AppSpacing spacing, AppLocalizations l10n) {
    // Read aggregates for the *currently selected* period — insightsProvider
    // is always pinned to 'Month' internally, so it can't be reused here.
    final aggregates = ref.read(analyticsAggregatesProvider(_period.key)).value;
    final transactions = ref.read(analyticsTransactionsProvider).value;
    final categories = ref.read(categoryListProvider).value;
    final profile = ref.read(userProfileProvider).value;

    if (aggregates == null || transactions == null || categories == null) {
      SnackbarService.info(l10n.common_loading, spacing);
      return;
    }

    final periodDates = _period.resolve();
    final periodTransactions = transactions.where((tx) {
      return !tx.date.isBefore(periodDates.start) &&
          !tx.date.isAfter(periodDates.end);
    }).toList();

    final categoryDataMap = {for (final c in categories) c.name: c};

    showDialog(
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

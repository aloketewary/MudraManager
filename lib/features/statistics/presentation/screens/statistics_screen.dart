import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/features/dashboard/data/status_data_provider.dart';
import 'package:mudra_manager/features/statistics/presentation/widgets/widgets.dart';
import 'package:mudra_manager/shared/templates/analytics_view_template.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/shared/widgets/period_calendar_selector.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  String _period = 'Month';
  PeriodType _selectedPeriod = PeriodType.month;
  DateTime? _customStart;
  DateTime? _customEnd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final spacing = ref.watch(spacingProvider);

    final stats = _selectedPeriod == PeriodType.custom &&
            _customStart != null &&
            _customEnd != null
        ? ref.watch(
            customStatsProvider(
              '${_customStart!.millisecondsSinceEpoch}_${_customEnd!.millisecondsSinceEpoch}',
            ),
          )
        : ref.watch(statsProvider(_period));

    return ScreenShell(
      config: ScreenShellConfig(
        titleWidget: Padding(
          padding: EdgeInsets.only(right: spacing.cardHorizontal),
          child: PeriodCalendarSelector(
            selectedPeriod: _selectedPeriod,
            customStart: _customStart,
            customEnd: _customEnd,
            spacing: spacing,
            onChanged: (period, start, end) {
              setState(() {
                _selectedPeriod = period;
                _customStart = start;
                _customEnd = end;
                _period = period == PeriodType.day
                    ? l10n.stats_today
                    : period == PeriodType.week
                        ? l10n.stats_week
                        : period == PeriodType.month
                            ? l10n.stats_month
                            : period == PeriodType.year
                                ? l10n.stats_year
                                : l10n.stats_custom;
              });
            },
          ),
        ),
        appBarMode: AppBarMode.standard,
        toolbarHeight: 80,
      ),
      body: stats.when(
        data: (d) {
          final hasData =
              d.income > 0 || d.expense > 0 || d.categoryData.isNotEmpty;
          if (!hasData) {
            return Center(
              child: NoDataFound(
                message: BuddyMessages.noTransactions,
                iconData: LucideIcons.chartBar,
              ),
            );
          }

          return AnalyticsViewTemplate(
            timeSelector:
                const SizedBox.shrink(), // Handled in ScreenShell title
            chart: const StatisticsChartSection(),
            metricSummary: StatisticsMetricsSection(data: d),
            content: [
              StatisticsInsightsSection(data: d),
              SpendingTagsSection(period: _period),
              const FinancialBehaviorSection(),
              const AmbientBrandSection(),
            ],
          );
        },
        loading: () => _buildLoading(spacing),
        error: (_, __) => Center(child: Text(BuddyMessages.genericError)),
      ),
    );
  }

  Widget _buildLoading(AppSpacing spacing) {
    return Padding(
      padding: EdgeInsets.all(spacing.cardHorizontal),
      child: Column(
        children: [
          SkeletonLoader(
            width: double.infinity,
            height: 250,
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
          ),
          SizedBox(height: spacing.sectionGap),
          Row(
            children: [
              Expanded(
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 120,
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                ),
              ),
              SizedBox(width: spacing.elementGap),
              Expanded(
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 120,
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

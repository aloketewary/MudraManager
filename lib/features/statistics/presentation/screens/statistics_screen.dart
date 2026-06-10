import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/features/analytics/data/analytics_provider.dart';
import 'package:mudra_manager/features/analytics/domain/analytics_period.dart';
import 'package:mudra_manager/features/analytics/presentation/widgets/widgets.dart';
import 'package:mudra_manager/shared/templates/analytics_view_template.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/shared/widgets/period_calendar_selector.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';

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
              });
            },
          ),
        ),
        appBarMode: AppBarMode.standard,
        toolbarHeight: 80,
      ),
      body: ref.watch(analyticsAggregatesProvider(_period.key)).when(
            data: (aggregates) {
              return AnalyticsViewTemplate(
                timeSelector: const SizedBox.shrink(),
                chart: StatisticsChartSection(periodKey: _period.key),
                metricSummary: StatisticsMetricsSection(periodKey: _period.key),
                content: [
                  StatisticsInsightsSection(periodKey: _period.key),
                  SpendingTagsSection(periodKey: _period.key),
                  const FinancialBehaviorSection(),
                  const AmbientBrandSection(),
                ],
              );
            },
            loading: () => _buildLoading(spacing),
            error: (e, _) => Center(child: Text(BuddyMessages.genericError)),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

/// Template E — Analytics View
///
/// Used for: charts, trends, history, spending analysis.
/// Structure:
///   - Time window selector
///   - Chart/visualization area
///   - Optional metric summary row
///   - No alerts. No interpretation. Only data.
///
/// This template ONLY renders. No logic.
class AnalyticsViewTemplate extends ConsumerWidget {
  /// Time window selector widget (month picker, date range, etc).
  final Widget timeSelector;

  /// Primary chart or visualization.
  final Widget chart;

  /// Optional summary metrics below the chart.
  final Widget? metricSummary;

  /// Optional additional content sections below.
  final List<Widget> content;

  /// Whether data is loading.
  final bool isLoading;

  const AnalyticsViewTemplate({
    super.key,
    required this.timeSelector,
    required this.chart,
    this.metricSummary,
    this.content = const [],
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    return CustomScrollView(
      slivers: [
        // Time window
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
            child: timeSelector,
          ),
        ),

        // Chart
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing.cardHorizontal),
            child: chart,
          ),
        ),

        // Metric summary
        if (metricSummary != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontal,
                vertical: spacing.elementGap,
              ),
              child: metricSummary,
            ),
          ),

        // Additional content
        if (content.isNotEmpty)
          SliverList(
            delegate: SliverChildListDelegate(
              content.map((w) => Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.cardHorizontal,
                      vertical: spacing.elementGapMin,
                    ),
                    child: w,
                  ),).toList(),
            ),
          ),
      ],
    );
  }
}

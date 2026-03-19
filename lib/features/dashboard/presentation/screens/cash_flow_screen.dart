import 'package:go_router/go_router.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mudra_manager/core/db/filter_type.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/filter_provider.dart';
import 'package:mudra_manager/features/dashboard/data/historical_data_provider.dart';
import 'package:mudra_manager/shared/widgets/animated_balance.dart';
import 'package:mudra_manager/shared/widgets/period_calendar_selector.dart';
import 'package:mudra_manager/shared/widgets/responseive_layout_builder.dart';
import 'package:mudra_manager/shared/widgets/trend_indicator.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class CashFlowScreen extends ConsumerStatefulWidget {
  final double globalPadding;
  final PeriodType selectedPeriod;
  final DateTime? customStart;
  final DateTime? customEnd;

  const CashFlowScreen({
    super.key,
    this.globalPadding = 16.0,
    required this.selectedPeriod,
    this.customStart,
    this.customEnd,
  });

  @override
  ConsumerState<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends ConsumerState<CashFlowScreen> {
  double leftBoxWidthFactor = 0.5;
  double rightBoxWidthFactor = 0.5;
  double tiltAngleDegrees = 20.0;
  double tiltExpenseAngleDegrees = 20.0;

  @override
  Widget build(BuildContext context) {
    final isGuestMode = ref.watch(guestModeProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final filter = widget.selectedPeriod == PeriodType.day
        ? FilterType.day
        : widget.selectedPeriod == PeriodType.week
            ? FilterType.week
            : widget.selectedPeriod == PeriodType.month
                ? FilterType.month
                : widget.selectedPeriod == PeriodType.year
                    ? FilterType.year
                    : FilterType.all;
    final now = DateTime.now();
    final ctxt = AppLocalizations.of(context)!;

    DateTime startDate;
    DateTime endDate;

    if (widget.selectedPeriod == PeriodType.custom &&
        widget.customStart != null &&
        widget.customEnd != null) {
      startDate = widget.customStart!;
      endDate = widget.customEnd!;
    } else {
      switch (filter) {
        case FilterType.day:
          startDate = DateTime(now.year, now.month, now.day);
          endDate = startDate;
          break;
        case FilterType.week:
          startDate = now.subtract(Duration(days: now.weekday - 1));
          endDate = startDate.add(const Duration(days: 6));
          break;
        case FilterType.month:
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(
            now.year,
            now.month + 1,
            1,
          ).subtract(const Duration(days: 1));
          break;
        case FilterType.year:
          startDate = DateTime(now.year, 1, 1);
          endDate = DateTime(
            now.year + 1,
            1,
            1,
          ).subtract(const Duration(days: 1));
          break;
        case FilterType.all:
          startDate = DateTime.fromMillisecondsSinceEpoch(0);
          endDate = now;
          break;
      }
    }

    final summary = widget.selectedPeriod == PeriodType.custom &&
            widget.customStart != null &&
            widget.customEnd != null
        ? ref.watch(
            customDateRangeTransactionsProvider(
              '${widget.customStart!.millisecondsSinceEpoch}_${widget.customEnd!.millisecondsSinceEpoch}',
            ),
          )
        : ref.watch(
            periodBasedTransactionsProvider(
              widget.selectedPeriod == PeriodType.day
                  ? 'day'
                  : widget.selectedPeriod == PeriodType.week
                      ? 'week'
                      : widget.selectedPeriod == PeriodType.month
                          ? 'month'
                          : widget.selectedPeriod == PeriodType.year
                              ? 'year'
                              : 'month',
            ),
          );

    final previousPeriod = widget.selectedPeriod == PeriodType.day
        ? 'day'
        : widget.selectedPeriod == PeriodType.week
            ? 'week'
            : widget.selectedPeriod == PeriodType.month
                ? 'month'
                : widget.selectedPeriod == PeriodType.year
                    ? 'year'
                    : 'month';
    final prevSummary = ref.watch(
      previousPeriodTransactionsProvider(previousPeriod),
    );
    return summary.when(
      skipLoadingOnReload: true,
      data: (data) {
        final rawIncome = data['income'] ?? 0.0;
        final rawExpense = data['expense'] ?? 0.0;
        final rawPrevIncome = prevSummary.value?['income'] ?? 0.0;
        final rawPrevExpense = prevSummary.value?['expense'] ?? 0.0;
        final income = GuestModeUtil.applyGuestMode(rawIncome, isGuestMode);
        final expense = GuestModeUtil.applyGuestMode(rawExpense, isGuestMode);
        final prevIncome =
            GuestModeUtil.applyGuestMode(rawPrevIncome, isGuestMode);
        final prevExpense =
            GuestModeUtil.applyGuestMode(rawPrevExpense, isGuestMode);
        return Padding(
          padding: EdgeInsets.all(widget.globalPadding),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  context.push(AppRoutes.transactions);
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
                  child: Row(
                    children: [
                      Icon(LucideIcons.wallet, color: color.primary),
                      const SizedBox(width: 8),
                      Text(
                        ctxt.dashboard_cash_flow_text,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color.primary,
                        ),
                      ),
                      const Spacer(),
                      Icon(LucideIcons.chevronRight,
                          color: color.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
              ResponsiveLayoutBuilder(
                columnWidget: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildCashFlowCard(
                      false,
                      income,
                      startDate,
                      endDate,
                      filter,
                      prevIncome,
                    ),
                    const SizedBox(height: 12),
                    buildCashFlowCard(
                      true,
                      expense,
                      startDate,
                      endDate,
                      filter,
                      prevExpense,
                    ),
                  ],
                ),
                rowWidget: Row(
                  children: [
                    buildCashFlowCard(
                      false,
                      income,
                      startDate,
                      endDate,
                      filter,
                      prevIncome,
                    ),
                    const SizedBox(width: 12),
                    buildCashFlowCard(
                      true,
                      expense,
                      startDate,
                      endDate,
                      filter,
                      prevExpense,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Padding(
        padding: EdgeInsets.all(widget.globalPadding),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
              child: Row(
                children: [
                  SkeletonLoader(
                      width: 24,
                      height: 24,
                      borderRadius: BorderRadius.circular(4)),
                  const SizedBox(width: 8),
                  SkeletonLoader(
                      width: 120,
                      height: 20,
                      borderRadius: BorderRadius.circular(4)),
                ],
              ),
            ),
            ResponsiveLayoutBuilder(
              columnWidget: Column(
                children: [
                  SkeletonLoader(
                      width: double.infinity,
                      height: 170,
                      borderRadius: BorderRadius.circular(12)),
                  const SizedBox(height: 12),
                  SkeletonLoader(
                      width: double.infinity,
                      height: 170,
                      borderRadius: BorderRadius.circular(12)),
                ],
              ),
              rowWidget: Row(
                children: [
                  Expanded(
                      child: SkeletonLoader(
                          width: double.infinity,
                          height: 170,
                          borderRadius: BorderRadius.circular(12))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: SkeletonLoader(
                          width: double.infinity,
                          height: 170,
                          borderRadius: BorderRadius.circular(12))),
                ],
              ),
            ),
          ],
        ),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget buildCashFlowCard(
    bool isExpense,
    double value,
    DateTime startDate,
    DateTime endDate,
    FilterType filter,
    double previousValue,
  ) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    final tiltAngleRadians = math.pi * tiltAngleDegrees / 180;
    final tiltExpenseAngleRadians = math.pi * tiltExpenseAngleDegrees / 180;

    return Expanded(
      child: SizedBox(
        height: 170,
        child: Semantics(
          label:
              '${isExpense ? "Expense" : "Income"}: ${ctxt.formatCurrencyWithSign(0, value)}',
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
            },
            child: Card(
              elevation: 0,
              color: isExpense ? color.errorContainer : color.primaryContainer,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  HapticFeedback.mediumImpact();
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      !isExpense
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: color.primary.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Transform.rotate(
                                    angle: tiltAngleRadians,
                                    child: Icon(
                                      LucideIcons.arrowDown,
                                      size: 16,
                                      color: color.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6.0),
                                Flexible(
                                  child: Text(
                                    ctxt.transaction_type_income.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: textTheme.labelMedium?.copyWith(
                                      color: color.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (previousValue > 0) ...[
                                  const SizedBox(width: 6.0),
                                  TrendIndicator(
                                    current: value,
                                    previous: previousValue,
                                    isIncome: !isExpense,
                                  ),
                                ],
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                if (previousValue > 0) ...[
                                  TrendIndicator(
                                    current: value,
                                    previous: previousValue,
                                    isIncome: !isExpense,
                                  ),
                                  const SizedBox(width: 6.0),
                                ],
                                Flexible(
                                  child: Text(
                                    ctxt.transaction_type_expense.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: textTheme.labelMedium?.copyWith(
                                      color: color.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6.0),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: color.error.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Transform.rotate(
                                    angle: tiltExpenseAngleRadians,
                                    child: Icon(
                                      LucideIcons.arrowUp,
                                      size: 16,
                                      color: color.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      Flexible(
                        child: Container(
                          height: 80,
                          alignment: Alignment.centerLeft,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Consumer(
                                  builder: (context, ref, child) {
                                    final historyAsync = ref.watch(
                                      isExpense
                                          ? historicalExpenseProvider
                                          : historicalIncomeProvider,
                                    );
                                    return historyAsync.when(
                                      data: (history) {
                                        if (history.isEmpty) {
                                          return const SizedBox();
                                        }
                                        // If all values are zero, show a flat line at bottom
                                        if (history.every((v) => v == 0)) {
                                          final spots =
                                              history.asMap().entries.map((e) {
                                            return FlSpot(
                                                e.key.toDouble(), 10.0);
                                          }).toList();
                                          return LineChart(
                                            LineChartData(
                                              gridData:
                                                  const FlGridData(show: false),
                                              titlesData: const FlTitlesData(
                                                  show: false),
                                              borderData:
                                                  FlBorderData(show: false),
                                              lineTouchData:
                                                  const LineTouchData(
                                                      enabled: false),
                                              lineBarsData: [
                                                LineChartBarData(
                                                  spots: spots,
                                                  isCurved: true,
                                                  color: (isExpense
                                                          ? color.error
                                                          : color.primary)
                                                      .withValues(alpha: 0.15),
                                                  barWidth: 2,
                                                  dotData: const FlDotData(
                                                      show: false),
                                                  belowBarData: BarAreaData(
                                                    show: true,
                                                    color: (isExpense
                                                            ? color.error
                                                            : color.primary)
                                                        .withValues(
                                                            alpha: 0.05),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                        final maxVal = history
                                            .reduce((a, b) => a > b ? a : b);
                                        final minVal = history
                                            .reduce((a, b) => a < b ? a : b);
                                        final range = maxVal - minVal;
                                        final spots =
                                            history.asMap().entries.map((e) {
                                          final normalized = range > 0
                                              ? ((e.value - minVal) / range) *
                                                      40 +
                                                  10
                                              : 25;
                                          return FlSpot(e.key.toDouble(),
                                              normalized.toDouble());
                                        }).toList();
                                        return LineChart(
                                          LineChartData(
                                            gridData:
                                                const FlGridData(show: false),
                                            titlesData:
                                                const FlTitlesData(show: false),
                                            borderData:
                                                FlBorderData(show: false),
                                            lineTouchData: const LineTouchData(
                                                enabled: false),
                                            lineBarsData: [
                                              LineChartBarData(
                                                spots: spots,
                                                isCurved: true,
                                                color: (isExpense
                                                        ? color.error
                                                        : color.primary)
                                                    .withValues(alpha: 0.15),
                                                barWidth: 2,
                                                dotData: const FlDotData(
                                                    show: false),
                                                belowBarData: BarAreaData(
                                                  show: true,
                                                  color: (isExpense
                                                          ? color.error
                                                          : color.primary)
                                                      .withValues(alpha: 0.05),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      loading: () => const SizedBox(),
                                      error: (_, __) => const SizedBox(),
                                    );
                                  },
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: AnimatedBalance(
                                  value: value,
                                  style: textTheme.titleMedium?.copyWith(
                                    color:
                                        isExpense ? color.error : color.primary,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  fixedStringLength: 0,
                                  overflow: TextOverflow.fade,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        FilterType.day == filter
                            ? DateFormat(
                                'dd MMM yy',
                                ctxt.localeName,
                              ).format(startDate)
                            : "${DateFormat("dd MMM yy", ctxt.localeName).format(startDate)} - ${DateFormat("dd MMM yy", ctxt.localeName).format(endDate)}",
                        style: textTheme.labelSmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/filter_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/features/dashboard/data/historical_data_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/shared/widgets/animated_balance.dart';
import 'package:mudra_manager/shared/widgets/widgets.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:fl_chart/fl_chart.dart';

class ModernCashFlowCard extends ConsumerWidget {
  const ModernCashFlowCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final isGuestMode = ref.watch(guestModeProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(
      now.year,
      now.month + 1,
      1,
    ).subtract(const Duration(days: 1));

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: color.surfaceContainerLow,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            context.push(AppRoutes.transactions);
          },
          borderRadius: BorderRadius.circular(spacing.radiusSmall),
          child: Semantics(
            button: true,
            label:
                '${ctxt.dashboard_cash_flow_text}. ${ctxt.dashboard_viewAllLabel}',
            child: Padding(
              padding: EdgeInsets.all(spacing.cardInner),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ctxt.dashboard_cash_flow_text,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${DateFormat('dd', ctxt.localeName).format(startDate)} - ${DateFormat('dd MMM', ctxt.localeName).format(endDate)}',
                              style: textTheme.bodySmall?.copyWith(
                                color: color.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        LucideIcons.chevronRight,
                        color: color.onSurfaceVariant,
                        size: 18,
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.sectionGap),

                  // ── Income / Expense row ──
                  Consumer(
                    builder: (context, ref, child) {
                      final rawIncome = ref.watch(dashboardIncomeProvider);
                      final rawExpense = ref.watch(dashboardExpenseProvider);
                      final income =
                          GuestModeUtil.applyGuestMode(rawIncome, isGuestMode);
                      final expense =
                          GuestModeUtil.applyGuestMode(rawExpense, isGuestMode);
                      final prevSummary = ref.watch(
                        previousPeriodTransactionsProvider('month'),
                      );
                      final rawPrevIncome = prevSummary.value?['income'] ?? 0.0;
                      final rawPrevExpense =
                          prevSummary.value?['expense'] ?? 0.0;
                      final prevIncome = GuestModeUtil.applyGuestMode(
                          rawPrevIncome, isGuestMode);
                      final prevExpense = GuestModeUtil.applyGuestMode(
                          rawPrevExpense, isGuestMode);

                      final historicalIncome =
                          ref.watch(historicalIncomeProvider).value ?? [];
                      final historicalExpense =
                          ref.watch(historicalExpenseProvider).value ?? [];

                      return Row(
                        children: [
                          Expanded(
                            child: _buildCompactSection(
                              isExpense: false,
                              amount: income,
                              previousValue: prevIncome,
                              data: historicalIncome,
                              context: context,
                              spacing: spacing,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: color.outlineVariant.withValues(alpha: 0.5),
                          ),
                          SizedBox(width: spacing.elementGap),
                          Expanded(
                            child: _buildCompactSection(
                              isExpense: true,
                              amount: expense,
                              previousValue: prevExpense,
                              data: historicalExpense,
                              context: context,
                              spacing: spacing,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSection({
    required bool isExpense,
    required double amount,
    required double previousValue,
    required List<double> data,
    required BuildContext context,
    required AppSpacing spacing,
  }) {
    final ctxt = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final accent = isExpense
        ? FinanceColors.expenseColor(brightness)
        : FinanceColors.incomeColor(brightness);

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    return Stack(
      children: [
        // Sparkline chart behind
        if (spots.length >= 2)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(left: 48, bottom: 36),
              child: IgnorePointer(
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.4,
                        preventCurveOverShooting: true,
                        color: accent.withValues(alpha: 0.4),
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              accent.withValues(alpha: 0.15),
                              accent.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineTouchData: const LineTouchData(enabled: false),
                  ),
                ),
              ),
            ),
          ),
        // Content on top
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isExpense ? LucideIcons.arrowUp : LucideIcons.arrowDown,
                  size: 12,
                  color: accent,
                ),
                SizedBox(width: spacing.elementGapMin),
                Text(
                  isExpense
                      ? ctxt.transaction_type_expense
                      : ctxt.transaction_type_income,
                  style: textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.elementGapMin),
            AnimatedBalance(
              value: amount,
              style: textTheme.headlineMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
              fixedStringLength: 0,
            ),
            if (previousValue > 0) ...[
              const SizedBox(height: 2),
              TrendIndicator(
                current: amount,
                previous: previousValue,
                isIncome: !isExpense,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

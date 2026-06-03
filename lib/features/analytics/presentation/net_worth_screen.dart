import 'package:mudra_manager/core/utils/safe_date_format.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/shared/widgets/stat_panel_card.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/refresh_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/features/analytics/data/net_worth_service.dart';
import 'package:mudra_manager/core/extension/account_type_extenstion.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mudra_manager/shared/widgets/widgets.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';

class NetWorthScreen extends ConsumerWidget {
  const NetWorthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final netWorthAsync = ref.watch(netWorthProvider);
    final historyAsync = ref.watch(netWorthHistoryProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final ctxt = AppLocalizations.of(context)!;

    return ScreenShell(
      config: ScreenShellConfig(
        title: AppLocalizations.of(context)!.title_netWorth,
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      actions: ScreenActions.empty,
      body: netWorthAsync.when(
        data: (data) {
          if (data.assets.isEmpty && data.liabilities.isEmpty) {
            return NoDataFound(
              message: BuddyMessages.noAccounts,
              iconData: LucideIcons.wallet,
            );
          }

          return RefreshIndicator(
            onRefresh: () => RefreshHelper.withMinDuration(() async {
              ref.invalidate(netWorthProvider);
              ref.invalidate(netWorthHistoryProvider);
            }),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontal,
                vertical: spacing.cardVertical,
              ),
              children: [
                _buildHeroCard(data, color, textTheme, spacing, isDark, ctxt,),
                SizedBox(height: spacing.sectionGap),
                _sectionHeader('30-Day Trend', LucideIcons.chartLine, color, textTheme),
                const SizedBox(height: 10),
                _buildTrendCard(historyAsync, color, textTheme, spacing, ctxt,),
                SizedBox(height: spacing.sectionGap),
                _buildQuickStats(data, color, textTheme, spacing, brightness, ctxt,),
                SizedBox(height: spacing.sectionGap),
                _sectionHeader(ctxt.netWorth_composition, LucideIcons.chartPie, color, textTheme,),
                const SizedBox(height: 10),
                _buildCompositionCard(data, color, textTheme, spacing, brightness, ctxt,),
                SizedBox(height: spacing.sectionGap),
                if (data.assets.isNotEmpty) ...[
                  _sectionHeader(ctxt.netWorth_assets, LucideIcons.trendingUp, color, textTheme),
                  const SizedBox(height: 10),
                  _buildAccountsCard(data.assets, data.totalAssets, color, textTheme, spacing, isAsset: true),
                  SizedBox(height: spacing.sectionGap),
                ],
                if (data.liabilities.isNotEmpty) ...[
                  _sectionHeader(ctxt.netWorth_liabilities, LucideIcons.trendingDown, color, textTheme),
                  const SizedBox(height: 10),
                  _buildAccountsCard(data.liabilities, data.totalLiabilities, color, textTheme, spacing, isAsset: false),
                  SizedBox(height: spacing.sectionGap),
                ],
                const AmbientBrandSection(),
              ],
            ),
          );
        },
        loading: () => ListView(
          children: List.generate(3, (_) => const DashboardCardSkeleton()),
        ),
        error: (_, __) => Center(child: Text(BuddyMessages.genericError)),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, ColorScheme color, TextTheme textTheme) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color.primary),
        const SizedBox(width: 8),
        Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: color.primary)),
      ],
    );
  }

  // ── HERO CARD ──

  Widget _buildHeroCard(
    NetWorthData data,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    bool isDark,
    AppLocalizations ctxt,
  ) {
    final isPositive = data.monthlyChange >= 0;
    final changeColor = isPositive ? color.primary : color.error;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.primary.withValues(alpha: isDark ? 0.15 : 0.08),
            color.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
      padding: EdgeInsets.all(spacing.cardInner + spacing.elementGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ctxt.netWorth_totalLabel,
            style: textTheme.labelLarge?.copyWith(
              color: color.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: spacing.elementGapMin),
          CurrencyText(
            amount: data.netWorth,
            compact: false,
            showSign: true,
            fixedLength: 0,
            style: textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
            showPositiveSign: false,
          ),
          SizedBox(height: spacing.elementGap),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.elementGap,
                  vertical: spacing.elementGapMin,
                ),
                decoration: BoxDecoration(
                  color: changeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                      size: 14,
                      color: changeColor,
                    ),
                    const SizedBox(width: 4),
                    CurrencyText(
                      amount: data.monthlyChange.abs(),
                      compact: false,
                      showSign: false,
                      fixedLength: 0,
                      style: textTheme.labelMedium?.copyWith(
                        color: changeColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: spacing.elementGap),
              Text(
                'this month',
                style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 30-DAY TREND CHART ──

  Widget _buildTrendCard(
    AsyncValue<List<NetWorthHistoryPoint>> historyAsync,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: historyAsync.when(
          data: (history) {
            if (history.length < 2) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    ctxt.netWorth_notEnoughData,
                    style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
                  ),
                ),
              );
            }
            return _buildFullChart(history, color, textTheme, spacing);
          },
          loading: () => const SizedBox(height: 200),
          error: (_, __) => const SizedBox(height: 200),
        ),
      ),
    );
  }

  Widget _buildFullChart(
    List<NetWorthHistoryPoint> history,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final spots = history
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.netWorth))
        .toList();

    final values = history.map((e) => e.netWorth).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range > 0 ? range * 0.1 : maxY.abs() * 0.1;
    final chartMinY = minY - padding;
    final chartMaxY = maxY + padding;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: chartMinY,
          maxY: chartMaxY,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: range > 0 ? range / 3 : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: color.outlineVariant.withValues(alpha: 0.2),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: (history.length / 5).ceilToDouble().clamp(1, 30),
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= history.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      safeDateFormat('d MMM', 'en').format(history[i].date),
                      style: textTheme.labelSmall?.copyWith(
                        color: color.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 58,
                interval: range > 0 ? range / 3 : 1,
                getTitlesWidget: (value, meta) {
                  if (value == chartMinY || value == chartMaxY) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      formatCurrencyCompact(value),
                      style: textTheme.labelSmall?.copyWith(
                        color: color.onSurfaceVariant,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => color.surfaceContainerHighest,
              getTooltipItems: (spots) => spots.map((spot) {
                final i = spot.x.toInt();
                final date = i >= 0 && i < history.length
                    ? safeDateFormat('dd MMM', 'en').format(history[i].date)
                    : '';
                return LineTooltipItem(
                  '$date\n${formatCurrencyCompact(spot.y)}',
                  textTheme.labelSmall?.copyWith(
                    color: color.onSurface,
                    fontWeight: FontWeight.w600,
                  ) ?? const TextStyle(),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              preventCurveOverShooting: true,
              color: color.primary,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) {
                  if (spot.x == spots.last.x) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: color.primary,
                      strokeWidth: 2,
                      strokeColor: color.surface,
                    );
                  }
                  return FlDotCirclePainter(
                    radius: 0,
                    color: Colors.transparent,
                    strokeWidth: 0,
                    strokeColor: Colors.transparent,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.primary.withValues(alpha: 0.15),
                    color.primary.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── QUICK STATS ──

  Widget _buildQuickStats(
    NetWorthData data,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    Brightness brightness,
    AppLocalizations ctxt,
  ) {
    return Row(
      children: [
        Expanded(
          child: StatPanelCard(
            label: ctxt.netWorth_assets,
            amount: data.totalAssets,
            icon: LucideIcons.arrowDown,
            accent: FinanceColors.incomeColor(brightness),
          ),
        ),
        SizedBox(width: spacing.elementGap),
        Expanded(
          child: StatPanelCard(
            label: ctxt.netWorth_liabilities,
            amount: data.totalLiabilities,
            icon: LucideIcons.arrowUp,
            accent: FinanceColors.expenseColor(brightness),
            trendInverted: true,
          ),
        ),
      ],
    );
  }

  // ── COMPOSITION — donut ring ──

  Widget _buildCompositionCard(
    NetWorthData data,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    Brightness brightness,
    AppLocalizations ctxt,
  ) {
    final totalAssets = data.totalAssets;
    final totalLiabilities = data.totalLiabilities;
    final total = totalAssets + totalLiabilities;
    final assetPct = total > 0 ? (totalAssets / total * 100) : 50.0;
    final liabilityPct = total > 0 ? (totalLiabilities / total * 100) : 50.0;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner + spacing.elementGap),
        child: Row(
          children: [
            // Donut chart
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 30,
                      startDegreeOffset: -90,
                      sections: [
                        PieChartSectionData(
                          value: totalAssets > 0 ? totalAssets : 0.01,
                          color: FinanceColors.incomeColor(brightness),
                          radius: 16,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: totalLiabilities > 0 ? totalLiabilities : 0.01,
                          color: FinanceColors.expenseColor(brightness),
                          radius: 16,
                          showTitle: false,
                        ),
                      ],
                    ),
                  ),
                  // Center label
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${assetPct.toStringAsFixed(0)}%',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: FinanceColors.incomeColor(brightness),
                          height: 1,
                        ),
                      ),
                      Text(
                        'assets',
                        style: textTheme.labelSmall?.copyWith(
                          color: color.onSurfaceVariant,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: spacing.sectionGap),
            // Legend
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendRow(
                    ctxt.netWorth_assets,
                    assetPct,
                    FinanceColors.incomeColor(brightness),
                    textTheme,
                    color,
                    spacing,
                  ),
                  SizedBox(height: spacing.elementGap),
                  _buildLegendRow(
                    ctxt.netWorth_liabilities,
                    liabilityPct,
                    FinanceColors.expenseColor(brightness),
                    textTheme,
                    color,
                    spacing,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendRow(
    String label,
    double percentage,
    Color accent,
    TextTheme textTheme,
    ColorScheme color,
    AppSpacing spacing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            SizedBox(width: spacing.elementGap),
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: textTheme.labelMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: (percentage / 100).clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: color.outlineVariant.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(accent),
          ),
        ),
      ],
    );
  }

  // ── ACCOUNTS LIST ──

  Widget _buildAccountsCard(
    List<AccountItem> items,
    double sectionTotal,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing, {
    required bool isAsset,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    final itemColor = isAsset ? color.primary : color.error;

    return ClipRRect(
      borderRadius: BorderRadius.circular(spacing.radiusMedium),
      child: Container(
        decoration: BoxDecoration(
          color: color.surfaceContainerLow,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          border: Border.all(color: color.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;
          final share = sectionTotal > 0 ? item.balance / sectionTotal : 0.0;

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardInner,
                  vertical: spacing.elementGap * 1.5,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(spacing.radiusMedium),
                          decoration: BoxDecoration(
                            color: Color(item.colorValue ?? 0xFF6B4CE6).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(spacing.radiusMedium),
                          ),
                          child: Icon(
                            item.accountType.icon,
                            size: 22,
                            color: Color(item.colorValue ?? 0xFF6B4CE6),
                          ),
                        ),
                        SizedBox(width: spacing.elementGap * 1.5),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              SizedBox(height: spacing.elementGapUltraMin),
                              Text(
                                _getPsychologicalLabel(item.accountType, isAsset),
                                style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            CurrencyText(
                              amount: item.balance,
                              currencyCode: item.currencyCode,
                              fixedLength: 0,
                              compact: false,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: itemColor,
                              ),
                              showPositiveSign: false,
                              showSign: true,
                            ),
                            Text(
                              '${(share * 100).toStringAsFixed(1)}%',
                              style: textTheme.labelSmall?.copyWith(color: color.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: spacing.elementGap),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: share.clamp(0.0, 1.0),
                        minHeight: 3,
                        backgroundColor: color.outlineVariant.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation(
                          (item.colorValue != null ? Color(item.colorValue!) : itemColor).withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 72,
                  endIndent: spacing.cardInner,
                  color: color.outlineVariant.withValues(alpha: 0.3),
                ),
            ],
          );
        }).toList(),
      ),
      ),
    );
  }

  String _getPsychologicalLabel(AccountType type, bool isAsset) {
    if (isAsset) {
      switch (type) {
        case AccountType.bank:
          return 'Liquid Safety Net';
        case AccountType.cash:
          return 'Immediate Access';
        case AccountType.investment:
          return 'Growth Engine';
        case AccountType.eWallet:
          return 'Digital Reserve';
        default:
          return 'Available Funds';
      }
    } else {
      switch (type) {
        case AccountType.creditCard:
          return 'Revolving Credit';
        default:
          return 'Financial Obligation';
      }
    }
  }
}

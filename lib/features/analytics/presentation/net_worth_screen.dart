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

class NetWorthScreen extends ConsumerWidget {
  const NetWorthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final netWorthAsync = ref.watch(netWorthProvider);
    final historyAsync = ref.watch(netWorthHistoryProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        title: const Text('Net Worth'),
        backgroundColor: color.surface,
        elevation: 0,
      ),
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
                _buildHeroCard(data, historyAsync, color, textTheme, spacing),
                SizedBox(height: spacing.elementGap),
                _buildQuickStats(data, color, textTheme, spacing, Theme.of(context).brightness),
                SizedBox(height: spacing.elementGap),
                _buildCompositionCard(data, color, textTheme, spacing),
                SizedBox(height: spacing.elementGap),
                _buildAccountsCard(
                  data.assets, color, textTheme, spacing, isAsset: true,
                ),
                SizedBox(height: spacing.elementGap),
                _buildAccountsCard(
                  data.liabilities, color, textTheme, spacing, isAsset: false,
                ),
                SizedBox(height: spacing.sectionGap),
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

  // ── HERO CARD ──

  Widget _buildHeroCard(
    NetWorthData data,
    AsyncValue<List<NetWorthHistoryPoint>> historyAsync,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final isPositive = data.netWorth >= 0;

    return Card(
      elevation: 0,
      color: color.primaryContainer,
      margin: const EdgeInsets.only(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner + spacing.elementGap),
        child: Column(
          children: [
            CurrencyText(
              amount: data.netWorth,
              compact: false,
              showSign: true,
              fixedLength: 0,
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: color.onPrimaryContainer,
                letterSpacing: -0.5,
              ),
              showPositiveSign: false,
            ),
            SizedBox(height: spacing.elementGap * 1.5),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.sectionGap,
                vertical: spacing.elementGap,
              ),
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive
                        ? LucideIcons.trendingUp
                        : LucideIcons.trendingDown,
                    size: 16,
                    color: color.onPrimaryContainer,
                  ),
                  SizedBox(width: spacing.elementGap),
                  CurrencyText(
                    amount: data.monthlyChange,
                    compact: false,
                    showSign: true,
                    fixedLength: 0,
                    suffixText: 'this month',
                    style: textTheme.labelLarge?.copyWith(
                      color: color.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.sectionGap),
            historyAsync.when(
              data: (history) => _buildMiniChart(history, color),
              loading: () => const SizedBox(height: 60),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChart(
    List<NetWorthHistoryPoint> history,
    ColorScheme color,
  ) {
    if (history.isEmpty) return const SizedBox.shrink();
    final spots = history
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.netWorth))
        .toList();

    return SizedBox(
      height: 60,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.4,
              preventCurveOverShooting: true,
              color: color.onPrimaryContainer.withValues(alpha: 0.9),
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.onPrimaryContainer.withValues(alpha: 0.5),
                    color.onPrimaryContainer.withValues(alpha: 0.3),
                    color.onPrimaryContainer.withValues(alpha: 0.05),
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
  ) {
    return Row(
      children: [
        Expanded(
          child: StatPanelCard(
            label: 'Assets',
            amount: data.totalAssets,
            icon: LucideIcons.arrowDown,
            accent: FinanceColors.incomeColor(brightness),
          ),
        ),
        SizedBox(width: spacing.elementGap),
        Expanded(
          child: StatPanelCard(
            label: 'Liabilities',
            amount: data.totalLiabilities,
            icon: LucideIcons.arrowUp,
            accent: FinanceColors.expenseColor(brightness),
            trendInverted: true,
          ),
        ),
      ],
    );
  }

  // ── COMPOSITION ──

  Widget _buildCompositionCard(
    NetWorthData data,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final totalAssets = data.totalAssets;
    final totalLiabilities = data.totalLiabilities;
    final total = totalAssets + totalLiabilities;

    return Card(
      elevation: 0,
      color: color.primaryContainer,
      margin: const EdgeInsets.only(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner + spacing.elementGap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wealth Composition',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color.onPrimaryContainer,
              ),
            ),
            SizedBox(height: spacing.sectionGap),
            ClipRRect(
              borderRadius: BorderRadius.circular(spacing.radiusSmall),
              child: Row(
                children: [
                  Expanded(
                    flex: totalAssets > 0 ? totalAssets.toInt() : 1,
                    child: Container(height: 8, color: color.primary),
                  ),
                  SizedBox(width: spacing.elementGapUltraMin),
                  Expanded(
                    flex: totalLiabilities > 0 ? totalLiabilities.toInt() : 1,
                    child: Container(height: 8, color: color.error),
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.sectionGap),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLegendItem(
                  'Assets',
                  total > 0 ? (totalAssets / total * 100) : 0,
                  color.primary, textTheme, color, spacing,
                ),
                _buildLegendItem(
                  'Liabilities',
                  total > 0 ? (totalLiabilities / total * 100) : 0,
                  color.error, textTheme, color, spacing,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(
    String label,
    double percentage,
    Color itemColor,
    TextTheme textTheme,
    ColorScheme color,
    AppSpacing spacing,
  ) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: itemColor, shape: BoxShape.circle),
        ),
        SizedBox(width: spacing.elementGap),
        Text(
          '$label ${percentage.toStringAsFixed(1)}%',
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: color.onPrimaryContainer,
          ),
        ),
      ],
    );
  }

  // ── ACCOUNTS LIST ──

  Widget _buildAccountsCard(
    List<AccountItem> items,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing, {
    required bool isAsset,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    final itemColor = isAsset ? color.primary : color.error;

    return Card(
      elevation: 0,
      color: color.surfaceContainerLow,
      margin: const EdgeInsets.only(),
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
                Container(
                  padding: EdgeInsets.all(spacing.elementGap),
                  decoration: BoxDecoration(
                    color: itemColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  ),
                  child: Icon(
                    isAsset ? LucideIcons.wallet : LucideIcons.creditCard,
                    color: itemColor, size: 20,
                  ),
                ),
                SizedBox(width: spacing.elementGap * 1.5),
                Text(
                  isAsset ? 'Assets' : 'Liabilities',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.elementGap,
                    vertical: spacing.elementGapMin,
                  ),
                  decoration: BoxDecoration(
                    color: itemColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  ),
                  child: Text(
                    '${items.length}',
                    style: textTheme.labelMedium?.copyWith(
                      color: itemColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: color.outlineVariant.withValues(alpha: 0.3),
          ),
          // Items
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == items.length - 1;

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.cardInner,
                    vertical: spacing.elementGap * 1.5,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(spacing.radiusMedium),
                        decoration: BoxDecoration(
                          color: Color(item.colorValue ?? 0xFF6B4CE6)
                              .withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(spacing.radiusMedium),
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
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: spacing.elementGapUltraMin),
                            Text(
                              _getPsychologicalLabel(item.accountType, isAsset),
                              style: textTheme.bodySmall?.copyWith(
                                color: color.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
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
          }),
        ],
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

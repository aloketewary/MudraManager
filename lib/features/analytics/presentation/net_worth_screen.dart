import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/features/analytics/data/net_worth_service.dart';
import 'package:mudra_manager/core/extension/account_type_extenstion.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
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
      body: netWorthAsync.when(
        data: (data) => CustomScrollView(
          slivers: [
            _buildSliverAppBar(
              data,
              historyAsync,
              color,
              textTheme,
              context,
              spacing,
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(height: spacing.sectionGap * 1.5),
                  _buildQuickStats(
                    data,
                    color,
                    textTheme,
                    spacing,
                  ),
                  SizedBox(height: spacing.sectionGap * 1.5),
                  _buildCompositionCards(
                    data,
                    color,
                    textTheme,
                    spacing,
                  ),
                  SizedBox(height: spacing.sectionGap),
                  _buildAssetsList(
                    data.assets,
                    color,
                    textTheme,
                    spacing,
                    isAsset: true,
                  ),
                  SizedBox(height: spacing.elementGap * 1.5),
                  _buildAssetsList(
                    data.liabilities,
                    color,
                    textTheme,
                    spacing,
                    isAsset: false,
                  ),
                  SizedBox(height: spacing.sectionGap * 2),
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Unable to load net worth data')),
      ),
    );
  }

  Widget _buildSliverAppBar(
    NetWorthData data,
    AsyncValue<List<NetWorthHistoryPoint>> historyAsync,
    ColorScheme color,
    TextTheme textTheme,
    BuildContext context,
    AppSpacing spacing,
  ) {
    final isPositive = data.netWorth >= 0;

    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      elevation: 0,
      backgroundColor: color.surface,
      title: Text(
        'Net Worth',
        style: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate opacity based on scroll position
          final expandRatio =
              (constraints.maxHeight - kToolbarHeight) / (320 - kToolbarHeight);
          final opacity = expandRatio.clamp(0.0, 1.0);

          return FlexibleSpaceBar(
            background: Opacity(
              opacity: opacity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.primaryContainer,
                      color.primaryContainer.withValues(alpha: 0.8),
                      color.tertiaryContainer.withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      spacing.sectionGap * 1.5,
                      56,
                      spacing.sectionGap * 1.5,
                      spacing.elementGap,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CurrencyText(
                          amount: data.netWorth,
                          compact: false,
                          showSign: true,
                          fixedLength: 0,
                          style: textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: color.onPrimaryContainer,
                            letterSpacing: -1,
                          ),
                        ),
                        SizedBox(height: spacing.sectionGap),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: spacing.sectionGap,
                            vertical: spacing.elementGap,
                          ),
                          decoration: BoxDecoration(
                            color: color.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: color.primary.withValues(alpha: 0.3),
                              width: 1,
                            ),
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
                              SizedBox(width: spacing.elementGap * 0.75),
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
                        SizedBox(
                          height: spacing.cardInner + spacing.elementGap,
                        ),
                        historyAsync.when(
                          data: (history) => _buildMiniChart(history, color),
                          loading: () => const SizedBox(height: 60),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
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

  Widget _buildQuickStats(
    NetWorthData data,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing.sectionGap),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Assets',
              data.totalAssets,
              LucideIcons.circleArrowUp,
              const Color(0xFF10B981),
              color,
              textTheme,
              spacing,
            ),
          ),
          SizedBox(width: spacing.elementGap * 1.5),
          Expanded(
            child: _buildStatCard(
              'Total Liabilities',
              data.totalLiabilities,
              LucideIcons.circleArrowDown,
              const Color(0xFFEF4444),
              color,
              textTheme,
              spacing,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    double amount,
    IconData icon,
    Color accentColor,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusLarge),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(spacing.elementGap),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(spacing.radiusSmall + 2),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          SizedBox(height: spacing.elementGap * 1.5),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: color.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: spacing.elementGap * 0.5),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompositionCards(
    NetWorthData data,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final totalAssets = data.totalAssets;
    final totalLiabilities = data.totalLiabilities;
    final total = totalAssets + totalLiabilities;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing.sectionGap),
      child: Container(
        padding: EdgeInsets.all(spacing.cardInner + spacing.elementGap),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.primaryContainer,
              color.secondaryContainer.withValues(alpha: 0.5),
            ],
          ),
          borderRadius:
              BorderRadius.circular(spacing.cardInner + spacing.elementGap),
        ),
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
            Row(
              children: [
                Expanded(
                  flex: totalAssets.toInt(),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(spacing.elementGap * 0.5),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: totalLiabilities.toInt() > 0
                      ? totalLiabilities.toInt()
                      : 1,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(spacing.elementGap * 0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.sectionGap),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLegendItem(
                  'Assets',
                  total > 0 ? (totalAssets / total * 100) : 0,
                  const Color(0xFF10B981),
                  textTheme,
                  color,
                  spacing,
                ),
                _buildLegendItem(
                  'Liabilities',
                  total > 0 ? (totalLiabilities / total * 100) : 0,
                  const Color(0xFFEF4444),
                  textTheme,
                  color,
                  spacing,
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
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: itemColor,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: spacing.elementGap),
        Text(
          '$label ${percentage.toStringAsFixed(1)}%',
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color.onPrimaryContainer,
          ),
        ),
      ],
    );
  }

  Widget _buildAssetsList(
    List<AccountItem> items,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing, {
    required bool isAsset,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    final itemColor =
        isAsset ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing.sectionGap),
      child: Container(
        decoration: BoxDecoration(
          color: color.surfaceContainerLow,
          borderRadius:
              BorderRadius.circular(spacing.cardInner + spacing.elementGap),
          border: Border.all(
            color: color.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(spacing.cardInner + spacing.elementGap),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(spacing.radiusSmall + 2),
                    decoration: BoxDecoration(
                      color: itemColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    ),
                    child: Icon(
                      isAsset ? LucideIcons.wallet : LucideIcons.creditCard,
                      color: itemColor,
                      size: 20,
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
                      horizontal: spacing.radiusSmall + 2,
                      vertical: spacing.elementGap * 0.75,
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
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.cardInner + spacing.elementGap,
                      vertical: spacing.sectionGap,
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
                        SizedBox(width: spacing.elementGap * 1.75),
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
                              SizedBox(height: spacing.elementGap * 0.25),
                              Text(
                                _getPsychologicalLabel(
                                  item.accountType,
                                  isAsset,
                                ),
                                style: textTheme.bodySmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${item.balance.toStringAsFixed(0)}',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: itemColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 72,
                      endIndent: spacing.cardInner + spacing.elementGap,
                      color: color.outlineVariant.withValues(alpha: 0.3),
                    ),
                ],
              );
            }),
          ],
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

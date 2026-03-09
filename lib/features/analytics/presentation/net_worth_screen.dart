import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/features/analytics/data/net_worth_service.dart';
import 'package:mudra_manager/core/extension/account_type_extenstion.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:fl_chart/fl_chart.dart';

class NetWorthScreen extends ConsumerWidget {
  const NetWorthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netWorthAsync = ref.watch(netWorthProvider);
    final historyAsync = ref.watch(netWorthHistoryProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        title: const Text('Net Worth'),
        elevation: 0,
      ),
      body: netWorthAsync.when(
        data: (data) => SingleChildScrollView(
          child: Column(
            children: [
              _buildHeroSection(data, historyAsync, color, textTheme),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildCompositionDonut(data, color, textTheme),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildAssetsList(data.assets, color, textTheme, isAsset: true),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildAssetsList(data.liabilities, color, textTheme, isAsset: false),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Unable to load net worth data')),
      ),
    );
  }



  Widget _buildHeroSection(NetWorthData data, AsyncValue<List<NetWorthHistoryPoint>> historyAsync, ColorScheme color, TextTheme textTheme) {
    final isPositive = data.netWorth >= 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.primaryContainer,
            color.primaryContainer.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          children: [
            Text(
              'Total Net Worth',
              style: textTheme.titleSmall?.copyWith(
                color: color.onPrimaryContainer.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${data.netWorth.abs().toStringAsFixed(0)}',
              style: textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: color.onPrimaryContainer,
                fontSize: 48,
              ),
            ),
            const SizedBox(height: 16),
            historyAsync.when(
              data: (history) => _buildMiniChart(history, color),
              loading: () => const SizedBox(height: 60),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isPositive
                    ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                    : const Color(0xFFF44336).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                    size: 14,
                    color: isPositive ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${isPositive ? '+' : ''}₹${data.monthlyChange.toStringAsFixed(0)} this month',
                    style: textTheme.labelMedium?.copyWith(
                      color: isPositive ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChart(List<NetWorthHistoryPoint> history, ColorScheme color) {
    if (history.isEmpty) return const SizedBox.shrink();
    final spots = history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.netWorth)).toList();

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
              color: color.onPrimaryContainer.withValues(alpha: 0.6),
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.onPrimaryContainer.withValues(alpha: 0.15),
                    color.onPrimaryContainer.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompositionDonut(NetWorthData data, ColorScheme color, TextTheme textTheme) {
    final totalAssets = data.totalAssets;
    final totalLiabilities = data.totalLiabilities;
    final total = totalAssets + totalLiabilities;

    return Row(
      children: [
        Expanded(
          child: _buildCompositionItem(
            'Assets',
            totalAssets,
            total > 0 ? (totalAssets / total * 100) : 0,
            const Color(0xFF4CAF50),
            color,
            textTheme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCompositionItem(
            'Liabilities',
            totalLiabilities,
            total > 0 ? (totalLiabilities / total * 100) : 0,
            const Color(0xFFFF5252),
            color,
            textTheme,
          ),
        ),
      ],
    );
  }

  Widget _buildCompositionItem(String label, double amount, double percentage, Color itemColor, ColorScheme color, TextTheme textTheme) {
    return Card(
      elevation: 0,
      color: color.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: itemColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                label == 'Assets' ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                color: itemColor,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: color.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '₹${amount.toStringAsFixed(0)}',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: itemColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${percentage.toStringAsFixed(1)}%',
                style: textTheme.labelSmall?.copyWith(
                  color: itemColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetsList(List<AccountItem> items, ColorScheme color, TextTheme textTheme, {required bool isAsset}) {
    if (items.isEmpty) return const SizedBox.shrink();
    final itemColor = isAsset ? const Color(0xFF4CAF50) : const Color(0xFFFF5252);

    return Card(
      elevation: 0,
      color: color.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: itemColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isAsset ? LucideIcons.wallet : LucideIcons.creditCard,
                    color: itemColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  isAsset ? 'Assets' : 'Liabilities',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.surfaceContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.accountType.icon,
                      size: 20,
                      color: color.onSurface,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getPsychologicalLabel(item.accountType, isAsset),
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
                    ),
                  ),
                ],
              ),
            )),
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

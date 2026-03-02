import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mudra_manager/core/db/models/balance_snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';

class BalanceHistoryChart extends ConsumerWidget {
  final List<BalanceSnapshot> snapshots;
  final String accountName;
  final bool isGuestMode;

  const BalanceHistoryChart({
    super.key,
    required this.snapshots,
    required this.accountName,
    required this.isGuestMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (snapshots.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No balance history available'),
        ),
      );
    }

    final minBalance = snapshots.map((s) => s.balance).reduce((a, b) => a < b ? a : b);
    final maxBalance = snapshots.map((s) => s.balance).reduce((a, b) => a > b ? a : b);
    final displayMinBalance = GuestModeUtil.applyGuestMode(minBalance, isGuestMode);
    final displayMaxBalance = GuestModeUtil.applyGuestMode(maxBalance, isGuestMode);
    final displayCurrentBalance = GuestModeUtil.applyGuestMode(snapshots.last.balance, isGuestMode);

    final spots = snapshots.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), GuestModeUtil.applyGuestMode(e.value.balance, isGuestMode));
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Balance Trend - $accountName',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < snapshots.length) {
                          return Text(
                            snapshots[index].date.day.toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 2,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                ],
                minY: displayMinBalance - 1000,
                maxY: displayMaxBalance + 1000,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatCard(
                label: 'Current',
                displayValue: displayCurrentBalance,
              ),
              _StatCard(
                label: 'Highest',
                displayValue: displayMaxBalance,
              ),
              _StatCard(
                label: 'Lowest',
                displayValue: displayMinBalance,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double displayValue;

  const _StatCard({
    required this.label,
    required this.displayValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 4),
        Text(
          '₹${displayValue.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

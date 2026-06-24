import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/dashboard/data/historical_data_provider.dart';
import 'package:mudra_manager/shared/widgets/animated_balance.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';

class NetWorthMiniCard extends ConsumerStatefulWidget {
  final double globalPadding;

  const NetWorthMiniCard({super.key, this.globalPadding = 16.0});

  @override
  ConsumerState<NetWorthMiniCard> createState() => _NetWorthMiniCardState();
}

class _NetWorthMiniCardState extends ConsumerState<NetWorthMiniCard> {
  Map<int, double> _balanceMap = {};
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      ref.watch(accountServiceProvider).getAccountBalanceMapInBase().then(
        (val) {
          if (mounted) setState(() => _balanceMap = val);
        },
      );
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    final spacing = ref.watch(spacingProvider);
    final double totalBalance = _balanceMap.values.fold(
      0.0,
      (sum, value) => sum + value,
    );
    final color = Theme.of(context).colorScheme;
    final isGuestMode = ref.watch(guestModeProvider);
    final displayTotalBalance =
        GuestModeUtil.applyGuestMode(totalBalance, isGuestMode);

    return Padding(
      padding: EdgeInsets.all(widget.globalPadding),
      child: SizedBox(
        height: 180,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
          },
          child: Card(
            elevation: 0,
            color: color.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              side: BorderSide(color: color.outlineVariant),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              onTap: () {
                HapticFeedback.mediumImpact();
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(
                                Tone.current.borderRadius,),
                          ),
                          child: Icon(
                            LucideIcons.wallet,
                            size: 20,
                            color: color.secondary,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            ctxt.dashboard_netWorthTitle.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: textTheme.labelLarge?.copyWith(
                              color: color.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 100,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Consumer(
                              builder: (context, ref, child) {
                                final historyAsync =
                                    ref.watch(historicalBalanceProvider);
                                return historyAsync.when(
                                  data: (history) {
                                    if (history.isEmpty ||
                                        history.every((v) => v == 0)) {
                                      return const SizedBox();
                                    }
                                    final maxVal =
                                        history.reduce((a, b) => a > b ? a : b);
                                    final minVal =
                                        history.reduce((a, b) => a < b ? a : b);
                                    final range = maxVal - minVal;
                                    final spots =
                                        history.asMap().entries.map((e) {
                                      final normalized = range > 0
                                          ? ((e.value - minVal) / range) * 50 +
                                              10
                                          : 30;
                                      return FlSpot(e.key.toDouble(),
                                          normalized.toDouble(),);
                                    }).toList();
                                    return LineChart(
                                      LineChartData(
                                        gridData: const FlGridData(show: false),
                                        titlesData:
                                            const FlTitlesData(show: false),
                                        borderData: FlBorderData(show: false),
                                        lineTouchData:
                                            const LineTouchData(enabled: false),
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: spots,
                                            isCurved: true,
                                            color: color.secondary
                                                .withValues(alpha: 0.15),
                                            barWidth: 3,
                                            dotData:
                                                const FlDotData(show: false),
                                            belowBarData: BarAreaData(
                                              show: true,
                                              color: color.secondary
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
                              value: displayTotalBalance,
                              style: textTheme.titleLarge?.copyWith(
                                color: color.secondary,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                              fixedStringLength: 0,
                              overflow: TextOverflow.fade,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

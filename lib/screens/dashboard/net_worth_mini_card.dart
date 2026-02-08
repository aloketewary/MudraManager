import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/providers/account_providers.dart';
import 'package:mudra_manager/screens/reusable/animated_balance.dart';

import 'package:mudra_manager/util/localization_extension.dart';

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
      final balanceMap =
          ref.watch(accountServiceProvider).getAccountBalanceMap();
      balanceMap.then(
        (val) => {
          if (mounted)
            {
              setState(() {
                _balanceMap = val;
              }),
            },
        },
      );
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    double totalBalance = _balanceMap.values.fold(
      0.0,
      (sum, value) => sum + value,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = Theme.of(context).colorScheme;

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
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
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
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet,
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
                        alignment: Alignment.centerLeft,
                        children: [
                          Text(
                            ctxt.formatCurrencyWithSign(0, totalBalance),
                            style: textTheme.titleLarge?.copyWith(
                              color: color.onSurfaceVariant.withValues(alpha: 0.1),
                              fontSize: 80,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.fade,
                          ),
                          AnimatedBalance(
                            value: totalBalance,
                            style: textTheme.titleLarge?.copyWith(
                              color: color.secondary,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                            fixedStringLength: 0,
                            overflow: TextOverflow.fade,
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

import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/providers/account_providers.dart';
import 'package:mudra_manager/screens/reusable/animated_balance.dart';
import 'package:mudra_manager/screens/transaction/transaction_list_screen.dart';
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
      final balanceMap = ref.watch(accountServiceProvider).getAccountBalanceMap();
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
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    double totalBalance = _balanceMap.values.fold(0.0, (sum, value) => sum + value);

    return Padding(
      padding: EdgeInsets.all(widget.globalPadding),
      child: SizedBox(
        height: 150,
        child: GestureDetector(
          onTap: () => {},
          child: Container(
            // width: 120,
            padding: const EdgeInsets.all(8.0),
            // margin: const EdgeInsets.only(right: 8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              color: color.primary,
              // Light background color
              border: Border.all(color: color.primary), // Subtle border
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    CircleAvatar(radius: 16, child: Icon(Icons.money, size: 16)),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        ctxt.dashboard_netWorthTitle.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: textTheme.labelLarge?.copyWith(color: color.onPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 100,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    // or whatever aligns best for you
                    children: [
                      Text(
                        ctxt.formatCurrencyWithSign(0, totalBalance),
                        style: textTheme.titleLarge?.copyWith(color: color.onPrimary.withAlpha(10), fontSize: 80, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.fade,
                      ),
                      AnimatedBalance(
                        value: totalBalance,
                        style: textTheme.titleLarge?.copyWith(color: color.onPrimary, fontSize: 40, fontWeight: FontWeight.bold),
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
    );
  }
}

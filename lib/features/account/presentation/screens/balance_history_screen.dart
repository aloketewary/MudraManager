import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/features/account/data/balance_history_provider.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/features/account/presentation/widgets/balance_history_chart.dart';

class BalanceHistoryScreen extends ConsumerWidget {
  final Account account;

  const BalanceHistoryScreen({
    super.key,
    required this.account,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceHistory = ref.watch(balanceHistoryProvider(account.id));
    final isGuestMode = ref.watch(guestModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${account.name} - Balance History'),
      ),
      body: balanceHistory.when(
        data: (snapshots) => SingleChildScrollView(
          child: BalanceHistoryChart(
            snapshots: snapshots,
            accountName: account.name,
            isGuestMode: isGuestMode,
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

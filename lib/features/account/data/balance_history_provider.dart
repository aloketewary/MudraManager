import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/db/models/balance_snapshot.dart';
import 'package:mudra_manager/features/account/data/balance_history_service.dart';

final balanceHistoryProvider = FutureProvider.family<List<BalanceSnapshot>, int>(
  (ref, accountId) async {
    return await BalanceHistoryService.instance.getBalanceHistory(
      accountId,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now(),
    );
  },
);

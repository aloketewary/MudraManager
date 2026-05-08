import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/db/models/balance_snapshot.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/features/account/data/balance_history_service.dart';

final balanceHistoryServiceProvider = Provider<BalanceHistoryService>((ref) {
  return BalanceHistoryService(ref.watch(isarServiceProvider));
});

final balanceHistoryProvider = FutureProvider.family<List<BalanceSnapshot>, int>(
  (ref, accountId) async {
    final service = ref.watch(balanceHistoryServiceProvider);
    return await service.getBalanceHistory(
      accountId,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now(),
    );
  },
);

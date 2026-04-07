import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/collection_watchers.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';

final incomeExpenseSummaryProvider =
    FutureProvider.autoDispose<Map<String, double>>((
  ref,
) async {
  ref.watch(transactionChangeProvider);
  final txnService = ref.watch(transactionProvider);
  final txns = await txnService.getAllForDashBoard();

  double income = 0;
  double expense = 0;

  for (var txn in txns) {
    if (!txn.isExpense) {
      income += txn.effectiveAmount;
    } else if (txn.isExpense) {
      expense += txn.effectiveAmount;
    }
  }

  return {'income': income, 'expense': expense};
});

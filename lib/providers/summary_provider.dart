// lib/providers/summary_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/providers/transaction_provider.dart';

final incomeExpenseSummaryProvider = FutureProvider<Map<String, double>>((ref) async {
  final txnService = ref.watch(transactionProvider);
  final txns = await txnService.getAll();

  double income = 0;
  double expense = 0;

  for (var txn in txns) {
    if (!txn.isExpense) {
      income += txn.amount;
    } else if (txn.isExpense) {
      expense += txn.amount;
    }
  }

  return {
    'income': income,
    'expense': expense,
  };
});

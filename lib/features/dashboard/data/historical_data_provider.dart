import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/collection_watchers.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';

class HistoricalData {
  final List<double> balances; // 7 days
  final List<double> income; // 6 days
  final List<double> expense; // 6 days

  const HistoricalData({
    required this.balances,
    required this.income,
    required this.expense,
  });
}

final _historicalDataProvider =
    FutureProvider.autoDispose<HistoricalData>((ref) async {
  ref.watch(transactionChangeProvider);
  final db = await ref.watch(isarServiceProvider).getInstance();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Single query: all non-transfer transactions ever
  final allTxns = await db.transactions
      .where()
      .dateBetween(DateTime.fromMillisecondsSinceEpoch(0), now)
      .findAll();

  // Running balance up to each of the last 7 days
  final balances = List.filled(7, 0.0);
  // Per-day income/expense for last 6 days
  final dailyIncome = List.filled(6, 0.0);
  final dailyExpense = List.filled(6, 0.0);

  for (final txn in allTxns) {
    if (!txn.affectsStats) continue;

    final amount = txn.isExpense ? -txn.amount : txn.amount;

    // Balance: accumulate for each day this txn falls on or before
    final txnDay = DateTime(txn.date.year, txn.date.month, txn.date.day);
    for (int i = 0; i < 7; i++) {
      final day = today.subtract(Duration(days: 6 - i));
      if (!txnDay.isAfter(day)) {
        balances[i] += amount;
      }
    }

    // Income/Expense: bucket into the specific day
    final dayDiff = today.difference(txnDay).inDays;
    if (dayDiff >= 0 && dayDiff < 6) {
      final idx = 5 - dayDiff;
      if (txn.isExpense) {
        dailyExpense[idx] += txn.effectiveAmount;
      } else {
        dailyIncome[idx] += txn.effectiveAmount;
      }
    }
  }

  return HistoricalData(
    balances: balances,
    income: dailyIncome,
    expense: dailyExpense,
  );
});

// Derived providers — zero extra computation
final historicalBalanceProvider =
    FutureProvider.autoDispose<List<double>>((ref) async {
  final data = await ref.watch(_historicalDataProvider.future);
  return data.balances;
});

final historicalIncomeProvider =
    FutureProvider.autoDispose<List<double>>((ref) async {
  final data = await ref.watch(_historicalDataProvider.future);
  return data.income;
});

final historicalExpenseProvider =
    FutureProvider.autoDispose<List<double>>((ref) async {
  final data = await ref.watch(_historicalDataProvider.future);
  return data.expense;
});

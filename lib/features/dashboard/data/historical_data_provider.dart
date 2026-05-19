import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/exchange_rate.dart';
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

  final windowStart = today.subtract(const Duration(days: 6));

  // BOLT OPTIMIZATION: Calculate baseline balance for the start of the window
  // using optimized sum() instead of fetching all historical transactions.
  double baselineBalance = 0;
  final accounts = await db.collection<Account>().where().findAll();
  for (final account in accounts) {
    final results = await Future.wait([
      db.transactions
          .filter()
          .account((q) => q.idEqualTo(account.id))
          .isExpenseEqualTo(false)
          .dateLessThan(windowStart)
          .isTransferEqualTo(false)
          .isSettlementEqualTo(false)
          .amountProperty()
          .sum(),
      db.transactions
          .filter()
          .account((q) => q.idEqualTo(account.id))
          .isExpenseEqualTo(true)
          .dateLessThan(windowStart)
          .isTransferEqualTo(false)
          .isSettlementEqualTo(false)
          .amountProperty()
          .sum(),
    ]);
    final income = results[0];
    final expense = results[1];
    final rawBalance = account.initialBalance + income - expense;

    if (account.currencyCode != null) {
      final rate = await db.exchangeRates
          .filter()
          .currencyCodeEqualTo(account.currencyCode!)
          .findFirst();
      baselineBalance += rawBalance * (rate?.rateToBase ?? 1.0);
    } else {
      baselineBalance += rawBalance;
    }
  }

  // Fetch only transactions within the 7-day window
  final windowTxns = await db.transactions
      .where()
      .dateBetween(windowStart, now)
      .findAll();

  // Running balance up to each of the last 7 days
  final balances = List.filled(7, baselineBalance);
  // Per-day income/expense for last 6 days
  final dailyIncome = List.filled(6, 0.0);
  final dailyExpense = List.filled(6, 0.0);

  for (final txn in windowTxns) {
    final txnDay = DateTime(txn.date.year, txn.date.month, txn.date.day);

    if (txn.affectsStats) {
      // Balance: update all days from txn day onwards
      final balanceDayIdx = txnDay.difference(windowStart).inDays;
      if (balanceDayIdx >= 0 && balanceDayIdx < 7) {
        final amount = txn.isExpense ? -txn.baseAmount : txn.baseAmount;
        for (int i = balanceDayIdx; i < 7; i++) {
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

import 'package:mudra_manager/core/providers/state_value.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/db/filter_type.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/collection_watchers.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';

final filterProvider = NotifierProvider.autoDispose<StateValue<FilterType>, FilterType>(
  () => StateValue(FilterType.day),
);

// ── Shared helpers ──

Map<String, double> _sumIncomeExpense(List<Transaction> txns) {
  double income = 0;
  double expense = 0;
  for (final txn in txns) {
    if (txn.isExpense) {
      expense += txn.baseAmount;
    } else {
      income += txn.baseAmount;
    }
  }
  return {'income': income, 'expense': expense};
}

List<Transaction> _filterByPeriod(
  List<Transaction> txns,
  String period,
  DateTime ref,
) {
  return switch (period) {
    'day' => txns.where((t) => _isSameDay(t.date, ref)).toList(),
    'week' => txns.where((t) => _isSameWeek(t.date, ref)).toList(),
    'month' => txns.where((t) => _isSameMonth(t.date, ref)).toList(),
    'year' => txns.where((t) => _isSameYear(t.date, ref)).toList(),
    _ => txns,
  };
}

// ── Providers ──

final filteredDashboardTransactionsProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) async {
  ref.watch(transactionChangeProvider);
  final filter = ref.watch(filterProvider);
  final allTxns = await ref.watch(transactionProvider).getAllForDashBoard();
  final now = DateTime.now();

  final txns = switch (filter) {
    FilterType.all => allTxns,
    FilterType.day => allTxns.where((t) => _isSameDay(t.date, now)).toList(),
    FilterType.week => allTxns.where((t) => _isSameWeek(t.date, now)).toList(),
    FilterType.month => allTxns.where((t) => _isSameMonth(t.date, now)).toList(),
    FilterType.year => allTxns.where((t) => _isSameYear(t.date, now)).toList(),
  };

  return _sumIncomeExpense(txns);
});

final customDateRangeTransactionsProvider = FutureProvider.autoDispose
    .family<Map<String, double>, String>((ref, dateKey) async {
  ref.watch(transactionChangeProvider);
  final parts = dateKey.split('_');
  if (parts.length != 2) return {'income': 0.0, 'expense': 0.0};

  final startDate = DateTime.fromMillisecondsSinceEpoch(int.parse(parts[0]));
  final endDate = DateTime.fromMillisecondsSinceEpoch(int.parse(parts[1]));
  final allTxns = await ref.watch(transactionProvider).getAllForDashBoard();

  final txns = allTxns
      .where(
        (txn) =>
            !txn.date.isBefore(startDate) &&
            !txn.date.isAfter(
              DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
            ),
      )
      .toList();

  return _sumIncomeExpense(txns);
});

final periodBasedTransactionsProvider = FutureProvider.autoDispose
    .family<Map<String, double>, String>((ref, period) async {
  ref.watch(transactionChangeProvider);
  final allTxns = await ref.watch(transactionProvider).getAllForDashBoard();
  return _sumIncomeExpense(_filterByPeriod(allTxns, period, DateTime.now()));
});

final previousPeriodTransactionsProvider = FutureProvider.autoDispose
    .family<Map<String, double>, String>((ref, period) async {
  ref.watch(transactionChangeProvider);
  final allTxns = await ref.watch(transactionProvider).getAllForDashBoard();
  final now = DateTime.now();

  final txns = switch (period) {
    'day' => allTxns
        .where((t) => _isSameDay(t.date, now.subtract(const Duration(days: 1))))
        .toList(),
    'week' => allTxns
        .where((t) => _isSameWeek(t.date, now.subtract(const Duration(days: 7))))
        .toList(),
    'month' => allTxns
        .where((t) => _isSameMonth(t.date, DateTime(now.year, now.month - 1)))
        .toList(),
    'year' => allTxns
        .where((t) => _isSameYear(t.date, DateTime(now.year - 1)))
        .toList(),
    _ => <Transaction>[],
  };

  return _sumIncomeExpense(txns);
});

// ── Date helpers ──

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool _isSameWeek(DateTime a, DateTime b) {
  final startOfWeek = b.subtract(Duration(days: b.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 6));
  return a.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
      a.isBefore(endOfWeek.add(const Duration(days: 1)));
}

bool _isSameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

bool _isSameYear(DateTime a, DateTime b) => a.year == b.year;

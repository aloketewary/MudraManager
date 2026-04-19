import 'package:mudra_manager/core/providers/state_value.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/db/filter_type.dart';
import 'package:mudra_manager/core/providers/collection_watchers.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';

final filterProvider = NotifierProvider.autoDispose<StateValue<FilterType>, FilterType>(
  () => StateValue(FilterType.day),
);

// filtered_transactions_provider.dart
final filteredDashboardTransactionsProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) async {
  ref.watch(transactionChangeProvider);
  final filter = ref.watch(filterProvider);
  final txnService = ref.watch(transactionProvider);
  final allTxns = await txnService.getAllForDashBoard();

  final now = DateTime.now();

  final txns = switch (filter) {
    FilterType.all => allTxns,
    FilterType.day =>
      allTxns.where((txn) => _isSameDay(txn.date, now)).toList(),
    FilterType.week =>
      allTxns.where((txn) => _isSameWeek(txn.date, now)).toList(),
    FilterType.month =>
      allTxns.where((txn) => _isSameMonth(txn.date, now)).toList(),
    FilterType.year =>
      allTxns.where((txn) => _isSameYear(txn.date, now)).toList(),
  };

  double income = 0;
  double expense = 0;

  for (var txn in txns) {
    if (!txn.isExpense) {
      income += txn.baseAmount;
    } else if (txn.isExpense) {
      expense += txn.baseAmount;
    }
  }

  return {
    'income': income,
    'expense': expense,
  };
});

// Custom date range provider
final customDateRangeTransactionsProvider = FutureProvider.autoDispose
    .family<Map<String, double>, String>((ref, dateKey) async {
  ref.watch(transactionChangeProvider);
  final parts = dateKey.split('_');
  if (parts.length != 2) return {'income': 0, 'expense': 0};

  final startDate = DateTime.fromMillisecondsSinceEpoch(int.parse(parts[0]));
  final endDate = DateTime.fromMillisecondsSinceEpoch(int.parse(parts[1]));

  final txnService = ref.watch(transactionProvider);
  final allTxns = await txnService.getAllForDashBoard();

  final txns = allTxns
      .where(
        (txn) =>
            !txn.date.isBefore(startDate) &&
            !txn.date.isAfter(
              DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
            ),
      )
      .toList();

  double income = 0;
  double expense = 0;

  for (var txn in txns) {
    if (!txn.isExpense) {
      income += txn.baseAmount;
    } else if (txn.isExpense) {
      expense += txn.baseAmount;
    }
  }

  return {
    'income': income,
    'expense': expense,
  };
});

// Period-based provider for cash flow
final periodBasedTransactionsProvider = FutureProvider.autoDispose
    .family<Map<String, double>, String>((ref, period) async {
  ref.watch(transactionChangeProvider);
  final txnService = ref.watch(transactionProvider);
  final allTxns = await txnService.getAllForDashBoard();
  final now = DateTime.now();

  final txns = switch (period) {
    'day' => allTxns.where((txn) => _isSameDay(txn.date, now)).toList(),
    'week' => allTxns.where((txn) => _isSameWeek(txn.date, now)).toList(),
    'month' => allTxns.where((txn) => _isSameMonth(txn.date, now)).toList(),
    'year' => allTxns.where((txn) => _isSameYear(txn.date, now)).toList(),
    _ => allTxns,
  };

  double income = 0;
  double expense = 0;

  for (var txn in txns) {
    if (!txn.isExpense) {
      income += txn.baseAmount;
    } else if (txn.isExpense) {
      expense += txn.baseAmount;
    }
  }

  return {
    'income': income,
    'expense': expense,
  };
});

// Previous period provider for trend comparison
final previousPeriodTransactionsProvider = FutureProvider.autoDispose
    .family<Map<String, double>, String>((ref, period) async {
  ref.watch(transactionChangeProvider);
  final txnService = ref.watch(transactionProvider);
  final allTxns = await txnService.getAllForDashBoard();
  final now = DateTime.now();

  final txns = switch (period) {
    'day' => allTxns
        .where(
          (txn) => _isSameDay(txn.date, now.subtract(const Duration(days: 1))),
        )
        .toList(),
    'week' => allTxns
        .where(
          (txn) => _isSameWeek(txn.date, now.subtract(const Duration(days: 7))),
        )
        .toList(),
    'month' => allTxns
        .where(
          (txn) => _isSameMonth(txn.date, DateTime(now.year, now.month - 1)),
        )
        .toList(),
    'year' => allTxns
        .where((txn) => _isSameYear(txn.date, DateTime(now.year - 1)))
        .toList(),
    _ => [],
  };

  double income = 0;
  double expense = 0;

  for (var txn in txns) {
    if (!txn.isExpense) {
      income += txn.baseAmount;
    } else if (txn.isExpense) {
      expense += txn.baseAmount;
    }
  }

  return {
    'income': income,
    'expense': expense,
  };
});

// Helper date functions
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

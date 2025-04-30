// filter_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/db/filter_type.dart' show FilterType;
import 'package:mudra_manager/providers/transaction_provider.dart';

final filterProvider = StateProvider<FilterType>((ref) => FilterType.day);

// filtered_transactions_provider.dart
final filteredDashboardTransactionsProvider = FutureProvider<Map<String, double>>((ref) async {
  final filter = ref.watch(filterProvider);
  final txnService = ref.watch(transactionProvider);
  final allTxns = await txnService.getAllForDashBoard();

  final now = DateTime.now();

   var txns = switch (filter) {
    FilterType.all => allTxns,
    FilterType.day => allTxns.where((txn) => _isSameDay(txn.date, now)).toList(),
    FilterType.week => allTxns.where((txn) => _isSameWeek(txn.date, now)).toList(),
    FilterType.month => allTxns.where((txn) => _isSameMonth(txn.date, now)).toList(),
    FilterType.year => allTxns.where((txn) => _isSameYear(txn.date, now)).toList(),
  };

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

// Helper date functions
bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

bool _isSameWeek(DateTime a, DateTime b) {
  final startOfWeek = b.subtract(Duration(days: b.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 6));
  return a.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
      a.isBefore(endOfWeek.add(const Duration(days: 1)));
}

bool _isSameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;
bool _isSameYear(DateTime a, DateTime b) => a.year == b.year;

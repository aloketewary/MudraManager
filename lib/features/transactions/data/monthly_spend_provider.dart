import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';

/// Monthly spending summary with trend.
class MonthlySpend {
  final double totalSpent;
  final double totalIncome;
  final double? previousMonthSpent;
  final String? changePercent;
  final bool isLoading;

  const MonthlySpend({
    this.totalSpent = 0,
    this.totalIncome = 0,
    this.previousMonthSpent,
    this.changePercent,
    this.isLoading = true,
  });

  double get netFlow => totalIncome - totalSpent;
}

/// Provider for current month's spending summary.
final monthlySpendProvider = StateNotifierProvider<MonthlySpendNotifier, MonthlySpend>(
  (ref) => MonthlySpendNotifier(ref),
);

class MonthlySpendNotifier extends StateNotifier<MonthlySpend> {
  final Ref _ref;

  MonthlySpendNotifier(this._ref) : super(const MonthlySpend()) {
    _load();
  }

  Future<void> _load() async {
    state = const MonthlySpend(isLoading: true);

    try {
      final isar = await _ref.read(isarServiceProvider).getInstance();
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Get this month's transactions
      final thisMonth = await isar.transactions
          .where()
          .dateBetween(startOfMonth, endOfMonth)
          .filter()
          .isTransferEqualTo(false)
          .findAll();

      double spent = 0;
      double income = 0;

      for (final txn in thisMonth) {
        if (txn.isExpense) {
          spent += txn.convertedAmount ?? txn.amount;
        } else {
          income += txn.convertedAmount ?? txn.amount;
        }
      }

      // Get previous month for comparison
      final prevMonthStart = DateTime(now.year, now.month - 1, 1);
      final prevMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

      final prevMonth = await isar.transactions
          .where()
          .dateBetween(prevMonthStart, prevMonthEnd)
          .filter()
          .isExpenseEqualTo(true)
          .isTransferEqualTo(false)
          .findAll();

      final double prevSpent = prevMonth.fold(0, (sum, txn) => sum + (txn.convertedAmount ?? txn.amount));

      String? changePercent;
      if (prevSpent > 0) {
        final change = ((spent - prevSpent) / prevSpent) * 100;
        changePercent = '${change > 0 ? '+' : ''}${change.toStringAsFixed(0)}%';
      }

      state = MonthlySpend(
        totalSpent: spent,
        totalIncome: income,
        previousMonthSpent: prevSpent,
        changePercent: changePercent,
        isLoading: false,
      );
    } catch (e) {
      state = MonthlySpend(
        totalSpent: state.totalSpent,
        totalIncome: state.totalIncome,
        previousMonthSpent: state.previousMonthSpent,
        changePercent: state.changePercent,
        isLoading: false,
      );
    }
  }

  void refresh() => _load();
}
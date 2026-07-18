import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';

/// Derived provider - reuses data from dashboardDataProvider
/// No duplicate fetching, efficient recomputation
final incomeExpenseSummaryProvider = Provider<Map<String, double>>((ref) {
  final data = ref.watch(dashboardDataProvider.select((v) => v.value));

  if (data == null) {
    return {'income': 0.0, 'expense': 0.0};
  }

  double income = 0;
  double expense = 0;

  for (final txn in data.transactions) {
    if (txn.isExpense) {
      expense += txn.baseAmount;
    } else {
      income += txn.baseAmount;
    }
  }

  return {'income': income, 'expense': expense};
});

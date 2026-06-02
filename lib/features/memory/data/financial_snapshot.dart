import 'package:isar_community/isar.dart';

part 'financial_snapshot.g.dart';

/// Pre-aggregated monthly financial data.
/// Pure aggregation — no interpretation, no intelligence.
/// "What happened" — never "what does it mean."
@collection
class FinancialSnapshot {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late DateTime month;

  late double income;
  late double expense;
  int transactionCount = 0;

  /// Category breakdown stored as parallel lists of IDs and amounts.
  /// IDs (not names) for rename-safety. Names resolved at read-time.
  List<int> categoryIds = [];
  List<double> categoryAmounts = [];

  double cashExpense = 0;
  double weekendExpense = 0;
  double weekdayExpense = 0;

  late DateTime computedAt;

  FinancialSnapshot();

  double get savings => income - expense;

  double amountForCategory(int catId) {
    final idx = categoryIds.indexOf(catId);
    return idx >= 0 && idx < categoryAmounts.length ? categoryAmounts[idx] : 0;
  }
}

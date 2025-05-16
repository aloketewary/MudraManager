// 1. Define the data structure:
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:mudra_manager/db/models/category.dart';
import 'package:mudra_manager/db/models/transaction.dart'
    show
        GetTransactionCollection,
        Transaction,
        TransactionQueryFilter,
        TransactionQueryLinks,
        TransactionQueryProperty,
        TransactionQuerySortBy;
import 'package:mudra_manager/providers/isar_provider.dart';

class StatsData {
  final double income;
  final double expense;
  final List<FlSpot> incomeSpots;
  final List<FlSpot> expenseSpots;
  final Map<String, double> categoryData;
  final List<Transaction> recent;
  final Map<String, Category> categoryDataMap;

  StatsData({
    required this.income,
    required this.expense,
    required this.incomeSpots,
    required this.expenseSpots,
    required this.categoryData,
    required this.recent,
    required this.categoryDataMap,
  });
}

// 2. The provider:
final statsProvider = FutureProvider.family<StatsData, String>((
  ref,
  period,
) async {
  final isar = await ref.watch(isarServiceProvider).getInstance();

  // 2.1 Determine the date range:
  final now = DateTime.now();
  DateTime start;
  switch (period) {
    case 'Today':
      start = DateTime(now.year, now.month, now.day);
      break;
    case 'Week':
      start = now.subtract(Duration(days: now.weekday - 1));
      break;
    case 'Month':
      start = DateTime(now.year, now.month, 1);
      break;
    case 'Year':
      start = DateTime(now.year, 1, 1);
      break;
    default: // All
      start = DateTime(2000);
  }
  final end = now;

  // 2.2 Total income & expense sums:
  final income =
      await isar.transactions
          .filter()
          .dateBetween(start, end)
          .and()
          .isExpenseEqualTo(false)
          .isTransferEqualTo(false)
          .amountProperty()
          .sum() ??
      0.0;
  final expense =
      await isar.transactions
          .filter()
          .dateBetween(start, end)
          .and()
          .isExpenseEqualTo(true)
          .isTransferEqualTo(false)
          .amountProperty()
          .sum() ??
      0.0;

  // 2.3 Time-series points (e.g. one per day)
  List<FlSpot> incomeSpots = [];
  List<FlSpot> expenseSpots = [];
  if (period == 'Year') {
    for (int month = 1; month <= 12; month++) {
      final monthStart = DateTime(start.year, month, 1);
      final monthEnd = DateTime(start.year, month + 1, 1).subtract(const Duration(days: 1));

      final income = await isar.transactions
          .filter()
          .dateBetween(monthStart, monthEnd)
          .and()
          .isExpenseEqualTo(false)
          .isTransferEqualTo(false)
          .amountProperty()
          .sum() ?? 0.0;

      final expense = await isar.transactions
          .filter()
          .dateBetween(monthStart, monthEnd)
          .and()
          .isExpenseEqualTo(true)
          .isTransferEqualTo(false)
          .amountProperty()
          .sum() ?? 0.0;

      incomeSpots.add(FlSpot((month - 1).toDouble(), income));
      expenseSpots.add(FlSpot((month - 1).toDouble(), expense));
    }
  } else if (period == 'Today') {
    for (int hour = 0; hour < 24; hour++) {
      final hourStart = DateTime(start.year, start.month, start.day, hour);
      final hourEnd = hourStart.add(const Duration(hours: 1));

      final income = await isar.transactions
          .filter()
          .dateBetween(hourStart, hourEnd)
          .and()
          .isExpenseEqualTo(false)
          .isTransferEqualTo(false)
          .amountProperty()
          .sum() ?? 0.0;

      final expense = await isar.transactions
          .filter()
          .dateBetween(hourStart, hourEnd)
          .and()
          .isExpenseEqualTo(true)
          .isTransferEqualTo(false)
          .amountProperty()
          .sum() ?? 0.0;

      incomeSpots.add(FlSpot(hour.toDouble(), income));
      expenseSpots.add(FlSpot(hour.toDouble(), expense));
    }
  } else {
    final days = end
        .difference(start)
        .inDays + 1;
    for (int i = 0; i < days; i++) {
      final day = start.add(Duration(days: i));
      final next = day.add(const Duration(days: 1));

      final dayIncome =
          await isar.transactions
              .filter()
              .dateBetween(day, next)
              .and()
              .isExpenseEqualTo(false)
              .isTransferEqualTo(false)
              .amountProperty()
              .sum() ??
              0.0;
      final dayExpense =
          await isar.transactions
              .filter()
              .dateBetween(day, next)
              .and()
              .isExpenseEqualTo(true)
              .isTransferEqualTo(false)
              .amountProperty()
              .sum() ??
              0.0;

      incomeSpots.add(FlSpot(i.toDouble(), dayIncome));
      expenseSpots.add(FlSpot(i.toDouble(), dayExpense));
    }
  }

  // 2.4 Category breakdown (pie chart)
  final cats = await isar.categorys.where().findAll();
  final Map<String, double> categoryData = {};
  final Map<String, Category> categoryMapData = {};
  for (final cat in cats) {
    final catSpent =
        await isar.transactions
            .filter()
            .dateBetween(start, end)
            .and()
            .category((q) => q.idEqualTo(cat.id))
            .and()
            .isExpenseEqualTo(true)
            .amountProperty()
            .sum() ??
        0.0;
    if (catSpent > 0) {
      categoryData[cat.name] = catSpent;
      categoryMapData[cat.name] = cat;
    }
  }

  // 2.5 Recent 5 transactions in period
  final recent =
      await isar.transactions
          .filter()
          .dateBetween(start, end)
          .isTransferEqualTo(false)
          .sortByDateDesc()
          .findAll();
  final List<Transaction> recentFive = recent.take(5).toList();

  return StatsData(
    income: income,
    expense: expense,
    incomeSpots: incomeSpots,
    expenseSpots: expenseSpots,
    categoryData: categoryData,
    recent: recentFive,
    categoryDataMap: categoryMapData,
  );
});

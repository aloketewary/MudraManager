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
  final Map<String, Category> categoryDataMap;
  final Map<String, double> incomeCategoryData;
  final Map<String, Category> incomeCategoryMapData;
  final double savingsRate;
  final double avgDailySpend;
  final List<Transaction> recent;
  final Map<Category, List<FlSpot>> categoryTrends;

  StatsData({
    required this.income,
    required this.expense,
    required this.incomeSpots,
    required this.expenseSpots,
    required this.categoryData,
    required this.categoryDataMap,
    required this.incomeCategoryData,
    required this.incomeCategoryMapData,
    required this.savingsRate,
    required this.avgDailySpend,
    required this.recent,
    required this.categoryTrends,
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
      start = now.subtract(Duration(days: 6));
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
          .sum();
  final expense =
      await isar.transactions
          .filter()
          .dateBetween(start, end)
          .and()
          .isExpenseEqualTo(true)
          .isTransferEqualTo(false)
          .amountProperty()
          .sum();

  // 2.3 Time-series points (e.g. one per day)
  List<FlSpot> incomeSpots = [];
  List<FlSpot> expenseSpots = [];
  if (period == 'Year') {
    for (int month = 1; month <= 12; month++) {
      final monthStart = DateTime(start.year, month, 1);
      final monthEnd = DateTime(
        start.year,
        month + 1,
        1,
      ).subtract(const Duration(days: 1));

      final income =
          await isar.transactions
              .filter()
              .dateBetween(monthStart, monthEnd)
              .and()
              .isExpenseEqualTo(false)
              .isTransferEqualTo(false)
              .amountProperty()
              .sum();

      final expense =
          await isar.transactions
              .filter()
              .dateBetween(monthStart, monthEnd)
              .and()
              .isExpenseEqualTo(true)
              .isTransferEqualTo(false)
              .amountProperty()
              .sum();

      incomeSpots.add(FlSpot((month - 1).toDouble(), income));
      expenseSpots.add(FlSpot((month - 1).toDouble(), expense));
    }
  } else if (period == 'Today') {
    for (int hour = 0; hour < 24; hour++) {
      final hourStart = DateTime(start.year, start.month, start.day, hour);
      final hourEnd = hourStart.add(const Duration(hours: 1));

      final income =
          await isar.transactions
              .filter()
              .dateBetween(hourStart, hourEnd)
              .and()
              .isExpenseEqualTo(false)
              .isTransferEqualTo(false)
              .amountProperty()
              .sum();

      final expense =
          await isar.transactions
              .filter()
              .dateBetween(hourStart, hourEnd)
              .and()
              .isExpenseEqualTo(true)
              .isTransferEqualTo(false)
              .amountProperty()
              .sum();

      incomeSpots.add(FlSpot(hour.toDouble(), income));
      expenseSpots.add(FlSpot(hour.toDouble(), expense));
    }
  } else {
    final days = end.difference(start).inDays + 1;
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
              .sum();
      final dayExpense =
          await isar.transactions
              .filter()
              .dateBetween(day, next)
              .and()
              .isExpenseEqualTo(true)
              .isTransferEqualTo(false)
              .amountProperty()
              .sum();

      incomeSpots.add(FlSpot(i.toDouble(), dayIncome));
      expenseSpots.add(FlSpot(i.toDouble(), dayExpense));
    }
  }

  // 2.4 Category breakdown (pie chart)
  final cats = await isar.categorys.where().findAll();
  final Map<String, double> categoryData = {};
  final Map<String, Category> categoryMapData = {};
  final Map<String, double> incomeCategoryData = {};
  final Map<String, Category> incomeCategoryMapData = {};
  final Map<Category, List<FlSpot>> categoryTrends = {};

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
            .sum();
    if (catSpent > 0) {
      categoryData[cat.name] = catSpent;
      categoryMapData[cat.name] = cat;
    }

    final catIncome =
        await isar.transactions
            .filter()
            .dateBetween(start, end)
            .and()
            .category((q) => q.idEqualTo(cat.id))
            .and()
            .isExpenseEqualTo(false)
            .amountProperty()
            .sum();
    if (catIncome > 0) {
      incomeCategoryData[cat.name] = catIncome;
      incomeCategoryMapData[cat.name] = cat;
    }

    // 2.6 Trend data
    List<FlSpot> categorySpots = [];
    for (int i = 0; i < 12; i++) {
      final monthStart = DateTime(now.year, now.month - 11 + i, 1);
      final monthEnd = DateTime(
        now.year,
        now.month - 11 + i + 1,
        1,
      ).subtract(const Duration(days: 1));

      final expenseForMonth =
          await isar.transactions
              .filter()
              .dateBetween(monthStart, monthEnd)
              .and()
              .category((q) => q.idEqualTo(cat.id))
              .and()
              .isExpenseEqualTo(true)
              .amountProperty()
              .sum();
      categorySpots.add(FlSpot(i.toDouble(), expenseForMonth));
    }
    categoryTrends[cat] = categorySpots;
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

  // 2.7 Calculate new metrics
  final savingsRate = income > 0 ? ((income - expense) / income) * 100 : 0.0;
  final daysInPeriod = end.difference(start).inDays + 1;
  final avgDailySpend = expense / (daysInPeriod > 0 ? daysInPeriod : 1);

  return StatsData(
    income: income,
    expense: expense,
    incomeSpots: incomeSpots,
    expenseSpots: expenseSpots,
    categoryData: categoryData,
    categoryDataMap: categoryMapData,
    incomeCategoryData: incomeCategoryData,
    incomeCategoryMapData: incomeCategoryMapData,
    savingsRate: savingsRate,
    avgDailySpend: avgDailySpend,
    recent: recentFive,
    categoryTrends: categoryTrends,
  );
});

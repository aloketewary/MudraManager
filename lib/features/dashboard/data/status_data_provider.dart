// 1. Define the data structure:
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';

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

// 2. The provider - OPTIMIZED:
final statsProvider = FutureProvider.family<StatsData, String>((
  ref,
  period,
) async {
  final isar = await ref.watch(isarServiceProvider).getInstance();
  final now = DateTime.now();
  DateTime start;

  switch (period) {
    case 'Today':
      start = DateTime(now.year, now.month, now.day);
      break;
    case 'Week':
      start = now.subtract(const Duration(days: 6));
      break;
    case 'Month':
      start = DateTime(now.year, now.month, 1);
      break;
    case 'Year':
      start = DateTime(now.year, 1, 1);
      break;
    default:
      start = DateTime(2000);
  }
  final end = now;

  // Get categories first
  final cats = await isar.categorys.where().findAll();

  // OPTIMIZED: Single query for all transactions
  final allTxns = await isar.transactions
      .filter()
      .dateBetween(start, end)
      .isTransferEqualTo(false)
      .sortByDateDesc()
      .findAll();

  double income = 0;
  double expense = 0;
  final Map<String, double> categoryData = {};
  final Map<String, double> incomeCategoryData = {};
  final Map<int, Map<int, double>> dailyIncome = {};
  final Map<int, Map<int, double>> dailyExpense = {};

  // Single pass aggregation
  for (final txn in allTxns) {
    txn.category.loadSync();
    final catName = txn.category.value?.name ?? 'Unknown';

    if (txn.isExpense) {
      expense += txn.amount;
      categoryData[catName] = (categoryData[catName] ?? 0) + txn.amount;

      if (period == 'Year') {
        final month = txn.date.month;
        dailyExpense[month] = dailyExpense[month] ?? {};
        dailyExpense[month]![0] = (dailyExpense[month]![0] ?? 0) + txn.amount;
      } else if (period == 'Today') {
        final hour = txn.date.hour;
        dailyExpense[hour] = dailyExpense[hour] ?? {};
        dailyExpense[hour]![0] = (dailyExpense[hour]![0] ?? 0) + txn.amount;
      } else {
        final dayIndex = txn.date.difference(start).inDays;
        dailyExpense[dayIndex] = dailyExpense[dayIndex] ?? {};
        dailyExpense[dayIndex]![0] =
            (dailyExpense[dayIndex]![0] ?? 0) + txn.amount;
      }
    } else {
      income += txn.amount;
      incomeCategoryData[catName] =
          (incomeCategoryData[catName] ?? 0) + txn.amount;

      if (period == 'Year') {
        final month = txn.date.month;
        dailyIncome[month] = dailyIncome[month] ?? {};
        dailyIncome[month]![0] = (dailyIncome[month]![0] ?? 0) + txn.amount;
      } else if (period == 'Today') {
        final hour = txn.date.hour;
        dailyIncome[hour] = dailyIncome[hour] ?? {};
        dailyIncome[hour]![0] = (dailyIncome[hour]![0] ?? 0) + txn.amount;
      } else {
        final dayIndex = txn.date.difference(start).inDays;
        dailyIncome[dayIndex] = dailyIncome[dayIndex] ?? {};
        dailyIncome[dayIndex]![0] =
            (dailyIncome[dayIndex]![0] ?? 0) + txn.amount;
      }
    }
  }

  // Build spots
  final List<FlSpot> incomeSpots = [];
  final List<FlSpot> expenseSpots = [];

  if (period == 'Year') {
    for (int month = 1; month <= 12; month++) {
      incomeSpots.add(
        FlSpot((month - 1).toDouble(), dailyIncome[month]?[0] ?? 0),
      );
      expenseSpots.add(
        FlSpot((month - 1).toDouble(), dailyExpense[month]?[0] ?? 0),
      );
    }
  } else if (period == 'Today') {
    for (int hour = 0; hour < 24; hour++) {
      incomeSpots.add(FlSpot(hour.toDouble(), dailyIncome[hour]?[0] ?? 0));
      expenseSpots.add(FlSpot(hour.toDouble(), dailyExpense[hour]?[0] ?? 0));
    }
  } else {
    final days = end.difference(start).inDays + 1;
    for (int i = 0; i < days; i++) {
      incomeSpots.add(FlSpot(i.toDouble(), dailyIncome[i]?[0] ?? 0));
      expenseSpots.add(FlSpot(i.toDouble(), dailyExpense[i]?[0] ?? 0));
    }
  }

  final Map<String, Category> categoryMapData = {for (var c in cats) c.name: c};
  final Map<String, Category> incomeCategoryMapData = {
    for (var c in cats) c.name: c,
  };
  final recent = allTxns.take(5).toList();
  final savingsRate = income > 0 ? ((income - expense) / income) * 100 : 0.0;
  final daysInPeriod = end.difference(start).inDays + 1;
  final avgDailySpend = expense / (daysInPeriod > 0 ? daysInPeriod : 1);

  // Calculate category trends for last 12 months
  final Map<Category, List<FlSpot>> categoryTrends = {};
  final trendStart = DateTime(now.year, now.month - 11, 1);
  final expenseTxns = allTxns
      .where((t) => t.isExpense && t.date.isAfter(trendStart))
      .toList();

  for (final cat in cats.where((c) => c.categoryType == CategoryType.expense)) {
    final monthlyData = <int, double>{};
    for (final txn in expenseTxns) {
      txn.category.loadSync();
      if (txn.category.value?.id == cat.id) {
        final monthIndex =
            (txn.date.year - trendStart.year) * 12 +
            (txn.date.month - trendStart.month);
        monthlyData[monthIndex] = (monthlyData[monthIndex] ?? 0) + txn.amount;
      }
    }
    if (monthlyData.isNotEmpty) {
      categoryTrends[cat] = List.generate(
        12,
        (i) => FlSpot(i.toDouble(), monthlyData[i] ?? 0),
      );
    }
  }

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
    recent: recent,
    categoryTrends: categoryTrends,
  );
});

// Custom date range stats provider - optimized
final customStatsProvider = FutureProvider.family<StatsData, String>((
  ref,
  dateKey,
) async {
  // Parse the date key format: "start_end"
  final parts = dateKey.split('_');
  if (parts.length != 2) {
    throw ArgumentError(
      'Invalid date key format. Expected: startMillis_endMillis',
    );
  }

  final start = DateTime.fromMillisecondsSinceEpoch(int.parse(parts[0]));
  final endDate = DateTime.fromMillisecondsSinceEpoch(int.parse(parts[1]));
  final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
  final days = endDate.difference(start).inDays + 1;

  final isar = await ref.watch(isarServiceProvider).getInstance();
  final cats = await isar.categorys.where().findAll();

  final allTxns = await isar.transactions
      .filter()
      .dateBetween(start, end)
      .isTransferEqualTo(false)
      .sortByDateDesc()
      .findAll();

  double income = 0;
  double expense = 0;
  final Map<int, double> dailyIncome = {};
  final Map<int, double> dailyExpense = {};
  final Map<String, double> categoryData = {};
  final Map<String, double> incomeCategoryData = {};

  for (final txn in allTxns) {
    final dayIndex = txn.date.difference(start).inDays;
    txn.category.loadSync();
    final catName = txn.category.value?.name ?? 'Unknown';

    if (txn.isExpense) {
      expense += txn.amount;
      dailyExpense[dayIndex] = (dailyExpense[dayIndex] ?? 0) + txn.amount;
      categoryData[catName] = (categoryData[catName] ?? 0) + txn.amount;
    } else {
      income += txn.amount;
      dailyIncome[dayIndex] = (dailyIncome[dayIndex] ?? 0) + txn.amount;
      incomeCategoryData[catName] =
          (incomeCategoryData[catName] ?? 0) + txn.amount;
    }
  }

  final List<FlSpot> incomeSpots = List.generate(
    days,
    (i) => FlSpot(i.toDouble(), dailyIncome[i] ?? 0),
  );
  final List<FlSpot> expenseSpots = List.generate(
    days,
    (i) => FlSpot(i.toDouble(), dailyExpense[i] ?? 0),
  );
  final Map<String, Category> categoryMapData = {for (var c in cats) c.name: c};
  final Map<String, Category> incomeCategoryMapData = {
    for (var c in cats) c.name: c,
  };
  final recent = allTxns.take(5).toList();
  final savingsRate = income > 0 ? ((income - expense) / income) * 100 : 0.0;
  final avgDailySpend = expense / days;

  // Calculate category trends for last 12 months
  final Map<Category, List<FlSpot>> categoryTrends = {};
  final now = DateTime.now();
  final trendStart = DateTime(now.year, now.month - 11, 1);
  final expenseTxns = allTxns
      .where((t) => t.isExpense && t.date.isAfter(trendStart))
      .toList();

  for (final cat in cats.where((c) => c.categoryType == CategoryType.expense)) {
    final monthlyData = <int, double>{};
    for (final txn in expenseTxns) {
      txn.category.loadSync();
      if (txn.category.value?.id == cat.id) {
        final monthIndex =
            (txn.date.year - trendStart.year) * 12 +
            (txn.date.month - trendStart.month);
        monthlyData[monthIndex] = (monthlyData[monthIndex] ?? 0) + txn.amount;
      }
    }
    if (monthlyData.isNotEmpty) {
      categoryTrends[cat] = List.generate(
        12,
        (i) => FlSpot(i.toDouble(), monthlyData[i] ?? 0),
      );
    }
  }

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
    recent: recent,
    categoryTrends: categoryTrends,
  );
});

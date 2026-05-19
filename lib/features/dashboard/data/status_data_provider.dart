// 1. Define the data structure:
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/exchange_rate.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/collection_watchers.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';

class StatsData {
  final double income;
  final double expense;
  final List<FlSpot> incomeSpots;
  final List<FlSpot> expenseSpots;
  final List<FlSpot> savingsSpots;
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
    required this.savingsSpots,
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
final statsProvider = FutureProvider.autoDispose.family<StatsData, String>((
  ref,
  period,
) async {
  ref.watch(transactionChangeProvider);
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
      .isSettlementEqualTo(false)
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
      expense += txn.effectiveAmount;
      categoryData[catName] = (categoryData[catName] ?? 0) + txn.effectiveAmount;

      if (period == 'Year') {
        final month = txn.date.month;
        dailyExpense[month] = dailyExpense[month] ?? {};
        dailyExpense[month]![0] = (dailyExpense[month]![0] ?? 0) + txn.effectiveAmount;
      } else if (period == 'Today') {
        final hour = txn.date.hour;
        dailyExpense[hour] = dailyExpense[hour] ?? {};
        dailyExpense[hour]![0] = (dailyExpense[hour]![0] ?? 0) + txn.effectiveAmount;
      } else {
        final dayIndex = txn.date.difference(start).inDays;
        dailyExpense[dayIndex] = dailyExpense[dayIndex] ?? {};
        dailyExpense[dayIndex]![0] =
            (dailyExpense[dayIndex]![0] ?? 0) + txn.amount;
      }
    } else {
      income += txn.effectiveAmount;
      incomeCategoryData[catName] =
          (incomeCategoryData[catName] ?? 0) + txn.effectiveAmount;

      if (period == 'Year') {
        final month = txn.date.month;
        dailyIncome[month] = dailyIncome[month] ?? {};
        dailyIncome[month]![0] = (dailyIncome[month]![0] ?? 0) + txn.effectiveAmount;
      } else if (period == 'Today') {
        final hour = txn.date.hour;
        dailyIncome[hour] = dailyIncome[hour] ?? {};
        dailyIncome[hour]![0] = (dailyIncome[hour]![0] ?? 0) + txn.effectiveAmount;
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
  final List<FlSpot> savingsSpots = [];

  if (period == 'Year') {
    for (int month = 1; month <= 12; month++) {
      final monthIncome = dailyIncome[month]?[0] ?? 0;
      final monthExpense = dailyExpense[month]?[0] ?? 0;
      incomeSpots.add(FlSpot((month - 1).toDouble(), monthIncome));
      expenseSpots.add(FlSpot((month - 1).toDouble(), monthExpense));
      savingsSpots
          .add(FlSpot((month - 1).toDouble(), monthIncome - monthExpense));
    }
  } else if (period == 'Today') {
    for (int hour = 0; hour < 24; hour++) {
      final hourIncome = dailyIncome[hour]?[0] ?? 0;
      final hourExpense = dailyExpense[hour]?[0] ?? 0;
      incomeSpots.add(FlSpot(hour.toDouble(), hourIncome));
      expenseSpots.add(FlSpot(hour.toDouble(), hourExpense));
      savingsSpots.add(FlSpot(hour.toDouble(), hourIncome - hourExpense));
    }
  } else {
    final days = end.difference(start).inDays + 1;
    for (int i = 0; i < days; i++) {
      final dayIncome = dailyIncome[i]?[0] ?? 0;
      final dayExpense = dailyExpense[i]?[0] ?? 0;
      incomeSpots.add(FlSpot(i.toDouble(), dayIncome));
      expenseSpots.add(FlSpot(i.toDouble(), dayExpense));
      savingsSpots.add(FlSpot(i.toDouble(), dayIncome - dayExpense));
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
  // BOLT OPTIMIZATION: Single-pass aggregation O(T) instead of O(C * T)
  final Map<int, List<double>> monthlyValues = {};
  final Map<int, Category> catMap = {};
  final trendStart = DateTime(now.year, now.month - 11, 1);

  for (final txn in allTxns) {
    if (!txn.isExpense || txn.date.isBefore(trendStart)) continue;
    final cat = txn.category.value;
    if (cat == null) continue;

    final monthIndex = (txn.date.year - trendStart.year) * 12 +
        (txn.date.month - trendStart.month);

    if (monthIndex >= 0 && monthIndex < 12) {
      catMap[cat.id] = cat;
      monthlyValues.putIfAbsent(cat.id, () => List<double>.filled(12, 0.0));
      monthlyValues[cat.id]![monthIndex] += txn.effectiveAmount;
    }
  }

  final categoryTrends = monthlyValues.map(
    (id, values) => MapEntry(
      catMap[id]!,
      List.generate(12, (i) => FlSpot(i.toDouble(), values[i])),
    ),
  );

  return StatsData(
    income: income,
    expense: expense,
    incomeSpots: incomeSpots,
    expenseSpots: expenseSpots,
    savingsSpots: savingsSpots,
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
final customStatsProvider = FutureProvider.autoDispose.family<StatsData, String>((
  ref,
  dateKey,
) async {
  ref.watch(transactionChangeProvider);
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
      .isSettlementEqualTo(false)
      .sortByDateDesc()
      .findAll();

  // Batch-load categories once
  for (final txn in allTxns) {
    txn.category.loadSync();
  }

  double income = 0;
  double expense = 0;
  final Map<int, double> dailyIncome = {};
  final Map<int, double> dailyExpense = {};
  final Map<String, double> categoryData = {};
  final Map<String, double> incomeCategoryData = {};

  for (final txn in allTxns) {
    final dayIndex = txn.date.difference(start).inDays;
    final catName = txn.category.value?.name ?? 'Unknown';

    if (txn.isExpense) {
      expense += txn.effectiveAmount;
      dailyExpense[dayIndex] = (dailyExpense[dayIndex] ?? 0) + txn.effectiveAmount;
      categoryData[catName] = (categoryData[catName] ?? 0) + txn.effectiveAmount;
    } else {
      income += txn.effectiveAmount;
      dailyIncome[dayIndex] = (dailyIncome[dayIndex] ?? 0) + txn.effectiveAmount;
      incomeCategoryData[catName] =
          (incomeCategoryData[catName] ?? 0) + txn.effectiveAmount;
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
  final List<FlSpot> savingsSpots = List.generate(
    days,
    (i) => FlSpot(i.toDouble(), (dailyIncome[i] ?? 0) - (dailyExpense[i] ?? 0)),
  );
  final Map<String, Category> categoryMapData = {for (var c in cats) c.name: c};
  final Map<String, Category> incomeCategoryMapData = {
    for (var c in cats) c.name: c,
  };
  final recent = allTxns.take(5).toList();
  final savingsRate = income > 0 ? ((income - expense) / income) * 100 : 0.0;
  final avgDailySpend = expense / days;

  // Calculate category trends for last 12 months
  // BOLT OPTIMIZATION: Single-pass aggregation O(T) instead of O(C * T)
  final Map<int, List<double>> monthlyValues = {};
  final Map<int, Category> catMap = {};
  final now = DateTime.now();
  final trendStart = DateTime(now.year, now.month - 11, 1);

  for (final txn in allTxns) {
    if (!txn.isExpense || txn.date.isBefore(trendStart)) continue;
    final cat = txn.category.value;
    if (cat == null) continue;

    final monthIndex = (txn.date.year - trendStart.year) * 12 +
        (txn.date.month - trendStart.month);

    if (monthIndex >= 0 && monthIndex < 12) {
      catMap[cat.id] = cat;
      monthlyValues.putIfAbsent(cat.id, () => List<double>.filled(12, 0.0));
      monthlyValues[cat.id]![monthIndex] += txn.effectiveAmount;
    }
  }

  final categoryTrends = monthlyValues.map(
    (id, values) => MapEntry(
      catMap[id]!,
      List.generate(12, (i) => FlSpot(i.toDouble(), values[i])),
    ),
  );

  return StatsData(
    income: income,
    expense: expense,
    incomeSpots: incomeSpots,
    expenseSpots: expenseSpots,
    savingsSpots: savingsSpots,
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

// Total account balance provider (in base currency)
final totalAccountBalanceProvider =
    FutureProvider.autoDispose<double>((ref) async {
  ref.watch(transactionChangeProvider);
  ref.watch(accountChangeProvider);
  final isar = await ref.watch(isarServiceProvider).getInstance();
  final accounts = await isar.collection<Account>().where().findAll();

  double totalBalance = 0.0;
  for (final account in accounts) {
    // BOLT OPTIMIZATION: Use Isar's aggregate sum instead of fetching all objects
    final results = await Future.wait([
      isar.transactions
          .filter()
          .account((q) => q.idEqualTo(account.id))
          .isExpenseEqualTo(false)
          .amountProperty()
          .sum(),
      isar.transactions
          .filter()
          .account((q) => q.idEqualTo(account.id))
          .isExpenseEqualTo(true)
          .amountProperty()
          .sum(),
    ]);

    final income = results[0];
    final expense = results[1];

    // Balance in account's own currency
    final rawBalance = account.initialBalance + income - expense;

    // Convert to base currency if account is foreign
    if (account.currencyCode != null) {
      final rate = await isar.exchangeRates
          .filter()
          .currencyCodeEqualTo(account.currencyCode!)
          .findFirst();
      totalBalance += rawBalance * (rate?.rateToBase ?? 1.0);
    } else {
      totalBalance += rawBalance;
    }
  }

  return totalBalance;
});

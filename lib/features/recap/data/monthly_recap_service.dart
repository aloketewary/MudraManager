import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/extensions/transaction_links.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/user_profile.dart';
import 'package:mudra_manager/features/gamification/models/achievement.dart';

class MonthlyRecapData {
  final String currency;
  final DateTime month;
  final double totalIncome;
  final double totalExpense;
  final double netSavings;
  final double savingsRate;
  final double avgDailySpend;
  final int transactionCount;
  final List<CategorySpend> topCategories;
  final List<CategorySpend> incomeCategories;
  final List<TransactionSummary> topTransactions;
  final List<TransactionSummary> topIncomeTransactions;
  final int budgetsKept;
  final int budgetsTotal;
  final List<BudgetUtilization> budgetDetails;
  final int achievementsUnlocked;
  final int currentStreak;
  final int longestStreak;
  final String? userName;

  // New analytics fields
  final Map<int, double> dailySpending; // day (1-31) → amount
  final double weekdayAvg;
  final double weekendAvg;
  final double prevMonthIncome;
  final double prevMonthExpense;
  final double firstHalfSpend;
  final double secondHalfSpend;
  final double recurringExpense;
  final double oneTimeExpense;
  final List<AccountSpend> accountBreakdown;
  final List<CategoryFrequency> categoryByFrequency;

  // Year-over-year comparison
  final double? yoyIncome;
  final double? yoyExpense;
  final int? yoyTransactionCount;

  MonthlyRecapData({
    String? currency,
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
    required this.savingsRate,
    required this.avgDailySpend,
    required this.transactionCount,
    required this.topCategories,
    required this.incomeCategories,
    required this.topTransactions,
    required this.topIncomeTransactions,
    required this.budgetsKept,
    required this.budgetsTotal,
    required this.budgetDetails,
    required this.achievementsUnlocked,
    required this.currentStreak,
    required this.longestStreak,
    this.userName,
    required this.dailySpending,
    required this.weekdayAvg,
    required this.weekendAvg,
    required this.prevMonthIncome,
    required this.prevMonthExpense,
    required this.firstHalfSpend,
    required this.secondHalfSpend,
    required this.recurringExpense,
    required this.oneTimeExpense,
    required this.accountBreakdown,
    required this.categoryByFrequency,
    this.yoyIncome,
    this.yoyExpense,
    this.yoyTransactionCount,
  }) : currency = currency ?? BaseCurrency.symbol;

  double get prevMonthSavings => prevMonthIncome - prevMonthExpense;
  double get incomeChange => prevMonthIncome > 0
      ? (totalIncome - prevMonthIncome) / prevMonthIncome * 100
      : 0;
  double get expenseChange => prevMonthExpense > 0
      ? (totalExpense - prevMonthExpense) / prevMonthExpense * 100
      : 0;
  bool get hasYoyData => yoyIncome != null || yoyExpense != null;
  double get yoyIncomeChange => (yoyIncome != null && yoyIncome! > 0)
      ? (totalIncome - yoyIncome!) / yoyIncome! * 100
      : 0;
  double get yoyExpenseChange => (yoyExpense != null && yoyExpense! > 0)
      ? (totalExpense - yoyExpense!) / yoyExpense! * 100
      : 0;
}

class CategorySpend {
  final String name;
  final double amount;
  final double percentage;
  CategorySpend(this.name, this.amount, this.percentage);
}

class TransactionSummary {
  final String description;
  final String category;
  final double amount;
  final DateTime date;
  TransactionSummary(this.description, this.category, this.amount, this.date);
}

class BudgetUtilization {
  final String name;
  final double allocated;
  final double spent;
  double get percentage => allocated > 0 ? (spent / allocated * 100) : 0;
  bool get overBudget => spent > allocated;
  BudgetUtilization(this.name, this.allocated, this.spent);
}

class AccountSpend {
  final String name;
  final double amount;
  final double percentage;
  AccountSpend(this.name, this.amount, this.percentage);
}

class CategoryFrequency {
  final String name;
  final int count;
  final double totalAmount;
  CategoryFrequency(this.name, this.count, this.totalAmount);
}

class MonthlyRecapService {
  final IsarService _isarService;
  MonthlyRecapService(this._isarService);

  Future<MonthlyRecapData> generate(
    DateTime month, {
    String? currency,
  }) async {
    final effectiveCurrency = currency ?? BaseCurrency.symbol;
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final daysInMonth = end.day;
    final midDay = (daysInMonth / 2).ceil();

    final _isar = await _isarService.getInstance();

    // ── Current month transactions ──
    final txns =
        await _isar.transactions.where().dateBetween(start, end).findAll().withLinks();
    double income = 0, expense = 0;
    final Map<String, double> catTotals = {};
    final Map<String, int> catCounts = {};
    final Map<String, double> incomeCatTotals = {};
    final Map<String, double> accountTotals = {};
    final Map<int, double> dailySpend = {};
    final expenseTxns = <Transaction>[];
    final incomeTxns = <Transaction>[];
    double weekdayTotal = 0, weekendTotal = 0;
    double firstHalf = 0, secondHalf = 0;
    double recurringExp = 0, oneTimeExp = 0;

    // Track which days are weekday/weekend for averaging
    final Set<int> weekdayDaysSeen = {}, weekendDaysSeen = {};

    for (final txn in txns) {
      if (txn.isTransfer) continue;

      if (txn.isExpense) {
        expense += txn.baseAmount;
        final catName = txn.category.value?.name ?? 'Uncategorized';
        catTotals[catName] = (catTotals[catName] ?? 0) + txn.baseAmount;
        catCounts[catName] = (catCounts[catName] ?? 0) + 1;
        expenseTxns.add(txn);

        // Daily spending
        dailySpend[txn.date.day] = (dailySpend[txn.date.day] ?? 0) + txn.baseAmount;

        // Weekday vs weekend
        final wd = txn.date.weekday;
        if (wd >= 6) {
          weekendTotal += txn.baseAmount;
          weekendDaysSeen.add(txn.date.day);
        } else {
          weekdayTotal += txn.baseAmount;
          weekdayDaysSeen.add(txn.date.day);
        }

        // First half vs second half
        if (txn.date.day <= midDay) {
          firstHalf += txn.baseAmount;
        } else {
          secondHalf += txn.baseAmount;
        }

        // Recurring vs one-time
        await txn.recurringTransactionSource.load();
        if (txn.recurringTransactionSource.value != null) {
          recurringExp += txn.baseAmount;
        } else {
          oneTimeExp += txn.baseAmount;
        }

        // Account breakdown
        final accName = txn.account.value?.name ?? 'Unknown';
        accountTotals[accName] = (accountTotals[accName] ?? 0) + txn.baseAmount;
      } else {
        income += txn.baseAmount;
        final catName = txn.category.value?.name ?? 'Other Income';
        incomeCatTotals[catName] = (incomeCatTotals[catName] ?? 0) + txn.baseAmount;
        incomeTxns.add(txn);
      }
    }

    // ── Previous month for comparison ──
    final prevStart = DateTime(month.year, month.month - 1, 1);
    final prevEnd = DateTime(month.year, month.month, 0, 23, 59, 59);
    final prevTxns = await _isar.transactions
        .where()
        .dateBetween(prevStart, prevEnd)
        .findAll();
    double prevIncome = 0, prevExpense = 0;
    for (final txn in prevTxns) {
      if (txn.isTransfer) continue;
      if (txn.isExpense) {
        prevExpense += txn.baseAmount;
      } else {
        prevIncome += txn.baseAmount;
      }
    }

    // ── Top expense categories ──
    final sortedCats = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCats
        .take(8)
        .map(
          (e) => CategorySpend(
            e.key,
            e.value,
            expense > 0 ? e.value / expense * 100 : 0,
          ),
        )
        .toList();

    // ── Income categories ──
    final sortedIncomeCats = incomeCatTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final incomeCategories = sortedIncomeCats
        .take(5)
        .map(
          (e) => CategorySpend(
            e.key,
            e.value,
            income > 0 ? e.value / income * 100 : 0,
          ),
        )
        .toList();

    // ── Top 5 biggest expenses ──
    expenseTxns.sort((a, b) => b.amount.compareTo(a.amount));
    final topTxns = <TransactionSummary>[];
    for (final txn in expenseTxns.take(5)) {
      topTxns.add(
        TransactionSummary(
          txn.description ?? 'No description',
          txn.category.value?.name ?? 'Uncategorized',
          txn.baseAmount,
          txn.date,
        ),
      );
    }

    // ── Top 5 income transactions ──
    incomeTxns.sort((a, b) => b.amount.compareTo(a.amount));
    final topIncomeTxns = <TransactionSummary>[];
    for (final txn in incomeTxns.take(5)) {
      topIncomeTxns.add(
        TransactionSummary(
          txn.description ?? 'No description',
          txn.category.value?.name ?? 'Other Income',
          txn.baseAmount,
          txn.date,
        ),
      );
    }

    // ── Account breakdown ──
    final sortedAccounts = accountTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final accountBreakdown = sortedAccounts
        .map(
          (e) => AccountSpend(
            e.key,
            e.value,
            expense > 0 ? e.value / expense * 100 : 0,
          ),
        )
        .toList();

    // ── Category by frequency ──
    final sortedByFreq = catCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final categoryByFrequency = sortedByFreq
        .take(8)
        .map((e) => CategoryFrequency(e.key, e.value, catTotals[e.key] ?? 0))
        .toList();

    // ── Budgets ──
    final budgets = await _isar.budgets.where().findAll();
    final monthBudgets = budgets
        .where((b) => b.startDate.isBefore(end) && b.endDate.isAfter(start))
        .toList();

    // Budget utilization details
    final budgetDetails = <BudgetUtilization>[];
    int kept = 0;
    for (final b in monthBudgets) {
      await b.categories.load();
      final catIds = b.categories.map((c) => c.id).toSet();
      double spent = 0;
      for (final txn in expenseTxns) {
        if (catIds.isEmpty || catIds.contains(txn.category.value?.id)) {
          spent += txn.baseAmount;
        }
      }
      if (spent <= b.amount) kept++;
      budgetDetails.add(BudgetUtilization(b.name, b.amount, spent));
    }

    // ── Achievements & Streaks ──
    final achievements = await _isar.achievements.where().findAll();
    final unlockedCount = achievements
        .where(
          (a) =>
              a.unlockedAt != null &&
              a.unlockedAt!.isAfter(start) &&
              a.unlockedAt!.isBefore(end),
        )
        .length;

    final streaks = await _isar.streaks.where().findAll();
    final daily = streaks.where((s) => s.type == 'daily_checkin').firstOrNull;

    // ── Year-over-year comparison ──
    final yoyStart = DateTime(month.year - 1, month.month, 1);
    final yoyEnd = DateTime(month.year - 1, month.month + 1, 0, 23, 59, 59);
    final yoyTxns = await _isar.transactions
        .where()
        .dateBetween(yoyStart, yoyEnd)
        .findAll();
    double? yoyIncome, yoyExpense;
    int? yoyTxnCount;
    if (yoyTxns.isNotEmpty) {
      double yi = 0, ye = 0;
      int count = 0;
      for (final txn in yoyTxns) {
        if (txn.isTransfer) continue;
        count++;
        if (txn.isExpense) {
          ye += txn.baseAmount;
        } else {
          yi += txn.baseAmount;
        }
      }
      yoyIncome = yi;
      yoyExpense = ye;
      yoyTxnCount = count;
    }

    // ── User ──
    final profile = await _isar.userProfiles.where().findFirst();

    final net = income - expense;
    final wdAvg = weekdayDaysSeen.isNotEmpty
        ? weekdayTotal / weekdayDaysSeen.length
        : 0.0;
    final weAvg = weekendDaysSeen.isNotEmpty
        ? weekendTotal / weekendDaysSeen.length
        : 0.0;

    return MonthlyRecapData(
      currency: effectiveCurrency,
      month: start,
      totalIncome: income,
      totalExpense: expense,
      netSavings: net,
      savingsRate: income > 0 ? net / income * 100 : 0,
      avgDailySpend: daysInMonth > 0 ? expense / daysInMonth : 0,
      transactionCount: txns.where((t) => !t.isTransfer).length,
      topCategories: topCategories,
      incomeCategories: incomeCategories,
      topTransactions: topTxns,
      topIncomeTransactions: topIncomeTxns,
      budgetsKept: kept,
      budgetsTotal: monthBudgets.length,
      budgetDetails: budgetDetails,
      achievementsUnlocked: unlockedCount,
      currentStreak: daily?.currentCount ?? 0,
      longestStreak: daily?.longestCount ?? 0,
      userName: profile?.name,
      dailySpending: dailySpend,
      weekdayAvg: wdAvg,
      weekendAvg: weAvg,
      prevMonthIncome: prevIncome,
      prevMonthExpense: prevExpense,
      firstHalfSpend: firstHalf,
      secondHalfSpend: secondHalf,
      recurringExpense: recurringExp,
      oneTimeExpense: oneTimeExp,
      accountBreakdown: accountBreakdown,
      categoryByFrequency: categoryByFrequency,
      yoyIncome: yoyIncome,
      yoyExpense: yoyExpense,
      yoyTransactionCount: yoyTxnCount,
    );
  }
}

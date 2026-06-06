import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/extensions/field_encryption_ext.dart';
import 'package:mudra_manager/core/db/extensions/transaction_links.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/user_profile.dart';
import 'package:mudra_manager/features/gamification/models/achievement.dart';

// ── Data Models ──

class MonthlyRecapData {
  final String currency;
  final DateTime month;
  final double totalIncome;
  final double totalExpense;
  final double netSavings;
  final double savingsRate;
  final double avgDailySpend;
  final int transactionCount;
  final String? userName;

  // Financial Score
  final int financialScore;
  final int financialScoreDelta;

  // AI Insight
  final RecapInsight insight;

  // Achievement/Warning
  final List<RecapAchievement> achievements;

  // Category Change Leaders
  final List<CategoryChange> categoryChanges;

  // Budget Utilization (only >70% or breached)
  final List<BudgetUtilization> budgetDetails;

  // Biggest Expenses (top 5)
  final List<TransactionSummary> topTransactions;

  // Previous month (for computations)
  final double prevMonthIncome;
  final double prevMonthExpense;
  final double prevSavingsRate;

  MonthlyRecapData({
    String? currency,
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
    required this.savingsRate,
    required this.avgDailySpend,
    required this.transactionCount,
    this.userName,
    required this.financialScore,
    required this.financialScoreDelta,
    required this.insight,
    required this.achievements,
    required this.categoryChanges,
    required this.budgetDetails,
    required this.topTransactions,
    required this.prevMonthIncome,
    required this.prevMonthExpense,
    required this.prevSavingsRate,
  }) : currency = currency ?? BaseCurrency.symbol;
}

class RecapInsight {
  final List<String> lines;
  final String? suggestedFocus;

  RecapInsight({required this.lines, this.suggestedFocus});

  bool get isEmpty => lines.isEmpty;
}

class RecapAchievement {
  final String text;
  final bool isWarning;

  RecapAchievement({required this.text, this.isWarning = false});
}

class CategoryChange {
  final String name;
  final double currentAmount;
  final double previousAmount;

  CategoryChange({
    required this.name,
    required this.currentAmount,
    required this.previousAmount,
  });

  double get delta => currentAmount - previousAmount;
  double get deltaPercent =>
      previousAmount > 0 ? delta / previousAmount * 100 : 0;
  bool get increased => delta > 0;
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

// Keep these for PDF compatibility
class CategorySpend {
  final String name;
  final double amount;
  final double percentage;
  CategorySpend(this.name, this.amount, this.percentage);
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

// ── Service ──

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

    final isar = await _isarService.getInstance();

    // ── Current month transactions ──
    final txns = await isar.transactions
        .where()
        .dateBetween(start, end)
        .findAll()
        .withLinks();

    double income = 0, expense = 0;
    final Map<String, double> catTotals = {};
    final expenseTxns = <Transaction>[];

    for (final txn in txns) {
      if (txn.isTransfer) continue;
      if (txn.isExpense) {
        expense += txn.baseAmount;
        final catName = txn.category.value?.name ?? 'Uncategorized';
        catTotals[catName] = (catTotals[catName] ?? 0) + txn.baseAmount;
        expenseTxns.add(txn);
      } else {
        income += txn.baseAmount;
      }
    }

    // ── Previous month ──
    final prevStart = DateTime(month.year, month.month - 1, 1);
    final prevEnd = DateTime(month.year, month.month, 0, 23, 59, 59);
    final prevTxns = await isar.transactions
        .where()
        .dateBetween(prevStart, prevEnd)
        .findAll()
        .withLinks();

    double prevIncome = 0, prevExpense = 0;
    final Map<String, double> prevCatTotals = {};

    for (final txn in prevTxns) {
      if (txn.isTransfer) continue;
      if (txn.isExpense) {
        prevExpense += txn.baseAmount;
        final catName = txn.category.value?.name ?? 'Uncategorized';
        prevCatTotals[catName] = (prevCatTotals[catName] ?? 0) + txn.baseAmount;
      } else {
        prevIncome += txn.baseAmount;
      }
    }

    final net = income - expense;
    final savingsRate = income > 0 ? net / income * 100 : 0.0;
    final prevNet = prevIncome - prevExpense;
    final prevSavingsRate = prevIncome > 0 ? prevNet / prevIncome * 100 : 0.0;

    // ── Category Change Leaders ──
    final allCats = {...catTotals.keys, ...prevCatTotals.keys};
    final categoryChanges = <CategoryChange>[];
    for (final cat in allCats) {
      final current = catTotals[cat] ?? 0;
      final prev = prevCatTotals[cat] ?? 0;
      if ((current - prev).abs() > 0) {
        categoryChanges.add(CategoryChange(
          name: cat,
          currentAmount: current,
          previousAmount: prev,
        ));
      }
    }
    categoryChanges.sort((a, b) => b.delta.abs().compareTo(a.delta.abs()));
    final topCategoryChanges = categoryChanges.take(5).toList();

    // ── Budgets (only >70% or breached) ──
    final budgets = await isar.budgets.where().findAll();
    final monthBudgets = budgets
        .where((b) => b.startDate.isBefore(end) && b.endDate.isAfter(start))
        .toList();

    final budgetDetails = <BudgetUtilization>[];
    for (final b in monthBudgets) {
      await b.categories.load();
      final catIds = b.categories.map((c) => c.id).toSet();
      double spent = 0;
      for (final txn in expenseTxns) {
        if (catIds.isEmpty || catIds.contains(txn.category.value?.id)) {
          spent += txn.baseAmount;
        }
      }
      final pct = b.amount > 0 ? spent / b.amount * 100 : 0;
      if (pct >= 70) {
        budgetDetails.add(BudgetUtilization(b.name, b.amount, spent));
      }
    }
    budgetDetails.sort((a, b) => b.percentage.compareTo(a.percentage));

    // ── Top 5 biggest expenses ──
    expenseTxns.sort((a, b) => b.amount.compareTo(a.amount));
    final topTxns = expenseTxns.take(5).map((txn) => TransactionSummary(
          txn.description ?? '',
          txn.category.value?.name ?? 'Uncategorized',
          txn.baseAmount,
          txn.date,
        )).toList();

    // ── Financial Score ──
    final score = _computeFinancialScore(
      savingsRate: savingsRate,
      budgetDetails: budgetDetails,
      expense: expense,
      prevExpense: prevExpense,
    );
    final prevScore = _computeFinancialScore(
      savingsRate: prevSavingsRate,
      budgetDetails: [], // approximate
      expense: prevExpense,
      prevExpense: 0,
    );

    // ── AI Insight ──
    final insight = _buildInsight(
      income: income,
      expense: expense,
      prevIncome: prevIncome,
      prevExpense: prevExpense,
      savingsRate: savingsRate,
      prevSavingsRate: prevSavingsRate,
      categoryChanges: topCategoryChanges,
      budgetDetails: budgetDetails,
      topTxns: topTxns,
      currency: effectiveCurrency,
    );

    // ── Achievements/Warnings ──
    final achievementsList = await _buildAchievements(
      isar,
      month: start,
      savingsRate: savingsRate,
      net: net,
      budgetDetails: budgetDetails,
    );

    // ── User ──
    final profile =
        await isar.userProfiles.where().findFirst().withDecryption();

    return MonthlyRecapData(
      currency: effectiveCurrency,
      month: start,
      totalIncome: income,
      totalExpense: expense,
      netSavings: net,
      savingsRate: savingsRate,
      avgDailySpend: daysInMonth > 0 ? expense / daysInMonth : 0,
      transactionCount: txns.where((t) => !t.isTransfer).length,
      userName: profile?.name,
      financialScore: score,
      financialScoreDelta: score - prevScore,
      insight: insight,
      achievements: achievementsList,
      categoryChanges: topCategoryChanges,
      budgetDetails: budgetDetails,
      topTransactions: topTxns,
      prevMonthIncome: prevIncome,
      prevMonthExpense: prevExpense,
      prevSavingsRate: prevSavingsRate,
    );
  }

  // ── Financial Score (0-100) ──
  int _computeFinancialScore({
    required double savingsRate,
    required List<BudgetUtilization> budgetDetails,
    required double expense,
    required double prevExpense,
  }) {
    // Savings component (0-40 points)
    final savingsScore = (savingsRate.clamp(0, 40)).round();

    // Budget adherence (0-30 points)
    int budgetScore = 30;
    for (final b in budgetDetails) {
      if (b.overBudget) budgetScore -= 10;
      else if (b.percentage > 90) budgetScore -= 5;
    }
    budgetScore = budgetScore.clamp(0, 30);

    // Spending control (0-30 points) — less than or equal to prev month = full marks
    int spendScore = 30;
    if (prevExpense > 0 && expense > prevExpense) {
      final increase = (expense - prevExpense) / prevExpense * 100;
      spendScore = (30 - increase).round().clamp(0, 30);
    }

    return (savingsScore + budgetScore + spendScore).clamp(0, 100);
  }

  // ── AI Insight Builder ──
  RecapInsight _buildInsight({
    required double income,
    required double expense,
    required double prevIncome,
    required double prevExpense,
    required double savingsRate,
    required double prevSavingsRate,
    required List<CategoryChange> categoryChanges,
    required List<BudgetUtilization> budgetDetails,
    required List<TransactionSummary> topTxns,
    required String currency,
  }) {
    final lines = <String>[];

    // Spending change
    if (prevExpense > 0) {
      final delta = expense - prevExpense;
      final pct = (delta / prevExpense * 100).abs().round();
      if (delta > 0) {
        lines.add(
            'Spending increased by $currency${delta.round().abs()} (+$pct%) from last month.');
      } else if (delta < 0) {
        lines.add(
            'Spending decreased by $currency${delta.round().abs()} (-$pct%) from last month.');
      }
    }

    // Top category contributor to change
    if (categoryChanges.isNotEmpty) {
      final top = categoryChanges.first;
      if (top.increased) {
        lines.add(
            '${top.name} contributed $currency${top.delta.round()} of the increase.');
      } else {
        lines.add(
            '${top.name} spending fell by $currency${top.delta.round().abs()}.');
      }
    }

    // Savings rate change
    if (prevSavingsRate > 0) {
      if ((savingsRate - prevSavingsRate).abs() > 2) {
        lines.add(
            'Savings rate ${savingsRate > prevSavingsRate ? "improved" : "dropped"} from ${prevSavingsRate.round()}% to ${savingsRate.round()}%.');
      }
    }

    // Budget breaches
    final breached = budgetDetails.where((b) => b.overBudget).toList();
    for (final b in breached.take(2)) {
      final over = b.spent - b.allocated;
      lines.add(
          'Exceeded ${b.name} budget by $currency${over.round()}.');
    }

    // Largest expense
    if (topTxns.isNotEmpty) {
      final biggest = topTxns.first;
      final desc = biggest.description.isNotEmpty
          ? biggest.description
          : biggest.category;
      lines.add(
          'Largest expense: $currency${biggest.amount.round()} ($desc).');
    }

    // Suggested focus
    String? focus;
    if (categoryChanges.isNotEmpty && categoryChanges.first.increased) {
      final top = categoryChanges.first;
      final reductionNeeded = ((savingsRate - prevSavingsRate).abs() > 2 &&
              savingsRate < prevSavingsRate)
          ? ' to recover your savings rate'
          : '';
      focus =
          'Reduce ${top.name} spending by 20%$reductionNeeded.';
    }

    return RecapInsight(lines: lines, suggestedFocus: focus);
  }

  // ── Achievements/Warnings ──
  Future<List<RecapAchievement>> _buildAchievements(
    Isar isar, {
    required DateTime month,
    required double savingsRate,
    required double net,
    required List<BudgetUtilization> budgetDetails,
  }) async {
    final results = <RecapAchievement>[];

    // Check if best savings month in last 12 months
    final yearAgo = DateTime(month.year - 1, month.month, 1);
    final prevMonths = await isar.transactions
        .where()
        .dateBetween(yearAgo, month)
        .findAll();

    // Group by month and compute savings
    final Map<String, double> monthlySavings = {};
    for (final txn in prevMonths) {
      if (txn.isTransfer) continue;
      final key = '${txn.date.year}-${txn.date.month}';
      monthlySavings[key] = (monthlySavings[key] ?? 0) +
          (txn.isExpense ? -txn.baseAmount : txn.baseAmount);
    }

    final currentKey = '${month.year}-${month.month}';
    final otherMonths = monthlySavings.entries
        .where((e) => e.key != currentKey)
        .map((e) => e.value)
        .toList();

    if (otherMonths.isNotEmpty && net > 0) {
      final maxPrev = otherMonths.reduce((a, b) => a > b ? a : b);
      if (net > maxPrev) {
        results.add(RecapAchievement(text: 'Best savings month in 12 months 🎉'));
      }
    }

    // High savings rate
    if (savingsRate >= 30) {
      results.add(RecapAchievement(text: 'Saved ${savingsRate.round()}% of income 💪'));
    }

    // Budget breaches as warnings
    final breachedCount = budgetDetails.where((b) => b.overBudget).length;
    if (breachedCount >= 2) {
      results.add(RecapAchievement(
        text: '$breachedCount budgets exceeded this month',
        isWarning: true,
      ));
    }

    // Streaks
    final streaks = await isar.streaks.where().findAll();
    final daily = streaks.where((s) => s.type == 'daily_checkin').firstOrNull;
    if (daily != null && daily.currentCount >= 30) {
      results.add(RecapAchievement(
          text: '${daily.currentCount}-day tracking streak 🔥'));
    }

    return results;
  }
}

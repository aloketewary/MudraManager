import 'package:mudra_manager/core/db/models/transaction.dart';

/// Bolt: Optimized Analytics Data Processing
///
/// Impact:
/// - Reduces database queries from O(K) to O(1) where K is the number of dependent providers.
/// - Optimizes processing from O(M * N) to O(N) by using single-pass aggregation.
/// - Minimizes redundant Isar IPC overhead by sharing the transaction list.
class AdvancedAnalyticsService {
  AdvancedAnalyticsService();

  // Predict next month spending based on last 3 months
  // OPTIMIZED: O(N) single-pass aggregation
  double predictMonthlySpending(List<Transaction> transactions) {
    final now = DateTime.now();
    final monthTotals = <int, double>{}; // key: year * 12 + month

    for (final tx in transactions) {
      if (!tx.isExpense || !tx.affectsStats) continue;

      final monthKey = tx.date.year * 12 + tx.date.month;
      monthTotals[monthKey] = (monthTotals[monthKey] ?? 0) + tx.effectiveAmount;
    }

    double total = 0;
    int count = 0;

    for (int i = 1; i <= 3; i++) {
      final month = DateTime(now.year, now.month - i);
      final monthKey = month.year * 12 + month.month;
      final monthTotal = monthTotals[monthKey] ?? 0;

      if (monthTotal > 0) {
        total += monthTotal;
        count++;
      }
    }

    return count > 0 ? total / count : 0;
  }

  /// Cash flow forecast for the next 3 months.
  /// Uses weighted average of last 6 months for both income and expense.
  // OPTIMIZED: O(N) single-pass aggregation
  CashFlowForecast forecastCashFlow(List<Transaction> transactions) {
    final now = DateTime.now();

    // key: year * 12 + month
    final incomeTotals = <int, double>{};
    final expenseTotals = <int, double>{};

    for (final tx in transactions) {
      if (tx.isTransfer) continue;

      final monthKey = tx.date.year * 12 + tx.date.month;
      if (tx.isExpense) {
        expenseTotals[monthKey] =
            (expenseTotals[monthKey] ?? 0) + tx.effectiveAmount;
      } else {
        incomeTotals[monthKey] =
            (incomeTotals[monthKey] ?? 0) + tx.effectiveAmount;
      }
    }

    // Build 6-month history
    final incomeHistory = <double>[];
    final expenseHistory = <double>[];

    for (int i = 1; i <= 6; i++) {
      final month = DateTime(now.year, now.month - i);
      final monthKey = month.year * 12 + month.month;
      incomeHistory.add(incomeTotals[monthKey] ?? 0);
      expenseHistory.add(expenseTotals[monthKey] ?? 0);
    }

    // Current month (partial)
    final currentMonthKey = now.year * 12 + now.month;
    final currentIncome = incomeTotals[currentMonthKey] ?? 0;
    final currentExpense = expenseTotals[currentMonthKey] ?? 0;

    // Project current month to full month
    final daysElapsed = now.day;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final projectedIncome = daysElapsed > 0
        ? currentIncome / daysElapsed * daysInMonth
        : _weightedAvg(incomeHistory);
    final projectedExpense = daysElapsed > 0
        ? currentExpense / daysElapsed * daysInMonth
        : _weightedAvg(expenseHistory);

    // Forecast next 3 months using weighted average
    final forecastMonths = <MonthForecast>[];
    final incForecast = _weightedAvg(incomeHistory);
    final expForecast = _weightedAvg(expenseHistory);

    for (int i = 1; i <= 3; i++) {
      final forecastMonth = DateTime(now.year, now.month + i);
      forecastMonths.add(
        MonthForecast(
          month: forecastMonth,
          income: incForecast,
          expense: expForecast,
          net: incForecast - expForecast,
        ),
      );
    }

    final avgNet = forecastMonths.isEmpty
        ? 0.0
        : forecastMonths.map((f) => f.net).reduce((a, b) => a + b) / 3;

    return CashFlowForecast(
      currentMonthIncome: currentIncome,
      currentMonthExpense: currentExpense,
      projectedMonthIncome: projectedIncome,
      projectedMonthExpense: projectedExpense,
      incomeHistory: incomeHistory,
      expenseHistory: expenseHistory,
      forecastMonths: forecastMonths,
      avgMonthlyNet: avgNet,
    );
  }

  double _weightedAvg(List<double> values) {
    if (values.isEmpty) return 0;
    const weights = [0.30, 0.25, 0.20, 0.12, 0.08, 0.05];
    double sum = 0, wSum = 0;
    for (int i = 0; i < values.length && i < weights.length; i++) {
      if (values[i] > 0) {
        sum += values[i] * weights[i];
        wSum += weights[i];
      }
    }
    return wSum > 0 ? sum / wSum : 0;
  }

  // Calculate financial health score (0-100)
  // OPTIMIZED: O(N) single-pass aggregation
  FinancialHealthScore calculateHealthScore(
    List<Transaction> transactions,
    double totalBalance,
  ) {
    final now = DateTime.now();
    double income = 0;
    double expense = 0;

    for (final tx in transactions) {
      if (tx.date.year == now.year &&
          tx.date.month == now.month &&
          tx.affectsStats) {
        if (tx.isExpense) {
          expense += tx.effectiveAmount;
        } else {
          income += tx.effectiveAmount;
        }
      }
    }

    if (income == 0) {
      return FinancialHealthScore(
        score: 0,
        rating: 'Poor',
        insights: ['Add income to calculate health score'],
      );
    }

    final savingsRate = ((income - expense) / income * 100).clamp(0, 100);
    final expenseRatio = (expense / income * 100).clamp(0, 100);

    double score = 0;
    final insights = <String>[];

    // 1. Savings Rate (30 points)
    if (savingsRate >= 30) {
      score += 30;
      insights.add('Excellent savings rate!');
    } else if (savingsRate >= 20) {
      score += 25;
      insights.add('Good savings habit');
    } else if (savingsRate >= 10) {
      score += 15;
      insights.add('Try to save 20% of income');
    } else {
      score += 5;
      insights.add('Aim to save at least 10% monthly');
    }

    // 2. Budget Discipline (30 points) - based on expense ratio
    if (expenseRatio <= 50) {
      score += 30;
    } else if (expenseRatio <= 70) {
      score += 20;
      insights.add('Keep expenses under 70%');
    } else if (expenseRatio <= 90) {
      score += 10;
      insights.add('Expenses are high, review spending');
    } else {
      insights.add('Critical: Expenses exceed income');
    }

    // 3. Debt Factor (20 points) - negative balance indicates debt
    if (totalBalance >= 0) {
      score += 20;
    } else if (totalBalance >= -income) {
      score += 10;
      insights.add('Work on clearing debt');
    } else {
      insights.add('High debt level detected');
    }

    // 4. Emergency Fund (20 points) - 3-6 months of expenses
    final monthlyExpense = expense;
    if (totalBalance >= monthlyExpense * 6) {
      score += 20;
      insights.add('Strong emergency fund!');
    } else if (totalBalance >= monthlyExpense * 3) {
      score += 15;
    } else if (totalBalance >= monthlyExpense) {
      score += 10;
      insights.add('Build 3-6 months emergency fund');
    } else if (totalBalance > 0) {
      score += 5;
      insights.add('Start building emergency fund');
    }

    final rating = score >= 80
        ? 'Excellent'
        : score >= 60
            ? 'Good'
            : score >= 40
                ? 'Fair'
                : 'Poor';

    return FinancialHealthScore(
      score: score.round(),
      rating: rating,
      savingsRate: savingsRate.toDouble(),
      expenseRatio: expenseRatio.toDouble(),
      insights: insights,
    );
  }

  // Spending by category trends
  // OPTIMIZED: O(N) single-pass aggregation
  Map<String, CategoryTrend> getCategoryTrends(List<Transaction> transactions) {
    final now = DateTime.now();

    // Build 6-month history per category
    final catMonths = <String, List<double>>{};

    for (final tx in transactions) {
      if (!tx.isExpense || !tx.affectsStats) continue;

      // Calculate month index (0 = this month, 1 = last month, ..., 5 = 5 months ago)
      final monthDiff =
          (now.year - tx.date.year) * 12 + (now.month - tx.date.month);

      if (monthDiff >= 0 && monthDiff < 6) {
        final name = tx.category.value?.name ?? 'Uncategorized';
        catMonths.putIfAbsent(name, () => List.filled(6, 0.0));
        catMonths[name]![monthDiff] += tx.effectiveAmount;
      }
    }

    final trends = <String, CategoryTrend>{};
    for (final entry in catMonths.entries) {
      final history =
          entry.value; // [thisMonth, lastMonth, 2ago, 3ago, 4ago, 5ago]
      final thisMonth = history[0];
      final lastMonth = history[1];

      // Predict next month using weighted average (recent months weigh more)
      final weights = [0.35, 0.25, 0.20, 0.10, 0.05, 0.05];
      double predicted = 0;
      double totalWeight = 0;
      for (int i = 0; i < 6; i++) {
        if (history[i] > 0) {
          predicted += history[i] * weights[i];
          totalWeight += weights[i];
        }
      }
      predicted = totalWeight > 0 ? predicted / totalWeight : 0;

      // Determine trend direction from last 3 months
      final recent3 = history.sublist(0, 3);
      final direction = _classifyTrend(recent3);

      // Anomaly: this month > 2x the average of months 1-5
      final pastAvgValues = history.sublist(1).where((v) => v > 0).toList();
      final avg = pastAvgValues.isNotEmpty
          ? pastAvgValues.reduce((a, b) => a + b) / pastAvgValues.length
          : 0.0;
      final isAnomaly = avg > 0 && thisMonth > avg * 2;

      trends[entry.key] = CategoryTrend(
        categoryName: entry.key,
        thisMonth: thisMonth,
        lastMonth: lastMonth,
        monthlyHistory: history,
        predictedNextMonth: predicted,
        direction: direction,
        isAnomaly: isAnomaly,
      );
    }

    return trends;
  }

  TrendDirection _classifyTrend(List<double> recent3) {
    if (recent3.length < 3) return TrendDirection.stable;
    // recent3[0] = this month, [1] = last month, [2] = 2 months ago
    final increasing = recent3[0] > recent3[1] && recent3[1] > recent3[2];
    final decreasing = recent3[0] < recent3[1] && recent3[1] < recent3[2];
    if (increasing) return TrendDirection.rising;
    if (decreasing) return TrendDirection.falling;
    return TrendDirection.stable;
  }

  // Predict budget exhaustion date
  DateTime? predictBudgetExhaustion(
    List<Transaction> transactions,
    double budgetAmount,
  ) {
    final now = DateTime.now();
    double spent = 0;

    for (final tx in transactions) {
      if (tx.isExpense &&
          tx.date.year == now.year &&
          tx.date.month == now.month) {
        spent += tx.effectiveAmount;
      }
    }

    final remaining = budgetAmount - spent;

    if (remaining <= 0) return now;

    final daysElapsed = now.day;
    final dailyBurnRate = spent / daysElapsed;

    if (dailyBurnRate == 0) return null;

    final daysRemaining = (remaining / dailyBurnRate).ceil();
    return now.add(Duration(days: daysRemaining));
  }

  // Get spending patterns by day of week
  // OPTIMIZED: O(N) single-pass aggregation
  Map<String, double> getSpendingByDayOfWeek(List<Transaction> transactions) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 90));

    final byDay = <String, double>{
      'Mon': 0,
      'Tue': 0,
      'Wed': 0,
      'Thu': 0,
      'Fri': 0,
      'Sat': 0,
      'Sun': 0,
    };

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (final tx in transactions) {
      if (tx.isExpense && tx.date.isAfter(cutoff)) {
        final dayName = days[tx.date.weekday - 1];
        byDay[dayName] = (byDay[dayName] ?? 0) + tx.effectiveAmount;
      }
    }

    return byDay;
  }
}

class FinancialHealthScore {
  final int score;
  final String rating;
  final double savingsRate;
  final double expenseRatio;
  final List<String> insights;

  FinancialHealthScore({
    required this.score,
    required this.rating,
    this.savingsRate = 0,
    this.expenseRatio = 0,
    required this.insights,
  });
}

class CategoryTrend {
  final String categoryName;
  double thisMonth;
  double lastMonth;
  final List<double> monthlyHistory; // last 6 months, newest first
  final double predictedNextMonth;
  final TrendDirection direction;
  final bool isAnomaly;

  CategoryTrend({
    required this.categoryName,
    required this.thisMonth,
    required this.lastMonth,
    this.monthlyHistory = const [],
    this.predictedNextMonth = 0,
    this.direction = TrendDirection.stable,
    this.isAnomaly = false,
  });

  double get change => thisMonth - lastMonth;
  double get changePercent => lastMonth == 0 ? 0 : (change / lastMonth * 100);
}

enum TrendDirection { rising, falling, stable }

class CashFlowForecast {
  final double currentMonthIncome;
  final double currentMonthExpense;
  final double projectedMonthIncome;
  final double projectedMonthExpense;
  final List<double> incomeHistory; // last 6 months, newest first
  final List<double> expenseHistory;
  final List<MonthForecast> forecastMonths; // next 3 months
  final double avgMonthlyNet;

  CashFlowForecast({
    required this.currentMonthIncome,
    required this.currentMonthExpense,
    required this.projectedMonthIncome,
    required this.projectedMonthExpense,
    required this.incomeHistory,
    required this.expenseHistory,
    required this.forecastMonths,
    required this.avgMonthlyNet,
  });

  double get currentNet => currentMonthIncome - currentMonthExpense;
  double get projectedNet => projectedMonthIncome - projectedMonthExpense;
  bool get isPositive => avgMonthlyNet > 0;
}

class MonthForecast {
  final DateTime month;
  final double income;
  final double expense;
  final double net;

  MonthForecast({
    required this.month,
    required this.income,
    required this.expense,
    required this.net,
  });

  bool get isPositive => net > 0;
}

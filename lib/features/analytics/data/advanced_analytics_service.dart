

import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';

class AdvancedAnalyticsService {
  final TransactionService _transactionService;

  AdvancedAnalyticsService(this._transactionService);

  // Predict next month spending based on last 3 months
  Future<double> predictMonthlySpending() async {
    final now = DateTime.now();
    final transactions = await _transactionService.getAllForDashBoard();

    double total = 0;
    int count = 0;

    for (int i = 1; i <= 3; i++) {
      final month = DateTime(now.year, now.month - i);
      final monthTotal = transactions
          .where((tx) =>
              tx.isExpense &&
              tx.date.year == month.year &&
              tx.date.month == month.month)
          .fold(0.0, (sum, tx) => sum + tx.amount);
      
      if (monthTotal > 0) {
        total += monthTotal;
        count++;
      }
    }

    return count > 0 ? total / count : 0;
  }

  // Calculate financial health score (0-100)
  Future<FinancialHealthScore> calculateHealthScore(double totalBalance) async {
    final now = DateTime.now();
    final transactions = await _transactionService.getAllForDashBoard();

    final thisMonth = transactions.where(
      (tx) => tx.date.year == now.year && tx.date.month == now.month,
    );

    final income = thisMonth
        .where((tx) => !tx.isExpense)
        .fold(0.0, (sum, tx) => sum + tx.amount);
    final expense = thisMonth
        .where((tx) => tx.isExpense)
        .fold(0.0, (sum, tx) => sum + tx.amount);

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

    final rating =
        score >= 80
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
  Future<Map<String, CategoryTrend>> getCategoryTrends() async {
    final now = DateTime.now();
    final transactions = await _transactionService.getAllForDashBoard();

    final trends = <String, CategoryTrend>{};

    for (var tx in transactions.where((t) => t.isExpense)) {
      final categoryName = tx.category.value?.name ?? 'Uncategorized';

      if (!trends.containsKey(categoryName)) {
        trends[categoryName] = CategoryTrend(
          categoryName: categoryName,
          thisMonth: 0,
          lastMonth: 0,
        );
      }

      if (tx.date.year == now.year && tx.date.month == now.month) {
        trends[categoryName]!.thisMonth += tx.amount;
      } else if (tx.date.year == now.year && tx.date.month == now.month - 1) {
        trends[categoryName]!.lastMonth += tx.amount;
      }
    }

    return trends;
  }

  // Predict budget exhaustion date
  Future<DateTime?> predictBudgetExhaustion(double budgetAmount) async {
    final now = DateTime.now();
    final transactions = await _transactionService.getAllForDashBoard();

    final thisMonth = transactions.where(
      (tx) =>
          tx.isExpense &&
          tx.date.year == now.year &&
          tx.date.month == now.month,
    );

    final spent = thisMonth.fold(0.0, (sum, tx) => sum + tx.amount);
    final remaining = budgetAmount - spent;

    if (remaining <= 0) return now;

    final daysElapsed = now.day;
    final dailyBurnRate = spent / daysElapsed;

    if (dailyBurnRate == 0) return null;

    final daysRemaining = (remaining / dailyBurnRate).ceil();
    return now.add(Duration(days: daysRemaining));
  }

  // Get spending patterns by day of week
  Future<Map<String, double>> getSpendingByDayOfWeek() async {
    final transactions = await _transactionService.getAllForDashBoard();
    final now = DateTime.now();

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

    for (var tx in transactions.where(
      (t) => t.isExpense && t.date.isAfter(now.subtract(const Duration(days: 90))),
    )) {
      final dayName = days[tx.date.weekday - 1];
      byDay[dayName] = (byDay[dayName] ?? 0) + tx.amount;
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

  CategoryTrend({
    required this.categoryName,
    required this.thisMonth,
    required this.lastMonth,
  });

  double get change => thisMonth - lastMonth;
  double get changePercent => lastMonth == 0 ? 0 : (change / lastMonth * 100);
}

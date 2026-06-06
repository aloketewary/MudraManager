import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:isar/isar.dart';

/// Phase 1: User Financial Context Foundation
/// Deterministic state computation from raw financial data
class UserFinancialContext {
  final double monthlyIncomeEstimate;
  final double avgMonthlyExpenses;
  final double liquidityBufferDays;
  final double spendingVolatilityIndex;
  final double debtRatio;
  final double autopayCoverage;
  final DateTime lastSalaryCredit;
  final DateTime lastUpdated;

  const UserFinancialContext({
    required this.monthlyIncomeEstimate,
    required this.avgMonthlyExpenses,
    required this.liquidityBufferDays,
    required this.spendingVolatilityIndex,
    required this.debtRatio,
    required this.autopayCoverage,
    required this.lastSalaryCredit,
    required this.lastUpdated,
  });

  /// Financial stability score (0.0 - 1.0)
  double get stabilityScore {
    final bufferScore = (liquidityBufferDays / 30).clamp(0.0, 1.0);
    final volatilityScore = (1.0 - spendingVolatilityIndex).clamp(0.0, 1.0);
    final debtScore = (1.0 - debtRatio).clamp(0.0, 1.0);
    final automationScore = autopayCoverage;
    
    return (bufferScore * 0.4 + 
            volatilityScore * 0.3 + 
            debtScore * 0.2 + 
            automationScore * 0.1);
  }

  /// Is user in stable financial state
  bool get isStable => stabilityScore >= 0.7;

  /// Days since last salary (income regularity indicator)
  int get daysSinceLastSalary {
    return DateTime.now().difference(lastSalaryCredit).inDays;
  }

  /// Context freshness check
  bool get isContextFresh {
    return DateTime.now().difference(lastUpdated).inDays < 7;
  }

  UserFinancialContext copyWith({
    double? monthlyIncomeEstimate,
    double? avgMonthlyExpenses,
    double? liquidityBufferDays,
    double? spendingVolatilityIndex,
    double? debtRatio,
    double? autopayCoverage,
    DateTime? lastSalaryCredit,
    DateTime? lastUpdated,
  }) {
    return UserFinancialContext(
      monthlyIncomeEstimate: monthlyIncomeEstimate ?? this.monthlyIncomeEstimate,
      avgMonthlyExpenses: avgMonthlyExpenses ?? this.avgMonthlyExpenses,
      liquidityBufferDays: liquidityBufferDays ?? this.liquidityBufferDays,
      spendingVolatilityIndex: spendingVolatilityIndex ?? this.spendingVolatilityIndex,
      debtRatio: debtRatio ?? this.debtRatio,
      autopayCoverage: autopayCoverage ?? this.autopayCoverage,
      lastSalaryCredit: lastSalaryCredit ?? this.lastSalaryCredit,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  factory UserFinancialContext.initial() {
    return UserFinancialContext(
      monthlyIncomeEstimate: 0.0,
      avgMonthlyExpenses: 0.0,
      liquidityBufferDays: 0.0,
      spendingVolatilityIndex: 0.0,
      debtRatio: 0.0,
      autopayCoverage: 0.0,
      lastSalaryCredit: DateTime.now(),
      lastUpdated: DateTime.now(),
    );
  }
}

/// Context computation service - deterministic and testable
class FinancialContextService {
  final Isar isar;

  FinancialContextService(this.isar);

  /// Compute current financial context from raw data
  Future<UserFinancialContext> computeContext() async {
    final now = DateTime.now();
    final last90Days = now.subtract(const Duration(days: 90));
    final last30Days = now.subtract(const Duration(days: 30));

    // Get all transactions for analysis
    final transactions = await isar.transactions
        .filter()
        .timestampGreaterThan(last90Days)
        .findAll();

    final accounts = await isar.accounts.findAll();
    final recurringBills = await isar.recurringTransactions.findAll();

    // Compute each context dimension
    final monthlyIncome = _computeMonthlyIncome(transactions);
    final monthlyExpenses = _computeAvgMonthlyExpenses(transactions);
    final liquidityDays = _computeLiquidityBuffer(accounts, monthlyExpenses);
    final volatility = _computeSpendingVolatility(transactions);
    final debtRatio = _computeDebtRatio(accounts, monthlyIncome);
    final autopayRatio = _computeAutopayCoverage(recurringBills, monthlyExpenses);
    final lastSalary = _findLastSalaryCredit(transactions);

    return UserFinancialContext(
      monthlyIncomeEstimate: monthlyIncome,
      avgMonthlyExpenses: monthlyExpenses,
      liquidityBufferDays: liquidityDays,
      spendingVolatilityIndex: volatility,
      debtRatio: debtRatio,
      autopayCoverage: autopayRatio,
      lastSalaryCredit: lastSalary,
      lastUpdated: now,
    );
  }

  /// Estimate monthly income from salary/transfer patterns
  double _computeMonthlyIncome(List<Transaction> transactions) {
    final incomeTransactions = transactions
        .where((t) => t.type == TransactionType.income || 
                     (t.amount > 0 && _isSalaryLike(t)))
        .toList();

    if (incomeTransactions.isEmpty) return 0.0;

    final totalIncome = incomeTransactions
        .fold<double>(0.0, (sum, t) => sum + t.amount.abs());

    // Convert to monthly estimate based on data period
    final daysOfData = DateTime.now()
        .difference(incomeTransactions.first.timestamp)
        .inDays;

    return daysOfData > 0 ? (totalIncome / daysOfData) * 30 : 0.0;
  }

  /// Calculate average monthly expenses
  double _computeAvgMonthlyExpenses(List<Transaction> transactions) {
    final expenseTransactions = transactions
        .where((t) => t.type == TransactionType.expense && t.amount < 0)
        .toList();

    if (expenseTransactions.isEmpty) return 0.0;

    final totalExpenses = expenseTransactions
        .fold<double>(0.0, (sum, t) => sum + t.amount.abs());

    final daysOfData = DateTime.now()
        .difference(expenseTransactions.first.timestamp)
        .inDays;

    return daysOfData > 0 ? (totalExpenses / daysOfData) * 30 : 0.0;
  }

  /// Calculate liquidity buffer in days
  double _computeLiquidityBuffer(List<Account> accounts, double monthlyExpenses) {
    final liquidAccounts = accounts
        .where((a) => a.accountType == AccountType.savings || 
                     a.accountType == AccountType.checking)
        .toList();

    final totalLiquid = liquidAccounts
        .fold<double>(0.0, (sum, a) => sum + a.currentBalance);

    return monthlyExpenses > 0 ? (totalLiquid / monthlyExpenses) * 30 : 0.0;
  }

  /// Calculate spending volatility (coefficient of variation)
  double _computeSpendingVolatility(List<Transaction> transactions) {
    final weeklySpending = <double>[];
    final now = DateTime.now();

    // Group spending by week for last 12 weeks
    for (int week = 0; week < 12; week++) {
      final weekStart = now.subtract(Duration(days: (week + 1) * 7));
      final weekEnd = now.subtract(Duration(days: week * 7));

      final weekExpenses = transactions
          .where((t) => t.type == TransactionType.expense &&
                       t.timestamp.isAfter(weekStart) &&
                       t.timestamp.isBefore(weekEnd))
          .fold<double>(0.0, (sum, t) => sum + t.amount.abs());

      weeklySpending.add(weekExpenses);
    }

    if (weeklySpending.length < 4) return 0.0;

    // Calculate coefficient of variation
    final mean = weeklySpending.reduce((a, b) => a + b) / weeklySpending.length;
    final variance = weeklySpending
        .map((x) => (x - mean) * (x - mean))
        .reduce((a, b) => a + b) / weeklySpending.length;
    final stdDev = variance > 0 ? variance : 0.0;

    return mean > 0 ? stdDev / mean : 0.0;
  }

  /// Calculate debt-to-income ratio
  double _computeDebtRatio(List<Account> accounts, double monthlyIncome) {
    final debtAccounts = accounts
        .where((a) => a.accountType == AccountType.creditCard ||
                     a.accountType == AccountType.loan)
        .toList();

    final totalDebt = debtAccounts
        .fold<double>(0.0, (sum, a) => sum + a.currentBalance.abs());

    return monthlyIncome > 0 ? totalDebt / monthlyIncome : 0.0;
  }

  /// Calculate autopay coverage ratio
  double _computeAutopayCoverage(List<RecurringTransaction> bills, double monthlyExpenses) {
    final totalBillsAmount = bills
        .where((b) => b.isActive)
        .fold<double>(0.0, (sum, b) => sum + b.amount.abs());

    return monthlyExpenses > 0 ? totalBillsAmount / monthlyExpenses : 0.0;
  }

  /// Find last salary credit transaction
  DateTime _findLastSalaryCredit(List<Transaction> transactions) {
    final salaryTransactions = transactions
        .where((t) => _isSalaryLike(t))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return salaryTransactions.isNotEmpty 
        ? salaryTransactions.first.timestamp 
        : DateTime.now().subtract(const Duration(days: 60));
  }

  /// Heuristic to identify salary-like transactions
  bool _isSalaryLike(Transaction transaction) {
    final description = transaction.description?.toLowerCase() ?? '';
    final amount = transaction.amount.abs();

    // Common salary indicators
    final salaryKeywords = [
      'salary', 'sal', 'wage', 'payroll', 'emp', 'neft', 'imps'
    ];

    final hasKeyword = salaryKeywords
        .any((keyword) => description.contains(keyword));

    // Typical salary amount range (₹15K - ₹500K)
    final isTypicalSalaryAmount = amount >= 15000 && amount <= 500000;

    return hasKeyword && isTypicalSalaryAmount && transaction.amount > 0;
  }
}
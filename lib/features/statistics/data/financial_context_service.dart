import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';

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

  double get stabilityScore {
    final buffer = (liquidityBufferDays / 30).clamp(0.0, 1.0);
    final volatility = (1.0 - spendingVolatilityIndex).clamp(0.0, 1.0);
    final debt = (1.0 - debtRatio).clamp(0.0, 1.0);
    return buffer * 0.4 + volatility * 0.3 + debt * 0.2 + autopayCoverage * 0.1;
  }

  bool get isStable => stabilityScore >= 0.7;

  int get daysSinceLastSalary => DateTime.now().difference(lastSalaryCredit).inDays;

  bool get isContextFresh => DateTime.now().difference(lastUpdated).inDays < 7;

  factory UserFinancialContext.initial() => UserFinancialContext(
        monthlyIncomeEstimate: 0,
        avgMonthlyExpenses: 0,
        liquidityBufferDays: 0,
        spendingVolatilityIndex: 0,
        debtRatio: 0,
        autopayCoverage: 0,
        lastSalaryCredit: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
}

/// Context computation service — deterministic and testable
class FinancialContextService {
  final Isar _isar;

  FinancialContextService(this._isar);

  Future<UserFinancialContext> computeContext() async {
    final now = DateTime.now();
    final last90Days = now.subtract(const Duration(days: 90));

    final transactions = await _isar.transactions
        .filter()
        .dateGreaterThan(last90Days)
        .findAll();

    final accounts = await _isar.accounts.where().findAll();
    final bills = await _isar.recurringTransactions
        .filter()
        .isActiveEqualTo(true)
        .findAll();

    final monthlyIncome = _monthlyIncome(transactions);
    final monthlyExpenses = _monthlyExpenses(transactions);

    return UserFinancialContext(
      monthlyIncomeEstimate: monthlyIncome,
      avgMonthlyExpenses: monthlyExpenses,
      liquidityBufferDays: _liquidityBuffer(accounts, monthlyExpenses),
      spendingVolatilityIndex: _volatility(transactions),
      debtRatio: _debtRatio(accounts, monthlyIncome),
      autopayCoverage: _autopayCoverage(bills, monthlyExpenses),
      lastSalaryCredit: _lastSalary(transactions),
      lastUpdated: now,
    );
  }

  double _monthlyIncome(List<Transaction> txns) {
    final income = txns.where((t) => !t.isExpense && !t.isTransfer).toList();
    if (income.isEmpty) return 0.0;

    final total = income.fold<double>(0.0, (s, t) => s + t.amount);
    final days = DateTime.now().difference(income.last.date).inDays.clamp(1, 999);
    return (total / days) * 30;
  }

  double _monthlyExpenses(List<Transaction> txns) {
    final expenses = txns.where((t) => t.isExpense && !t.isTransfer).toList();
    if (expenses.isEmpty) return 0.0;

    final total = expenses.fold<double>(0.0, (s, t) => s + t.amount);
    final days = DateTime.now().difference(expenses.last.date).inDays.clamp(1, 999);
    return (total / days) * 30;
  }

  double _liquidityBuffer(List<Account> accounts, double monthlyExpenses) {
    final liquid = accounts
        .where((a) => a.accountType == AccountType.bank || a.accountType == AccountType.cash)
        .fold<double>(0.0, (s, a) => s + a.initialBalance);

    return monthlyExpenses > 0 ? (liquid / monthlyExpenses) * 30 : 0.0;
  }

  double _volatility(List<Transaction> txns) {
    final now = DateTime.now();
    final weekly = <double>[];

    for (var w = 0; w < 12; w++) {
      final start = now.subtract(Duration(days: (w + 1) * 7));
      final end = now.subtract(Duration(days: w * 7));
      final total = txns
          .where((t) => t.isExpense && !t.isTransfer && t.date.isAfter(start) && t.date.isBefore(end))
          .fold<double>(0.0, (s, t) => s + t.amount);
      weekly.add(total);
    }

    if (weekly.length < 4) return 0.0;
    final mean = weekly.reduce((a, b) => a + b) / weekly.length;
    if (mean == 0) return 0.0;

    final variance = weekly.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / weekly.length;
    // Simplified stddev approximation via sqrt(variance) ≈ variance^0.5
    // For coefficient of variation we just use variance/mean as a proxy
    return (variance / (mean * mean)).clamp(0.0, 1.0);
  }

  double _debtRatio(List<Account> accounts, double monthlyIncome) {
    final debt = accounts
        .where((a) => a.accountType == AccountType.creditCard)
        .fold<double>(0.0, (s, a) => s + a.initialBalance.abs());

    return monthlyIncome > 0 ? (debt / monthlyIncome).clamp(0.0, 5.0) : 0.0;
  }

  double _autopayCoverage(List<RecurringTransaction> bills, double monthlyExpenses) {
    final total = bills.fold<double>(0.0, (s, b) => s + b.amount.abs());
    return monthlyExpenses > 0 ? (total / monthlyExpenses).clamp(0.0, 1.0) : 0.0;
  }

  DateTime _lastSalary(List<Transaction> txns) {
    final salaries = txns
        .where((t) => !t.isExpense && _isSalaryLike(t))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return salaries.isNotEmpty
        ? salaries.first.date
        : DateTime.now().subtract(const Duration(days: 60));
  }

  bool _isSalaryLike(Transaction t) {
    final desc = t.description?.toLowerCase() ?? '';
    const keywords = ['salary', 'sal', 'wage', 'payroll', 'neft', 'imps'];
    return keywords.any(desc.contains) && t.amount >= 15000 && t.amount <= 500000;
  }
}

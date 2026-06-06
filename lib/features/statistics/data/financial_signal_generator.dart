import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/features/statistics/data/financial_context_service.dart';

/// Phase 2: Signal Generation Layer
/// Converts financial events into comparable signals without interpretation

class FinancialSignalGenerator {
  /// Generate signals from recent financial activity
  List<FinancialSignal> generateSignals({
    required List<Transaction> recentTransactions,
    required List<Budget> budgets,
    required List<Goal> goals,
    required List<RecurringTransaction> bills,
    required UserFinancialContext context,
  }) {
    final signals = <FinancialSignal>[];

    // Budget-related signals
    signals.addAll(_generateBudgetSignals(budgets, recentTransactions));

    // Goal-related signals  
    signals.addAll(_generateGoalSignals(goals));

    // Bill-related signals
    signals.addAll(_generateBillSignals(bills, recentTransactions));

    // Transaction pattern signals
    signals.addAll(_generateTransactionPatternSignals(recentTransactions, context));

    // Income variation signals
    signals.addAll(_generateIncomeSignals(recentTransactions, context));

    return signals;
  }

  /// Generate budget breach and spending pace signals
  List<FinancialSignal> _generateBudgetSignals(
    List<Budget> budgets, 
    List<Transaction> transactions,
  ) {
    final signals = <FinancialSignal>[];

    for (final budget in budgets.where((b) => b.isActive)) {
      final periodTransactions = _getTransactionsInPeriod(
        transactions, 
        budget.startDate, 
        budget.endDate,
        categoryId: budget.categoryId,
      );

      final totalSpent = periodTransactions
          .fold<double>(0.0, (sum, t) => sum + t.amount.abs());

      // Budget breach signal
      if (totalSpent > budget.amount) {
        signals.add(FinancialSignal(
          type: SignalType.budgetBreach,
          absoluteValue: totalSpent - budget.amount,
          relativeToBaseline: totalSpent / budget.amount,
          timestamp: DateTime.now(),
          metadata: {
            'budgetId': budget.id,
            'budgetName': budget.name,
            'spent': totalSpent,
            'limit': budget.amount,
            'overspendPercent': ((totalSpent / budget.amount) - 1.0) * 100,
          },
        ));
      }

      // Spending pace signal (if trending toward breach)
      final daysInPeriod = budget.endDate.difference(budget.startDate).inDays;
      final daysPassed = DateTime.now().difference(budget.startDate).inDays;
      final daysRemaining = budget.endDate.difference(DateTime.now()).inDays;

      if (daysRemaining > 0 && daysPassed > 7) {
        final currentPace = totalSpent / daysPassed;
        final projectedTotal = currentPace * daysInPeriod;

        if (projectedTotal > budget.amount * 1.1) { // 10% buffer
          signals.add(FinancialSignal(
            type: SignalType.budgetPaceRisk,
            absoluteValue: projectedTotal - budget.amount,
            relativeToBaseline: projectedTotal / budget.amount,
            timestamp: DateTime.now(),
            metadata: {
              'budgetId': budget.id,
              'budgetName': budget.name,
              'currentPace': currentPace,
              'projectedTotal': projectedTotal,
              'daysRemaining': daysRemaining,
            },
          ));
        }
      }
    }

    return signals;
  }

  /// Generate goal contribution delay signals
  List<FinancialSignal> _generateGoalSignals(List<Goal> goals) {
    final signals = <FinancialSignal>[];

    for (final goal in goals.where((g) => g.isActive)) {
      final daysSinceContribution = goal.lastContributionDate != null
          ? DateTime.now().difference(goal.lastContributionDate!).inDays
          : 999;

      // Goal contribution delay signal
      if (daysSinceContribution > 14) { // 2 weeks threshold
        final expectedMonthlyContribution = goal.targetDate != null
            ? _calculateRequiredMonthlyContribution(goal)
            : 0.0;

        signals.add(FinancialSignal(
          type: SignalType.goalDelay,
          absoluteValue: expectedMonthlyContribution,
          relativeToBaseline: daysSinceContribution / 30.0, // Convert to months
          timestamp: DateTime.now(),
          metadata: {
            'goalId': goal.id,
            'goalName': goal.name,
            'daysDelayed': daysSinceContribution,
            'expectedContribution': expectedMonthlyContribution,
            'progress': goal.currentAmount / goal.targetAmount,
          },
        ));
      }
    }

    return signals;
  }

  /// Generate bill-related signals
  List<FinancialSignal> _generateBillSignals(
    List<RecurringTransaction> bills,
    List<Transaction> transactions,
  ) {
    final signals = <FinancialSignal>[];

    for (final bill in bills.where((b) => b.isActive)) {
      // Check for overdue bills
      final nextDueDate = _calculateNextDueDate(bill);
      final daysUntilDue = nextDueDate.difference(DateTime.now()).inDays;

      if (daysUntilDue < 0) {
        // Bill is overdue
        signals.add(FinancialSignal(
          type: SignalType.billOverdue,
          absoluteValue: bill.amount.abs(),
          relativeToBaseline: daysUntilDue.abs() / 30.0,
          timestamp: DateTime.now(),
          metadata: {
            'billId': bill.id,
            'billName': bill.description,
            'amount': bill.amount.abs(),
            'daysOverdue': daysUntilDue.abs(),
            'dueDate': nextDueDate,
          },
        ));
      } else if (daysUntilDue <= 2) {
        // Bill due soon
        signals.add(FinancialSignal(
          type: SignalType.billDueSoon,
          absoluteValue: bill.amount.abs(),
          relativeToBaseline: 1.0 - (daysUntilDue / 7.0), // Urgency factor
          timestamp: DateTime.now(),
          metadata: {
            'billId': bill.id,
            'billName': bill.description,
            'amount': bill.amount.abs(),
            'daysTillDue': daysUntilDue,
            'dueDate': nextDueDate,
          },
        ));
      }

      // Check for unusual bill amounts
      final recentPayments = _findRecentBillPayments(bill, transactions);
      if (recentPayments.isNotEmpty) {
        final avgAmount = recentPayments
            .fold<double>(0.0, (sum, t) => sum + t.amount.abs()) / 
            recentPayments.length;

        final currentAmount = bill.amount.abs();
        final variance = (currentAmount - avgAmount).abs() / avgAmount;

        if (variance > 0.3) { // 30% variance threshold
          signals.add(FinancialSignal(
            type: SignalType.billAmountAnomaly,
            absoluteValue: currentAmount - avgAmount,
            relativeToBaseline: currentAmount / avgAmount,
            timestamp: DateTime.now(),
            metadata: {
              'billId': bill.id,
              'billName': bill.description,
              'currentAmount': currentAmount,
              'historicalAvg': avgAmount,
              'variancePercent': variance * 100,
            },
          ));
        }
      }
    }

    return signals;
  }

  /// Generate transaction pattern anomaly signals
  List<FinancialSignal> _generateTransactionPatternSignals(
    List<Transaction> transactions,
    UserFinancialContext context,
  ) {
    final signals = <FinancialSignal>[];

    // Group transactions by category for pattern analysis
    final categoryGroups = <int, List<Transaction>>{};
    for (final transaction in transactions) {
      if (transaction.categoryId != null) {
        categoryGroups.putIfAbsent(transaction.categoryId!, () => [])
            .add(transaction);
      }
    }

    // Analyze each category for spending anomalies
    categoryGroups.forEach((categoryId, categoryTransactions) {
      final thisWeekTransactions = categoryTransactions
          .where((t) => _isThisWeek(t.timestamp))
          .toList();

      final historicalWeeklyAvg = _calculateWeeklyAverage(categoryTransactions);

      if (thisWeekTransactions.isNotEmpty && historicalWeeklyAvg > 0) {
        final thisWeekTotal = thisWeekTransactions
            .fold<double>(0.0, (sum, t) => sum + t.amount.abs());

        final variance = thisWeekTotal / historicalWeeklyAvg;

        if (variance > 1.5) { // 50% above normal
          signals.add(FinancialSignal(
            type: SignalType.categorySpendingSpike,
            absoluteValue: thisWeekTotal - historicalWeeklyAvg,
            relativeToBaseline: variance,
            timestamp: DateTime.now(),
            metadata: {
              'categoryId': categoryId,
              'thisWeekSpending': thisWeekTotal,
              'historicalAvg': historicalWeeklyAvg,
              'variancePercent': (variance - 1.0) * 100,
              'transactionCount': thisWeekTransactions.length,
            },
          ));
        }
      }
    });

    return signals;
  }

  /// Generate income variation signals
  List<FinancialSignal> _generateIncomeSignals(
    List<Transaction> transactions,
    UserFinancialContext context,
  ) {
    final signals = <FinancialSignal>[];

    // Check for missed salary
    if (context.daysSinceLastSalary > 35) { // More than typical month
      signals.add(FinancialSignal(
        type: SignalType.incomeDelay,
        absoluteValue: context.monthlyIncomeEstimate,
        relativeToBaseline: context.daysSinceLastSalary / 30.0,
        timestamp: DateTime.now(),
        metadata: {
          'daysSinceLastSalary': context.daysSinceLastSalary,
          'expectedMonthlyIncome': context.monthlyIncomeEstimate,
          'lastSalaryDate': context.lastSalaryCredit,
        },
      ));
    }

    return signals;
  }

  // Helper methods
  List<Transaction> _getTransactionsInPeriod(
    List<Transaction> transactions,
    DateTime start,
    DateTime end, {
    int? categoryId,
  }) {
    return transactions.where((t) =>
        t.timestamp.isAfter(start) &&
        t.timestamp.isBefore(end) &&
        (categoryId == null || t.categoryId == categoryId) &&
        t.type == TransactionType.expense
    ).toList();
  }

  double _calculateRequiredMonthlyContribution(Goal goal) {
    if (goal.targetDate == null) return 0.0;

    final monthsRemaining = goal.targetDate!.difference(DateTime.now()).inDays / 30.0;
    final amountRemaining = goal.targetAmount - goal.currentAmount;

    return monthsRemaining > 0 ? amountRemaining / monthsRemaining : 0.0;
  }

  DateTime _calculateNextDueDate(RecurringTransaction bill) {
    // Simplified - assumes monthly bills
    final lastPaymentDate = bill.lastExecutedDate ?? bill.startDate;
    return DateTime(
      lastPaymentDate.year,
      lastPaymentDate.month + 1,
      lastPaymentDate.day,
    );
  }

  List<Transaction> _findRecentBillPayments(
    RecurringTransaction bill,
    List<Transaction> transactions,
  ) {
    return transactions
        .where((t) => 
            t.recurringTransactionId == bill.id ||
            (t.description?.toLowerCase().contains(
                bill.description.toLowerCase()) ?? false))
        .take(6) // Last 6 payments
        .toList();
  }

  bool _isThisWeek(DateTime timestamp) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return timestamp.isAfter(weekStart);
  }

  double _calculateWeeklyAverage(List<Transaction> transactions) {
    if (transactions.isEmpty) return 0.0;

    final totalAmount = transactions
        .fold<double>(0.0, (sum, t) => sum + t.amount.abs());
    final totalWeeks = transactions.length / 4.0; // Rough weekly average

    return totalWeeks > 0 ? totalAmount / totalWeeks : 0.0;
  }
}

/// Base financial signal - no interpretation, just facts
class FinancialSignal {
  final SignalType type;
  final double absoluteValue;
  final double relativeToBaseline;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const FinancialSignal({
    required this.type,
    required this.absoluteValue,
    required this.relativeToBaseline,
    required this.timestamp,
    required this.metadata,
  });

  @override
  String toString() {
    return 'FinancialSignal(type: $type, value: $absoluteValue, relative: $relativeToBaseline)';
  }
}

enum SignalType {
  budgetBreach,
  budgetPaceRisk,
  goalDelay,
  billOverdue,
  billDueSoon,
  billAmountAnomaly,
  categorySpendingSpike,
  incomeDelay,
  unusualTransaction,
}
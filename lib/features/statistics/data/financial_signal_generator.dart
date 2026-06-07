import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/features/statistics/data/financial_context_service.dart';

/// Phase 2: Signal Generation Layer
/// Converts financial events into comparable signals without interpretation

class FinancialSignalGenerator {
  List<FinancialSignal> generateSignals({
    required List<Transaction> recentTransactions,
    required List<Budget> budgets,
    required List<Goal> goals,
    required List<RecurringTransaction> bills,
    required UserFinancialContext context,
  }) {
    return [
      ..._budgetSignals(budgets, recentTransactions),
      ..._goalSignals(goals),
      ..._billSignals(bills),
      ..._spendingPatternSignals(recentTransactions, context),
      ..._incomeSignals(context),
    ];
  }

  List<FinancialSignal> _budgetSignals(
    List<Budget> budgets,
    List<Transaction> transactions,
  ) {
    final signals = <FinancialSignal>[];

    for (final budget in budgets) {
      final spent = _spentForBudget(budget, transactions);
      final limit = budget.amount;
      if (limit <= 0) continue;

      if (spent > limit) {
        signals.add(FinancialSignal(
          type: SignalType.budgetBreach,
          absoluteValue: spent - limit,
          relativeToBaseline: spent / limit,
          timestamp: DateTime.now(),
          metadata: {
            'budgetId': budget.id,
            'budgetName': budget.name,
            'spent': spent,
            'limit': limit,
            'overspendPercent': ((spent / limit) - 1.0) * 100,
          },
        ),);
      }

      final daysPassed = DateTime.now().difference(budget.startDate).inDays;
      final daysRemaining = budget.endDate.difference(DateTime.now()).inDays;
      final daysInPeriod = budget.endDate.difference(budget.startDate).inDays;

      if (daysRemaining > 0 && daysPassed > 7 && daysInPeriod > 0) {
        final pace = spent / daysPassed;
        final projected = pace * daysInPeriod;

        if (projected > limit * 1.1) {
          signals.add(FinancialSignal(
            type: SignalType.budgetPaceRisk,
            absoluteValue: projected - limit,
            relativeToBaseline: projected / limit,
            timestamp: DateTime.now(),
            metadata: {
              'budgetId': budget.id,
              'budgetName': budget.name,
              'currentPace': pace,
              'projectedTotal': projected,
              'daysRemaining': daysRemaining,
            },
          ),);
        }
      }
    }

    return signals;
  }

  double _spentForBudget(Budget budget, List<Transaction> transactions) {
    return transactions
        .where((t) =>
            t.isExpense &&
            !t.isTransfer &&
            t.date.isAfter(budget.startDate) &&
            t.date.isBefore(budget.endDate),)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  List<FinancialSignal> _goalSignals(List<Goal> goals) {
    final signals = <FinancialSignal>[];

    for (final goal in goals) {
      if (goal.targetDate == null || goal.currentAmount <= 0) continue;

      final monthsRemaining =
          goal.targetDate!.difference(DateTime.now()).inDays / 30.0;
      if (monthsRemaining <= 0) continue;

      final totalMonths =
          goal.targetDate!.difference(goal.creationDate).inDays / 30.0;
      if (totalMonths <= 0) continue;

      final expectedProgress = 1.0 - (monthsRemaining / totalMonths);
      final actualProgress = goal.progressPercent;

      // Goal is behind if expected > actual by 15%+
      if (expectedProgress - actualProgress > 0.15) {
        final remaining = goal.remainingAmount;
        final neededPerMonth = remaining / monthsRemaining;

        signals.add(FinancialSignal(
          type: SignalType.goalDelay,
          absoluteValue: neededPerMonth,
          relativeToBaseline:
              expectedProgress / actualProgress.clamp(0.01, 1.0),
          timestamp: DateTime.now(),
          metadata: {
            'goalId': goal.id,
            'goalName': goal.name,
            'progress': actualProgress,
            'expectedProgress': expectedProgress,
            'daysDelayed': ((expectedProgress - actualProgress) * 30).round(),
          },
        ),);
      }
    }

    return signals;
  }

  List<FinancialSignal> _billSignals(List<RecurringTransaction> bills) {
    final signals = <FinancialSignal>[];
    final now = DateTime.now();

    for (final bill in bills) {
      final daysUntilDue = bill.nextDueDate.difference(now).inDays;

      if (daysUntilDue < 0) {
        signals.add(FinancialSignal(
          type: SignalType.billOverdue,
          absoluteValue: bill.amount.abs(),
          relativeToBaseline: daysUntilDue.abs() / 30.0,
          timestamp: now,
          metadata: {
            'billName': bill.description ?? 'Bill',
            'amount': bill.amount.abs(),
            'daysOverdue': daysUntilDue.abs(),
          },
        ),);
      } else if (daysUntilDue <= 2) {
        signals.add(FinancialSignal(
          type: SignalType.billDueSoon,
          absoluteValue: bill.amount.abs(),
          relativeToBaseline: 1.0 - (daysUntilDue / 7.0),
          timestamp: now,
          metadata: {
            'billName': bill.description ?? 'Bill',
            'amount': bill.amount.abs(),
            'daysTillDue': daysUntilDue,
          },
        ),);
      }
    }

    return signals;
  }

  List<FinancialSignal> _spendingPatternSignals(
    List<Transaction> transactions,
    UserFinancialContext context,
  ) {
    if (context.avgMonthlyExpenses <= 0) return [];

    final now = DateTime.now();
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final expenses = transactions.where((t) => t.isExpense && !t.isTransfer);

    final thisWeekTotal = expenses
        .where((t) => t.date.isAfter(thisWeekStart))
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    final weeklyAvg = context.avgMonthlyExpenses / 4.3;

    if (weeklyAvg > 0 && thisWeekTotal / weeklyAvg > 1.5) {
      return [
        FinancialSignal(
          type: SignalType.categorySpendingSpike,
          absoluteValue: thisWeekTotal - weeklyAvg,
          relativeToBaseline: thisWeekTotal / weeklyAvg,
          timestamp: now,
          metadata: {
            'thisWeekSpending': thisWeekTotal,
            'historicalAvg': weeklyAvg,
            'variancePercent': ((thisWeekTotal / weeklyAvg) - 1.0) * 100,
          },
        ),
      ];
    }

    return [];
  }

  List<FinancialSignal> _incomeSignals(UserFinancialContext context) {
    if (context.daysSinceLastSalary > 35 && context.monthlyIncomeEstimate > 0) {
      return [
        FinancialSignal(
          type: SignalType.incomeDelay,
          absoluteValue: context.monthlyIncomeEstimate,
          relativeToBaseline: context.daysSinceLastSalary / 30.0,
          timestamp: DateTime.now(),
          metadata: {
            'daysSinceLastSalary': context.daysSinceLastSalary,
            'expectedMonthlyIncome': context.monthlyIncomeEstimate,
          },
        ),
      ];
    }
    return [];
  }
}

/// Raw financial signal — no interpretation, just facts
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
}

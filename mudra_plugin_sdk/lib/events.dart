class ExpenseEvent {
  final String category;
  final double amount;
  final DateTime time;

  ExpenseEvent(this.category, this.amount, this.time);
}

class IncomeEvent {
  final String source;
  final double amount;
  final DateTime time;

  IncomeEvent(this.source, this.amount, this.time);
}

class SmsEvent {
  final String sender;
  final String body;

  SmsEvent(this.sender, this.body);
}

class BudgetEvent {
  final double used;
  final double limit;

  BudgetEvent(this.used, this.limit);
}

class GoalEvent {
  final String goalId;
  final bool achieved;

  GoalEvent(this.goalId, this.achieved);
}

class TransferEvent {
  final String fromAccount;
  final String toAccount;
  final double amount;
  final DateTime time;

  TransferEvent(this.fromAccount, this.toAccount, this.amount, this.time);
}

class RecurringEvent {
  final String name;
  final double amount;
  final String frequency;

  RecurringEvent(this.name, this.amount, this.frequency);
}

class LowBalanceEvent {
  final String accountName;
  final double balance;
  final double threshold;

  LowBalanceEvent(this.accountName, this.balance, this.threshold);
}

class DailySummaryEvent {
  final DateTime date;
  DailySummaryEvent(this.date);
}

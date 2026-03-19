/// Base class for all plugin events.
abstract class PluginEvent {
  String get eventType;
  Map<String, dynamic> toMap();
}

class ExpenseEvent extends PluginEvent {
  final String category;
  final double amount;
  final DateTime time;

  ExpenseEvent(this.category, this.amount, this.time);

  @override
  String get eventType => 'expense';

  @override
  Map<String, dynamic> toMap() => {
    'category': category,
    'amount': amount,
    'time': time.toIso8601String(),
  };
}

class IncomeEvent extends PluginEvent {
  final String source;
  final double amount;
  final DateTime time;

  IncomeEvent(this.source, this.amount, this.time);

  @override
  String get eventType => 'income';

  @override
  Map<String, dynamic> toMap() => {
    'source': source,
    'amount': amount,
    'time': time.toIso8601String(),
  };
}

class SmsEvent extends PluginEvent {
  final String sender;
  final String body;

  SmsEvent(this.sender, this.body);

  @override
  String get eventType => 'sms';

  @override
  Map<String, dynamic> toMap() => {'sender': sender, 'body': body};
}

class BudgetEvent extends PluginEvent {
  final double used;
  final double limit;

  BudgetEvent(this.used, this.limit);

  @override
  String get eventType => 'budget';

  @override
  Map<String, dynamic> toMap() => {'used': used, 'limit': limit};
}

class GoalEvent extends PluginEvent {
  final String goalId;
  final bool achieved;

  GoalEvent(this.goalId, this.achieved);

  @override
  String get eventType => 'goal';

  @override
  Map<String, dynamic> toMap() => {'goalId': goalId, 'achieved': achieved};
}

class TransferEvent extends PluginEvent {
  final String fromAccount;
  final String toAccount;
  final double amount;
  final DateTime time;

  TransferEvent(this.fromAccount, this.toAccount, this.amount, this.time);

  @override
  String get eventType => 'transfer';

  @override
  Map<String, dynamic> toMap() => {
    'fromAccount': fromAccount,
    'toAccount': toAccount,
    'amount': amount,
    'time': time.toIso8601String(),
  };
}

class RecurringEvent extends PluginEvent {
  final String name;
  final double amount;
  final String frequency;

  RecurringEvent(this.name, this.amount, this.frequency);

  @override
  String get eventType => 'recurring';

  @override
  Map<String, dynamic> toMap() => {
    'name': name,
    'amount': amount,
    'frequency': frequency,
  };
}

class LowBalanceEvent extends PluginEvent {
  final String accountName;
  final double balance;
  final double threshold;

  LowBalanceEvent(this.accountName, this.balance, this.threshold);

  @override
  String get eventType => 'low_balance';

  @override
  Map<String, dynamic> toMap() => {
    'accountName': accountName,
    'balance': balance,
    'threshold': threshold,
  };
}

class DailySummaryEvent extends PluginEvent {
  final DateTime date;
  DailySummaryEvent(this.date);

  @override
  String get eventType => 'daily_summary';

  @override
  Map<String, dynamic> toMap() => {'date': date.toIso8601String()};
}

class TransactionSavedEvent extends PluginEvent {
  final double amount;
  final bool isExpense;
  final String? category;
  final String? account;
  final String? description;
  final DateTime date;
  final bool isTransfer;

  TransactionSavedEvent({
    required this.amount,
    required this.isExpense,
    required this.date,
    this.category,
    this.account,
    this.description,
    this.isTransfer = false,
  });

  @override
  String get eventType => 'transaction_saved';

  @override
  Map<String, dynamic> toMap() => {
    'amount': amount,
    'isExpense': isExpense,
    'category': category,
    'account': account,
    'description': description,
    'date': date.toIso8601String(),
    'isTransfer': isTransfer,
  };
}

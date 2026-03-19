enum PluginPermission {
  /// Show/schedule/cancel notifications
  notifications,

  /// Read transactions
  readTransactions,

  /// Read account balances
  readAccounts,

  /// Read budgets
  readBudgets,

  /// Read goals
  readGoals,

  /// Read categories
  readCategories,

  /// Write expenses
  writeExpenses,

  /// Write income
  writeIncome,

  /// Use plugin-scoped storage
  storage,
}

class TransactionData {
  final double amount;
  final bool isExpense;
  final String? category;
  final String? account;
  final String? description;
  final DateTime date;
  final bool isTransfer;

  TransactionData({
    required this.amount,
    required this.isExpense,
    required this.date,
    this.category,
    this.account,
    this.description,
    this.isTransfer = false,
  });
}

class AccountData {
  final String name;
  final double balance;
  final String type;
  final bool isActive;

  AccountData({
    required this.name,
    required this.balance,
    required this.type,
    required this.isActive,
  });
}

class BudgetData {
  final String name;
  final double amount;
  final double spent;
  final DateTime startDate;
  final DateTime endDate;

  BudgetData({
    required this.name,
    required this.amount,
    required this.spent,
    required this.startDate,
    required this.endDate,
  });

  double get remaining => amount - spent;
  double get usagePercent =>
      amount > 0 ? (spent / amount).clamp(0.0, 1.0) : 0.0;
}

class GoalData {
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final bool isActive;

  GoalData({
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.targetDate,
    required this.isActive,
  });

  double get progressPercent =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
}

class CategoryData {
  final String name;
  final String type; // 'income' or 'expense'

  CategoryData({required this.name, required this.type});
}

abstract class MudraApi {
  // --- Notifications ---
  void showNotification(String text);
  Future<void> scheduleNotification(String text, DateTime at, {int? id});
  Future<void> cancelNotification(int id);

  // --- Read ---
  Future<List<TransactionData>> getTransactions({
    DateTime? from,
    DateTime? to,
    bool? expenseOnly,
  });
  Future<List<AccountData>> getAccounts({bool activeOnly = true});
  Future<double> getAccountBalance(String accountName);
  Future<List<BudgetData>> getActiveBudgets();
  Future<List<GoalData>> getActiveGoals();
  Future<List<CategoryData>> getCategories({String? type});

  // --- Write ---
  Future<void> addExpense(
    double amount, {
    String? category,
    String? account,
    String? description,
  });
  Future<void> addIncome(
    double amount, {
    String? source,
    String? account,
    String? description,
  });

  // --- Plugin Storage (scoped per plugin) ---
  Future<void> putStorage(String key, String value);
  Future<String?> getStorage(String key);
  Future<void> removeStorage(String key);
}

import 'package:mudra_plugin_sdk/mudra_plugin_sdk.dart';

class PermissionDeniedException implements Exception {
  final String pluginId;
  final PluginPermission permission;

  PermissionDeniedException(this.pluginId, this.permission);

  @override
  String toString() =>
      'PermissionDenied: Plugin "$pluginId" lacks ${permission.name} permission';
}

class PermissionGuardedApi implements MudraApi {
  final MudraApi _delegate;
  final String _pluginId;
  final Set<PluginPermission> _granted;

  PermissionGuardedApi(this._delegate, this._pluginId, this._granted);

  void _require(PluginPermission p) {
    if (!_granted.contains(p)) {
      throw PermissionDeniedException(_pluginId, p);
    }
  }

  // --- Notifications ---

  @override
  void showNotification(String text) {
    _require(PluginPermission.notifications);
    _delegate.showNotification(text);
  }

  @override
  Future<void> scheduleNotification(String text, DateTime at, {int? id}) {
    _require(PluginPermission.notifications);
    return _delegate.scheduleNotification(text, at, id: id);
  }

  @override
  Future<void> cancelNotification(int id) {
    _require(PluginPermission.notifications);
    return _delegate.cancelNotification(id);
  }

  // --- Read ---

  @override
  Future<List<TransactionData>> getTransactions({
    DateTime? from,
    DateTime? to,
    bool? expenseOnly,
  }) {
    _require(PluginPermission.readTransactions);
    return _delegate.getTransactions(
      from: from,
      to: to,
      expenseOnly: expenseOnly,
    );
  }

  @override
  Future<List<AccountData>> getAccounts({bool activeOnly = true}) {
    _require(PluginPermission.readAccounts);
    return _delegate.getAccounts(activeOnly: activeOnly);
  }

  @override
  Future<double> getAccountBalance(String accountName) {
    _require(PluginPermission.readAccounts);
    return _delegate.getAccountBalance(accountName);
  }

  @override
  Future<List<BudgetData>> getActiveBudgets() {
    _require(PluginPermission.readBudgets);
    return _delegate.getActiveBudgets();
  }

  @override
  Future<List<GoalData>> getActiveGoals() {
    _require(PluginPermission.readGoals);
    return _delegate.getActiveGoals();
  }

  @override
  Future<List<CategoryData>> getCategories({String? type}) {
    _require(PluginPermission.readCategories);
    return _delegate.getCategories(type: type);
  }

  // --- Write ---

  @override
  Future<void> addExpense(
    double amount, {
    String? category,
    String? account,
    String? description,
  }) {
    _require(PluginPermission.writeExpenses);
    return _delegate.addExpense(
      amount,
      category: category,
      account: account,
      description: description,
    );
  }

  @override
  Future<void> addIncome(
    double amount, {
    String? source,
    String? account,
    String? description,
  }) {
    _require(PluginPermission.writeIncome);
    return _delegate.addIncome(
      amount,
      source: source,
      account: account,
      description: description,
    );
  }

  // --- Storage ---

  @override
  Future<void> putStorage(String key, String value) {
    _require(PluginPermission.storage);
    return _delegate.putStorage(key, value);
  }

  @override
  Future<String?> getStorage(String key) {
    _require(PluginPermission.storage);
    return _delegate.getStorage(key);
  }

  @override
  Future<void> removeStorage(String key) {
    _require(PluginPermission.storage);
    return _delegate.removeStorage(key);
  }
}

import 'package:isar_community/isar.dart';
import 'package:mudra_plugin_sdk/mudra_plugin_sdk.dart';
import 'package:mudra_manager/core/db/models/transaction.dart' as db;
import 'package:mudra_manager/core/db/models/account.dart' as db;
import 'package:mudra_manager/core/db/models/budget.dart' as db;
import 'package:mudra_manager/core/db/models/goal.dart' as db;
import 'package:mudra_manager/core/db/models/category.dart' as db;
import 'package:mudra_manager/core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MudraApiImpl implements MudraApi {
  final String _pluginId;

  MudraApiImpl(this._pluginId);

  Isar? get _isar => Isar.getInstance();

  // --- Notifications ---

  @override
  void showNotification(String text) {
    final id =
        DateTime.now().millisecondsSinceEpoch.hashCode.abs() % 2147483647;
    NotificationService.showLocalNotification(
      id: id,
      title: 'Mudra Manager',
      body: text,
    );
  }

  @override
  Future<void> scheduleNotification(String text, DateTime at, {int? id}) async {
    final notifId = id ?? at.hashCode.abs() % 2147483647;
    await NotificationService.showLocalNotification(
      id: notifId,
      title: 'Mudra Manager',
      body: text,
    );
  }

  @override
  Future<void> cancelNotification(int id) async {
    // Delegate to notification service cancel
  }

  // --- Read ---

  @override
  Future<List<TransactionData>> getTransactions({
    DateTime? from,
    DateTime? to,
    bool? expenseOnly,
  }) async {
    final isar = _isar;
    if (isar == null) return [];

    final query = isar.collection<db.Transaction>().where();

    final results = await query.findAll();

    return results.where((tx) {
      if (from != null && tx.date.isBefore(from)) return false;
      if (to != null && tx.date.isAfter(to)) return false;
      if (expenseOnly == true && !tx.isExpense) return false;
      if (expenseOnly == false && tx.isExpense) return false;
      return true;
    }).map((tx) {
      return TransactionData(
        amount: tx.amount,
        isExpense: tx.isExpense,
        date: tx.date,
        category: tx.category.value?.name,
        account: tx.account.value?.name,
        description: tx.description,
        isTransfer: tx.isTransfer,
      );
    }).toList();
  }

  @override
  Future<List<AccountData>> getAccounts({bool activeOnly = true}) async {
    final isar = _isar;
    if (isar == null) return [];

    final accounts = activeOnly
        ? await isar
            .collection<db.Account>()
            .filter()
            .isActiveEqualTo(true)
            .findAll()
        : await isar.collection<db.Account>().where().findAll();

    final result = <AccountData>[];
    for (final acc in accounts) {
      final balance = await _calculateBalance(isar, acc);
      result.add(
        AccountData(
          name: acc.name,
          balance: balance,
          type: acc.accountType.name,
          isActive: acc.isActive,
        ),
      );
    }
    return result;
  }

  @override
  Future<double> getAccountBalance(String accountName) async {
    final isar = _isar;
    if (isar == null) return 0.0;

    final acc = await isar
        .collection<db.Account>()
        .filter()
        .nameEqualTo(accountName, caseSensitive: false)
        .findFirst();
    if (acc == null) return 0.0;

    return _calculateBalance(isar, acc);
  }

  Future<double> _calculateBalance(Isar isar, db.Account acc) async {
    final txs = await isar
        .collection<db.Transaction>()
        .filter()
        .account((q) => q.idEqualTo(acc.id))
        .findAll();
    return acc.initialBalance +
        txs.fold<double>(
          0,
          (sum, tx) => sum + (tx.isExpense ? -tx.amount : tx.amount),
        );
  }

  @override
  Future<List<BudgetData>> getActiveBudgets() async {
    final isar = _isar;
    if (isar == null) return [];

    final now = DateTime.now();
    final budgets = await isar
        .collection<db.Budget>()
        .filter()
        .isArchivedEqualTo(false)
        .endDateGreaterThan(now)
        .findAll();

    final result = <BudgetData>[];
    for (final b in budgets) {
      await b.categories.load();
      double spent = 0;
      for (final cat in b.categories) {
        final txs = await isar
            .collection<db.Transaction>()
            .filter()
            .isExpenseEqualTo(true)
            .dateBetween(b.startDate, b.endDate)
            .category((q) => q.idEqualTo(cat.id))
            .findAll();
        spent += txs.fold<double>(0, (s, t) => s + t.baseAmount);
      }
      result.add(
        BudgetData(
          name: b.name,
          amount: b.amount,
          spent: spent,
          startDate: b.startDate,
          endDate: b.endDate,
        ),
      );
    }
    return result;
  }

  @override
  Future<List<GoalData>> getActiveGoals() async {
    final isar = _isar;
    if (isar == null) return [];

    final goals = await isar
        .collection<db.Goal>()
        .filter()
        .isActiveEqualTo(true)
        .findAll();

    return goals
        .map(
          (g) => GoalData(
            name: g.name,
            targetAmount: g.targetAmount,
            currentAmount: g.currentAmount,
            targetDate: g.targetDate,
            isActive: g.isActive,
          ),
        )
        .toList();
  }

  @override
  Future<List<CategoryData>> getCategories({String? type}) async {
    final isar = _isar;
    if (isar == null) return [];

    List<db.Category> cats;
    if (type == 'expense') {
      cats = await isar
          .collection<db.Category>()
          .filter()
          .categoryTypeEqualTo(db.CategoryType.expense)
          .findAll();
    } else if (type == 'income') {
      cats = await isar
          .collection<db.Category>()
          .filter()
          .categoryTypeEqualTo(db.CategoryType.income)
          .findAll();
    } else {
      cats = await isar.collection<db.Category>().where().findAll();
    }

    return cats
        .map(
          (c) => CategoryData(
            name: c.name,
            type: c.categoryType.name,
          ),
        )
        .toList();
  }

  // --- Write ---

  @override
  Future<void> addExpense(
    double amount, {
    String? category,
    String? account,
    String? description,
  }) async {
    final isar = _isar;
    if (isar == null) return;

    final tx = db.Transaction.create(
      date: DateTime.now(),
      amount: amount,
      isExpense: true,
      description: description,
    );

    await isar.writeTxn(() async {
      if (category != null) {
        final cat = await isar
            .collection<db.Category>()
            .filter()
            .nameEqualTo(category, caseSensitive: false)
            .findFirst();
        if (cat != null) tx.category.value = cat;
      }
      if (account != null) {
        final acc = await isar
            .collection<db.Account>()
            .filter()
            .nameEqualTo(account, caseSensitive: false)
            .findFirst();
        if (acc != null) tx.account.value = acc;
      }
      await isar.collection<db.Transaction>().put(tx);
      await tx.category.save();
      await tx.account.save();
    });
  }

  @override
  Future<void> addIncome(
    double amount, {
    String? source,
    String? account,
    String? description,
  }) async {
    final isar = _isar;
    if (isar == null) return;

    final tx = db.Transaction.create(
      date: DateTime.now(),
      amount: amount,
      isExpense: false,
      description: description ?? source,
    );

    await isar.writeTxn(() async {
      if (source != null) {
        final cat = await isar
            .collection<db.Category>()
            .filter()
            .nameEqualTo(source, caseSensitive: false)
            .findFirst();
        if (cat != null) tx.category.value = cat;
      }
      if (account != null) {
        final acc = await isar
            .collection<db.Account>()
            .filter()
            .nameEqualTo(account, caseSensitive: false)
            .findFirst();
        if (acc != null) tx.account.value = acc;
      }
      await isar.collection<db.Transaction>().put(tx);
      await tx.category.save();
      await tx.account.save();
    });
  }

  // --- Plugin Storage ---

  @override
  Future<void> putStorage(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('plugin_store_${_pluginId}_$key', value);
  }

  @override
  Future<String?> getStorage(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('plugin_store_${_pluginId}_$key');
  }

  @override
  Future<void> removeStorage(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('plugin_store_${_pluginId}_$key');
  }
}

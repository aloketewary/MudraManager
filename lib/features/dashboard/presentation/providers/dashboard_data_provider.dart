import 'dart:async';
import 'package:async/async.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/extensions/field_encryption_ext.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/singleton_providers.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/core/providers/budget_refresh_provider.dart';

class DashboardData {
  final List<Transaction> transactions;
  final List<Account> accounts;
  final Map<int, double> accountBalances;
  final List<BudgetWithProgress> budgets;
  final List<RecurringTransaction> recurringExpenses;
  final List<Goal> goals;
  final double totalIncome;
  final double totalExpense;
  final double totalBalance;
  final double netWorth;
  final int pendingSmsCount;
  final DateTime? budgetEvaluationDate;
  final int budgetGeneration;

  const DashboardData({
    required this.transactions,
    required this.accounts,
    required this.accountBalances,
    required this.budgets,
    required this.recurringExpenses,
    required this.goals,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalBalance,
    required this.netWorth,
    required this.pendingSmsCount,
    this.budgetEvaluationDate,
    this.budgetGeneration = 0,
  });

  static List<BudgetWithProgress> _sortedBudgets(
    List<BudgetWithProgress> budgets,
  ) {
    final sorted = List<BudgetWithProgress>.of(budgets);
    sorted.sort((a, b) {
      final byId = a.snapshot.budgetId.compareTo(b.snapshot.budgetId);
      if (byId != 0) return byId;
      return a.snapshot.occurrenceKey.compareTo(b.snapshot.occurrenceKey);
    });
    return sorted;
  }

  static List<CategorySpending> _sortedCategorySpendings(
    List<CategorySpending> spendings,
  ) {
    final sorted = List<CategorySpending>.of(spendings);
    sorted.sort((a, b) {
      final byId = a.category.id.compareTo(b.category.id);
      if (byId != 0) return byId;
      return a.category.name.compareTo(b.category.name);
    });
    return sorted;
  }

  static List<String> _sortedTags(Budget budget) {
    final tags = budget.budgetTags
        .map((tag) => '${tag.id}:${tag.name}')
        .toList(growable: false);
    return List<String>.of(tags)..sort();
  }

  static bool _sameBudget(BudgetWithProgress left, BudgetWithProgress right) {
    final a = left.snapshot;
    final b = right.snapshot;
    if (left.hasInvalidCategories != right.hasInvalidCategories ||
        left.startDate != right.startDate ||
        left.endDate != right.endDate ||
        a.budgetId != b.budgetId ||
        a.budgetName != b.budgetName ||
        a.budgetType != b.budgetType ||
        a.recurrence != b.recurrence ||
        a.isArchived != b.isArchived ||
        a.evaluationDate != b.evaluationDate ||
        a.periodStart != b.periodStart ||
        a.periodEnd != b.periodEnd ||
        a.limit != b.limit ||
        a.spent != b.spent ||
        a.remaining != b.remaining ||
        a.percentage != b.percentage ||
        a.status != b.status ||
        left.spent != right.spent ||
        _sortedTags(left.budget).length != _sortedTags(right.budget).length) {
      return false;
    }

    final leftTags = _sortedTags(left.budget);
    final rightTags = _sortedTags(right.budget);
    if (!_sameStrings(leftTags, rightTags)) return false;

    final leftCategories = _sortedCategorySpendings(left.categorySpendings);
    final rightCategories = _sortedCategorySpendings(right.categorySpendings);
    if (leftCategories.length != rightCategories.length) return false;
    for (var i = 0; i < leftCategories.length; i++) {
      final leftCategory = leftCategories[i];
      final rightCategory = rightCategories[i];
      if (leftCategory.category.id != rightCategory.category.id ||
          leftCategory.category.name != rightCategory.category.name ||
          leftCategory.allocated != rightCategory.allocated ||
          leftCategory.spent != rightCategory.spent) {
        return false;
      }
    }
    return true;
  }

  static bool _sameStrings(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }

  static bool _sameBudgets(
    List<BudgetWithProgress> left,
    List<BudgetWithProgress> right,
  ) {
    if (left.length != right.length) return false;
    final sortedLeft = _sortedBudgets(left);
    final sortedRight = _sortedBudgets(right);
    for (var i = 0; i < sortedLeft.length; i++) {
      if (!_sameBudget(sortedLeft[i], sortedRight[i])) return false;
    }
    return true;
  }

  static int _budgetHash(BudgetWithProgress value) {
    final snapshot = value.snapshot;
    final categories = _sortedCategorySpendings(value.categorySpendings);
    final categoryHash = Object.hashAll(
      categories.map(
        (category) => Object.hash(
          category.category.id,
          category.category.name,
          category.allocated,
          category.spent,
        ),
      ),
    );
    return Object.hash(
      value.hasInvalidCategories,
      value.startDate,
      value.endDate,
      snapshot.budgetId,
      snapshot.budgetName,
      snapshot.budgetType,
      snapshot.recurrence,
      snapshot.isArchived,
      snapshot.evaluationDate,
      snapshot.periodStart,
      snapshot.periodEnd,
      snapshot.limit,
      snapshot.spent,
      snapshot.remaining,
      snapshot.percentage,
      snapshot.status,
      value.spent,
      Object.hashAll(_sortedTags(value.budget)),
      categoryHash,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DashboardData ||
        totalIncome != other.totalIncome ||
        totalExpense != other.totalExpense ||
        totalBalance != other.totalBalance ||
        netWorth != other.netWorth ||
        transactions.length != other.transactions.length ||
        accounts.length != other.accounts.length ||
        goals.length != other.goals.length ||
        pendingSmsCount != other.pendingSmsCount ||
        budgetEvaluationDate != other.budgetEvaluationDate ||
        budgetGeneration != other.budgetGeneration) {
      return false;
    }
    return _sameBudgets(budgets, other.budgets);
  }

  @override
  int get hashCode => Object.hash(
        transactions.length,
        accounts.length,
        goals.length,
        budgets.length,
        totalIncome,
        totalExpense,
        totalBalance,
        netWorth,
        pendingSmsCount,
        budgetEvaluationDate,
        budgetGeneration,
        Object.hashAll(_sortedBudgets(budgets).map(_budgetHash)),
      );
}

// Main dashboard provider with debouncing
final dashboardDataProvider =
    StreamProvider.autoDispose<DashboardData>((ref) async* {
  final isar = await ref.watch(isarServiceProvider).getInstance();
  if (!ref.mounted) return;
  final budgetRefresh = ref.watch(budgetRefreshProvider);
  final budgetService = ref.watch(budgetServiceProvider);
  final accountService = ref.watch(accountServiceProvider);

  Timer? debounceTimer;
  DashboardData? lastEmittedData;

  ref.onDispose(() {
    debounceTimer?.cancel();
  });

  Future<List<Transaction>> getRecentTransactions(Isar isar) async {
    final cutoff = DateTime.now().subtract(const Duration(days: 93));
    final txns = await isar.transactions
        .where()
        .dateBetween(cutoff, DateTime.now())
        .sortByDateDesc()
        .findAll();
    // Load links for the ones we'll need
    for (final t in txns) {
      await t.category.load();
      await t.account.load();
      t.decryptFields();
    }
    return txns;
  }

  // Returns null if the provider was disposed mid-fetch (e.g. user
  // navigated away while a fetch was in flight). Callers must check for
  // null and bail out without touching `ref` again.
  Future<DashboardData?> fetchData(BudgetRefreshState refresh) async {
    try {
      // Fetch all data in parallel
      final results = await Future.wait([
        getRecentTransactions(isar),
        ref.read(accountsProvider.future),
        accountService.getAccountBalanceMap(),
        budgetService.getBudgetPeriodSnapshots(
          evaluationDate: refresh.evaluationDate,
        ),
        isar.recurringTransactions
            .filter()
            .isActiveEqualTo(true)
            .and()
            .isExpenseEqualTo(true)
            .sortByNextDueDate()
            .findAll(),
        isar.goals.where().findAll(),
        accountService.getAccountBalanceMapInBase(),
      ]);

      if (!ref.mounted) return null;

      final transactions = results[0] as List<Transaction>;
      // accountsProvider has already applied AccountDataContract. Balance and
      // totals below use only IDs/types and preserve existing formulas.
      final accounts = results[1] as List<Account>;
      final accountBalances = results[2] as Map<int, double>;
      final budgetSnapshots = results[3] as List<BudgetPeriodSnapshot>;
      final budgets =
          budgetSnapshots.map(BudgetWithProgress.fromSnapshot).toList();
      final recurringExpenses = results[4] as List<RecurringTransaction>;
      for (final r in recurringExpenses) {
        await r.category.load();
        r.decryptFields();
      }
      final goals = results[5] as List<Goal>;
      for (final g in goals) {
        g.decryptFields();
      }
      final baseBalances = results[6] as Map<int, double>;

      // Calculate totals once
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final monthTransactions = transactions
          .where(
            (t) =>
                t.date
                    .isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
                t.date.isBefore(endOfMonth.add(const Duration(days: 1))),
          )
          .toList();

      final totalIncome = monthTransactions
          .where((t) => !t.isExpense && !t.isTransfer)
          .fold<double>(0, (sum, t) => sum + t.baseAmount);

      final totalExpense = monthTransactions
          .where((t) => t.isExpense && !t.isTransfer)
          .fold<double>(0, (sum, t) => sum + t.baseAmount);

      final totalBalance = accounts.fold<double>(0, (sum, acc) {
        final balance = baseBalances[acc.id] ?? 0;
        return acc.accountType == AccountType.creditCard
            ? sum - balance
            : sum + balance;
      });

      final netWorth = accounts.fold<double>(0, (sum, acc) {
        final balance = baseBalances[acc.id] ?? 0;
        return sum + balance;
      });

      if (!ref.mounted) return null;
      final pendingSmsCount =
          await ref.read(smsActivityServiceProvider).getPendingCount();

      if (!ref.mounted ||
          ref.read(budgetRefreshProvider).generation != refresh.generation) {
        return null;
      }

      return DashboardData(
        transactions: transactions,
        accounts: accounts,
        accountBalances: accountBalances,
        budgets: budgets,
        recurringExpenses: recurringExpenses,
        goals: goals,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        totalBalance: totalBalance,
        netWorth: netWorth,
        pendingSmsCount: pendingSmsCount,
        budgetEvaluationDate: refresh.evaluationDate,
        budgetGeneration: refresh.generation,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Emit initial data immediately
  final initialData = await fetchData(budgetRefresh);
  if (!ref.mounted || initialData == null) return;
  lastEmittedData = initialData;
  yield initialData;

  // Watch for changes with debouncing
  final controller = StreamController<DashboardData>();
// Replace the single subscription block with:
  final mergedStream = StreamGroup.merge([
    isar.transactions.watchLazy(fireImmediately: false),
    isar.accounts.watchLazy(fireImmediately: false),
    isar.budgets.watchLazy(fireImmediately: false),
    isar.goals.watchLazy(fireImmediately: false),
    isar.recurringTransactions.watchLazy(fireImmediately: false),
  ]);

  final subscription = mergedStream.listen((_) {
    debounceTimer?.cancel();
    debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (!ref.mounted) return;
      try {
        final newData = await fetchData(budgetRefresh);
        if (!ref.mounted || newData == null) return;
        // Only emit if data actually changed
        if (lastEmittedData != newData) {
          lastEmittedData = newData;
          if (!controller.isClosed) {
            controller.add(newData);
          }
        }
      } catch (e) {
        if (!ref.mounted) return;
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    });
  });

  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });

  yield* controller.stream;
});

// Derived providers - use cached data with select for granular updates
final dashboardTransactionsProvider = Provider<List<Transaction>>((ref) {
  return ref.watch(
    dashboardDataProvider.select(
      (asyncValue) => asyncValue.value?.transactions ?? <Transaction>[],
    ),
  );
});

final dashboardAccountsProvider = Provider<List<Account>>((ref) {
  return ref.watch(
    dashboardDataProvider.select(
      (asyncValue) => asyncValue.value?.accounts ?? <Account>[],
    ),
  );
});

final dashboardAccountBalancesProvider = Provider<Map<int, double>>((ref) {
  return ref.watch(
    dashboardDataProvider.select(
      (asyncValue) => asyncValue.value?.accountBalances ?? <int, double>{},
    ),
  );
});

final dashboardBudgetsProvider = Provider<List<BudgetWithProgress>>((ref) {
  return ref.watch(
    dashboardDataProvider.select(
      (asyncValue) => asyncValue.value?.budgets ?? <BudgetWithProgress>[],
    ),
  );
});

final dashboardRecurringExpensesProvider =
    Provider<List<RecurringTransaction>>((ref) {
  return ref.watch(
    dashboardDataProvider.select(
      (asyncValue) =>
          asyncValue.value?.recurringExpenses ?? <RecurringTransaction>[],
    ),
  );
});

final dashboardTotalBalanceProvider = Provider<double>((ref) {
  return ref.watch(
    dashboardDataProvider.select(
      (asyncValue) => asyncValue.value?.totalBalance ?? 0.0,
    ),
  );
});

final dashboardNetWorthProvider = Provider<double>((ref) {
  return ref.watch(
    dashboardDataProvider.select(
      (asyncValue) => asyncValue.value?.netWorth ?? 0.0,
    ),
  );
});

final dashboardIncomeProvider = Provider<double>((ref) {
  return ref.watch(
    dashboardDataProvider.select(
      (asyncValue) => asyncValue.value?.totalIncome ?? 0.0,
    ),
  );
});

final dashboardExpenseProvider = Provider<double>((ref) {
  return ref.watch(
    dashboardDataProvider.select(
      (asyncValue) => asyncValue.value?.totalExpense ?? 0.0,
    ),
  );
});

final dashboardGoalsProvider = Provider<List<Goal>>((ref) {
  return ref.watch(
    dashboardDataProvider.select(
      (asyncValue) => asyncValue.value?.goals ?? <Goal>[],
    ),
  );
});

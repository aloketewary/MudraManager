import 'dart:async';
import 'package:async/async.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';

// Dashboard data model
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
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardData &&
          totalIncome == other.totalIncome &&
          totalExpense == other.totalExpense &&
          totalBalance == other.totalBalance &&
          netWorth == other.netWorth &&
          transactions.length == other.transactions.length &&
          accounts.length == other.accounts.length &&
          budgets.length == other.budgets.length &&
          goals.length == other.goals.length;

  @override
  int get hashCode =>
      transactions.length.hashCode ^
      accounts.length.hashCode ^
      budgets.length.hashCode ^
      goals.length.hashCode ^
      totalIncome.hashCode ^
      totalExpense.hashCode ^
      netWorth.hashCode;
}

// Main dashboard provider with debouncing
final dashboardDataProvider =
    StreamProvider.autoDispose<DashboardData>((ref) async* {
  final isar = await ref.watch(isarServiceProvider).getInstance();
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
    }
    return txns;
  }

  Future<DashboardData> fetchData() async {
    try {
      // Fetch all data in parallel
      final results = await Future.wait([
        getRecentTransactions(isar),
        ref.read(accountsProvider.future),
        accountService.getAccountBalanceMap(),
        budgetService.watchBudgetsWithProgress().first,
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

      final transactions = results[0] as List<Transaction>;
      final accounts = results[1] as List<Account>;
      final accountBalances = results[2] as Map<int, double>;
      final budgets = results[3] as List<BudgetWithProgress>;
      final recurringExpenses = results[4] as List<RecurringTransaction>;
      final goals = results[5] as List<Goal>;
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
      );
    } catch (e) {
      rethrow;
    }
  }

  // Emit initial data immediately
  final initialData = await fetchData();
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
      try {
        final newData = await fetchData();
        // Only emit if data actually changed
        if (lastEmittedData != newData) {
          lastEmittedData = newData;
          if (!controller.isClosed) {
            controller.add(newData);
          }
        }
      } catch (e) {
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
      (asyncValue) => asyncValue.valueOrNull?.transactions ?? <Transaction>[],
    ),
  );
});

final dashboardAccountsProvider = Provider<List<Account>>((ref) {
  return ref.watch(
    dashboardDataProvider.select(
      (asyncValue) => asyncValue.valueOrNull?.accounts ?? <Account>[],
    ),
  );
});

final dashboardAccountBalancesProvider = Provider<Map<int, double>>((ref) {
  return ref.watch(
    dashboardDataProvider.select(
      (asyncValue) =>
          asyncValue.valueOrNull?.accountBalances ?? <int, double>{},
    ),
  );
});

final dashboardBudgetsProvider = Provider<List<BudgetWithProgress>>((ref) {
  return ref.watch(
    dashboardDataProvider.select(
      (asyncValue) => asyncValue.valueOrNull?.budgets ?? <BudgetWithProgress>[],
    ),
  );
});

final dashboardRecurringExpensesProvider =
    Provider<List<RecurringTransaction>>((ref) {
  return ref.watch(
    dashboardDataProvider.select(
      (asyncValue) =>
          asyncValue.valueOrNull?.recurringExpenses ?? <RecurringTransaction>[],
    ),
  );
});

final dashboardTotalBalanceProvider = Provider<double>((ref) {
  return ref.watch(
    dashboardDataProvider.select(
      (asyncValue) => asyncValue.valueOrNull?.totalBalance ?? 0.0,
    ),
  );
});

final dashboardNetWorthProvider = Provider<double>((ref) {
  return ref.watch(
    dashboardDataProvider.select(
      (asyncValue) => asyncValue.valueOrNull?.netWorth ?? 0.0,
    ),
  );
});

final dashboardIncomeProvider = Provider<double>((ref) {
  return ref.watch(
    dashboardDataProvider.select(
      (asyncValue) => asyncValue.valueOrNull?.totalIncome ?? 0.0,
    ),
  );
});

final dashboardExpenseProvider = Provider<double>((ref) {
  return ref.watch(
    dashboardDataProvider.select(
      (asyncValue) => asyncValue.valueOrNull?.totalExpense ?? 0.0,
    ),
  );
});

final dashboardGoalsProvider = Provider<List<Goal>>((ref) {
  return ref.watch(
    dashboardDataProvider.select(
      (asyncValue) => asyncValue.valueOrNull?.goals ?? <Goal>[],
    ),
  );
});

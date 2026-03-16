import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
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
          runtimeType == other.runtimeType &&
          transactions.length == other.transactions.length &&
          accounts.length == other.accounts.length &&
          budgets.length == other.budgets.length &&
          goals.length == other.goals.length &&
          totalIncome == other.totalIncome &&
          totalExpense == other.totalExpense;

  @override
  int get hashCode =>
      transactions.length.hashCode ^
      accounts.length.hashCode ^
      budgets.length.hashCode ^
      goals.length.hashCode ^
      totalIncome.hashCode ^
      totalExpense.hashCode;
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

  Future<DashboardData> fetchData() async {
    try {
      // Fetch all data in parallel
      final results = await Future.wait([
        ref.read(transactionProvider).getAll(),
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
      ]);

      final transactions = results[0] as List<Transaction>;
      final accounts = results[1] as List<Account>;
      final accountBalances = results[2] as Map<int, double>;
      final budgets = results[3] as List<BudgetWithProgress>;
      final recurringExpenses = results[4] as List<RecurringTransaction>;
      final goals = results[5] as List<Goal>;

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
          .fold<double>(0, (sum, t) => sum + t.amount);

      final totalExpense = monthTransactions
          .where((t) => t.isExpense && !t.isTransfer)
          .fold<double>(0, (sum, t) => sum + t.amount);

      final totalBalance = accounts.fold<double>(0, (sum, acc) {
        final balance = accountBalances[acc.id] ?? 0;
        return acc.accountType == AccountType.creditCard
            ? sum - balance
            : sum + balance;
      });

      final netWorth = accounts.fold<double>(0, (sum, acc) {
        final balance = accountBalances[acc.id] ?? 0;
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
      print('Error fetching dashboard data: $e');
      rethrow;
    }
  }

  // Emit initial data immediately
  final initialData = await fetchData();
  lastEmittedData = initialData;
  yield initialData;

  // Watch for changes with debouncing
  final controller = StreamController<DashboardData>();

  final subscription =
      isar.transactions.watchLazy(fireImmediately: false).listen((_) {
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
      (asyncValue) => asyncValue.maybeWhen(
        data: (data) => data.transactions,
        orElse: () => <Transaction>[],
      ),
    ),
  );
});

final dashboardAccountsProvider = Provider<List<Account>>((ref) {
  return ref.watch(
    dashboardDataProvider.select(
      (asyncValue) => asyncValue.maybeWhen(
        data: (data) => data.accounts,
        orElse: () => <Account>[],
      ),
    ),
  );
});

final dashboardAccountBalancesProvider = Provider<Map<int, double>>((ref) {
  return ref.watch(
    dashboardDataProvider.select(
      (asyncValue) => asyncValue.maybeWhen(
        data: (data) => data.accountBalances,
        orElse: () => <int, double>{},
      ),
    ),
  );
});

final dashboardBudgetsProvider = Provider<List<BudgetWithProgress>>((ref) {
  return ref.watch(
    dashboardDataProvider.select(
      (asyncValue) => asyncValue.maybeWhen(
        data: (data) => data.budgets,
        orElse: () => <BudgetWithProgress>[],
      ),
    ),
  );
});

final dashboardRecurringExpensesProvider =
    Provider<List<RecurringTransaction>>((ref) {
  return ref.watch(
    dashboardDataProvider.select(
      (asyncValue) => asyncValue.maybeWhen(
        data: (data) => data.recurringExpenses,
        orElse: () => <RecurringTransaction>[],
      ),
    ),
  );
});

final dashboardTotalBalanceProvider = Provider<double>((ref) {
  return ref.watch(
    dashboardDataProvider.select(
      (asyncValue) => asyncValue.maybeWhen(
        data: (data) => data.totalBalance,
        orElse: () => 0.0,
      ),
    ),
  );
});

final dashboardNetWorthProvider = Provider<double>((ref) {
  return ref.watch(
    dashboardDataProvider.select(
      (asyncValue) => asyncValue.maybeWhen(
        data: (data) => data.netWorth,
        orElse: () => 0.0,
      ),
    ),
  );
});

final dashboardIncomeProvider = Provider<double>((ref) {
  return ref.watch(
    dashboardDataProvider.select(
      (asyncValue) => asyncValue.maybeWhen(
        data: (data) => data.totalIncome,
        orElse: () => 0.0,
      ),
    ),
  );
});

final dashboardExpenseProvider = Provider<double>((ref) {
  return ref.watch(
    dashboardDataProvider.select(
      (asyncValue) => asyncValue.maybeWhen(
        data: (data) => data.totalExpense,
        orElse: () => 0.0,
      ),
    ),
  );
});

final dashboardGoalsProvider = Provider<List<Goal>>((ref) {
  return ref.watch(
    dashboardDataProvider.select(
      (asyncValue) => asyncValue.maybeWhen(
        data: (data) => data.goals,
        orElse: () => <Goal>[],
      ),
    ),
  );
});

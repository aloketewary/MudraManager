import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/logging/app_log.dart';

final accountsProvider = FutureProvider.autoDispose((ref) async {
  final isarService = ref.watch(isarServiceProvider);
  final isar = await isarService.getInstance();
  return await isar.accounts.filter().isActiveEqualTo(true).findAll();
});

final accountServiceProvider = Provider((ref) {
  final isar = ref.watch(isarServiceProvider);
  final log = ref.getLogger('AccountService');
  return AccountsService(isar, log);
});

final balanceVisibilityProvider = StateProvider.autoDispose<bool>((ref) => true);

class AccountsService {
  final IsarService isarService;
  final AppLog log;

  AccountsService(this.isarService, this.log);

  Future<double> getAccountBalance(int accountId) async {
    final isar = await isarService.getInstance();

    final account = await isar.accounts.get(accountId);
    if (account == null) {
      log.w('Account not found: $accountId');
      return 0.0;
    }

    final income = await isar.transactions
        .filter()
        .account((q) => q.idEqualTo(accountId))
        .and()
        .isExpenseEqualTo(false)
        .amountProperty()
        .sum();

    final expense = await isar.transactions
        .filter()
        .account((q) => q.idEqualTo(accountId))
        .and()
        .isExpenseEqualTo(true)
        .amountProperty()
        .sum();

    // For credit cards: expenses increase debt, payments decrease debt
    if (account.accountType == AccountType.creditCard) {
      return account.initialBalance + expense - income;
    }

    return account.initialBalance + income - expense;
  }

  Future<Map<int, double>> getAccountBalanceMap() async {
    final isar = await isarService.getInstance();

    final accounts = await isar.accounts
        .filter()
        .isActiveEqualTo(true)
        .findAll();
    if (accounts.isEmpty) return <int, double>{};

    final balanceMap = <int, double>{};

    // Optimization: Fetch all transactions grouped by account in memory if feasible,
    // or use a more efficient summation.
    for (final account in accounts) {
      final accountId = account.id;

      // Using property().sum() is already quite fast in Isar as it's a native operation.
      // But we can ensure we only query transactions that AREN'T transfers (or handle them correctly).
      final income = await isar.transactions
          .filter()
          .account((q) => q.idEqualTo(accountId))
          .and()
          .isExpenseEqualTo(false)
          .amountProperty()
          .sum();

      final expense = await isar.transactions
          .filter()
          .account((q) => q.idEqualTo(accountId))
          .and()
          .isExpenseEqualTo(true)
          .amountProperty()
          .sum();

      // For credit cards: expenses increase debt, payments decrease debt
      final balance = account.accountType == AccountType.creditCard
          ? account.initialBalance + expense - income
          : account.initialBalance + income - expense;
      balanceMap[accountId] = balance;
    }

    return balanceMap;
  }
}

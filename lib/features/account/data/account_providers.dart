import 'package:mudra_manager/core/providers/state_value.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/db/extensions/field_encryption_ext.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/exchange_rate.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/collection_watchers.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/logging/app_log.dart';

final accountsProvider = FutureProvider.autoDispose((ref) async {
  ref.watch(accountChangeProvider);
  ref.watch(transactionChangeProvider);
  final isar = await ref.watch(isarServiceProvider).getInstance();
  final accounts = await isar.accounts.filter().isActiveEqualTo(true).findAll();
  for (final a in accounts) {
    a.decryptFields();
  }
  return accounts;
});

final accountServiceProvider = Provider((ref) {
  final isar = ref.watch(isarServiceProvider);
  final log = ref.getLogger('AccountService');
  return AccountsService(isar, log);
});

final allAccountsProvider = FutureProvider.autoDispose((ref) async {
  ref.watch(accountChangeProvider);
  ref.watch(transactionChangeProvider);
  final isarService = ref.watch(isarServiceProvider);
  final isar = await isarService.getInstance();
  final accounts = await isar.accounts.where().findAll();
  for (final a in accounts) {
    a.decryptFields();
  }
  return accounts;
});

final accountBalanceMapProvider = FutureProvider.autoDispose<Map<int, double>>((ref) async {
  ref.watch(accountChangeProvider);
  ref.watch(transactionChangeProvider);
  final service = ref.watch(accountServiceProvider);
  return service.getAccountBalanceMap();
});

final accountBaseBalanceMapProvider = FutureProvider.autoDispose<Map<int, double>>((ref) async {
  ref.watch(accountChangeProvider);
  ref.watch(transactionChangeProvider);
  final service = ref.watch(accountServiceProvider);
  return service.getAccountBalanceMapInBase();
});

final balanceVisibilityProvider =
    NotifierProvider.autoDispose<StateValue<bool>, bool>(
  () => StateValue(true),
);

/// The user's primary/default account.
final primaryAccountProvider = FutureProvider.autoDispose<Account?>((ref) async {
  ref.watch(accountChangeProvider);
  final isar = await ref.watch(isarServiceProvider).getInstance();
  // Find the primary account
  var primary = await isar.accounts
      .filter()
      .isPrimaryEqualTo(true)
      .isActiveEqualTo(true)
      .findFirst();
  // Fallback: first active account
  primary ??= await isar.accounts
      .filter()
      .isActiveEqualTo(true)
      .findFirst();
  return primary;
});

// Add this new provider:
final frequencySortedAccountsProvider =
    FutureProvider.autoDispose<List<Account>>((ref) async {
  final accounts = await ref.watch(accountsProvider.future);
  if (accounts.isEmpty) return accounts;

  ref.watch(transactionChangeProvider);
  final isar = await ref.watch(isarServiceProvider).getInstance();
  final cutoff = DateTime.now().subtract(const Duration(days: 30));

  // Single query: all recent transactions, group by account in memory
  final recentTxns = await isar.transactions
      .filter()
      .dateGreaterThan(cutoff)
      .findAll();

  final counts = <int, int>{};
  for (final txn in recentTxns) {
    txn.account.loadSync();
    final accId = txn.account.value?.id;
    if (accId != null) {
      counts[accId] = (counts[accId] ?? 0) + 1;
    }
  }

  return accounts.toList()
    ..sort((a, b) => (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0));
});

class AccountsService {
  final IsarService isarService;
  final AppLog log;

  AccountsService(this.isarService, this.log);

  /// Sets the given account as primary, clearing any previous primary.
  Future<void> setPrimaryAccount(int accountId) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      // Clear existing primary
      final current = await isar.accounts
          .filter()
          .isPrimaryEqualTo(true)
          .findAll();
      for (final acc in current) {
        acc.isPrimary = false;
        await isar.accounts.put(acc);
      }
      // Set new primary
      final account = await isar.accounts.get(accountId);
      if (account != null) {
        account.isPrimary = true;
        await isar.accounts.put(account);
      }
    });
  }

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
    final accounts =
        await isar.accounts.filter().isActiveEqualTo(true).findAll();
    if (accounts.isEmpty) return {};

    // Run all queries in parallel instead of sequentially
    final futures = accounts.map((acc) async {
      final results = await Future.wait([
        isar.transactions
            .filter()
            .account((q) => q.idEqualTo(acc.id))
            .isExpenseEqualTo(false)
            .amountProperty()
            .sum(),
        isar.transactions
            .filter()
            .account((q) => q.idEqualTo(acc.id))
            .isExpenseEqualTo(true)
            .amountProperty()
            .sum(),
      ]);
      final income = results[0];
      final expense = results[1];
      final balance = acc.accountType == AccountType.creditCard
          ? acc.initialBalance + expense - income
          : acc.initialBalance + income - expense;
      return MapEntry(acc.id, balance);
    });

    final entries = await Future.wait(futures);
    return Map.fromEntries(entries);
  }

  /// Returns balances converted to base currency for cross-account totals.
  Future<Map<int, double>> getAccountBalanceMapInBase() async {
    final isar = await isarService.getInstance();
    final accounts =
        await isar.accounts.filter().isActiveEqualTo(true).findAll();
    if (accounts.isEmpty) return {};

    final rates = await isar.exchangeRates.where().findAll();
    final rateMap = {for (final r in rates) r.currencyCode: r.rateToBase};
    // Populate the shared cache so other code benefits
    CurrencyService.mergeCachedRates(rateMap);

    final futures = accounts.map((acc) async {
      final results = await Future.wait([
        isar.transactions
            .filter()
            .account((q) => q.idEqualTo(acc.id))
            .isExpenseEqualTo(false)
            .amountProperty()
            .sum(),
        isar.transactions
            .filter()
            .account((q) => q.idEqualTo(acc.id))
            .isExpenseEqualTo(true)
            .amountProperty()
            .sum(),
      ]);
      final income = results[0];
      final expense = results[1];
      final rawBalance = acc.accountType == AccountType.creditCard
          ? acc.initialBalance + expense - income
          : acc.initialBalance + income - expense;

      final rate = acc.currencyCode != null
          ? (rateMap[acc.currencyCode!] ?? 1.0)
          : 1.0;
      return MapEntry(acc.id, rawBalance * rate);
    });

    final entries = await Future.wait(futures);
    return Map.fromEntries(entries);
  }
}

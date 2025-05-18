import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:mudra_manager/db/isar_service.dart' show IsarService;
import 'package:mudra_manager/db/models/account.dart';
import 'package:mudra_manager/db/models/transaction.dart';
import 'package:mudra_manager/providers/isar_provider.dart';

final accountsProvider = FutureProvider.autoDispose((ref) async {
  final isarService = ref.watch(isarServiceProvider);
  final isar = await isarService.getInstance();
  return await isar.accounts.filter().isActiveEqualTo(true).findAll();
});

final accountServiceProvider = Provider((ref) {
  final isar = ref.watch(isarServiceProvider);
  return AccountsService(isar);
});

final balanceVisibilityProvider = StateProvider<bool>((ref) => true);

class AccountsService {
  final IsarService isarService;

  AccountsService(this.isarService);

  Future<double> getAccountBalance(int accountId) async {
    final isar = await isarService.getInstance();

    final account = await isar.accounts.get(accountId);
    if (account == null) return 0.0;

    final income =
        await isar.transactions
            .filter()
            .account((q) => q.idEqualTo(accountId))
            .and()
            .isExpenseEqualTo(false)
            .amountProperty()
            .sum();

    final expense =
        await isar.transactions
            .filter()
            .account((q) => q.idEqualTo(accountId))
            .and()
            .isExpenseEqualTo(true)
            .amountProperty()
            .sum();

    return account.initialBalance + income - expense;
  }

  Future<Map<int, double>> getAccountBalanceMap() async {
    final isar = await isarService.getInstance();

    final accounts = await isar.accounts.filter().isActiveEqualTo(true).findAll();
    if (accounts.isEmpty) return <int, double>{};

    final balanceMap = <int, double>{};

    for (final account in accounts) {
      final accountId = account.id;

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

      final balance = account.initialBalance + income - expense;
      balanceMap[accountId] = balance;
    }

    return balanceMap;
  }
}

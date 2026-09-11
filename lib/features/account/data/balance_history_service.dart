import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/balance_snapshot.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/features/account/data/account_data_contract.dart';

class BalanceHistoryService {
  final IsarService _isarService;
  final AppLog _log = AppLog(getLogger(), 'BalanceHistoryService');

  BalanceHistoryService(this._isarService);

  Future<void> recordDailySnapshots() async {
    final isar = await _isarService.getInstance();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Link/count-only aggregation: account ID/type drive snapshot math;
    // account-number content remains opaque and is never rendered or rewritten.
    final accounts = await AccountDataContract.linkProjections(isar);

    for (final account in accounts) {
      // Check if snapshot already exists for today
      final existingSnapshot = await isar.balanceSnapshots
          .filter()
          .account((q) => q.idEqualTo(account.id))
          .and()
          .dateBetween(
            today,
            DateTime(now.year, now.month, now.day, 23, 59, 59),
          )
          .findFirst();

      if (existingSnapshot != null) continue;

      // Calculate current balance
      final income = await isar.transactions
          .filter()
          .account((q) => q.idEqualTo(account.id))
          .and()
          .isExpenseEqualTo(false)
          .amountProperty()
          .sum();

      final expense = await isar.transactions
          .filter()
          .account((q) => q.idEqualTo(account.id))
          .and()
          .isExpenseEqualTo(true)
          .amountProperty()
          .sum();

      final balance = account.accountType == AccountType.creditCard
          ? account.initialBalance + expense - income
          : account.initialBalance + income - expense;

      final snapshot = BalanceSnapshot.create(date: today, balance: balance);
      await isar.writeTxn(() async {
        await isar.balanceSnapshots.put(snapshot);
        final storedAccount = await isar.accounts.get(account.id);
        if (storedAccount == null) return;
        snapshot.account.value = storedAccount;
        await snapshot.account.save();
      });

      _log.i(
        'Snapshot recorded for account ${account.id}: ${BaseCurrency.symbol}$balance',
      );
    }
  }

  Future<List<BalanceSnapshot>> getBalanceHistory(
    int accountId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final isar = await IsarService.initIsar();

    final start =
        startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    return await isar.balanceSnapshots
        .filter()
        .account((q) => q.idEqualTo(accountId))
        .and()
        .dateBetween(start, end)
        .sortByDate()
        .findAll();
  }

  Future<double?> getBalanceOnDate(int accountId, DateTime date) async {
    final isar = await IsarService.initIsar();

    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final snapshot = await isar.balanceSnapshots
        .filter()
        .account((q) => q.idEqualTo(accountId))
        .and()
        .dateLessThan(endOfDay, include: true)
        .sortByDateDesc()
        .findFirst();

    return snapshot?.balance;
  }
}

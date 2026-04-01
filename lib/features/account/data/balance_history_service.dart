import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/balance_snapshot.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';

class BalanceHistoryService {
  static final BalanceHistoryService instance = BalanceHistoryService._();
  static final AppLog _log = AppLog(getLogger(), 'BalanceHistoryService');

  BalanceHistoryService._();

  Future<void> recordDailySnapshots() async {
    final isar = await IsarService().getInstance();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final accounts = await isar.accounts.where().findAll();

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
        snapshot.account.value = account;
        await snapshot.account.save();
      });

      _log.i('Snapshot recorded for ${account.name}: ₹$balance');
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

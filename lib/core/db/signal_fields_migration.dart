import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Migration: backfills denormalized fields added for signal generation.
///
/// - Transaction.categoryId (from category IsarLink)
/// - Goal.lastContributionDate (from embedded contributions list)
///
/// RecurringTransaction.lastExecutedDate is left null for existing bills —
/// it will be populated on next execution cycle.
class SignalFieldsMigration {
  static const _migrationKey = 'migration_signal_fields_v1';
  static final _log = AppLog(getLogger(), 'SignalFieldsMigration');

  static Future<void> run(Isar isar) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migrationKey) == true) return;

    _log.i('Starting signal fields migration...');

    await _backfillCategoryIds(isar);
    await _backfillLastContributionDates(isar);

    await prefs.setBool(_migrationKey, true);
    _log.i('Signal fields migration complete.');
  }

  static Future<void> _backfillCategoryIds(Isar isar) async {
    final transactions = await isar.transactions
        .filter()
        .categoryIdIsNull()
        .findAll();

    if (transactions.isEmpty) return;

    var count = 0;
    await isar.writeTxn(() async {
      for (final txn in transactions) {
        await txn.category.load();
        final catId = txn.category.value?.id;
        if (catId != null) {
          txn.categoryId = catId;
          await isar.transactions.put(txn);
          count++;
        }
      }
    });

    _log.i('Backfilled categoryId on $count transactions.');
  }

  static Future<void> _backfillLastContributionDates(Isar isar) async {
    final goals = await isar.goals.where().findAll();
    if (goals.isEmpty) return;

    var count = 0;
    await isar.writeTxn(() async {
      for (final goal in goals) {
        if (goal.contributions.isEmpty) continue;
        if (goal.lastContributionDate != null) continue;

        final sorted = goal.contributions.toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        goal.lastContributionDate = sorted.first.date;
        await isar.goals.put(goal);
        count++;
      }
    });

    _log.i('Backfilled lastContributionDate on $count goals.');
  }
}

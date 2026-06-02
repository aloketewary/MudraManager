import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/features/memory/data/financial_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Computes FinancialSnapshot records from raw transaction data.
/// Called by BackgroundTaskManager (every 6h) and on app open for current month.
class SnapshotGenerator {
  /// Bump this when snapshot schema or aggregation logic changes.
  /// Triggers automatic re-backfill on next app open.
  static const snapshotBackfillVersion = 1;
  static const _versionKey = 'snapshot_backfill_version';

  final Isar _isar;

  SnapshotGenerator(this._isar);

  /// Generate or update snapshot for a specific month.
  Future<void> generateForMonth(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final txns = await _isar.transactions
        .where()
        .dateBetween(start, end)
        .filter()
        .isTransferEqualTo(false)
        .isSettlementEqualTo(false)
        .findAll();

    // Batch load all links in single pass
    for (final tx in txns) {
      tx.category.loadSync();
      tx.account.loadSync();
    }

    double income = 0, expense = 0;
    double cashExp = 0, weekendExp = 0, weekdayExp = 0;
    final catTotals = <int, double>{};

    for (final tx in txns) {
      if (tx.isExpense) {
        final amt = tx.baseAmount;
        expense += amt;
        final catId = tx.category.value?.id;
        if (catId != null) catTotals[catId] = (catTotals[catId] ?? 0) + amt;
        if (tx.account.value?.accountType == AccountType.cash) cashExp += amt;
        if (tx.date.weekday >= 6) {
          weekendExp += amt;
        } else {
          weekdayExp += amt;
        }
      } else {
        income += tx.baseAmount;
      }
    }

    final sortedCats = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final existing = await _isar.financialSnapshots
        .filter()
        .monthEqualTo(start)
        .findFirst();

    final snapshot = existing ?? FinancialSnapshot();
    snapshot
      ..month = start
      ..income = income
      ..expense = expense
      ..transactionCount = txns.length
      ..categoryIds = sortedCats.map((e) => e.key).toList()
      ..categoryAmounts = sortedCats.map((e) => e.value).toList()
      ..cashExpense = cashExp
      ..weekendExpense = weekendExp
      ..weekdayExpense = weekdayExp
      ..computedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.financialSnapshots.put(snapshot);
    });
  }

  /// Runs backfill only if version has changed. Idempotent.
  Future<void> backfillIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_versionKey) ?? 0;
    if (stored >= snapshotBackfillVersion) {
      // Version current — just refresh this month
      await refreshCurrentMonth();
      return;
    }
    await _backfillAll();
    await prefs.setInt(_versionKey, snapshotBackfillVersion);
  }

  Future<void> _backfillAll() async {
    final oldest = await _isar.transactions.where().sortByDate().findFirst();
    if (oldest == null) return;
    var current = DateTime(oldest.date.year, oldest.date.month, 1);
    final now = DateTime.now();
    while (current.isBefore(now)) {
      await generateForMonth(current);
      current = DateTime(current.year, current.month + 1, 1);
    }
  }

  Future<void> refreshCurrentMonth() => generateForMonth(DateTime.now());
}

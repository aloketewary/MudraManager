import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/budget_period_ledger_migration.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/budget_category_allocation.dart';
import 'package:mudra_manager/core/db/models/budget_period_ledger_entry.dart';
import 'package:mudra_manager/core/db/models/budget_type.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/exchange_rate.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('budget_ledger_migration_');
    final existing = Isar.getInstance();
    if (existing != null && existing.isOpen) await existing.close();
    isar = await Isar.open(
      [
        BudgetSchema,
        BudgetCategoryAllocationSchema,
        BudgetPeriodLedgerEntrySchema,
        CategorySchema,
        TagSchema,
        TransactionSchema,
        AccountSchema,
        RecurringTransactionSchema,
        ExchangeRateSchema,
      ],
      directory: tempDir.path,
    );
  });

  tearDown(() async {
    await isar.close();
    tempDir.deleteSync(recursive: true);
  });

  Budget budget({
    required int id,
    required DateTime start,
    required DateTime end,
    required double amount,
    BudgetRecurrence recurrence = BudgetRecurrence.none,
    bool archived = false,
  }) {
    return Budget()
      ..id = id
      ..name = 'Legacy $id'
      ..amount = amount
      ..startDate = start
      ..endDate = end
      ..budgetType = BudgetType.dayWise
      ..recurrence = recurrence
      ..isArchived = archived;
  }

  test('backfills completed records without changing source records', () async {
    final oneTime = budget(
      id: 1,
      start: DateTime(2024, 1, 1),
      end: DateTime(2024, 1, 31),
      amount: 100,
    );
    final recurring = budget(
      id: 2,
      start: DateTime(2024, 1, 1),
      end: DateTime(2024, 1, 31),
      amount: 200,
      recurrence: BudgetRecurrence.monthly,
    );
    final archived = budget(
      id: 3,
      start: DateTime(2024, 2, 1),
      end: DateTime(2024, 2, 29),
      amount: 300,
      archived: true,
    );
    final transaction = Transaction.create(
      date: DateTime(2024, 1, 31, 23, 59),
      amount: 75,
      isExpense: true,
    );

    await isar.writeTxn(() async {
      await isar.budgets.putAll([oneTime, recurring, archived]);
      await isar.transactions.put(transaction);
    });
    final originalDate = transaction.date;

    final created = await BudgetPeriodLedgerMigration.backfill(
      isar,
      evaluationDate: DateTime(2024, 3, 1),
    );
    expect(created, 4); // one-time + recurring Jan/Feb + archived

    final entries = await isar.budgetPeriodLedgerEntrys.where().findAll();
    expect(entries, hasLength(4));
    expect(entries.map((entry) => entry.occurrenceKey).toSet(), hasLength(4));
    expect(entries.every((entry) => entry.isFinalized), isTrue);
    expect(
      entries.every(
        (entry) =>
            entry.provenance == BudgetPeriodLedgerProvenance.legacyUnknown &&
            !entry.limitIsKnown &&
            entry.status == BudgetPeriodLedgerStatus.unknown,
      ),
      isTrue,
    );
    expect(
      entries.where((entry) => entry.budgetId == recurring.id),
      hasLength(2),
    );
    expect(
      entries
          .where((entry) => entry.budgetId == recurring.id)
          .map((entry) => entry.periodStart.month),
      containsAll(<int>[1, 2]),
    );

    final storedBudget = await isar.budgets.get(oneTime.id);
    final storedTransaction = await isar.transactions.get(transaction.id);
    expect(storedBudget?.amount, oneTime.amount);
    expect(storedBudget?.startDate, oneTime.startDate);
    expect(storedBudget?.endDate, oneTime.endDate);
    expect(storedTransaction?.amount, transaction.amount);
    expect(storedTransaction?.date, originalDate);
  });

  test('rerunning backfill creates no duplicate occurrence rows', () async {
    final legacy = budget(
      id: 10,
      start: DateTime(2024, 1, 1),
      end: DateTime(2024, 1, 31),
      amount: 250,
    );
    await isar.writeTxn(() => isar.budgets.put(legacy));

    expect(
      await BudgetPeriodLedgerMigration.backfill(
        isar,
        evaluationDate: DateTime(2024, 2, 1),
      ),
      1,
    );
    expect(
      await BudgetPeriodLedgerMigration.backfill(
        isar,
        evaluationDate: DateTime(2024, 2, 1),
      ),
      0,
    );
    expect(await isar.budgetPeriodLedgerEntrys.count(), 1);
  });

  test('startup guard is retry-safe and idempotent', () async {
    final legacy = budget(
      id: 20,
      start: DateTime(2024, 1, 1),
      end: DateTime(2024, 1, 31),
      amount: 50,
    );
    await isar.writeTxn(() => isar.budgets.put(legacy));

    expect(
      await BudgetPeriodLedgerMigration.run(
        isar,
        evaluationDate: DateTime(2024, 2, 1),
      ),
      1,
    );
    expect(
      await BudgetPeriodLedgerMigration.run(
        isar,
        evaluationDate: DateTime(2024, 2, 1),
      ),
      0,
    );
    expect(await isar.budgetPeriodLedgerEntrys.count(), 1);
    expect(
      (await isar.budgetPeriodLedgerEntrys.where().findFirst())?.provenance,
      BudgetPeriodLedgerProvenance.legacyUnknown,
    );
  });
}

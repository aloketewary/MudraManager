import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
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
import 'package:mudra_manager/core/domain/budget_period_ledger_adapter.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/features/budget/data/budget_period_ledger_service.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late Directory tempDir;
  late BudgetService budgetService;
  late BudgetPeriodLedgerService ledgerService;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('budget_history_');
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
    final isarService = IsarService();
    budgetService = BudgetService(
      isarService,
      AppLog(getLogger(), 'BudgetHistoryTest'),
      null,
    );
    ledgerService = BudgetPeriodLedgerService(isarService);
  });

  tearDown(() async {
    await isar.close();
    tempDir.deleteSync(recursive: true);
  });

  Budget makeBudget({
    required int id,
    required double amount,
    required DateTime start,
    required DateTime end,
    BudgetRecurrence recurrence = BudgetRecurrence.none,
    bool archived = false,
  }) {
    return Budget()
      ..id = id
      ..name = 'History $id'
      ..amount = amount
      ..startDate = start
      ..endDate = end
      ..budgetType = BudgetType.dayWise
      ..recurrence = recurrence
      ..isArchived = archived;
  }

  Future<void> addExpense(DateTime date, double amount) async {
    await isar.writeTxn(
      () => isar.transactions.put(
        Transaction.create(date: date, amount: amount, isExpense: true),
      ),
    );
  }

  group('Property 6: completed history and status', () {
    test('history exposes ended, recurring, and archived periods once',
        () async {
      final ended = makeBudget(
        id: 1,
        amount: 50,
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      );
      final recurring = makeBudget(
        id: 2,
        amount: 100,
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
        recurrence: BudgetRecurrence.monthly,
      );
      final archived = makeBudget(
        id: 3,
        amount: 100,
        start: DateTime(2024, 2, 1),
        end: DateTime(2024, 2, 28),
        archived: true,
      );
      await isar.writeTxn(
        () => isar.budgets.putAll([ended, recurring, archived]),
      );
      await addExpense(DateTime(2024, 1, 15), 50);
      await addExpense(DateTime(2024, 2, 15), 101);

      final history = await budgetService.getBudgetHistory(
        evaluationDate: DateTime(2024, 3, 15),
      );
      final keys = history.map((entry) => entry.occurrenceKey).toSet();
      expect(keys.length, history.length);
      expect(history, isNotEmpty);
      expect(
        history.where((entry) => entry.budgetId == recurring.id),
        hasLength(2),
      );

      final endedEntry =
          history.firstWhere((entry) => entry.budgetId == ended.id);
      expect(endedEntry.periodStart, DateTime(2024, 1, 1));
      expect(endedEntry.periodEnd, DateTime(2024, 1, 31, 23, 59, 59, 999, 999));
      expect(endedEntry.limit, 50);
      expect(endedEntry.spent, 50);
      expect(endedEntry.status, BudgetPeriodStatus.met);

      final recurringEnds = history
          .where((entry) => entry.budgetId == recurring.id)
          .map((entry) => entry.periodEnd.month)
          .toList();
      expect(recurringEnds, containsAll(<int>[1, 2]));
      expect(
        history.where((entry) => entry.budgetId == archived.id).single.status,
        BudgetPeriodStatus.exceeded,
      );
    });

    test('status rule remains deterministic for 120 generated periods', () {
      // Generated deterministic cases: 120 iterations.
      for (var i = 0; i < 120; i++) {
        final limit = 100.0 + i;
        final spent = i % 3 == 0
            ? limit - 1
            : i % 3 == 1
                ? limit
                : limit + 1;
        final budget = makeBudget(
          id: i + 10,
          amount: limit,
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 31),
        );
        final snapshot = BudgetPeriodSnapshot.fromBudget(
          budget: budget,
          evaluationDate: DateTime(2024, 2, 1),
          periodStart: DateTime(2024, 1, 1),
          periodEnd: DateTime(2024, 1, 31),
          spent: spent,
        );
        final entry = snapshot.toLedgerEntry(
          recordedAt: DateTime(2024, 2, 1),
          finalizedAt: DateTime(2024, 2, 1),
        );
        expect(
          entry.status,
          spent <= limit
              ? BudgetPeriodLedgerStatus.met
              : BudgetPeriodLedgerStatus.exceeded,
        );
        expect(entry.limitAtPeriod, limit);
        expect(entry.finalSpent, spent);
      }
    });
  });

  group('History boundary and ordering', () {
    test('current recurring occurrence stays out of history on exact end date',
        () async {
      final budget = makeBudget(
        id: 20,
        amount: 100,
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
        recurrence: BudgetRecurrence.monthly,
      );
      await isar.writeTxn(() => isar.budgets.put(budget));

      final onEnd = await budgetService.getBudgetHistory(
        evaluationDate: DateTime(2024, 1, 31),
      );
      expect(onEnd.where((entry) => entry.budgetId == budget.id), isEmpty);

      final afterEnd = await budgetService.getBudgetHistory(
        evaluationDate: DateTime(2024, 2, 1),
      );
      expect(
        afterEnd.where((entry) => entry.budgetId == budget.id),
        hasLength(1),
      );
    });

    test('same-end history sorts by numeric budget ID then occurrence key',
        () async {
      final higher = makeBudget(
        id: 10,
        amount: 100,
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      );
      final lower = makeBudget(
        id: 2,
        amount: 100,
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      );
      await isar.writeTxn(() => isar.budgets.putAll([higher, lower]));

      final history = await budgetService.getBudgetHistory(
        evaluationDate: DateTime(2024, 2, 1),
      );
      expect(
        history
            .where((entry) => entry.periodEnd.day == 31)
            .map((e) => e.budgetId),
        [2, 10],
      );
    });

    test('legacy derived values are explicitly marked best available',
        () async {
      final budget = makeBudget(
        id: 21,
        amount: 100,
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      );
      await isar.writeTxn(() => isar.budgets.put(budget));

      final history = await budgetService.getBudgetHistory(
        evaluationDate: DateTime(2024, 2, 1),
      );
      final entry = history.single;
      expect(entry.valueSource, BudgetHistoryValueSource.legacyBestAvailable);
      expect(entry.limitIsKnown, isTrue);
      expect(entry.status, BudgetPeriodStatus.met);
    });
  });

  group('Property 6: ledger finalization and migration safety', () {
    test('finalization is idempotent and preserves finalized historical facts',
        () async {
      final budget = makeBudget(
        id: 7,
        amount: 100,
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      );
      await isar.writeTxn(() async {
        await isar.budgets.put(budget);
        await isar.transactions.put(
          Transaction.create(
            date: DateTime(2024, 1, 31, 23, 59),
            amount: 100,
            isExpense: true,
          ),
        );
      });
      final snapshot = BudgetPeriodSnapshot.fromBudget(
        budget: budget,
        evaluationDate: DateTime(2024, 2, 1),
        periodStart: budget.startDate,
        periodEnd: budget.endDate,
        spent: 100,
      );

      final first = await ledgerService.finalizeSnapshot(
        snapshot,
        finalizedAt: DateTime(2024, 2, 1),
      );
      final duplicate = await ledgerService.finalizeSnapshot(
        snapshot,
        finalizedAt: DateTime(2024, 2, 2),
      );
      expect(duplicate.id, first.id);
      expect(await isar.budgetPeriodLedgerEntrys.count(), 1);

      budget.amount = 1000;
      await isar.writeTxn(() => isar.budgets.put(budget));
      final changedCandidate = BudgetPeriodSnapshot.fromBudget(
        budget: budget,
        evaluationDate: DateTime(2024, 2, 1),
        periodStart: snapshot.periodStart,
        periodEnd: snapshot.periodEnd,
        spent: 999,
      ).toLedgerEntry(finalizedAt: DateTime(2024, 2, 3));
      final retained = await ledgerService.upsertEntry(changedCandidate);

      expect(retained.id, first.id);
      expect(retained.limitAtPeriod, 100);
      expect(retained.finalSpent, 100);
      expect((await isar.budgets.get(budget.id))?.amount, 1000);
      expect((await isar.transactions.where().findFirst())?.amount, 100);
      final completed = await ledgerService.readCompleted(
        evaluationDate: DateTime(2024, 2, 2),
      );
      expect(completed.single.status, BudgetPeriodLedgerStatus.met);
      final history = await budgetService.getBudgetHistory(
        evaluationDate: DateTime(2024, 2, 2),
      );
      expect(history.single.valueSource, BudgetHistoryValueSource.persisted);
      expect(history.single.limit, 100);
      expect(history.single.spent, 100);
    });

    test('backfill rerun is non-destructive and does not duplicate rows',
        () async {
      final budget = makeBudget(
        id: 8,
        amount: 250,
        start: DateTime(2023, 1, 1),
        end: DateTime(2023, 1, 31),
      );
      final transaction = Transaction.create(
        date: DateTime(2023, 1, 15),
        amount: 40,
        isExpense: true,
      );
      await isar.writeTxn(() async {
        await isar.budgets.put(budget);
        await isar.transactions.put(transaction);
      });
      final snapshot = BudgetPeriodSnapshot.fromBudget(
        budget: budget,
        evaluationDate: DateTime(2024, 1, 1),
        periodStart: budget.startDate,
        periodEnd: budget.endDate,
        spent: 40,
      );

      await ledgerService.recordBackfill(
        snapshot,
        provenance: BudgetPeriodLedgerProvenance.backfilledExact,
        limitIsKnown: true,
      );
      await ledgerService.recordBackfill(
        snapshot,
        provenance: BudgetPeriodLedgerProvenance.backfilledExact,
        limitIsKnown: true,
      );

      expect(await isar.budgetPeriodLedgerEntrys.count(), 1);
      expect((await isar.budgets.get(budget.id))?.amount, 250);
      expect((await isar.transactions.get(transaction.id))?.amount, 40);
      final entry = (await ledgerService.readCompleted(
        evaluationDate: DateTime(2024, 2, 1),
      ))
          .single;
      expect(entry.occurrenceKey, snapshot.occurrenceKey);
      expect(entry.limitIsKnown, isTrue);
      expect(entry.status, BudgetPeriodLedgerStatus.met);

      final unknownBudget = makeBudget(
        id: 9,
        amount: 0,
        start: DateTime(2023, 2, 1),
        end: DateTime(2023, 2, 28),
      );
      await isar.writeTxn(() => isar.budgets.put(unknownBudget));
      final unknownSnapshot = BudgetPeriodSnapshot.fromBudget(
        budget: unknownBudget,
        evaluationDate: DateTime(2024, 1, 1),
        periodStart: unknownBudget.startDate,
        periodEnd: unknownBudget.endDate,
        spent: 12,
      );
      await ledgerService.recordBackfill(
        unknownSnapshot,
        provenance: BudgetPeriodLedgerProvenance.legacyUnknown,
        limitIsKnown: false,
      );
      final history = await budgetService.getBudgetHistory(
        evaluationDate: DateTime(2024, 2, 1),
      );
      final unknown = history.singleWhere((item) => item.budgetId == 9);
      expect(unknown.valueSource, BudgetHistoryValueSource.unknown);
      expect(unknown.limitIsKnown, isFalse);
      expect(unknown.status, isNull);
    });
  });
}

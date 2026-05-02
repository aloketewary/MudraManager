import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/exchange_rate.dart';
import 'package:mudra_manager/core/db/models/frequency.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/trip.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/utils/date_arithmetic.dart';
import 'package:mudra_manager/features/transactions/data/transaction_service.dart';

late Isar isar;
late Directory tmpDir;
late TransactionService service;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('txn_integration_test_');
    final existing = Isar.getInstance();
    if (existing != null && existing.isOpen) await existing.close();

    isar = await Isar.open(
      [
        TransactionSchema,
        CategorySchema,
        AccountSchema,
        TagSchema,
        RecurringTransactionSchema,
        ExchangeRateSchema,
        TripSchema,
        TripParticipantSchema,
        TripTransactionSchema,
        SplitExpenseSchema,
        SettlementSchema,
      ],
      directory: tmpDir.path,
    );

    final isarService = IsarService();
    service = TransactionService(
      isarService,
      AppLog(getLogger(), 'TxnIntegrationTest'),
      null,
    );
  });

  tearDown(() async {
    await isar.close();
    tmpDir.deleteSync(recursive: true);
  });

  // ── Helpers ──

  Future<Category> seedCategory(String name, {bool isExpense = true}) async {
    final cat = Category()
      ..name = name
      ..iconName = 'circle'
      ..categoryType =
          isExpense ? CategoryType.expense : CategoryType.income;
    await isar.writeTxn(() => isar.categorys.put(cat));
    return cat;
  }

  Future<Account> seedAccount(String name) async {
    final acc = Account()
      ..name = name
      ..accountType = AccountType.bank
      ..initialBalance = 0
      ..isActive = true;
    await isar.writeTxn(() => isar.accounts.put(acc));
    return acc;
  }

  Future<Transaction> addExpense(
    double amount,
    Category cat,
    Account acc, {
    DateTime? date,
    String? description,
  }) async {
    final txn = Transaction.create(
      date: date ?? DateTime.now(),
      amount: amount,
      isExpense: true,
      description: description,
    )
      ..category.value = cat
      ..account.value = acc;
    await service.addTransaction(txn);
    return txn;
  }

  Future<RecurringTransaction> seedRecurring({
    required double amount,
    required Category cat,
    required Account acc,
    required DateTime nextDueDate,
    Frequency frequency = Frequency.monthly,
  }) async {
    final recurring = RecurringTransaction()
      ..amount = amount
      ..isExpense = true
      ..frequency = frequency
      ..nextDueDate = nextDueDate
      ..startDate = nextDueDate.subtract(const Duration(days: 30))
      ..isActive = true;
    recurring.category.value = cat;
    recurring.account.value = acc;
    await isar.writeTxn(() async {
      await isar.recurringTransactions.put(recurring);
      await recurring.category.save();
      await recurring.account.save();
    });
    return recurring;
  }

  // ── Integration Tests ──

  group('Delete + immediate re-read (DB consistency)', () {
    test('deleted transaction is gone from getAll immediately', () async {
      final cat = await seedCategory('Food');
      final acc = await seedAccount('Cash');

      final txn1 = await addExpense(100, cat, acc);
      final txn2 = await addExpense(200, cat, acc);
      final txn3 = await addExpense(300, cat, acc);

      expect((await service.getAll()).length, 3);

      await service.deleteTransaction(txn2.id);

      final remaining = await service.getAll();
      expect(remaining.length, 2);
      expect(remaining.any((t) => t.id == txn2.id), false);
      expect(remaining.any((t) => t.id == txn1.id), true);
      expect(remaining.any((t) => t.id == txn3.id), true);
    });

    test('back-to-back deletes remove all targeted transactions', () async {
      final cat = await seedCategory('Food');
      final acc = await seedAccount('Cash');

      final txn1 = await addExpense(100, cat, acc);
      final txn2 = await addExpense(200, cat, acc);
      final txn3 = await addExpense(300, cat, acc);

      // Delete two back-to-back without awaiting between
      await service.deleteTransaction(txn1.id);
      await service.deleteTransaction(txn3.id);

      final remaining = await service.getAll();
      expect(remaining.length, 1);
      expect(remaining.first.id, txn2.id);
      expect(remaining.first.amount, 200);
    });

    test('delete all transactions leaves empty DB', () async {
      final cat = await seedCategory('Food');
      final acc = await seedAccount('Cash');

      final txns = <Transaction>[];
      for (int i = 0; i < 5; i++) {
        txns.add(await addExpense(100.0 * (i + 1), cat, acc));
      }

      for (final txn in txns) {
        await service.deleteTransaction(txn.id);
      }

      expect(await service.getAll(), isEmpty);
    });

    test('delete non-existent ID does not affect existing data', () async {
      final cat = await seedCategory('Food');
      final acc = await seedAccount('Cash');

      await addExpense(500, cat, acc);

      await service.deleteTransaction(99999);

      expect((await service.getAll()).length, 1);
    });
  });

  group('Delete with recurring transaction rollback', () {
    test('deleting recurring-linked txn reverts due date', () async {
      final cat = await seedCategory('Netflix');
      final acc = await seedAccount('HDFC');

      final recurring = await seedRecurring(
        amount: 649,
        cat: cat,
        acc: acc,
        nextDueDate: DateTime(2025, 7, 15),
      );

      // Create a transaction linked to this recurring
      final txn = Transaction.create(
        date: DateTime(2025, 6, 15),
        amount: 649,
        isExpense: true,
      )
        ..category.value = cat
        ..account.value = acc
        ..recurringTransactionSource.value = recurring;

      await isar.writeTxn(() async {
        await isar.transactions.put(txn);
        await txn.category.save();
        await txn.account.save();
        await txn.recurringTransactionSource.save();
      });

      // Delete the transaction — should revert recurring due date
      await service.deleteTransaction(txn.id);

      final updatedRecurring =
          await isar.recurringTransactions.get(recurring.id);
      expect(updatedRecurring, isNotNull);
      // Monthly rollback: July 15 → June 15
      expect(updatedRecurring!.nextDueDate, DateTime(2025, 6, 15));
      expect(updatedRecurring.isActive, true);
    });

    test('back-to-back delete of two recurring-linked txns reverts both', () async {
      final cat = await seedCategory('Netflix');
      final acc = await seedAccount('HDFC');

      // Two different recurring bills
      final recurring1 = await seedRecurring(
        amount: 649,
        cat: cat,
        acc: acc,
        nextDueDate: DateTime(2025, 7, 15),
      );
      final recurring2 = await seedRecurring(
        amount: 199,
        cat: cat,
        acc: acc,
        nextDueDate: DateTime(2025, 8, 1),
      );

      // Create linked transactions
      final txn1 = Transaction.create(
        date: DateTime(2025, 6, 15),
        amount: 649,
        isExpense: true,
      )
        ..category.value = cat
        ..account.value = acc
        ..recurringTransactionSource.value = recurring1;

      final txn2 = Transaction.create(
        date: DateTime(2025, 7, 1),
        amount: 199,
        isExpense: true,
      )
        ..category.value = cat
        ..account.value = acc
        ..recurringTransactionSource.value = recurring2;

      await isar.writeTxn(() async {
        await isar.transactions.put(txn1);
        await txn1.category.save();
        await txn1.account.save();
        await txn1.recurringTransactionSource.save();
        await isar.transactions.put(txn2);
        await txn2.category.save();
        await txn2.account.save();
        await txn2.recurringTransactionSource.save();
      });

      // Delete both back-to-back
      await service.deleteTransaction(txn1.id);
      await service.deleteTransaction(txn2.id);

      // Both transactions gone
      expect(await service.getAll(), isEmpty);

      // Both recurring due dates reverted
      final r1 = await isar.recurringTransactions.get(recurring1.id);
      final r2 = await isar.recurringTransactions.get(recurring2.id);
      expect(r1!.nextDueDate, DateTime(2025, 6, 15));
      expect(r2!.nextDueDate, DateTime(2025, 7, 1));
    });

    test('rollback preserves month-end clamping', () async {
      final cat = await seedCategory('Rent');
      final acc = await seedAccount('SBI');

      final recurring = await seedRecurring(
        amount: 15000,
        cat: cat,
        acc: acc,
        nextDueDate: DateTime(2025, 3, 31),
        frequency: Frequency.monthly,
      );

      final txn = Transaction.create(
        date: DateTime(2025, 2, 28),
        amount: 15000,
        isExpense: true,
      )
        ..category.value = cat
        ..account.value = acc
        ..recurringTransactionSource.value = recurring;

      await isar.writeTxn(() async {
        await isar.transactions.put(txn);
        await txn.category.save();
        await txn.account.save();
        await txn.recurringTransactionSource.save();
      });

      await service.deleteTransaction(txn.id);

      final updated = await isar.recurringTransactions.get(recurring.id);
      // Mar 31 - 1 month = Feb 28 (clamped)
      expect(updated!.nextDueDate, DateTime(2025, 2, 28));
    });
  });

  group('Save + update data consistency', () {
    test('update (same ID) overwrites existing transaction', () async {
      final cat = await seedCategory('Food');
      final acc = await seedAccount('Cash');

      final txn = await addExpense(500, cat, acc, description: 'Lunch');

      // Update by reusing the same ID
      final updated = Transaction.create(
        date: txn.date,
        amount: 750,
        isExpense: true,
        description: 'Dinner',
      )
        ..id = txn.id
        ..category.value = cat
        ..account.value = acc;

      await service.addTransaction(updated);

      final all = await service.getAll();
      expect(all.length, 1);
      expect(all.first.amount, 750);
      expect(all.first.description, 'Dinner');
    });

    test('update preserves category and account links', () async {
      final food = await seedCategory('Food');
      final transport = await seedCategory('Transport');
      final acc = await seedAccount('Cash');

      final txn = await addExpense(500, food, acc);

      // Update category
      final updated = Transaction.create(
        date: txn.date,
        amount: 500,
        isExpense: true,
      )
        ..id = txn.id
        ..category.value = transport
        ..account.value = acc;

      await service.addTransaction(updated);

      final all = await service.getAll();
      expect(all.length, 1);
      expect(all.first.category.value?.name, 'Transport');
      expect(all.first.account.value?.name, 'Cash');
    });

    test('rapid add-delete-add cycle maintains consistency', () async {
      final cat = await seedCategory('Food');
      final acc = await seedAccount('Cash');

      final txn1 = await addExpense(100, cat, acc);
      await service.deleteTransaction(txn1.id);
      final txn2 = await addExpense(200, cat, acc);

      final all = await service.getAll();
      expect(all.length, 1);
      expect(all.first.id, txn2.id);
      expect(all.first.amount, 200);
    });

    test('add multiple then delete middle preserves order', () async {
      final cat = await seedCategory('Food');
      final acc = await seedAccount('Cash');

      final t1 = await addExpense(100, cat, acc, date: DateTime(2025, 1, 1));
      final t2 = await addExpense(200, cat, acc, date: DateTime(2025, 2, 1));
      final t3 = await addExpense(300, cat, acc, date: DateTime(2025, 3, 1));

      await service.deleteTransaction(t2.id);

      final all = await service.getAll();
      expect(all.length, 2);
      // Sorted desc: Mar first, then Jan
      expect(all[0].amount, 300);
      expect(all[1].amount, 100);
    });
  });

  group('Transfer delete consistency', () {
    test('deleting one side of transfer leaves the other intact', () async {
      final acc1 = await seedAccount('HDFC');
      final acc2 = await seedAccount('SBI');

      await service.transfer(
        from: acc1,
        to: acc2,
        amount: 5000,
        date: DateTime.now(),
      );

      final allRaw = await isar.transactions.where().findAll();
      expect(allRaw.length, 2);

      final debit = allRaw.firstWhere((t) => t.isExpense);
      await service.deleteTransaction(debit.id);

      // Only debit deleted, credit remains
      final remaining = await isar.transactions.where().findAll();
      expect(remaining.length, 1);
      expect(remaining.first.isExpense, false);
    });
  });

  group('Date range queries after mutations', () {
    test('getByDateRange reflects deletions immediately', () async {
      final cat = await seedCategory('Food');
      final acc = await seedAccount('Cash');

      await addExpense(100, cat, acc, date: DateTime(2025, 6, 10));
      final toDelete =
          await addExpense(200, cat, acc, date: DateTime(2025, 6, 15));
      await addExpense(300, cat, acc, date: DateTime(2025, 6, 20));

      await service.deleteTransaction(toDelete.id);

      final june = await service.getByDateRange(
        DateTime(2025, 6, 1),
        DateTime(2025, 6, 30, 23, 59, 59),
      );
      expect(june.length, 2);
      expect(june.any((t) => t.amount == 200), false);
    });

    test('getByTypeAndDateRange reflects updates immediately', () async {
      final cat = await seedCategory('Food');
      final acc = await seedAccount('Cash');

      final txn =
          await addExpense(500, cat, acc, date: DateTime(2025, 6, 15));

      // Update to income
      final updated = Transaction.create(
        date: DateTime(2025, 6, 15),
        amount: 500,
        isExpense: false,
      )
        ..id = txn.id
        ..category.value = cat
        ..account.value = acc;
      await service.addTransaction(updated);

      final expenses = await service.getByTypeAndDateRange(
        isExpense: true,
        start: DateTime(2025, 6, 1),
        end: DateTime(2025, 6, 30, 23, 59, 59),
      );
      expect(expenses, isEmpty);

      final income = await service.getByTypeAndDateRange(
        isExpense: false,
        start: DateTime(2025, 6, 1),
        end: DateTime(2025, 6, 30, 23, 59, 59),
      );
      expect(income.length, 1);
    });
  });

  group('Category/tag query after mutations', () {
    test('getByCategoryAndType reflects deletion', () async {
      final food = await seedCategory('Food');
      final acc = await seedAccount('Cash');

      final t1 = await addExpense(100, food, acc);
      await addExpense(200, food, acc);

      await service.deleteTransaction(t1.id);

      final result = await service.getByCategoryAndType(
        categoryId: food.id,
        type: 'expense',
      );
      expect(result.length, 1);
      expect(result.first.amount, 200);
    });

    test('getTransactionCountForCategory updates after delete', () async {
      final food = await seedCategory('Food');
      final acc = await seedAccount('Cash');

      final t1 = await addExpense(100, food, acc);
      await addExpense(200, food, acc);
      await addExpense(300, food, acc);

      expect(await service.getTransactionCountForCategory(food.id), 3);

      await service.deleteTransaction(t1.id);

      expect(await service.getTransactionCountForCategory(food.id), 2);
    });
  });
}

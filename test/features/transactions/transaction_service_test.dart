import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/exchange_rate.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/trip.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/features/transactions/data/transaction_service.dart';

late Isar isar;
late Directory tmpDir;
late TransactionService service;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('txn_service_test_');
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
      AppLog(getLogger(), 'TxnServiceTest'),
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

  Future<Account> seedAccount(String name, {String? currency}) async {
    final acc = Account()
      ..name = name
      ..accountType = AccountType.bank
      ..currencyCode = currency
      ..initialBalance = 0
      ..isActive = true;
    await isar.writeTxn(() => isar.accounts.put(acc));
    return acc;
  }

  Future<Tag> seedTag(String name) async {
    final tag = Tag()..name = name;
    await isar.writeTxn(() => isar.tags.put(tag));
    return tag;
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

  Future<Transaction> addIncome(
    double amount,
    Category cat,
    Account acc, {
    DateTime? date,
  }) async {
    final txn = Transaction.create(
      date: date ?? DateTime.now(),
      amount: amount,
      isExpense: false,
    )
      ..category.value = cat
      ..account.value = acc;
    await service.addTransaction(txn);
    return txn;
  }

  // ── Tests ──

  group('addTransaction', () {
    test('saves expense with category and account links', () async {
      final cat = await seedCategory('Food');
      final acc = await seedAccount('HDFC');

      await addExpense(500, cat, acc);

      final all = await service.getAll();
      expect(all.length, 1);
      expect(all.first.amount, 500);
      expect(all.first.isExpense, true);
      expect(all.first.category.value?.name, 'Food');
      expect(all.first.account.value?.name, 'HDFC');
    });

    test('saves income transaction', () async {
      final cat = await seedCategory('Salary', isExpense: false);
      final acc = await seedAccount('SBI');

      await addIncome(50000, cat, acc);

      final all = await service.getAll();
      expect(all.length, 1);
      expect(all.first.isExpense, false);
      expect(all.first.amount, 50000);
    });

    test('saves transaction with description', () async {
      final cat = await seedCategory('Food');
      final acc = await seedAccount('Cash');

      await addExpense(200, cat, acc, description: 'Lunch at office');

      final all = await service.getAll();
      expect(all.first.description, 'Lunch at office');
    });

    test('saves transaction with tags', () async {
      final cat = await seedCategory('Food');
      final acc = await seedAccount('Cash');
      final tag = await seedTag('work-lunch');

      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 300,
        isExpense: true,
      )
        ..category.value = cat
        ..account.value = acc
        ..tags.add(tag);
      await service.addTransaction(txn);

      final all = await service.getAll();
      expect(all.length, 1);
    });

    test('assigns auto-increment ID', () async {
      final cat = await seedCategory('Food');
      final acc = await seedAccount('Cash');

      final txn = await addExpense(100, cat, acc);
      expect(txn.id, greaterThan(0));
    });
  });

  group('getAll', () {
    test('returns empty list when no transactions', () async {
      final all = await service.getAll();
      expect(all, isEmpty);
    });

    test('returns transactions sorted by date descending', () async {
      final cat = await seedCategory('Food');
      final acc = await seedAccount('Cash');

      await addExpense(100, cat, acc, date: DateTime(2025, 1, 1));
      await addExpense(200, cat, acc, date: DateTime(2025, 3, 1));
      await addExpense(300, cat, acc, date: DateTime(2025, 2, 1));

      final all = await service.getAll();
      expect(all.length, 3);
      expect(all[0].amount, 200); // Mar (newest)
      expect(all[1].amount, 300); // Feb
      expect(all[2].amount, 100); // Jan (oldest)
    });

    test('respects limit parameter', () async {
      final cat = await seedCategory('Food');
      final acc = await seedAccount('Cash');

      for (int i = 0; i < 10; i++) {
        await addExpense(100.0 + i, cat, acc);
      }

      final limited = await service.getAll(limit: 3);
      expect(limited.length, 3);
    });

    test('filters transfer debit side (shows only credit)', () async {
      final acc1 = await seedAccount('HDFC');
      final acc2 = await seedAccount('SBI');

      await service.transfer(
        from: acc1,
        to: acc2,
        amount: 1000,
        date: DateTime.now(),
      );

      final all = await service.getAll();
      // Transfer creates 2 txns (debit + credit), getAll shows only credit
      expect(all.length, 1);
      expect(all.first.isExpense, false);
    });

    test('loads category and account links', () async {
      final cat = await seedCategory('Transport');
      final acc = await seedAccount('Paytm');

      await addExpense(150, cat, acc);

      final all = await service.getAll();
      expect(all.first.category.value, isNotNull);
      expect(all.first.category.value!.name, 'Transport');
      expect(all.first.account.value, isNotNull);
      expect(all.first.account.value!.name, 'Paytm');
    });
  });

  group('getByType', () {
    test('returns only expenses', () async {
      final expCat = await seedCategory('Food');
      final incCat = await seedCategory('Salary', isExpense: false);
      final acc = await seedAccount('Cash');

      await addExpense(500, expCat, acc);
      await addIncome(50000, incCat, acc);

      final expenses = await service.getByType(isExpense: true);
      expect(expenses.length, 1);
      expect(expenses.first.amount, 500);
    });

    test('returns only income', () async {
      final expCat = await seedCategory('Food');
      final incCat = await seedCategory('Salary', isExpense: false);
      final acc = await seedAccount('Cash');

      await addExpense(500, expCat, acc);
      await addIncome(50000, incCat, acc);

      final income = await service.getByType(isExpense: false);
      expect(income.length, 1);
      expect(income.first.amount, 50000);
    });

    test('excludes transfers', () async {
      final acc1 = await seedAccount('HDFC');
      final acc2 = await seedAccount('SBI');
      final cat = await seedCategory('Food');

      await addExpense(500, cat, acc1);
      await service.transfer(
        from: acc1,
        to: acc2,
        amount: 1000,
        date: DateTime.now(),
      );

      final expenses = await service.getByType(isExpense: true);
      expect(expenses.length, 1); // only the food expense, not transfer debit
    });
  });

  group('getByDateRange', () {
    test('returns transactions within range', () async {
      final cat = await seedCategory('Food');
      final acc = await seedAccount('Cash');

      await addExpense(100, cat, acc, date: DateTime(2025, 1, 15));
      await addExpense(200, cat, acc, date: DateTime(2025, 2, 15));
      await addExpense(300, cat, acc, date: DateTime(2025, 3, 15));

      final feb = await service.getByDateRange(
        DateTime(2025, 2, 1),
        DateTime(2025, 2, 28, 23, 59, 59),
      );
      expect(feb.length, 1);
      expect(feb.first.amount, 200);
    });

    test('returns empty for range with no transactions', () async {
      final cat = await seedCategory('Food');
      final acc = await seedAccount('Cash');

      await addExpense(100, cat, acc, date: DateTime(2025, 1, 15));

      final empty = await service.getByDateRange(
        DateTime(2025, 6, 1),
        DateTime(2025, 6, 30),
      );
      expect(empty, isEmpty);
    });
  });

  group('deleteTransaction', () {
    test('removes transaction from DB', () async {
      final cat = await seedCategory('Food');
      final acc = await seedAccount('Cash');

      final txn = await addExpense(500, cat, acc);

      await service.deleteTransaction(txn.id);

      final all = await service.getAll();
      expect(all, isEmpty);
    });

    test('no-op for non-existent ID', () async {
      await service.deleteTransaction(99999);
      // Should not throw
    });
  });

  group('transfer', () {
    test('creates debit and credit transactions', () async {
      final acc1 = await seedAccount('HDFC');
      final acc2 = await seedAccount('SBI');

      await service.transfer(
        from: acc1,
        to: acc2,
        amount: 5000,
        date: DateTime(2025, 6, 1),
      );

      final allRaw = await isar.transactions.where().findAll();
      expect(allRaw.length, 2);

      final debit = allRaw.firstWhere((t) => t.isExpense);
      final credit = allRaw.firstWhere((t) => !t.isExpense);

      expect(debit.amount, 5000);
      expect(debit.isTransfer, true);
      expect(credit.amount, 5000);
      expect(credit.isTransfer, true);
    });

    test('links debit and credit via related', () async {
      final acc1 = await seedAccount('HDFC');
      final acc2 = await seedAccount('SBI');

      await service.transfer(
        from: acc1,
        to: acc2,
        amount: 1000,
        date: DateTime.now(),
      );

      final allRaw = await isar.transactions.where().findAll();
      final debit = allRaw.firstWhere((t) => t.isExpense);
      final credit = allRaw.firstWhere((t) => !t.isExpense);

      await debit.related.load();
      await credit.related.load();

      expect(debit.related.value?.id, credit.id);
      expect(credit.related.value?.id, debit.id);
    });

    test('supports different credit amount (cross-currency)', () async {
      final acc1 = await seedAccount('HDFC', currency: 'INR');
      final acc2 = await seedAccount('US Bank', currency: 'USD');

      await service.transfer(
        from: acc1,
        to: acc2,
        amount: 83000,
        creditAmount: 1000,
        date: DateTime.now(),
      );

      final allRaw = await isar.transactions.where().findAll();
      final debit = allRaw.firstWhere((t) => t.isExpense);
      final credit = allRaw.firstWhere((t) => !t.isExpense);

      expect(debit.amount, 83000);
      expect(credit.amount, 1000);
    });

    test('saves note on both sides', () async {
      final acc1 = await seedAccount('HDFC');
      final acc2 = await seedAccount('SBI');

      await service.transfer(
        from: acc1,
        to: acc2,
        amount: 500,
        date: DateTime.now(),
        note: 'Rent transfer',
      );

      final allRaw = await isar.transactions.where().findAll();
      for (final t in allRaw) {
        expect(t.description, 'Rent transfer');
      }
    });
  });

  group('getByTypeAndDateRange', () {
    test('filters by type and date', () async {
      final expCat = await seedCategory('Food');
      final incCat = await seedCategory('Salary', isExpense: false);
      final acc = await seedAccount('Cash');

      await addExpense(500, expCat, acc, date: DateTime(2025, 3, 10));
      await addIncome(50000, incCat, acc, date: DateTime(2025, 3, 15));
      await addExpense(200, expCat, acc, date: DateTime(2025, 4, 10));

      final marchExpenses = await service.getByTypeAndDateRange(
        isExpense: true,
        start: DateTime(2025, 3, 1),
        end: DateTime(2025, 3, 31, 23, 59, 59),
      );
      expect(marchExpenses.length, 1);
      expect(marchExpenses.first.amount, 500);
    });
  });

  group('getByCategoryAndType', () {
    test('filters by category', () async {
      final food = await seedCategory('Food');
      final transport = await seedCategory('Transport');
      final acc = await seedAccount('Cash');

      await addExpense(500, food, acc);
      await addExpense(200, transport, acc);
      await addExpense(300, food, acc);

      final foodExpenses = await service.getByCategoryAndType(
        categoryId: food.id,
        type: 'expense',
      );
      expect(foodExpenses.length, 2);
    });

    test('returns empty for non-existent category', () async {
      final result = await service.getByCategoryAndType(
        categoryId: 99999,
        type: 'expense',
      );
      expect(result, isEmpty);
    });
  });

  group('Transaction model', () {
    test('baseAmount returns convertedAmount when available', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 1000,
        isExpense: true,
        convertedAmount: 12.5,
      );
      expect(txn.baseAmount, 12.5);
    });

    test('baseAmount falls back to amount', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 1000,
        isExpense: true,
      );
      expect(txn.baseAmount, 1000);
    });

    test('effectiveAmount is positive for expense', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 500,
        isExpense: true,
      );
      expect(txn.effectiveAmount, 500);
    });
  });

  group('getTransactionCountForCategory', () {
    test('returns correct count', () async {
      final food = await seedCategory('Food');
      final acc = await seedAccount('Cash');

      await addExpense(100, food, acc);
      await addExpense(200, food, acc);
      await addExpense(300, food, acc);

      final count = await service.getTransactionCountForCategory(food.id);
      expect(count, 3);
    });

    test('returns 0 for unused category', () async {
      final cat = await seedCategory('Unused');
      final count = await service.getTransactionCountForCategory(cat.id);
      expect(count, 0);
    });
  });
}

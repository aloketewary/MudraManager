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
    tmpDir = Directory.systemTemp.createTempSync('merge_transfer_test_');
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
      AppLog(getLogger(), 'MergeTransferTest'),
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
      ..initialBalance = 10000
      ..isActive = true;
    await isar.writeTxn(() => isar.accounts.put(acc));
    return acc;
  }

  /// Validates whether two transactions can be merged as a transfer.
  /// Mirrors the validation logic in _mergeAsTransfer.
  ({bool valid, String? error}) canMergeAsTransfer(
    Transaction a,
    Transaction b,
  ) {
    // One expense, one income
    final expense = a.isExpense ? a : (b.isExpense ? b : null);
    final income = !a.isExpense ? a : (!b.isExpense ? b : null);
    if (expense == null || income == null) {
      return (valid: false, error: 'need one expense and one income');
    }

    // Neither is already a transfer
    if (a.isTransfer || b.isTransfer) {
      return (valid: false, error: 'already a transfer');
    }

    // Same amount (±1 tolerance)
    if ((expense.amount - income.amount).abs() > 1) {
      return (valid: false, error: 'amounts differ');
    }

    // Within 24 hours
    if (expense.date.difference(income.date).inHours.abs() > 24) {
      return (valid: false, error: 'more than 24h apart');
    }

    return (valid: true, error: null);
  }

  // ── Tests ──

  group('Merge-as-transfer validation', () {
    test('valid pair: same amount, one expense one income, within 24h', () {
      final expense = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 0),
        amount: 5000,
        isExpense: true,
      );
      final income = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 30),
        amount: 5000,
        isExpense: false,
      );

      final result = canMergeAsTransfer(expense, income);
      expect(result.valid, true);
    });

    test('valid: amounts within ₹1 tolerance', () {
      final expense = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 0),
        amount: 5000.50,
        isExpense: true,
      );
      final income = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 30),
        amount: 5000,
        isExpense: false,
      );

      final result = canMergeAsTransfer(expense, income);
      expect(result.valid, true);
    });

    test('invalid: both are expenses', () {
      final a = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 0),
        amount: 5000,
        isExpense: true,
      );
      final b = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 30),
        amount: 5000,
        isExpense: true,
      );

      final result = canMergeAsTransfer(a, b);
      expect(result.valid, false);
      expect(result.error, 'need one expense and one income');
    });

    test('invalid: both are income', () {
      final a = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 0),
        amount: 5000,
        isExpense: false,
      );
      final b = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 30),
        amount: 5000,
        isExpense: false,
      );

      final result = canMergeAsTransfer(a, b);
      expect(result.valid, false);
    });

    test('invalid: amounts differ by more than ₹1', () {
      final expense = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 0),
        amount: 5000,
        isExpense: true,
      );
      final income = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 30),
        amount: 5002,
        isExpense: false,
      );

      final result = canMergeAsTransfer(expense, income);
      expect(result.valid, false);
      expect(result.error, 'amounts differ');
    });

    test('invalid: more than 24 hours apart', () {
      final expense = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 0),
        amount: 5000,
        isExpense: true,
      );
      final income = Transaction.create(
        date: DateTime(2025, 6, 16, 11, 0), // 25 hours later
        amount: 5000,
        isExpense: false,
      );

      final result = canMergeAsTransfer(expense, income);
      expect(result.valid, false);
      expect(result.error, 'more than 24h apart');
    });

    test('valid: exactly 24 hours apart', () {
      final expense = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 0),
        amount: 5000,
        isExpense: true,
      );
      final income = Transaction.create(
        date: DateTime(2025, 6, 16, 10, 0), // exactly 24h
        amount: 5000,
        isExpense: false,
      );

      final result = canMergeAsTransfer(expense, income);
      expect(result.valid, true);
    });

    test('invalid: one is already a transfer', () {
      final expense = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 0),
        amount: 5000,
        isExpense: true,
        isTransfer: true,
      );
      final income = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 30),
        amount: 5000,
        isExpense: false,
      );

      final result = canMergeAsTransfer(expense, income);
      expect(result.valid, false);
      expect(result.error, 'already a transfer');
    });
  });

  group('Merge-as-transfer DB operation', () {
    test('deleting both originals + creating transfer leaves correct state',
        () async {
      final expCat = await seedCategory('Transfer Out');
      final incCat = await seedCategory('Transfer In', isExpense: false);
      final hdfc = await seedAccount('HDFC');
      final sbi = await seedAccount('SBI');

      // Simulate SMS-imported pair
      final expense = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 0),
        amount: 5000,
        isExpense: true,
      )
        ..category.value = expCat
        ..account.value = hdfc;
      await service.addTransaction(expense);

      final income = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 30),
        amount: 5000,
        isExpense: false,
      )
        ..category.value = incCat
        ..account.value = sbi;
      await service.addTransaction(income);

      expect((await service.getAll()).length, 2);

      // Simulate merge: create transfer then delete originals
      await service.transfer(
        from: hdfc,
        to: sbi,
        amount: 5000,
        date: DateTime(2025, 6, 15, 10, 0),
      );
      await service.deleteTransaction(expense.id);
      await service.deleteTransaction(income.id);

      // Should have exactly 2 txns (debit + credit of transfer)
      final allRaw = await isar.transactions.where().findAll();
      expect(allRaw.length, 2);
      expect(allRaw.every((t) => t.isTransfer), true);

      // getAll filters to show only credit side
      final visible = await service.getAll();
      expect(visible.length, 1);
      expect(visible.first.isTransfer, true);
      expect(visible.first.isExpense, false);
      expect(visible.first.amount, 5000);
    });

    test('merge preserves other unrelated transactions', () async {
      final cat = await seedCategory('Food');
      final incCat = await seedCategory('Salary', isExpense: false);
      final hdfc = await seedAccount('HDFC');
      final sbi = await seedAccount('SBI');

      // Unrelated transaction
      final food = Transaction.create(
        date: DateTime(2025, 6, 14),
        amount: 200,
        isExpense: true,
      )
        ..category.value = cat
        ..account.value = hdfc;
      await service.addTransaction(food);

      // SMS pair to merge
      final expense = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 0),
        amount: 5000,
        isExpense: true,
      )
        ..category.value = cat
        ..account.value = hdfc;
      await service.addTransaction(expense);

      final income = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 30),
        amount: 5000,
        isExpense: false,
      )
        ..category.value = incCat
        ..account.value = sbi;
      await service.addTransaction(income);

      expect((await service.getAll()).length, 3);

      // Merge
      await service.transfer(
        from: hdfc,
        to: sbi,
        amount: 5000,
        date: DateTime(2025, 6, 15, 10, 0),
      );
      await service.deleteTransaction(expense.id);
      await service.deleteTransaction(income.id);

      final visible = await service.getAll();
      // food expense + transfer credit = 2 visible
      expect(visible.length, 2);
      expect(visible.any((t) => t.amount == 200 && !t.isTransfer), true);
      expect(visible.any((t) => t.amount == 5000 && t.isTransfer), true);
    });
  });
}

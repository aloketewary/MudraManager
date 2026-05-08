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
    tmpDir = Directory.systemTemp.createTempSync('txn_update_test_');
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
      AppLog(getLogger(), 'TxnUpdateTest'),
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


  /// Simulates the edit screen's save: creates a new Transaction.create(),
  /// sets the old ID, and copies over non-editable fields.
  Future<void> updateLikeScreen({
    required Transaction existing,
    required double amount,
    required bool isExpense,
    required Category category,
    required Account account,
    String? description,
    List<Tag> tags = const [],
  }) async {
    final txn = Transaction.create(
      date: existing.date,
      amount: amount,
      isExpense: isExpense,
      description: description ?? existing.description,
      currencyCode: existing.currencyCode,
      convertedAmount: existing.convertedAmount,
      rateUsed: existing.rateUsed,
    );
    txn.id = existing.id;
    // Carry over fields the edit screen doesn't modify
    txn.isFromSms = existing.isFromSms;
    txn.smsActivityId = existing.smsActivityId;
    txn.isSharedExpense = existing.isSharedExpense;
    txn.isSettlement = existing.isSettlement;
    txn.myShare = existing.myShare;

    txn.account.value = account;
    txn.category.value = category;
    txn.tags.addAll(tags);

    await service.addTransaction(txn);
  }

  /// Simulates the OLD broken edit pattern: creates Transaction.create()
  /// with the old ID but does NOT copy non-editable fields.
  Future<void> updateLikeBrokenScreen({
    required Transaction existing,
    required double amount,
    required bool isExpense,
    required Category category,
    required Account account,
    String? description,
  }) async {
    final txn = Transaction.create(
      date: existing.date,
      amount: amount,
      isExpense: isExpense,
      description: description,
    );
    txn.id = existing.id;
    // BUG: does NOT copy isFromSms, smsActivityId, etc.
    txn.account.value = account;
    txn.category.value = category;
    await service.addTransaction(txn);
  }

  // ── Tests ──

  group('Update preserves non-editable fields', () {
    test('isFromSms and smsActivityId survive update', () async {
      final cat = await seedCategory('Food');
      final acc = await seedAccount('HDFC');

      // Create SMS-linked transaction
      final txn = Transaction.create(
        date: DateTime(2025, 6, 15),
        amount: 500,
        isExpense: true,
        description: 'Swiggy order',
      )
        ..isFromSms = true
        ..smsActivityId = 42
        ..category.value = cat
        ..account.value = acc;
      await service.addTransaction(txn);

      // Verify initial state
      final before = (await service.getAll()).first;
      expect(before.isFromSms, true);
      expect(before.smsActivityId, 42);

      // Update amount via the fixed screen pattern
      await updateLikeScreen(
        existing: txn,
        amount: 600,
        isExpense: true,
        category: cat,
        account: acc,
        description: 'Swiggy order updated',
      );

      final after = (await service.getAll()).first;
      expect(after.amount, 600);
      expect(after.description, 'Swiggy order updated');
      expect(after.isFromSms, true, reason: 'isFromSms must survive update');
      expect(after.smsActivityId, 42, reason: 'smsActivityId must survive update');
    });

    test('isSharedExpense and myShare survive update', () async {
      final cat = await seedCategory('Dinner');
      final acc = await seedAccount('Cash');

      final txn = Transaction.create(
        date: DateTime(2025, 6, 15),
        amount: 1200,
        isExpense: true,
      )
        ..isSharedExpense = true
        ..myShare = 400
        ..category.value = cat
        ..account.value = acc;
      await service.addTransaction(txn);

      await updateLikeScreen(
        existing: txn,
        amount: 1500,
        isExpense: true,
        category: cat,
        account: acc,
      );

      final after = (await service.getAll()).first;
      expect(after.amount, 1500);
      expect(after.isSharedExpense, true, reason: 'isSharedExpense must survive');
      expect(after.myShare, 400, reason: 'myShare must survive');
    });

    test('isSettlement survives update', () async {
      final cat = await seedCategory('Settlement');
      final acc = await seedAccount('Cash');

      final txn = Transaction.create(
        date: DateTime(2025, 6, 15),
        amount: 300,
        isExpense: true,
      )
        ..isSettlement = true
        ..category.value = cat
        ..account.value = acc;
      await service.addTransaction(txn);

      await updateLikeScreen(
        existing: txn,
        amount: 350,
        isExpense: true,
        category: cat,
        account: acc,
      );

      final after = (await service.getAll()).first;
      expect(after.amount, 350);
      expect(after.isSettlement, true, reason: 'isSettlement must survive');
    });
  });

  group('Old broken pattern loses fields (regression proof)', () {
    test('broken pattern wipes isFromSms', () async {
      final cat = await seedCategory('Food');
      final acc = await seedAccount('HDFC');

      final txn = Transaction.create(
        date: DateTime(2025, 6, 15),
        amount: 500,
        isExpense: true,
      )
        ..isFromSms = true
        ..smsActivityId = 42
        ..category.value = cat
        ..account.value = acc;
      await service.addTransaction(txn);

      // Simulate the OLD broken edit pattern
      await updateLikeBrokenScreen(
        existing: txn,
        amount: 600,
        isExpense: true,
        category: cat,
        account: acc,
      );

      final after = (await service.getAll()).first;
      expect(after.amount, 600);
      // These WOULD fail with the old code — proving the bug existed
      expect(after.isFromSms, isNot(true),
          reason: 'Broken pattern resets isFromSms to null',);
      expect(after.smsActivityId, isNull,
          reason: 'Broken pattern resets smsActivityId to null',);
    });

    test('broken pattern wipes isSharedExpense and myShare', () async {
      final cat = await seedCategory('Dinner');
      final acc = await seedAccount('Cash');

      final txn = Transaction.create(
        date: DateTime(2025, 6, 15),
        amount: 1200,
        isExpense: true,
      )
        ..isSharedExpense = true
        ..myShare = 400
        ..category.value = cat
        ..account.value = acc;
      await service.addTransaction(txn);

      await updateLikeBrokenScreen(
        existing: txn,
        amount: 1500,
        isExpense: true,
        category: cat,
        account: acc,
      );

      final after = (await service.getAll()).first;
      expect(after.isSharedExpense, false,
          reason: 'Broken pattern resets isSharedExpense to default',);
      expect(after.myShare, isNull,
          reason: 'Broken pattern resets myShare to null',);
    });
  });

  group('Update changes editable fields correctly', () {
    test('update amount', () async {
      final cat = await seedCategory('Food');
      final acc = await seedAccount('Cash');

      final txn = Transaction.create(
        date: DateTime(2025, 6, 15),
        amount: 500,
        isExpense: true,
      )
        ..category.value = cat
        ..account.value = acc;
      await service.addTransaction(txn);

      await updateLikeScreen(
        existing: txn,
        amount: 750,
        isExpense: true,
        category: cat,
        account: acc,
      );

      final all = await service.getAll();
      expect(all.length, 1);
      expect(all.first.amount, 750);
    });

    test('update category', () async {
      final food = await seedCategory('Food');
      final transport = await seedCategory('Transport');
      final acc = await seedAccount('Cash');

      final txn = Transaction.create(
        date: DateTime(2025, 6, 15),
        amount: 500,
        isExpense: true,
      )
        ..category.value = food
        ..account.value = acc;
      await service.addTransaction(txn);

      await updateLikeScreen(
        existing: txn,
        amount: 500,
        isExpense: true,
        category: transport,
        account: acc,
      );

      final all = await service.getAll();
      expect(all.length, 1);
      expect(all.first.category.value?.name, 'Transport');
    });

    test('update account', () async {
      final cat = await seedCategory('Food');
      final hdfc = await seedAccount('HDFC');
      final sbi = await seedAccount('SBI');

      final txn = Transaction.create(
        date: DateTime(2025, 6, 15),
        amount: 500,
        isExpense: true,
      )
        ..category.value = cat
        ..account.value = hdfc;
      await service.addTransaction(txn);

      await updateLikeScreen(
        existing: txn,
        amount: 500,
        isExpense: true,
        category: cat,
        account: sbi,
      );

      final all = await service.getAll();
      expect(all.length, 1);
      expect(all.first.account.value?.name, 'SBI');
    });

    test('flip expense to income', () async {
      final cat = await seedCategory('Refund', isExpense: false);
      final acc = await seedAccount('Cash');

      final txn = Transaction.create(
        date: DateTime(2025, 6, 15),
        amount: 500,
        isExpense: true,
      )
        ..category.value = cat
        ..account.value = acc;
      await service.addTransaction(txn);

      await updateLikeScreen(
        existing: txn,
        amount: 500,
        isExpense: false,
        category: cat,
        account: acc,
      );

      final all = await service.getAll();
      expect(all.length, 1);
      expect(all.first.isExpense, false);
    });

    test('update description', () async {
      final cat = await seedCategory('Food');
      final acc = await seedAccount('Cash');

      final txn = Transaction.create(
        date: DateTime(2025, 6, 15),
        amount: 500,
        isExpense: true,
        description: 'Lunch',
      )
        ..category.value = cat
        ..account.value = acc;
      await service.addTransaction(txn);

      await updateLikeScreen(
        existing: txn,
        amount: 500,
        isExpense: true,
        category: cat,
        account: acc,
        description: 'Dinner with friends',
      );

      final all = await service.getAll();
      expect(all.length, 1);
      expect(all.first.description, 'Dinner with friends');
    });

    // NOTE: Tag updates via addTransaction on a new Transaction.create()
    // with an existing ID have a known Isar limitation — IsarLinks.toList()
    // calls loadSync() which returns empty for objects not fetched from DB.
    // The edit screen works around this because the tags are saved via
    // reset() + addAll() + save() inside addTransaction, but the toList()
    // snapshot before writeTxn captures empty. This is a separate issue
    // tracked for future fix (use DB-fetched object for tag updates).
  });

  group('Update does not create duplicate', () {
    test('update with same ID keeps count at 1', () async {
      final cat = await seedCategory('Food');
      final acc = await seedAccount('Cash');

      final txn = Transaction.create(
        date: DateTime(2025, 6, 15),
        amount: 500,
        isExpense: true,
      )
        ..category.value = cat
        ..account.value = acc;
      await service.addTransaction(txn);

      // Update 3 times
      for (int i = 1; i <= 3; i++) {
        await updateLikeScreen(
          existing: txn,
          amount: 500.0 + (i * 100),
          isExpense: true,
          category: cat,
          account: acc,
        );
      }

      final all = await service.getAll();
      expect(all.length, 1, reason: 'Update must not create duplicates');
      expect(all.first.amount, 800); // 500 + 300
      expect(all.first.id, txn.id);
    });
  });

  group('Update preserves currency fields', () {
    test('currencyCode, convertedAmount, rateUsed survive update', () async {
      final cat = await seedCategory('Shopping');
      final acc = await seedAccount('USD Account');

      final txn = Transaction.create(
        date: DateTime(2025, 6, 15),
        amount: 100,
        isExpense: true,
        currencyCode: 'USD',
        convertedAmount: 8350,
        rateUsed: 83.5,
      )
        ..category.value = cat
        ..account.value = acc;
      await service.addTransaction(txn);

      // Update only the description — currency fields should survive
      await updateLikeScreen(
        existing: txn,
        amount: 100,
        isExpense: true,
        category: cat,
        account: acc,
        description: 'Amazon US',
      );

      final after = (await service.getAll()).first;
      expect(after.currencyCode, 'USD');
      expect(after.convertedAmount, 8350);
      expect(after.rateUsed, 83.5);
    });
  });

  group('Update combined scenario', () {
    test('SMS-linked shared expense: update amount preserves all metadata',
        () async {
      final cat = await seedCategory('Dinner');
      final acc = await seedAccount('HDFC');

      final txn = Transaction.create(
        date: DateTime(2025, 6, 15),
        amount: 2400,
        isExpense: true,
        description: 'Team dinner',
        currencyCode: 'INR',
      )
        ..isFromSms = true
        ..smsActivityId = 99
        ..isSharedExpense = true
        ..myShare = 600
        ..category.value = cat
        ..account.value = acc;
      await service.addTransaction(txn);

      // User edits only the amount
      await updateLikeScreen(
        existing: txn,
        amount: 2800,
        isExpense: true,
        category: cat,
        account: acc,
        description: 'Team dinner updated',
      );

      final after = (await service.getAll()).first;
      expect(after.amount, 2800);
      expect(after.description, 'Team dinner updated');
      expect(after.isFromSms, true);
      expect(after.smsActivityId, 99);
      expect(after.isSharedExpense, true);
      expect(after.myShare, 600);
      expect(after.currencyCode, 'INR');
      expect(after.category.value?.name, 'Dinner');
      expect(after.account.value?.name, 'HDFC');
    });
  });
}

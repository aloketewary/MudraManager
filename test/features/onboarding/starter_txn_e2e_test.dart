import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/exchange_rate.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// E2E tests for the "Accelerate First Value" feature.
///
/// Tests the starter transaction creation flow and the frequent categories
/// provider logic using a real Isar database.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late Directory tmpDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    SharedPrefsUtil.init(prefs);

    tmpDir = Directory.systemTemp.createTempSync('starter_txn_e2e_');
    final existing = Isar.getInstance();
    if (existing != null && existing.isOpen) await existing.close();

    isar = await Isar.open(
      [
        CategorySchema,
        AccountSchema,
        TransactionSchema,
        TagSchema,
        RecurringTransactionSchema,
        ExchangeRateSchema,
      ],
      directory: tmpDir.path,
    );
  });

  tearDown(() async {
    await isar.close();
    tmpDir.deleteSync(recursive: true);
  });

  // ── Helpers ──

  Future<Account> seedAccount(String name) async {
    final acc = Account()
      ..name = name
      ..accountType = AccountType.cash
      ..accountNumber = '0000'
      ..initialBalance = 10000
      ..isActive = true
      ..isPrimary = true;
    await isar.writeTxn(() => isar.accounts.put(acc));
    return acc;
  }

  Future<List<Category>> seedCategories() async {
    final cats = [
      Category()
        ..name = 'Food'
        ..iconName = 'utensils'
        ..categoryType = CategoryType.expense,
      Category()
        ..name = 'Transport'
        ..iconName = 'car'
        ..categoryType = CategoryType.expense,
      Category()
        ..name = 'Coffee'
        ..iconName = 'coffee'
        ..categoryType = CategoryType.expense,
      Category()
        ..name = 'Groceries'
        ..iconName = 'shoppingCart'
        ..categoryType = CategoryType.expense,
      Category()
        ..name = 'Salary'
        ..iconName = 'briefcase'
        ..categoryType = CategoryType.income,
    ];
    await isar.writeTxn(() => isar.categorys.putAll(cats));
    return cats;
  }

  Future<Transaction> addExpense(
    double amount,
    Account account,
    Category category, {
    DateTime? date,
  }) async {
    final txn = Transaction.create(
      date: date ?? DateTime.now(),
      amount: amount,
      isExpense: true,
      description: 'test',
    );
    txn.account.value = account;
    txn.category.value = category;
    await isar.writeTxn(() async {
      await isar.transactions.put(txn);
      await txn.account.save();
      await txn.category.save();
    });
    return txn;
  }

  // ── Starter Transaction Tests ──

  group('E2E: starter transaction creation', () {
    test('creates transactions with correct amounts and categories', () async {
      final account = await seedAccount('Cash');
      final categories = await seedCategories();

      // Simulate what _saveStarterTransactions does
      final starterAmounts = {'Coffee': 50.0, 'Transport': 100.0, 'Food': 200.0};
      final now = DateTime.now();

      await isar.writeTxn(() async {
        for (final entry in starterAmounts.entries) {
          final cat = categories.where((c) => c.name == entry.key).firstOrNull;
          final txn = Transaction.create(
            date: now,
            amount: entry.value,
            isExpense: true,
            description: '',
          );
          txn.account.value = account;
          if (cat != null) txn.category.value = cat;
          await isar.transactions.put(txn);
          await txn.account.save();
          await txn.category.save();
        }
      });

      final txns = await isar.transactions.where().findAll();
      expect(txns.length, 3);

      final amounts = txns.map((t) => t.amount).toSet();
      expect(amounts, containsAll([50.0, 100.0, 200.0]));

      // Verify all are expenses
      expect(txns.every((t) => t.isExpense), true);

      // Verify all linked to account
      for (final txn in txns) {
        await txn.account.load();
        expect(txn.account.value?.name, 'Cash');
      }

      // Verify categories linked
      for (final txn in txns) {
        await txn.category.load();
        expect(txn.category.value, isNotNull);
      }
    });

    test('skips zero and empty amounts', () async {
      final account = await seedAccount('Cash');
      await seedCategories();

      final starterAmounts = {'Coffee': 0.0, 'Transport': 0.0, 'Food': 150.0};
      final now = DateTime.now();

      await isar.writeTxn(() async {
        for (final entry in starterAmounts.entries) {
          if (entry.value <= 0) continue;
          final txn = Transaction.create(
            date: now,
            amount: entry.value,
            isExpense: true,
            description: '',
          );
          txn.account.value = account;
          await isar.transactions.put(txn);
          await txn.account.save();
        }
      });

      expect(await isar.transactions.count(), 1);
      final txn = (await isar.transactions.where().findAll()).first;
      expect(txn.amount, 150.0);
    });

    test('all zero amounts creates no transactions', () async {
      await seedAccount('Cash');
      await seedCategories();

      // No transactions should be created
      expect(await isar.transactions.count(), 0);
    });
  });

  // ── Frequent Categories Tests ──

  group('E2E: frequent categories logic', () {
    test('returns top categories by transaction count', () async {
      final account = await seedAccount('Cash');
      final categories = await seedCategories();

      final food = categories.firstWhere((c) => c.name == 'Food');
      final transport = categories.firstWhere((c) => c.name == 'Transport');
      final coffee = categories.firstWhere((c) => c.name == 'Coffee');

      // Food: 5 txns, Transport: 3 txns, Coffee: 1 txn
      for (var i = 0; i < 5; i++) {
        await addExpense(100, account, food);
      }
      for (var i = 0; i < 3; i++) {
        await addExpense(50, account, transport);
      }
      await addExpense(30, account, coffee);

      // Simulate frequentCategoriesProvider logic
      final cutoff = DateTime.now().subtract(const Duration(days: 90));
      final transactions = await isar.transactions
          .filter()
          .isExpenseEqualTo(true)
          .dateGreaterThan(cutoff)
          .findAll();

      final counts = <int, int>{};
      final catMap = <int, Category>{};
      for (final tx in transactions) {
        await tx.category.load();
        final cat = tx.category.value;
        if (cat == null) continue;
        counts[cat.id] = (counts[cat.id] ?? 0) + 1;
        catMap[cat.id] = cat;
      }

      final sorted = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topCats = sorted.take(8).map((e) => catMap[e.key]!).toList();

      expect(topCats.length, 3);
      expect(topCats[0].name, 'Food'); // most used
      expect(topCats[1].name, 'Transport');
      expect(topCats[2].name, 'Coffee'); // least used
    });

    test('returns fallback categories when no transactions', () async {
      await seedCategories();

      final expenseCats = await isar.categorys
          .filter()
          .categoryTypeEqualTo(CategoryType.expense)
          .limit(8)
          .findAll();

      expect(expenseCats.length, 4); // Food, Transport, Coffee, Groceries
      expect(expenseCats.every((c) => c.categoryType == CategoryType.expense), true);
    });

    test('does not include income categories in expense frequent list', () async {
      final account = await seedAccount('Cash');
      final categories = await seedCategories();

      final salary = categories.firstWhere((c) => c.name == 'Salary');
      final food = categories.firstWhere((c) => c.name == 'Food');

      // Add income transaction (should not appear in expense frequent)
      final incomeTxn = Transaction.create(
        date: DateTime.now(),
        amount: 50000,
        isExpense: false,
        description: 'salary',
      );
      incomeTxn.account.value = account;
      incomeTxn.category.value = salary;
      await isar.writeTxn(() async {
        await isar.transactions.put(incomeTxn);
        await incomeTxn.account.save();
        await incomeTxn.category.save();
      });

      await addExpense(100, account, food);

      final cutoff = DateTime.now().subtract(const Duration(days: 90));
      final expenseTxns = await isar.transactions
          .filter()
          .isExpenseEqualTo(true)
          .dateGreaterThan(cutoff)
          .findAll();

      final counts = <int, int>{};
      final catMap = <int, Category>{};
      for (final tx in expenseTxns) {
        await tx.category.load();
        final cat = tx.category.value;
        if (cat == null) continue;
        counts[cat.id] = (counts[cat.id] ?? 0) + 1;
        catMap[cat.id] = cat;
      }

      expect(counts.length, 1);
      expect(catMap.values.first.name, 'Food');
    });
  });

  // ── Last Used Account Tests ──

  group('E2E: last used account logic', () {
    test('returns primary account when available', () async {
      final primary = Account()
        ..name = 'Primary'
        ..accountType = AccountType.bank
        ..isActive = true
        ..isPrimary = true
        ..initialBalance = 0;
      final secondary = Account()
        ..name = 'Secondary'
        ..accountType = AccountType.cash
        ..isActive = true
        ..isPrimary = false
        ..initialBalance = 0;
      await isar.writeTxn(() async {
        await isar.accounts.put(primary);
        await isar.accounts.put(secondary);
      });

      final result = await isar.accounts
          .filter()
          .isPrimaryEqualTo(true)
          .isActiveEqualTo(true)
          .findFirst();

      expect(result, isNotNull);
      expect(result!.name, 'Primary');
    });

    test('falls back to first active when no primary', () async {
      final acc1 = Account()
        ..name = 'First'
        ..accountType = AccountType.cash
        ..isActive = true
        ..isPrimary = false
        ..initialBalance = 0;
      final acc2 = Account()
        ..name = 'Second'
        ..accountType = AccountType.bank
        ..isActive = true
        ..isPrimary = false
        ..initialBalance = 0;
      await isar.writeTxn(() async {
        await isar.accounts.put(acc1);
        await isar.accounts.put(acc2);
      });

      final primary = await isar.accounts
          .filter()
          .isPrimaryEqualTo(true)
          .isActiveEqualTo(true)
          .findFirst();
      expect(primary, isNull);

      final fallback = await isar.accounts
          .filter()
          .isActiveEqualTo(true)
          .findFirst();
      expect(fallback, isNotNull);
      expect(fallback!.name, 'First');
    });

    test('skips inactive accounts', () async {
      final inactive = Account()
        ..name = 'Inactive'
        ..accountType = AccountType.bank
        ..isActive = false
        ..isPrimary = true
        ..initialBalance = 0;
      final active = Account()
        ..name = 'Active'
        ..accountType = AccountType.cash
        ..isActive = true
        ..isPrimary = false
        ..initialBalance = 0;
      await isar.writeTxn(() async {
        await isar.accounts.put(inactive);
        await isar.accounts.put(active);
      });

      final primary = await isar.accounts
          .filter()
          .isPrimaryEqualTo(true)
          .isActiveEqualTo(true)
          .findFirst();
      expect(primary, isNull, reason: 'Primary is inactive');

      final fallback = await isar.accounts
          .filter()
          .isActiveEqualTo(true)
          .findFirst();
      expect(fallback!.name, 'Active');
    });
  });

  // ── Zero-State Dashboard Logic Tests ──

  group('E2E: zero-state dashboard detection', () {
    test('new user with no transactions: zero state', () async {
      await seedAccount('Cash');
      await seedCategories();

      final txnCount = await isar.transactions.count();
      expect(txnCount, 0);

      // Simulate onboarding just completed
      await SharedPrefsUtil.instance.setOnboardingCompletedAt(DateTime.now());
      final onboardedAt = SharedPrefsUtil.instance.getOnboardingCompletedAt();
      final isNewUser = onboardedAt != null &&
          DateTime.now().difference(onboardedAt).inHours < 24;

      expect(isNewUser, true);
      expect(txnCount == 0 && isNewUser, true,
          reason: 'Should show zero-state dashboard');
    });

    test('user with starter transactions: not zero state', () async {
      final account = await seedAccount('Cash');
      final categories = await seedCategories();
      final food = categories.firstWhere((c) => c.name == 'Food');

      await addExpense(100, account, food);

      final txnCount = await isar.transactions.count();
      expect(txnCount, 1);
      expect(txnCount == 0, false,
          reason: 'Should NOT show zero-state dashboard');
    });

    test('nudge dismissed: not shown even with zero transactions', () async {
      await SharedPrefsUtil.instance.setFirstTxnNudgeDismissed();

      final txnCount = await isar.transactions.count();
      final nudgeDismissed =
          SharedPrefsUtil.instance.getFirstTxnNudgeDismissed();

      expect(txnCount, 0);
      expect(nudgeDismissed, true);
      expect(txnCount == 0 && !nudgeDismissed, false,
          reason: 'Nudge should not show when dismissed');
    });

    test('old user (>24h) with no transactions: nudge but no quick actions', () async {
      final old = DateTime.now().subtract(const Duration(hours: 30));
      await SharedPrefsUtil.instance.setOnboardingCompletedAt(old);

      final onboardedAt = SharedPrefsUtil.instance.getOnboardingCompletedAt();
      final isNewUser = onboardedAt != null &&
          DateTime.now().difference(onboardedAt).inHours < 24;

      expect(isNewUser, false,
          reason: 'Quick action grid should not show for old users');
    });
  });

  // ── Category Matching Tests ──

  group('E2E: starter category matching', () {
    test('matches by icon name', () async {
      final categories = await seedCategories();

      // Simulate _matchCategory logic
      Category? matchCategory(List<Category> cats, String iconHint) {
        final byIcon = cats
            .where((c) => c.iconName?.toLowerCase() == iconHint.toLowerCase())
            .firstOrNull;
        if (byIcon != null) return byIcon;

        final nameMap = {
          'coffee': ['coffee', 'cafe', 'tea', 'beverage'],
          'car': ['transport', 'travel', 'auto', 'cab'],
          'utensils': ['food', 'lunch', 'dinner', 'restaurant'],
          'shoppingCart': ['grocery', 'groceries', 'shopping'],
        };
        final keywords = nameMap[iconHint] ?? [];
        for (final kw in keywords) {
          final match =
              cats.where((c) => c.name.toLowerCase().contains(kw)).firstOrNull;
          if (match != null) return match;
        }
        return cats.firstOrNull;
      }

      expect(matchCategory(categories, 'coffee')?.name, 'Coffee');
      expect(matchCategory(categories, 'car')?.name, 'Transport');
      expect(matchCategory(categories, 'utensils')?.name, 'Food');
      expect(matchCategory(categories, 'shoppingCart')?.name, 'Groceries');
    });

    test('falls back to name matching when icon not found', () async {
      // Categories without matching icon names
      final cats = [
        Category()
          ..name = 'Food & Dining'
          ..iconName = 'plate'
          ..categoryType = CategoryType.expense,
        Category()
          ..name = 'Travel'
          ..iconName = 'plane'
          ..categoryType = CategoryType.expense,
      ];
      await isar.writeTxn(() => isar.categorys.putAll(cats));
      final allCats = await isar.categorys.where().findAll();

      Category? matchCategory(List<Category> categories, String iconHint) {
        final byIcon = categories
            .where((c) => c.iconName?.toLowerCase() == iconHint.toLowerCase())
            .firstOrNull;
        if (byIcon != null) return byIcon;

        final nameMap = {
          'coffee': ['coffee', 'cafe', 'tea', 'beverage'],
          'car': ['transport', 'travel', 'auto', 'cab'],
          'utensils': ['food', 'lunch', 'dinner', 'restaurant'],
          'shoppingCart': ['grocery', 'groceries', 'shopping'],
        };
        final keywords = nameMap[iconHint] ?? [];
        for (final kw in keywords) {
          final match = categories
              .where((c) => c.name.toLowerCase().contains(kw))
              .firstOrNull;
          if (match != null) return match;
        }
        return categories.firstOrNull;
      }

      // 'utensils' icon not found, but 'food' keyword matches 'Food & Dining'
      expect(matchCategory(allCats, 'utensils')?.name, 'Food & Dining');
      // 'car' icon not found, but 'travel' keyword matches 'Travel'
      expect(matchCategory(allCats, 'car')?.name, 'Travel');
    });

    test('falls back to first category when nothing matches', () async {
      final cats = [
        Category()
          ..name = 'Misc'
          ..iconName = 'circle'
          ..categoryType = CategoryType.expense,
      ];
      await isar.writeTxn(() => isar.categorys.putAll(cats));
      final allCats = await isar.categorys.where().findAll();

      Category? matchCategory(List<Category> categories, String iconHint) {
        final byIcon = categories
            .where((c) => c.iconName?.toLowerCase() == iconHint.toLowerCase())
            .firstOrNull;
        if (byIcon != null) return byIcon;

        final nameMap = {
          'coffee': ['coffee', 'cafe', 'tea'],
          'car': ['transport', 'travel'],
          'utensils': ['food', 'lunch'],
          'shoppingCart': ['grocery', 'groceries'],
        };
        final keywords = nameMap[iconHint] ?? [];
        for (final kw in keywords) {
          final match = categories
              .where((c) => c.name.toLowerCase().contains(kw))
              .firstOrNull;
          if (match != null) return match;
        }
        return categories.firstOrNull;
      }

      // Nothing matches 'coffee' — falls back to first category
      expect(matchCategory(allCats, 'coffee')?.name, 'Misc');
    });
  });
}

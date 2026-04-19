import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/budget_category_allocation.dart';
import 'package:mudra_manager/core/db/models/budget_type.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/exchange_rate.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late Directory tmpDir;
  late BudgetService budgetService;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('budget_type_test_');
    final existing = Isar.getInstance();
    if (existing != null && existing.isOpen) await existing.close();

    isar = await Isar.open(
      [
        BudgetSchema,
        BudgetCategoryAllocationSchema,
        CategorySchema,
        TagSchema,
        TransactionSchema,
        AccountSchema,
        RecurringTransactionSchema,
        ExchangeRateSchema,
      ],
      directory: tmpDir.path,
    );

    final isarService = IsarService();
    budgetService = BudgetService(
      isarService,
      AppLog(getLogger(), 'BudgetServiceTest'),
      null,
    );
  });

  tearDown(() async {
    await isar.close();
    tmpDir.deleteSync(recursive: true);
  });

  // ── Helpers ──

  Future<Category> seedCategory(String name) async {
    final cat = Category()
      ..name = name
      ..iconName = 'circle'
      ..categoryType = CategoryType.expense;
    await isar.writeTxn(() => isar.categorys.put(cat));
    return cat;
  }

  Future<Tag> seedTag(String name) async {
    final tag = Tag()..name = name;
    await isar.writeTxn(() => isar.tags.put(tag));
    return tag;
  }

  Future<Transaction> seedExpense(
    double amount,
    DateTime date, {
    Category? category,
    List<Tag>? tags,
  }) async {
    final txn = Transaction.create(
      date: date,
      amount: amount,
      isExpense: true,
      description: 'test',
    );
    if (category != null) txn.category.value = category;
    await isar.writeTxn(() async {
      await isar.transactions.put(txn);
      if (category != null) await txn.category.save();
      if (tags != null) {
        txn.tags.addAll(tags);
        await txn.tags.save();
      }
    });
    return txn;
  }

  Future<Budget> seedBudget({
    required BudgetType type,
    required double amount,
    required DateTime start,
    required DateTime end,
    List<Category>? categories,
    List<Tag>? tags,
    BudgetRecurrence recurrence = BudgetRecurrence.none,
  }) async {
    final budget = Budget()
      ..name = 'Test Budget'
      ..amount = amount
      ..startDate = start
      ..endDate = end
      ..budgetType = type
      ..recurrence = recurrence;
    await isar.writeTxn(() async {
      await isar.budgets.put(budget);
      if (categories != null) {
        budget.categories.addAll(categories);
        await budget.categories.save();
      }
      if (tags != null) {
        budget.budgetTags.addAll(tags);
        await budget.budgetTags.save();
      }
    });
    return budget;
  }

  // ── Tests ──

  group('calculateSpentAmount — categoryWise', () {
    test('sums only matching category expenses', () async {
      final food = await seedCategory('Food');
      final transport = await seedCategory('Transport');
      await seedExpense(500, DateTime(2024, 3, 5), category: food);
      await seedExpense(300, DateTime(2024, 3, 10), category: food);
      await seedExpense(200, DateTime(2024, 3, 15), category: transport);

      final budget = await seedBudget(
        type: BudgetType.categoryWise,
        amount: 2000,
        start: DateTime(2024, 3, 1),
        end: DateTime(2024, 3, 31),
        categories: [food],
      );

      final spent = await budgetService.calculateSpentAmount(budget,
          start: DateTime(2024, 3, 1), end: DateTime(2024, 3, 31));
      expect(spent, 800); // 500 + 300, not 200 (transport)
    });

    test('returns 0 when no categories linked', () async {
      await seedExpense(500, DateTime(2024, 3, 5));

      final budget = await seedBudget(
        type: BudgetType.categoryWise,
        amount: 2000,
        start: DateTime(2024, 3, 1),
        end: DateTime(2024, 3, 31),
      );

      final spent = await budgetService.calculateSpentAmount(budget,
          start: DateTime(2024, 3, 1), end: DateTime(2024, 3, 31));
      expect(spent, 0);
    });
  });

  group('calculateSpentAmount — tagWise', () {
    test('sums only matching tag expenses', () async {
      final vacation = await seedTag('Vacation');
      final work = await seedTag('Work');
      await seedExpense(1000, DateTime(2024, 3, 5), tags: [vacation]);
      await seedExpense(500, DateTime(2024, 3, 10), tags: [work]);
      await seedExpense(300, DateTime(2024, 3, 15), tags: [vacation, work]);

      final budget = await seedBudget(
        type: BudgetType.tagWise,
        amount: 5000,
        start: DateTime(2024, 3, 1),
        end: DateTime(2024, 3, 31),
        tags: [vacation],
      );

      final spent = await budgetService.calculateSpentAmount(budget,
          start: DateTime(2024, 3, 1), end: DateTime(2024, 3, 31));
      expect(spent, 1300); // 1000 + 300 (both have vacation tag)
    });

    test('returns 0 when no tags linked', () async {
      final vacation = await seedTag('Vacation');
      await seedExpense(1000, DateTime(2024, 3, 5), tags: [vacation]);

      final budget = await seedBudget(
        type: BudgetType.tagWise,
        amount: 5000,
        start: DateTime(2024, 3, 1),
        end: DateTime(2024, 3, 31),
      );

      final spent = await budgetService.calculateSpentAmount(budget,
          start: DateTime(2024, 3, 1), end: DateTime(2024, 3, 31));
      expect(spent, 0);
    });

    test('expense with multiple tags counted once', () async {
      final t1 = await seedTag('Tag1');
      final t2 = await seedTag('Tag2');
      await seedExpense(500, DateTime(2024, 3, 5), tags: [t1, t2]);

      final budget = await seedBudget(
        type: BudgetType.tagWise,
        amount: 5000,
        start: DateTime(2024, 3, 1),
        end: DateTime(2024, 3, 31),
        tags: [t1, t2],
      );

      final spent = await budgetService.calculateSpentAmount(budget,
          start: DateTime(2024, 3, 1), end: DateTime(2024, 3, 31));
      expect(spent, 500); // counted once, not twice
    });
  });

  group('calculateSpentAmount — dayWise', () {
    test('sums all expenses when no categories linked', () async {
      final food = await seedCategory('Food');
      await seedExpense(500, DateTime(2024, 3, 5), category: food);
      await seedExpense(300, DateTime(2024, 3, 5));

      final budget = await seedBudget(
        type: BudgetType.dayWise,
        amount: 1000,
        start: DateTime(2024, 3, 5),
        end: DateTime(2024, 3, 5),
      );

      final spent = await budgetService.calculateSpentAmount(budget,
          start: DateTime(2024, 3, 5), end: DateTime(2024, 3, 5));
      expect(spent, 800); // all expenses
    });

    test('filters by categories when linked', () async {
      final food = await seedCategory('Food');
      final transport = await seedCategory('Transport');
      await seedExpense(500, DateTime(2024, 3, 5), category: food);
      await seedExpense(300, DateTime(2024, 3, 5), category: transport);

      final budget = await seedBudget(
        type: BudgetType.dayWise,
        amount: 1000,
        start: DateTime(2024, 3, 5),
        end: DateTime(2024, 3, 5),
        categories: [food],
      );

      final spent = await budgetService.calculateSpentAmount(budget,
          start: DateTime(2024, 3, 5), end: DateTime(2024, 3, 5));
      expect(spent, 500); // only food
    });
  });

  group('calculateSpentAmount — festival', () {
    test('sums all expenses in festival period', () async {
      await seedExpense(2000, DateTime(2024, 10, 20));
      await seedExpense(3000, DateTime(2024, 10, 25));
      await seedExpense(1000, DateTime(2024, 11, 5)); // outside

      final budget = await seedBudget(
        type: BudgetType.festival,
        amount: 10000,
        start: DateTime(2024, 10, 15),
        end: DateTime(2024, 10, 31),
      );

      final spent = await budgetService.calculateSpentAmount(budget,
          start: DateTime(2024, 10, 15), end: DateTime(2024, 10, 31));
      expect(spent, 5000); // 2000 + 3000
    });
  });

  group('calculateSpentAmount — travel', () {
    test('sums all expenses in travel period', () async {
      await seedExpense(1500, DateTime(2024, 6, 10));
      await seedExpense(2500, DateTime(2024, 6, 12));

      final budget = await seedBudget(
        type: BudgetType.travel,
        amount: 20000,
        start: DateTime(2024, 6, 8),
        end: DateTime(2024, 6, 15),
      );

      final spent = await budgetService.calculateSpentAmount(budget,
          start: DateTime(2024, 6, 8), end: DateTime(2024, 6, 15));
      expect(spent, 4000);
    });
  });

  group('calculateSpentAmount — edge cases', () {
    test('no transactions returns 0', () async {
      final budget = await seedBudget(
        type: BudgetType.dayWise,
        amount: 1000,
        start: DateTime(2024, 3, 5),
        end: DateTime(2024, 3, 5),
      );

      final spent = await budgetService.calculateSpentAmount(budget,
          start: DateTime(2024, 3, 5), end: DateTime(2024, 3, 5));
      expect(spent, 0);
    });

    test('income transactions not counted', () async {
      final txn = Transaction.create(
        date: DateTime(2024, 3, 5),
        amount: 5000,
        isExpense: false,
        description: 'salary',
      );
      await isar.writeTxn(() => isar.transactions.put(txn));

      final budget = await seedBudget(
        type: BudgetType.dayWise,
        amount: 1000,
        start: DateTime(2024, 3, 5),
        end: DateTime(2024, 3, 5),
      );

      final spent = await budgetService.calculateSpentAmount(budget,
          start: DateTime(2024, 3, 5), end: DateTime(2024, 3, 5));
      expect(spent, 0);
    });

    test('uses baseAmount not amount', () async {
      final txn = Transaction.create(
        date: DateTime(2024, 3, 5),
        amount: 100,
        isExpense: true,
        description: 'test',
        currencyCode: 'USD',
        convertedAmount: 8300,
        rateUsed: 83.0,
      );
      await isar.writeTxn(() => isar.transactions.put(txn));

      final budget = await seedBudget(
        type: BudgetType.dayWise,
        amount: 10000,
        start: DateTime(2024, 3, 5),
        end: DateTime(2024, 3, 5),
      );

      final spent = await budgetService.calculateSpentAmount(budget,
          start: DateTime(2024, 3, 5), end: DateTime(2024, 3, 5));
      // baseAmount should be convertedAmount (8300) if set, else amount (100)
      expect(spent, txn.baseAmount);
    });
  });

  group('calculateSpentAmount — recurrence with period range', () {
    test('weekly budget only counts current week expenses', () async {
      await seedExpense(200, DateTime(2024, 3, 4)); // week 1
      await seedExpense(300, DateTime(2024, 3, 11)); // week 2
      await seedExpense(400, DateTime(2024, 3, 18)); // week 3

      final budget = await seedBudget(
        type: BudgetType.dayWise,
        amount: 1000,
        start: DateTime(2024, 3, 4),
        end: DateTime(2024, 3, 10),
        recurrence: BudgetRecurrence.weekly,
      );

      // Query week 2 range
      final spent = await budgetService.calculateSpentAmount(budget,
          start: DateTime(2024, 3, 11), end: DateTime(2024, 3, 17));
      expect(spent, 300); // only week 2
    });
  });
}

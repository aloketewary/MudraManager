import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/category_rule.dart';
import 'package:mudra_manager/core/services/category_rule_service.dart';
import 'package:mudra_manager/core/utils/bulk_categorization_helper.dart';
import 'package:mudra_manager/core/utils/transaction_msg_util.dart';

void main() {
  late Directory tempDirectory;
  late Isar isar;
  late BulkCategorizationHelper helper;

  setUp(() async {
    final existing = Isar.getInstance();
    if (existing != null && existing.isOpen) await existing.close();

    tempDirectory = await Directory.systemTemp.createTemp(
      'bulk_categorization_characterization_',
    );
    isar = await Isar.open(
      [CategoryRuleSchema],
      directory: tempDirectory.path,
    );
    helper = BulkCategorizationHelper(CategoryRuleService(isar));
  });

  tearDown(() async {
    if (isar.isOpen) await isar.close();
    if (tempDirectory.existsSync()) tempDirectory.deleteSync(recursive: true);
  });

  TransactionInfo transaction(String recipient) {
    return TransactionInfo(
      address: '',
      sender: '',
      body: 'Payment to $recipient',
      account: AccountDetails(sendTo: recipient),
      money: '100',
    );
  }

  test('groups matching learned rule as auto-suggested bulk work', () async {
    await isar.writeTxn(() async {
      await isar.categoryRules.put(
        CategoryRule(
          recipientName: 'Vendor',
          categoryId: 'category-a',
          confidence: 80,
          matchCount: 2,
        ),
      );
    });

    final result = await helper.processBulkTransactions([
      transaction('Vendor'),
      transaction('Vendor'),
    ]);

    expect(result.autoSuggested.keys, contains('UPI:vendor'));
    expect(
      result.autoSuggested['UPI:vendor']!.suggestedCategoryId,
      'category-a',
    );
    expect(result.autoSuggested['UPI:vendor']!.count, 2);
    expect(result.needsManualReview, isEmpty);
  });

  test(
    'uses only non-system categories compatible with transaction type',
    () async {
      await isar.writeTxn(() async {
        await isar.categoryRules.putAll([
          CategoryRule(
            recipientName: 'Vendor',
            categoryId: '1',
            confidence: 100,
          ),
          CategoryRule(
            recipientName: 'Vendor',
            categoryId: '2',
            confidence: 90,
          ),
          CategoryRule(
            recipientName: 'Vendor',
            categoryId: '3',
            confidence: 80,
          ),
        ]);
      });

      final systemExpense = Category.create(
        name: 'System expense',
        categoryType: CategoryType.expense,
      )
        ..id = 1
        ..isSystem = true;
      final income = Category.create(
        name: 'Income',
        categoryType: CategoryType.income,
      )..id = 2;
      final expense = Category.create(
        name: 'Expense',
        categoryType: CategoryType.expense,
      )..id = 3;

      final debit = transaction('Vendor')
        ..typeOfTransaction = TransactionType.debited;
      final result = await helper.processBulkTransactions(
        [debit],
        availableCategories: [systemExpense, income, expense],
      );

      expect(result.autoSuggested['UPI:vendor']!.suggestedCategoryId, '3');
    },
  );

  test('excludes learned categories with incompatible transaction type',
      () async {
    await isar.writeTxn(() async {
      await isar.categoryRules.put(
        CategoryRule(
          recipientName: 'Vendor',
          categoryId: '1',
          confidence: 80,
        ),
      );
    });

    final income = Category.create(
      name: 'Income',
      categoryType: CategoryType.income,
    )..id = 1;
    final debit = transaction('Vendor')
      ..typeOfTransaction = TransactionType.debited;

    final result = await helper.processBulkTransactions(
      [debit],
      availableCategories: [income],
    );

    expect(result.autoSuggested, isEmpty);
    expect(result.needsManualReview['UPI:vendor']!.count, 1);
  });

  test('keeps empty/no-match bulk groups in manual review', () async {
    final result = await helper.processBulkTransactions([
      transaction('Unknown Vendor'),
    ]);

    // Characterization: no learned result does not create an auto-suggestion.
    expect(result.autoSuggested, isEmpty);
    expect(result.needsManualReview.keys, contains('UPI:unknown vendor'));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/extensions/field_encryption_ext.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/category_rule.dart';
import 'package:mudra_manager/core/db/models/pending_transaction.dart';
import 'package:mudra_manager/core/utils/category_matcher.dart';
import 'package:mudra_manager/core/utils/transaction_msg_util.dart';
import 'package:mudra_manager/features/transactions/data/transaction_matching_service.dart';

void main() {
  group('CategoryMatcher learned-rule baseline', () {
    test('requires confidence strictly above 40', () {
      final txn = TransactionInfo(
        address: '',
        sender: '',
        body: 'Payment to Vendor Bank',
        account: AccountDetails(
          sendTo: 'Vendor',
          bankName: 'Vendor Bank',
          no: '1234',
        ),
        money: '100',
      );
      final rule = CategoryRule(
        recipientName: 'Vendor',
        merchantName: 'Vendor Bank',
        accountNumber: '1234',
        amountMin: 50,
        amountMax: 150,
        categoryId: 'learned-category',
        confidence: 40,
        matchCount: 1,
      );

      // Current contract: confidence must exceed 40, regardless of match evidence.
      expect(
        CategoryMatcher.suggestCategoryFromRules(txn, [rule]),
        isNull,
      );
    });

    test('exact merchant rule outranks partial rule', () {
      final txn = TransactionInfo(
        address: '',
        sender: '',
        body: 'Payment at Acme Market',
        account: AccountDetails(bankName: 'Acme Market'),
      );
      final partialRule = CategoryRule(
        merchantName: 'Acme',
        categoryId: 'partial-category',
        confidence: 100,
        matchCount: 5,
      );
      final exactRule = CategoryRule(
        merchantName: 'Acme Market',
        categoryId: 'exact-category',
        confidence: 100,
        matchCount: 1,
      );

      // Current contract: normalized exact identity has precedence over partial identity.
      expect(
        CategoryMatcher.suggestCategoryFromRules(
          txn,
          [partialRule, exactRule],
        ),
        'exact-category',
      );
    });

    test('returns null for empty or non-matching learned rules', () {
      final txn = TransactionInfo(
        address: '',
        sender: '',
        body: 'Unknown payment',
        account: AccountDetails(bankName: 'Completely Different Merchant'),
      );

      expect(CategoryMatcher.suggestCategoryFromRules(txn, []), isNull);
      expect(
        CategoryMatcher.suggestCategoryFromRules(
          txn,
          [
            CategoryRule(
              merchantName: 'Known Merchant',
              categoryId: 'known-category',
              confidence: 100,
            ),
          ],
        ),
        isNull,
      );
    });

    test('does not validate category availability in current API', () {
      final txn = TransactionInfo(
        address: '',
        sender: '',
        body: 'Payment to Vendor',
        account: AccountDetails(sendTo: 'Vendor'),
      );
      final rule = CategoryRule(
        recipientName: 'Vendor',
        categoryId: 'deleted-category',
        confidence: 80,
      );

      // Characterization: matcher returns persisted ID without category lookup.
      expect(
        CategoryMatcher.suggestCategoryFromRules(txn, [rule]),
        'deleted-category',
      );
    });
  });

  group('Pending import generic matching baseline', () {
    test(
      'Feature: category-auto-analyze-bug, Property 4: No qualifying learned rule delegates to filtered generic matching',
      () {
        // **Validates: Requirements 3.1**
        // Generated type/body/category combinations exceed required 100
        // iterations. Incompatible category carries matching keyword and comes
        // first, so unfiltered generic matching would select it before fallback.
        for (var i = 0; i < 128; i++) {
          final isIncome = i.isOdd;
          final compatibleType =
              isIncome ? CategoryType.income : CategoryType.expense;
          final incompatibleType =
              isIncome ? CategoryType.expense : CategoryType.income;
          final compatible = Category.create(
            name: 'Compatible $i',
            categoryType: compatibleType,
          );
          final incompatible = Category.create(
            name: 'Incompatible $i',
            categoryType: incompatibleType,
            keywords: ['marker-$i'],
          );
          final pending = PendingTransaction()
            ..account = '1234'
            ..body = 'Payment marker-$i'
            ..isIncome = isIncome;
          final account = Account.create(name: 'Primary')
            ..accountNumber = '1234';

          final result = TransactionMatchingService.matchTransaction(
            pending: pending,
            accounts: [account],
            categories: [incompatible, compatible],
          );

          expect(result, isNotNull);
          expect(result!.category, same(compatible));
          expect(result.category.categoryType, compatibleType);
        }
      },
    );

    test('filters generic matching by transaction type before fallback', () {
      final account = Account.create(name: 'Primary')..accountNumber = '1234';
      final expense = Category.create(
        name: 'Groceries',
        categoryType: CategoryType.expense,
      );
      final income = Category.create(
        name: 'Salary',
        categoryType: CategoryType.income,
        keywords: ['salary'],
      );
      final pending = PendingTransaction()
        ..account = '1234'
        ..body = 'Salary credited'
        ..isIncome = false;

      final result = TransactionMatchingService.matchTransaction(
        pending: pending,
        accounts: [account],
        categories: [expense, income],
      );

      // Characterization: income category is excluded from expense relevantCategories;
      // robust matcher falls back to first relevant expense category.
      expect(result, isNotNull);
      expect(result!.category, same(expense));
    });

    test('pre-matched category bypasses generic matcher', () {
      final account = Account.create(name: 'Primary')..accountNumber = '1234';
      final genericCategory = Category.create(
        name: 'Groceries',
        categoryType: CategoryType.expense,
        keywords: ['groceries'],
      );
      final preMatchedCategory = Category.create(
        name: 'Transport',
        categoryType: CategoryType.expense,
      );
      final pending = PendingTransaction()
        ..account = '1234'
        ..body = 'Groceries purchase'
        ..isIncome = false;

      final result = TransactionMatchingService.matchTransaction(
        pending: pending,
        accounts: [account],
        categories: [genericCategory, preMatchedCategory],
        preMatchedCategory: preMatchedCategory,
      );

      expect(result, isNotNull);
      expect(result!.category, same(preMatchedCategory));
    });
  });

  group('CategoryRule persistence boundary baseline', () {
    test('encryption extension preserves fields when encryption is unavailable',
        () {
      final rule = CategoryRule(
        recipientName: 'Vendor',
        merchantName: 'Merchant',
        accountNumber: '1234',
        categoryId: 'category',
      );

      rule.encryptFields();
      expect(rule.recipientName, 'Vendor');
      expect(rule.merchantName, 'Merchant');
      expect(rule.accountNumber, '1234');

      rule.decryptFields();
      expect(rule.recipientName, 'Vendor');
      expect(rule.merchantName, 'Merchant');
      expect(rule.accountNumber, '1234');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/category_rule.dart';
import 'package:mudra_manager/core/utils/category_matcher.dart';
import 'package:mudra_manager/core/utils/transaction_msg_util.dart';

void main() {
  late List<Category> categories;

  setUp(() {
    categories = [
      Category.create(
        name: 'Food & Dining',
        categoryType: CategoryType.expense,
        keywords: ['swiggy', 'zomato', 'restaurant', 'food', 'dining', 'cafe'],
      ),
      Category.create(
        name: 'Grocery',
        categoryType: CategoryType.expense,
        keywords: [
          'grocery',
          'vegetable',
          'supermarket',
          'bigbasket',
          'kirana',
        ],
      ),
      Category.create(
        name: 'Transport',
        categoryType: CategoryType.expense,
        keywords: ['uber', 'ola', 'petrol', 'fuel', 'metro', 'bus'],
      ),
      Category.create(
        name: 'Other',
        categoryType: CategoryType.expense,
      ),
      Category.create(
        name: 'Salary',
        categoryType: CategoryType.income,
        keywords: ['salary', 'payroll'],
      ),
    ];
  });

  group('CategoryMatcher.normalizeIdentity', () {
    test('trims edge whitespace and lowercases identity', () {
      expect(
        CategoryMatcher.normalizeIdentity('  AcMe Market  '),
        'acme market',
      );
    });

    test('returns null for null or blank identity', () {
      expect(CategoryMatcher.normalizeIdentity(null), isNull);
      expect(CategoryMatcher.normalizeIdentity(' \t\n '), isNull);
    });
  });

  group('CategoryMatcher.matchByKeywords', () {
    test('matches by keyword in text', () {
      final result = CategoryMatcher.matchByKeywords(
        'Payment to Swiggy for food order',
        categories,
      );
      expect(result?.name, 'Food & Dining');
    });

    test('matches by category name', () {
      final result = CategoryMatcher.matchByKeywords(
        'Grocery shopping at store',
        categories,
      );
      expect(result?.name, 'Grocery');
    });

    test('longer keyword match wins', () {
      // "supermarket" (11 chars) > "grocery" (7 chars)
      final result = CategoryMatcher.matchByKeywords(
        'Bought items at supermarket grocery',
        categories,
      );
      // Both match Grocery, score = 11 + 7 = 18
      expect(result?.name, 'Grocery');
    });

    test('no match returns null', () {
      final result = CategoryMatcher.matchByKeywords(
        'Random unknown transaction xyz',
        categories,
      );
      expect(result, null);
    });

    test('case insensitive matching', () {
      final result = CategoryMatcher.matchByKeywords(
        'UBER ride to airport',
        categories,
      );
      expect(result?.name, 'Transport');
    });

    test('empty text returns null', () {
      final result = CategoryMatcher.matchByKeywords('', categories);
      expect(result, null);
    });

    test('empty categories returns null', () {
      final result = CategoryMatcher.matchByKeywords('some text', []);
      expect(result, null);
    });

    test('category without keywords matches by name only', () {
      final result = CategoryMatcher.matchByKeywords(
        'Other expenses for the month',
        categories,
      );
      expect(result?.name, 'Other');
    });
  });

  group('CategoryMatcher.getFallbackCategory', () {
    test('returns Other category when available', () {
      final result = CategoryMatcher.getFallbackCategory(categories, null);
      expect(result?.name, 'Other');
    });

    test('returns first category when no Other exists', () {
      final noOther = categories.where((c) => c.name != 'Other').toList();
      final result = CategoryMatcher.getFallbackCategory(noOther, null);
      expect(result, isNotNull);
      expect(result?.name, 'Food & Dining');
    });

    test('returns null for empty list', () {
      final result = CategoryMatcher.getFallbackCategory([], null);
      expect(result, null);
    });

    test('amount parameter does not crash', () {
      final result = CategoryMatcher.getFallbackCategory(categories, 500.0);
      expect(result, isNotNull);
    });
  });

  group('Keyword matching edge cases', () {
    test('partial keyword match works', () {
      // "food" is in "foodcourt"
      final result = CategoryMatcher.matchByKeywords(
        'Paid at foodcourt',
        categories,
      );
      expect(result?.name, 'Food & Dining');
    });

    test('multiple categories match — highest score wins', () {
      // "food" matches Food & Dining, "grocery" matches Grocery
      final result = CategoryMatcher.matchByKeywords(
        'food grocery store',
        categories,
      );
      // "grocery" (7) + "food & dining" name doesn't match "food grocery store"
      // "food" (4) matches Food & Dining
      // "grocery" (7) matches Grocery → higher score
      expect(result?.name, 'Grocery');
    });

    test('special characters in text', () {
      final result = CategoryMatcher.matchByKeywords(
        'Paid ₹500 to Zomato (food delivery)',
        categories,
      );
      expect(result?.name, 'Food & Dining');
    });
  });
  group('CategoryMatcher.learned rules', () {
    TransactionInfo transaction({
      String? merchant,
      String? recipient,
      String? account,
      String? amount,
    }) {
      return TransactionInfo(
        account: AccountDetails(
          bankName: merchant,
          sendTo: recipient,
          no: account,
        ),
        money: amount,
        address: '',
        sender: '',
        body: '',
      );
    }

    CategoryRule rule(
      String categoryId, {
      String? merchant,
      String? recipient,
      String? account,
      double? amountMin,
      double? amountMax,
      int confidence = 50,
      int matchCount = 1,
      int id = 0,
    }) {
      return CategoryRule(
        merchantName: merchant,
        recipientName: recipient,
        accountNumber: account,
        amountMin: amountMin,
        amountMax: amountMax,
        categoryId: categoryId,
        confidence: confidence,
        matchCount: matchCount,
      )..id = id;
    }

    test('requires confidence strictly greater than 40', () {
      final txn = transaction(merchant: 'Acme');

      expect(
        CategoryMatcher.suggestCategoryFromRules(
          txn,
          [rule('low', merchant: 'Acme', confidence: 40)],
        ),
        isNull,
      );
      expect(
        CategoryMatcher.suggestCategoryFromRules(
          txn,
          [rule('valid', merchant: 'Acme', confidence: 41)],
        ),
        'valid',
      );
    });

    test('skips unavailable and no-signal rules', () {
      final txn = transaction(merchant: 'Acme');
      final rules = [
        rule('missing', merchant: 'Acme'),
        rule('no-signal'),
      ];

      expect(
        CategoryMatcher.findBestLearnedRule(
          txn,
          rules,
          availableCategoryIds: {'other'},
        ),
        isNull,
      );
    });

    test('ranks exact identity above partial identity', () {
      final txn = transaction(merchant: 'Acme Market');
      final exact = rule('exact', merchant: 'Acme Market');
      final partial = rule('partial', merchant: 'Acme');

      expect(
        CategoryMatcher.suggestCategoryFromRules(txn, [partial, exact]),
        'exact',
      );
    });

    test('ranks specificity, confidence, then match count', () {
      final txn = transaction(merchant: 'Acme', account: '1234');
      final amountOnly = rule(
        'amount',
        amountMin: 10,
        amountMax: 20,
      );
      final accountMatch = rule('account', account: '1234');
      final exactLowConfidence = rule(
        'exact-low',
        merchant: 'Acme',
        confidence: 41,
      );
      final exactHighConfidence = rule(
        'exact-high',
        merchant: 'Acme',
        confidence: 90,
      );

      expect(
        CategoryMatcher.suggestCategoryFromRules(
          txn,
          [amountOnly, accountMatch, exactLowConfidence, exactHighConfidence],
        ),
        'exact-high',
      );

      final sameSpecificity = [
        rule('low-count', merchant: 'Acme', matchCount: 1),
        rule('high-count', merchant: 'Acme', matchCount: 2),
      ];
      expect(
        CategoryMatcher.suggestCategoryFromRules(txn, sameSpecificity),
        'high-count',
      );
    });

    test('uses stable canonical key independent of input order', () {
      final txn = transaction(merchant: 'Acme');
      final first = rule('category-a', merchant: 'Acme', id: 20);
      final second = rule('category-b', merchant: 'Acme', id: 10);

      final forward = CategoryMatcher.suggestCategoryFromRules(
        txn,
        [first, second],
      );
      final reverse = CategoryMatcher.suggestCategoryFromRules(
        txn,
        [second, first],
      );

      expect(forward, 'category-a');
      expect(reverse, forward);
    });
  });

  group('CategoryMatcher learned-rule edge cases', () {
    TransactionInfo transaction({
      String? merchant,
      String? recipient,
      String? account,
      String? amount,
    }) {
      return TransactionInfo(
        account: AccountDetails(
          bankName: merchant,
          sendTo: recipient,
          no: account,
        ),
        money: amount,
        address: '',
        sender: '',
        body: '',
      );
    }

    CategoryRule rule(
      String categoryId, {
      String? merchant,
      String? recipient,
      String? account,
      double? amountMin,
      double? amountMax,
      int confidence = 50,
      int matchCount = 1,
      int id = 0,
    }) {
      return CategoryRule(
        merchantName: merchant,
        recipientName: recipient,
        accountNumber: account,
        amountMin: amountMin,
        amountMax: amountMax,
        categoryId: categoryId,
        confidence: confidence,
        matchCount: matchCount,
      )..id = id;
    }

    test('excludes confidence 40 while accepting confidence 41', () {
      final txn = transaction(merchant: 'Acme');
      final lowConfidence = rule(
        'low-confidence',
        merchant: 'Acme',
        confidence: 40,
      );
      final qualifying = rule(
        'qualifying',
        merchant: 'Acme',
        confidence: 41,
      );

      expect(
        CategoryMatcher.findBestLearnedRule(
          txn,
          [lowConfidence],
          availableCategoryIds: {lowConfidence.categoryId},
        ),
        isNull,
      );
      expect(
        CategoryMatcher.findBestLearnedRule(
          txn,
          [lowConfidence, qualifying],
          availableCategoryIds: {
            lowConfidence.categoryId,
            qualifying.categoryId,
          },
        )?.categoryId,
        qualifying.categoryId,
      );
    });

    test('skips blank and unavailable category IDs', () {
      final txn = transaction(merchant: 'Acme');
      final blankCategory = rule('', merchant: 'Acme');
      final unavailableCategory = rule('deleted', merchant: 'Acme');

      expect(
        CategoryMatcher.suggestCategoryFromRules(txn, [blankCategory]),
        isNull,
      );
      expect(
        CategoryMatcher.suggestCategoryFromRules(
          txn,
          [unavailableCategory],
          availableCategoryIds: {'current'},
        ),
        isNull,
      );
    });

    test('returns null for empty rules and empty identities', () {
      final blankTransaction = transaction(
        merchant: ' \t',
        recipient: '\n',
        account: ' ',
      );
      final blankIdentityRule = rule(
        'blank-identity',
        merchant: ' ',
        recipient: '\t',
        account: ' ',
      );

      expect(
        CategoryMatcher.suggestCategoryFromRules(blankTransaction, []),
        isNull,
      );
      expect(
        CategoryMatcher.suggestCategoryFromRules(
          blankTransaction,
          [blankIdentityRule],
        ),
        isNull,
      );
    });

    test('ignores malformed amounts without throwing', () {
      final malformedAmount = transaction(amount: 'not-a-number');
      final amountRule = rule(
        'amount-only',
        amountMin: 10,
        amountMax: 20,
      );

      expect(
        CategoryMatcher.findBestLearnedRule(
          malformedAmount,
          [amountRule],
        ),
        isNull,
      );
    });

    test('ignores incomplete and reversed amount ranges', () {
      final txn = transaction(amount: '15');
      final incompleteMinimum = rule(
        'missing-minimum',
        amountMax: 20,
      );
      final incompleteMaximum = rule(
        'missing-maximum',
        amountMin: 10,
      );
      final reversedRange = rule(
        'reversed-range',
        amountMin: 20,
        amountMax: 10,
      );

      expect(
        CategoryMatcher.findBestLearnedRule(
          txn,
          [incompleteMinimum, incompleteMaximum, reversedRange],
        ),
        isNull,
      );
    });

    test('handles duplicate candidate entries deterministically', () {
      final txn = transaction(merchant: 'Acme');
      final duplicate = rule(
        'duplicate-category',
        merchant: 'Acme',
        id: 7,
      );

      final selected = CategoryMatcher.findBestLearnedRule(
        txn,
        [duplicate, duplicate],
      );

      expect(selected, same(duplicate));
    });

    test('equal-ranked candidates keep same result when input is reversed', () {
      final txn = transaction(merchant: 'Acme');
      final categoryA = rule(
        'category-a',
        merchant: 'Acme',
        confidence: 80,
        matchCount: 4,
        id: 2,
      );
      final categoryB = rule(
        'category-b',
        merchant: 'Acme',
        confidence: 80,
        matchCount: 4,
        id: 1,
      );

      final forward = CategoryMatcher.suggestCategoryFromRules(
        txn,
        [categoryA, categoryB],
      );
      final reversed = CategoryMatcher.suggestCategoryFromRules(
        txn,
        [categoryB, categoryA],
      );

      expect(forward, 'category-a');
      expect(reversed, forward);
    });
  });

  group('Learned-rule precedence properties', () {
    test(
      'Feature: category-auto-analyze-bug, Property 1: Qualifying learned rules take precedence',
      () {
        // **Validates: Requirements 1.1, 1.2, 1.3**
        // Deterministic generated cases provide property coverage without adding
        // a test-only dependency; iteration count exceeds required minimum 100.
        for (var i = 0; i < 128; i++) {
          final merchant = 'Merchant $i';
          final learnedCategoryId = 'learned-category-$i';
          final genericCategory = Category.create(
            name: 'generic-category-$i',
            keywords: [merchant],
          );
          final txn = TransactionInfo(
            account: AccountDetails(bankName: merchant),
            money: '${i + 1}',
            address: '',
            sender: '',
            body: 'Payment at $merchant',
          );

          final genericResult = CategoryMatcher.matchByKeywords(
            txn.body,
            [genericCategory],
          );
          expect(genericResult?.name, genericCategory.name);

          final lowerSpecificityRule = CategoryRule(
            merchantName: 'Merchant',
            categoryId: 'partial-category-$i',
            confidence: 100,
            matchCount: 100,
          )..id = i + 1;
          final exactRule = CategoryRule(
            merchantName: merchant,
            categoryId: learnedCategoryId,
            confidence: 41 + (i % 60),
            matchCount: 1 + (i % 10),
          )..id = i + 1000;

          final learnedResult = CategoryMatcher.suggestCategoryFromRules(
            txn,
            [lowerSpecificityRule, exactRule],
            availableCategoryIds: {
              lowerSpecificityRule.categoryId,
              exactRule.categoryId,
            },
          );

          expect(learnedResult, learnedCategoryId);
          expect(learnedResult, isNot(genericResult?.name));
        }
      },
    );

    test(
      'Feature: category-auto-analyze-bug, Property 2: Identity normalization preserves learned matching',
      () {
        // **Validates: Requirements 1.4**
        // Deterministic generated cases provide property coverage without adding
        // a test-only dependency; iteration count exceeds required minimum 100.
        TransactionInfo makeTransaction({
          String? merchant,
          String? recipient,
        }) {
          return TransactionInfo(
            account: AccountDetails(
              bankName: merchant,
              sendTo: recipient,
            ),
            address: '',
            sender: '',
            body: '',
          );
        }

        CategoryRule makeRule(
          String categoryId, {
          String? merchant,
          String? recipient,
        }) {
          return CategoryRule(
            merchantName: merchant,
            recipientName: recipient,
            categoryId: categoryId,
          );
        }

        for (var i = 0; i < 128; i++) {
          final identity = 'Merchant $i';
          final decoratedIdentity = '\t  ${identity.toUpperCase()}  \n';
          final categoryId = 'normalized-category-$i';
          final useRecipient = i.isOdd;

          final canonicalTxn = makeTransaction(
            merchant: useRecipient ? null : identity,
            recipient: useRecipient ? identity : null,
          );
          final decoratedTxn = makeTransaction(
            merchant: useRecipient ? null : decoratedIdentity,
            recipient: useRecipient ? decoratedIdentity : null,
          );
          final canonicalRule = makeRule(
            categoryId,
            merchant: useRecipient ? null : identity,
            recipient: useRecipient ? identity : null,
          );
          final decoratedRule = makeRule(
            categoryId,
            merchant: useRecipient ? null : decoratedIdentity,
            recipient: useRecipient ? decoratedIdentity : null,
          );

          expect(
            CategoryMatcher.suggestCategoryFromRules(
              decoratedTxn,
              [canonicalRule],
            ),
            categoryId,
          );
          expect(
            CategoryMatcher.suggestCategoryFromRules(
              canonicalTxn,
              [decoratedRule],
            ),
            categoryId,
          );
        }
      },
    );

    test(
      'Feature: category-auto-analyze-bug, Property 3: Learned-rule ranking is lexicographic and deterministic',
      () {
        // **Validates: Requirements 2.1, 2.2, 2.3, 2.4**
        // Each generated case exercises one ranking dimension, then reverses
        // candidates to prove selection does not depend on iteration order.
        TransactionInfo makeTransaction(int index) {
          return TransactionInfo(
            account: AccountDetails(
              bankName: 'Merchant $index',
              no: 'account-$index',
            ),
            money: '${100 + index}',
            address: '',
            sender: '',
            body: '',
          );
        }

        CategoryRule makeRule(
          String categoryId, {
          String? merchant,
          String? account,
          double? amountMin,
          double? amountMax,
          int confidence = 50,
          int matchCount = 1,
          int id = 0,
        }) {
          return CategoryRule(
            merchantName: merchant,
            accountNumber: account,
            amountMin: amountMin,
            amountMax: amountMax,
            categoryId: categoryId,
            confidence: confidence,
            matchCount: matchCount,
          )..id = id;
        }

        for (var i = 0; i < 128; i++) {
          final txn = makeTransaction(i);
          final merchant = 'Merchant $i';
          final account = 'account-$i';
          final amount = (100 + i).toDouble();
          final mode = i % 6;

          late List<CategoryRule> candidates;
          late String expectedCategory;
          int? expectedRuleId;

          switch (mode) {
            case 0:
              // Identity tier outranks account/amount evidence and confidence.
              candidates = [
                makeRule(
                  'amount-only-$i',
                  amountMin: amount - 1,
                  amountMax: amount + 1,
                  confidence: 100,
                  matchCount: 100,
                  id: 1,
                ),
                makeRule(
                  'account-only-$i',
                  account: account,
                  confidence: 100,
                  matchCount: 100,
                  id: 2,
                ),
                makeRule(
                  'partial-$i',
                  merchant: 'Merchant',
                  confidence: 100,
                  matchCount: 100,
                  id: 3,
                ),
                makeRule(
                  'exact-$i',
                  merchant: merchant,
                  confidence: 41,
                  matchCount: 1,
                  id: 4,
                ),
              ];
              expectedCategory = 'exact-$i';
              break;
            case 1:
              // Within equal identity tier, account evidence outranks amount.
              candidates = [
                makeRule(
                  'amount-$i',
                  amountMin: amount - 1,
                  amountMax: amount + 1,
                  confidence: 100,
                  matchCount: 100,
                  id: 1,
                ),
                makeRule(
                  'account-$i',
                  account: account,
                  confidence: 41,
                  matchCount: 1,
                  id: 2,
                ),
              ];
              expectedCategory = 'account-$i';
              break;
            case 2:
              // Within equal identity/account evidence, amount evidence wins.
              candidates = [
                makeRule(
                  'identity-account-$i',
                  merchant: merchant,
                  account: account,
                  confidence: 41,
                  matchCount: 1,
                  id: 1,
                ),
                makeRule(
                  'identity-account-amount-$i',
                  merchant: merchant,
                  account: account,
                  amountMin: amount - 1,
                  amountMax: amount + 1,
                  confidence: 41,
                  matchCount: 1,
                  id: 2,
                ),
              ];
              expectedCategory = 'identity-account-amount-$i';
              break;
            case 3:
              candidates = [
                makeRule(
                  'low-confidence-$i',
                  merchant: merchant,
                  confidence: 41,
                  matchCount: 100,
                  id: 1,
                ),
                makeRule(
                  'high-confidence-$i',
                  merchant: merchant,
                  confidence: 42 + (i % 58),
                  matchCount: 1,
                  id: 2,
                ),
              ];
              expectedCategory = 'high-confidence-$i';
              break;
            case 4:
              final confidence = 60 + (i % 30);
              candidates = [
                makeRule(
                  'low-count-$i',
                  merchant: merchant,
                  confidence: confidence,
                  matchCount: 1,
                  id: 1,
                ),
                makeRule(
                  'high-count-$i',
                  merchant: merchant,
                  confidence: confidence,
                  matchCount: 2 + (i % 20),
                  id: 2,
                ),
              ];
              expectedCategory = 'high-count-$i';
              break;
            default:
              candidates = [
                makeRule(
                  'category-z-$i',
                  merchant: merchant,
                  confidence: 75,
                  matchCount: 5,
                  id: 10,
                ),
                makeRule(
                  'category-a-$i',
                  merchant: merchant,
                  confidence: 75,
                  matchCount: 5,
                  id: 20,
                ),
              ];
              expectedCategory = 'category-a-$i';
              expectedRuleId = 20;
          }

          final forward = CategoryMatcher.findBestLearnedRule(txn, candidates);
          final reverse = CategoryMatcher.findBestLearnedRule(
            txn,
            candidates.reversed.toList(),
          );

          expect(forward?.categoryId, expectedCategory);
          expect(reverse?.categoryId, expectedCategory);
          expect(reverse?.categoryId, forward?.categoryId);
          if (expectedRuleId != null) {
            expect(forward?.id, expectedRuleId);
            expect(reverse?.id, expectedRuleId);
          }
        }
      },
    );
  });

  group('Learned-rule eligibility fallback properties', () {
    test(
      'Feature: category-auto-analyze-bug, Property 6: Ineligible rules preserve safe fallback',
      () {
        // **Validates: Requirements 3.3, 3.4**
        // Deterministic generated cases cover low-confidence and unavailable
        // learned categories, each with and without a generic result.
        for (var i = 0; i < 128; i++) {
          final hasGenericResult = i % 4 < 2;
          final isUnavailableCategory = i.isOdd;
          final merchant = 'Merchant $i';
          final learnedCategoryId = 'learned-category-$i';
          final genericCategory = Category.create(
            name: 'Generic $i',
            categoryType: CategoryType.expense,
            keywords: ['generic-marker-$i'],
          );
          final fallbackCategory = Category.create(
            name: 'Other',
            categoryType: CategoryType.expense,
          );
          final incompatibleCategory = Category.create(
            name: 'Incompatible $i',
            categoryType: CategoryType.income,
            keywords: ['generic-marker-$i'],
          );
          final allCategories = [
            incompatibleCategory,
            genericCategory,
            fallbackCategory,
          ];
          final relevantCategories = allCategories
              .where(
                (category) => category.categoryType == CategoryType.expense,
              )
              .toList();
          final txn = TransactionInfo(
            account: AccountDetails(bankName: merchant),
            money: '100',
            address: '',
            sender: '',
            body: hasGenericResult
                ? 'Payment generic-marker-$i'
                : 'Payment without category marker',
          );
          final rule = CategoryRule(
            merchantName: merchant,
            categoryId: learnedCategoryId,
            confidence: isUnavailableCategory ? 80 : 40,
          );
          final availableCategoryIds = isUnavailableCategory
              ? <String>{genericCategory.name, fallbackCategory.name}
              : <String>{learnedCategoryId};

          // Ineligible learned result must open fallback path, never win.
          expect(
            CategoryMatcher.suggestCategoryFromRules(
              txn,
              [rule],
              availableCategoryIds: availableCategoryIds,
            ),
            isNull,
          );

          // Generic matching receives only type-compatible categories. The
          // income category has same keyword and must never suppress fallback.
          final genericResult = CategoryMatcher.matchByKeywords(
            txn.body,
            relevantCategories,
          );
          if (hasGenericResult) {
            expect(genericResult, same(genericCategory));
            expect(genericResult, isNot(same(incompatibleCategory)));
          } else {
            expect(genericResult, isNull);
            expect(
              CategoryMatcher.getFallbackCategory(relevantCategories, 100),
              same(fallbackCategory),
            );
          }
        }
      },
    );
  });

  group('CategoryMatcher learning upsert properties', () {
    TransactionInfo transaction({
      required String identity,
      bool asRecipient = false,
    }) {
      return TransactionInfo(
        account: AccountDetails(
          bankName: asRecipient ? null : identity,
          sendTo: asRecipient ? identity : null,
          no: '  account-1234  ',
        ),
        money: '125.50',
        address: '',
        sender: '',
        body: '',
      );
    }

    test(
      'Feature: category-auto-analyze-bug, Property 7: Learning is normalized upsert with ranking metadata',
      () {
        // **Validates: Requirements 4.1, 4.2, 4.3**
        // Deterministic generated cases exceed required 100 iterations.
        for (var i = 0; i < 128; i++) {
          final identity = 'Merchant $i';
          final asRecipient = i.isOdd;
          final firstTransaction = transaction(
            identity: '  ${identity.toUpperCase()}  ',
            asRecipient: asRecipient,
          );
          final created = CategoryMatcher.createOrUpdateRule(
            firstTransaction,
            'category-before-$i',
            [],
          );

          expect(
            created.recipientName,
            asRecipient ? identity.toLowerCase() : isNull,
          );
          expect(
            created.merchantName,
            asRecipient ? isNull : identity.toLowerCase(),
          );
          expect(created.accountNumber, 'account-1234');
          expect(created.categoryId, 'category-before-$i');
          expect(created.matchCount, 1);
          expect(created.confidence, 50);

          final originalLastUsed = DateTime(2020, 1, 1);
          created.lastUsed = originalLastUsed;
          created.amountMin = 100;
          created.amountMax = 150;
          created.accountNumber = ' retained-account-$i ';
          created.matchCount = 7;
          created.confidence = i.isEven ? 95 : 100;
          final originalRecipient = created.recipientName;
          final originalMerchant = created.merchantName;
          final originalAccount = created.accountNumber;

          final updated = CategoryMatcher.createOrUpdateRule(
            transaction(identity: identity, asRecipient: asRecipient),
            'category-after-$i',
            [created],
          );

          expect(updated, same(created));
          expect(updated.categoryId, 'category-after-$i');
          expect(updated.matchCount, 8);
          expect(updated.confidence, 100);
          expect(updated.recipientName, originalRecipient);
          expect(updated.merchantName, originalMerchant);
          expect(updated.accountNumber, originalAccount);
          expect(updated.amountMin, 100);
          expect(updated.amountMax, 150);
          expect(
            updated.lastUsed.isAfter(originalLastUsed),
            isTrue,
          );

          final oldTimestamp = DateTime(2020, 1, 1);
          final firstTie = CategoryRule(
            merchantName: asRecipient ? null : identity,
            recipientName: asRecipient ? identity : null,
            categoryId: 'category-a-$i',
            matchCount: 3,
            confidence: 80,
          )..id = 1;
          final secondTie = CategoryRule(
            merchantName: asRecipient ? null : identity,
            recipientName: asRecipient ? identity : null,
            categoryId: 'category-b-$i',
            matchCount: 3,
            confidence: 80,
          )..id = 2;
          firstTie.lastUsed = oldTimestamp;
          secondTie.lastUsed = DateTime(2030, 1, 1);

          final forward = CategoryMatcher.suggestCategoryFromRules(
            transaction(identity: identity, asRecipient: asRecipient),
            [firstTie, secondTie],
          );
          final reversed = CategoryMatcher.suggestCategoryFromRules(
            transaction(identity: identity, asRecipient: asRecipient),
            [secondTie, firstTie],
          );
          expect(forward, 'category-a-$i');
          expect(reversed, forward);
        }
      },
    );
    test('prefers recipient upsert when both identities match', () {
      // **Validates: Requirements 4.1, 4.2, 4.3**
      final transaction = TransactionInfo(
        account: AccountDetails(
          bankName: '  ACME PAY  ',
          sendTo: '  Alice  ',
          no: '  new-account  ',
        ),
        money: '42.00',
        address: '',
        sender: '',
        body: '',
      );
      final merchantRule = CategoryRule(
        merchantName: 'acme pay',
        categoryId: 'merchant-category',
      )..id = 1;
      final recipientRule = CategoryRule(
        recipientName: 'alice',
        merchantName: 'legacy merchant',
        accountNumber: 'legacy-account',
        amountMin: 10,
        amountMax: 50,
        categoryId: 'old-category',
        matchCount: 99,
        confidence: 95,
      )..id = 2;
      final originalLastUsed = DateTime(2020, 1, 1);
      recipientRule.lastUsed = originalLastUsed;

      final updated = CategoryMatcher.createOrUpdateRule(
        transaction,
        'corrected-category',
        [merchantRule, recipientRule],
      );

      expect(updated, same(recipientRule));
      expect(updated.categoryId, 'corrected-category');
      expect(updated.matchCount, 100);
      expect(updated.confidence, 100);
      expect(updated.recipientName, 'alice');
      expect(updated.merchantName, 'legacy merchant');
      expect(updated.accountNumber, 'legacy-account');
      expect(updated.amountMin, 10);
      expect(updated.amountMax, 50);
      expect(updated.lastUsed.isAfter(originalLastUsed), isTrue);
      expect(merchantRule.categoryId, 'merchant-category');
    });
  });
}

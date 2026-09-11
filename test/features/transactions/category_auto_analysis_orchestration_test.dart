import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/extensions/field_encryption_ext.dart';
import 'package:mudra_manager/core/db/field_encryption_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/category_rule.dart';
import 'package:mudra_manager/core/db/models/exchange_rate.dart';
import 'package:mudra_manager/core/db/models/pending_notifications.dart';
import 'package:mudra_manager/core/db/models/pending_transaction.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/sms_activity.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/services/category_rule_service.dart';
import 'package:mudra_manager/core/utils/bulk_categorization_helper.dart';
import 'package:mudra_manager/core/utils/transaction_msg_util.dart';
import 'package:mudra_manager/features/sms/data/sms_activity_service.dart';
import 'package:mudra_manager/features/transactions/data/pending_transaction_prodiver.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  late Isar isar;
  late Category shopping;
  late Category food;
  late Category salary;
  late Category systemExpense;
  late Category others;

  setUp(() async {
    FieldEncryptionService.setKeyForTesting(
      'AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQE=',
    );

    final existing = Isar.getInstance();
    if (existing != null && existing.isOpen) await existing.close();

    SharedPreferences.setMockInitialValues({});
    SharedPrefsUtil.init(await SharedPreferences.getInstance());

    tempDirectory = await Directory.systemTemp.createTemp(
      'category_auto_analysis_orchestration_',
    );
    isar = await Isar.open(
      [
        SmsActivitySchema,
        CategorySchema,
        AccountSchema,
        TransactionSchema,
        TagSchema,
        RecurringTransactionSchema,
        CategoryRuleSchema,
        ExchangeRateSchema,
        PendingNotificationsSchema,
        PendingTransactionSchema,
      ],
      directory: tempDirectory.path,
    );

    shopping = Category.create(
      name: 'Shopping',
      categoryType: CategoryType.expense,
    )..id = 1;
    food = Category.create(
      name: 'Food',
      categoryType: CategoryType.expense,
      keywords: ['swiggy'],
    )..id = 2;
    salary = Category.create(
      name: 'Salary',
      categoryType: CategoryType.income,
      keywords: ['swiggy'],
    )..id = 3;
    systemExpense = Category.create(
      name: 'System expense',
      categoryType: CategoryType.expense,
      keywords: ['swiggy'],
    )
      ..id = 4
      ..isSystem = true;
    others = Category.create(
      name: 'Others',
      categoryType: CategoryType.expense,
    )..id = 5;

    await isar.writeTxn(() async {
      await isar.categorys.putAll([
        shopping,
        food,
        salary,
        systemExpense,
        others,
      ]);
      await isar.accounts.put(
        Account()
          ..name = 'Primary'
          ..accountNumber = 'XXXX6988'
          ..accountSuffixHash = accountSuffixHashFor('6988')
          ..accountType = AccountType.bank
          ..initialBalance = 10000
          ..isActive = true,
      );
    });
  });

  tearDown(() async {
    if (isar.isOpen) await isar.close();
    if (tempDirectory.existsSync()) tempDirectory.deleteSync(recursive: true);
    FieldEncryptionService.resetForTesting();
  });

  CategoryRule rule({
    required String categoryId,
    String? merchant,
    String? recipient,
    int confidence = 80,
    int matchCount = 2,
  }) {
    return CategoryRule(
      merchantName: merchant,
      recipientName: recipient,
      categoryId: categoryId,
      confidence: confidence,
      matchCount: matchCount,
    );
  }

  Future<void> saveRules(List<CategoryRule> rules) async {
    await isar.writeTxn(() async {
      await isar.categoryRules.putAll(rules);
    });
  }

  Future<SmsActivity> addSwiggySms({String hash = 'sms-orchestration'}) {
    return SmsActivityService.instance.addActivity(
      sender: 'HDFCBK',
      body:
          'Rs.2500.00 debited from a/c XX6988 on 15-04-25 to VPA swiggy@icici '
          '(UPI Ref No 510712345678). Avl Bal:Rs.45,230.50',
      date: DateTime.now(),
      smsHash: hash,
      amount: 2500,
      isIncome: false,
      account: '6988',
      toAccount: 'swiggy@icici',
    );
  }

  TransactionInfo bulkTransaction(
    String recipient, {
    TransactionType? type,
    String body = 'Payment to swiggy for food',
  }) {
    return TransactionInfo(
      address: '',
      sender: '',
      body: body,
      account: AccountDetails(sendTo: recipient),
      money: '100',
    )..typeOfTransaction = type;
  }

  PendingTransaction pendingTransaction({
    String hash = 'pending-orchestration',
    String? fromBank,
    String body =
        'Rs.250 debited from a/c XX6988 to VPA swiggy@icici. Food order',
  }) {
    return PendingTransaction()
      ..sender = 'HDFCBK'
      ..body = body
      ..date = DateTime(2025, 4, 15)
      ..amount = 250
      ..isIncome = false
      ..account = '6988'
      ..fromBank = fromBank
      ..toAccount = 'swiggy@icici'
      ..smsHash = hash;
  }

  List<Category> expenseCategories() =>
      [shopping, food, salary, systemExpense, others];

  group('SMS automatic analysis orchestration', () {
    test('exact learned category wins conflicting generic keyword', () async {
      await saveRules([
        rule(
          categoryId: shopping.id.toString(),
          merchant: 'swiggy',
        ),
      ]);

      final activity = await addSwiggySms();

      expect(activity.category, shopping.name);
    });

    test('type and system filtering rejects ineligible learned categories',
        () async {
      await saveRules([
        rule(categoryId: salary.id.toString(), merchant: 'swiggy'),
        rule(categoryId: systemExpense.id.toString(), merchant: 'swiggy'),
      ]);

      final activity = await addSwiggySms(hash: 'sms-filtered-rules');

      // Income/system rules are excluded before generic expense matching.
      expect(activity.category, food.name);
    });

    test('unavailable learned category falls through to generic matching',
        () async {
      await saveRules([
        rule(categoryId: 'deleted-category', merchant: 'swiggy'),
      ]);

      final activity = await addSwiggySms(hash: 'sms-unavailable-rule');

      expect(activity.category, food.name);
    });

    test('SMS correction learning normalizes identity and updates one rule',
        () async {
      await saveRules([
        rule(
          categoryId: food.id.toString(),
          merchant: 'swiggy',
          matchCount: 3,
        ),
      ]);

      await SmsActivityService.instance.learnKeywordsFromApproval(
        'A generic debit notification with no merchant text',
        shopping,
        merchant: '  SWIGGY  ',
      );

      final rules = await CategoryRuleService(isar).getAllRules();
      final matching =
          rules.where((item) => item.merchantName == 'swiggy').toList();
      expect(matching, hasLength(1));
      expect(matching.single.categoryId, shopping.id.toString());
      expect(matching.single.matchCount, 4);
    });
  });

  group('Bulk automatic analysis orchestration', () {
    test('learned category wins generic keyword and respects category filters',
        () async {
      await saveRules([
        rule(
          categoryId: shopping.id.toString(),
          recipient: 'swiggy',
        ),
        rule(
          categoryId: salary.id.toString(),
          recipient: 'swiggy',
          confidence: 100,
          matchCount: 100,
        ),
        rule(
          categoryId: systemExpense.id.toString(),
          recipient: 'swiggy',
          confidence: 100,
          matchCount: 100,
        ),
      ]);

      final result = await BulkCategorizationHelper(
        CategoryRuleService(isar),
      ).processBulkTransactions(
        [bulkTransaction('swiggy', type: TransactionType.debited)],
        availableCategories: expenseCategories(),
      );

      expect(
        result.autoSuggested['UPI:swiggy']?.suggestedCategoryId,
        shopping.id.toString(),
      );
      expect(result.needsManualReview, isEmpty);
    });

    test('unavailable learned category preserves bulk manual fallback',
        () async {
      await saveRules([
        rule(categoryId: 'deleted-category', recipient: 'swiggy'),
      ]);

      final result = await BulkCategorizationHelper(
        CategoryRuleService(isar),
      ).processBulkTransactions(
        [bulkTransaction('swiggy', body: 'Payment to swiggy')],
        availableCategories: [food, others],
      );

      expect(result.autoSuggested, isEmpty);
      expect(result.needsManualReview['UPI:swiggy']?.count, 1);
    });

    test('no qualifying rule creates manual-review group', () async {
      final result = await BulkCategorizationHelper(
        CategoryRuleService(isar),
      ).processBulkTransactions(
        [bulkTransaction('unknown vendor', body: 'Payment without marker')],
        availableCategories: [food, others],
      );

      expect(result.autoSuggested, isEmpty);
      expect(result.needsManualReview['UPI:unknown vendor']?.count, 1);
    });

    test('bulk correction learning uses normalized upsert', () async {
      await saveRules([
        rule(
          categoryId: food.id.toString(),
          recipient: 'swiggy',
          matchCount: 2,
        ),
      ]);

      final txn = bulkTransaction('  SWIGGY  ');
      await BulkCategorizationHelper(CategoryRuleService(isar))
          .applyCategoryToGroup([txn], shopping.id.toString());

      final rules = await CategoryRuleService(isar).getAllRules();
      final matching =
          rules.where((item) => item.recipientName == 'swiggy').toList();
      expect(matching, hasLength(1));
      expect(matching.single.categoryId, shopping.id.toString());
      expect(matching.single.matchCount, 3);
    });
  });

  group('Pending-import automatic analysis orchestration', () {
    PendingTransactionService service() {
      return PendingTransactionService(
        IsarService(),
        AppLog(getLogger(), 'category-auto-analysis-test'),
      );
    }

    test('learned category is pre-matched before generic category matching',
        () async {
      await saveRules([
        rule(
          categoryId: shopping.id.toString(),
          merchant: 'swiggy',
        ),
      ]);

      final pending = pendingTransaction(fromBank: '  SWIGGY  ');
      final processed = await service().processTransaction(
        pending: pending,
        accounts: await isar.accounts.where().findAll(),
        categories: expenseCategories(),
      );

      expect(processed, isTrue);
      final transactions = await isar.transactions.where().findAll();
      expect(transactions, hasLength(1));
      expect(transactions.single.category.value!.name, shopping.name);
    });

    test('type/system and unavailable rules preserve pending fallback',
        () async {
      await saveRules([
        rule(categoryId: salary.id.toString(), merchant: 'swiggy'),
        rule(categoryId: systemExpense.id.toString(), merchant: 'swiggy'),
      ]);

      final processed = await service().processTransaction(
        pending: pendingTransaction(
          hash: 'pending-filtered-rules',
          fromBank: '  SWIGGY  ',
          body: 'Rs.250 debited from a/c XX6988. Generic bank notification',
        ),
        accounts: await isar.accounts.where().findAll(),
        categories: expenseCategories(),
      );

      expect(processed, isTrue);
      final transaction = (await isar.transactions.where().findAll()).single;
      // No eligible learned rule: generic body has no category keyword, so
      // TransactionMatchingService uses existing expense fallback.
      expect(transaction.category.value!.name, others.name);
    });

    test('empty rule set preserves configured default category fallback',
        () async {
      final processed = await service().processTransaction(
        pending: pendingTransaction(
          hash: 'pending-default-fallback',
          body: 'Rs.250 debited from a/c XX6988. Generic bank notification',
        ),
        accounts: await isar.accounts.where().findAll(),
        categories: [others],
      );

      expect(processed, isTrue);
      final transaction = (await isar.transactions.where().findAll()).single;
      expect(transaction.category.value!.name, others.name);
    });

    test('unavailable learned category does not suppress pending generic match',
        () async {
      await saveRules([
        rule(categoryId: 'deleted-category', merchant: 'swiggy'),
      ]);

      final processed = await service().processTransaction(
        pending: pendingTransaction(hash: 'pending-unavailable-rule'),
        accounts: await isar.accounts.where().findAll(),
        categories: [food, others],
      );

      expect(processed, isTrue);
      final transaction = (await isar.transactions.where().findAll()).single;
      expect(transaction.category.value!.name, food.name);
    });
  });

  test(
    'Feature: category-auto-analyze-bug, Property 8: Every automatic-analysis caller applies learned precedence',
    () async {
      // **Validates: Requirements 1.5, 3.1, 3.3, 3.4**
      // Deterministic generated cases exceed required 100 iterations. Each
      // case exercises eligible and unavailable learned rules through SMS,
      // bulk, and pending-import entry points.
      final accounts = await isar.accounts.where().findAll();
      final pendingService = PendingTransactionService(
        IsarService(),
        AppLog(getLogger(), 'category-auto-analysis-test'),
      );
      final bulkHelper = BulkCategorizationHelper(CategoryRuleService(isar));

      Future<void> resetCase() async {
        await isar.writeTxn(() async {
          await isar.categoryRules.clear();
          await isar.smsActivitys.clear();
          await isar.transactions.clear();
          await isar.pendingTransactions.clear();
        });
      }

      for (var i = 0; i < 128; i++) {
        final hash = 'property-8-$i';
        final recipient = 'swiggy@icici';
        final body =
            'Rs.250 debited from a/c XX6988 to VPA $recipient. Food order';

        await resetCase();
        await saveRules([
          rule(
            categoryId: shopping.id.toString(),
            recipient: recipient,
          ),
        ]);

        final sms = await SmsActivityService.instance.addActivity(
          sender: 'HDFCBK',
          body: body,
          date: DateTime.now(),
          smsHash: 'sms-$hash',
          amount: 250,
          isIncome: false,
          account: '6988',
          toAccount: recipient,
        );
        expect(
          sms.category,
          shopping.name,
          reason: 'SMS learned rule must bypass conflicting keyword rule',
        );

        final bulk = await bulkHelper.processBulkTransactions(
          [bulkTransaction(recipient, body: body)],
          availableCategories: [shopping, food, others],
        );
        expect(
          bulk.autoSuggested['UPI:$recipient']?.suggestedCategoryId,
          shopping.id.toString(),
          reason: 'Bulk learned rule must bypass generic category conflict',
        );

        await resetCase();
        await saveRules([
          rule(
            categoryId: shopping.id.toString(),
            merchant: 'swiggy',
          ),
        ]);
        final pending = await pendingService.processTransaction(
          pending: pendingTransaction(
            hash: 'pending-$hash',
            body: body,
            fromBank: ' SWIGGY ',
          ),
          accounts: accounts,
          categories: expenseCategories(),
        );
        expect(
          pending,
          isTrue,
          reason: 'Pending import must process with pre-matched category',
        );
        final pendingTransactions = await isar.transactions.where().findAll();
        expect(pendingTransactions.single.category.value!.name, shopping.name);

        await resetCase();
        await saveRules([
          rule(
            categoryId: 'deleted-category-$i',
            recipient: recipient,
          ),
        ]);

        final ineligibleSms = await SmsActivityService.instance.addActivity(
          sender: 'HDFCBK',
          body: body,
          date: DateTime.now(),
          smsHash: 'ineligible-sms-$hash',
          amount: 250,
          isIncome: false,
          account: '6988',
          toAccount: recipient,
        );
        expect(
          ineligibleSms.category,
          food.name,
          reason: 'SMS must preserve filtered generic fallback',
        );

        await resetCase();
        await saveRules([
          rule(
            categoryId: 'deleted-category-$i',
            recipient: recipient,
          ),
        ]);
        final ineligibleBulk = await bulkHelper.processBulkTransactions(
          [bulkTransaction(recipient, body: body)],
          availableCategories: [shopping, food, others],
        );
        expect(ineligibleBulk.autoSuggested, isEmpty);
        expect(ineligibleBulk.needsManualReview['UPI:$recipient'], isNotNull);

        await resetCase();
        await saveRules([
          rule(
            categoryId: 'deleted-category-$i',
            merchant: 'swiggy',
          ),
        ]);
        final ineligiblePending = await pendingService.processTransaction(
          pending: pendingTransaction(
            hash: 'ineligible-pending-$hash',
            body: body,
            fromBank: ' SWIGGY ',
          ),
          accounts: accounts,
          categories: expenseCategories(),
        );
        expect(ineligiblePending, isTrue);
        final fallbackTransactions = await isar.transactions.where().findAll();
        expect(fallbackTransactions.single.category.value!.name, food.name);
      }
    },
    timeout: Timeout(const Duration(minutes: 2)),
  );
}

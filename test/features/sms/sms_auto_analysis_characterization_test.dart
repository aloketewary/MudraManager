import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/category_rule.dart';
import 'package:mudra_manager/core/db/models/exchange_rate.dart';
import 'package:mudra_manager/core/db/models/pending_notifications.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/sms_activity.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/features/sms/data/sms_activity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  late Isar isar;
  late Category learnedCategory;

  setUp(() async {
    final existing = Isar.getInstance();
    if (existing != null && existing.isOpen) await existing.close();

    SharedPreferences.setMockInitialValues({});
    SharedPrefsUtil.init(await SharedPreferences.getInstance());

    tempDirectory = await Directory.systemTemp.createTemp(
      'sms_auto_analysis_characterization_',
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
      ],
      directory: tempDirectory.path,
    );

    learnedCategory = Category()
      ..name = 'Shopping'
      ..iconName = 'shopping-bag'
      ..categoryType = CategoryType.expense;
    final genericCategory = Category()
      ..name = 'Food'
      ..iconName = 'utensils'
      ..categoryType = CategoryType.expense
      ..keywords = ['swiggy'];
    await isar.writeTxn(() async {
      await isar.categorys.putAll([learnedCategory, genericCategory]);
      await isar.accounts.put(
        Account()
          ..name = 'Primary'
          ..accountNumber = 'XXXX6988'
          ..accountType = AccountType.bank
          ..initialBalance = 10000
          ..isActive = true,
      );
    });
  });

  tearDown(() async {
    if (isar.isOpen) await isar.close();
    if (tempDirectory.existsSync()) tempDirectory.deleteSync(recursive: true);
  });

  test('learned merchant category wins current SMS generic-keyword conflict',
      () async {
    await isar.writeTxn(() async {
      await isar.categoryRules.put(
        CategoryRule(
          merchantName: 'swiggy',
          categoryId: learnedCategory.id.toString(),
          confidence: 80,
          matchCount: 2,
        ),
      );
    });

    final activity = await SmsActivityService.instance.addActivity(
      sender: 'HDFCBK',
      body:
          'Rs.2500.00 debited from a/c XX6988 on 15-04-25 to VPA swiggy@icici (UPI Ref No 510712345678). Avl Bal:Rs.45,230.50',
      date: DateTime.now(),
      smsHash: 'sms-characterization-1',
      amount: 2500,
      isIncome: false,
      account: '6988',
      toAccount: 'swiggy@icici',
    );

    // Characterization: learned lookup runs before robust keyword matching;
    // Food keyword would otherwise select genericCategory.
    expect(activity.category, 'Shopping');
  });

  test('unavailable learned category falls through to generic SMS matching',
      () async {
    await isar.writeTxn(() async {
      await isar.categoryRules.put(
        CategoryRule(
          merchantName: 'swiggy',
          categoryId: 'deleted-category-id',
          confidence: 80,
          matchCount: 2,
        ),
      );
    });

    final activity = await SmsActivityService.instance.addActivity(
      sender: 'HDFCBK',
      body:
          'Rs.2500.00 debited from a/c XX6988 on 15-04-25 to VPA swiggy@icici (UPI Ref No 510712345678). Avl Bal:Rs.45,230.50',
      date: DateTime.now(),
      smsHash: 'sms-characterization-2',
      amount: 2500,
      isIncome: false,
      account: '6988',
      toAccount: 'swiggy@icici',
    );

    expect(activity.category, 'Food');
  });
}

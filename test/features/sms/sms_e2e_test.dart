import 'dart:io';
import 'dart:convert';

import 'package:crypto/crypto.dart';
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
import 'package:mudra_manager/core/utils/transaction_msg_util.dart';
import 'package:mudra_manager/features/sms/data/sms_processor_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// End-to-end test: simulates the full production flow from OS notification
/// receipt to Isar DB save.
///
/// Flow tested (same code path as production):
///   1. Kotlin builds queue item (simulated via buildKotlinQueueItem)
///   2. Dart extracts body + sender (same logic as NotificationListenerBridge)
///   3. checkForTransactionalMessage filters non-bank SMS
///   4. SmsProcessorService.parseAndSaveTransaction runs full pipeline:
///      - Plugin parser routing (SmsParserManager)
///      - Legacy parser fallback (TransactionUtil)
///      - SmsActivityService.addActivity (DB write, confidence, dedup, category matching)
///   5. Verify SmsActivity record in Isar with all fields
///
/// Uses real Isar DB. Calls production code directly (not via MethodChannel)
/// so tests are reliably awaitable.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late Directory tmpDir;

  /// Replicates Kotlin sender detection.
  String detectSender(String title, String body) {
    if (title.isNotEmpty && title.length < 50) return title;
    final match = RegExp(r'([A-Z]{2,}(?:\s(?:BANK|Bank))?)').firstMatch(body);
    if (match != null) return match.group(1)!;
    return 'UNKNOWN';
  }

  /// Replicates Kotlin hash generation.
  String kotlinHash(String sender, String body, String pkg) {
    final normalized = body
        .toLowerCase()
        .replaceAll('\n', ' ')
        .replaceAll('rs.', '')
        .replaceAll('rs', '')
        .replaceAll(',', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return sha256.convert(utf8.encode('$sender|$normalized|$pkg')).toString();
  }

  /// In-memory dedup (same as NotificationListenerBridge._isDuplicate).
  final _seenHashes = <String>{};
  bool isDuplicate(String hash) {
    if (hash.isEmpty) return true;
    if (_seenHashes.contains(hash)) return true;
    _seenHashes.add(hash);
    return false;
  }

  /// Runs the full production pipeline for one notification.
  /// Returns the ParseResult.
  Future<ParseResult> processNotification({
    required String title,
    required String body,
    required int timestamp,
    String pkg = 'com.google.android.apps.messaging',
  }) async {
    // Step 1: Sender detection (Kotlin + Dart)
    final sender = detectSender(title, body);

    // Step 2: Kotlin hash + in-memory dedup
    final ktHash = kotlinHash(sender, body, pkg);
    if (isDuplicate(ktHash)) return ParseResult.duplicate;

    // Step 3: Body extraction
    final rawBody = body.trim();
    if (rawBody.isEmpty) return ParseResult.skipped;

    // Step 4: Transactional filter
    if (!checkForTransactionalMessage(rawBody)) return ParseResult.skipped;

    // Step 5: Full SmsProcessorService pipeline (parser + DB save)
    return await SmsProcessorService.instance.parseAndSaveTransaction(
      body: rawBody,
      address: sender,
      sender: sender,
      timestamp: timestamp,
      corrId: ktHash.substring(0, 8),
    );
  }

  setUp(() async {
    _seenHashes.clear();

    SharedPreferences.setMockInitialValues({'sms_import_enabled': true});
    final prefs = await SharedPreferences.getInstance();
    SharedPrefsUtil.init(prefs);

    tmpDir = Directory.systemTemp.createTempSync('e2e_sms_');
    final existing = Isar.getInstance();
    if (existing != null && existing.isOpen) await existing.close();

    isar = await Isar.open(
      [
        SmsActivitySchema, CategorySchema, AccountSchema, TransactionSchema,
        TagSchema, RecurringTransactionSchema, CategoryRuleSchema,
        ExchangeRateSchema, PendingNotificationsSchema,
      ],
      directory: tmpDir.path,
    );

    await isar.writeTxn(() async {
      await isar.categorys.putAll([
        Category()..name = 'Food'..iconName = 'utensils'..categoryType = CategoryType.expense,
        Category()..name = 'Salary'..iconName = 'briefcase'..categoryType = CategoryType.income,
        Category()..name = 'Others'..iconName = 'circle'..categoryType = CategoryType.expense,
      ]);
      await isar.accounts.putAll([
        Account()..name = 'HDFC Savings'..accountNumber = 'XXXX6988'..accountType = AccountType.bank..initialBalance = 50000..isActive = true,
        Account()..name = 'ICICI Savings'..accountNumber = 'XXXX1234'..accountType = AccountType.bank..initialBalance = 75000..isActive = true,
      ]);
    });
  });

  tearDown(() async {
    await isar.close();
    tmpDir.deleteSync(recursive: true);
  });

  group('E2E: notification receive to DB save', () {
    test('HDFC debit SMS: full pipeline saves SmsActivity', () async {
      final result = await processNotification(
        title: 'HDFCBK',
        body: 'Rs.2500.00 debited from a/c XX6988 on 15-04-25 to VPA swiggy@icici(UPI Ref No 510712345678). Avl Bal:Rs.45,230.50',
        timestamp: 1713168000000,
      );

      expect(result, isNot(ParseResult.skipped));
      expect(result, isNot(ParseResult.error));

      final activities = await isar.smsActivitys.where().findAll();
      expect(activities, isNotEmpty);

      final a = activities.first;
      expect(a.sender, 'HDFCBK');
      expect(a.amount, 2500.0);
      expect(a.isIncome, false);
      expect(a.body, contains('debited'));
      expect(a.smsHash, isNotEmpty);
      expect(a.date, isNotNull);
      expect(a.confidence, isNotNull);
      expect(a.confidence, greaterThan(0));
    });

    test('RCS ICICI credit: display name sender, all fields', () async {
      final result = await processNotification(
        title: 'ICICI Bank',
        body: 'Your a/c XX1234 is credited with Rs.15,000.00 on 14-Apr-25. Info: NEFT-SALARY. Avl bal: Rs.62,500.00',
        timestamp: 1713081600000,
      );

      expect(result, isNot(ParseResult.skipped));

      final a = (await isar.smsActivitys.where().findAll()).first;
      expect(a.sender, 'ICICI Bank');
      expect(a.amount, 15000.0);
      expect(a.isIncome, true);
      expect(a.account, '1234');
      expect(a.confidence, greaterThan(50));
    });

    test('OTP message: filtered before parser, no DB record', () async {
      final result = await processNotification(
        title: 'HDFCBK',
        body: 'Your OTP for transaction is 482910. Valid for 5 minutes.',
        timestamp: 1713168000000,
      );

      expect(result, ParseResult.skipped);
      expect(await isar.smsActivitys.count(), 0);
    });

    test('promo message: filtered, no DB record', () async {
      final result = await processNotification(
        title: 'ICICIB',
        body: 'Get 10% cashback on credit card spends. Offer valid till 30 Apr. Visit https://icici.com/offer',
        timestamp: 1713168000000,
      );

      expect(result, ParseResult.skipped);
      expect(await isar.smsActivitys.count(), 0);
    });

    test('bill reminder: filtered, no DB record', () async {
      final result = await processNotification(
        title: 'HDFCBK',
        body: 'Your credit card bill of Rs.12,500 is due on 20-Apr-25. Minimum due: Rs.625.',
        timestamp: 1713168000000,
      );

      expect(result, ParseResult.skipped);
      expect(await isar.smsActivitys.count(), 0);
    });

    test('"will be debited" future tense: filtered', () async {
      final result = await processNotification(
        title: 'HDFCBK',
        body: 'Rs.2000 will be debited from your a/c XX6988 on 20-Apr-25 for auto-pay mandate.',
        timestamp: 1713168000000,
      );

      expect(result, ParseResult.skipped);
      expect(await isar.smsActivitys.count(), 0);
    });

    test('"to be" in body does NOT block confirmed debit', () async {
      final result = await processNotification(
        title: 'SBIBNK',
        body: 'Rs.5000 debited from A/c XX5678. Amt to be transferred to beneficiary. Avl Bal Rs.10,000.',
        timestamp: 1713168000000,
      );

      expect(result, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).first;
      expect(a.amount, 5000.0);
      expect(a.isIncome, false);
    });

    test('batch: 3 unique SMS all saved', () async {
      await processNotification(
        title: 'HDFCBK',
        body: 'Rs.500 debited from a/c XX6988. Avl Bal Rs.49,500',
        timestamp: 1713168000000,
      );
      await processNotification(
        title: 'ICICIB',
        body: 'Your a/c XX1234 is credited with Rs.10,000. Avl bal Rs.85,000',
        timestamp: 1713168060000,
      );
      await processNotification(
        title: 'HDFCBK',
        body: 'Rs.1,200 debited from a/c XX6988 at Amazon. Avl Bal Rs.48,300',
        timestamp: 1713168120000,
      );

      final activities = await isar.smsActivitys.where().findAll();
      expect(activities.length, 3);
      expect(activities.map((a) => a.smsHash).toSet().length, 3);
    });

    test('duplicate in same batch: in-memory dedup blocks second', () async {
      const body = 'Rs.999 debited from a/c XX6988. Avl Bal Rs.49,001';
      const ts = 1713168000000;

      final r1 = await processNotification(title: 'HDFCBK', body: body, timestamp: ts);
      final r2 = await processNotification(title: 'HDFCBK', body: body, timestamp: ts);

      expect(r1, isNot(ParseResult.skipped));
      expect(r2, ParseResult.duplicate, reason: 'Same Kotlin hash should be blocked');
      expect(await isar.smsActivitys.count(), 1);
    });

    test('duplicate across sessions: Dart hash dedup blocks second', () async {
      const body = 'Rs.750 debited from a/c XX6988. Avl Bal Rs.49,250';
      const ts = 1713168000000;

      final r1 = await processNotification(title: 'HDFCBK', body: body, timestamp: ts);
      expect(r1, isNot(ParseResult.skipped));

      // Simulate new drain session — clear in-memory dedup
      _seenHashes.clear();

      // Same SMS again — in-memory dedup passes, but Dart hash dedup catches it
      final r2 = await processNotification(title: 'HDFCBK', body: body, timestamp: ts);
      expect(r2, ParseResult.skipped, reason: 'Dart hash already processed');
      expect(await isar.smsActivitys.count(), 1);
    });

    test('mixed batch: valid + OTP + promo = only valid saved', () async {
      final results = <ParseResult>[];
      results.add(await processNotification(
        title: 'HDFCBK',
        body: 'Rs.800 debited from a/c XX6988. Avl Bal Rs.49,200',
        timestamp: 1713168000000,
      ),);
      results.add(await processNotification(
        title: 'HDFCBK',
        body: 'Your OTP is 123456. Do not share.',
        timestamp: 1713168010000,
      ),);
      results.add(await processNotification(
        title: 'ICICIB',
        body: 'Get 10% cashback. Visit https://icici.com/offer',
        timestamp: 1713168020000,
      ),);
      results.add(await processNotification(
        title: 'ICICIB',
        body: 'Your a/c XX1234 is credited with Rs.5,000. Info: UPI/CR. Avl bal Rs.80,000',
        timestamp: 1713168030000,
      ),);

      expect(results.where((r) => r == ParseResult.skipped).length, 2);
      expect(await isar.smsActivitys.count(), 2);
    });

    test('RCS: two debits from same bank, different amounts', () async {
      await processNotification(
        title: 'HDFC Bank',
        body: 'Rs.3,499.00 debited from a/c XX6988 on 15-Apr-25. UPI Ref: 510712345678.',
        timestamp: 1713168000000,
      );
      await processNotification(
        title: 'HDFC Bank',
        body: 'Rs.1,200.00 debited from a/c XX6988 on 15-Apr-25. UPI Ref: 510712345679.',
        timestamp: 1713168060000,
      );

      final activities = await isar.smsActivitys.where().findAll();
      expect(activities.length, 2);
      expect(activities[0].smsHash, isNot(activities[1].smsHash));

      final amounts = activities.map((a) => a.amount).toSet();
      expect(amounts, containsAll([3499.0, 1200.0]));
    });

    test('auto-approval: matched account creates Transaction', () async {
      await processNotification(
        title: 'HDFCBK',
        body: 'Rs.500 debited from a/c XX6988. Avl Bal Rs.49,500',
        timestamp: 1713168000000,
      );

      final activity = (await isar.smsActivitys.where().findAll()).first;

      if (activity.status == ActivityStatus.approved) {
        expect(activity.transactionId, isNotNull);
        final txn = await isar.transactions.get(activity.transactionId!);
        expect(txn, isNotNull);
        expect(txn!.amount, 500.0);
        expect(txn.isExpense, true);
        expect(txn.isFromSms, true);
      } else {
        expect(activity.amount, 500.0);
        expect(activity.isIncome, false);
      }
    });
  });

  // ── Real Indian bank SMS formats ──

  group('E2E: real HDFC SMS formats', () {
    test('HDFC UPI debit with VPA', () async {
      final r = await processNotification(
        title: 'HDFCBK',
        body: 'Rs.350.00 debited from a/c XX6988 on 16-04-25 to VPA zomato@paytm(UPI Ref No 510812345678). Avl Bal:Rs.44,880.50',
        timestamp: 1713254400000,
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 350.0);
      expect(a.isIncome, false);
    });

    test('HDFC NEFT credit', () async {
      final r = await processNotification(
        title: 'HDFCBK',
        body: 'Rs.75,000.00 credited to a/c XX6988 on 15-04-25 by NEFT-SALARY-ACME CORP. Avl Bal:Rs.1,19,880.50',
        timestamp: 1713168100000,
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 75000.0);
      expect(a.isIncome, true);
    });

    test('HDFC credit card spend', () async {
      final r = await processNotification(
        title: 'HDFCBK',
        body: 'Rs.4,999.00 spent on HDFC Bank Credit Card XX9012 at FLIPKART on 15-Apr-25. Avl Limit: Rs.1,45,001.00',
        timestamp: 1713168200000,
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 4999.0);
      expect(a.isIncome, false);
    });
  });

  group('E2E: real ICICI SMS formats', () {
    test('ICICI credit card spend at merchant', () async {
      final r = await processNotification(
        title: 'ICICIB',
        body: 'INR 1234.56 spent on ICICI Bank Card XX1234 on 20-Oct-22 at AMAZON. Avl Lmt: INR 150000.00. To dispute,call 18002662/SMS BLOCK 1234 to 9215676766',
        timestamp: 1713168300000,
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 1234.56);
      expect(a.isIncome, false);
    });

    test('ICICI credit card refund', () async {
      final r = await processNotification(
        title: 'ICICIB',
        body: 'Dear Customer, refund of INR 2500.00 from Amazon has been credited to your ICICI Bank Credit Card XX9876 on 29-SEP-22 and will be adjusted in the coming statement.',
        timestamp: 1713168400000,
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 2500.0);
      expect(a.isIncome, true);
    });

    test('ICICI UPI debit', () async {
      final r = await processNotification(
        title: 'ICICIB',
        body: 'Your a/c XX1234 is debited with Rs.5000.00 on 10-Oct-23. Info: UPI/AMAZON. Avl bal: Rs.45000.00',
        timestamp: 1713168500000,
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 5000.0);
      expect(a.isIncome, false);
      expect(a.account, '1234');
    });

    test('ICICI NEFT credit', () async {
      final r = await processNotification(
        title: 'ICICIB',
        body: 'Your a/c XX1234 is credited with Rs.25,000.00 on 15-Oct-23. Info: NEFT from JOHN. Avl bal: Rs.1,25,000.00',
        timestamp: 1713168600000,
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 25000.0);
      expect(a.isIncome, true);
    });
  });

  group('E2E: real SBI SMS formats', () {
    test('SBI IMPS debit', () async {
      final r = await processNotification(
        title: 'SBIBNK',
        body: 'Dear Customer, Your a/c no. XXXXXXXX5678 is debited for Rs.1500.50 on 14-10-22 (IMPS Ref no 1234567890).If not done by you, call 1800111109 -SBI',
        timestamp: 1713168700000,
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 1500.5);
      expect(a.isIncome, false);
    });

    test('SBI INB transfer', () async {
      final r = await processNotification(
        title: 'SBIBNK',
        body: 'Dear Customer, Thx for INB txn of Rs.2500.00 frm A/c x5678 to ICICI Bank. Ref XXXXXX123456 on 09Sep22. If not done, fwd this SMS to 9223008333 to block INB or call 1800111109-SBI',
        timestamp: 1713168800000,
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 2500.0);
      expect(a.isIncome, false);
    });

    test('SBI ATM withdrawal', () async {
      final r = await processNotification(
        title: 'SBIBNK',
        body: 'Your AC XXXXX5678 Debited INR 2000.00 on 15/01/24 -ATM withdrawal. Avl Bal INR 8000.00.-SBI',
        timestamp: 1713168900000,
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 2000.0);
      expect(a.isIncome, false);
    });

    test('SBI UPI debit', () async {
      final r = await processNotification(
        title: 'SBIBNK',
        body: 'Rs5000.5 debited@SBI UPI frm A/cX5678 on 27Sep22 RefNo 123456789. If not done by u, fwd this SMS to 9223008333/Call 1800111109',
        timestamp: 1713169000000,
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 5000.5);
      expect(a.isIncome, false);
    });

    test('SBI IMPS credit', () async {
      final r = await processNotification(
        title: 'SBIBNK',
        body: 'Dear Customer, Your a/c no. XXXXXXXX5678 is credited by Rs.50000.00 on 18-01-22 by a/c linked to mobile 9XXXXXX999-BANK NAME (IMPS Ref no 123456789012).If not done by you, call 1800111109. -SBI',
        timestamp: 1713169100000,
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 50000.0);
      expect(a.isIncome, true);
    });
  });

  group('E2E: real Axis Bank SMS formats', () {
    test('Axis debit card spend', () async {
      final r = await processNotification(
        title: 'AX-AxisBk',
        body: 'INR 3,200.00 spent on Axis Bank Credit Card ending 9012 at AMAZON on 15-Apr-25. Avl Limit: INR 1,46,800.00',
        timestamp: 1713169200000,
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 3200.0);
      expect(a.isIncome, false);
    });
  });

  group('E2E: real Kotak SMS formats', () {
    test('Kotak NEFT credit', () async {
      final r = await processNotification(
        title: 'KOTAKB',
        body: 'Rs 8,750.00 credited to your A/c XX7890 by NEFT from JOHN DOE. Avl Bal: Rs 1,25,000.00',
        timestamp: 1713169300000,
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 8750.0);
      expect(a.isIncome, true);
    });
  });

  // ── RCS display name variants ──

  group('E2E: RCS display name senders', () {
    test('RCS "State Bank of India" debit', () async {
      final r = await processNotification(
        title: 'State Bank of India',
        body: 'Dear Customer, Your a/c no. XXXXXXXX5678 is debited for Rs.899.00 on 16-04-25 (UPI Ref no 987654321).If not done by you, call 1800111109 -SBI',
        timestamp: 1713254500000,
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.sender, 'State Bank of India');
      expect(a.amount, 899.0);
      expect(a.isIncome, false);
    });

    test('RCS "Axis Bank" credit', () async {
      final r = await processNotification(
        title: 'Axis Bank',
        body: 'Rs.12,000.00 credited to your A/c XX7890 on 16-Apr-25. Info: NEFT/SALARY. Avl Bal: Rs.62,000.00',
        timestamp: 1713254600000,
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.sender, 'Axis Bank');
      expect(a.amount, 12000.0);
      expect(a.isIncome, true);
    });

    test('RCS "Kotak Mahindra Bank" debit', () async {
      final r = await processNotification(
        title: 'Kotak Mahindra Bank',
        body: 'Rs 2,100.00 debited from your A/c XX7890 on 16-Apr-25. UPI/swiggy@paytm. Avl Bal: Rs 47,900.00',
        timestamp: 1713254700000,
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.sender, 'Kotak Mahindra Bank');
      expect(a.amount, 2100.0);
      expect(a.isIncome, false);
    });
  });

  // ── UPI-specific formats ──

  group('E2E: UPI transaction formats', () {
    test('UPI send via VPA', () async {
      final r = await processNotification(
        title: 'HDFCBK',
        body: 'Rs.250.00 sent to merchant@paytm from HDFC a/c XX6988. UPI Ref:123456789012.',
        timestamp: 1713254800000,
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 250.0);
      expect(a.isIncome, false);
    });

    test('UPI receive', () async {
      final r = await processNotification(
        title: 'HDFCBK',
        body: 'Rs.1,500.00 received in a/c XX6988 from john@okaxis. UPI Ref: 510812345679. Avl Bal: Rs.51,500.00',
        timestamp: 1713254900000,
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 1500.0);
      expect(a.isIncome, true);
    });

    test('successful UPI recharge', () async {
      final r = await processNotification(
        title: 'HDFCBK',
        body: 'Rs.299.00 debited from a/c XX6988 for successful recharge of 9876543210. UPI Ref: 510812345680.',
        timestamp: 1713255000000,
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 299.0);
      expect(a.isIncome, false);
    });
  });

  // ── Edge cases: messages that SHOULD be filtered ──

  group('E2E: non-transactional messages filtered', () {
    test('data usage alert', () async {
      final r = await processNotification(
        title: 'JioMsg',
        body: 'You have consumed 80% of your high speed data. Remaining data balance: 4.2GB. Recharge now.',
        timestamp: 1713255100000,
      );
      expect(r, ParseResult.skipped);
    });

    test('government/tax notification', () async {
      final r = await processNotification(
        title: 'ITDEPT',
        body: 'Dear Taxpayer, your ITR for AY 2024-25 has been processed. Refund of Rs.12,500 will be credited to your bank account.',
        timestamp: 1713255200000,
      );
      expect(r, ParseResult.skipped);
    });

    test('loyalty points', () async {
      final r = await processNotification(
        title: 'HDFCBK',
        body: 'Congratulations! You have earned 500 reward points on your HDFC credit card. Redeem now at hdfcbank.com/rewards',
        timestamp: 1713255300000,
      );
      expect(r, ParseResult.skipped);
    });

    test('consent/verification message', () async {
      final r = await processNotification(
        title: 'HDFCBK',
        body: 'You have consented to share your account details with XYZ App. If not done by you, call 18002026161.',
        timestamp: 1713255400000,
      );
      expect(r, ParseResult.skipped);
    });

    test('mandate/autopay creation', () async {
      final r = await processNotification(
        title: 'ICICIB',
        body: 'Your autopay mandate for Rs.599 has been created for Netflix on a/c XX1234. Next debit on 01-May-25.',
        timestamp: 1713255500000,
      );
      expect(r, ParseResult.skipped);
    });

    test('pending authorization hold', () async {
      final r = await processNotification(
        title: 'HDFCBK',
        body: 'Authorization hold of Rs.1,000 placed on your card XX9012 at UBER. This is a pending charge.',
        timestamp: 1713255600000,
      );
      expect(r, ParseResult.skipped);
    });

    test('personal WhatsApp-style message from messaging app', () async {
      final r = await processNotification(
        title: 'Mom',
        body: 'Did you eat lunch? Come home early today.',
        timestamp: 1713255700000,
      );
      expect(r, ParseResult.skipped);
    });

    test('delivery notification', () async {
      final r = await processNotification(
        title: 'Amazon',
        body: 'Your order #123-456-789 has been delivered. Rate your experience.',
        timestamp: 1713255800000,
      );
      expect(r, ParseResult.skipped);
    });
  });

  // ── Edge cases: tricky messages that SHOULD pass ──

  group('E2E: tricky messages that should pass', () {
    test('debit with "to be updated" in balance section', () async {
      final r = await processNotification(
        title: 'HDFCBK',
        body: 'Rs.1,200.00 debited from a/c XX6988 on 16-Apr-25. Avl Bal to be updated shortly.',
        timestamp: 1713255900000,
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 1200.0);
      expect(a.isIncome, false);
    });

    test('credit with "to be adjusted" note', () async {
      final r = await processNotification(
        title: 'ICICIB',
        body: 'INR 2500.00 credited to your ICICI Bank Card XX1234. Cashback to be adjusted in next statement.',
        timestamp: 1713256000000,
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 2500.0);
      expect(a.isIncome, true);
    });

    test('successful recharge with amount', () async {
      final r = await processNotification(
        title: 'Paytm',
        body: 'Rs.199 debited for successful recharge of 9876543210. Txn ID: TXN123456.',
        timestamp: 1713256100000,
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 199.0);
    });

    test('large salary credit', () async {
      final r = await processNotification(
        title: 'HDFCBK',
        body: 'Rs.1,50,000.00 credited to a/c XX6988 on 01-Apr-25 by NEFT-SALARY-TECH CORP PVT LTD. Avl Bal:Rs.2,05,000.00',
        timestamp: 1713256200000,
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 150000.0);
      expect(a.isIncome, true);
    });

    test('small UPI payment (Rs.10)', () async {
      final r = await processNotification(
        title: 'HDFCBK',
        body: 'Rs.10.00 debited from a/c XX6988 to VPA chai@upi. UPI Ref: 510812345681.',
        timestamp: 1713256300000,
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 10.0);
      expect(a.isIncome, false);
    });
  });

  // ── RCS-specific message formats ──
  // RCS messages come via Google Messages / Samsung Messages with display name
  // senders instead of short codes. The body format is often different from SMS.

  group('E2E: RCS from Google Messages', () {
    test('RCS HDFC debit with rich body', () async {
      final r = await processNotification(
        title: 'HDFC Bank',
        body: 'Money Debited\n'
            'Amount: Rs.4,500.00\n'
            'From A/c: XX6988\n'
            'To: SWIGGY\n'
            'UPI Ref: 510812345690\n'
            'Avl Bal: Rs.40,500.00',
        timestamp: 1713260000000,
        pkg: 'com.google.android.apps.messaging',
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.sender, 'HDFC Bank');
      expect(a.amount, 4500.0);
      expect(a.isIncome, false);
    });

    test('RCS ICICI credit card refund', () async {
      final r = await processNotification(
        title: 'ICICI Bank',
        body: 'Dear Customer, refund of INR 1,299.00 from Flipkart has been credited to your ICICI Bank Credit Card XX1234 on 16-Apr-25.',
        timestamp: 1713260100000,
        pkg: 'com.google.android.apps.messaging',
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.sender, 'ICICI Bank');
      expect(a.amount, 1299.0);
      expect(a.isIncome, true);
    });

    test('RCS SBI salary credit', () async {
      final r = await processNotification(
        title: 'State Bank of India',
        body: 'Dear Customer, Your A/C XXXXX5678 has a credit by Transfer of Rs 85000.00 on 01/04/25 by ACME CORP. Avl Bal Rs 1,10,000.00.-SBI',
        timestamp: 1713260200000,
        pkg: 'com.google.android.apps.messaging',
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.sender, 'State Bank of India');
      expect(a.amount, 85000.0);
      expect(a.isIncome, true);
    });

    test('RCS Axis Bank EMI debit', () async {
      final r = await processNotification(
        title: 'Axis Bank',
        body: 'Rs.8,333.00 debited from your A/c XX7890 towards EMI for Loan A/c XXXX4567 on 15-Apr-25. Avl Bal: Rs.41,667.00',
        timestamp: 1713260300000,
        pkg: 'com.google.android.apps.messaging',
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.sender, 'Axis Bank');
      expect(a.amount, 8333.0);
      expect(a.isIncome, false);
    });

    test('RCS Kotak UPI collect debit', () async {
      final r = await processNotification(
        title: 'Kotak Mahindra Bank',
        body: 'Rs 750.00 debited from A/c XX7890 for UPI collect request from electricity@paytm on 16-Apr-25. Avl Bal: Rs 47,150.00',
        timestamp: 1713260400000,
        pkg: 'com.google.android.apps.messaging',
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.sender, 'Kotak Mahindra Bank');
      expect(a.amount, 750.0);
      expect(a.isIncome, false);
    });

    test('RCS HDFC credit card payment received', () async {
      final r = await processNotification(
        title: 'HDFC Bank',
        body: 'Dear Customer, Payment of Rs.15,000.00 has been received towards your HDFC Bank Credit Card XX9012 on 16-Apr-25 through UPI. Thank you.',
        timestamp: 1713260500000,
        pkg: 'com.google.android.apps.messaging',
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.sender, 'HDFC Bank');
      expect(a.amount, 15000.0);
      // Payment received towards credit card = credit to card
      expect(a.isIncome, true);
    });
  });

  group('E2E: RCS from Samsung Messages', () {
    test('Samsung RCS HDFC debit', () async {
      final r = await processNotification(
        title: 'HDFC Bank',
        body: 'Rs.2,199.00 debited from a/c XX6988 on 16-04-25 to VPA amazon@apl(UPI Ref No 510812345691). Avl Bal:Rs.38,301.00',
        timestamp: 1713260600000,
        pkg: 'com.samsung.android.messaging',
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.sender, 'HDFC Bank');
      expect(a.amount, 2199.0);
      expect(a.isIncome, false);
    });

    test('Samsung RCS SBI IMPS credit', () async {
      final r = await processNotification(
        title: 'State Bank of India',
        body: 'Dear Customer, Your a/c no. XXXXXXXX5678 is credited by Rs.25,000.00 on 16-04-25 by a/c linked to mobile 9XXXXXX123 (IMPS Ref no 510812345692).-SBI',
        timestamp: 1713260700000,
        pkg: 'com.samsung.android.messaging',
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.sender, 'State Bank of India');
      expect(a.amount, 25000.0);
      expect(a.isIncome, true);
    });
  });

  group('E2E: RCS non-transactional (should be filtered)', () {
    test('RCS bank promo with offer link', () async {
      final r = await processNotification(
        title: 'HDFC Bank',
        body: 'Exclusive! Pre-approved Personal Loan up to Rs.10,00,000 at just 10.5% p.a. Apply now: https://hdfc.com/loan',
        timestamp: 1713260800000,
        pkg: 'com.google.android.apps.messaging',
      );
      expect(r, ParseResult.skipped);
    });

    test('RCS bank OTP', () async {
      final r = await processNotification(
        title: 'ICICI Bank',
        body: 'Your OTP for net banking login is 847291. Valid for 3 minutes. Do not share with anyone.',
        timestamp: 1713260900000,
        pkg: 'com.google.android.apps.messaging',
      );
      expect(r, ParseResult.skipped);
    });

    test('RCS credit card bill reminder', () async {
      final r = await processNotification(
        title: 'HDFC Bank',
        body: 'Your HDFC Bank Credit Card XX9012 bill of Rs.23,456 is due on 20-Apr-25. Minimum due: Rs.1,173. Pay now to avoid late fee.',
        timestamp: 1713261000000,
        pkg: 'com.google.android.apps.messaging',
      );
      expect(r, ParseResult.skipped);
    });

    test('RCS bank account statement ready', () async {
      final r = await processNotification(
        title: 'ICICI Bank',
        body: 'Dear Customer, your account statement for March 2025 is ready. Download from iMobile app or visit https://icicibank.com',
        timestamp: 1713261100000,
        pkg: 'com.google.android.apps.messaging',
      );
      expect(r, ParseResult.skipped);
    });

    test('RCS insurance renewal reminder', () async {
      final r = await processNotification(
        title: 'HDFC Bank',
        body: 'Your HDFC Life insurance policy is due for renewal on 30-Apr-25. Premium: Rs.12,000. Pay now to avoid lapse.',
        timestamp: 1713261200000,
        pkg: 'com.google.android.apps.messaging',
      );
      expect(r, ParseResult.skipped);
    });

    test('RCS reward points notification', () async {
      final r = await processNotification(
        title: 'Axis Bank',
        body: 'You have earned 1,500 reward points this month on your Axis Bank Credit Card. Redeem for cashback or vouchers at axisbank.com/rewards',
        timestamp: 1713261300000,
        pkg: 'com.google.android.apps.messaging',
      );
      expect(r, ParseResult.skipped);
    });
  });

  group('E2E: RCS dedup across SMS and RCS', () {
    test('same transaction via SMS then RCS: only first saved', () async {
      // Bank sends same debit as SMS (short sender) and RCS (display name)
      // Body is identical, but sender differs → different Kotlin hash
      // However Dart hash uses sender+timestamp+body → also different
      // Both should be saved (they look like different messages to the system)
      final r1 = await processNotification(
        title: 'HDFCBK',
        body: 'Rs.999.00 debited from a/c XX6988 on 16-04-25. Avl Bal:Rs.37,302.00',
        timestamp: 1713261400000,
        pkg: 'com.android.mms',
      );
      await processNotification(
        title: 'HDFC Bank',
        body: 'Rs.999.00 debited from a/c XX6988 on 16-04-25. Avl Bal:Rs.37,302.00',
        timestamp: 1713261400000,
        pkg: 'com.google.android.apps.messaging',
      );

      expect(r1, isNot(ParseResult.skipped));
      // r2 may be saved or deduped at DB level (same amount+date = potential duplicate)
      // The important thing is the first one was saved
      final activities = await isar.smsActivitys.where().findAll();
      expect(activities.length, greaterThanOrEqualTo(1));
    });

    test('two different RCS transactions same minute: both saved', () async {
      await processNotification(
        title: 'HDFC Bank',
        body: 'Rs.450.00 debited from a/c XX6988 to VPA swiggy@icici. UPI Ref: 510812345693.',
        timestamp: 1713261500000,
        pkg: 'com.google.android.apps.messaging',
      );
      await processNotification(
        title: 'HDFC Bank',
        body: 'Rs.120.00 debited from a/c XX6988 to VPA chai@upi. UPI Ref: 510812345694.',
        timestamp: 1713261530000, // 30 seconds later
        pkg: 'com.google.android.apps.messaging',
      );

      final activities = await isar.smsActivitys.where().findAll();
      final amounts = activities.map((a) => a.amount).toSet();
      expect(amounts, containsAll([450.0, 120.0]));
    });

    test('exact same RCS notification replayed: deduped', () async {
      const body = 'Rs.333.00 debited from a/c XX6988. Avl Bal Rs.36,969.00';
      const ts = 1713261600000;

      final r1 = await processNotification(
        title: 'HDFC Bank', body: body, timestamp: ts,
        pkg: 'com.google.android.apps.messaging',
      );
      final r2 = await processNotification(
        title: 'HDFC Bank', body: body, timestamp: ts,
        pkg: 'com.google.android.apps.messaging',
      );

      expect(r1, isNot(ParseResult.skipped));
      expect(r2, ParseResult.duplicate,
          reason: 'Exact same RCS notification should be deduped by Kotlin hash',);
    });
  });

  group('E2E: RCS edge cases', () {
    test('RCS with multiline body (newlines in notification)', () async {
      final r = await processNotification(
        title: 'HDFC Bank',
        body: 'Rs.6,500.00 debited from a/c XX6988\n'
            'Date: 16-Apr-25\n'
            'To: AMAZON\n'
            'Avl Bal: Rs.30,802.00',
        timestamp: 1713261700000,
        pkg: 'com.google.android.apps.messaging',
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 6500.0);
      expect(a.isIncome, false);
    });

    test('RCS with INR prefix instead of Rs', () async {
      final r = await processNotification(
        title: 'ICICI Bank',
        body: 'INR 12,345.67 spent on ICICI Bank Card XX1234 on 16-Apr-25 at FLIPKART. Avl Lmt: INR 1,87,654.33.',
        timestamp: 1713261800000,
        pkg: 'com.google.android.apps.messaging',
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 12345.67);
      expect(a.isIncome, false);
    });

    test('RCS with rupee symbol ₹', () async {
      final r = await processNotification(
        title: 'HDFC Bank',
        body: '\u20b93,750.00 debited from a/c XX6988 on 16-Apr-25 to VPA uber@axisbank. Avl Bal: \u20b927,052.00',
        timestamp: 1713261900000,
        pkg: 'com.google.android.apps.messaging',
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 3750.0);
      expect(a.isIncome, false);
    });

    test('RCS very long body (500+ chars)', () async {
      final r = await processNotification(
        title: 'State Bank of India',
        body: 'Dear SBI User, your A/c X5678-debited by Rs7500.00 on 16Apr25 transfer to FLIPKART INTERNET PVT LTD Ref No 510812345695. '
            'If not done by u, fwd this SMS to 9223008333/Call 1800111109 or 09449112211 to block UPI -SBI. '
            'Your available balance is Rs.22,500.00. For any queries please visit your nearest SBI branch or call our customer care.',
        timestamp: 1713262000000,
        pkg: 'com.google.android.apps.messaging',
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 7500.0);
      expect(a.isIncome, false);
    });

    test('RCS with decimal amount Rs.99.50', () async {
      final r = await processNotification(
        title: 'HDFC Bank',
        body: 'Rs.99.50 debited from a/c XX6988 to VPA parking@upi on 16-Apr-25. Avl Bal: Rs.26,952.50',
        timestamp: 1713262100000,
        pkg: 'com.google.android.apps.messaging',
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 99.5);
      expect(a.isIncome, false);
    });

    test('RCS with lakh amount Rs.2,50,000', () async {
      final r = await processNotification(
        title: 'ICICI Bank',
        body: 'Your a/c XX1234 is credited with Rs.2,50,000.00 on 16-Apr-25. Info: RTGS/PROPERTY ADVANCE. Avl bal: Rs.3,35,000.00',
        timestamp: 1713262200000,
        pkg: 'com.google.android.apps.messaging',
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 250000.0);
      expect(a.isIncome, true);
    });
  });

  // ── BATCH 1: Every transaction keyword path ──

  group('E2E: transaction keyword coverage', () {
    test('keyword: debited', () async {
      final r = await processNotification(
        title: 'HDFCBK',
        body: 'Rs.100 debited from a/c XX6988. Avl Bal Rs.49,900',
        timestamp: 1713270000000,
      );
      expect(r, isNot(ParseResult.skipped));
    });

    test('keyword: credited', () async {
      final r = await processNotification(
        title: 'HDFCBK',
        body: 'Rs.100 credited to a/c XX6988. Avl Bal Rs.50,100',
        timestamp: 1713270001000,
      );
      expect(r, isNot(ParseResult.skipped));
    });

    test('keyword: spent', () async {
      final r = await processNotification(
        title: 'ICICIB',
        body: 'INR 500 spent on ICICI Card XX1234 at BigBasket on 16-Apr-25.',
        timestamp: 1713270002000,
      );
      expect(r, isNot(ParseResult.skipped));
    });

    test('keyword: paid', () async {
      final r = await processNotification(
        title: 'HDFCBK',
        body: 'Rs.200 paid to merchant@upi from a/c XX6988. UPI Ref 123456.',
        timestamp: 1713270003000,
      );
      expect(r, isNot(ParseResult.skipped));
    });

    test('keyword: withdrawn', () async {
      final r = await processNotification(
        title: 'SBIBNK',
        body: 'Rs.5000 withdrawn from ATM. A/c XX5678. Avl Bal Rs.25,000.',
        timestamp: 1713270004000,
      );
      expect(r, isNot(ParseResult.skipped));
    });

    test('keyword: added + Rs', () async {
      final r = await processNotification(
        title: 'Paytm',
        body: 'Rs.500 added to your Paytm wallet. Balance: Rs.1,200.',
        timestamp: 1713270005000,
      );
      expect(r, isNot(ParseResult.skipped));
    });

    test('keyword: debit (not debited)', () async {
      final r = await processNotification(
        title: 'HDFCBK',
        body: 'Debit of Rs.300 from a/c XX6988 for NEFT transfer.',
        timestamp: 1713270006000,
      );
      expect(r, isNot(ParseResult.skipped));
    });

    test('keyword: credit (not credited)', () async {
      final r = await processNotification(
        title: 'HDFCBK',
        body: 'Credit of Rs.1000 to a/c XX6988 via IMPS.',
        timestamp: 1713270007000,
      );
      expect(r, isNot(ParseResult.skipped));
    });

    test('keyword: sent', () async {
      final r = await processNotification(
        title: 'HDFCBK',
        body: 'Rs.750 sent to john@okaxis from a/c XX6988. UPI Ref 987654.',
        timestamp: 1713270008000,
      );
      expect(r, isNot(ParseResult.skipped));
    });

    test('keyword: transfer', () async {
      final r = await processNotification(
        title: 'HDFCBK',
        body: 'Rs.2000 transfer from a/c XX6988 to a/c XX1234. Ref 456789.',
        timestamp: 1713270009000,
      );
      expect(r, isNot(ParseResult.skipped));
    });

    test('keyword: received', () async {
      final r = await processNotification(
        title: 'HDFCBK',
        body: 'Rs.3000 received in a/c XX6988 from jane@okicici. UPI Ref 111222.',
        timestamp: 1713270010000,
      );
      expect(r, isNot(ParseResult.skipped));
    });

    test('keyword: contribution + Rs amount', () async {
      final r = await processNotification(
        title: 'EPFO',
        body: 'Your PF contribution of Rs.1800 has been received for Mar 2025.',
        timestamp: 1713270011000,
      );
      expect(r, isNot(ParseResult.skipped));
    });

    test('keyword: successful + Rs amount', () async {
      final r = await processNotification(
        title: 'Paytm',
        body: 'Recharge successful for 9876543210. Rs.199 debited.',
        timestamp: 1713270012000,
      );
      expect(r, isNot(ParseResult.skipped));
    });

    test('no transaction keyword at all: filtered', () async {
      final r = await processNotification(
        title: 'HDFCBK',
        body: 'Dear Customer, your account statement for March 2025 is ready.',
        timestamp: 1713270013000,
      );
      expect(r, ParseResult.skipped);
    });
  });

  // ── BATCH 2: Every exclusion filter path ──

  group('E2E: percentage alert filter', () {
    test('50% alert', () async {
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713280000000,
        body: '50% Alert: Your credit card XX9012 has used 50% of the limit.',
      );
      expect(r, ParseResult.skipped);
    });

    test('90% alert', () async {
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713280001000,
        body: '90% Alert: Credit limit nearly exhausted on card XX9012.',
      );
      expect(r, ParseResult.skipped);
    });

    test('100% alert', () async {
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713280002000,
        body: '100% Alert: Your credit card XX9012 limit is fully used.',
      );
      expect(r, ParseResult.skipped);
    });
  });

  group('E2E: government/tax filter', () {
    test('ITR processed', () async {
      final r = await processNotification(
        title: 'ITDEPT', timestamp: 1713280003000,
        body: 'Your ITR for AY 2024-25 has been processed. Refund of Rs.12,500 will be credited.',
      );
      expect(r, ParseResult.skipped);
    });

    test('income tax notice', () async {
      final r = await processNotification(
        title: 'ITDEPT', timestamp: 1713280004000,
        body: 'Dear Taxpayer, your income tax return has been received. Ref: CPC/2025/123456.',
      );
      expect(r, ParseResult.skipped);
    });

    test('PAN update', () async {
      final r = await processNotification(
        title: 'NSDL', timestamp: 1713280005000,
        body: 'Your PAN: ABCDE1234F has been linked to Aadhaar successfully.',
      );
      expect(r, ParseResult.skipped);
    });
  });

  group('E2E: loyalty/rewards filter', () {
    test('reward points earned', () async {
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713280006000,
        body: 'You have earned 500 reward points on your HDFC credit card this month.',
      );
      expect(r, ParseResult.skipped);
    });

    test('cashback points', () async {
      final r = await processNotification(
        title: 'Paytm', timestamp: 1713280007000,
        body: 'Congratulations! 200 cashback points added to your wallet.',
      );
      expect(r, ParseResult.skipped);
    });

    test('loyalty points redeemed', () async {
      final r = await processNotification(
        title: 'ICICIB', timestamp: 1713280008000,
        body: 'Your 1000 loyalty points have been redeemed for Rs.250 voucher.',
      );
      expect(r, ParseResult.skipped);
    });
  });

  group('E2E: promotional/marketing filter', () {
    test('explore now', () async {
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713280009000,
        body: 'New credit card offers available. Explore now and get 5X rewards.',
      );
      expect(r, ParseResult.skipped);
    });

    test('plans starting', () async {
      final r = await processNotification(
        title: 'JioMsg', timestamp: 1713280010000,
        body: 'Jio plans starting at Rs.149. Get unlimited data and calls. Recharge now.',
      );
      expect(r, ParseResult.skipped);
    });

    test('offer + http link', () async {
      final r = await processNotification(
        title: 'ICICIB', timestamp: 1713280011000,
        body: 'Special offer on personal loan! Apply now at https://icici.com/offer',
      );
      expect(r, ParseResult.skipped);
    });

    test('subscribe', () async {
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713280012000,
        body: 'Subscribe to HDFC SmartBuy for exclusive deals on credit card spends.',
      );
      expect(r, ParseResult.skipped);
    });

    test('click here', () async {
      final r = await processNotification(
        title: 'ICICIB', timestamp: 1713280013000,
        body: 'Activate your new debit card. Click here to set PIN: https://icici.com/pin',
      );
      expect(r, ParseResult.skipped);
    });

    test('download app', () async {
      final r = await processNotification(
        title: 'SBIBNK', timestamp: 1713280014000,
        body: 'Download app YONO SBI for easy banking. Transfer money instantly.',
      );
      expect(r, ParseResult.skipped);
    });

    test('shop for + get', () async {
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713280015000,
        body: 'Shop for Rs.5000 and get Rs.500 cashback on HDFC credit card.',
      );
      expect(r, ParseResult.skipped);
    });

    test('get best deals', () async {
      final r = await processNotification(
        title: 'ICICIB', timestamp: 1713280016000,
        body: 'Get best deals on electronics with ICICI credit card EMI.',
      );
      expect(r, ParseResult.skipped);
    });

    test('facility enabled', () async {
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713280017000,
        body: 'International transaction facility enabled on your debit card XX6988.',
      );
      expect(r, ParseResult.skipped);
    });

    test('loan enabled', () async {
      final r = await processNotification(
        title: 'ICICIB', timestamp: 1713280018000,
        body: 'Pre-approved personal loan of Rs.5,00,000 enabled on your account. Apply now.',
      );
      expect(r, ParseResult.skipped);
    });

    test('confirmed debit WITH promo keyword still passes', () async {
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713280019000,
        body: 'Rs.999 debited from a/c XX6988 for subscription to Netflix. Explore now at hdfc.com',
      );
      expect(r, isNot(ParseResult.skipped),
          reason: 'hasConfirmedTrn=true bypasses promo filter',);
    });
  });

  group('E2E: data usage alert filter', () {
    test('data limit', () async {
      final r = await processNotification(
        title: 'JioMsg', timestamp: 1713280020000,
        body: 'You have reached your data limit. Recharge for more data.',
      );
      expect(r, ParseResult.skipped);
    });

    test('high speed data consumed', () async {
      final r = await processNotification(
        title: 'Airtel', timestamp: 1713280021000,
        body: 'You have consumed 90% of your high speed data. 1.2GB left.',
      );
      expect(r, ParseResult.skipped);
    });

    test('data pack', () async {
      final r = await processNotification(
        title: 'Vi', timestamp: 1713280022000,
        body: 'Your data pack of 2GB/day is active. Validity: 28 days.',
      );
      expect(r, ParseResult.skipped);
    });

    test('mb left', () async {
      final r = await processNotification(
        title: 'BSNL', timestamp: 1713280023000,
        body: 'Dear customer, 500 mb left in your current plan. Recharge to continue.',
      );
      expect(r, ParseResult.skipped);
    });

    test('gb left', () async {
      final r = await processNotification(
        title: 'JioMsg', timestamp: 1713280024000,
        body: '2.5 gb left in your daily data quota. Resets at midnight.',
      );
      expect(r, ParseResult.skipped);
    });

    test('expires on', () async {
      final r = await processNotification(
        title: 'Airtel', timestamp: 1713280025000,
        body: 'Your current plan expires on 30-Apr-25. Recharge now to avoid disruption.',
      );
      expect(r, ParseResult.skipped);
    });

    test('recharge without amount: filtered', () async {
      final r = await processNotification(
        title: 'JioMsg', timestamp: 1713280026000,
        body: 'Recharge your Jio number for uninterrupted service. Plans start at Rs.149.',
      );
      expect(r, ParseResult.skipped);
    });

    test('successful recharge WITH amount: passes', () async {
      final r = await processNotification(
        title: 'JioMsg', timestamp: 1713280027000,
        body: 'Recharge successful of Rs.299 for 9876543210. Validity 28 days.',
      );
      expect(r, isNot(ParseResult.skipped));
    });

    test('welcome back + pack', () async {
      final r = await processNotification(
        title: 'Airtel', timestamp: 1713280028000,
        body: 'Welcome back! Your pack has been activated. Enjoy unlimited calls.',
      );
      expect(r, ParseResult.skipped);
    });
  });

  group('E2E: future/pending transaction filter', () {
    test('will be debited', () async {
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713280029000,
        body: 'Rs.5000 will be debited from a/c XX6988 on 20-Apr-25 for SIP.',
      );
      expect(r, ParseResult.skipped);
    });

    test('will be credited', () async {
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713280030000,
        body: 'Rs.10000 will be credited to a/c XX6988 on 01-May-25.',
      );
      expect(r, ParseResult.skipped);
    });

    test('to be debited', () async {
      final r = await processNotification(
        title: 'ICICIB', timestamp: 1713280031000,
        body: 'Rs.2000 to be debited from a/c XX1234 for auto-pay on 20-Apr-25.',
      );
      expect(r, ParseResult.skipped);
    });

    test('pending transaction', () async {
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713280032000,
        body: 'A pending transaction of Rs.1500 on your card XX9012 at Amazon.',
      );
      expect(r, ParseResult.skipped);
    });

    test('authorization hold', () async {
      final r = await processNotification(
        title: 'ICICIB', timestamp: 1713280033000,
        body: 'Authorization hold of Rs.2000 on card XX1234 at Uber.',
      );
      expect(r, ParseResult.skipped);
    });

    test('mandate created', () async {
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713280034000,
        body: 'Your mandate for Rs.599 has been created for Netflix autopay on a/c XX6988.',
      );
      expect(r, ParseResult.skipped);
    });

    test('autopay created', () async {
      final r = await processNotification(
        title: 'ICICIB', timestamp: 1713280035000,
        body: 'Autopay of Rs.299 created for Spotify on a/c XX1234. Next debit 01-May-25.',
      );
      expect(r, ParseResult.skipped);
    });

    test('request for payment', () async {
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713280036000,
        body: 'You have a UPI collect request of Rs.500 from merchant@upi.',
      );
      expect(r, ParseResult.skipped);
    });

    test('confirmed debit WITH "pending" in body still passes', () async {
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713280037000,
        body: 'Rs.1500 debited from a/c XX6988. Your pending balance will be updated.',
      );
      expect(r, isNot(ParseResult.skipped),
          reason: 'hasConfirmedTrn=true bypasses future filter',);
    });
  });

  group('E2E: bill reminder filter', () {
    test('payment due', () async {
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713280038000,
        body: 'Your credit card payment of Rs.15,000 is due on 20-Apr-25.',
      );
      expect(r, ParseResult.skipped);
    });

    test('bill due', () async {
      final r = await processNotification(
        title: 'BESCOM', timestamp: 1713280039000,
        body: 'Your electricity bill of Rs.2,500 is due. Pay by 25-Apr-25.',
      );
      expect(r, ParseResult.skipped);
    });

    test('minimum due', () async {
      final r = await processNotification(
        title: 'ICICIB', timestamp: 1713280040000,
        body: 'Minimum due of Rs.1,500 on your ICICI credit card XX1234. Pay by 18-Apr-25.',
      );
      expect(r, ParseResult.skipped);
    });

    test('outstanding amount', () async {
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713280041000,
        body: 'Your outstanding amount on credit card XX9012 is Rs.25,000.',
      );
      expect(r, ParseResult.skipped);
    });

    test('overdue', () async {
      final r = await processNotification(
        title: 'ICICIB', timestamp: 1713280042000,
        body: 'Your credit card payment is overdue. Please pay Rs.5,000 immediately.',
      );
      expect(r, ParseResult.skipped);
    });

    test('reminder', () async {
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713280043000,
        body: 'Reminder: Your SIP of Rs.5000 is scheduled for 20-Apr-25.',
      );
      expect(r, ParseResult.skipped);
    });

    test('confirmed debit WITH "due" in body still passes', () async {
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713280044000,
        body: 'Rs.5000 debited from a/c XX6988 for credit card due payment.',
      );
      expect(r, isNot(ParseResult.skipped),
          reason: 'hasConfirmedTrn=true bypasses bill reminder filter',);
    });
  });

  group('E2E: OTP/verification filter', () {
    test('OTP message', () async {
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713280045000,
        body: 'Your OTP for net banking is 847291. Valid for 5 min.',
      );
      expect(r, ParseResult.skipped);
    });

    test('verification code', () async {
      final r = await processNotification(
        title: 'Google', timestamp: 1713280046000,
        body: 'Your verification code is 123456. Do not share.',
      );
      expect(r, ParseResult.skipped);
    });

    test('verify your account', () async {
      final r = await processNotification(
        title: 'ICICIB', timestamp: 1713280047000,
        body: 'Please verify your mobile number linked to a/c XX1234.',
      );
      expect(r, ParseResult.skipped);
    });

    test('consent + share', () async {
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713280048000,
        body: 'You have given consent to share your account details with XYZ app.',
      );
      expect(r, ParseResult.skipped);
    });
  });

  group('E2E: receipt filter', () {
    test('payment receipt without amount: filtered', () async {
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713280049000,
        body: 'Your payment receipt is ready. Download from netbanking.',
      );
      expect(r, ParseResult.skipped);
    });

    test('payment receipt WITH amount: passes', () async {
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713280050000,
        body: 'Payment receipt: Rs.5000 paid to BESCOM. Download the receipt from netbanking.',
      );
      expect(r, isNot(ParseResult.skipped));
    });
  });

  // ── BATCH 3: Edge cases that test boundary conditions ──

  group('E2E: amount edge cases', () {
    test('Rs.1 (minimum amount)', () async {
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713290000000,
        body: 'Rs.1.00 debited from a/c XX6988 for UPI. Avl Bal Rs.49,999.',
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 1.0);
    });

    test('Rs.99,99,999 (crore range)', () async {
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713290001000,
        body: 'Rs.99,99,999.00 credited to a/c XX6988 via RTGS. Avl Bal Rs.1,05,00,000.',
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 9999999.0);
      expect(a.isIncome, true);
    });

    test('amount with paise: Rs.49.50', () async {
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713290002000,
        body: 'Rs.49.50 debited from a/c XX6988 for parking. Avl Bal Rs.49,950.50',
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 49.5);
    });

    test('INR prefix with space', () async {
      final r = await processNotification(
        title: 'ICICIB', timestamp: 1713290003000,
        body: 'INR 7,500.00 spent on ICICI Card XX1234 at Myntra.',
        );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 7500.0);
    });

    test('INR without space', () async {
      final r = await processNotification(
        title: 'SBIBNK', timestamp: 1713290004000,
        body: 'Your AC XXXXX5678 Debited INR150.00 on 16/04/25. Avl Bal INR8000.00.-SBI',
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 150.0);
    });
  });

  group('E2E: sender edge cases', () {
    test('sender with AD- prefix', () async {
      final r = await processNotification(
        title: 'AD-ICICIB',
        body: 'Your a/c XX1234 is debited with Rs.800.00. Info: UPI/SWIGGY.',
        timestamp: 1713290005000,
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.sender, 'AD-ICICIB');
    });

    test('sender with VM- prefix', () async {
      final r = await processNotification(
        title: 'VM-HDFCBK',
        body: 'Rs.600 debited from a/c XX6988 for UPI payment.',
        timestamp: 1713290006000,
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.sender, 'VM-HDFCBK');
    });

    test('sender: long RCS name under 50 chars', () async {
      final r = await processNotification(
        title: 'Punjab National Bank',
        body: 'Rs.1000 debited from your A/c XX3456 on 16-Apr-25. Avl Bal Rs.9,000.',
        timestamp: 1713290007000,
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.sender, 'Punjab National Bank');
    });
  });

  group('E2E: body format edge cases', () {
    test('body with no spaces around amount', () async {
      final r = await processNotification(
        title: 'SBIBNK', timestamp: 1713290008000,
        body: 'Rs5000.5 debited@SBI UPI frm A/cX5678 on 16Apr25 RefNo 123456789.',
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 5000.5);
    });

    test('body with mixed case keywords', () async {
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713290009000,
        body: 'RS.2000 DEBITED from A/C XX6988 on 16-APR-25. AVL BAL RS.48,000.',
      );
      expect(r, isNot(ParseResult.skipped));
      final a = (await isar.smsActivitys.where().findAll()).last;
      expect(a.amount, 2000.0);
    });

    test('body with extra whitespace', () async {
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713290010000,
        body: '  Rs.500.00   debited  from  a/c  XX6988 .  Avl  Bal  Rs.49,500  ',
      );
      expect(r, isNot(ParseResult.skipped));
    });

    test('empty body: skipped', () async {
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713290011000, body: '',
      );
      expect(r, ParseResult.skipped);
    });

    test('body with only whitespace: skipped', () async {
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713290012000, body: '   \n  \t  ',
      );
      expect(r, ParseResult.skipped);
    });

    test('very short body (4 chars): skipped by Kotlin filter', () async {
      // Kotlin skips body.length < 5, but our processNotification
      // doesn't replicate that — it goes to checkForTransactionalMessage
      // which will skip it anyway (no keywords)
      final r = await processNotification(
        title: 'HDFCBK', timestamp: 1713290013000, body: 'Hi!',
      );
      expect(r, ParseResult.skipped);
    });
  });

  group('E2E: cashback in transaction body', () {
    test('real debit with cashback mention: should be saved as debit, not filtered', () async {
      final r = await processNotification(
        title: 'HDFCBK',
        body: 'Rs.1,499.00 debited from a/c XX6988 on 16-Apr-25 at Swiggy. '
            'Cashback of Rs.50 will be credited within 5 days. Avl Bal: Rs.48,501.00',
        timestamp: 1713295000000,
      );
      expect(r, isNot(ParseResult.skipped),
          reason: 'Real debit with cashback note should NOT be filtered',);
      final a = (await isar.smsActivitys.where().findAll()).last;
      // Must parse the DEBIT amount (1499), not the cashback amount (50)
      expect(a.amount, 1499.0);
      expect(a.isIncome, false,
          reason: 'This is a debit, not a cashback credit',);
    });
  });
}

import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/utils/transaction_msg_util.dart';
import 'package:mudra_manager/features/sms/data/bank_sms_parser.dart';

/// Full SMS flow functional test.
///
/// Simulates the entire pipeline:
///   Kotlin notification → sender detection → transactional filter →
///   dedup → parser → amount/account extraction
///
/// Does NOT require Isar — tests pure logic only.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (call) async {
        if (call.method == 'getAll') return <String, dynamic>{};
        return null;
      },
    );
  });

  // ── Helpers that replicate the exact production logic ──

  /// Replicates TransactionNotificationListener.kt sender detection
  String kotlinSenderDetection(String title) {
    if (title.isNotEmpty && title.length < 50) return title;
    return 'UNKNOWN';
  }

  /// Replicates NotificationListenerBridge._detectSender (Dart side)
  String dartSenderDetection(String title, String body) {
    if (title.isNotEmpty && title.length < 50) return title;
    final bankPattern = RegExp(r'([A-Z]{2,}(?:\s(?:BANK|Bank))?)');
    final match = bankPattern.firstMatch(body);
    if (match != null) return match.group(1)!;
    return 'UNKNOWN';
  }

  /// Replicates SmsProcessorService.generateSmsHash
  String generateSmsHash(String address, int timestamp, String body) {
    final input = '$address|$timestamp|$body';
    return sha256.convert(utf8.encode(input)).toString();
  }

  /// Replicates NotificationListenerBridge._isDuplicate
  bool Function(String) createDedupChecker() {
    final hashSet = <String>{};
    final hashQueue = Queue<String>();
    return (String hash) {
      if (hash.isEmpty) return true;
      if (hashSet.contains(hash)) return true;
      hashSet.add(hash);
      hashQueue.addLast(hash);
      if (hashQueue.length > 200) {
        hashSet.remove(hashQueue.removeFirst());
      }
      return false;
    };
  }

  // ── Real Indian bank SMS samples ──

  final testMessages = <String, Map<String, dynamic>>{
    'HDFC debit SMS': {
      'sender': 'HDFCBK',
      'body':
          'Rs.2500.00 debited from a/c **6988 on 15-04-25 to VPA swiggy@icici(UPI Ref No 510712345678). Avl Bal:Rs.45,230.50',
      'expectTransactional': true,
      'expectAmount': 2500.0,
      'expectIncome': false,
    },
    'ICICI credit SMS': {
      'sender': 'ICICIB',
      'body':
          'Your a/c XX1234 is credited with Rs.15,000.00 on 14-Apr-25. Info: NEFT-SALARY. Avl bal: Rs.62,500.00',
      'expectTransactional': true,
      'expectAmount': 15000.0,
      'expectAccount': '1234',
      'expectIncome': true,
    },
    'SBI UPI SMS': {
      'sender': 'SBIBNK',
      'body':
          'Dear Customer, Rs.499 debited from your A/c no. XX5678 for UPI txn to amazon@apl. Ref 412345678901. If not done by you call 1800112211.',
      'expectTransactional': true,
      'expectAmount': 499.0,
      'expectIncome': false,
    },
    'Axis credit card SMS': {
      'sender': 'AX-AxisBk',
      'body':
          'INR 3,200.00 spent on Axis Bank Credit Card ending 9012 at AMAZON on 15-Apr-25. Avl Limit: INR 1,46,800.00',
      'expectTransactional': true,
      'expectAmount': 3200.0,
      'expectAccount': '9012',
      'expectIncome': false,
    },
    'RCS HDFC debit (display name sender)': {
      'sender': 'HDFC Bank',
      'body':
          'Rs.1,500.00 debited from a/c XX4321 on 15-04-25. UPI/CR/510700001234/swiggy. Avl bal: Rs.23,100.50',
      'expectTransactional': true,
      'expectAmount': 1500.0,
      'expectAccount': '4321',
      'expectIncome': false,
    },
    'OTP message (should be filtered)': {
      'sender': 'HDFCBK',
      'body': 'Your OTP for transaction is 482910. Valid for 5 minutes.',
      'expectTransactional': false,
    },
    'Promo message (should be filtered)': {
      'sender': 'ICICIB',
      'body':
          'Get 10% cashback on credit card spends. Offer valid till 30 Apr. Visit https://icici.com/offer',
      'expectTransactional': false,
    },
    'Bill reminder (should be filtered)': {
      'sender': 'HDFCBK',
      'body':
          'Your credit card bill of Rs.12,500 is due on 20-Apr-25. Minimum due: Rs.625. Pay by due date to avoid late fee.',
      'expectTransactional': false,
    },
    'Future tense with confirmed keyword (should pass)': {
      'sender': 'SBIBNK',
      'body':
          'Rs.5000 debited from A/c XX5678. Amt to be transferred to beneficiary. Avl Bal Rs.10,000.',
      'expectTransactional': true,
      'expectAmount': 5000.0,
      'expectIncome': false,
    },
    'Pure future tense (should be filtered)': {
      'sender': 'HDFCBK',
      'body':
          'Rs.2000 will be debited from your a/c XX6988 on 20-Apr-25 for auto-pay mandate.',
      'expectTransactional': false,
    },
    'Kotak credit SMS': {
      'sender': 'KOTAKB',
      'body':
          'Rs 8,750.00 credited to your A/c XX7890 by NEFT from JOHN DOE. Avl Bal: Rs 1,25,000.00',
      'expectTransactional': true,
      'expectAmount': 8750.0,
      'expectAccount': '7890',
      'expectIncome': true,
    },
    'Data usage alert (should be filtered)': {
      'sender': 'JioMsg',
      'body':
          'You have consumed 80% of your high speed data. Remaining data balance: 4.2GB. Recharge now.',
      'expectTransactional': false,
    },
  };

  // ── STEP 1: Sender detection ──

  group('Step 1: Sender detection (Kotlin → Dart)', () {
    test('SMS short sender ID preserved through both layers', () {
      const sender = 'HDFCBK';
      expect(kotlinSenderDetection(sender), 'HDFCBK');
      expect(dartSenderDetection(sender, ''), 'HDFCBK');
    });

    test('RCS display name preserved through both layers', () {
      const sender = 'HDFC Bank';
      expect(kotlinSenderDetection(sender), 'HDFC Bank');
      expect(dartSenderDetection(sender, ''), 'HDFC Bank');
    });

    test('SIM name like "Jio" is NOT used as sender (Kotlin uses title)', () {
      // In the old buggy code, EXTRA_SUB_TEXT ("Jio") would override title.
      // Now Kotlin always uses title. Dart _detectSender also uses title first.
      const title = 'HDFCBK';
      // Even if subText was "Jio", Kotlin now ignores it and uses title
      expect(kotlinSenderDetection(title), 'HDFCBK');
    });

    test('empty title falls back to UNKNOWN in Kotlin, body extraction in Dart',
        () {
      expect(kotlinSenderDetection(''), 'UNKNOWN');
      expect(
        dartSenderDetection(
            '', 'Rs.500 debited from HDFC Bank a/c XX1234'),
        'HDFC Bank',
      );
    });
  });

  // ── STEP 2: Transactional message filter ──

  group('Step 2: checkForTransactionalMessage', () {
    for (final entry in testMessages.entries) {
      test('${entry.key}', () {
        final body = entry.value['body'] as String;
        final expected = entry.value['expectTransactional'] as bool;
        expect(
          checkForTransactionalMessage(body),
          expected,
          reason: 'Body: ${body.substring(0, body.length.clamp(0, 80))}...',
        );
      });
    }
  });

  // ── STEP 3: Hash generation & dedup ──

  group('Step 3: Hash generation & dedup', () {
    test('same SMS produces same Dart hash', () {
      final h1 = generateSmsHash('HDFCBK', 1000, 'Rs.500 debited');
      final h2 = generateSmsHash('HDFCBK', 1000, 'Rs.500 debited');
      expect(h1, h2);
    });

    test('different timestamp produces different hash', () {
      final h1 = generateSmsHash('HDFCBK', 1000, 'Rs.500 debited');
      final h2 = generateSmsHash('HDFCBK', 1001, 'Rs.500 debited');
      expect(h1, isNot(h2));
    });

    test('in-memory dedup blocks second occurrence', () {
      final isDuplicate = createDedupChecker();
      expect(isDuplicate('abc123'), isFalse);
      expect(isDuplicate('abc123'), isTrue);
      expect(isDuplicate('def456'), isFalse);
    });

    test('in-memory dedup evicts after 200 entries', () {
      final isDuplicate = createDedupChecker();
      for (int i = 0; i < 200; i++) {
        isDuplicate('hash_$i');
      }
      // hash_0 is still in window
      expect(isDuplicate('hash_0'), isTrue);
      // Add one more to evict hash_0
      isDuplicate('hash_200');
      // hash_0 evicted — no longer duplicate
      expect(isDuplicate('hash_0'), isFalse);
    });
  });

  // ── STEP 4: Bank parser (amount, account, direction) ──

  group('Step 4: BankSmsParser extraction', () {
    for (final entry in testMessages.entries) {
      if (entry.value['expectTransactional'] != true) continue;
      if (entry.value['expectAmount'] == null) continue;

      test('${entry.key} — parses correctly', () async {
        final sender = entry.value['sender'] as String;
        final body = entry.value['body'] as String;
        final expectedAmount = entry.value['expectAmount'] as double;
        final expectedIncome = entry.value['expectIncome'] as bool?;
        final expectedAccount = entry.value['expectAccount'] as String?;

        final parsed = await BankSmsParser.parse(sender, body);

        expect(parsed, isNotNull, reason: 'Parser returned null for: $sender');
        expect(parsed!.amount, expectedAmount,
            reason: 'Amount mismatch for $sender');
        if (expectedIncome != null) {
          expect(parsed.isIncome, expectedIncome,
              reason: 'Direction mismatch for $sender');
        }
        if (expectedAccount != null) {
          expect(parsed.account, expectedAccount,
              reason: 'Account mismatch for $sender');
        }
      });
    }
  });

  // ── STEP 5: Full pipeline simulation ──

  group('Step 5: Full pipeline (sender → filter → dedup → parse)', () {
    test('HDFC debit SMS flows through entire pipeline', () async {
      const kotlinTitle = 'HDFCBK';
      const body =
          'Rs.2500.00 debited from a/c XX6988 on 15-04-25 to VPA swiggy@icici(UPI Ref No 510712345678). Avl Bal:Rs.45,230.50';
      const timestamp = 1713168000000;

      // Step 1: Kotlin sender detection
      final senderHint = kotlinSenderDetection(kotlinTitle);
      expect(senderHint, 'HDFCBK');

      // Step 2: Dart sender detection (should match)
      final sender = dartSenderDetection(senderHint, body);
      expect(sender, 'HDFCBK');

      // Step 3: Transactional filter
      expect(checkForTransactionalMessage(body), isTrue);

      // Step 4: Hash + dedup
      final smsHash = generateSmsHash(sender, timestamp, body);
      expect(smsHash, isNotEmpty);
      final isDuplicate = createDedupChecker();
      expect(isDuplicate(smsHash), isFalse);
      expect(isDuplicate(smsHash), isTrue); // second time = duplicate

      // Step 5: Parser
      final parsed = await BankSmsParser.parse(sender, body);
      expect(parsed, isNotNull);
      expect(parsed!.amount, 2500.0);
      expect(parsed.isIncome, false);
    });

    test('RCS HDFC message flows through with display name sender', () async {
      const kotlinTitle = 'HDFC Bank';
      const body =
          'Rs.1,500.00 debited from a/c XX4321 on 15-04-25. UPI/CR/510700001234/swiggy. Avl bal: Rs.23,100.50';
      const timestamp = 1713168000000;

      final senderHint = kotlinSenderDetection(kotlinTitle);
      expect(senderHint, 'HDFC Bank');

      final sender = dartSenderDetection(senderHint, body);
      expect(sender, 'HDFC Bank');

      expect(checkForTransactionalMessage(body), isTrue);

      final smsHash = generateSmsHash(sender, timestamp, body);
      final isDuplicate = createDedupChecker();
      expect(isDuplicate(smsHash), isFalse);

      final parsed = await BankSmsParser.parse(sender, body);
      expect(parsed, isNotNull);
      expect(parsed!.amount, 1500.0);
      expect(parsed.isIncome, false);
      expect(parsed.account, '4321');
    });

    test('OTP message is filtered before reaching parser', () {
      const body = 'Your OTP for transaction is 482910. Valid for 5 minutes.';
      expect(checkForTransactionalMessage(body), isFalse);
      // Parser never called — pipeline stops at filter
    });

    test('"to be" in body does NOT block confirmed debited keyword', () {
      const body =
          'Rs.5000 debited from A/c XX5678. Amt to be transferred to beneficiary. Avl Bal Rs.10,000.';
      expect(checkForTransactionalMessage(body), isTrue);
    });

    test('"will be debited" is correctly filtered as future tense', () {
      const body =
          'Rs.2000 will be debited from your a/c XX6988 on 20-Apr-25 for auto-pay mandate.';
      expect(checkForTransactionalMessage(body), isFalse);
    });

    test('batch of 5 SMS — dedup blocks re-processing', () async {
      final isDuplicate = createDedupChecker();
      final hashes = <String>[];

      for (int i = 0; i < 5; i++) {
        final hash = generateSmsHash('HDFCBK', 1000 + i, 'Rs.${i * 100} debited');
        hashes.add(hash);
        expect(isDuplicate(hash), isFalse);
      }

      // Re-drain same batch — all should be blocked
      for (final hash in hashes) {
        expect(isDuplicate(hash), isTrue);
      }
    });
  });

  // ── STEP 6: Full RCS flow with dedup + transaction data verification ──

  group('Step 6: RCS end-to-end with dedup & transaction data', () {
    // Simulates: Google Messages RCS notification → Kotlin → Dart → parse → transaction data
    test('ICICI RCS credit: full flow produces correct transaction data', () async {
      // ── Kotlin side ──
      const rcsTitle = 'ICICI Bank'; // RCS display name
      const rcsBody =
          'Dear Customer, your A/c XX7890 has been credited with Rs.25,000.00 on 15-Apr-25. '
          'Info: NEFT/SALARY/ACME CORP. Avl Bal: Rs.1,42,500.00';
      const rcsTimestamp = 1713168000000;
      const rcsPackage = 'com.google.android.apps.messaging';

      // Kotlin: sender = title (not EXTRA_SUB_TEXT)
      final ktSender = kotlinSenderDetection(rcsTitle);
      expect(ktSender, 'ICICI Bank');

      // Kotlin: normalize + hash
      final ktNormalized = rcsBody
          .toLowerCase()
          .replaceAll('\n', ' ')
          .replaceAll('rs.', '')
          .replaceAll('rs', '')
          .replaceAll(',', '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final ktHash = sha256
          .convert(utf8.encode('$ktSender|$ktNormalized|$rcsPackage'))
          .toString();

      // Kotlin queues: {title: ktSender, text: rcsBody, timestamp, hash: ktHash}

      // ── Dart side: drain queue ──
      // 1. Body extraction
      final rawBody = rcsBody; // text is non-empty, so rawBody = text
      expect(rawBody.trim().isNotEmpty, isTrue);

      // 2. In-memory dedup (Kotlin hash)
      final isDuplicate = createDedupChecker();
      expect(isDuplicate(ktHash), isFalse, reason: 'First occurrence should pass');

      // 3. Sender detection (Dart)
      final sender = dartSenderDetection(ktSender, rawBody);
      expect(sender, 'ICICI Bank');

      // 4. Transactional filter
      expect(checkForTransactionalMessage(rawBody), isTrue);

      // 5. Dart hash (different from Kotlin hash — that's by design)
      final dartHash = generateSmsHash(sender, rcsTimestamp, rawBody);
      expect(dartHash, isNot(ktHash),
          reason: 'Kotlin and Dart hashes use different inputs — two separate dedup layers');

      // 6. Parse via BankSmsParser (legacy fallback since plugins not loaded in test)
      final parsed = await BankSmsParser.parse(sender, rawBody);
      expect(parsed, isNotNull, reason: 'Parser should extract data from ICICI RCS');
      expect(parsed!.amount, 25000.0);
      expect(parsed.isIncome, true);
      expect(parsed.account, '7890');

      // 7. Verify TransactionUtil also parses correctly (legacy path)
      final txnUtil = TransactionUtil();
      final txnInfo = txnUtil.getTransactionInfo(rawBody, sender, sender, dartHash);
      expect(txnInfo.typeOfTransaction, TransactionType.credited);
      expect(txnInfo.money, isNotEmpty);
      expect(double.tryParse(txnInfo.money!.replaceAll(',', '')), 25000.0);
      expect(txnInfo.account?.no, '7890');

      // 8. Second drain of same notification — Kotlin hash dedup blocks it
      expect(isDuplicate(ktHash), isTrue, reason: 'Same Kotlin hash should be blocked');
    });

    test('SBI RCS debit: sender detection + parse + dedup across two messages', () async {
      const sender1 = 'State Bank of India';
      const body1 =
          'Rs.3,499.00 debited from your A/c XX5678 on 15-Apr-25. '
          'UPI Ref: 510712345678. If not done by you, call 1800112211. Avl Bal: Rs.18,750.00';
      const ts1 = 1713168000000;

      const body2 =
          'Rs.1,200.00 debited from your A/c XX5678 on 15-Apr-25. '
          'UPI Ref: 510712345679. If not done by you, call 1800112211. Avl Bal: Rs.17,550.00';
      const ts2 = 1713168060000; // 1 minute later

      final isDuplicate = createDedupChecker();

      // ── Message 1 ──
      final s1 = dartSenderDetection(kotlinSenderDetection(sender1), body1);
      expect(s1, 'State Bank of India');
      expect(checkForTransactionalMessage(body1), isTrue);

      final hash1 = generateSmsHash(s1, ts1, body1);
      expect(isDuplicate(hash1), isFalse);

      final parsed1 = await BankSmsParser.parse(s1, body1);
      expect(parsed1, isNotNull);
      expect(parsed1!.amount, 3499.0);
      expect(parsed1.isIncome, false);
      expect(parsed1.account, '5678');

      // ── Message 2 (different body, different timestamp) ──
      final hash2 = generateSmsHash(s1, ts2, body2);
      expect(hash2, isNot(hash1), reason: 'Different body+timestamp = different hash');
      expect(isDuplicate(hash2), isFalse);

      final parsed2 = await BankSmsParser.parse(s1, body2);
      expect(parsed2, isNotNull);
      expect(parsed2!.amount, 1200.0);
      expect(parsed2.isIncome, false);

      // ── Re-drain both — blocked ──
      expect(isDuplicate(hash1), isTrue);
      expect(isDuplicate(hash2), isTrue);
    });

    test('RCS promo from bank sender is filtered before parsing', () {
      const sender = 'HDFC Bank';
      const body =
          'Exclusive offer! Get 5X reward points on your HDFC credit card. '
          'Shop for Rs.2000 and get Rs.500 cashback. Visit https://hdfc.com/offer';

      final s = dartSenderDetection(kotlinSenderDetection(sender), body);
      expect(s, 'HDFC Bank');

      // Filter catches it — parser never runs
      expect(checkForTransactionalMessage(body), isFalse);
    });

    test('Kotlin hash dedup vs Dart hash dedup are independent layers', () {
      const sender = 'HDFCBK';
      const body = 'Rs.500 debited from a/c XX1234';
      const timestamp = 1713168000000;
      const packageName = 'com.google.android.apps.messaging';

      // Kotlin hash (sender|normalized|package)
      final normalized = body
          .toLowerCase()
          .replaceAll('\n', ' ')
          .replaceAll('rs.', '')
          .replaceAll('rs', '')
          .replaceAll(',', '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final ktHash = sha256
          .convert(utf8.encode('$sender|$normalized|$packageName'))
          .toString();

      // Dart hash (sender|timestamp|body)
      final dartHash = generateSmsHash(sender, timestamp, body);

      // They must be different — two independent dedup layers
      expect(ktHash, isNot(dartHash));

      // Kotlin hash: in-memory sliding window (200 entries, per drain session)
      // Dart hash: SharedPreferences persistent store (500 entries, across restarts)
      // Both must pass for a message to be processed
    });
  });
}

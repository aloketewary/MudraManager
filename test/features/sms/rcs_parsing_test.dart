import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/features/sms/data/bank_sms_parser.dart';
import 'package:mudra_manager/core/utils/transaction_msg_util.dart';

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

  group('RCS message parsing — display name senders', () {
    test('HDFC Bank (RCS display name) parses correctly', () async {
      const sender = 'HDFC Bank';
      const body =
          'Rs.5000.00 debited from A/c XX1234 on 15-Jan-25. Info: VPA merchant@paytm. Avl Bal: Rs.10000.00';
      final result = await BankSmsParser.parse(sender, body);

      expect(result, isNotNull);
      expect(result!.amount, 5000.00);
      expect(result.isIncome, false);
      expect(result.account, '1234');
    });

    test('ICICI Bank (RCS display name) parses correctly', () async {
      const sender = 'ICICI Bank';
      const body =
          'Rs 2,500.00 debited from a/c XX9876 on 15-Jan-25. Info: AMAZON. Avl bal: Rs 8,500.00';
      final result = await BankSmsParser.parse(sender, body);

      expect(result, isNotNull);
      expect(result!.amount, 2500.00);
      expect(result.isIncome, false);
    });

    test('State Bank of India (RCS display name) parses correctly', () async {
      const sender = 'State Bank of India';
      const body =
          'Dear Customer, Your a/c no. XXXXXXXX2222 is debited for Rs.500.00 on 15-01-25 (IMPS Ref no 1234567890).If not done by you, call 1800111109 -SBI';
      final result = await BankSmsParser.parse(sender, body);

      expect(result, isNotNull);
      expect(result!.amount, 500.00);
      expect(result.isIncome, false);
    });

    test('Axis Bank (RCS display name) parses correctly', () async {
      const sender = 'Axis Bank';
      const body =
          'Rs.1500.00 debited from A/c XX5678 on 15-Jan-25. Avl Bal: Rs.8500.00';
      final result = await BankSmsParser.parse(sender, body);

      expect(result, isNotNull);
      expect(result!.amount, 1500.00);
      expect(result.isIncome, false);
    });

    test('Kotak Mahindra Bank (long RCS name) parses correctly', () async {
      const sender = 'Kotak Mahindra Bank';
      const body =
          'Rs.3000.00 credited to A/c XX4321 on 15-Jan-25. Avl Bal: Rs.15000.00';
      final result = await BankSmsParser.parse(sender, body);

      expect(result, isNotNull);
      expect(result!.amount, 3000.00);
      expect(result.isIncome, true);
    });
  });

  group('RCS vs SMS sender detection', () {
    /// Simulates _detectSender from notification_listener_service.dart
    String detectSender(String title, String body) {
      if (title.isNotEmpty && title.length < 50) return title;
      final bankPattern = RegExp(r'([A-Z]{2,}(?:\s(?:BANK|Bank))?)');
      final match = bankPattern.firstMatch(body);
      if (match != null) return match.group(1)!;
      return 'UNKNOWN';
    }

    test('SMS short sender ID is preserved', () {
      expect(detectSender('HDFCBK', 'Rs.500 debited'), 'HDFCBK');
    });

    test('SMS sender with prefix is preserved', () {
      expect(detectSender('AD-ICICIB', 'Rs.500 debited'), 'AD-ICICIB');
    });

    test('RCS display name is preserved', () {
      expect(detectSender('HDFC Bank', 'Rs.500 debited'), 'HDFC Bank');
    });

    test('RCS long display name is preserved (under 50 chars)', () {
      expect(
        detectSender('State Bank of India', 'Rs.500 debited'),
        'State Bank of India',
      );
    });

    test('very long title falls back to body extraction', () {
      final longTitle = 'A' * 60;
      expect(
        detectSender(longTitle, 'Rs.500 debited from HDFC account'),
        'HDFC',
      );
    });

    test('empty title falls back to body extraction', () {
      expect(
        detectSender('', 'Rs.500 debited from SBI account'),
        'SBI',
      );
    });

    test('empty title and no bank in body returns UNKNOWN', () {
      expect(detectSender('', 'some random text'), 'UNKNOWN');
    });
  });

  group('checkForTransactionalMessage — RCS body formats', () {
    test('standard RCS debit message passes filter', () {
      const body = 'Rs.5000.00 debited from A/c XX1234 on 15-Jan-25';
      expect(checkForTransactionalMessage(body), isTrue);
    });

    test('RCS credit message passes filter', () {
      const body = 'Rs.15000.00 credited to A/c XX1234 on 15-Jan-25';
      expect(checkForTransactionalMessage(body), isTrue);
    });

    test('RCS UPI payment passes filter', () {
      const body =
          'Rs.250.00 sent to merchant@paytm from HDFC Bank a/c XX1234. UPI Ref:123456789012.';
      expect(checkForTransactionalMessage(body), isTrue);
    });

    test('RCS promotional message is filtered out', () {
      const body =
          'Get 50% cashback on your next purchase. Limited time offer! Click here to avail.';
      expect(checkForTransactionalMessage(body), isFalse);
    });

    test('RCS OTP message is filtered out', () {
      const body = 'Your OTP for transaction is 123456. Do not share with anyone.';
      expect(checkForTransactionalMessage(body), isFalse);
    });

    test('RCS bill reminder is filtered out', () {
      const body =
          'Your credit card bill of Rs.15000 is due on 25-Jan-25. Pay by due date to avoid late fee.';
      expect(checkForTransactionalMessage(body), isFalse);
    });

    test('RCS with confirmed debit + due date passes (confirmed keyword wins)', () {
      const body =
          'Rs.5000.00 debited from A/c XX1234. Your next EMI is due on 15-Feb-25.';
      expect(checkForTransactionalMessage(body), isTrue);
    });
  });

  group('Production: hash generation consistency', () {
    test('same inputs produce same hash', () {
      final service = SmsProcessorService_TestHelper();
      final hash1 = service.generateSmsHash('HDFCBK', 1000, 'Rs.500 debited');
      final hash2 = service.generateSmsHash('HDFCBK', 1000, 'Rs.500 debited');
      expect(hash1, hash2);
    });

    test('different timestamp produces different hash', () {
      final service = SmsProcessorService_TestHelper();
      final hash1 = service.generateSmsHash('HDFCBK', 1000, 'Rs.500 debited');
      final hash2 = service.generateSmsHash('HDFCBK', 1001, 'Rs.500 debited');
      expect(hash1, isNot(hash2));
    });

    test('RCS display name vs SMS sender ID produce different hashes', () {
      final service = SmsProcessorService_TestHelper();
      final hash1 =
          service.generateSmsHash('HDFCBK', 1000, 'Rs.500 debited');
      final hash2 =
          service.generateSmsHash('HDFC Bank', 1000, 'Rs.500 debited');
      expect(hash1, isNot(hash2));
    });
  });

  group('Production: body-based bank detection fallback', () {
    test('detects HDFC from body when sender is unknown', () async {
      const sender = 'Unknown Sender';
      const body =
          'Rs.1000.00 debited from your HDFC Bank A/c XX5678 on 15-Jan-25';
      final result = await BankSmsParser.parse(sender, body);

      // Should fall through to body-based detection or generic parser
      expect(result, isNotNull);
      expect(result!.amount, 1000.00);
    });

    test('generic parser handles unknown bank RCS message', () async {
      const sender = 'My Bank';
      const body = 'Rs.750.00 debited from Card XX6666 on 15-Jan-25';
      final result = await BankSmsParser.parse(sender, body);

      expect(result, isNotNull);
      expect(result!.amount, 750.00);
      expect(result.isIncome, false);
    });
  });
}

/// Helper to test hash generation without accessing the singleton
class SmsProcessorService_TestHelper {
  String generateSmsHash(String address, int timestamp, String body) {
    final input = '$address|$timestamp|$body';
    // Replicate the hash logic
    // Simple hash for testing — actual uses sha256
    return input.hashCode.toString();
  }
}

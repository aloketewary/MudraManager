import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/features/sms/data/bank_sms_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock SharedPreferences
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

  group('BankSmsParser - HDFC', () {
    test('should parse HDFC debit SMS', () async {
      const sms =
          'Rs.1234.56 debited from A/c XX5678 on 15-Jan-24. Info: VPA merchant@paytm. Avl Bal: Rs.10000.00';
      final result = await BankSmsParser.parse('HDFCBK', sms);

      expect(result, isNotNull);
      expect(result!.amount, 1234.56);
      expect(result.isIncome, false);
    });

    test('should parse HDFC credit SMS', () async {
      const sms =
          'Rs.15000.00 credited to A/c XX1234 on 15-Jan-24. Avl Bal: Rs.25000.00';
      final result = await BankSmsParser.parse('HDFCBK', sms);

      expect(result, isNotNull);
      expect(result!.amount, 15000.00);
      expect(result.isIncome, true);
    });
  });

  group('BankSmsParser - ICICI', () {
    test('should parse ICICI debit SMS', () async {
      const sms =
          'Rs 2,500.00 debited from a/c XX9876 on 15-Jan-24. Info: AMAZON. Avl bal: Rs 8,500.00';
      final result = await BankSmsParser.parse('ICICIB', sms);

      expect(result, isNotNull);
      expect(result!.amount, 2500.00);
      expect(result.isIncome, false);
    });
  });

  group('BankSmsParser - SBI', () {
    test('should parse SBI debit SMS', () async {
      const sms =
          'Dear Customer, Your a/c no. XXXXXXXX2222 is debited for Rs.500.00 on 15-01-24 (IMPS Ref no 1234567890).If not done by you, call 1800111109 -SBI';
      final result = await BankSmsParser.parse('SBIINB', sms);

      expect(result, isNotNull);
      expect(result!.amount, 500.00);
      expect(result.isIncome, false);
    });

    test('should parse SBI ATM withdrawal', () async {
      const sms =
          'Your AC XXXXX3333 Debited INR 2000.00 on 15/01/24 -ATM withdrawal. Avl Bal INR 8000.00.-SBI';
      final result = await BankSmsParser.parse('SBIINB', sms);

      expect(result, isNotNull);
      expect(result!.amount, 2000.00);
      expect(result.isIncome, false);
    });
  });

  group('BankSmsParser - Paytm', () {
    test('should parse Paytm payment', () async {
      const sms =
          'Rs.250.00 sent to merchant@paytm from BANKNAME a/c 91XX1234. UPI Ref:123456789012.';
      final result = await BankSmsParser.parse('PAYTM', sms);

      expect(result, isNotNull);
      expect(result!.amount, 250.00);
      expect(result.isIncome, false);
    });
  });

  group('BankSmsParser - Generic', () {
    test('should parse generic bank SMS', () async {
      const sms = 'Rs.1000.00 debited from Card XX6666 on 15-Jan-24';
      final result = await BankSmsParser.parse('UNKNOWN', sms);

      expect(result, isNotNull);
      expect(result!.amount, 1000.00);
      expect(result.isIncome, false);
    });

    test('should return null for invalid SMS', () async {
      const sms = 'This is not a transaction SMS';
      final result = await BankSmsParser.parse('UNKNOWN', sms);

      expect(result, isNull);
    });
  });

  group('BankSmsParser - Promotional SMS Filter', () {
    test('should reject promotional shopping SMS', () async {
      const sms =
          'Dear Customer shop for Rs 299 & get best deals on daily items';
      final result = await BankSmsParser.parse('UNKNOWN', sms);

      expect(result, isNull);
    });

    test('should reject loan facility SMS', () async {
      const sms =
          'Dear customer based on your HDFC bank Credit card usage loan facility has been enabled';
      final result = await BankSmsParser.parse('HDFCBK', sms);

      expect(result, isNull);
    });

    test('should reject offer SMS', () async {
      const sms =
          'Get 50% cashback offer on your next purchase. Limited time only!';
      final result = await BankSmsParser.parse('UNKNOWN', sms);

      expect(result, isNull);
    });

    test('should reject pre-approved loan SMS', () async {
      const sms =
          'You are eligible for pre-approved loan of Rs 50000. Apply now!';
      final result = await BankSmsParser.parse('UNKNOWN', sms);

      expect(result, isNull);
    });

    test('should accept valid transaction SMS with amount', () async {
      const sms = 'Rs.500.00 debited from A/c XX1234 on 15-Jan-24';
      final result = await BankSmsParser.parse('UNKNOWN', sms);

      expect(result, isNotNull);
      expect(result!.amount, 500.00);
    });
  });

  group('BankSmsParser - New Banks', () {
    test('should parse Yes Bank SMS', () async {
      const sms =
          'Rs 1500.00 debited from A/c XX4567 on 15-Jan-24. Avl Bal: Rs 8500.00';
      final result = await BankSmsParser.parse('YESBNK', sms);

      expect(result, isNotNull);
      expect(result!.amount, 1500.00);
      expect(result.isIncome, false);
    });

    test('should parse IndusInd Bank SMS', () async {
      const sms =
          'A/C *XX7890 debited by Rs 2000.00 at AMAZON on 15-Jan-24. Avl Bal:5000 - IndusInd Bank';
      final result = await BankSmsParser.parse('INDUS', sms);

      expect(result, isNotNull);
      expect(result!.amount, 2000.00);
      expect(result.isIncome, false);
    });

    test('should parse IDFC Bank SMS', () async {
      const sms =
          'Rs 750.00 credited to A/c XX3456 on 15-Jan-24. Avl Bal: Rs 12000.00';
      final result = await BankSmsParser.parse('IDFC', sms);

      expect(result, isNotNull);
      expect(result!.amount, 750.00);
      expect(result.isIncome, true);
    });

    test('should parse AU Bank SMS', () async {
      const sms =
          'Rs 500.00 debited from A/c XX8901 on 15-Jan-24. Avl Bal: Rs 5000.00';
      final result = await BankSmsParser.parse('AUBANK', sms);

      expect(result, isNotNull);
      expect(result!.amount, 500.00);
      expect(result.isIncome, false);
    });

    test('should parse Amazon Pay SMS', () async {
      const sms = 'Rs.300.00 sent to MERCHANT via Amazon Pay';
      final result = await BankSmsParser.parse('AMAZONPAY', sms);

      expect(result, isNotNull);
      expect(result!.amount, 300.00);
      expect(result.isIncome, false);
    });
  });
}

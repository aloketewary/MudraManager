import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/features/sms/data/bank_sms_parser.dart';

void main() {
  group('BankSmsParser - HDFC', () {
    test('should parse HDFC debit SMS', () {
      const sms = 'Rs.1234.56 debited from A/c XX5678 on 15-Jan-24 to VPA merchant@paytm. Avl Bal: Rs.10000.00';
      final result = BankSmsParser.parse('HDFCBK', sms);

      expect(result, isNotNull);
      expect(result!.amount, 1234.56);
      expect(result.isIncome, false);
      expect(result.account, '5678');
      expect(result.transactionType, 'UPI');
      expect(result.merchant, 'merchant@paytm');
      expect(result.balance, 10000.00);
    });

    test('should parse HDFC credit SMS', () {
      const sms = 'Rs.5000.00 credited to A/c XX1234 on 15-Jan-24. Avl Bal: Rs.15000.00';
      final result = BankSmsParser.parse('HDFCBK', sms);

      expect(result, isNotNull);
      expect(result!.amount, 5000.00);
      expect(result.isIncome, true);
      expect(result.account, '1234');
      expect(result.balance, 15000.00);
    });
  });

  group('BankSmsParser - ICICI', () {
    test('should parse ICICI debit SMS', () {
      const sms = 'Rs 2,500.00 debited from a/c XX9876 on 15-Jan-24. Info: AMAZON. Avl bal: Rs 8,500.00';
      final result = BankSmsParser.parse('ICICIB', sms);

      expect(result, isNotNull);
      expect(result!.amount, 2500.00);
      expect(result.isIncome, false);
      expect(result.account, '9876');
      expect(result.merchant, 'AMAZON');
      expect(result.balance, 8500.00);
    });
  });

  group('BankSmsParser - SBI', () {
    test('should parse SBI debit SMS with UPI', () {
      const sms = 'INR 500.00 debited from A/c XX2222 on 15JAN24 to VPA user@paytm. Avl Bal: INR 5000.00';
      final result = BankSmsParser.parse('SBIINB', sms);

      expect(result, isNotNull);
      expect(result!.amount, 500.00);
      expect(result.isIncome, false);
      expect(result.account, '2222');
      expect(result.transactionType, 'UPI');
      expect(result.merchant, 'user@paytm');
      expect(result.balance, 5000.00);
    });

    test('should parse SBI ATM withdrawal', () {
      const sms = 'Rs 2000.00 withdrawn from A/c XX3333 on 15JAN24 at ATM. Avl Bal: Rs 8000.00';
      final result = BankSmsParser.parse('SBIINB', sms);

      expect(result, isNotNull);
      expect(result!.amount, 2000.00);
      expect(result.isIncome, false);
      expect(result.account, '3333');
      expect(result.transactionType, 'ATM');
      expect(result.balance, 8000.00);
    });
  });

  group('BankSmsParser - Paytm', () {
    test('should parse Paytm payment', () {
      const sms = 'Rs.250.00 sent to MERCHANT via Paytm';
      final result = BankSmsParser.parse('PAYTM', sms);

      expect(result, isNotNull);
      expect(result!.amount, 250.00);
      expect(result.isIncome, false);
      expect(result.transactionType, 'UPI');
      expect(result.merchant, 'MERCHANT');
    });
  });

  group('BankSmsParser - Generic', () {
    test('should parse generic bank SMS', () {
      const sms = 'Rs.1000.00 debited from Card XX6666 on 15-Jan-24';
      final result = BankSmsParser.parse('UNKNOWN', sms);

      expect(result, isNotNull);
      expect(result!.amount, 1000.00);
      expect(result.isIncome, false);
      expect(result.account, '6666');
    });

    test('should return null for invalid SMS', () {
      const sms = 'This is not a transaction SMS';
      final result = BankSmsParser.parse('UNKNOWN', sms);

      expect(result, isNull);
    });
  });

  group('BankSmsParser - Promotional SMS Filter', () {
    test('should reject promotional shopping SMS', () {
      const sms = 'Dear Customer shop for Rs 299 & get best deals on daily essentials';
      final result = BankSmsParser.parse('UNKNOWN', sms);

      expect(result, isNull);
    });

    test('should reject loan facility SMS', () {
      const sms = 'Dear customer based on your HDFC bank Credit card usage loan facility has been enabled';
      final result = BankSmsParser.parse('HDFCBK', sms);

      expect(result, isNull);
    });

    test('should reject offer SMS', () {
      const sms = 'Get 50% cashback offer on your next purchase. Limited time only!';
      final result = BankSmsParser.parse('UNKNOWN', sms);

      expect(result, isNull);
    });

    test('should reject pre-approved loan SMS', () {
      const sms = 'You are eligible for pre-approved loan of Rs 50000. Apply now!';
      final result = BankSmsParser.parse('UNKNOWN', sms);

      expect(result, isNull);
    });

    test('should accept valid transaction SMS with amount', () {
      const sms = 'Rs.500.00 debited from A/c XX1234 on 15-Jan-24';
      final result = BankSmsParser.parse('UNKNOWN', sms);

      expect(result, isNotNull);
      expect(result!.amount, 500.00);
    });
  });

  group('BankSmsParser - New Banks', () {
    test('should parse Yes Bank SMS', () {
      const sms = 'Rs 1500.00 debited from A/c XX4567 on 15-Jan-24. Avl Bal: Rs 8500.00';
      final result = BankSmsParser.parse('YESBNK', sms);

      expect(result, isNotNull);
      expect(result!.amount, 1500.00);
      expect(result.isIncome, false);
      expect(result.account, '4567');
      expect(result.balance, 8500.00);
    });

    test('should parse IndusInd Bank SMS', () {
      const sms = 'Rs.2000.00 debited from Card XX7890 at AMAZON on 15-Jan-24';
      final result = BankSmsParser.parse('INDUS', sms);

      expect(result, isNotNull);
      expect(result!.amount, 2000.00);
      expect(result.isIncome, false);
      expect(result.account, '7890');
      expect(result.merchant, 'AMAZON');
    });

    test('should parse IDFC Bank SMS', () {
      const sms = 'Rs 750.00 credited to A/c XX3456 on 15-Jan-24. Avl Bal: Rs 12000.00';
      final result = BankSmsParser.parse('IDFC', sms);

      expect(result, isNotNull);
      expect(result!.amount, 750.00);
      expect(result.isIncome, true);
      expect(result.account, '3456');
      expect(result.balance, 12000.00);
    });

    test('should parse AU Bank SMS', () {
      const sms = 'Rs 500.00 debited from A/c XX8901 on 15-Jan-24. Avl Bal: Rs 5000.00';
      final result = BankSmsParser.parse('AUBANK', sms);

      expect(result, isNotNull);
      expect(result!.amount, 500.00);
      expect(result.isIncome, false);
      expect(result.account, '8901');
      expect(result.balance, 5000.00);
    });

    test('should parse Amazon Pay SMS', () {
      const sms = 'Rs.300.00 sent to MERCHANT via Amazon Pay';
      final result = BankSmsParser.parse('AMAZONPAY', sms);

      expect(result, isNotNull);
      expect(result!.amount, 300.00);
      expect(result.isIncome, false);
      expect(result.transactionType, 'UPI');
      expect(result.merchant, 'MERCHANT');
    });
  });
}

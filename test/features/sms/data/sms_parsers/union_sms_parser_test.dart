import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/features/sms/data/sms_parsers/union_sms_parser.dart';

void main() {
  group('Union Bank SMS Parser', () {
    late UnionBankSmsParserPlugin parser;

    setUp(() {
      parser = UnionBankSmsParserPlugin();
    });

    test('canParse Union Bank senders', () {
      expect(parser.canParse('UNIONBANK'), isTrue);
      expect(parser.canParse('UNIBNK'), isTrue);
      expect(parser.canParse('UBOI'), isTrue);
      expect(parser.canParse('HDFCBK'), isFalse);
    });

    test('debit transaction', () {
      const sms =
          'Your A/c XX5678 is debited for Rs.3,000.00 on 10-01-25. Avl Bal Rs.42,000.00-Union Bank';
      final r = parser.parseSms('UNIONBANK', sms);
      expect(r, isNotNull);
      expect(r!.amount, 3000.00);
      expect(r.isIncome, isFalse);
      expect(r.account, '5678');
      expect(r.balance, 42000.00);
    });

    test('credit IMPS', () {
      const sms =
          'Your A/c XX9012 is credited by Rs.15,000.00 on 18-02-25 via IMPS from Amit Shah. Avl Bal Rs.67,000.00-Union Bank';
      final r = parser.parseSms('UNIONBANK', sms);
      expect(r, isNotNull);
      expect(r!.amount, 15000.00);
      expect(r.isIncome, isTrue);
      expect(r.isLikelyTransfer, isTrue);
    });

    test('UPI debit with VPA', () {
      const sms =
          'Rs.199.00 debited from A/c XX3456 on 25-03-25 via UPI to VPA shop@upi. Avl Bal Rs.8,000.00-Union Bank';
      final r = parser.parseSms('UNIBNK', sms);
      expect(r, isNotNull);
      expect(r!.amount, 199.00);
      expect(r.isIncome, isFalse);
      expect(r.merchant, 'shop@upi');
      expect(r.transactionType, 'UPI');
    });

    test('RTGS credit large amount', () {
      const sms =
          'Your A/c XX7890 is credited by Rs.5,00,000.00 on 05-04-25 via RTGS from XYZ Enterprises. Avl Bal Rs.8,50,000.00-Union Bank';
      final r = parser.parseSms('UBOI', sms);
      expect(r, isNotNull);
      expect(r!.amount, 500000.00);
      expect(r.isIncome, isTrue);
      expect(r.isLikelyTransfer, isTrue);
    });

    test('returns null for OTP', () {
      const sms = 'Your OTP for Union Bank net banking is 654321. Valid for 5 min.';
      expect(parser.parseSms('UNIONBANK', sms), isNull);
    });
  });
}

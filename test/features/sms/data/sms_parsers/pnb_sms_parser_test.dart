import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/features/sms/data/sms_parsers/pnb_sms_parser.dart';

void main() {
  group('PNB SMS Parser', () {
    late PnbSmsParserPlugin parser;

    setUp(() {
      parser = PnbSmsParserPlugin();
    });

    test('canParse PNB senders', () {
      expect(parser.canParse('PNBSMS'), isTrue);
      expect(parser.canParse('AD-PNB'), isTrue);
      expect(parser.canParse('PUNBNK'), isTrue);
      expect(parser.canParse('HDFCBK'), isFalse);
    });

    test('debit UPI transaction', () {
      const sms =
          'Dear Customer, Your A/c XX1234 is debited for Rs.500.00 on 15-01-25 by UPI. Avl Bal Rs.12345.67-PNB';
      final r = parser.parseSms('PNB', sms);
      expect(r, isNotNull);
      expect(r!.amount, 500.00);
      expect(r.isIncome, isFalse);
      expect(r.account, '1234');
      expect(r.balance, 12345.67);
      expect(r.transactionType, 'UPI');
    });

    test('credit IMPS transaction', () {
      const sms =
          'Dear Customer, Your A/c XX5678 is credited by Rs.25,000.00 on 20-03-25 via IMPS from Rajesh Kumar. Avl Bal Rs.1,50,000.00-PNB';
      final r = parser.parseSms('PNB', sms);
      expect(r, isNotNull);
      expect(r!.amount, 25000.00);
      expect(r.isIncome, isTrue);
      expect(r.account, '5678');
      expect(r.balance, 150000.00);
      expect(r.isLikelyTransfer, isTrue);
    });

    test('ATM withdrawal', () {
      const sms =
          'Dear Customer, Rs.10000.00 withdrawn from your A/c XX9012 on 05-02-25 at ATM. Avl Bal Rs.45000.00-PNB';
      final r = parser.parseSms('PNB', sms);
      expect(r, isNotNull);
      expect(r!.amount, 10000.00);
      expect(r.isIncome, isFalse);
      expect(r.transactionType, 'ATM');
    });

    test('NEFT credit', () {
      const sms =
          'Dear Customer, Your A/c XX3456 is credited by Rs.1,00,000.00 on 10-04-25 via NEFT from ABC Corp. Avl Bal Rs.2,50,000.00-PNB';
      final r = parser.parseSms('PNB', sms);
      expect(r, isNotNull);
      expect(r!.amount, 100000.00);
      expect(r.isIncome, isTrue);
      expect(r.isLikelyTransfer, isTrue);
    });

    test('returns null for OTP', () {
      const sms = 'Your OTP for PNB net banking is 456789. Do not share.';
      expect(parser.parseSms('PNB', sms), isNull);
    });

    test('returns null for promo', () {
      const sms = 'PNB wishes you Happy Diwali! Get 50% off on locker charges.';
      expect(parser.parseSms('PNB', sms), isNull);
    });
  });
}

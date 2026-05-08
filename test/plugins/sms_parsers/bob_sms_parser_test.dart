import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/plugins/sms_parsers/bob_sms_parser.dart';

void main() {
  group('Bank of Baroda SMS Parser', () {
    late BobSmsParserPlugin parser;

    setUp(() {
      parser = BobSmsParserPlugin();
    });

    test('canParse BOB senders', () {
      expect(parser.canParse('BOBANK'), isTrue);
      expect(parser.canParse('AD-BARODA'), isTrue);
      expect(parser.canParse('BOBSMS'), isTrue);
      expect(parser.canParse('SBIINB'), isFalse);
    });

    test('debit transaction', () {
      const sms =
          'Your A/c XX4567 is debited for Rs.2,500.00 on 12-01-25. Avl Bal Rs.35,000.00-Bank of Baroda';
      final r = parser.parseSms('BOBANK', sms);
      expect(r, isNotNull);
      expect(r!.amount, 2500.00);
      expect(r.isIncome, isFalse);
      expect(r.account, '4567');
      expect(r.balance, 35000.00);
    });

    test('credit NEFT transaction', () {
      const sms =
          'Your A/c XX8901 is credited by Rs.50,000.00 on 15-02-25 via NEFT from Suresh Patel. Avl Bal Rs.1,25,000.00-BOB';
      final r = parser.parseSms('BOBANK', sms);
      expect(r, isNotNull);
      expect(r!.amount, 50000.00);
      expect(r.isIncome, isTrue);
      expect(r.account, '8901');
      expect(r.isLikelyTransfer, isTrue);
    });

    test('UPI debit', () {
      const sms =
          'Rs.750.00 debited from your A/c XX2345 on 20-03-25 via UPI to Swiggy. Avl Bal Rs.18,500.00-BOB';
      final r = parser.parseSms('BOBANK', sms);
      expect(r, isNotNull);
      expect(r!.amount, 750.00);
      expect(r.isIncome, isFalse);
      expect(r.transactionType, 'UPI');
    });

    test('returns null for OTP', () {
      const sms = 'Your OTP for BOB World debit card is 987654.';
      expect(parser.parseSms('BOBANK', sms), isNull);
    });
  });
}

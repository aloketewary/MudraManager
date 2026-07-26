import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/features/sms/data/sms_parsers/canara_sms_parser.dart';

void main() {
  group('Canara Bank SMS Parser', () {
    late CanaraSmsParserPlugin parser;

    setUp(() {
      parser = CanaraSmsParserPlugin();
    });

    test('canParse Canara senders', () {
      expect(parser.canParse('CANBNK'), isTrue);
      expect(parser.canParse('AD-CANARA'), isTrue);
      expect(parser.canParse('HDFCBK'), isFalse);
    });

    test('debit transaction', () {
      const sms =
          'Your A/c XX6789 is debited for Rs.1,200.00 on 08-01-25. Avl Bal Rs.22,000.00-Canara Bank';
      final r = parser.parseSms('CANBNK', sms);
      expect(r, isNotNull);
      expect(r!.amount, 1200.00);
      expect(r.isIncome, isFalse);
      expect(r.account, '6789');
      expect(r.balance, 22000.00);
    });

    test('credit salary', () {
      const sms =
          'Your A/c XX3456 is credited by Rs.75,000.00 on 01-03-25 via NEFT from Infosys Ltd. Avl Bal Rs.1,80,000.00-Canara Bank';
      final r = parser.parseSms('CANBNK', sms);
      expect(r, isNotNull);
      expect(r!.amount, 75000.00);
      expect(r.isIncome, isTrue);
      expect(r.isLikelyTransfer, isTrue);
    });

    test('UPI debit with VPA', () {
      const sms =
          'Rs.350.00 debited from A/c XX7890 on 15-04-25 via UPI to VPA merchant@ybl. Avl Bal Rs.9,500.00-Canara Bank';
      final r = parser.parseSms('CANBNK', sms);
      expect(r, isNotNull);
      expect(r!.amount, 350.00);
      expect(r.isIncome, isFalse);
      expect(r.merchant, 'merchant@ybl');
      expect(r.transactionType, 'UPI');
    });

    test('ATM withdrawal', () {
      const sms =
          'Rs.5000.00 withdrawn from your A/c XX1234 on 22-02-25 at ATM. Avl Bal Rs.15,000.00-Canara Bank';
      final r = parser.parseSms('CANBNK', sms);
      expect(r, isNotNull);
      expect(r!.amount, 5000.00);
      expect(r.isIncome, isFalse);
      expect(r.transactionType, 'ATM');
    });

    test('returns null for promo', () {
      const sms = 'Canara Bank: Apply for home loan at 8.5% interest. Visit branch.';
      expect(parser.parseSms('CANBNK', sms), isNull);
    });
  });
}

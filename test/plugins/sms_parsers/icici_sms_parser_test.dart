import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/plugins/sms_parsers/icici_sms_parser.dart';

void main() {
  group('ICICI Bank SMS Parser', () {
    late IciciSmsParserPlugin parser;

    setUp(() {
      parser = IciciSmsParserPlugin();
    });

    // ── canParse ──

    test('canParse returns true for ICICI senders', () {
      expect(parser.canParse('ICICIB'), isTrue);
      expect(parser.canParse('AD-ICICI'), isTrue);
      expect(parser.canParse('VM-ICICIB'), isTrue);
    });

    test('canParse returns false for other senders', () {
      expect(parser.canParse('HDFCBK'), isFalse);
      expect(parser.canParse('SBINOB'), isFalse);
    });

    // ── Credit Card: Debit (spent) ──

    test('parses CC spend SMS', () {
      const sms =
          'INR 1234.56 spent on ICICI Bank Card XX1234 on 20-Oct-22 at AMAZON. Avl Lmt: INR 150000.00. To dispute,call 18002662/SMS BLOCK 1234 to 9215676766';

      final result = parser.parseSms('ICICIB', sms);

      expect(result, isNotNull);
      expect(result!.amount, 1234.56);
      expect(result.isIncome, isFalse);
      expect(result.account, '1234');
      expect(result.merchant, 'AMAZON');
      expect(result.balance, 150000.00);
    });

    test('parses CC spend with comma in amount', () {
      const sms =
          'INR 12,345.67 spent on ICICI Bank Card XX5678 on 15-Nov-23 at FLIPKART. Avl Lmt: INR 2,00,000.00. To dispute,call 18002662';

      final result = parser.parseSms('ICICIB', sms);

      expect(result, isNotNull);
      expect(result!.amount, 12345.67);
      expect(result.isIncome, isFalse);
      expect(result.account, '5678');
      expect(result.merchant, 'FLIPKART');
      expect(result.balance, 200000.00);
    });

    // ── Credit Card: Refund ──

    test('parses CC refund SMS', () {
      const sms =
          'Dear Customer, refund of INR 2500.00 from Amazon has been credited to your ICICI Bank Credit Card XX9876 on 29-SEP-22 and will be adjusted in the coming statement. For details, please call our Customer Care.';

      final result = parser.parseSms('ICICIB', sms);

      expect(result, isNotNull);
      expect(result!.amount, 2500.00);
      expect(result.isIncome, isTrue);
      expect(result.account, '9876');
      expect(result.merchant, 'Amazon');
    });

    // ── Credit Card: Payment received (Click to Pay) ──

    test('parses CC payment via Click to Pay', () {
      const sms =
          'Dear Customer, payment of INR 15000.00 towards your ICICI Bank Credit Card XX4321 has been received through Click to Pay on 26-SEP-22. Thank you.';

      final result = parser.parseSms('ICICIB', sms);

      expect(result, isNotNull);
      expect(result!.amount, 15000.00);
      expect(result.isIncome, isTrue);
      expect(result.account, '4321');
      expect(result.merchant, 'Credit Card Payment');
    });

    // ── Credit Card: Payment received (UPI) ──

    test('parses CC payment via UPI', () {
      const sms =
          'Dear Customer, Payment of INR 25000.00 has been received towards your ICICI Bank Credit Card XX4321 on 29-AUG-22 through UPI. Thank you.';

      final result = parser.parseSms('ICICIB', sms);

      expect(result, isNotNull);
      expect(result!.amount, 25000.00);
      expect(result.isIncome, isTrue);
      expect(result.account, '4321');
    });

    // ── Credit Card: Bill statement (should be skipped) ──

    test('returns null for CC bill statement', () {
      const sms =
          'Dear Customer, statement for ICICI Bank Credit Card XX1234 has been sent to example@example.com. Total amount of Rs 15432.00 or Minimum amount of Rs 500 is due by 30-AUG-22.';

      final result = parser.parseSms('ICICIB', sms);

      expect(result, isNull);
    });

    // ── Savings Account: Debit ──

    test('parses savings account debit SMS', () {
      const sms =
          'Your a/c XX1234 is debited with Rs.5000.00 on 10-Oct-23. Info: UPI/AMAZON. Avl bal: Rs.45000.00';

      final result = parser.parseSms('ICICIB', sms);

      expect(result, isNotNull);
      expect(result!.amount, 5000.00);
      expect(result.isIncome, isFalse);
      expect(result.account, '1234');
      expect(result.merchant, 'UPI/AMAZON');
      expect(result.balance, 45000.00);
    });

    // ── Savings Account: Credit ──

    test('parses savings account credit SMS', () {
      const sms =
          'Your a/c XX5678 is credited with Rs.25,000.00 on 15-Oct-23. Info: NEFT from JOHN. Avl bal: Rs.1,25,000.00';

      final result = parser.parseSms('ICICIB', sms);

      expect(result, isNotNull);
      expect(result!.amount, 25000.00);
      expect(result.isIncome, isTrue);
      expect(result.account, '5678');
      expect(result.balance, 125000.00);
      expect(result.isLikelyTransfer, isTrue);
    });

    // ── Savings Account: IMPS transfer ──

    test('detects IMPS as likely transfer', () {
      const sms =
          'Your a/c XX9999 is debited with Rs.10000.00 on 01-Jan-24. Info: IMPS to JANE. Avl bal: Rs.50000.00';

      final result = parser.parseSms('ICICIB', sms);

      expect(result, isNotNull);
      expect(result!.isLikelyTransfer, isTrue);
    });

    // ── Non-transaction SMS ──

    test('returns null for OTP SMS', () {
      const sms = 'Your OTP for transaction is 123456. Do not share with anyone. - ICICI Bank';

      final result = parser.parseSms('ICICIB', sms);

      expect(result, isNull);
    });

    test('returns null for promotional SMS', () {
      const sms = 'Dear Customer, get 10% cashback on your ICICI Bank Credit Card. T&C apply.';

      final result = parser.parseSms('ICICIB', sms);

      expect(result, isNull);
    });
  });
}

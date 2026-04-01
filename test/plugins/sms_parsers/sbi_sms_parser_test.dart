import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/plugins/sms_parsers/sbi_sms_parser.dart';

void main() {
  group('SBI SMS Parser', () {
    late SbiSmsParserPlugin parser;

    setUp(() {
      parser = SbiSmsParserPlugin();
    });

    test('canParse SBI senders', () {
      expect(parser.canParse('SBIINB'), isTrue);
      expect(parser.canParse('AD-SBI'), isTrue);
      expect(parser.canParse('HDFCBK'), isFalse);
    });

    // ── Debit SMS ──

    test('debit IMPS with a/c no. format', () {
      const sms =
          'Dear Customer, Your a/c no. XXXXXXXX0000 is debited for Rs.1500.50 on 14-10-22 and a/c XXXXXXX000 credited (IMPS Ref no 1234567890).If not done by you, call 1800111109 -SBI';
      final r = parser.parseSms('SBI', sms);
      expect(r, isNotNull);
      expect(r!.amount, 1500.50);
      expect(r.isIncome, isFalse);
      expect(r.account, '0000');
      expect(r.isLikelyTransfer, isTrue);
    });

    test('debit INB txn to bank', () {
      const sms =
          'Dear Customer, Thx for INB txn of Rs.2500.00 frm A/c x0000 to ICICI Bank. Ref XXXXXX123456 on 09Sep22. If not done, fwd this SMS to 9223008333 to block INB or call 1800111109-SBI';
      final r = parser.parseSms('SBI', sms);
      expect(r, isNotNull);
      expect(r!.amount, 2500.00);
      expect(r.isIncome, isFalse);
      expect(r.account, '0000');
      expect(r.merchant, 'ICICI Bank');
      expect(r.isLikelyTransfer, isTrue);
    });

    test('debit service charge with INR', () {
      const sms =
          'Your AC XXXXX123456 Debited INR 150.00 on 13/07/22 -Service Charge for forex trans. Avl Bal INR 5000000.00.-SBI';
      final r = parser.parseSms('SBI', sms);
      expect(r, isNotNull);
      expect(r!.amount, 150.00);
      expect(r.isIncome, isFalse);
      expect(r.balance, 5000000.00);
    });

    test('debit by transfer', () {
      const sms =
          'Dear Customer, Your A/C XXXXX123456 has a debit by transfer of Rs 500.00 on 11/03/22. Avl Bal Rs 1234567.00.-SBI';
      final r = parser.parseSms('SBI', sms);
      expect(r, isNotNull);
      expect(r!.amount, 500.00);
      expect(r.isIncome, isFalse);
      expect(r.balance, 1234567.00);
      expect(r.isLikelyTransfer, isTrue);
    });

    test('UPI debit with transfer to merchant', () {
      const sms =
          'Dear SBI User, your A/c X1234-debited by Rs100000.5 on 29Sep22 transfer to Merchant Ref No 123456789012. If not done by u, fwd this SMS to 9223008333/Call 1800111109 or 09449112211 to block UPI -SBI';
      final r = parser.parseSms('SBI', sms);
      expect(r, isNotNull);
      expect(r!.amount, 100000.5);
      expect(r.isIncome, isFalse);
      expect(r.account, '1234');
      expect(r.merchant, 'Merchant');
    });

    test('UPI debit @SBI format', () {
      const sms =
          'Rs5000.5 debited@SBI UPI frm A/cX1234 on 27Sep22 RefNo 123456789. If not done by u, fwd this SMS to 9223008333/Call 1800111109 or 09449112211 to block UPI';
      final r = parser.parseSms('SBI', sms);
      expect(r, isNotNull);
      expect(r!.amount, 5000.5);
      expect(r.isIncome, isFalse);
      expect(r.account, '1234');
    });

    // ── Credit SMS ──

    test('credit IMPS with mobile linked', () {
      const sms =
          'Dear Customer, Your a/c no. XXXXXXXX0000 is credited by Rs.50000.00 on 18-01-22 by a/c linked to mobile 9XXXXXX999-BANK NAME (IMPS Ref no 123456789012).If not done by you, call 1800111109. -SBI';
      final r = parser.parseSms('SBI', sms);
      expect(r, isNotNull);
      expect(r!.amount, 50000.00);
      expect(r.isIncome, isTrue);
      expect(r.account, '0000');
      expect(r.isLikelyTransfer, isTrue);
    });

    test('credit by transfer with balance', () {
      const sms =
          'Dear Customer, Your A/C XXXXX123456 has a credit by Transfer of Rs 10000000.00 on 13/07/22 by Bank. Avl Bal Rs 1234567.00.-SBI';
      final r = parser.parseSms('SBI', sms);
      expect(r, isNotNull);
      expect(r!.amount, 10000000.00);
      expect(r.isIncome, isTrue);
      expect(r.balance, 1234567.00);
      expect(r.isLikelyTransfer, isTrue);
    });

    test('credit deposit by transfer from person', () {
      const sms =
          'Your A/C XXXXX983974 Credited INR 1500.00 on 15/03/22 -Deposit by transfer from FIRSTNAME LASTNAME. Avl Bal INR 1234567.00-SBI';
      final r = parser.parseSms('SBI', sms);
      expect(r, isNotNull);
      expect(r!.amount, 1500.00);
      expect(r.isIncome, isTrue);
      expect(r.balance, 1234567.00);
    });

    // ── Non-transaction ──

    test('returns null for OTP', () {
      const sms = 'Your OTP is 123456 for SBI transaction. Do not share.';
      expect(parser.parseSms('SBI', sms), isNull);
    });
  });
}

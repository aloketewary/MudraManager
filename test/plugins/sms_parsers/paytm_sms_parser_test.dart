import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/plugins/sms_parsers/upi_sms_parsers.dart';

void main() {
  group('Paytm SMS Parser', () {
    late PaytmSmsParserPlugin parser;

    setUp(() {
      parser = PaytmSmsParserPlugin();
    });

    test('canParse PAYTM and PPBL senders', () {
      expect(parser.canParse('PAYTM'), isTrue);
      expect(parser.canParse('AD-PPBL'), isTrue);
      expect(parser.canParse('HDFCBK'), isFalse);
    });

    test('UPI sent to merchant', () {
      const sms =
          'Rs.250.50 sent to merchant@bankid from BANKNAME a/c 91XX1234. UPI Ref:123456789012. Balance:https://m.paytm.me/pbCheckBal. Query:http://m.p-y.tm/care';
      final r = parser.parseSms('PAYTM', sms);
      expect(r, isNotNull);
      expect(r!.amount, 250.50);
      expect(r.isIncome, isFalse);
      expect(r.account, '91XX1234');
      expect(r.merchant, 'merchant@bankid');
    });

    test('Paid to merchant', () {
      const sms =
          'Paid Rs.500.00 via a/c 91XX1234 to Merchant Name on 07-09-2022. Ref No: 1234567890 Check payment history at https://m.paytm.me/msg :PPBL';
      final r = parser.parseSms('PPBL', sms);
      expect(r, isNotNull);
      expect(r!.amount, 500.00);
      expect(r.isIncome, isFalse);
      expect(r.account, '91XX1234');
      expect(r.merchant, 'Merchant Name');
    });

    test('ATM withdrawal', () {
      const sms =
          'Rs.5000.00 withdrawn at ATM NAME on 04-09-2022 using Debit Card. Avl Bal:Rs.8000. RefNo. 123456789012. Queries? Call 0120-4456456 :PPBL';
      final r = parser.parseSms('PPBL', sms);
      expect(r, isNotNull);
      expect(r!.amount, 5000.00);
      expect(r.isIncome, isFalse);
      expect(r.merchant, 'ATM NAME');
      expect(r.balance, 8000.0);
      expect(r.transactionType, 'ATM');
    });

    test('Received from sender', () {
      const sms =
          'Rs.1500.00 received from Sender Name in your Paytm Payments Bank a/c 91XX01234. UPI Ref: 12345678901. Check your Avl Bal: https://m.paytm.me/pbCheckBal';
      final r = parser.parseSms('PAYTM', sms);
      expect(r, isNotNull);
      expect(r!.amount, 1500.00);
      expect(r.isIncome, isTrue);
      expect(r.account, '91XX01234');
      expect(r.merchant, 'Sender Name');
    });

    test('returns null for OTP', () {
      const sms = 'Your OTP is 123456. Do not share. - Paytm';
      expect(parser.parseSms('PAYTM', sms), isNull);
    });
  });
}

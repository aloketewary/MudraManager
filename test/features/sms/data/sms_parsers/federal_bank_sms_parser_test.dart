import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/features/sms/data/sms_parser_plugin.dart';
import 'package:mudra_manager/features/sms/data/sms_parsers/federal_bank_sms_parser.dart';

void main() {
  group('Federal Bank SMS Parser', () {
    late FederalBankSmsParserPlugin parser;

    setUp(() {
      parser = FederalBankSmsParserPlugin();
    });

    test('canParse Federal Bank senders', () {
      expect(parser.canParse('FEDERAL'), isTrue);
      expect(parser.canParse('AD-FEDBNK'), isTrue);
      expect(parser.canParse('Federal Bank'), isTrue);
      expect(parser.canParse('SBIINB'), isFalse);
    });

    test('NEFT sent from account detected as expense', () {
      const sms =
          'MMTP has recieved Rs 10.00 from your A/c 3373 via NEFT on 02-May-2026 15:12:21. Ref no. FBBT123456 - Federal Bank';
      final r = parser.parseSms('FEDBNK', sms);
      expect(r, isNotNull);
      expect(r!.amount, 10.00);
      expect(r.isIncome, isFalse);
      expect(r.account, '3373');
      expect(r.isLikelyTransfer, isTrue);
    });

    test('NEFT received with correct spelling detected as expense', () {
      const sms =
          'XYZ has received Rs 5,000.00 from your A/c 1234 via NEFT on 01-May-2026. Ref no. FBBT999 - Federal Bank';
      final r = parser.parseSms('FEDBNK', sms);
      expect(r, isNotNull);
      expect(r!.amount, 5000.00);
      expect(r.isIncome, isFalse);
    });

    test('credited to account detected as income', () {
      const sms =
          'Rs 25,000.00 credited to your A/c 3373 on 01-May-2026 via NEFT. Ref no. FBBT789 - Federal Bank';
      final r = parser.parseSms('FEDBNK', sms);
      expect(r, isNotNull);
      expect(r!.amount, 25000.00);
      expect(r.isIncome, isTrue);
    });

    test('debited from account detected as expense', () {
      const sms =
          'Rs 1,200.00 debited from your A/c 3373 on 03-May-2026 via UPI. Ref no. FBBT456 - Federal Bank';
      final r = parser.parseSms('FEDBNK', sms);
      expect(r, isNotNull);
      expect(r!.amount, 1200.00);
      expect(r.isIncome, isFalse);
    });

    test('returns null for OTP', () {
      const sms = 'Your OTP for Federal Bank NetBanking is 123456.';
      expect(parser.parseSms('FEDBNK', sms), isNull);
    });
  });

  group('ParsedSms.isReceivedCredit', () {
    test('received from your A/c is NOT credit', () {
      expect(
        ParsedSms.isReceivedCredit(
            'MMTP has received Rs 10.00 from your A/c 3373 via NEFT',),
        isFalse,
      );
    });

    test('recieved (misspelled) from your A/c is NOT credit', () {
      expect(
        ParsedSms.isReceivedCredit(
            'MMTP has recieved Rs 10.00 from your A/c 3373 via NEFT',),
        isFalse,
      );
    });

    test('received from your account is NOT credit', () {
      expect(
        ParsedSms.isReceivedCredit(
            'XYZ received Rs 500 from your account 1234',),
        isFalse,
      );
    });

    test('received in your account IS credit', () {
      expect(
        ParsedSms.isReceivedCredit(
            'Rs 500 received in your A/c 1234 from Suresh',),
        isTrue,
      );
    });

    test('plain received IS credit', () {
      expect(
        ParsedSms.isReceivedCredit('Rs 500 received from Suresh via UPI'),
        isTrue,
      );
    });

    test('no received keyword returns false', () {
      expect(
        ParsedSms.isReceivedCredit('Rs 500 debited from your A/c 1234'),
        isFalse,
      );
    });
  });
}

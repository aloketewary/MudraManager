import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/features/sms/data/bank_sms_parser.dart';

void main() {
  test('should parse NPS transfer as debit (money going OUT)', () async {
    const sms = 'cam nps tier 2 recieved Rs 1000.00 from your A/c 3373 via NEFT';
    final result = await BankSmsParser.parse('UNKNOWN', sms);

    expect(result, isNotNull);
    expect(result!.amount, 1000.00);
    expect(result.isIncome, false); // Money going OUT = debit
    expect(result.account, '3373');
  });

  test('should parse money received TO account as credit', () async {
    const sms = 'Rs 1000.00 received to your A/c 1234 via NEFT';
    final result = await BankSmsParser.parse('UNKNOWN', sms);

    expect(result, isNotNull);
    expect(result!.amount, 1000.00);
    expect(result.isIncome, true); // Money coming IN = credit
    expect(result.account, '1234');
  });
}

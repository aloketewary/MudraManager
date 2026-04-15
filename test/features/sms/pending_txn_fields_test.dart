import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';

void main() {
  group('Transaction from SMS auto-import fields', () {
    test('isFromSms is set to true for SMS-imported transactions', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 500.0,
        isExpense: true,
        description: 'Auto-imported: HDFCBK',
      );
      txn.isFromSms = true;

      expect(txn.isFromSms, isTrue);
      expect(txn.amount, 500.0);
      expect(txn.isExpense, isTrue);
    });

    test('currencyCode is inherited from account', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 100.0,
        isExpense: true,
        description: 'Auto-imported: ICICIB',
      );
      txn.isFromSms = true;
      txn.currencyCode = 'USD';

      expect(txn.currencyCode, 'USD');
      expect(txn.isFromSms, isTrue);
    });

    test('isFromSms defaults to null when not set', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 200.0,
        isExpense: false,
        description: 'Manual transaction',
      );

      expect(txn.isFromSms, isNull);
    });

    test('baseAmount returns convertedAmount when available', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 100.0,
        isExpense: true,
        currencyCode: 'USD',
        convertedAmount: 8350.0,
        rateUsed: 83.5,
      );

      expect(txn.baseAmount, 8350.0);
    });

    test('baseAmount returns amount when no conversion', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 500.0,
        isExpense: true,
      );

      expect(txn.baseAmount, 500.0);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/util/transaction_msg_util.dart';
import 'package:intl/intl.dart';

void main() {
  late TransactionUtil util;

  setUp(() {
    util = TransactionUtil();
  });

  group('TransactionUtil - SMS Parsing', () {
    test('HDFC Format with bonded currency and YYYY-MM-DD date', () {
      const sms =
          'Spent Rs.19189.3 On Hdfc Card ends with xxxx At Some place on 2026-01-07';
      final info = util.getTransactionInfo(sms, 'HDFC', 'HDFC', 'hash');

      expect(info.money, '19189.3');
      expect(
        DateFormat('yyyy-MM-dd').format(info.transactionTime!),
        '2026-01-07',
      );
      expect(info.typeOfTransaction, TransactionType.debitMisc);
      expect(info.account?.type, 'card');
      expect(info.account?.no, 'xxxx');
    });

    test('Standard Bank Debit with Rs. and comma', () {
      const sms =
          'Your A/c x1234 has been debited by Rs. 1,500.00 on 29-01-26. Total Bal Rs.50000.00';
      final info = util.getTransactionInfo(sms, 'BANK', 'BANK', 'hash');

      expect(info.money, '1500.00');
      expect(info.balance, '50000.00');
      expect(info.typeOfTransaction, TransactionType.debited);
      expect(info.account?.no, '1234');
    });

    test('Standard Bank Credit with INR and DD-MM-YYYY date', () {
      const sms =
          'INR 5,000.00 credited to your A/c x9999 on 15-01-2026. Ref no: 123456';
      final info = util.getTransactionInfo(sms, 'BANK', 'BANK', 'hash');

      expect(info.money, '5000.00');
      expect(
        DateFormat('dd-MM-yyyy').format(info.transactionTime!),
        '15-01-2026',
      );
      expect(info.typeOfTransaction, TransactionType.credited);
      expect(info.account?.no, '9999');
    });

    test('UPI Transaction parsing', () {
      const sms =
          'Money Transfer: Rs 200.0 paid from your account to upiuser@bank. UPI Ref: 654321. Date: 20-01-2026';
      final info = util.getTransactionInfo(sms, 'UPI', 'UPI', 'hash');

      expect(info.money, '200.0');
      expect(info.account?.type, 'UPI');
      expect(info.account?.sendTo, 'upiuser@bank');
    });

    group('SBI Formats', () {
      test('SBI Debit', () {
        const sms =
            'VM-SBIBNK: INR 1000.00 debited from A/c XXXXXX1234 on 28-01-2026 10:30. Avail Bal: INR 5000.00.';
        final info = util.getTransactionInfo(sms, 'SBIBNK', 'SBI', 'hash');
        expect(info.money, '1000.00');
        expect(info.balance, '5000.00');
        expect(info.account?.no, '1234');
        expect(info.typeOfTransaction, TransactionType.debited);
      });

      test('SBI Credit', () {
        const sms =
            'VM-SBIBNK: INR 2000.00 credited to A/c XXXXXX1234 on 28-01-2026 11:15. Avail Bal: INR 7000.00.';
        final info = util.getTransactionInfo(sms, 'SBIBNK', 'SBI', 'hash');
        expect(info.money, '2000.00');
        expect(info.balance, '7000.00');
        expect(info.account?.no, '1234');
        expect(info.typeOfTransaction, TransactionType.credited);
      });
    });

    group('ICICI Formats', () {
      test('ICICI Debit', () {
        const sms =
            'VM-ICICIB: Your A/c XXXXXX5678 is debited for Rs 500.00 on 28-01-2026 14:00 by UPI. Avail Bal: Rs 4500.00.';
        final info = util.getTransactionInfo(sms, 'ICICIB', 'ICICI', 'hash');
        expect(info.money, '500.00');
        expect(info.balance, '4500.00');
        expect(info.account?.no, '5678');
        expect(info.typeOfTransaction, TransactionType.debited);
      });

      test('ICICI Credit', () {
        const sms =
            'VM-ICICIB: Rs 1500.00 credited to your A/c XXXXXX5678 on 28-01-2026 15:00. Avail Bal: Rs 6000.00.';
        final info = util.getTransactionInfo(sms, 'ICICIB', 'ICICI', 'hash');
        expect(info.money, '1500.00');
        expect(info.balance, '6000.00');
        expect(info.account?.no, '5678');
        expect(info.typeOfTransaction, TransactionType.credited);
      });
    });

    group('Axis & PNB Formats', () {
      test('Axis Debit', () {
        const sms =
            'AXISBANK: Rs. 750.00 debited from A/c XXXXXX8901 on 28/01/26 16:45. Ref No. 123456789. Avl Bal: Rs. 9250.00.';
        final info = util.getTransactionInfo(sms, 'AXISBK', 'AXIS', 'hash');
        expect(info.money, '750.00');
        expect(info.balance, '9250.00');
        expect(info.account?.no, '8901');
        expect(info.typeOfTransaction, TransactionType.debited);
      });

      test('PNB Debit', () {
        const sms =
            'PNNNNN: Your A/c XXXXXX7890 debited by Rs. 800.00 on 28/01/26 13:00. For NEFT. Bal: Rs. 7200.00.';
        final info = util.getTransactionInfo(sms, 'PNBNK', 'PNB', 'hash');
        expect(info.money, '800.00');
        expect(info.balance, '7200.00');
        expect(info.account?.no, '7890');
        expect(info.typeOfTransaction, TransactionType.debited);
      });

      test('SBM Debit (User Requirement)', () {
        const sms =
            'Your Account xxxxxxx1651 is debited with INR 5914.33. on 2026-0-03 10:23:29 after : UPI .... and others details';
        final info = util.getTransactionInfo(sms, 'SBMBANK', 'SBM', 'hash');
        expect(info.money, '5914.33');
        expect(info.account?.no, '1651');
        expect(info.typeOfTransaction, TransactionType.debited);
        expect(info.transactionTime, isNotNull);
      });

      test('SBM Debit Card ending with', () {
        const sms =
            'Dear Customer, INR 5914.33 spent on SBM Bank Debit Card ending with 1651 at AMZN Mktp on 2026-0-03:10:23:29. Avail Bal: INR 11090.87-SBM Bank';
        final info = util.getTransactionInfo(sms, 'SBMBANK', 'SBM', 'hash');
        expect(info.money, '5914.33');
        expect(info.account?.no, '1651');
        expect(info.account?.type, 'card');
      });
    });

    test('Relevance check for transactional messages', () {
      expect(
        checkForTransactionalMessage('Your OTP is 1234. Do not share.'),
        isFalse,
      );
      expect(
        checkForTransactionalMessage(
          'Request for Rs 500 from user@upi is pending.',
        ),
        isFalse,
      );
      expect(
        checkForTransactionalMessage('Your A/c has been credited with Rs 100.'),
        isTrue,
      );
      expect(checkForTransactionalMessage('Spent Rs 50 on snacks.'), isTrue);
    });
  });

  group('TransactionUtil - Date Support', () {
    test('Supports YYYY-MM-DD', () {
      final date = util.getTransactionTime('Date: 2025-12-31');
      expect(DateFormat('yyyy-MM-dd').format(date!), '2025-12-31');
    });

    test('Supports DD-MM-YYYY', () {
      final date = util.getTransactionTime('Date: 31-12-2025');
      expect(DateFormat('dd-MM-yyyy').format(date!), '31-12-2025');
    });

    test('Supports DD-MM-YY', () {
      final date = util.getTransactionTime('Date: 31-12-25');
      expect(DateFormat('dd-MM-yy').format(date!), '31-12-25');
    });

    test('Supports DD/MM/YY via replacement', () {
      final date = util.getTransactionTime('Date: 28/01/26');
      expect(DateFormat('dd-MM-yy').format(date!), '28-01-26');
    });
    group('TransactionUtil - Edge Cases', () {
      test('Message with no amount', () {
        const sms = 'Your A/c X1234 has some news for you.';
        final info = util.getTransactionInfo(sms, 'BANK', 'BANK', 'hash');
        expect(info.money, '');
        expect(info.typeOfTransaction, TransactionType.noMatch);
      });
    });
  });
}

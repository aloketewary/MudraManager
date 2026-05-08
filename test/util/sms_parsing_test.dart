import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/utils/transaction_msg_util.dart';
import 'package:mudra_manager/features/sms/data/sms_processor_service.dart';

void main() {
  group('SMS Transaction Parsing', () {
    late TransactionUtil util;

    setUp(() {
      util = TransactionUtil();
    });

    test('parses HDFC debit transaction correctly', () {
      const sms =
          'Rs 500.00 debited from A/c XX1234 on 01-01-2024. '
          'Avbl Bal: Rs 10000.00. HDFC Bank';

      final result = util.getTransactionInfo(sms, 'HDFCBK', null, 'hash123');

      expect(result.money, '500.00');
      expect(result.typeOfTransaction, TransactionType.debited);
      expect(result.account?.no, contains('1234'));
    });

    test('parses ICICI credit transaction correctly', () {
      const sms =
          'INR 1000.00 credited to A/c XX5678 on 01-01-2024. '
          'ICICI Bank';

      final result = util.getTransactionInfo(sms, 'ICICIB', null, 'hash456');

      expect(result.money, '1000.00');
      expect(result.typeOfTransaction, TransactionType.credited);
    });

    test('filters out non-transactional messages', () {
      const sms = 'Your OTP is 123456. Do not share with anyone.';

      final isTransactional = checkForTransactionalMessage(sms);

      expect(isTransactional, false);
    });

    test('identifies transactional keywords', () {
      const sms = 'Rs 250 debited from your account';

      final isTransactional = checkForTransactionalMessage(sms);

      expect(isTransactional, true);
    });

    test('handles UPI transactions', () {
      const sms = 'Rs 300 debited from A/c XX1234 via UPI to merchant@paytm';

      final result = util.getTransactionInfo(sms, 'HDFCBK', null, 'hash789');

      expect(result.money, '300');
      expect(result.typeOfTransaction, TransactionType.debited);
    });

    test('extracts reference number', () {
      const sms = 'Rs 500 debited. Ref No: 123456789';

      final result = util.getTransactionInfo(sms, 'BANK', null, 'hash999');

      expect(result.account?.refNo, isNull);
    });
  });

  group('SMS Hash Generation', () {
    test('generates consistent hash for same input', () {
      const address = 'HDFCBK';
      const body = 'Test SMS';

      final hash1 = SmsProcessorService.instance.generateSmsHash(address, 1234567890, body);
      final hash2 = SmsProcessorService.instance.generateSmsHash(address, 1234567890, body);

      expect(hash1, equals(hash2));
    });

    test('generates different hash for different input', () {
      const address = 'HDFCBK';
      const body1 = 'Test SMS';
      const body2 = 'Different SMS';

      final hash1 = SmsProcessorService.instance.generateSmsHash(address, 1234567890, body1);
      final hash2 = SmsProcessorService.instance.generateSmsHash(address, 1234567890, body2);

      expect(hash1, isNot(equals(hash2)));
    });
  });
}

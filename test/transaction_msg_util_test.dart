import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/utils/transaction_msg_util.dart';

void main() {
  final util = TransactionUtil();

  group('SMS Transaction Parsing Tests', () {
    test('RWallet transaction with typo in balance', () {
      const sms = 'Rs. 110.00 debited from your RWallet Account on Dec 5 2025 2:14PM . Avaialble Balance Rs. 104.97. Indian Railway';
      
      final info = util.getTransactionInfo(sms, '', '', '');
      
      expect(info.money, '110.00');
      expect(info.balance, '104.97');
      expect(info.account?.bankName, 'RWallet');
      expect(info.typeOfTransaction, TransactionType.debited);
      expect(info.transactionTime, isNotNull);
      expect(info.transactionTime?.year, 2025);
      expect(info.transactionTime?.month, 12);
      expect(info.transactionTime?.day, 5);
    });

    test('IndusInd Bank with A?C pattern', () {
      const sms = 'IndusInd A?C **6988 Debited: INR 53143.00 Ref-Loan Recovery for 7730000039072. Bal INR 3444.28 Dispute call IndusInd Bank';
      
      final info = util.getTransactionInfo(sms, '', '', '');
      
      expect(info.money, '53143.00');
      expect(info.balance, '3444.28');
      expect(info.account?.bankName, 'IndusInd Bank');
      expect(info.account?.no, '6988');
      expect(info.account?.type, 'account');
      expect(info.typeOfTransaction, TransactionType.debited);
    });

    test('Loyalty points message should be filtered', () {
      const sms = '5.6 more+ Points have been credited from your more+ Points wallet TnC applied To know more: s.more.vg/+';
      
      final isTransactional = checkForTransactionalMessage(sms);
      
      expect(isTransactional, false);
    });

    test('ITR notification should be filtered', () {
      const sms = 'ITR for AY 2025-26 and PAN: aojxxxxxin has been processed at CPC. Initimation u/s 143(1) has been sent to your registered email id';
      
      final isTransactional = checkForTransactionalMessage(sms);
      
      expect(isTransactional, false);
    });
    test('Milkbasket topup offer', () {
      const sms = 'Dear customer, Topup offer amount of Rs 150.0 has been credited to your wallet. - Team Milkbasket';
      
      final isTransactional = checkForTransactionalMessage(sms);
      expect(isTransactional, true);
      
      final info = util.getTransactionInfo(sms, '', '', '');
      expect(info.money, '150.0');
      expect(info.typeOfTransaction, TransactionType.credited);
      expect(info.account?.bankName, 'Milkbasket Wallet');
    });
  });

  group('Transaction Type Detection', () {
    test('Debit transaction', () {
      expect(util.getTypeOfTransaction('debited from account'), TransactionType.debited);
      expect(util.getTypeOfTransaction('withdrawn from ATM'), TransactionType.debited);
    });

    test('Credit transaction', () {
      expect(util.getTypeOfTransaction('credited to account'), TransactionType.credited);
      expect(util.getTypeOfTransaction('received payment'), TransactionType.credited);
    });

    test('Misc transaction', () {
      expect(util.getTypeOfTransaction('payment made'), TransactionType.debitMisc);
      expect(util.getTypeOfTransaction('spent on shopping'), TransactionType.debitMisc);
    });
  });

  group('Bank Name Extraction', () {
    test('Extract RWallet', () {
      const sms = 'Rs. 110.00 debited from your RWallet Account';
      final info = util.getTransactionInfo(sms, '', '', '');
      expect(info.account?.bankName, 'RWallet');
    });

    test('Extract IndusInd Bank', () {
      const sms = 'IndusInd A?C **6988 Debited';
      final info = util.getTransactionInfo(sms, '', '', '');
      expect(info.account?.bankName, 'IndusInd Bank');
    });

    test('Extract HDFC Bank', () {
      const sms = 'HDFC Bank: Rs 500 debited';
      final info = util.getTransactionInfo(sms, '', '', '');
      expect(info.account?.bankName, 'HDFC Bank');
    });
  });

  group('Amount Extraction', () {
    test('Extract amount with Rs.', () {
      const sms = 'Rs. 110.00 debited';
      final info = util.getTransactionInfo(sms, '', '', '');
      expect(info.money, '110.00');
    });

    test('Extract amount with INR', () {
      const sms = 'INR 53143.00 debited';
      final info = util.getTransactionInfo(sms, '', '', '');
      expect(info.money, '53143.00');
    });

    test('Extract amount with comma', () {
      const sms = 'Rs 1,234.56 debited';
      final info = util.getTransactionInfo(sms, '', '', '');
      expect(info.money, '1234.56');
    });
  });

  group('Balance Extraction', () {
    test('Extract balance with typo "Avaialble"', () {
      const sms = 'Avaialble Balance Rs. 104.97';
      final processed = util.processMessage(sms).join(' ');
      final balance = util.getBalanceFromProcessed(processed);
      expect(balance, '104.97');
    });

    test('Extract balance with "Bal"', () {
      const sms = 'Bal INR 3444.28';
      final processed = util.processMessage(sms).join(' ');
      final balance = util.getBalanceFromProcessed(processed);
      expect(balance, '3444.28');
    });

    test('Extract balance with "Available Balance"', () {
      const sms = 'Available Balance Rs 5000.00';
      final processed = util.processMessage(sms).join(' ');
      final balance = util.getBalanceFromProcessed(processed);
      expect(balance, '5000.00');
    });
  });

  group('Account Number Extraction', () {
    test('Extract account with A?C pattern', () {
      const sms = 'IndusInd A?C **6988 Debited';
      final info = util.getTransactionInfo(sms, '', '', '');
      expect(info.account?.no, '6988');
      expect(info.account?.type, 'account');
    });

    test('Extract account with a/c pattern', () {
      const sms = 'a/c 1234 debited';
      final info = util.getTransactionInfo(sms, '', '', '');
      expect(info.account?.no, '1234');
      expect(info.account?.type, 'account');
    });

    test('Extract card number', () {
      const sms = 'card ending 5678 debited';
      final info = util.getTransactionInfo(sms, '', '', '');
      expect(info.account?.no, '5678');
      expect(info.account?.type, 'card');
    });
  });

  group('Date Parsing', () {
    test('Parse month name format with AM/PM', () {
      const sms = 'Transaction on Dec 5 2025 2:14PM';
      final date = util.getTransactionTime(sms);
      expect(date, isNotNull);
      expect(date?.year, 2025);
      expect(date?.month, 12);
      expect(date?.day, 5);
      expect(date?.hour, 14);
      expect(date?.minute, 14);
    });

    test('Parse numeric date format', () {
      const sms = 'Transaction on 15-03-2024 10:30';
      final date = util.getTransactionTime(sms);
      expect(date, isNotNull);
      expect(date?.year, 2024);
      expect(date?.month, 3);
      expect(date?.day, 15);
    });
  });

  group('Message Filtering', () {
    test('Valid transaction messages', () {
      expect(checkForTransactionalMessage('Rs 100 debited from account'), true);
      expect(checkForTransactionalMessage('Rs 500 credited to account'), true);
      expect(checkForTransactionalMessage('Payment of Rs 200 received'), true);
    });

    test('Filter loyalty points', () {
      expect(checkForTransactionalMessage('5.6 points credited from wallet'), false);
      expect(checkForTransactionalMessage('Reward points added'), false);
    });

    test('Filter promotional messages', () {
      expect(checkForTransactionalMessage('Explore now and get offers'), false);
      expect(checkForTransactionalMessage('Click here to know more'), false);
      expect(checkForTransactionalMessage('loan facility has been enabled. Review Details'), false);
      expect(checkForTransactionalMessage('Shop for Rs.199 & get best deals on Daily essentials'), false);
    });

    test('Filter OTP messages', () {
      expect(checkForTransactionalMessage('Your OTP is 123456'), false);
      expect(checkForTransactionalMessage('Verification code: 9876'), false);
      expect(checkForTransactionalMessage('You consented to share accountdata with Amica Investment'), false);
    });

    test('Filter bill reminders', () {
      expect(checkForTransactionalMessage('Payment due on 15th'), false);
      expect(checkForTransactionalMessage('Bill due Rs 1000'), false);
      expect(checkForTransactionalMessage('Please make your payment to keep your subscription active'), false);
    });

    test('Filter future transactions', () {
      expect(checkForTransactionalMessage('Amount will be debited tomorrow'), false);
      expect(checkForTransactionalMessage('Pending authorization'), false);
      expect(checkForTransactionalMessage('UPI Autopay mandate with ASPRESENTED is successfuly created towards HOSTINGER'), false);
    });

    test('Filter data usage alerts', () {
      expect(checkForTransactionalMessage('Data limit reached'), false);
      expect(checkForTransactionalMessage('500MB left, recharge now'), false);
      expect(checkForTransactionalMessage('Your account is credited with a 7 days welcome back 5G unlimited pack'), false);
    });

    test('Include successful recharge confirmations', () {
      const jio = 'Recharge of Rs. 10.00 is successful for your jio number 828383838383.';
      expect(checkForTransactionalMessage(jio), true);
      
      final info = util.getTransactionInfo(jio, '', '', '');
      expect(info.money, '10.00');
    });
    test('Include bill payment confirmations with amount', () {
      const airtel = 'Hi XXXXX XXXX, we have received a payment of Rs. 849.07 for your Airtel Wi-FI ID 0314050367.';
      expect(checkForTransactionalMessage(airtel), true);
      
      final info = util.getTransactionInfo(airtel, '', '', '');
      expect(info.money, '849.07');
    });

    test('Filter payment receipts without amount', () {
      expect(checkForTransactionalMessage('Download the payment receipt'), false);
    });
  });

  group('Internal Transfer Detection', () {
    test('Detect transfer between own accounts', () {
      final util = TransactionUtil();
      
      // Debit from account 6988
      final debit = util.getTransactionInfo(
        'Rs 5000 debited from A/C 6988 on 15-01-2025 10:30',
        '',
        '',
        'hash1',
      );
      
      // Credit to account 8910
      final credit = util.getTransactionInfo(
        'Rs 5000 credited to A/C 8910 on 15-01-2025 10:31',
        '',
        '',
        'hash2',
      );
      
      // Initially not marked as transfer
      expect(debit.isInternalTransfer, false);
      expect(credit.isInternalTransfer, false);
      
      // Detect transfers
      final result = detectInternalTransfers([debit, credit]);
      
      // Should be marked as internal transfer
      expect(result[0].isInternalTransfer, true);
      expect(result[1].isInternalTransfer, true);
    });

    test('Do not mark as transfer if amounts differ', () {
      final util = TransactionUtil();
      
      final debit = util.getTransactionInfo(
        'Rs 5000 debited from A/C 6988 on 15-01-2025 10:30',
        '',
        '',
        'hash1',
      );
      
      final credit = util.getTransactionInfo(
        'Rs 4999 credited to A/C 8910 on 15-01-2025 10:31',
        '',
        '',
        'hash2',
      );
      
      final result = detectInternalTransfers([debit, credit]);
      
      // Should NOT be marked as transfer (different amounts)
      expect(result[0].isInternalTransfer, false);
      expect(result[1].isInternalTransfer, false);
    });
  });
}

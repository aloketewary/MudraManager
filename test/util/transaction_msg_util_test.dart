import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/util/transaction_msg_util.dart';

void main() {
  group('SMS Transaction Parsing Tests', () {
    late TransactionUtil util;

    setUp(() {
      util = TransactionUtil();
    });

    group('HDFC Bank SMS Tests', () {
      test('HDFC debit with account number', () {
        const sms =
            'Rs.450.00 debited from A/c **1234 on 15-Jan-25 at SWIGGY. Avl Bal: Rs.5000.00';
        final info = util.getTransactionInfo(sms, 'HDFCBK', 'HDFCBK', 'hash1');

        expect(info.money, '450.00');
        expect(info.account?.no, '1234');
        expect(info.typeOfTransaction, TransactionType.debited);
        expect(info.balance, '5000.00');
      });

      test('HDFC debit with XX format', () {
        const sms =
            'Rs 350 debited from A/c XX1234 on 15-Jan-25. Avl Bal: Rs 4650';
        final info = util.getTransactionInfo(sms, 'HDFCBK', 'HDFCBK', 'hash2');

        expect(info.money, '350');
        expect(info.account?.no, '1234');
        expect(info.typeOfTransaction, TransactionType.debited);
      });

      test('HDFC credit transaction', () {
        const sms =
            'Rs.5000 credited to A/c **5678 on 15-Jan-25. Avl Bal: Rs.10000';
        final info = util.getTransactionInfo(sms, 'HDFCBK', 'HDFCBK', 'hash3');

        expect(info.money, '5000');
        expect(info.account?.no, '5678');
        expect(info.typeOfTransaction, TransactionType.credited);
      });

      test('HDFC card transaction', () {
        const sms =
            'Rs 1200 spent on HDFC Bank Card XX9876 at AMAZON on 15-Jan-25';
        final info = util.getTransactionInfo(sms, 'HDFCBK', 'HDFCBK', 'hash4');

        expect(info.money, '1200');
        expect(info.account?.no, '9876');
        expect(info.account?.type, 'card');
      });

      test('HDFC with comma in amount', () {
        const sms =
            'Rs.12,450.50 debited from A/c **1234 on 15-Jan-25. Avl Bal: Rs.50,000.00';
        final info = util.getTransactionInfo(sms, 'HDFCBK', 'HDFCBK', 'hash5');

        expect(info.money, '12450.50');
        expect(info.balance, '50000.00');
      });
    });

    group('SBI Bank SMS Tests', () {
      test('SBI debit transaction', () {
        const sms =
            'Dear Customer, Rs.500.00 is debited from A/c **4321 on 15-Jan-25 at ZOMATO. Avl Bal: Rs.8000.00';
        final info = util.getTransactionInfo(sms, 'SBIINB', 'SBIINB', 'hash6');

        expect(info.money, '500.00');
        expect(info.account?.no, '4321');
        expect(info.typeOfTransaction, TransactionType.debited);
      });

      test('SBI with account ending format', () {
        const sms =
            'Rs 750 debited from account ending 8765 on 15-Jan-25. Available balance: Rs 5250';
        final info = util.getTransactionInfo(sms, 'SBIINB', 'SBIINB', 'hash7');

        expect(info.money, '750');
        expect(info.account?.no, '8765');
      });
    });

    group('ICICI Bank SMS Tests', () {
      test('ICICI debit transaction', () {
        const sms =
            'Rs.300 debited from A/c XX2468 on 15-Jan-25 for UPI/PAYTM. Avl Bal Rs.7000';
        final info =
            util.getTransactionInfo(sms, 'ICICIB', 'ICICIB', 'hash8');

        expect(info.money, '300');
        expect(info.account?.no, '2468');
      });

      test('ICICI card transaction', () {
        const sms =
            'INR 2500 spent on ICICI Card ending 1357 at FLIPKART on 15-Jan-25';
        final info =
            util.getTransactionInfo(sms, 'ICICIB', 'ICICIB', 'hash9');

        expect(info.money, '2500');
        expect(info.account?.no, '1357');
      });
    });

    group('Axis Bank SMS Tests', () {
      test('Axis debit transaction', () {
        const sms =
            'Rs 600 debited from A/c no. XX9753 on 15-Jan-25. Avl bal: Rs 4400';
        final info =
            util.getTransactionInfo(sms, 'AXISBK', 'AXISBK', 'hash10');

        expect(info.money, '600');
        expect(info.account?.no, '9753');
      });
    });

    group('UPI Transaction Tests', () {
      test('UPI payment with VPA', () {
        const sms =
            'Rs 250 debited from A/c XX1234 to user@paytm on 15-Jan-25. UPI Ref No: 123456789';
        final info = util.getTransactionInfo(sms, 'UPIAPP', 'UPIAPP', 'hash11');

        expect(info.money, '250');
        expect(info.account?.sendTo, 'user@paytm');
        expect(info.account?.type, 'UPI');
        expect(info.account?.refNo, '123456789');
      });

      test('UPI with phonepe format', () {
        const sms =
            'Rs 150 sent to merchant@phonepe via UPI. Ref: 987654321';
        final info = util.getTransactionInfo(sms, 'PHONEPE', 'PHONEPE', 'hash12');

        expect(info.money, '150');
        expect(info.account?.sendTo, 'merchant@phonepe');
      });
    });

    group('Edge Cases', () {
      test('Missing account number', () {
        const sms = 'Rs 100 debited on 15-Jan-25 at STORE. Avl Bal: Rs 900';
        final info = util.getTransactionInfo(sms, 'BANK', 'BANK', 'hash13');

        expect(info.money, '100');
        expect(info.account?.no, anyOf(isNull, isEmpty));
      });

      test('Large amount with commas', () {
        const sms =
            'Rs.1,50,000.00 credited to A/c **1234 on 15-Jan-25';
        final info = util.getTransactionInfo(sms, 'BANK', 'BANK', 'hash14');

        expect(info.money, '150000.00');
      });

      test('Multiple Rs in message', () {
        const sms =
            'Rs 500 debited from A/c XX1234. Avl Bal: Rs 4500. Min Bal: Rs 1000';
        final info = util.getTransactionInfo(sms, 'BANK', 'BANK', 'hash15');

        expect(info.money, '500');
        expect(info.balance, '4500');
      });

      test('Date with time', () {
        const sms =
            'Rs 200 debited from A/c XX1234 on 15-01-2025 14:30:45';
        final info = util.getTransactionInfo(sms, 'BANK', 'BANK', 'hash16');

        expect(info.transactionTime, isNotNull);
        expect(info.transactionTime?.day, 15);
        expect(info.transactionTime?.month, 1);
        expect(info.transactionTime?.year, 2025);
      });

      test('Invalid transaction message', () {
        const sms = 'Your OTP is 123456. Valid for 10 minutes.';
        final isValid = checkForTransactionalMessage(sms);

        expect(isValid, false);
      });

      test('Pending transaction (should be ignored)', () {
        const sms = 'Rs 500 pending debit from A/c XX1234';
        final isValid = checkForTransactionalMessage(sms);

        expect(isValid, false);
      });

      test('Future transaction - will be debited', () {
        const sms = 'Rs 1000 will be debited from A/c XX1234 on 20-Jan-25';
        final isValid = checkForTransactionalMessage(sms);

        expect(isValid, false);
      });

      test('Bill reminder - due payment', () {
        const sms = 'Your credit card bill of Rs 5000 is due on 25-Jan-25';
        final isValid = checkForTransactionalMessage(sms);

        expect(isValid, false);
      });

      test('Bill reminder - total due', () {
        const sms = 'Total due: Rs 3500. Pay by 30-Jan-25 to avoid charges';
        final isValid = checkForTransactionalMessage(sms);

        expect(isValid, false);
      });

      test('Bill reminder - minimum due', () {
        const sms = 'Minimum due Rs 500 on your HDFC Card. Pay by 28-Jan';
        final isValid = checkForTransactionalMessage(sms);

        expect(isValid, false);
      });

      test('Outstanding balance reminder', () {
        const sms = 'Outstanding balance Rs 2000 on A/c XX1234';
        final isValid = checkForTransactionalMessage(sms);

        expect(isValid, false);
      });

      test('Authorization hold', () {
        const sms = 'Rs 500 authorization hold on Card XX1234';
        final isValid = checkForTransactionalMessage(sms);

        expect(isValid, false);
      });

      test('Valid completed transaction', () {
        const sms = 'Rs 450 debited from A/c XX1234 on 15-Jan-25';
        final isValid = checkForTransactionalMessage(sms);

        expect(isValid, true);
      });
    });

    group('Account Number Extraction', () {
      test('Account with asterisks', () {
        final words = ['ac', '**1234'];
        final account = util.getAccountFromWords(words, 'ac **1234');

        expect(account.no, '1234');
      });

      test('Account with XX prefix', () {
        final words = ['ac', 'xx5678'];
        final account = util.getAccountFromWords(words, 'ac xx5678');

        expect(account.no, '5678');
      });

      test('Card ending with', () {
        final words = ['card', 'ending', 'with', '9876'];
        final account = util.getAccountFromWords(words, 'card ending with 9876');

        expect(account.no, '9876');
        expect(account.type, 'card');
      });

      test('Account no format', () {
        final words = ['ac', 'no', '1357'];
        final account = util.getAccountFromWords(words, 'ac no 1357');

        expect(account.no, '1357');
      });
    });

    group('Amount Extraction', () {
      test('Amount after Rs.', () {
        final words = ['rs.', '450.00'];
        final amount = util.getMoneySpentFromWords(words);

        expect(amount, '450.00');
      });

      test('Amount with comma', () {
        final words = ['rs.', '1,234.56'];
        final amount = util.getMoneySpentFromWords(words);

        expect(amount, '1234.56');
      });

      test('Amount without decimal', () {
        final words = ['rs', '500'];
        final amount = util.getMoneySpentFromWords(words);

        expect(amount, '500');
      });
    });

    group('Balance Extraction', () {
      test('Available balance', () {
        final balance = util.getBalanceFromProcessed('avl bal rs. 5000.00');

        expect(balance, '5000.00');
      });

      test('Balance with comma', () {
        final balance = util.getBalanceFromProcessed('avbl bal rs. 50,000.00');

        expect(balance, '50000.00');
      });

      test('Current balance', () {
        final balance = util.getBalanceFromProcessed('curr bal rs 3500');

        expect(balance, '3500');
      });
    });

    group('Transaction Type Detection', () {
      test('Debit transaction', () {
        final type = util.getTypeOfTransaction('amount debited from account');

        expect(type, TransactionType.debited);
      });

      test('Credit transaction', () {
        final type = util.getTypeOfTransaction('amount credited to account');

        expect(type, TransactionType.credited);
      });

      test('Payment transaction', () {
        final type = util.getTypeOfTransaction('payment of rs 500');

        expect(type, TransactionType.debitMisc);
      });

      test('No match', () {
        final type = util.getTypeOfTransaction('hello world');

        expect(type, TransactionType.noMatch);
      });
    });
  });
}

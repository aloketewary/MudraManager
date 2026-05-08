import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/plugins/sms_parsers/generic_international_parser.dart';

void main() {
  late GenericInternationalSmsParser parser;

  setUp(() {
    parser = GenericInternationalSmsParser();
  });

  group('canParse', () {
    test('matches short alphanumeric bank codes', () {
      expect(parser.canParse('CHASE'), true);
      expect(parser.canParse('BOFA'), true);
      expect(parser.canParse('CITI'), true);
      expect(parser.canParse('HSBC'), true);
    });

    test('matches senders with bank keywords', () {
      expect(parser.canParse('Wells Fargo Bank'), true);
      expect(parser.canParse('PayPal'), true);
      expect(parser.canParse('Barclays Bank'), true);
    });

    test('rejects long personal names', () {
      expect(parser.canParse('John Smith from Marketing'), false);
    });
  });

  group('parseSms — USD', () {
    test('Chase debit', () {
      final result = parser.parseSms(
        'CHASE',
        'You made a purchase of \$45.99 at WALMART on card ending 1234.',
      );
      expect(result, isNotNull);
      expect(result!.amount, 45.99);
      expect(result.isIncome, false);
      expect(result.currency, 'USD');
      expect(result.account, '1234');
    });

    test('Bank of America credit', () {
      final result = parser.parseSms(
        'BOFA',
        'A deposit of \$2,500.00 has been credited to your account ending 5678.',
      );
      expect(result, isNotNull);
      expect(result!.amount, 2500.0);
      expect(result.isIncome, true);
      expect(result.currency, 'USD');
    });
  });

  group('parseSms — EUR', () {
    test('euro debit', () {
      final result = parser.parseSms(
        'REVOLUT',
        'Payment of €32.50 at CARREFOUR. Card ending 9012.',
      );
      expect(result, isNotNull);
      expect(result!.amount, 32.50);
      expect(result.isIncome, false);
      expect(result.currency, 'EUR');
    });
  });

  group('parseSms — GBP', () {
    test('pound debit', () {
      final result = parser.parseSms(
        'BARCLAYS',
        'You spent £120.00 at TESCO on 15 Mar. A/c ending 3456.',
      );
      expect(result, isNotNull);
      expect(result!.amount, 120.0);
      expect(result.isIncome, false);
      expect(result.currency, 'GBP');
      expect(result.account, '3456');
    });
  });

  group('parseSms — currency code format', () {
    test('NGN (Nigeria)', () {
      final result = parser.parseSms(
        'GTBANK',
        'NGN 15,000.00 debited from your account 0123456789. Ref: TXN123.',
      );
      expect(result, isNotNull);
      expect(result!.amount, 15000.0);
      expect(result.isIncome, false);
      expect(result.currency, 'NGN');
    });

    test('KES (Kenya)', () {
      final result = parser.parseSms(
        'MPESA',
        'KES 5,000 sent to John Doe on 15/3/25. Balance: KES 12,000.',
      );
      expect(result, isNotNull);
      expect(result!.amount, 5000.0);
      expect(result.isIncome, false);
    });

    test('AED (UAE)', () {
      final result = parser.parseSms(
        'ENBD',
        'AED 350.00 has been debited from your account ending 7890 for purchase at CARREFOUR.',
      );
      expect(result, isNotNull);
      expect(result!.amount, 350.0);
      expect(result.isIncome, false);
      expect(result.currency, 'AED');
    });
  });

  group('parseSms — edge cases', () {
    test('rejects non-transactional SMS', () {
      final result = parser.parseSms(
        'CHASE',
        'Your OTP is 123456. Do not share with anyone.',
      );
      expect(result, isNull);
    });

    test('rejects promotional SMS', () {
      final result = parser.parseSms(
        'OFFERS',
        'Get 50% off on your next purchase! Use code SAVE50.',
      );
      expect(result, isNull);
    });

    test('handles comma-separated amounts', () {
      final result = parser.parseSms(
        'HSBC',
        'USD 1,234,567.89 credited to your account.',
      );
      expect(result, isNotNull);
      expect(result!.amount, 1234567.89);
    });

    test('extracts merchant name', () {
      final result = parser.parseSms(
        'CITI',
        '\$89.99 debited from card ending 4567 at AMAZON PRIME on 15 Mar.',
      );
      expect(result, isNotNull);
      expect(result!.merchant, isNotNull);
    });

    test('refund detected as income', () {
      final result = parser.parseSms(
        'CHASE',
        'Refund of \$25.00 has been credited to your card ending 1234.',
      );
      expect(result, isNotNull);
      expect(result!.isIncome, true);
    });
  });

  group('parseSms — South Asian banks (non-Indian)', () {
    test('PKR (Pakistan)', () {
      final result = parser.parseSms(
        'HBL',
        'PKR 5,000 debited from A/c 1234 for purchase at METRO.',
      );
      expect(result, isNotNull);
      expect(result!.amount, 5000.0);
      expect(result.currency, 'PKR');
    });

    test('BDT (Bangladesh)', () {
      final result = parser.parseSms(
        'BKASH',
        'BDT 2,500.00 sent to 01712345678. Balance: BDT 8,500.',
      );
      expect(result, isNotNull);
      expect(result!.amount, 2500.0);
      expect(result.currency, 'BDT');
    });
  });

  group('parseSms — Southeast Asian banks', () {
    test('THB (Thailand)', () {
      final result = parser.parseSms(
        'KBANK',
        'THB 1,500 debited from account ending 9876.',
      );
      expect(result, isNotNull);
      expect(result!.amount, 1500.0);
      expect(result.currency, 'THB');
    });

    test('MYR (Malaysia)', () {
      final result = parser.parseSms(
        'MAYBANK',
        'MYR 250.00 payment to GRAB on card ending 5432.',
      );
      expect(result, isNotNull);
      expect(result!.amount, 250.0);
      expect(result.currency, 'MYR');
    });
  });

  group('parseSms — Spanish (Latin America)', () {
    test('compra (purchase)', () {
      final result = parser.parseSms(
        'BANCOMER',
        'Compra por \$1,250.00 en WALMART con tarjeta *4567.',
      );
      expect(result, isNotNull);
      expect(result!.amount, 1250.0);
      expect(result.isIncome, false);
    });

    test('transferencia recibida (received transfer)', () {
      final result = parser.parseSms(
        'BANAMEX',
        'Deposito recibido de \$5,000.00 en tu cuenta *8901.',
      );
      expect(result, isNotNull);
      expect(result!.amount, 5000.0);
      expect(result.isIncome, true);
    });
  });

  group('parseSms — Portuguese (Brazil)', () {
    test('compra with R\$', () {
      final result = parser.parseSms(
        'NUBANK',
        'Compra de R\$45,99 no cartao final 1234 em IFOOD.',
      );
      expect(result, isNotNull);
      expect(result!.amount, 45.99);
      expect(result.isIncome, false);
      expect(result.currency, 'BRL');
    });

    test('large BRL amount with dots', () {
      final result = parser.parseSms(
        'ITAU',
        'Pagamento de R\$1.234,56 realizado com sucesso.',
      );
      expect(result, isNotNull);
      expect(result!.amount, 1234.56);
      expect(result.currency, 'BRL');
    });
  });

  group('parseSms — French', () {
    test('achat (purchase)', () {
      final result = parser.parseSms(
        'BNPPARIBAS',
        'Achat par carte de 32,50 EUR chez CARREFOUR le 15/03.',
      );
      expect(result, isNotNull);
      expect(result!.amount, 32.50);
      expect(result.isIncome, false);
      expect(result.currency, 'EUR');
    });

    test('virement recu (received transfer)', () {
      final result = parser.parseSms(
        'SOCGEN',
        'Virement recu de 1.500,00 EUR. Remboursement AMAZON.',
      );
      expect(result, isNotNull);
      expect(result!.isIncome, true);
    });
  });

  group('parseSms — German', () {
    test('abbuchung (debit)', () {
      final result = parser.parseSms(
        'SPARKASSE',
        'Abbuchung EUR 89,90 von Konto ending 3456. AMAZON DE.',
      );
      expect(result, isNotNull);
      expect(result!.amount, 89.90);
      expect(result.isIncome, false);
    });

    test('gutschrift (credit)', () {
      final result = parser.parseSms(
        'COMMERZBANK',
        'Gutschrift EUR 250,00 auf Ihr Konto. Erstattung PAYPAL.',
      );
      expect(result, isNotNull);
      expect(result!.isIncome, true);
    });
  });

  group('parseSms — Turkish', () {
    test('harcama (spending)', () {
      final result = parser.parseSms(
        'GARANTI',
        'Harcama: 150,00 TRY MIGROS. Kart *5678.',
      );
      expect(result, isNotNull);
      expect(result!.amount, 150.0);
      expect(result.isIncome, false);
      expect(result.currency, 'TRY');
    });
  });

  group('parseSms — Indonesian', () {
    test('pembelian (purchase)', () {
      final result = parser.parseSms(
        'BCA',
        'Pembelian Rp 250.000 di TOKOPEDIA. Rek *1234.',
      );
      expect(result, isNotNull);
      expect(result!.amount, 250000.0);
      expect(result.isIncome, false);
      expect(result.currency, 'IDR');
    });
  });

  group('parseSms — Swahili (East Africa)', () {
    test('malipo (payment)', () {
      final result = parser.parseSms(
        'EQUITY',
        'Malipo KES 3,500 kwa SAFARICOM. Akaunti *7890.',
      );
      expect(result, isNotNull);
      expect(result!.amount, 3500.0);
      expect(result.isIncome, false);
      expect(result.currency, 'KES');
    });

    test('umepokea (received)', () {
      final result = parser.parseSms(
        'MPESA',
        'Umepokea KES 10,000 kutoka John Doe.',
      );
      expect(result, isNotNull);
      expect(result!.isIncome, true);
    });
  });
}

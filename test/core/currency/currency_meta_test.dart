import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';

void main() {
  group('Currency metadata', () {
    test('INR is defined', () {
      expect(kCurrencies.containsKey('INR'), true);
      expect(kCurrencies['INR']!.symbol, '₹');
      expect(kCurrencies['INR']!.cleanSymbol, true);
    });

    test('USD is defined', () {
      expect(kCurrencies['USD']!.symbol, '\$');
      expect(kCurrencies['USD']!.cleanSymbol, true);
    });

    test('all currencies have required fields', () {
      for (final entry in kCurrencies.entries) {
        expect(entry.value.code, entry.key);
        expect(entry.value.symbol, isNotEmpty);
        expect(entry.value.name, isNotEmpty);
        expect(entry.value.decimalDigits, greaterThanOrEqualTo(0));
      }
    });

    test('JPY has 0 decimal digits', () {
      expect(kCurrencies['JPY']!.decimalDigits, 0);
    });

    test('KWD has 3 decimal digits', () {
      expect(kCurrencies['KWD']!.decimalDigits, 3);
    });
  });

  group('currencySymbol', () {
    test('returns correct symbol for known codes', () {
      expect(currencySymbol('INR'), '₹');
      expect(currencySymbol('USD'), '\$');
      expect(currencySymbol('EUR'), '€');
      expect(currencySymbol('GBP'), '£');
    });

    test('null defaults to INR', () {
      expect(currencySymbol(null), '₹');
    });

    test('unknown code returns the code itself', () {
      expect(currencySymbol('XYZ'), 'XYZ');
    });
  });

  group('currencyIcon', () {
    test('INR returns Indian Rupee icon', () {
      final icon = currencyIcon('INR');
      expect(icon, isNotNull);
    });

    test('null defaults to INR icon', () {
      final icon = currencyIcon(null);
      expect(icon, isNotNull);
    });

    test('unknown code returns coins icon', () {
      final icon = currencyIcon('XYZ');
      expect(icon, isNotNull);
    });
  });

  group('formatCurrency', () {
    test('INR formats with Indian grouping', () {
      final result = formatCurrency(1234567, code: 'INR', decimals: 0);
      expect(result.contains('₹'), true);
      expect(result.contains('12'), true);
    });

    test('zero amount', () {
      final result = formatCurrency(0, code: 'INR', decimals: 0);
      expect(result.contains('0'), true);
    });

    test('decimal formatting', () {
      final result = formatCurrency(99.99, code: 'USD', decimals: 2);
      expect(result.contains('99'), true);
    });

    test('no decimals', () {
      final result = formatCurrency(1234.56, code: 'INR', decimals: 0);
      expect(result.contains('.'), false);
    });

    test('large number', () {
      final result = formatCurrency(99999999, code: 'INR', decimals: 0);
      expect(result, isNotEmpty);
    });

    test('null code defaults to INR', () {
      final result = formatCurrency(100);
      expect(result.contains('₹'), true);
    });
  });

  group('formatCurrencyFull', () {
    test('clean symbol shows symbol + code', () {
      final result = formatCurrencyFull(1000, code: 'INR', decimals: 0);
      expect(result.contains('₹'), true);
      expect(result.contains('INR'), true);
    });

    test('non-clean symbol shows code only', () {
      final result = formatCurrencyFull(1000, code: 'AED', decimals: 0);
      expect(result.contains('AED'), true);
    });
  });

  group('formatCurrencyCompact', () {
    test('below 10K shows full number', () {
      final result = formatCurrencyCompact(9850, code: 'INR');
      expect(result, contains('₹'));
      expect(result, contains('9'));
      expect(result, isNot(contains('K')));
    });

    test('10K-99.9K shows K suffix', () {
      expect(formatCurrencyCompact(12500, code: 'INR'), '₹12.5K');
      expect(formatCurrencyCompact(48000, code: 'INR'), '₹48K');
      expect(formatCurrencyCompact(99900, code: 'INR'), '₹99.9K');
    });

    test('1L-99L shows L suffix', () {
      expect(formatCurrencyCompact(120000, code: 'INR'), '₹1.2L');
      expect(formatCurrencyCompact(850000, code: 'INR'), '₹8.5L');
      expect(formatCurrencyCompact(2500000, code: 'INR'), '₹25L');
    });

    test('1Cr+ shows Cr suffix', () {
      expect(formatCurrencyCompact(11000000, code: 'INR'), '₹1.1Cr');
      expect(formatCurrencyCompact(35000000, code: 'INR'), '₹3.5Cr');
    });

    test('trims trailing .0', () {
      expect(formatCurrencyCompact(50000, code: 'INR'), '₹50K');
      expect(formatCurrencyCompact(200000, code: 'INR'), '₹2L');
      expect(formatCurrencyCompact(10000000, code: 'INR'), '₹1Cr');
    });

    test('non-clean symbol uses code prefix', () {
      final result = formatCurrencyCompact(50000, code: 'AED');
      expect(result, contains('AED'));
      expect(result, contains('50K'));
    });

    test('negative amounts show minus sign', () {
      final result = formatCurrencyCompact(-25000, code: 'INR');
      expect(result, contains('-'));
      expect(result, contains('25K'));
    });

    test('USD uses dollar symbol', () {
      expect(formatCurrencyCompact(15000, code: 'USD'), '\$15K');
    });
  });

  group('Currency completeness', () {
    test('at least 30 currencies defined', () {
      expect(kCurrencies.length, greaterThanOrEqualTo(30));
    });

    test('major currencies all present', () {
      final major = ['INR', 'USD', 'EUR', 'GBP', 'JPY', 'AED', 'SGD', 'AUD', 'CAD'];
      for (final code in major) {
        expect(kCurrencies.containsKey(code), true,
            reason: '$code should be defined',);
      }
    });

    test('South Asian currencies present', () {
      final sa = ['INR', 'BDT', 'NPR', 'LKR', 'PKR'];
      for (final code in sa) {
        expect(kCurrencies.containsKey(code), true,
            reason: '$code should be defined',);
      }
    });
  });
}

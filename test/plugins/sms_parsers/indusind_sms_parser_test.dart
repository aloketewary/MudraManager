import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/plugins/sms_parsers/other_banks_sms_parsers.dart';

void main() {
  group('IndusInd Bank SMS Parser', () {
    late IndusIndSmsParserPlugin parser;

    setUp(() {
      parser = IndusIndSmsParserPlugin();
    });

    test('should parse credit transaction with XX prefix account', () {
      const sms = 'A/C *XX6988 credited by Rs 45000.00 from 891091@jupiteraxis. RRN: 7829832932 Avl Bal:657767 Not you? call 188383843 - IndusInd Bank';
      
      final result = parser.parseSms('INDUS', sms);
      
      expect(result, isNotNull);
      expect(result!.amount, equals(45000.00));
      expect(result.isIncome, isTrue);
      expect(result.account, equals('6988'));
      expect(result.balance, equals(657767.0));
    });

    test('should parse debit transaction', () {
      const sms = 'A/C *XX6988 debited by Rs 1500.00 at AMAZON on 15-Dec-23. Avl Bal:656267 - IndusInd Bank';
      
      final result = parser.parseSms('INDUS', sms);
      
      expect(result, isNotNull);
      expect(result!.amount, equals(1500.00));
      expect(result.isIncome, isFalse);
      expect(result.account, equals('6988'));
      expect(result.balance, equals(656267.0));
    });

    test('should parse transaction with lowercase a/c', () {
      const sms = 'a/c *xx1234 credited by Rs 2500.50 from UPI. Avl Bal:10000.75 - IndusInd Bank';
      
      final result = parser.parseSms('INDUS', sms);
      
      expect(result, isNotNull);
      expect(result!.amount, equals(2500.50));
      expect(result.isIncome, isTrue);
      expect(result.account, equals('1234'));
      expect(result.balance, equals(10000.75));
    });

    test('should return null for non-transaction SMS', () {
      const sms = 'Your OTP is 123456 - IndusInd Bank';
      
      final result = parser.parseSms('INDUS', sms);
      
      expect(result, isNull);
    });

    test('should return null when amount is missing', () {
      const sms = 'A/C *XX6988 credited from UPI. Avl Bal:10000 - IndusInd Bank';
      
      final result = parser.parseSms('INDUS', sms);
      
      expect(result, isNull);
    });
  });
}
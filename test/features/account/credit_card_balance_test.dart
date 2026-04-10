import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Credit Card Balance Logic', () {
    test('credit card balance increases with expenses', () {
      final initialOutstanding = 5000.0;
      final newPurchase = 500.0;
      final payment = 0.0;

      final balance = initialOutstanding + newPurchase - payment;

      expect(balance, 5500.0);
    });

    test('credit card balance decreases with payments', () {
      final initialOutstanding = 5000.0;
      final newPurchase = 0.0;
      final payment = 2000.0;

      final balance = initialOutstanding + newPurchase - payment;

      expect(balance, 3000.0);
    });

    test('paid off credit card shows zero balance', () {
      final initialOutstanding = 5000.0;
      final totalExpenses = 0.0;
      final totalPayments = 5000.0;

      final balance = initialOutstanding + totalExpenses - totalPayments;

      expect(balance, 0.0);
    });

    test('regular account balance increases with income', () {
      final initialBalance = 10000.0;
      final income = 5000.0;
      final expense = 0.0;

      final balance = initialBalance + income - expense;

      expect(balance, 15000.0);
    });
  });
}

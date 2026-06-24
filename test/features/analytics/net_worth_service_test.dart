import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/features/analytics/data/net_worth_service.dart';

void main() {
  group('NetWorthData model', () {
    test('net worth = assets - liabilities', () {
      final data = NetWorthData(
        netWorth: 500000,
        totalAssets: 700000,
        totalLiabilities: 200000,
        monthlyChange: 15000,
        assets: [
          AccountItem(
            name: 'Savings',
            balance: 500000,
            accountType: AccountType.bank,
          ),
          AccountItem(
            name: 'Wallet',
            balance: 200000,
            accountType: AccountType.eWallet,
          ),
        ],
        liabilities: [
          AccountItem(
            name: 'Credit Card',
            balance: 200000,
            accountType: AccountType.creditCard,
          ),
        ],
      );

      expect(data.netWorth, data.totalAssets - data.totalLiabilities);
      expect(data.assets.length, 2);
      expect(data.liabilities.length, 1);
    });

    test('positive monthly change indicates growth', () {
      final data = NetWorthData(
        netWorth: 600000,
        totalAssets: 600000,
        totalLiabilities: 0,
        monthlyChange: 50000,
        assets: [],
        liabilities: [],
      );

      expect(data.monthlyChange, greaterThan(0));
    });

    test('negative net worth when liabilities exceed assets', () {
      final data = NetWorthData(
        netWorth: -100000,
        totalAssets: 50000,
        totalLiabilities: 150000,
        monthlyChange: -10000,
        assets: [
          AccountItem(
            name: 'Cash',
            balance: 50000,
            accountType: AccountType.cash,
          ),
        ],
        liabilities: [
          AccountItem(
            name: 'Card A',
            balance: 80000,
            accountType: AccountType.creditCard,
          ),
          AccountItem(
            name: 'Card B',
            balance: 70000,
            accountType: AccountType.creditCard,
          ),
        ],
      );

      expect(data.netWorth, lessThan(0));
      expect(data.liabilities.length, 2);
    });

    test('zero net worth', () {
      final data = NetWorthData(
        netWorth: 0,
        totalAssets: 100000,
        totalLiabilities: 100000,
        monthlyChange: 0,
        assets: [],
        liabilities: [],
      );

      expect(data.netWorth, 0);
    });
  });

  group('AccountItem model', () {
    test('stores all fields correctly', () {
      final item = AccountItem(
        name: 'HDFC Savings',
        balance: 250000,
        accountType: AccountType.bank,
        colorValue: 0xFF2196F3,
        currencyCode: 'INR',
      );

      expect(item.name, 'HDFC Savings');
      expect(item.balance, 250000);
      expect(item.accountType, AccountType.bank);
      expect(item.colorValue, 0xFF2196F3);
      expect(item.currencyCode, 'INR');
    });

    test('nullable fields default to null', () {
      final item = AccountItem(
        name: 'Cash',
        balance: 5000,
        accountType: AccountType.cash,
      );

      expect(item.colorValue, isNull);
      expect(item.currencyCode, isNull);
    });
  });

  group('NetWorthHistoryPoint', () {
    test('stores date and net worth', () {
      final point = NetWorthHistoryPoint(
        date: DateTime(2025, 6, 15),
        netWorth: 450000,
      );

      expect(point.date.day, 15);
      expect(point.netWorth, 450000);
    });
  });
}

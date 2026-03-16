import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/account/data/balance_history_service.dart';

final netWorthProvider = FutureProvider.autoDispose((ref) async {
  final accounts = await ref.watch(accountsProvider.future);
  final accountService = ref.watch(accountServiceProvider);
  final balanceMap = await accountService.getAccountBalanceMap();

  final assets = <AccountItem>[];
  final liabilities = <AccountItem>[];

  for (final account in accounts) {
    final balance = balanceMap[account.id] ?? 0.0;
    final item = AccountItem(
      name: account.name,
      balance: balance.abs(),
      accountType: account.accountType,
      colorValue: account.colorValue,
    );

    if (account.accountType == AccountType.creditCard) {
      if (balance > 0) {
        liabilities.add(item);
      }
    } else {
      if (balance >= 0) {
        assets.add(item);
      } else {
        liabilities.add(item);
      }
    }
  }

  final totalAssets = assets.fold(0.0, (sum, item) => sum + item.balance);
  final totalLiabilities =
      liabilities.fold(0.0, (sum, item) => sum + item.balance);
  final netWorth = totalAssets - totalLiabilities;

  // Calculate monthly change from balance history
  final now = DateTime.now();
  final lastMonth = DateTime(now.year, now.month - 1, now.day);
  double lastMonthNetWorth = 0.0;

  for (final account in accounts) {
    final lastBalance = await BalanceHistoryService.instance
        .getBalanceOnDate(account.id, lastMonth);
    if (lastBalance != null) {
      if (account.accountType == AccountType.creditCard) {
        lastMonthNetWorth -= lastBalance.abs();
      } else {
        lastMonthNetWorth += lastBalance;
      }
    }
  }

  final monthlyChange = netWorth - lastMonthNetWorth;

  return NetWorthData(
    netWorth: netWorth,
    totalAssets: totalAssets,
    totalLiabilities: totalLiabilities,
    monthlyChange: monthlyChange,
    assets: assets,
    liabilities: liabilities,
  );
});

final netWorthHistoryProvider = FutureProvider.autoDispose((ref) async {
  final accounts = await ref.watch(accountsProvider.future);
  final now = DateTime.now();
  final startDate = now.subtract(const Duration(days: 30));

  final dailyNetWorth = <NetWorthHistoryPoint>[];

  for (int i = 0; i <= 30; i++) {
    final date = startDate.add(Duration(days: i));
    double dayNetWorth = 0.0;

    for (final account in accounts) {
      final balance = await BalanceHistoryService.instance
          .getBalanceOnDate(account.id, date);
      if (balance != null) {
        if (account.accountType == AccountType.creditCard) {
          dayNetWorth -= balance.abs();
        } else {
          dayNetWorth += balance;
        }
      }
    }

    dailyNetWorth.add(NetWorthHistoryPoint(date: date, netWorth: dayNetWorth));
  }

  return dailyNetWorth;
});

class NetWorthData {
  final double netWorth;
  final double totalAssets;
  final double totalLiabilities;
  final double monthlyChange;
  final List<AccountItem> assets;
  final List<AccountItem> liabilities;

  NetWorthData({
    required this.netWorth,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.monthlyChange,
    required this.assets,
    required this.liabilities,
  });
}

class AccountItem {
  final String name;
  final double balance;
  final AccountType accountType;
  final int? colorValue;

  AccountItem({
    required this.name,
    required this.balance,
    required this.accountType,
    this.colorValue,
  });
}

class NetWorthHistoryPoint {
  final DateTime date;
  final double netWorth;

  NetWorthHistoryPoint({required this.date, required this.netWorth});
}

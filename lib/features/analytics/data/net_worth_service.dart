import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/account/data/balance_history_provider.dart';

final netWorthProvider = FutureProvider.autoDispose((ref) async {
  final accounts = await ref.watch(accountsProvider.future);
  final accountService = ref.watch(accountServiceProvider);
  final balanceMap = await accountService.getAccountBalanceMap();
  final baseBalanceMap = await accountService.getAccountBalanceMapInBase();

  final assets = <AccountItem>[];
  final liabilities = <AccountItem>[];

  double totalAssets = 0;
  double totalLiabilities = 0;

  for (final account in accounts) {
    final balance = balanceMap[account.id] ?? 0.0;
    final baseBalance = baseBalanceMap[account.id] ?? 0.0;
    final item = AccountItem(
      name: account.name,
      balance: balance.abs(),
      accountType: account.accountType,
      colorValue: account.colorValue,
      currencyCode: account.currencyCode,
    );

    if (account.accountType == AccountType.creditCard) {
      if (balance > 0) {
        liabilities.add(item);
        totalLiabilities += baseBalance.abs();
      }
    } else {
      if (balance >= 0) {
        assets.add(item);
        totalAssets += baseBalance.abs();
      } else {
        liabilities.add(item);
        totalLiabilities += baseBalance.abs();
      }
    }
  }

  final netWorth = totalAssets - totalLiabilities;

  // Calculate monthly change from balance history
  // BOLT OPTIMIZATION: Parallelize async calls to reduce sequential wait time
  final now = DateTime.now();
  final lastMonth = DateTime(now.year, now.month - 1, now.day);

  final lastBalances = await Future.wait(
    accounts.map(
      (a) => ref
          .read(balanceHistoryServiceProvider)
          .getBalanceOnDate(a.id, lastMonth),
    ),
  );

  double lastMonthNetWorth = 0.0;
  for (int i = 0; i < accounts.length; i++) {
    final balance = lastBalances[i];
    if (balance != null) {
      if (accounts[i].accountType == AccountType.creditCard) {
        lastMonthNetWorth -= balance.abs();
      } else {
        lastMonthNetWorth += balance;
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

  // BOLT OPTIMIZATION: Parallelize balance lookups to avoid O(D * A) sequential awaits.
  // Each day depends on all accounts, so we can parallelize by day or by account.
  // Parallelizing by day ensures we get results as fast as the slowest day.
  for (int i = 0; i <= 30; i++) {
    final date = startDate.add(Duration(days: i));

    final balances = await Future.wait(
      accounts.map(
        (a) => ref.read(balanceHistoryServiceProvider).getBalanceOnDate(a.id, date),
      ),
    );

    double dayNetWorth = 0.0;
    for (int j = 0; j < accounts.length; j++) {
      final balance = balances[j];
      if (balance != null) {
        if (accounts[j].accountType == AccountType.creditCard) {
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
  final String? currencyCode;

  AccountItem({
    required this.name,
    required this.balance,
    required this.accountType,
    this.colorValue,
    this.currencyCode,
  });
}

class NetWorthHistoryPoint {
  final DateTime date;
  final double netWorth;

  NetWorthHistoryPoint({required this.date, required this.netWorth});
}

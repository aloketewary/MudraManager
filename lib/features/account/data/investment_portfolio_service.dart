import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/investment_holding.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';

class InvestmentPortfolioService {
  final IsarService isarService;
  final AppLog _log = AppLog(getLogger(), 'InvestmentPortfolioService');

  InvestmentPortfolioService(this.isarService);

  Future<void> addHolding(InvestmentHolding holding, int accountId) async {
    try {
      final isar = await isarService.getInstance();
      final account = await isar.accounts.get(accountId);
      if (account == null) {
        _log.e('Account not found: $accountId');
        throw Exception('Account not found');
      }
      holding.account.value = account;
      await isar.writeTxn(() async {
        await isar.investmentHoldings.put(holding);
        await holding.account.save();
      });
      _log.i('Holding added: ${holding.symbol}, Account: ${account.name}');
    } catch (e) {
      _log.e('Error adding holding: $e');
      rethrow;
    }
  }

  Future<void> updatePrice(int holdingId, double newPrice) async {
    final isar = await isarService.getInstance();
    final holding = await isar.investmentHoldings.get(holdingId);
    if (holding != null) {
      holding.currentPrice = newPrice;
      await isar.writeTxn(() => isar.investmentHoldings.put(holding));
      _log.i('Price updated for ${holding.symbol}: ${BaseCurrency.symbol}$newPrice');
    }
  }

  Future<List<InvestmentHolding>> getPortfolio(int accountId) async {
    final isar = await isarService.getInstance();
    final holdings = await isar.investmentHoldings.where().findAll();
    for (var h in holdings) {
      await h.account.load();
    }
    _log.i('Total holdings in DB: ${holdings.length}');
    for (var h in holdings) {
      _log.i('Holding: ${h.symbol}, Account ID: ${h.account.value?.id}');
    }
    final filtered = holdings.where((h) => h.account.value?.id == accountId).toList();
    _log.i('Filtered holdings for account $accountId: ${filtered.length}');
    return filtered;
  }

  Future<Map<String, double>> getPortfolioMetrics(int accountId) async {
    final holdings = await getPortfolio(accountId);

    double totalCost = 0;
    double totalValue = 0;

    for (final holding in holdings) {
      totalCost += holding.totalCost;
      totalValue += holding.currentValue;
    }

    final gainLoss = totalValue - totalCost;
    final gainLossPercent = totalCost > 0 ? (gainLoss / totalCost) * 100 : 0;

    return {
      'totalCost': totalCost,
      'totalValue': totalValue,
      'gainLoss': gainLoss,
      'gainLossPercent': gainLossPercent.toDouble(),
    };
  }

  Future<void> deleteHolding(int holdingId) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() => isar.investmentHoldings.delete(holdingId));
    _log.i('Holding deleted: $holdingId');
  }
}

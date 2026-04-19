import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';import 'package:mudra_manager/core/services/app_config_service.dart';

final currencyServiceProvider = FutureProvider<CurrencyService>((ref) async {
  final isar = await ref.watch(isarServiceProvider).getInstance();
  final config = AppConfigService(isar);
  final service = CurrencyService(isar, config);
  await service.seedIfEmpty();
  // Sync static accessor
  final base = await service.getBaseCurrency();
  BaseCurrency.sync(base);
  return service;
});

final baseCurrencyProvider = FutureProvider<String>((ref) async {
  final service = await ref.watch(currencyServiceProvider.future);
  return service.getBaseCurrency();
});

/// Returns the icon for the current base currency.
final baseCurrencyIconProvider = Provider<IconData>((ref) {
  final code = ref.watch(baseCurrencyProvider).value;
  return currencyIcon(code);
});

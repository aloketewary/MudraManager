import 'package:mudra_manager/core/providers/state_value.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/currency/currency_provider.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/providers/l10n_provider.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/features/category/data/category_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/features/gamification/data/gamification_service.dart';

final _isarService = IsarService();
final isarServiceProvider = Provider<IsarService>((ref) => _isarService);

final gamificationServiceInitProvider = FutureProvider<GamificationService>((ref) async {
  final isar = await ref.watch(isarServiceProvider).getInstance();
  final service = GamificationService(isar, ref.getLogger('GemificationService'));
  await service.initialize();
  return service;
});

/// Full provider reset — only for currency change (all amounts recalculate).
/// Do NOT use for normal operations — reactive watchers handle those.
void invalidateAfterCurrencyChange(WidgetRef ref) {
  ref.invalidate(currencyServiceProvider);
  ref.invalidate(baseCurrencyProvider);
  ref.invalidate(accountServiceProvider);
  ref.invalidate(accountsProvider);
  ref.invalidate(categoryListProvider);
  ref.invalidate(categoryServiceProvider);
  ref.invalidate(localeProvider);
  ref.invalidate(budgetServiceProvider);
  ref.invalidate(budgetsWithProgressProvider);
  ref.invalidate(transactionProvider);
  ref.invalidate(transactionCountsProvider);
  ref.invalidate(dashboardDataProvider);
}

final reminderTimeProvider = NotifierProvider<StateValue<TimeOfDay?>, TimeOfDay?>(
  () => StateValue(null),
);
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/providers/l10n_provider.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/features/category/data/category_provider.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/features/gamification/services/gamification_service.dart';

final isarServiceProvider = Provider<IsarService>((ref) => IsarService());

final gamificationServiceInitProvider = FutureProvider<GamificationService>((ref) async {
  final isar = await ref.watch(isarServiceProvider).getInstance();
  return GamificationService(isar, ref.getLogger('GemificationService'));
});

void invalidateAll(WidgetRef ref) {
  ref.invalidate(accountServiceProvider);
  ref.invalidate(categoryListProvider);
  ref.invalidate(categoryServiceProvider);
  ref.invalidate(localeProvider);
  ref.invalidate(budgetServiceProvider);
  ref.invalidate(transactionProvider);
  ref.invalidate(transactionCountsProvider);
}

final reminderTimeProvider = StateProvider<TimeOfDay?>((ref) => null);
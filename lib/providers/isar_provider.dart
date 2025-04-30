import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/db/isar_service.dart' show IsarService;
import 'package:mudra_manager/providers/account_providers.dart';
import 'package:mudra_manager/providers/budget_service_provider.dart';
import 'package:mudra_manager/providers/category_provider.dart';
import 'package:mudra_manager/providers/l10n_provider.dart';
import 'package:mudra_manager/providers/transaction_provider.dart';

final isarServiceProvider = Provider<IsarService>((ref) => IsarService());

void invalidateAll(WidgetRef ref) {
  ref.invalidate(accountServiceProvider);
  ref.invalidate(categoryListProvider);
  ref.invalidate(categoryServiceProvider);
  ref.invalidate(localeProvider);
  ref.invalidate(budgetServiceProvider);
  ref.invalidate(transactionProvider);
  ref.invalidate(transactionCountsProvider);
}

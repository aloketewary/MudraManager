import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/db/models/recurring_transaction.dart';
import 'package:mudra_manager/providers/isar_provider.dart';
import 'package:mudra_manager/service/recurring_transaction_service.dart';

final recurringTransactionServiceProvider = Provider<RecurringTransactionService>((ref) {
  return RecurringTransactionService(ref.watch(isarServiceProvider));
});

final recurringTransactionsProvider = StreamProvider<List<RecurringTransaction>>((ref) {
  return ref.watch(recurringTransactionServiceProvider).watchAll();
});

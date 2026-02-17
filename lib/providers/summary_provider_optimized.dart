// lib/providers/summary_provider_optimized.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/db/models/transaction.dart';
import 'package:mudra_manager/providers/isar_provider.dart';

// OPTIMIZED: Use database aggregation instead of loading all transactions
final incomeExpenseSummaryProvider = FutureProvider<Map<String, double>>((ref) async {
  final isar = await ref.watch(isarServiceProvider).getInstance();

  // Single aggregation query for income
  final income = await isar.transactions
      .filter()
      .isExpenseEqualTo(false)
      .isTransferEqualTo(false)
      .amountProperty()
      .sum();

  // Single aggregation query for expense
  final expense = await isar.transactions
      .filter()
      .isExpenseEqualTo(true)
      .isTransferEqualTo(false)
      .amountProperty()
      .sum();

  return {
    'income': income,
    'expense': expense,
  };
});

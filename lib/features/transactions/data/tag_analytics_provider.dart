import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/collection_watchers.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';

class TagSpending {
  final Tag tag;
  final double amount;
  final int count;

  TagSpending({required this.tag, required this.amount, required this.count});
}

final tagSpendingProvider = FutureProvider.autoDispose
    .family<List<TagSpending>, String>((ref, period) async {
  ref.watch(transactionChangeProvider);
  final isar = await ref.watch(isarServiceProvider).getInstance();
  final now = DateTime.now();

  DateTime start;
  switch (period) {
    case 'Today':
      start = DateTime(now.year, now.month, now.day);
      break;
    case 'Week':
      start = now.subtract(const Duration(days: 6));
      break;
    case 'Month':
      start = DateTime(now.year, now.month, 1);
      break;
    case 'Year':
      start = DateTime(now.year, 1, 1);
      break;
    default:
      start = DateTime(2000);
  }

  final tags = await isar.tags.where().findAll();
  if (tags.isEmpty) return [];

  final expenses = await isar.transactions
      .filter()
      .isExpenseEqualTo(true)
      .isTransferEqualTo(false)
      .dateBetween(start, now)
      .findAll();

  final result = <TagSpending>[];
  for (final tag in tags) {
    final tagged = expenses.where((tx) {
      tx.tags.loadSync();
      return tx.tags.any((t) => t.id == tag.id);
    }).toList();

    if (tagged.isNotEmpty) {
      final total = tagged.fold<double>(0, (sum, tx) => sum + tx.amount);
      result.add(TagSpending(tag: tag, amount: total, count: tagged.length));
    }
  }

  result.sort((a, b) => b.amount.compareTo(a.amount));
  return result;
});

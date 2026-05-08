import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/collection_watchers.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';

class DetectedSubscription {
  final String name;
  final double avgAmount;
  final int occurrences;
  final DateTime lastSeen;
  final int? estimatedDayOfMonth;

  const DetectedSubscription({
    required this.name,
    required this.avgAmount,
    required this.occurrences,
    required this.lastSeen,
    this.estimatedDayOfMonth,
  });

  double get monthlyTotal => avgAmount;
}

final detectedSubscriptionsProvider =
    FutureProvider.autoDispose<List<DetectedSubscription>>((ref) async {
  ref.watch(transactionChangeProvider);

  final isar = await ref.watch(isarServiceProvider).getInstance();
  final cutoff = DateTime.now().subtract(const Duration(days: 120));

  // Get SMS-imported expense transactions from last 4 months
  final txns = await isar.transactions
      .filter()
      .isFromSmsEqualTo(true)
      .isExpenseEqualTo(true)
      .isTransferEqualTo(false)
      .dateGreaterThan(cutoff)
      .sortByDateDesc()
      .findAll();

  // Group by normalized description, falling back to category
  final groups = <String, List<Transaction>>{};
  for (final t in txns) {
    var key = _normalizeKey(t.description ?? '');
    if (key.isEmpty) {
      await t.category.load();
      key = _normalizeKey(t.category.value?.name ?? '');
    }
    if (key.isEmpty) continue;
    groups.putIfAbsent(key, () => []).add(t);
  }

  final results = <DetectedSubscription>[];

  for (final entry in groups.entries) {
    final list = entry.value;
    if (list.length < 2) continue;

    // Check if amounts are similar (within 10% of median)
    final amounts = list.map((t) => t.baseAmount).toList()..sort();
    final median = amounts[amounts.length ~/ 2];
    if (median <= 0) continue;
    final consistent = amounts.every(
      (a) => (a - median).abs() / median < 0.10,
    );
    if (!consistent) continue;

    // Check if intervals are roughly monthly (25-35 days between occurrences)
    list.sort((a, b) => a.date.compareTo(b.date));
    bool isMonthly = true;
    for (int i = 1; i < list.length; i++) {
      final gap = list[i].date.difference(list[i - 1].date).inDays;
      if (gap < 20 || gap > 40) {
        isMonthly = false;
        break;
      }
    }
    if (!isMonthly) continue;

    final avg = amounts.reduce((a, b) => a + b) / amounts.length;
    final dayOfMonth = _estimateDayOfMonth(list);

    results.add(DetectedSubscription(
      name: _displayName(list.first),
      avgAmount: avg,
      occurrences: list.length,
      lastSeen: list.last.date,
      estimatedDayOfMonth: dayOfMonth,
    ),);
  }

  // Sort by amount descending
  results.sort((a, b) => b.avgAmount.compareTo(a.avgAmount));
  return results;
});

String _normalizeKey(String desc) {
  return desc
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _displayName(Transaction t) {
  final desc = t.description?.trim() ?? '';
  final name = desc.isNotEmpty ? desc : (t.category.value?.name ?? 'Unknown');
  return name.length > 30 ? '${name.substring(0, 27)}...' : name;
}

int? _estimateDayOfMonth(List<Transaction> txns) {
  if (txns.isEmpty) return null;
  final days = txns.map((t) => t.date.day).toList();
  // Most common day
  final freq = <int, int>{};
  for (final d in days) {
    freq[d] = (freq[d] ?? 0) + 1;
  }
  final sorted = freq.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return sorted.first.key;
}

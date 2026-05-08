import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';

class SmartDefaults {
  final Category? suggestedCategory;
  final Account? suggestedAccount;
  final double? suggestedAmount;
  final String? reason;

  const SmartDefaults({
    this.suggestedCategory,
    this.suggestedAccount,
    this.suggestedAmount,
    this.reason,
  });
}

final smartDefaultsProvider = FutureProvider.autoDispose
    .family<SmartDefaults, bool>((ref, isExpense) async {
  final isar = await ref.watch(isarServiceProvider).getInstance();
  final now = DateTime.now();
  final hour = now.hour;
  final dayOfWeek = now.weekday;

  final cutoff = now.subtract(const Duration(days: 90));
  final transactions = await isar.transactions
      .filter()
      .isExpenseEqualTo(isExpense)
      .isTransferEqualTo(false)
      .dateGreaterThan(cutoff)
      .findAll();

  if (transactions.length < 5) return const SmartDefaults();

  // Load links for all transactions
  for (final tx in transactions) {
    await tx.category.load();
    await tx.account.load();
  }

  final scores = <int, _CatScore>{};
  for (final tx in transactions) {
    final catId = tx.category.value?.id;
    if (catId == null) continue;

    final entry = scores.putIfAbsent(catId, () => _CatScore());
    entry.count++;
    entry.totalAmount += tx.baseAmount;

    final txHour = tx.date.hour;
    if ((txHour - hour).abs() <= 2 || (txHour - hour).abs() >= 22) {
      entry.timeScore += 3;
    }
    if (tx.date.weekday == dayOfWeek) {
      entry.dayScore += 2;
    }
  }

  if (scores.isEmpty) return const SmartDefaults();

  final ranked = scores.entries.toList()
    ..sort((a, b) {
      final scoreA = a.value.count + a.value.timeScore + a.value.dayScore;
      final scoreB = b.value.count + b.value.timeScore + b.value.dayScore;
      return scoreB.compareTo(scoreA);
    });

  final bestId = ranked.first.key;
  final bestScore = ranked.first.value;

  final totalScore = bestScore.count + bestScore.timeScore + bestScore.dayScore;
  if (totalScore < 5) return const SmartDefaults();

  final category = await isar.categorys.get(bestId);
  if (category != null) await category.parentCategory.load();

  // Suggest median amount for this category
  final catTxns =
      transactions.where((t) => t.category.value?.id == bestId).toList();
  final amounts = catTxns.map((t) => t.amount).toList()..sort();
  final median = amounts.isNotEmpty ? amounts[amounts.length ~/ 2] : null;

  // Find most-used account for this category
  final accountCounts = <int, int>{};
  for (final tx in catTxns) {
    final accId = tx.account.value?.id;
    if (accId != null) {
      accountCounts[accId] = (accountCounts[accId] ?? 0) + 1;
    }
  }
  Account? suggestedAccount;
  if (accountCounts.isNotEmpty) {
    final bestAccId = (accountCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .first
        .key;
    suggestedAccount = await isar.accounts.get(bestAccId);
    // Only suggest if account is still active
    if (suggestedAccount?.isActive == false) suggestedAccount = null;
  }

  final reason = bestScore.timeScore > 0
      ? 'You often spend on ${category?.name} around this time'
      : 'Your most frequent category';

  return SmartDefaults(
    suggestedCategory: category,
    suggestedAccount: suggestedAccount,
    suggestedAmount: median,
    reason: reason,
  );
});

class _CatScore {
  int count = 0;
  double totalAmount = 0;
  int timeScore = 0;
  int dayScore = 0;
}

/// Returns top 8 most-used categories for the given type (expense/income).
/// Used by compact quick-add mode.
final frequentCategoriesProvider = FutureProvider.autoDispose
    .family<List<Category>, bool>((ref, isExpense) async {
  final isar = await ref.watch(isarServiceProvider).getInstance();
  final cutoff = DateTime.now().subtract(const Duration(days: 90));
  final transactions = await isar.transactions
      .filter()
      .isExpenseEqualTo(isExpense)
      .isTransferEqualTo(false)
      .dateGreaterThan(cutoff)
      .findAll();

  final counts = <int, int>{};
  final catMap = <int, Category>{};
  for (final tx in transactions) {
    await tx.category.load();
    final cat = tx.category.value;
    if (cat == null) continue;
    counts[cat.id] = (counts[cat.id] ?? 0) + 1;
    catMap[cat.id] = cat;
  }

  if (counts.isEmpty) {
    // Fallback: return first 8 categories of the type
    final cats = await isar.categorys
        .filter()
        .categoryTypeEqualTo(
          isExpense ? CategoryType.expense : CategoryType.income,
        )
        .limit(8)
        .findAll();
    return cats;
  }

  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return sorted.take(8).map((e) => catMap[e.key]!).toList();
});

/// Returns the primary or most-used account.
final lastUsedAccountProvider = FutureProvider.autoDispose<Account?>((ref) async {
  final isar = await ref.watch(isarServiceProvider).getInstance();

  // Try primary account first
  final primary = await isar.accounts
      .filter()
      .isPrimaryEqualTo(true)
      .isActiveEqualTo(true)
      .findFirst();
  if (primary != null) return primary;

  // Fallback: most recent transaction's account
  final recent = await isar.transactions
      .where()
      .sortByDateDesc()
      .findFirst();
  if (recent != null) {
    await recent.account.load();
    if (recent.account.value?.isActive == true) return recent.account.value;
  }

  // Fallback: first active account
  return await isar.accounts
      .filter()
      .isActiveEqualTo(true)
      .findFirst();
});

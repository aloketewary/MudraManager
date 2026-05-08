import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/frequency.dart';
import 'package:mudra_manager/core/db/isar_service.dart';

class RecurringDetectorService {
  static const _minOccurrences = 2;
  final IsarService _isarService;

  RecurringDetectorService(this._isarService);

  /// Called after every transaction save (manual or SMS).
  /// First tries to link to an existing recurring bill by exact amount + account + date window.
  /// If no match, falls back to pattern detection from history.
  Future<void> detectAndTagRecurring(Transaction newTransaction) async {
    final isar = await _isarService.getInstance();

    if (newTransaction.recurringTransactionSource.value != null) return;

    // ── Step 1: Try exact match against existing recurring bills ──
    final linked = await _tryLinkToExistingRecurring(isar, newTransaction);
    if (linked) return;

    // ── Step 2: Pattern detection from transaction history ──
    await _detectPatternFromHistory(isar, newTransaction);
  }

  /// Match by exact amount, same account, within the recurring bill's date window.
  Future<bool> _tryLinkToExistingRecurring(
    Isar isar,
    Transaction newTransaction,
  ) async {
    await newTransaction.account.load();
    await newTransaction.category.load();
    final accountId = newTransaction.account.value?.id;
    if (accountId == null) return false;

    final activeRecurring = await isar.recurringTransactions
        .filter()
        .isActiveEqualTo(true)
        .amountBetween(
          newTransaction.amount - 0.01,
          newTransaction.amount + 0.01,
        )
        .isExpenseEqualTo(newTransaction.isExpense)
        .findAll();

    for (final recurring in activeRecurring) {
      await recurring.account.load();
      if (recurring.account.value?.id != accountId) continue;

      // Check if transaction date is within the billing period
      // (5 days before due to 2 days after)
      final dueDate = recurring.nextDueDate;
      final windowStart = dueDate.subtract(const Duration(days: 5));
      final windowEnd = dueDate.add(const Duration(days: 2));
      if (newTransaction.date.isBefore(windowStart) ||
          newTransaction.date.isAfter(windowEnd)) {
        continue;
      }

      // Check not already linked for this period
      final alreadyLinked = await isar.transactions
          .filter()
          .recurringTransactionSource((q) => q.idEqualTo(recurring.id))
          .dateBetween(windowStart, windowEnd)
          .count();
      if (alreadyLinked > 0) continue;

      // Exact match found — link it
      await isar.writeTxn(() async {
        newTransaction.recurringTransactionSource.value = recurring;
        await newTransaction.recurringTransactionSource.save();
        await isar.transactions.put(newTransaction);
      });
      return true;
    }
    return false;
  }

  /// Fallback: detect recurring pattern from similar past transactions.
  Future<void> _detectPatternFromHistory(
    Isar isar,
    Transaction newTransaction,
  ) async {
    final startDate = newTransaction.date.subtract(const Duration(days: 90));
    final similar = await isar.transactions
        .filter()
        .dateBetween(startDate, newTransaction.date)
        .and()
        .isExpenseEqualTo(newTransaction.isExpense)
        .amountBetween(
          newTransaction.amount - 0.01,
          newTransaction.amount + 0.01,
        )
        .findAll();

    // Filter by same category
    final matches = similar.where((t) {
      if (t.id == newTransaction.id) return false;
      return t.category.value?.id == newTransaction.category.value?.id;
    }).toList();

    if (matches.length < _minOccurrences) return;

    final pattern = _detectFrequency(matches, newTransaction);
    if (pattern == null) return;

    // Check if recurring transaction already exists for this pattern
    final existing = await isar.recurringTransactions
        .filter()
        .amountBetween(
          newTransaction.amount - 0.01,
          newTransaction.amount + 0.01,
        )
        .and()
        .isExpenseEqualTo(newTransaction.isExpense)
        .findAll();

    final matchingRecurring = existing
        .where(
          (r) =>
              r.category.value?.id == newTransaction.category.value?.id &&
              r.frequency == pattern,
        )
        .firstOrNull;

    if (matchingRecurring != null) {
      await isar.writeTxn(() async {
        newTransaction.recurringTransactionSource.value = matchingRecurring;
        await newTransaction.recurringTransactionSource.save();
        await isar.transactions.put(newTransaction);
      });
    } else {
      final recurring = RecurringTransaction()
        ..amount = newTransaction.amount
        ..isExpense = newTransaction.isExpense
        ..description = newTransaction.description
        ..frequency = pattern
        ..startDate = matches.first.date
        ..nextDueDate = _calculateNextDue(newTransaction.date, pattern)
        ..isActive = true;

      recurring.category.value = newTransaction.category.value;
      recurring.account.value = newTransaction.account.value;

      await isar.writeTxn(() async {
        await isar.recurringTransactions.put(recurring);
        await recurring.category.save();
        await recurring.account.save();

        for (final match in [...matches, newTransaction]) {
          match.recurringTransactionSource.value = recurring;
          await match.recurringTransactionSource.save();
          await isar.transactions.put(match);
        }
      });
    }
  }

  static Frequency? _detectFrequency(
    List<Transaction> transactions,
    Transaction latest,
  ) {
    final allDates = [...transactions.map((t) => t.date), latest.date]..sort();
    if (allDates.length < 2) return null;

    final intervals = <int>[];
    for (int i = 1; i < allDates.length; i++) {
      intervals.add(allDates[i].difference(allDates[i - 1]).inDays);
    }

    final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;

    // Monthly (25-35 days)
    if (avgInterval >= 25 && avgInterval <= 35) return Frequency.monthly;
    // Weekly (5-9 days)
    if (avgInterval >= 5 && avgInterval <= 9) return Frequency.weekly;
    // Yearly (350-380 days)
    if (avgInterval >= 350 && avgInterval <= 380) return Frequency.yearly;

    return null;
  }

  static DateTime _calculateNextDue(DateTime lastDate, Frequency frequency) {
    switch (frequency) {
      case Frequency.daily:
        return lastDate.add(const Duration(days: 1));
      case Frequency.weekly:
        return lastDate.add(const Duration(days: 7));
      case Frequency.monthly:
        return DateTime(lastDate.year, lastDate.month + 1, lastDate.day);
      case Frequency.yearly:
        return DateTime(lastDate.year + 1, lastDate.month, lastDate.day);
    }
  }
}

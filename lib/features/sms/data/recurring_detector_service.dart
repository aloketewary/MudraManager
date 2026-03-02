import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/frequency.dart';
import 'package:mudra_manager/core/db/isar_service.dart';

class RecurringDetectorService {
  static const _similarAmountThreshold = 0.05; // 5% variance
  static const _minOccurrences = 2; // Need 2+ occurrences to detect pattern

  static Future<void> detectAndTagRecurring(Transaction newTransaction) async {
    final isar = await IsarService().getInstance();

    // Skip if already linked to recurring
    if (newTransaction.recurringTransactionSource.value != null) return;

    // Look for similar transactions in past 90 days
    final startDate = newTransaction.date.subtract(const Duration(days: 90));
    final similar = await isar.transactions
        .filter()
        .dateBetween(startDate, newTransaction.date)
        .and()
        .isExpenseEqualTo(newTransaction.isExpense)
        .findAll();

    // Filter by amount similarity and same category
    final matches = similar.where((t) {
      if (t.id == newTransaction.id) return false;
      final amountDiff =
          (t.amount - newTransaction.amount).abs() / newTransaction.amount;
      return amountDiff <= _similarAmountThreshold &&
          t.category.value?.id == newTransaction.category.value?.id;
    }).toList();

    if (matches.length < _minOccurrences) return;

    // Detect frequency pattern
    final pattern = _detectFrequency(matches, newTransaction);
    if (pattern == null) return;

    // Check if recurring transaction already exists
    final existing = await isar.recurringTransactions
        .filter()
        .amountBetween(
          newTransaction.amount * (1 - _similarAmountThreshold),
          newTransaction.amount * (1 + _similarAmountThreshold),
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
      // Link to existing recurring
      await isar.writeTxn(() async {
        newTransaction.recurringTransactionSource.value = matchingRecurring;
        await newTransaction.recurringTransactionSource.save();
        await isar.transactions.put(newTransaction);
      });
    } else {
      // Create new recurring transaction
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

        // Link all matching transactions
        for (final match in [...matches, newTransaction]) {
          match.recurringTransactionSource.value = recurring;
          await match.recurringTransactionSource.save();
          await isar.transactions.put(match);
        }
      });
    }
  }

  static Frequency? _detectFrequency(
      List<Transaction> transactions, Transaction latest) {
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

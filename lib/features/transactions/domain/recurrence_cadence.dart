import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/frequency.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';

/// Shared cadence rules used before an observed transaction is linked to a
/// configured recurring transaction.
class RecurrenceCadence {
  const RecurrenceCadence._();

  /// Allows a missed occurrence, but rejects a different cadence.
  static bool matches(Frequency frequency, Iterable<DateTime> dates) {
    final normalizedDates = dates
        .map((date) => DateTime(date.year, date.month, date.day))
        .toSet()
        .toList()
      ..sort();

    if (normalizedDates.length < 2) return true;

    final intervals = <int>[];
    for (var index = 1; index < normalizedDates.length; index++) {
      intervals.add(
        normalizedDates[index].difference(normalizedDates[index - 1]).inDays,
      );
    }

    return intervals.every((interval) {
      switch (frequency) {
        case Frequency.daily:
          return interval >= 1 && interval <= 2;
        case Frequency.weekly:
          return interval >= 5 && interval <= 9;
        case Frequency.monthly:
          return interval >= 25 && interval <= 40;
        case Frequency.yearly:
          return interval >= 350 && interval <= 380;
      }
    });
  }

  /// Checks candidate plus comparable transaction history for a recurrence.
  ///
  /// A single observed payment is accepted because cadence cannot be inferred
  /// yet. Once history exists, every observed interval must fit the configured
  /// frequency. This prevents a monthly bill from absorbing weekly payments.
  static Future<bool> matchesTransaction({
    required Isar isar,
    required Transaction candidate,
    required RecurringTransaction recurring,
  }) async {
    final accountId = candidate.account.value?.id;
    if (accountId == null) return false;

    final historyStart = candidate.date.subtract(const Duration(days: 800));
    final history = await isar.transactions
        .filter()
        .isTransferEqualTo(false)
        .isExpenseEqualTo(candidate.isExpense)
        .amountBetween(candidate.amount - 0.01, candidate.amount + 0.01)
        .dateBetween(historyStart, candidate.date)
        .findAll();

    final dates = <DateTime>[candidate.date];
    for (final transaction in history) {
      if (transaction.id == candidate.id) continue;
      await transaction.account.load();
      if (transaction.account.value?.id == accountId) {
        dates.add(transaction.date);
      }
    }

    return matches(recurring.frequency, dates);
  }
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/frequency.dart';
import 'package:mudra_manager/core/utils/date_arithmetic.dart';

/// Characterization tests for the unfixed recurring processor.
///
/// The processor currently reads DateTime.now() internally, so deterministic
/// schedule vectors are paired with source-level gates for the service's
/// processing loop. These tests intentionally fail on the audited revision;
/// they must be rerun unchanged after the production fix.
void main() {
  final serviceSource = File(
    'lib/features/transactions/data/recurring_transaction_service.dart',
  ).readAsStringSync();
  final processBody = serviceSource.substring(
    serviceSource.indexOf('Future<void> processRecurringTransactions()'),
    serviceSource.indexOf('/// Find an unlinked transaction'),
  );

  group('Property 1 — recurring catch-up bug condition', () {
    final vectors = <({
      String name,
      Frequency frequency,
      DateTime firstDue,
      DateTime processingDate,
      List<DateTime> eligible,
    })>[
      (
        name: 'daily',
        frequency: Frequency.daily,
        firstDue: DateTime(2025, 4, 1),
        processingDate: DateTime(2025, 4, 5),
        eligible: [
          DateTime(2025, 4, 1),
          DateTime(2025, 4, 2),
          DateTime(2025, 4, 3),
        ],
      ),
      (
        name: 'weekly',
        frequency: Frequency.weekly,
        firstDue: DateTime(2025, 3, 1),
        processingDate: DateTime(2025, 4, 5),
        eligible: [DateTime(2025, 3, 1), DateTime(2025, 3, 8), DateTime(2025, 3, 15), DateTime(2025, 3, 22), DateTime(2025, 3, 29)],
      ),
      (
        name: 'monthly with stale month-end schedule',
        frequency: Frequency.monthly,
        firstDue: DateTime(2025, 1, 31),
        processingDate: DateTime(2025, 4, 5),
        eligible: [DateTime(2025, 1, 31), DateTime(2025, 2, 28), DateTime(2025, 3, 31)],
      ),
      (
        name: 'yearly',
        frequency: Frequency.yearly,
        firstDue: DateTime(2023, 4, 1),
        processingDate: DateTime(2025, 4, 5),
        eligible: [DateTime(2023, 4, 1), DateTime(2024, 4, 1), DateTime(2025, 4, 1)],
      ),
    ];

    for (final vector in vectors) {
      test('${vector.name}: schedule has exact chronological eligible dates', () {
        final actual = _eligibleDates(
          firstDue: vector.firstDue,
          frequency: vector.frequency,
          processingDate: vector.processingDate,
          startDate: vector.firstDue,
        );
        expect(actual, vector.eligible);
        expect(_isStrictlyIncreasing(actual), isTrue);
        expect(actual.every((date) => !date.isAfter(vector.processingDate)), isTrue);
      });
    }

    test('service loops through every elapsed due date, not one occurrence', () {
      expect(
        processBody,
        contains('while'),
        reason: 'Counterexample: stale monthly template Jan 31 → Apr 5 currently processes only Jan 31.',
      );
    });

    test('existing linked occurrence advances schedule before continuing', () {
      final existsBlock = processBody.substring(
        processBody.indexOf('if (exists)'),
        processBody.indexOf('// Try to match with an existing SMS-imported transaction'),
      );
      expect(
        existsBlock,
        contains('_updateNextDueDate'),
        reason: 'Counterexample: existing linked January occurrence is skipped while nextDueDate remains January.',
      );
    });

    test('occurrence processing is idempotent per exact template/date', () {
      expect(processBody, contains('_transactionExists'));
      expect(
        processBody,
        contains('dueDate'),
        reason: 'Each rerun must check exact scheduled occurrence date before write.',
      );
    });
  });
}

List<DateTime> _eligibleDates({
  required DateTime firstDue,
  required Frequency frequency,
  required DateTime processingDate,
  required DateTime startDate,
}) {
  final dates = <DateTime>[];
  var due = firstDue;
  final cutoff = processingDate.subtract(const Duration(days: 2));
  while (!due.isAfter(cutoff)) {
    dates.add(due);
    due = _nextDue(due, frequency, startDate);
  }
  return dates;
}

DateTime _nextDue(DateTime current, Frequency frequency, DateTime startDate) {
  switch (frequency) {
    case Frequency.daily:
      return current.add(const Duration(days: 1));
    case Frequency.weekly:
      return current.add(const Duration(days: 7));
    case Frequency.monthly:
      return DateArithmetic.addMonths(current, 1, preferDay: startDate.day);
    case Frequency.yearly:
      return DateArithmetic.addYears(current, 1, preferDay: startDate.day);
  }
}

bool _isStrictlyIncreasing(List<DateTime> dates) {
  for (var i = 1; i < dates.length; i++) {
    if (!dates[i].isAfter(dates[i - 1])) return false;
  }
  return true;
}

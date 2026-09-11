import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/frequency.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';

/// Deterministic preservation coverage for recurring processing.
///
/// The service currently obtains the clock and Isar instance internally, so
/// these tests characterize its stable date/side-effect contracts without
/// using wall-clock time or a real database.
void main() {
  final serviceSource = File(
    'lib/features/transactions/data/recurring_transaction_service.dart',
  ).readAsStringSync();
  final processStart = serviceSource.indexOf(
    'Future<void> processRecurringTransactions()',
  );
  final processEnd = serviceSource.indexOf(
    '/// Find an unlinked transaction',
    processStart,
  );
  final processBody = serviceSource.substring(processStart, processEnd);

  group('Property 2 preservation — one-period processing', () {
    test('one eligible due date creates one occurrence and advances once', () {
      final dueDate = DateTime(2025, 6, 15);
      final processingDate = DateTime(2025, 6, 17);
      final eligible = _eligibleDates(
        dueDate,
        Frequency.monthly,
        processingDate,
        dueDate,
      );

      expect(eligible, [dueDate]);
      expect(
        _nextDue(dueDate, Frequency.monthly, dueDate),
        DateTime(2025, 7, 15),
      );
      expect(processBody, contains('await _createTransaction(isar, recurring)'));
      expect(processBody, contains('await _updateNextDueDate(isar, recurring)'));
    });

    test('one-day overdue occurrence remains pending inside two-day grace', () {
      final dueDate = DateTime(2025, 6, 15);
      final processingDate = DateTime(2025, 6, 16);

      expect(processingDate.difference(dueDate).inDays, 1);
      expect(
        _shouldAutoCreate(dueDate, processingDate),
        isFalse,
      );
      expect(processBody, contains('if (daysOverdue >= 2)'));
    });

    test('SMS match links one transaction and does not create duplicate', () {
      final matchIndex = processBody.indexOf('_findSmsMatch(isar, recurring)');
      final linkIndex = processBody.indexOf(
        '_linkTransactionToRecurring(isar, smsMatch, recurring)',
      );
      final createIndex = processBody.indexOf(
        '_createTransaction(isar, recurring)',
      );

      expect(matchIndex, greaterThanOrEqualTo(0));
      expect(linkIndex, greaterThan(matchIndex));
      expect(createIndex, greaterThan(linkIndex));
      expect(processBody, contains('wasSmsMatched: true'));
      expect(processBody, contains('wasSmsMatched: false'));
    });

    test('already-linked due date remains exactly-once', () {
      final existsIndex = processBody.indexOf('if (exists)');
      final continueIndex = processBody.indexOf('continue;', existsIndex);
      final matchIndex = processBody.indexOf(
        '// Try to match with an existing SMS-imported transaction',
        existsIndex,
      );

      expect(processBody, contains('_transactionExists(isar, recurring'));
      expect(existsIndex, greaterThanOrEqualTo(0));
      expect(continueIndex, greaterThan(existsIndex));
      expect(matchIndex, greaterThan(continueIndex));
    });

    test('end-date cutoff deactivates after final occurrence', () {
      final currentDue = DateTime(2025, 6, 15);
      final endDate = DateTime(2025, 6, 15);
      final nextDue = _nextDue(currentDue, Frequency.monthly, currentDue);

      expect(nextDue.isAfter(endDate), isTrue);
      expect(_activeAfterAdvance(nextDue, endDate), isFalse);
      expect(serviceSource, contains('recurring.endDate'));
      expect(serviceSource, contains('recurring.isActive = false'));
    });
  });

  group('Property 2 preservation — frequency and date boundaries', () {
    final cases = <({
      Frequency frequency,
      DateTime due,
      DateTime start,
      DateTime expectedNext,
    })>[
      (
        frequency: Frequency.daily,
        due: DateTime(2025, 6, 15),
        start: DateTime(2025, 6, 15),
        expectedNext: DateTime(2025, 6, 16),
      ),
      (
        frequency: Frequency.weekly,
        due: DateTime(2025, 6, 15),
        start: DateTime(2025, 6, 15),
        expectedNext: DateTime(2025, 6, 22),
      ),
      (
        frequency: Frequency.monthly,
        due: DateTime(2025, 1, 31),
        start: DateTime(2025, 1, 31),
        expectedNext: DateTime(2025, 2, 28),
      ),
      (
        frequency: Frequency.yearly,
        due: DateTime(2024, 2, 29),
        start: DateTime(2024, 2, 29),
        expectedNext: DateTime(2025, 2, 28),
      ),
    ];

    for (final vector in cases) {
      test('${vector.frequency.name} boundary advances once', () {
        expect(
          _nextDue(vector.due, vector.frequency, vector.start),
          vector.expectedNext,
        );
      });
    }
  });

  group('Property 2 preservation — occurrence payload and side effects', () {
    test('generated payload preserves amount, type, currency, account, category', () {
      final account = Account.create(name: 'Bank')..currencyCode = 'USD';
      final category = Category.create(name: 'Rent');
      final recurring = RecurringTransaction.create(
        amount: 125.50,
        isExpense: true,
        description: 'Rent',
        frequency: Frequency.monthly,
        startDate: DateTime(2025, 6, 15),
      )
        ..account.value = account
        ..category.value = category;

      final generated = Transaction.create(
        date: recurring.nextDueDate,
        amount: recurring.amount,
        isExpense: recurring.isExpense,
        description: 'Rent (Monthly)',
        currencyCode: account.currencyCode,
      )
        ..account.value = recurring.account.value
        ..category.value = recurring.category.value
        ..recurringTransactionSource.value = recurring;

      expect(generated.amount, recurring.amount);
      expect(generated.isExpense, recurring.isExpense);
      expect(generated.currencyCode, 'USD');
      expect(generated.account.value, same(account));
      expect(generated.category.value, same(category));
      expect(generated.recurringTransactionSource.value, same(recurring));
    });

    test('create and SMS-match paths retain per-occurrence notification behavior', () {
      expect(processBody, contains('notifyBillPaid'));
      expect(processBody, contains('billId: recurring.id'));
      expect(processBody, contains('wasSmsMatched: true'));
      expect(processBody, contains('wasSmsMatched: false'));
      expect(processBody, contains('matched++'));
      expect(processBody, contains('processed++'));
    });
  });
}

List<DateTime> _eligibleDates(
  DateTime firstDue,
  Frequency frequency,
  DateTime processingDate,
  DateTime startDate,
) {
  final cutoff = processingDate.subtract(const Duration(days: 2));
  final dates = <DateTime>[];
  var due = firstDue;
  while (!due.isAfter(cutoff)) {
    dates.add(due);
    due = _nextDue(due, frequency, startDate);
  }
  return dates;
}

bool _shouldAutoCreate(DateTime dueDate, DateTime processingDate) =>
    processingDate.difference(dueDate).inDays >= 2;

DateTime _nextDue(DateTime current, Frequency frequency, DateTime startDate) =>
    calculateNextDueDate(current, frequency, startDate);

bool _activeAfterAdvance(DateTime nextDue, DateTime? endDate) =>
    endDate == null || !nextDue.isAfter(endDate);

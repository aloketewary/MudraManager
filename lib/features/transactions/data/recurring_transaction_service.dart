import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/frequency.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/features/gamification/models/gamification_enum.dart';
import 'package:mudra_manager/features/gamification/services/gamification_service.dart';

class RecurringTransactionService {
  final IsarService isarService;
  final GamificationService? gamificationService;
  late final AppLog log;

  RecurringTransactionService(this.isarService, this.gamificationService) {
    log = AppLog(getLogger(), 'RecurringTxnService');
  }

  Future<void> processRecurringTransactions() async {
    final isar = await isarService.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final dueRecurring = await isar.recurringTransactions
        .filter()
        .isActiveEqualTo(true)
        .findAll();

    log.i('Checking ${dueRecurring.length} recurring transactions');

    int processed = 0;
    int skipped = 0;
    for (final recurring in dueRecurring) {
      await recurring.category.load();
      await recurring.account.load();

      final dueDate = DateTime(
        recurring.nextDueDate.year,
        recurring.nextDueDate.month,
        recurring.nextDueDate.day,
      );

      // Process if due date is today or in the past
      if (dueDate.isBefore(today) || dueDate.isAtSameMomentAs(today)) {
        // Check for duplicate
        final exists =
            await _transactionExists(isar, recurring, recurring.nextDueDate);
        if (exists) {
          log.i(
              'Skipping duplicate: ${recurring.description} for ${recurring.nextDueDate}');
          skipped++;
          continue;
        }

        await _createTransaction(isar, recurring);
        await _updateNextDueDate(isar, recurring);
        log.i('Created recurring transaction: ${recurring.description}');
        processed++;
      }
    }

    log.i(
        'Processed $processed recurring transactions, skipped $skipped duplicates');
  }

  Future<bool> _transactionExists(
      Isar isar, RecurringTransaction recurring, DateTime dueDate) async {
    final startOfDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final endOfDay =
        DateTime(dueDate.year, dueDate.month, dueDate.day, 23, 59, 59);

    final existing = await isar.transactions
        .filter()
        .recurringTransactionSource((q) => q.idEqualTo(recurring.id))
        .dateBetween(startOfDay, endOfDay)
        .findFirst();

    return existing != null;
  }

  Future<void> _createTransaction(
      Isar isar, RecurringTransaction recurring) async {
    final frequencyText = _getFrequencyText(recurring.frequency);
    final description = recurring.description?.isNotEmpty == true
        ? '${recurring.description} (🔄 $frequencyText)'
        : '🔄 $frequencyText - ${recurring.category.value?.name ?? ""}';

    final transaction = Transaction.create(
      date: recurring.nextDueDate,
      amount: recurring.amount,
      isExpense: recurring.isExpense,
      description: description,
    )
      ..account.value = recurring.account.value
      ..category.value = recurring.category.value
      ..recurringTransactionSource.value = recurring;

    await isar.writeTxn(() async {
      await isar.transactions.put(transaction);
      await transaction.account.save();
      await transaction.category.save();
      await transaction.recurringTransactionSource.save();
    });
  }

  String _getFrequencyText(Frequency frequency) {
    switch (frequency) {
      case Frequency.daily:
        return 'Daily';
      case Frequency.weekly:
        return 'Weekly';
      case Frequency.monthly:
        return 'Monthly';
      case Frequency.yearly:
        return 'Yearly';
    }
  }

  Future<void> _updateNextDueDate(
      Isar isar, RecurringTransaction recurring) async {
    final nextDate = calculateNextDueDate(
      recurring.nextDueDate,
      recurring.frequency,
      recurring.startDate,
    );

    if (recurring.endDate != null && nextDate.isAfter(recurring.endDate!)) {
      recurring.isActive = false;
    } else {
      recurring.nextDueDate = nextDate;
    }

    await isar.writeTxn(() async {
      await isar.recurringTransactions.put(recurring);
    });
  }

  Future<void> save(RecurringTransaction recurring) async {
    final isar = await isarService.getInstance();
    final isNew = recurring.id == Isar.autoIncrement;
    await isar.writeTxn(() async {
      await isar.recurringTransactions.put(recurring);
      await recurring.account.save();
      await recurring.category.save();
    });
    if (isNew && gamificationService != null) {
      await gamificationService!
          .track(GamificationEvent.recurringTransactionCreated);
    }
  }

  Future<void> delete(int id) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      await isar.recurringTransactions.delete(id);
    });
  }

  Future<List<RecurringTransaction>> getAll() async {
    final isar = await isarService.getInstance();
    final all = await isar.recurringTransactions.where().findAll();
    for (var r in all) {
      await r.category.load();
      await r.account.load();
    }
    return all;
  }

  Stream<List<RecurringTransaction>> watchAll() async* {
    final isar = await isarService.getInstance();
    await for (final list
        in isar.recurringTransactions.where().watch(fireImmediately: true)) {
      for (var r in list) {
        await r.category.load();
        await r.account.load();
      }
      yield list;
    }
  }
}

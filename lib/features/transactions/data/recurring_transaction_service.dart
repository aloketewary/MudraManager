import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/db/models/frequency.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/extensions/field_encryption_ext.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/features/gamification/domain/gamification_enum.dart';
import 'package:mudra_manager/features/gamification/data/gamification_service.dart';
import 'package:mudra_manager/features/notifications/data/smart_notification_service.dart';

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
        .findAll()
        .withDecryption();

    log.i('Checking ${dueRecurring.length} recurring transactions');

    int processed = 0;
    int matched = 0;
    int skipped = 0;
    for (final recurring in dueRecurring) {
      await recurring.category.load();
      await recurring.account.load();

      final dueDate = DateTime(
        recurring.nextDueDate.year,
        recurring.nextDueDate.month,
        recurring.nextDueDate.day,
      );

      if (dueDate.isAfter(today)) continue;

      // Check if already processed for this period
      final exists =
          await _transactionExists(isar, recurring, recurring.nextDueDate);
      if (exists) {
        skipped++;
        continue;
      }

      // Try to match with an existing SMS-imported transaction
      final smsMatch = await _findSmsMatch(isar, recurring);
      if (smsMatch != null) {
        // Link the existing transaction to this recurring bill
        await _linkTransactionToRecurring(isar, smsMatch, recurring);
        await _updateNextDueDate(isar, recurring);
        final billName = recurring.description?.isNotEmpty == true
            ? recurring.description!
            : recurring.category.value?.name ?? 'Bill';
        await SmartNotificationService.instance.notifyBillPaid(
          description: billName,
          amount: recurring.amount,
          billId: recurring.id,
          wasSmsMatched: true,
        );
        log.i('Matched SMS transaction to recurring: ${recurring.description}');
        matched++;
        continue;
      }

      // No SMS match — only auto-create if overdue by 2+ days
      // (gives SMS import time to pick it up)
      final daysOverdue = today.difference(dueDate).inDays;
      if (daysOverdue >= 2) {
        await _createTransaction(isar, recurring);
        await _updateNextDueDate(isar, recurring);
        final billName = recurring.description?.isNotEmpty == true
            ? recurring.description!
            : recurring.category.value?.name ?? 'Bill';
        await SmartNotificationService.instance.notifyBillPaid(
          description: billName,
          amount: recurring.amount,
          billId: recurring.id,
          wasSmsMatched: false,
        );
        log.i('Auto-created overdue recurring: ${recurring.description}');
        processed++;
      }
    }

    log.i(
        'Recurring: $processed created, $matched SMS-matched, $skipped already done',);
  }

  /// Find an unlinked transaction that matches this recurring bill
  /// (exact amount, within the billing period, same account)
  Future<Transaction?> _findSmsMatch(
      Isar isar, RecurringTransaction recurring,) async {
    final dueDate = recurring.nextDueDate;
    // Search from 5 days before due to 2 days after (payments can be early/late)
    final searchStart = DateTime(
      dueDate.year, dueDate.month, dueDate.day,
    ).subtract(const Duration(days: 5));
    final searchEnd = DateTime(
      dueDate.year, dueDate.month, dueDate.day, 23, 59, 59,
    ).add(const Duration(days: 2));

    final candidates = await isar.transactions
        .filter()
        .isExpenseEqualTo(recurring.isExpense)
        .isTransferEqualTo(false)
        .dateBetween(searchStart, searchEnd)
        .amountBetween(recurring.amount - 0.01, recurring.amount + 0.01)
        .findAll()
        .withDecryption();

    // Find one that isn't already linked to a recurring source
    for (final txn in candidates) {
      await txn.recurringTransactionSource.load();
      await txn.account.load();
      if (txn.recurringTransactionSource.value == null &&
          txn.account.value?.id == recurring.account.value?.id) {
        return txn;
      }
    }
    return null;
  }

  Future<void> _linkTransactionToRecurring(
      Isar isar, Transaction txn, RecurringTransaction recurring,) async {
    txn.recurringTransactionSource.value = recurring;
    txn.encryptFields();
    await isar.writeTxn(() async {
      await isar.transactions.put(txn);
      await txn.recurringTransactionSource.save();
    });
  }

  Future<bool> _transactionExists(
      Isar isar, RecurringTransaction recurring, DateTime dueDate,) async {
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
      Isar isar, RecurringTransaction recurring,) async {
    final frequencyText = _getFrequencyText(recurring.frequency);
    final description = recurring.description?.isNotEmpty == true
        ? '${recurring.description} (🔄 $frequencyText)'
        : '🔄 $frequencyText - ${recurring.category.value?.name ?? ""}';

    // Inherit currency from linked account
    final accountCurrency = recurring.account.value?.currencyCode;
    double? convertedAmount;
    double? rateUsed;

    if (accountCurrency != null) {
      final r = CurrencyService.getCachedRate(accountCurrency);
      if (r != null) {
        convertedAmount = recurring.amount * r;
        rateUsed = r;
      }
    }

    final transaction = Transaction.create(
      date: recurring.nextDueDate,
      amount: recurring.amount,
      isExpense: recurring.isExpense,
      description: description,
      currencyCode: accountCurrency,
      convertedAmount: convertedAmount,
      rateUsed: rateUsed,
    )
      ..account.value = recurring.account.value
      ..category.value = recurring.category.value
      ..recurringTransactionSource.value = recurring;

    transaction.encryptFields();
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
      Isar isar, RecurringTransaction recurring,) async {
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

    recurring.encryptFields();
    await isar.writeTxn(() async {
      await isar.recurringTransactions.put(recurring);
    });
  }

  Future<void> save(RecurringTransaction recurring) async {
    final isar = await isarService.getInstance();
    final isNew = recurring.id == Isar.autoIncrement;
    recurring.encryptFields();
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
    final all = await isar.recurringTransactions.where().findAll().withDecryption();
    for (var r in all) {
      await r.category.load();
      await r.account.load();
    }
    return all;
  }

  Stream<List<RecurringTransaction>> watchAll() async* {
    final isar = await isarService.getInstance();
    await for (final list
        in isar.recurringTransactions.where().watch(fireImmediately: true).withDecryption()) {
      for (var r in list) {
        await r.category.load();
        await r.account.load();
      }
      yield list;
    }
  }
}

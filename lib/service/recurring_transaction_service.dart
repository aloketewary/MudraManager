import 'package:isar/isar.dart';
import 'package:mudra_manager/db/isar_service.dart';
import 'package:mudra_manager/db/models/recurring_transaction.dart';
import 'package:mudra_manager/db/models/transaction.dart';

class RecurringTransactionService {
  final IsarService isarService;

  RecurringTransactionService(this.isarService);

  Future<void> processRecurringTransactions() async {
    final isar = await isarService.getInstance();
    final now = DateTime.now();

    final dueRecurring = await isar.recurringTransactions
        .filter()
        .isActiveEqualTo(true)
        .nextDueDateLessThan(now.add(const Duration(days: 1)))
        .findAll();

    for (final recurring in dueRecurring) {
      await recurring.category.load();
      await recurring.account.load();

      if (recurring.nextDueDate.isBefore(now) || 
          recurring.nextDueDate.isAtSameMomentAs(now)) {
        await _createTransaction(isar, recurring);
        await _updateNextDueDate(isar, recurring);
      }
    }
  }

  Future<void> _createTransaction(dynamic isar, RecurringTransaction recurring) async {
    final transaction = Transaction.create(
      date: recurring.nextDueDate,
      amount: recurring.amount,
      isExpense: recurring.isExpense,
      description: recurring.description ?? 'Recurring: ${recurring.category.value?.name ?? ""}',
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

  Future<void> _updateNextDueDate(dynamic isar, RecurringTransaction recurring) async {
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
    await isar.writeTxn(() async {
      await isar.recurringTransactions.put(recurring);
      await recurring.account.save();
      await recurring.category.save();
    });
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
    await for (final list in isar.recurringTransactions.where().watch(fireImmediately: true)) {
      for (var r in list) {
        await r.category.load();
        await r.account.load();
      }
      yield list;
    }
  }
}

import 'package:mudra_manager/core/utils/date_arithmetic.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/pending_transaction.dart';
import 'package:mudra_manager/core/db/models/recurring_bill.dart';

class BillService {
  static Future<void> createPendingTransactionsForDueBills() async {
    final isar = Isar.getInstance();
    if (isar == null) return;

    final today = DateTime.now();
    final bills = await isar.recurringBills
        .filter()
        .isActiveEqualTo(true)
        .findAll();

    for (final bill in bills) {
      if (bill.nextDueDate != null &&
          bill.nextDueDate!.isBefore(today.add(const Duration(days: 1)))) {
        final existing = await isar.pendingTransactions
            .filter()
            .bodyContains(bill.name)
            .findFirst();

        if (existing == null) {
          await bill.category.load();
          await bill.account.load();
          final pending = PendingTransaction()
            ..amount = bill.amount
            ..body = 'Bill: ${bill.name}'
            ..sender = 'Bill Reminder'
            ..date = bill.nextDueDate!
            ..isIncome = false
            ..category = bill.category.value?.name
            ..account = bill.account.value?.name
            ..smsHash =
                'bill_${bill.id}_${bill.nextDueDate!.millisecondsSinceEpoch}';

          await isar.writeTxn(() async {
            await isar.pendingTransactions.put(pending);
          });
        }

        await _updateNextDueDate(isar, bill);
      }
    }
  }

  static Future<void> _updateNextDueDate(Isar isar, RecurringBill bill) async {
    final current = bill.nextDueDate!;
    final day = current.day;

    DateTime nextDate;
    switch (bill.frequency) {
      case BillFrequency.monthly:
        nextDate = DateArithmetic.addMonths(current, 1, preferDay: day);
        break;
      case BillFrequency.quarterly:
        nextDate = DateArithmetic.addMonths(current, 3, preferDay: day);
        break;
      case BillFrequency.yearly:
        nextDate = DateArithmetic.addYears(current, 1, preferDay: day);
        break;
    }

    await isar.writeTxn(() async {
      bill.nextDueDate = nextDate;
      await isar.recurringBills.put(bill);
    });
  }

  static Future<void> markBillAsPaid(int billId) async {
    final isar = Isar.getInstance();
    if (isar == null) return;

    final bill = await isar.recurringBills.get(billId);
    if (bill != null) {
      await isar.writeTxn(() async {
        bill.lastPaidDate = DateTime.now();
        await isar.recurringBills.put(bill);
      });

      await _updateNextDueDate(isar, bill);
    }
  }
}

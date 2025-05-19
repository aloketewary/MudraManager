import 'package:mudra_manager/backup/backable_model.dart' show BackupAdapter, Backupable;
import 'package:mudra_manager/db/models/account.dart' show Account;
import 'package:mudra_manager/db/models/category.dart' show Category;
import 'package:mudra_manager/db/models/frequency.dart' show Frequency;
import 'package:mudra_manager/db/models/recurring_transaction.dart' show RecurringTransaction, Frequency;

class RecurringTransactionBackup implements BackupAdapter<RecurringTransaction> {
  final int id;
  final double amount;
  final bool isExpense;
  final String? description;
  final int frequency; // Store enum index
  final String startDate;
  final String? endDate;
  final String nextDueDate;
  final int? categoryId; // Store linked Category ID
  final int? accountId;  // Store linked Account ID
  final bool isActive;

  RecurringTransactionBackup.fromRecurringTransaction(RecurringTransaction record)
      : id = record.id,
        amount = record.amount,
        isExpense = record.isExpense,
        description = record.description,
        frequency = record.frequency.index,
        startDate = record.startDate.toIso8601String(),
        endDate = record.endDate?.toIso8601String(),
        nextDueDate = record.nextDueDate.toIso8601String(),
        categoryId = record.category.value?.id,
        accountId = record.account.value?.id,
        isActive = record.isActive;

  RecurringTransactionBackup():
      id = 0,
      amount = 0.0,
      isExpense = false,
      description = null,
      frequency = 0,
      startDate = DateTime.now().toIso8601String(),
      endDate = null,
      nextDueDate = DateTime.now().toIso8601String(),
      categoryId = null,
      accountId = null,
      isActive = true;

  @override
  Map<String, dynamic> toBackupJson() => {
    'id': id,
    'amount': amount,
    'isExpense': isExpense,
    'description': description,
    'frequency': frequency,
    'startDate': startDate,
    'endDate': endDate,
    'nextDueDate': nextDueDate,
    'categoryId': categoryId,
    'accountId': accountId,
    'isActive': isActive,
  };

  @override
  RecurringTransaction fromBackupJson(Map<String, dynamic> json, Map<String, dynamic> linkedRefs) {
    final record = RecurringTransaction()
      ..id = json['id']
      ..amount = json['amount']
      ..isExpense = json['isExpense']
      ..description = json['description'] as String?
      ..frequency = Frequency.values[json['frequency'] as int]
      ..startDate = DateTime.parse(json['startDate'])
      ..endDate = json['endDate'] != null ? DateTime.parse(json['endDate']) : null
      ..nextDueDate = DateTime.parse(json['nextDueDate'])
      ..isActive = json['isActive'] as bool;

    // Re-link Category
    final categoryMap = linkedRefs['Category'] as Map<int, dynamic>?;
    final categoryId = json['categoryId'];
    if (categoryMap != null && categoryId != null) {
      record.category.value = categoryMap[categoryId];
    }

    // Re-link Account
    final accountMap = linkedRefs['Account'] as Map<int, dynamic>?;
    final accountId = json['accountId'];
    if (accountMap != null && accountId != null) {
      record.account.value = accountMap[accountId];
    }

    return record;
  }
}
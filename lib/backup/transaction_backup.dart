import 'package:mudra_manager/backup/backable_model.dart' show BackupAdapter, Backupable;
import 'package:mudra_manager/db/models/account.dart' show Account;
import 'package:mudra_manager/db/models/category.dart' show Category;
import 'package:mudra_manager/db/models/recurring_transaction.dart' show RecurringTransaction;
import 'package:mudra_manager/db/models/tag.dart' show Tag;
import 'package:mudra_manager/db/models/transaction.dart' show Transaction;

class TransactionBackup implements BackupAdapter<Transaction> {
  final int id;
  final double amount;
  final String? description;
  final int? accountId;
  final DateTime date;
  final bool isExpense;
  final bool isTransfer;
  final int? categoryId;
  final int? recurringTransactionSource;
  final int? related;
  final List<int> tagIds;

  TransactionBackup.fromTransaction(Transaction tx)
    : amount = tx.amount,
      description = tx.description,
      date = tx.date,
      isExpense = tx.isExpense,
      isTransfer = tx.isTransfer,
      categoryId = tx.category.value?.id,
      recurringTransactionSource = tx.recurringTransactionSource.value?.id,
      related = tx.related.value?.id,
      tagIds = tx.tags.map((link) => link.id).toList(),
      id = tx.id,
      accountId = tx.account.value?.id;

  TransactionBackup()
    : amount = 0,
      description = null,
      date = DateTime.now(),
      isExpense = false,
      isTransfer = false,
      categoryId = null,
      recurringTransactionSource = null,
      related = null,
      tagIds = [],
      id = 0,
      accountId = null;

  @override
  Map<String, dynamic> toBackupJson() => {
    'amount': amount,
    'description': description,
    'accountId': accountId,
    'date': date.toIso8601String(),
    'isExpense': isExpense,
    'isTransfer': isTransfer,
    'categoryId': categoryId,
    'recurringTransactionSource': recurringTransactionSource,
    'related': related,
    'tagIds': tagIds,
    'id': id,
  };

  @override
  Transaction fromBackupJson(Map<String, dynamic> json, Map<String, dynamic> linkedRefs) {
    final tx =
        Transaction()
          ..amount = json['amount']
          ..date = DateTime.parse(json['date'])
          ..isExpense = json['isExpense']
          ..isTransfer = json['isTransfer']
          ..id = json['id']
          ..description = json['description'];

    // Re-link Account
    final accountMap = linkedRefs['Account'] as Map<int, dynamic>?;
    final accountId = json['accountId'];
    if (accountMap != null && accountId != null) {
      tx.account.value = accountMap[accountId];
    }

    // Re-link Category
    final categoryMap = linkedRefs['Category'] as Map<int, dynamic>?;
    final categoryId = json['categoryId'];
    if (categoryMap != null && categoryId != null) {
      tx.category.value = categoryMap[categoryId];
    }

    // Re-link RecurringTransactionSource
    final recurringTransactionMap = linkedRefs['RecurringTransaction'] as Map<int, dynamic>?;
    final recurringTransactionSourceId = json['recurringTransactionSource'];
    if (recurringTransactionMap != null && recurringTransactionSourceId != null) {
      tx.recurringTransactionSource.value = recurringTransactionMap[recurringTransactionSourceId];
    }

    // Re-link Related Transaction
    final transactionMap = linkedRefs['Transaction'] as Map<int, dynamic>?;
    final relatedId = json['related'];
    if (transactionMap != null && relatedId != null && relatedId != tx.id) {
      // Avoid self-reference issues during restore
      tx.related.value = transactionMap[relatedId];
    }

    // Re-link Tags (IsarLinks)
    final tagMap = linkedRefs['Tag'] as Map<int, dynamic>?;
    final tagIds = json['tagIds'] as List<dynamic>? ?? [];
    if (tagMap != null) {
      for (final tagId in tagIds) {
        final tag = tagMap[tagId];
        if (tag != null) {
          tx.tags.add(tag);
        }
      }
    }

    return tx;
  }
}

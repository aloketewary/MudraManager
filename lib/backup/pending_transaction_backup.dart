import 'package:mudra_manager/backup/backable_model.dart' show BackupAdapter, Backupable;
import 'package:mudra_manager/db/models/pending_transaction.dart' show PendingTransaction;

class PendingTransactionBackup implements BackupAdapter<PendingTransaction> {
  final int id;
  final String sender;
  final String body;
  final String date;
  final double? amount;
  final bool? isIncome;
  final String? account;
  final String? type;
  final String? fromBank;
  final String? toAccount;
  final String? transactionRef;
  final String? category;
  final String smsHash;

  PendingTransactionBackup.fromPendingTransaction(PendingTransaction record)
      : id = record.id,
        sender = record.sender,
        body = record.body,
        date = record.date.toIso8601String(),
        amount = record.amount,
        isIncome = record.isIncome,
        account = record.account,
        type = record.type,
        fromBank = record.fromBank,
        toAccount = record.toAccount,
        transactionRef = record.transactionRef,
        category = record.category,
        smsHash = record.smsHash;

  PendingTransactionBackup():
      id = 0,
      sender = '',
      body = '',
      date = '',
      amount = 0.0,
      isIncome = false,
      account = '',
      type = '',
      fromBank = '',
      toAccount = '',
      transactionRef = '',
      category = '',
      smsHash = '';

  @override
  Map<String, dynamic> toBackupJson() => {
    'id': id,
    'sender': sender,
    'body': body,
    'date': date,
    'amount': amount,
    'isIncome': isIncome,
    'account': account,
    'type': type,
    'fromBank': fromBank,
    'toAccount': toAccount,
    'transactionRef': transactionRef,
    'category': category,
    'smsHash': smsHash,
  };

  @override
  PendingTransaction fromBackupJson(Map<String, dynamic> json, Map<String, dynamic> linkedRefs) {
    final record = PendingTransaction()
      ..id = json['id']
      ..sender = json['sender']
      ..body = json['body']
      ..date = DateTime.parse(json['date'])
      ..amount = json['amount'] as double?
      ..isIncome = json['isIncome'] as bool?
      ..account = json['account'] as String?
      ..type = json['type'] as String?
      ..fromBank = json['fromBank'] as String?
      ..toAccount = json['toAccount'] as String?
      ..transactionRef = json['transactionRef'] as String?
      ..category = json['category'] as String?
      ..smsHash = json['smsHash'];

    return record;
  }
}
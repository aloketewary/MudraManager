import 'package:isar_community/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mudra_manager/features/transactions/data/models/pending_transaction_data.dart';

part 'pending_transaction.g.dart';

@collection
@JsonSerializable()
class PendingTransaction implements PendingTransactionData {
  Id id = Isar.autoIncrement;

  late String sender;
  @override
  late String body;
  late DateTime date;
  @override
  double? amount;
  @override
  bool? isIncome;
  @override
  String? account;
  String? type;
  @override
  String? fromBank;
  String? toAccount;
  String? transactionRef;
  String? category;
  @Index(unique: true, replace: true)
  late String smsHash;

  PendingTransaction();

  factory PendingTransaction.fromJson(Map<String, dynamic> json) =>
      _$PendingTransactionFromJson(json);
  Map<String, dynamic> toJson() => _$PendingTransactionToJson(this);
}

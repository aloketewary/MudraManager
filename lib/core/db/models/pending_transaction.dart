import 'package:isar_community/isar.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pending_transaction.g.dart';

@collection
@JsonSerializable()
class PendingTransaction {
  Id id = Isar.autoIncrement;

  late String sender;
  late String body;
  late DateTime date;
  double? amount;
  bool? isIncome;
  String? account;
  String? type;
  String? fromBank;
  String? toAccount;
  String? transactionRef;
  String? category;
  @Index(unique: true, replace: true)
  late String smsHash;

  PendingTransaction();

  factory PendingTransaction.fromJson(Map<String, dynamic> json) => _$PendingTransactionFromJson(json);
  Map<String, dynamic> toJson() => _$PendingTransactionToJson(this);
}

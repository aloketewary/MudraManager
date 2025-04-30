import 'package:isar/isar.dart';

part 'pending_transaction.g.dart';

@collection
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
  @Index(unique: true)
  late String smsHash;
}

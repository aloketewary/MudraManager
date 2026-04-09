import 'package:isar_community/isar.dart';

part 'archived_transaction.g.dart';

/// Stores transactions archived during a base currency change.
/// Preserves the original data for historical reference.
@collection
class ArchivedTransaction {
  Id id = Isar.autoIncrement;

  late int originalTransactionId;
  late DateTime date;
  late double amount;
  late bool isExpense;
  String? description;
  String? currencyCode;
  double? convertedAmount;
  double? rateUsed;
  bool isTransfer = false;

  String? accountName;
  String? categoryName;

  /// The base currency that was active when this was archived.
  late String archivedFromBase;

  /// The new base currency that triggered the archive.
  late String archivedToBase;

  @Index()
  late DateTime archivedAt;

  ArchivedTransaction();
}

import 'package:mudra_manager/core/db/models/transaction.dart';


/// A union type for either a header or a transaction item
abstract class TxListEntry {}

class TxHeader implements TxListEntry {
  final DateTime group;

  TxHeader(this.group);
}

class TxItem implements TxListEntry {
  final Transaction txn;

  TxItem(this.txn);
}

List<TxListEntry> buildSectionedList(List<Transaction> allTxns) {
  final List<TxListEntry> sectioned = [];

  // Sort by date descending
  allTxns.sort((a, b) => b.date.compareTo(a.date));

  DateTime? currentDate;

  for (final txn in allTxns) {
    final txnDate = DateTime(txn.date.year, txn.date.month, txn.date.day);

    if (txnDate != currentDate) {
      currentDate = txnDate;
      sectioned.add(TxHeader(txnDate));
    }

    sectioned.add(TxItem(txn));
  }

  return sectioned;
}
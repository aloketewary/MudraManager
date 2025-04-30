import 'package:mudra_manager/db/models/transaction.dart' show Transaction;
import 'package:mudra_manager/util/date_group.dart'
    show DateGroup, groupForDate;

/// A union type for either a header or a transaction item
abstract class TxListEntry {}

class TxHeader implements TxListEntry {
  final DateGroup group;

  TxHeader(this.group);
}

class TxItem implements TxListEntry {
  final Transaction txn;

  TxItem(this.txn);
}

List<TxListEntry> buildSectionedList(List<Transaction> allTxns) {
  final List<TxListEntry> sectioned = [];
  DateGroup? currentGroup;

  for (final txn in allTxns) {
    final grp = groupForDate(txn.date);
    if (grp != currentGroup) {
      currentGroup = grp;
      sectioned.add(TxHeader(grp));
    }
    sectioned.add(TxItem(txn));
  }
  return sectioned;
}

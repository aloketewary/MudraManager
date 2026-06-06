import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/transaction_group.dart';

/// Transforms a flat list of [Transaction] (assumed sorted by date descending)
/// into a list of [TxListEntry] with date group headers.
///
/// This is a pure function — no side effects, no dependencies.
/// The input must already be sorted; this function does not re-sort.
List<TxListEntry> toTransactionListEntries(List<Transaction> transactions) {
  if (transactions.isEmpty) return [];

  final List<TxListEntry> entries = [];
  DateTime? currentDate;

  for (final txn in transactions) {
    final txnDate = DateTime(txn.date.year, txn.date.month, txn.date.day);

    if (txnDate != currentDate) {
      currentDate = txnDate;
      entries.add(TxHeader(txnDate));
    }

    entries.add(TxItem(txn));
  }

  return entries;
}

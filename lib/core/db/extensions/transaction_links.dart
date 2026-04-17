import 'package:mudra_manager/core/db/models/transaction.dart';

/// Extension to auto-load Isar links on transaction queries.
///
/// Isar links (category, account) return null if not loaded.
/// This caused bugs where transaction lists showed "Uncategorized"
/// and budget alerts never fired.
///
/// Usage:
/// ```dart
/// final txns = await isar.transactions.where().findAll().withLinks();
/// ```
extension TransactionListLinks on Future<List<Transaction>> {
  Future<List<Transaction>> withLinks() async {
    final txns = await this;
    for (final t in txns) {
      t.category.loadSync();
      t.account.loadSync();
    }
    return txns;
  }
}

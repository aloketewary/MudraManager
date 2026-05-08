/// Shared interface for pending transaction data used by TransactionMatchingService.
/// Implemented by both PendingTransaction (Isar model) and _PendingTransactionAdapter.
abstract class PendingTransactionData {
  String? get account;
  double? get amount;
  bool? get isIncome;
  String get body;
  String? get fromBank;
}

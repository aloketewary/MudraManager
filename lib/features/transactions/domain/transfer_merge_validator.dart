import 'package:mudra_manager/core/db/models/transaction.dart';

/// Validation result for merging two transactions as a transfer.
class MergeValidation {
  final bool valid;
  final String? error;
  final Transaction? expense;
  final Transaction? income;

  const MergeValidation._({
    required this.valid,
    this.error,
    this.expense,
    this.income,
  });

  factory MergeValidation.success({
    required Transaction expense,
    required Transaction income,
  }) =>
      MergeValidation._(valid: true, expense: expense, income: income);

  factory MergeValidation.failure(String error) =>
      MergeValidation._(valid: false, error: error);
}

/// Validates whether two transactions can be merged into a transfer.
///
/// Rules:
/// - One must be expense, one must be income
/// - Neither can already be a transfer
/// - Amounts must match within 1% tolerance
/// - Must be within 24 hours of each other
/// - Must belong to different accounts
///
/// Pure domain logic — no UI, no DB, no Riverpod.
MergeValidation validateTransferMerge(
  Transaction a,
  Transaction b,
) {
  // Neither is already a transfer
  if (a.isTransfer || b.isTransfer) {
    return MergeValidation.failure('already a transfer');
  }

  // One expense, one income
  final Transaction? expense;
  final Transaction? income;

  if (a.isExpense && !b.isExpense) {
    expense = a;
    income = b;
  } else if (b.isExpense && !a.isExpense) {
    expense = b;
    income = a;
  } else {
    return MergeValidation.failure('need one expense and one income');
  }

  // Same amount (±1% tolerance)
  if ((expense.amount - income.amount).abs() > expense.amount * 0.01) {
    return MergeValidation.failure('amounts must match (within 1%)');
  }

  // Within 24 hours
  if (expense.date.difference(income.date).inHours.abs() > 24) {
    return MergeValidation.failure('transactions must be within 24 hours');
  }

  // Different accounts (only check if both are loaded)
  final expenseAccountId = expense.account.value?.id;
  final incomeAccountId = income.account.value?.id;
  if (expenseAccountId != null &&
      incomeAccountId != null &&
      expenseAccountId == incomeAccountId) {
    return MergeValidation.failure('cannot transfer between the same account');
  }

  return MergeValidation.success(expense: expense, income: income);
}

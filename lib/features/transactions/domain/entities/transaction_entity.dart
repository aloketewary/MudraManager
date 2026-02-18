class TransactionEntity {
  final int? id;
  final DateTime date;
  final double amount;
  final bool isExpense;
  final String? description;
  final String? notes;

  const TransactionEntity({
    this.id,
    required this.date,
    required this.amount,
    required this.isExpense,
    this.description,
    this.notes,
  });

  bool get isIncome => !isExpense;
}

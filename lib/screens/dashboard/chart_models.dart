class GroupedTransaction {
  final String label; // e.g., "Apr 16", "Week 1", "2024"
  final double income;
  final double expense;

  GroupedTransaction({
    required this.label,
    required this.income,
    required this.expense,
  });
}

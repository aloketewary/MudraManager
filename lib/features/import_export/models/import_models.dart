/// A single parsed row from the Excel file.
class ImportRow {
  final int rowIndex;
  final DateTime? date;
  final double? amount;
  final String? description;
  final String? category;
  final String? account;
  final String? currency;
  final bool isExpense;
  final String? error;

  const ImportRow({
    required this.rowIndex,
    this.date,
    this.amount,
    this.description,
    this.category,
    this.account,
    this.currency,
    this.isExpense = true,
    this.error,
  });

  bool get isValid => date != null && amount != null && amount! > 0 && error == null;
}

/// Result of an import operation.
class ImportResult {
  final int imported;
  final int skipped;
  final int duplicates;
  final int categoriesCreated;
  final List<String> errors;

  const ImportResult({
    this.imported = 0,
    this.skipped = 0,
    this.duplicates = 0,
    this.categoriesCreated = 0,
    this.errors = const [],
  });

  int get total => imported + skipped + duplicates;
}

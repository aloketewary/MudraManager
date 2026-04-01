/// Maps Excel columns to transaction fields.
class ColumnMapping {
  final int? dateColumn;
  final int? amountColumn;
  final int? descriptionColumn;
  final int? categoryColumn;
  final int? accountColumn;
  final int? typeColumn;
  final int? currencyColumn;
  final String dateFormat;

  const ColumnMapping({
    this.dateColumn,
    this.amountColumn,
    this.descriptionColumn,
    this.categoryColumn,
    this.accountColumn,
    this.typeColumn,
    this.currencyColumn,
    this.dateFormat = 'dd/MM/yyyy',
  });

  bool get isValid => dateColumn != null && amountColumn != null;

  /// Sentinel value to clear a column mapping to null in copyWith.
  static const int clearColumn = -1;

  ColumnMapping copyWith({
    int? dateColumn,
    int? amountColumn,
    int? descriptionColumn,
    int? categoryColumn,
    int? accountColumn,
    int? typeColumn,
    int? currencyColumn,
    String? dateFormat,
  }) {
    return ColumnMapping(
      dateColumn: dateColumn == clearColumn ? null : (dateColumn ?? this.dateColumn),
      amountColumn: amountColumn == clearColumn ? null : (amountColumn ?? this.amountColumn),
      descriptionColumn: descriptionColumn == clearColumn ? null : (descriptionColumn ?? this.descriptionColumn),
      categoryColumn: categoryColumn == clearColumn ? null : (categoryColumn ?? this.categoryColumn),
      accountColumn: accountColumn == clearColumn ? null : (accountColumn ?? this.accountColumn),
      typeColumn: typeColumn == clearColumn ? null : (typeColumn ?? this.typeColumn),
      currencyColumn: currencyColumn == clearColumn ? null : (currencyColumn ?? this.currencyColumn),
      dateFormat: dateFormat ?? this.dateFormat,
    );
  }
}

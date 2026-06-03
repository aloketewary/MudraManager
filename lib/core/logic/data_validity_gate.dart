import 'package:mudra_manager/core/domain/financial_states.dart';

/// Determines whether dashboard has sufficient data to render truthfully.
/// Pure computation. No Riverpod. No Isar.
class DataValidity {
  final bool accountLinked;
  final bool transactionStreamActive;
  final bool budgetStateKnown;
  final bool recurringScanDone;

  const DataValidity({
    required this.accountLinked,
    required this.transactionStreamActive,
    required this.budgetStateKnown,
    required this.recurringScanDone,
  });

  int get validCount => [
        accountLinked,
        transactionStreamActive,
        budgetStateKnown,
        recurringScanDone,
      ].where((v) => v).length;

  DataValidityLevel get level {
    final count = validCount;
    if (count >= 4) return DataValidityLevel.valid;
    if (count >= 2) return DataValidityLevel.partial;
    return DataValidityLevel.insufficient;
  }
}

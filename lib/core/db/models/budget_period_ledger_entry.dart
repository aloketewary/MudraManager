import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/budget_type.dart';
import 'package:mudra_manager/core/utils/date_arithmetic.dart';

part 'budget_period_ledger_entry.g.dart';

enum BudgetPeriodLedgerStatus { met, exceeded, unknown }

enum BudgetPeriodLedgerProvenance {
  finalizedExact,
  backfilledExact,
  backfilledBestAvailable,
  legacyUnknown,
}

/// Persisted immutable financial facts for one completed budget occurrence.
///
/// [occurrenceKey] is the durable identity. [id] is only Isar storage identity.
/// Historical values remain available after the mutable Budget amount changes.
@collection
class BudgetPeriodLedgerEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String occurrenceKey;

  @Index()
  late int budgetId;

  late List<int> categoryIds;
  late List<int> tagIds;

  late String budgetName;

  @enumerated
  late BudgetType budgetType;

  @enumerated
  late BudgetRecurrence recurrence;

  late bool wasArchived;
  late DateTime periodStart;

  @Index()
  late DateTime periodEnd;

  late double limitAtPeriod;
  late double finalSpent;

  @enumerated
  late BudgetPeriodLedgerStatus status;

  @enumerated
  late BudgetPeriodLedgerProvenance provenance;

  late bool limitIsKnown;
  late bool isFinalized;
  DateTime? finalizedAt;
  late int occurrenceIndex;
  late DateTime recordedAt;

  BudgetPeriodLedgerEntry();

  static String buildOccurrenceKey(
    int budgetId,
    DateTime periodStart,
    DateTime periodEnd,
  ) =>
      _occurrenceKey(budgetId, periodStart, periodEnd);

  static String _occurrenceKey(
    int budgetId,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    final start = DateArithmetic.startOfDay(periodStart);
    final end = DateArithmetic.endOfDay(periodEnd);
    return '$budgetId:${start.toIso8601String()}:${end.toIso8601String()}';
  }
}

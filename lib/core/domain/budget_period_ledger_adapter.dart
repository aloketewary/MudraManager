import 'package:mudra_manager/core/db/models/budget_period_ledger_entry.dart';
import 'package:mudra_manager/core/domain/budget_period_snapshot.dart';
import 'package:mudra_manager/core/utils/date_arithmetic.dart';

extension BudgetPeriodSnapshotLedgerAdapter on BudgetPeriodSnapshot {
  BudgetPeriodLedgerEntry toLedgerEntry({
    BudgetPeriodLedgerProvenance provenance =
        BudgetPeriodLedgerProvenance.finalizedExact,
    bool limitIsKnown = true,
    bool isFinalized = true,
    int occurrenceIndex = 0,
    DateTime? recordedAt,
    DateTime? finalizedAt,
  }) {
    final now = recordedAt ?? DateTime.now();
    final entry = BudgetPeriodLedgerEntry()
      ..occurrenceKey = BudgetPeriodLedgerEntry.buildOccurrenceKey(
        budgetId,
        periodStart,
        periodEnd,
      )
      ..budgetId = budgetId
      ..categoryIds =
          (budget.categories.map((category) => category.id).toList()..sort())
      ..tagIds = (budget.budgetTags.map((tag) => tag.id).toList()..sort())
      ..budgetName = budgetName
      ..budgetType = budgetType
      ..recurrence = recurrence
      ..wasArchived = isArchived
      ..periodStart = DateArithmetic.startOfDay(periodStart)
      ..periodEnd = DateArithmetic.endOfDay(periodEnd)
      ..limitAtPeriod = limit
      ..finalSpent = spent
      ..status = !limitIsKnown
          ? BudgetPeriodLedgerStatus.unknown
          : spent <= limit
              ? BudgetPeriodLedgerStatus.met
              : BudgetPeriodLedgerStatus.exceeded
      ..provenance = provenance
      ..limitIsKnown = limitIsKnown
      ..isFinalized = isFinalized
      ..occurrenceIndex = occurrenceIndex
      ..recordedAt = now;
    entry.finalizedAt = finalizedAt ?? (isFinalized ? now : null);
    return entry;
  }
}

import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/budget_period_ledger_entry.dart';
import 'package:mudra_manager/core/utils/budget_spent_calculator.dart';
import 'package:mudra_manager/core/utils/date_arithmetic.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Backfills completed budget occurrences into the immutable period ledger.
///
/// Isar adds [BudgetPeriodLedgerEntrySchema] during normal schema opening. This
/// migration only creates missing ledger rows after that schema is available;
/// it never updates budgets or source transactions. Existing records do not
/// carry amount-change history, so their current amount is stored as a
/// best-available value with [limitIsKnown] false and an explicit
/// [BudgetPeriodLedgerProvenance.legacyUnknown] marker. This prevents history
/// from silently claiming an exact historical limit after a legacy edit.
class BudgetPeriodLedgerMigration {
  static const migrationKey = 'migration_budget_period_ledger_v1';

  /// Runs once during app startup. A failed run leaves the guard unset so a
  /// later startup can retry. Re-running [backfill] itself is always safe.
  static Future<int> run(
    Isar isar, {
    DateTime? evaluationDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(migrationKey) == true) return 0;

    final created = await backfill(isar, evaluationDate: evaluationDate);
    await prefs.setBool(migrationKey, true);
    return created;
  }

  /// Reconstructs completed occurrences that are absent from the ledger.
  /// Returns number of rows created. Safe to call repeatedly.
  static Future<int> backfill(
    Isar isar, {
    DateTime? evaluationDate,
  }) async {
    final evaluationDay = DateArithmetic.startOfDay(
      evaluationDate ?? DateTime.now(),
    );
    final budgets = await isar.budgets.where().findAll();
    final existing = await isar.budgetPeriodLedgerEntrys.where().findAll();
    final knownKeys = existing.map((entry) => entry.occurrenceKey).toSet();
    final pending = <BudgetPeriodLedgerEntry>[];

    for (final budget in budgets) {
      await budget.categories.load();
      await budget.budgetTags.load();

      var occurrence = 0;
      while (true) {
        final (start, end) = _periodAt(budget, occurrence);
        final periodStart = DateArithmetic.startOfDay(start);
        final periodEnd = DateArithmetic.endOfDay(end);
        final endDay = DateArithmetic.startOfDay(periodEnd);

        // Future and current occurrences are not completed history.
        if (!endDay.isBefore(evaluationDay)) break;

        final key = BudgetPeriodLedgerEntry.buildOccurrenceKey(
          budget.id,
          periodStart,
          periodEnd,
        );
        if (!knownKeys.contains(key)) {
          final spent = await BudgetSpentCalculator.calculate(
            isar,
            budget,
            periodStart,
            periodEnd,
          );
          pending.add(
            _legacyEntry(
              budget: budget,
              occurrenceKey: key,
              periodStart: periodStart,
              periodEnd: periodEnd,
              spent: spent,
              occurrenceIndex: occurrence,
              recordedAt: evaluationDay,
            ),
          );
          knownKeys.add(key);
        }

        // Non-recurring budgets have one occurrence only. Recurring periods
        // advance monotonically; this guard protects malformed legacy data.
        if (budget.recurrence == BudgetRecurrence.none) break;
        occurrence++;
        if (occurrence > 100000) {
          throw StateError(
            'Budget period backfill exceeded 100000 occurrences for '
            'budget ${budget.id}',
          );
        }
      }
    }

    if (pending.isEmpty) return 0;
    await isar.writeTxn(() async {
      await isar.budgetPeriodLedgerEntrys.putAll(pending);
    });
    return pending.length;
  }

  static BudgetPeriodLedgerEntry _legacyEntry({
    required Budget budget,
    required String occurrenceKey,
    required DateTime periodStart,
    required DateTime periodEnd,
    required double spent,
    required int occurrenceIndex,
    required DateTime recordedAt,
  }) {
    return BudgetPeriodLedgerEntry()
      ..occurrenceKey = occurrenceKey
      ..budgetId = budget.id
      ..categoryIds =
          (budget.categories.map((category) => category.id).toList()..sort())
      ..tagIds = (budget.budgetTags.map((tag) => tag.id).toList()..sort())
      ..budgetName = budget.name
      ..budgetType = budget.budgetType
      ..recurrence = budget.recurrence
      ..wasArchived = budget.isArchived
      ..periodStart = periodStart
      ..periodEnd = periodEnd
      // Current amount is retained as best available context only. It is not
      // treated as exact because legacy amount edits have no audit trail.
      ..limitAtPeriod = budget.amount
      ..finalSpent = spent
      ..status = BudgetPeriodLedgerStatus.unknown
      ..provenance = BudgetPeriodLedgerProvenance.legacyUnknown
      ..limitIsKnown = false
      ..isFinalized = true
      ..occurrenceIndex = occurrenceIndex
      ..recordedAt = recordedAt
      ..finalizedAt = recordedAt;
  }

  static (DateTime, DateTime) _periodAt(Budget budget, int occurrence) {
    if (occurrence == 0 || budget.recurrence == BudgetRecurrence.none) {
      return (budget.startDate, budget.endDate);
    }

    return switch (budget.recurrence) {
      BudgetRecurrence.daily => (
          budget.startDate.add(Duration(days: occurrence)),
          budget.endDate.add(Duration(days: occurrence)),
        ),
      BudgetRecurrence.weekly => (
          budget.startDate.add(Duration(days: occurrence * 7)),
          budget.endDate.add(Duration(days: occurrence * 7)),
        ),
      BudgetRecurrence.monthly => (
          DateArithmetic.addMonths(
            budget.startDate,
            occurrence,
            preferDay: budget.startDate.day,
          ),
          DateArithmetic.addMonths(
            budget.endDate,
            occurrence,
            preferDay: budget.endDate.day,
          ),
        ),
      BudgetRecurrence.yearly => (
          DateArithmetic.addYears(
            budget.startDate,
            occurrence,
            preferDay: budget.startDate.day,
          ),
          DateArithmetic.addYears(
            budget.endDate,
            occurrence,
            preferDay: budget.endDate.day,
          ),
        ),
      BudgetRecurrence.none => (budget.startDate, budget.endDate),
    };
  }
}

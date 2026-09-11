import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/db/models/budget_period_ledger_entry.dart';
import 'package:mudra_manager/core/domain/budget_period_ledger_adapter.dart';
import 'package:mudra_manager/core/domain/budget_period_snapshot.dart';
import 'package:mudra_manager/core/utils/date_arithmetic.dart';

final budgetPeriodLedgerServiceProvider =
    Provider<BudgetPeriodLedgerService>((ref) {
  return BudgetPeriodLedgerService(ref.watch(isarServiceProvider));
});

/// Durable completed-period storage. Source transactions are read only.
class BudgetPeriodLedgerService {
  final IsarService isarService;

  BudgetPeriodLedgerService(this.isarService);

  Future<BudgetPeriodLedgerEntry?> findByOccurrenceKey(
    String occurrenceKey,
  ) async {
    final isar = await isarService.getInstance();
    return isar.budgetPeriodLedgerEntrys
        .filter()
        .occurrenceKeyEqualTo(occurrenceKey)
        .findFirst();
  }

  /// Idempotently stores one occurrence. Finalized rows are immutable.
  Future<BudgetPeriodLedgerEntry> upsertEntry(
    BudgetPeriodLedgerEntry candidate,
  ) async {
    final isar = await isarService.getInstance();
    return isar.writeTxn(() async {
      final existing = await isar.budgetPeriodLedgerEntrys
          .filter()
          .occurrenceKeyEqualTo(candidate.occurrenceKey)
          .findFirst();
      if (existing != null && !_mayReplace(existing, candidate)) {
        return existing;
      }
      if (existing != null) candidate.id = existing.id;
      await isar.budgetPeriodLedgerEntrys.put(candidate);
      return candidate;
    });
  }

  Future<BudgetPeriodLedgerEntry> finalizeSnapshot(
    BudgetPeriodSnapshot snapshot, {
    int occurrenceIndex = 0,
    DateTime? finalizedAt,
  }) {
    return upsertEntry(
      snapshot.toLedgerEntry(
        occurrenceIndex: occurrenceIndex,
        finalizedAt: finalizedAt,
      ),
    );
  }

  Future<BudgetPeriodLedgerEntry> recordBackfill(
    BudgetPeriodSnapshot snapshot, {
    required BudgetPeriodLedgerProvenance provenance,
    required bool limitIsKnown,
    int occurrenceIndex = 0,
  }) {
    return upsertEntry(
      snapshot.toLedgerEntry(
        provenance: provenance,
        limitIsKnown: limitIsKnown,
        isFinalized: true,
        occurrenceIndex: occurrenceIndex,
      ),
    );
  }

  Future<List<BudgetPeriodLedgerEntry>> readCompleted({
    DateTime? evaluationDate,
  }) async {
    final isar = await isarService.getInstance();
    final day = DateArithmetic.startOfDay(evaluationDate ?? DateTime.now());
    final entries = await isar.budgetPeriodLedgerEntrys.where().findAll();
    final completed = entries
        .where(
          (entry) =>
              entry.isFinalized &&
              DateArithmetic.startOfDay(entry.periodEnd).isBefore(day),
        )
        .toList();
    completed.sort((a, b) {
      final byEnd = b.periodEnd.compareTo(a.periodEnd);
      return byEnd != 0 ? byEnd : a.occurrenceKey.compareTo(b.occurrenceKey);
    });
    return completed;
  }

  static bool _mayReplace(
    BudgetPeriodLedgerEntry existing,
    BudgetPeriodLedgerEntry candidate,
  ) {
    if (existing.isFinalized) return false;
    if (existing.limitIsKnown && !candidate.limitIsKnown) return false;
    if (_provenanceRank(existing.provenance) >
        _provenanceRank(candidate.provenance)) {
      return false;
    }
    return true;
  }

  static int _provenanceRank(BudgetPeriodLedgerProvenance provenance) {
    return switch (provenance) {
      BudgetPeriodLedgerProvenance.finalizedExact => 4,
      BudgetPeriodLedgerProvenance.backfilledExact => 3,
      BudgetPeriodLedgerProvenance.backfilledBestAvailable => 2,
      BudgetPeriodLedgerProvenance.legacyUnknown => 1,
    };
  }
}

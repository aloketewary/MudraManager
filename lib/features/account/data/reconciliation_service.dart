import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/reconciliation_status.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/features/gamification/models/gamification_enum.dart';
import 'package:mudra_manager/features/gamification/providers/gamification_providers.dart';
import 'package:mudra_manager/features/gamification/services/gamification_service.dart';

final reconciliationServiceProvider = Provider<ReconciliationService>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  final log = ref.getLogger('ReconciliationService');
  final gamificationService = ref.watch(gamificationServiceProvider);

  return ReconciliationService(isarService, log, gamificationService);
});

class ReconciliationService {
  final IsarService _isarService;
  final AppLog _log;
  final GamificationService? _gamificationService;

  ReconciliationService(
    this._isarService,
    this._log,
    this._gamificationService,
  );

  Future<void> verifyTransaction(
    int transactionId, {
    double? bankAmount,
  }) async {
    await _upsertStatus(
      transactionId: transactionId,
      state: ReconciliationState.verified,
      bankAmount: bankAmount,
    );
    _log.i('Transaction $transactionId verified');
    await _gamificationService?.track(GamificationEvent.reconciliationDone);
  }

  Future<void> markDiscrepancy(
    int transactionId,
    double bankAmount, {
    String? notes,
  }) async {
    await _upsertStatus(
      transactionId: transactionId,
      state: ReconciliationState.discrepancy,
      bankAmount: bankAmount,
      notes: notes,
    );
    _log.i('Discrepancy marked for transaction $transactionId');
  }

  Future<int> addMissingTransaction({
    required Account account,
    required double bankAmount,
    required bool isExpense,
    required DateTime date,
    String? description,
  }) async {
    try {
      final isar = await _isarService.getInstance();

      final txn = Transaction.create(
        date: date,
        amount: bankAmount,
        isExpense: isExpense,
        description: description ?? 'Missing transaction (reconciliation)',
      )..account.value = account;

      await isar.writeTxn(() async {
        await isar.transactions.put(txn);
        await txn.account.save();
      });

      await _upsertStatus(
        transactionId: txn.id,
        state: ReconciliationState.unrecognized,
        bankAmount: bankAmount,
        notes: description,
      );

      _log.i('Missing transaction added with ID: ${txn.id}');
      return txn.id;
    } catch (e, stack) {
      _log.e('Failed to add missing transaction', e, stack);
      rethrow;
    }
  }

  Future<List<ReconciliationStatus>> getStatusesForAccount(
    int accountId, {
    ReconciliationState? filterState,
  }) async {
    try {
      final isar = await _isarService.getInstance();

      final transactionIds = await isar.transactions
          .filter()
          .account((q) => q.idEqualTo(accountId))
          .idProperty()
          .findAll();

      if (transactionIds.isEmpty) return [];

      var query = isar.reconciliationStatus
          .filter()
          .anyOf(transactionIds, (q, id) => q.transactionIdEqualTo(id));

      if (filterState != null) {
        query = query.stateEqualTo(filterState);
      }

      return await query.findAll();
    } catch (e, stack) {
      _log.e('Failed to get statuses for account $accountId', e, stack);
      return [];
    }
  }

  Future<ReconciliationStatus?> getReconciliationStatus(
    int transactionId,
  ) async {
    try {
      final isar = await _isarService.getInstance();
      return await isar.reconciliationStatus
          .filter()
          .transactionIdEqualTo(transactionId)
          .findFirst();
    } catch (e, stack) {
      _log.e('Failed to get status for transaction $transactionId', e, stack);
      return null;
    }
  }

  Future<void> _upsertStatus({
    required int transactionId,
    required ReconciliationState state,
    double? bankAmount,
    String? notes,
  }) async {
    try {
      final isar = await _isarService.getInstance();

      final existing = await isar.reconciliationStatus
          .filter()
          .transactionIdEqualTo(transactionId)
          .findFirst();

      if (existing != null) {
        existing.state = state;
        existing.bankAmount = bankAmount;
        existing.notes = notes;
        await isar.writeTxn(() => isar.reconciliationStatus.put(existing));
      } else {
        final status = ReconciliationStatus.create(
          transactionId: transactionId,
          state: state,
          bankAmount: bankAmount,
          notes: notes,
        );
        await isar.writeTxn(() => isar.reconciliationStatus.put(status));
      }
    } catch (e, stack) {
      _log.e(
        'Failed to upsert status for transaction $transactionId',
        e,
        stack,
      );
      rethrow;
    }
  }
}

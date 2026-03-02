import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/reconciliation_status.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';

class ReconciliationService {
  static final ReconciliationService instance = ReconciliationService._();
  static final AppLog _log = AppLog(getLogger(), 'ReconciliationService');

  ReconciliationService._();

  Future<void> verifyTransaction(int transactionId, {double? bankAmount}) async {
    final isar = await IsarService.initIsar();

    final existing = await isar.reconciliationStatus
        .filter()
        .transactionIdEqualTo(transactionId)
        .findFirst();

    if (existing != null) {
      existing.state = ReconciliationState.verified;
      existing.bankAmount = bankAmount;
      await isar.writeTxn(() => isar.reconciliationStatus.put(existing));
    } else {
      final status = ReconciliationStatus.create(
        transactionId: transactionId,
        state: ReconciliationState.verified,
        bankAmount: bankAmount,
      );
      await isar.writeTxn(() => isar.reconciliationStatus.put(status));
    }
    _log.i('Transaction $transactionId verified');
  }

  Future<void> markDiscrepancy(int transactionId, double bankAmount,
      {String? notes}) async {
    final isar = await IsarService.initIsar();

    final existing = await isar.reconciliationStatus
        .filter()
        .transactionIdEqualTo(transactionId)
        .findFirst();

    if (existing != null) {
      existing.state = ReconciliationState.discrepancy;
      existing.bankAmount = bankAmount;
      existing.notes = notes;
      await isar.writeTxn(() => isar.reconciliationStatus.put(existing));
    } else {
      final status = ReconciliationStatus.create(
        transactionId: transactionId,
        state: ReconciliationState.discrepancy,
        bankAmount: bankAmount,
        notes: notes,
      );
      await isar.writeTxn(() => isar.reconciliationStatus.put(status));
    }
    _log.i('Discrepancy marked for transaction $transactionId');
  }

  Future<List<ReconciliationStatus>> getPendingReconciliations(
      int accountId) async {
    final isar = await IsarService.initIsar();

    final transactions = await isar.transactions
        .filter()
        .account((q) => q.idEqualTo(accountId))
        .findAll();

    final transactionIds = transactions.map((t) => t.id).toSet();

    final allStatuses = await isar.reconciliationStatus
        .filter()
        .stateEqualTo(ReconciliationState.pending)
        .findAll();

    return allStatuses
        .where((status) => transactionIds.contains(status.transactionId))
        .toList();
  }

  Future<List<ReconciliationStatus>> getDiscrepancies(int accountId) async {
    final isar = await IsarService.initIsar();

    final transactions = await isar.transactions
        .filter()
        .account((q) => q.idEqualTo(accountId))
        .findAll();

    final transactionIds = transactions.map((t) => t.id).toSet();

    final allStatuses = await isar.reconciliationStatus
        .filter()
        .stateEqualTo(ReconciliationState.discrepancy)
        .findAll();

    return allStatuses
        .where((status) => transactionIds.contains(status.transactionId))
        .toList();
  }

  Future<ReconciliationStatus?> getReconciliationStatus(
      int transactionId) async {
    final isar = await IsarService.initIsar();

    return await isar.reconciliationStatus
        .filter()
        .transactionIdEqualTo(transactionId)
        .findFirst();
  }
}

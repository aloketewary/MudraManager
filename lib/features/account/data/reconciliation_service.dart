import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/reconciliation_status.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/gamification/models/gamification_enum.dart';
import 'package:mudra_manager/features/gamification/providers/gamification_providers.dart';
import 'package:mudra_manager/features/gamification/services/gamification_service.dart';

final reconciliationServiceProvider = Provider<ReconciliationService>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  final log = ref.getLogger('ReconciliationService');
  final gamificationService = ref.watch(gamificationServiceProvider);
  final accountService = ref.watch(accountServiceProvider);

  return ReconciliationService(
    isarService,
    log,
    gamificationService,
    accountService,
  );
});

class ReconciliationService {
  final IsarService _isarService;
  final AppLog _log;
  final GamificationService? _gamificationService;
  final AccountsService _accountsService;

  ReconciliationService(
    this._isarService,
    this._log,
    this._gamificationService,
    this._accountsService,
  );

  Future<double> getCalculatedBalance(int accountId) {
    return _accountsService.getAccountBalance(accountId);
  }

  Future<Category?> _findFallbackCategory(Isar isar, bool isExpense) async {
    final type = isExpense ? CategoryType.expense : CategoryType.income;
    final cat = await isar.categorys
        .filter()
        .categoryTypeEqualTo(type)
        .nameContains('Miscellaneous', caseSensitive: false)
        .findFirst();
    if (cat != null) return cat;
    // Fallback: first parent category of matching type
    return await isar.categorys
        .filter()
        .categoryTypeEqualTo(type)
        .findFirst();
  }

  /// Creates an adjustment transaction to match the actual bank balance.
  /// Returns the adjustment amount (positive = income added, negative = expense added).
  Future<double> reconcileBalance({
    required Account account,
    required double actualBalance,
  }) async {
    final calculated = await getCalculatedBalance(account.id);
    final diff = actualBalance - calculated;
    if (diff.abs() < 0.01) return 0;

    final isar = await _isarService.getInstance();
    // For credit cards, balance = debt. A negative diff means debt decreased,
    // which requires an income (payment) transaction, not an expense.
    // For regular accounts, negative diff means money is missing → expense.
    final isCreditCard = account.accountType == AccountType.creditCard;
    final isExpense = isCreditCard ? diff > 0 : diff < 0;
    final category = await _findFallbackCategory(isar, isExpense);
    final txn = Transaction.create(
      date: DateTime.now(),
      amount: diff.abs(),
      isExpense: isExpense,
      description: 'Balance adjustment (reconciliation)',
    )
      ..account.value = account
      ..category.value = category;

    await isar.writeTxn(() async {
      await isar.transactions.put(txn);
      await txn.account.save();
      await txn.category.save();
    });

    await _upsertStatus(
      transactionId: txn.id,
      state: ReconciliationState.verified,
      bankAmount: actualBalance,
      notes: 'Auto-adjustment: ${isExpense ? "-" : "+"}${diff.abs().toStringAsFixed(2)}',
    );

    _log.i('Reconciled account ${account.id}: adjustment of $diff');
    await _gamificationService?.track(GamificationEvent.reconciliationDone);
    return diff;
  }

  /// Patches existing transactions that have no category (e.g., old reconciliation adjustments).
  Future<int> patchUncategorizedTransactions() async {
    try {
      final isar = await _isarService.getInstance();
      final orphans = await isar.transactions
          .filter()
          .descriptionContains('reconciliation', caseSensitive: false)
          .findAll();

      int patched = 0;
      for (final txn in orphans) {
        await txn.category.load();
        if (txn.category.value != null) continue;
        final cat = await _findFallbackCategory(isar, txn.isExpense);
        if (cat == null) continue;
        txn.category.value = cat;
        await isar.writeTxn(() => txn.category.save());
        patched++;
      }
      if (patched > 0) _log.i('Patched $patched uncategorized transactions');
      return patched;
    } catch (e, stack) {
      _log.e('Failed to patch uncategorized transactions', e, stack);
      rethrow;
    }
  }

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

      final category = await _findFallbackCategory(isar, isExpense);
      final txn = Transaction.create(
        date: date,
        amount: bankAmount,
        isExpense: isExpense,
        description: description ?? 'Missing transaction (reconciliation)',
      )
        ..account.value = account
        ..category.value = category;

      await isar.writeTxn(() async {
        await isar.transactions.put(txn);
        await txn.account.save();
        await txn.category.save();
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

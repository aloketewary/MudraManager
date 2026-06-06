import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Contract tests for transaction UI bug fixes.
/// Verifies the source code contains the correct patterns to prevent
/// each bug from regressing.
void main() {
  late String listScreen;
  late String txnService;
  late String transferScreen;

  setUpAll(() {
    listScreen = File(
      'lib/features/transactions/presentation/screens/transaction_list_screen.dart',
    ).readAsStringSync();
    txnService = File(
      'lib/features/transactions/data/transaction_service.dart',
    ).readAsStringSync();
    transferScreen = File(
      'lib/features/transactions/presentation/screens/transfer_screen_new.dart',
    ).readAsStringSync();
  });

  group('Bug 1 — Undo-Delete Timer Race', () {
    test('1.4: _pendingDeleteId field is removed', () {
      expect(listScreen, isNot(contains('_pendingDeleteId')));
    });

    test('1.4: _pendingDeleteTimer field is removed', () {
      expect(listScreen, isNot(contains('_pendingDeleteTimer')));
    });

    test('1.1: timer callback has mounted guard', () {
      // The timer callback should check mounted before doing work
      final timerSection = listScreen.substring(
        listScreen.indexOf('Timer(const Duration(seconds: 6)'),
      );
      final callbackEnd =
          timerSection.indexOf('_pendingDeletes[txnId] = timer');
      final callback = timerSection.substring(0, callbackEnd);
      expect(callback, contains('if (!mounted) return'));
    });

    test('1.3: deleteTransferAtomic exists in TransactionService', () {
      expect(
          txnService, contains('Future<void> deleteTransferAtomic(int txnId)'));
    });

    test('1.3: deleteTransferAtomic uses single writeTxn', () {
      final methodStart = txnService.indexOf('deleteTransferAtomic');
      final methodBody = txnService.substring(
        methodStart,
        txnService.indexOf('log.i(\'Transfer deleted atomically'),
      );
      // Should have exactly one writeTxn call
      expect('writeTxn'.allMatches(methodBody).length, 1);
    });

    test('1.3: timer uses deleteTransferAtomic for transfers', () {
      expect(listScreen, contains('service.deleteTransferAtomic(txnId)'));
    });
  });

  group('Bug 2 — Transfer Edit Null Safety', () {
    test('null guard before transfer navigation', () {
      final editMethod = listScreen.substring(
        listScreen.indexOf('Future<void> _onEditTransaction'),
        listScreen.indexOf('if (result == true && mounted)'),
      );
      expect(editMethod, contains('if (relatedTx == null)'));
      expect(editMethod, contains('SnackbarService.error'));
      expect(editMethod, contains('return;'));
    });

    test('no nullable access to relatedTx.account.value', () {
      final editMethod = listScreen.substring(
        listScreen.indexOf('Future<void> _onEditTransaction'),
        listScreen.indexOf('if (result == true && mounted)'),
      );
      expect(editMethod, isNot(contains('relatedTx?.account.value')));
      expect(editMethod, isNot(contains('relatedTx?.id')));
    });
  });

  group('Bug 4 — Merge Validation', () {
    test('4a: uses percentage-based tolerance, not hardcoded 1', () {
      expect(listScreen, contains('expense.amount * 0.01'));
      expect(listScreen, isNot(contains('Amounts must match (within ₹1)')));
    });

    test('4b: same-account check exists', () {
      expect(listScreen, contains('fromAccount?.id == toAccount?.id'));
      expect(listScreen, contains('Cannot transfer between the same account'));
    });

    test('4c: deleteTransactionPair exists in TransactionService', () {
      expect(txnService,
          contains('Future<void> deleteTransactionPair(int id1, int id2)'));
    });

    test('4c: merge uses deleteTransactionPair', () {
      expect(
          listScreen, contains('deleteTransactionPair(expense.id, income.id)'));
    });
  });

  group('Bug 6 — Reactive Tag Sheet', () {
    test('uses Consumer with ref.watch in tag sheet', () {
      final tagSheetMethod = listScreen.substring(
        listScreen.indexOf('void _showTagFilterSheet'),
        listScreen.indexOf('void showFilterBottomSheet'),
      );
      expect(tagSheetMethod, contains('Consumer('));
      expect(tagSheetMethod, contains('ref.watch(tagListProvider)'));
      expect(tagSheetMethod, isNot(contains('ref.read(tagListProvider)')));
    });
  });

  group('Bug 8 — Cache Cleared on FAB Return', () {
    test(
        'transactionQueryProvider watches transactionChangeProvider for reactivity',
        () {
      final queryProvider = File(
        'lib/features/transactions/data/transaction_query_provider.dart',
      ).readAsStringSync();
      expect(queryProvider, contains('ref.watch(transactionChangeProvider)'));
    });
  });

  group('Bug 9 — Full Provider Invalidation', () {
    test(
        '9a: _invalidateTransactionProviders invalidates transactionQueryProvider',
        () {
      final method = listScreen.substring(
        listScreen.indexOf('void _invalidateTransactionProviders()'),
        listScreen.indexOf('Widget _buildSearchBar'),
      );
      expect(method, contains('ref.invalidate(transactionQueryProvider)'));
    });

    test('9b: transfer screen invalidates transactionQueryProvider', () {
      expect(
          transferScreen, contains('ref.invalidate(transactionQueryProvider)'));
    });
  });
}

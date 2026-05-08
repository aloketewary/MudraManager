import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Contract tests: verify that providers watch the correct reactive change
/// streams. If someone accidentally removes a `ref.watch(xxxChangeProvider)`
/// line, these tests catch it immediately.
///
/// This is a source-level guard — faster and more reliable than spinning up
/// a full ProviderContainer + Isar for each case.
void main() {
  // ── Helpers ──

  /// Reads a lib source file and returns its content.
  String readSource(String relativePath) {
    final file = File('lib/$relativePath');
    if (!file.existsSync()) {
      fail('Source file not found: lib/$relativePath');
    }
    return file.readAsStringSync();
  }

  /// Extracts the body of a specific provider declaration from source.
  /// Looks for `final <name> = FutureProvider...` or `final <name> = StreamProvider...`
  /// and returns everything up to the matching `});`.
  String extractProvider(String source, String providerName) {
    final start = source.indexOf('final $providerName');
    if (start == -1) fail('Provider "$providerName" not found in source');

    // Find the end of the provider (matching closing `});`)
    var depth = 0;
    var foundOpen = false;
    for (var i = start; i < source.length; i++) {
      if (source[i] == '(') {
        depth++;
        foundOpen = true;
      } else if (source[i] == ')') {
        depth--;
        if (foundOpen && depth == 0) {
          return source.substring(start, i + 2); // include `);`
        }
      }
    }
    fail('Could not find closing bracket for "$providerName"');
  }

  // ── account_providers.dart ──

  group('account_providers.dart watcher contracts', () {
    late String source;

    setUpAll(() {
      source = readSource('features/account/data/account_providers.dart');
    });

    test('allAccountsProvider watches accountChangeProvider', () {
      final body = extractProvider(source, 'allAccountsProvider');
      expect(body, contains('ref.watch(accountChangeProvider)'));
    });

    test('allAccountsProvider watches transactionChangeProvider', () {
      final body = extractProvider(source, 'allAccountsProvider');
      expect(body, contains('ref.watch(transactionChangeProvider)'));
    });

    test('accountsProvider watches both account and transaction changes', () {
      final body = extractProvider(source, 'accountsProvider');
      expect(body, contains('ref.watch(accountChangeProvider)'));
      expect(body, contains('ref.watch(transactionChangeProvider)'));
    });

    test('accountBalanceMapProvider watches both account and transaction changes', () {
      final body = extractProvider(source, 'accountBalanceMapProvider');
      expect(body, contains('ref.watch(accountChangeProvider)'));
      expect(body, contains('ref.watch(transactionChangeProvider)'));
    });

    test('accountBaseBalanceMapProvider watches both account and transaction changes', () {
      final body = extractProvider(source, 'accountBaseBalanceMapProvider');
      expect(body, contains('ref.watch(accountChangeProvider)'));
      expect(body, contains('ref.watch(transactionChangeProvider)'));
    });

    test('frequencySortedAccountsProvider watches transactionChangeProvider', () {
      final body = extractProvider(source, 'frequencySortedAccountsProvider');
      expect(body, contains('ref.watch(transactionChangeProvider)'));
    });
  });

  // ── pending_transaction_prodiver.dart ──

  group('pending_transaction_prodiver.dart watcher contracts', () {
    late String source;

    setUpAll(() {
      source = readSource(
        'features/transactions/data/pending_transaction_prodiver.dart',
      );
    });

    test('pendingTxnCountProvider watches pendingTransactionChangeProvider', () {
      final body = extractProvider(source, 'pendingTxnCountProvider');
      expect(body, contains('ref.watch(pendingTransactionChangeProvider)'));
    });

    test('pendingTxnDataProvider watches pendingTransactionChangeProvider', () {
      final body = extractProvider(source, 'pendingTxnDataProvider');
      expect(body, contains('ref.watch(pendingTransactionChangeProvider)'));
    });
  });

  // ── analytics_provider.dart ──

  group('analytics_provider.dart watcher contracts', () {
    late String source;

    setUpAll(() {
      source = readSource('features/analytics/data/analytics_provider.dart');
    });

    test('financialHealthProvider watches transactionChangeProvider', () {
      final body = extractProvider(source, 'financialHealthProvider');
      expect(body, contains('ref.watch(transactionChangeProvider)'));
    });

    test('financialHealthProvider watches accountChangeProvider', () {
      final body = extractProvider(source, 'financialHealthProvider');
      expect(body, contains('ref.watch(accountChangeProvider)'));
    });

    test('categoryTrendsProvider watches transactionChangeProvider', () {
      final body = extractProvider(source, 'categoryTrendsProvider');
      expect(body, contains('ref.watch(transactionChangeProvider)'));
    });

    test('predictedSpendingProvider watches transactionChangeProvider', () {
      final body = extractProvider(source, 'predictedSpendingProvider');
      expect(body, contains('ref.watch(transactionChangeProvider)'));
    });

    test('cashFlowForecastProvider watches transactionChangeProvider', () {
      final body = extractProvider(source, 'cashFlowForecastProvider');
      expect(body, contains('ref.watch(transactionChangeProvider)'));
    });
  });

  // ── collection_watchers.dart ──

  group('collection_watchers.dart completeness', () {
    late String source;

    setUpAll(() {
      source = readSource('core/providers/collection_watchers.dart');
    });

    test('pendingTransactionChangeProvider exists', () {
      expect(source, contains('final pendingTransactionChangeProvider'));
      expect(source, contains('isar.pendingTransactions.watchLazy'));
    });

    test('transactionChangeProvider exists', () {
      expect(source, contains('final transactionChangeProvider'));
      expect(source, contains('isar.transactions.watchLazy'));
    });

    test('accountChangeProvider exists', () {
      expect(source, contains('final accountChangeProvider'));
      expect(source, contains('isar.accounts.watchLazy'));
    });

    test('tagChangeProvider exists', () {
      expect(source, contains('final tagChangeProvider'));
      expect(source, contains('isar.tags.watchLazy'));
    });
  });
}

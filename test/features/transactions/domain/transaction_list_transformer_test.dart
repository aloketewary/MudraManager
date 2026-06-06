import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/features/transactions/domain/transaction_list_transformer.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/transaction_group.dart';

/// Creates a minimal transaction for testing.
Transaction _tx(DateTime date, {double amount = 100, bool isExpense = true}) {
  return Transaction.create(
    date: date,
    amount: amount,
    isExpense: isExpense,
  );
}

void main() {
  group('toTransactionListEntries', () {
    // ── Grouping behavior ──

    test('empty list returns empty', () {
      final result = toTransactionListEntries([]);
      expect(result, isEmpty);
    });

    test('single transaction produces one header + one item', () {
      final result = toTransactionListEntries([
        _tx(DateTime(2025, 6, 15, 10, 30)),
      ]);

      expect(result.length, 2);
      expect(result[0], isA<TxHeader>());
      expect(result[1], isA<TxItem>());
      expect((result[0] as TxHeader).group, DateTime(2025, 6, 15));
    });

    test('transactions on same day get one header', () {
      final result = toTransactionListEntries([
        _tx(DateTime(2025, 6, 15, 18, 0)),
        _tx(DateTime(2025, 6, 15, 10, 0)),
        _tx(DateTime(2025, 6, 15, 8, 30)),
      ]);

      // 1 header + 3 items
      expect(result.length, 4);
      expect(result.whereType<TxHeader>().length, 1);
      expect(result.whereType<TxItem>().length, 3);
    });

    test('transactions on different days get separate headers', () {
      final result = toTransactionListEntries([
        _tx(DateTime(2025, 6, 15, 10, 0)),
        _tx(DateTime(2025, 6, 14, 10, 0)),
        _tx(DateTime(2025, 6, 13, 10, 0)),
      ]);

      // 3 headers + 3 items
      expect(result.length, 6);
      expect(result.whereType<TxHeader>().length, 3);

      final headers = result.whereType<TxHeader>().toList();
      expect(headers[0].group, DateTime(2025, 6, 15));
      expect(headers[1].group, DateTime(2025, 6, 14));
      expect(headers[2].group, DateTime(2025, 6, 13));
    });

    test('mixed same-day and different-day transactions', () {
      final result = toTransactionListEntries([
        _tx(DateTime(2025, 6, 15, 18, 0)),
        _tx(DateTime(2025, 6, 15, 10, 0)),
        _tx(DateTime(2025, 6, 14, 9, 0)),
        _tx(DateTime(2025, 6, 12, 8, 0)),
        _tx(DateTime(2025, 6, 12, 7, 0)),
      ]);

      // 3 date groups: Jun 15 (2 txns), Jun 14 (1 txn), Jun 12 (2 txns)
      expect(result.whereType<TxHeader>().length, 3);
      expect(result.whereType<TxItem>().length, 5);

      // Verify structure: header, items, header, items, header, items
      expect(result[0], isA<TxHeader>());
      expect(result[1], isA<TxItem>());
      expect(result[2], isA<TxItem>());
      expect(result[3], isA<TxHeader>());
      expect(result[4], isA<TxItem>());
      expect(result[5], isA<TxHeader>());
      expect(result[6], isA<TxItem>());
      expect(result[7], isA<TxItem>());
    });

    // ── Header date normalization ──

    test('header date strips time component', () {
      final result = toTransactionListEntries([
        _tx(DateTime(2025, 6, 15, 23, 59, 59)),
      ]);

      final header = result[0] as TxHeader;
      expect(header.group, DateTime(2025, 6, 15));
      expect(header.group.hour, 0);
      expect(header.group.minute, 0);
      expect(header.group.second, 0);
    });

    // ── Month boundary ──

    test('transactions spanning month boundary get separate headers', () {
      final result = toTransactionListEntries([
        _tx(DateTime(2025, 7, 1, 10, 0)),
        _tx(DateTime(2025, 6, 30, 10, 0)),
      ]);

      expect(result.whereType<TxHeader>().length, 2);
      final headers = result.whereType<TxHeader>().toList();
      expect(headers[0].group.month, 7);
      expect(headers[1].group.month, 6);
    });

    // ── Year boundary ──

    test('transactions spanning year boundary get separate headers', () {
      final result = toTransactionListEntries([
        _tx(DateTime(2026, 1, 1, 10, 0)),
        _tx(DateTime(2025, 12, 31, 10, 0)),
      ]);

      expect(result.whereType<TxHeader>().length, 2);
      final headers = result.whereType<TxHeader>().toList();
      expect(headers[0].group, DateTime(2026, 1, 1));
      expect(headers[1].group, DateTime(2025, 12, 31));
    });

    // ── Order preservation ──

    test('preserves input order (does not re-sort)', () {
      // Input is already sorted desc — verify output maintains order
      final transactions = [
        _tx(DateTime(2025, 6, 15), amount: 500),
        _tx(DateTime(2025, 6, 15), amount: 200),
        _tx(DateTime(2025, 6, 14), amount: 100),
      ];

      final result = toTransactionListEntries(transactions);
      final items = result.whereType<TxItem>().toList();

      expect(items[0].txn.amount, 500);
      expect(items[1].txn.amount, 200);
      expect(items[2].txn.amount, 100);
    });

    // ── Income and expense mixed ──

    test('income and expense on same day share one header', () {
      final result = toTransactionListEntries([
        _tx(DateTime(2025, 6, 15), isExpense: true),
        _tx(DateTime(2025, 6, 15), isExpense: false),
      ]);

      expect(result.whereType<TxHeader>().length, 1);
      expect(result.whereType<TxItem>().length, 2);
    });
  });
}

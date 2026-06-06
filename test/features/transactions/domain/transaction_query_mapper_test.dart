import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/features/transactions/domain/filter_state.dart';
import 'package:mudra_manager/features/transactions/domain/transaction_query_mapper.dart';
import 'package:mudra_manager/features/transactions/domain/transaction_view_mode.dart';

void main() {
  group('createTransactionQuery', () {
    // ── InfiniteView ──

    group('InfiniteView', () {
      test('produces null date bounds', () {
        final query = createTransactionQuery(
          const InfiniteView(),
          const FilterState(),
        );

        expect(query.startDate, isNull);
        expect(query.endDate, isNull);
      });

      test('passes through filter state', () {
        final query = createTransactionQuery(
          const InfiniteView(),
          const FilterState(
            type: TransactionTypeFilter.expense,
            categoryId: 5,
            tagId: 3,
            searchQuery: 'food',
          ),
        );

        expect(query.type, TransactionTypeFilter.expense);
        expect(query.categoryId, 5);
        expect(query.tagId, 3);
        expect(query.searchQuery, 'food');
      });
    });

    // ── MonthView ──

    group('MonthView', () {
      test('June 2026 spans entire month', () {
        final query = createTransactionQuery(
          const MonthView(2026, 6),
          const FilterState(),
        );

        // Starts at midnight June 1
        expect(query.startDate, DateTime(2026, 6, 1));
        // Ends at last microsecond of June 30
        expect(query.endDate!.year, 2026);
        expect(query.endDate!.month, 6);
        expect(query.endDate!.day, 30);
        expect(query.endDate!.hour, 23);
      });

      test('January spans full month (no year boundary issue)', () {
        final query = createTransactionQuery(
          const MonthView(2026, 1),
          const FilterState(),
        );

        expect(query.startDate, DateTime(2026, 1, 1));
        expect(query.endDate!.month, 1);
        expect(query.endDate!.day, 31);
      });

      test('December spans full month (year rollover)', () {
        final query = createTransactionQuery(
          const MonthView(2025, 12),
          const FilterState(),
        );

        expect(query.startDate, DateTime(2025, 12, 1));
        expect(query.endDate!.month, 12);
        expect(query.endDate!.day, 31);
      });

      test('February handles leap year correctly', () {
        // 2024 is a leap year
        final query = createTransactionQuery(
          const MonthView(2024, 2),
          const FilterState(),
        );

        expect(query.startDate, DateTime(2024, 2, 1));
        expect(query.endDate!.day, 29);
      });

      test('February handles non-leap year correctly', () {
        final query = createTransactionQuery(
          const MonthView(2025, 2),
          const FilterState(),
        );

        expect(query.startDate, DateTime(2025, 2, 1));
        expect(query.endDate!.day, 28);
      });

      test('income filter propagates through MonthView', () {
        final query = createTransactionQuery(
          const MonthView(2026, 6),
          const FilterState(type: TransactionTypeFilter.income),
        );

        expect(query.type, TransactionTypeFilter.income);
        expect(query.startDate, isNotNull);
      });
    });

    // ── DateRangeView ──

    group('DateRangeView', () {
      test('arbitrary range normalizes start to midnight and end to 23:59:59',
          () {
        final query = createTransactionQuery(
          DateRangeView(
            DateTime(2025, 6, 10, 14, 30), // mid-afternoon start
            DateTime(2025, 6, 20, 8, 0), // morning end
          ),
          const FilterState(),
        );

        // Start normalized to midnight
        expect(query.startDate, DateTime(2025, 6, 10));
        // End normalized to end of day
        expect(query.endDate, DateTime(2025, 6, 20, 23, 59, 59));
      });

      test('single day range works', () {
        final query = createTransactionQuery(
          DateRangeView(
            DateTime(2025, 6, 15),
            DateTime(2025, 6, 15),
          ),
          const FilterState(),
        );

        expect(query.startDate, DateTime(2025, 6, 15));
        expect(query.endDate, DateTime(2025, 6, 15, 23, 59, 59));
      });

      test('category filter propagates through DateRangeView', () {
        final query = createTransactionQuery(
          DateRangeView(
            DateTime(2025, 6, 1),
            DateTime(2025, 6, 30),
          ),
          const FilterState(categoryId: 42),
        );

        expect(query.categoryId, 42);
        expect(query.startDate, isNotNull);
        expect(query.endDate, isNotNull);
      });
    });

    // ── FilterState defaults ──

    group('FilterState defaults', () {
      test('default filter state produces neutral query', () {
        final query = createTransactionQuery(
          const InfiniteView(),
          const FilterState(),
        );

        expect(query.type, TransactionTypeFilter.all);
        expect(query.categoryId, isNull);
        expect(query.tagId, isNull);
        expect(query.searchQuery, '');
      });
    });
  });
}

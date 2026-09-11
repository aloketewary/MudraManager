import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/providers/budget_refresh_provider.dart';
import 'package:mudra_manager/core/providers/collection_watchers.dart';
import 'package:mudra_manager/core/providers/date_change_provider.dart';
import 'package:mudra_manager/core/utils/date_arithmetic.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer isolatedContainer() {
    const emptyEvents = Stream<void>.empty();
    const emptyDates = Stream<DateTime>.empty();
    return ProviderContainer(
      overrides: [
        transactionChangeProvider.overrideWith((ref) => emptyEvents),
        budgetChangeProvider.overrideWith((ref) => emptyEvents),
        categoryChangeProvider.overrideWith((ref) => emptyEvents),
        tagChangeProvider.overrideWith((ref) => emptyEvents),
        dateChangeProvider.overrideWith((ref) => emptyDates),
      ],
    );
  }

  group('Property 7: shared budget refresh contract', () {
    test('all supported reasons converge on one generation and evaluation day',
        () {
      // **Validates: Requirements 2.1, 2.2, 2.4, 2.12, 3.6, 3.7, 3.12**
      // Generated deterministic event sequence: 120 iterations.
      final container = isolatedContainer();
      addTearDown(container.dispose);
      final notifier = container.read(budgetRefreshProvider.notifier);
      final initial = container.read(budgetRefreshProvider);

      for (var i = 0; i < 120; i++) {
        final reason =
            BudgetRefreshReason.values[i % BudgetRefreshReason.values.length];
        final evaluationDate = DateTime(
          2024 + i ~/ 365,
          (i ~/ 31) % 12 + 1,
          i % 28 + 1,
          18,
          45,
        );
        notifier.refresh(reason, evaluationDate: evaluationDate);
        final state = container.read(budgetRefreshProvider);

        expect(state.generation, initial.generation + i + 1);
        expect(state.reason, reason);
        expect(
          state.evaluationDate,
          DateArithmetic.startOfDay(evaluationDate),
        );
        expect(state.evaluationDate.hour, 0);
        expect(state.evaluationDate.minute, 0);
      }
    });

    test('retry is a normal shared generation, not provider-specific refresh',
        () {
      // **Validates: Requirements 2.12, 3.6, 3.7**
      final container = isolatedContainer();
      addTearDown(container.dispose);
      final notifier = container.read(budgetRefreshProvider.notifier);
      final before = container.read(budgetRefreshProvider);

      notifier.refresh(
        BudgetRefreshReason.retry,
        evaluationDate: DateTime(2024, 2, 29, 23, 59),
      );
      final after = container.read(budgetRefreshProvider);

      expect(after.generation, before.generation + 1);
      expect(after.reason, BudgetRefreshReason.retry);
      expect(after.evaluationDate, DateTime(2024, 2, 29));
    });

    test('generation never repeats across refresh event sequence', () {
      // **Validates: Requirements 2.2, 2.4, 2.12, 3.10**
      final container = isolatedContainer();
      addTearDown(container.dispose);
      final notifier = container.read(budgetRefreshProvider.notifier);
      final generations = <int>{};

      for (var i = 0; i < 120; i++) {
        notifier.refresh(
          BudgetRefreshReason.values[i % BudgetRefreshReason.values.length],
          evaluationDate: DateTime(2025, 1, 1).add(Duration(days: i)),
        );
        generations.add(container.read(budgetRefreshProvider).generation);
      }

      expect(generations.length, 120);
    });
  });
}

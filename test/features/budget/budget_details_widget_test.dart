import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/core/domain/budget_constraint_snapshot.dart';
import 'package:mudra_manager/core/domain/budget_period_snapshot.dart';
import 'package:mudra_manager/core/domain/financial_states.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/budget_refresh_provider.dart';
import 'package:mudra_manager/features/budget/data/budget_constraint_provider.dart';
import 'package:mudra_manager/features/budget/presentation/screens/budget_details_screen.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'budget_widget_fixtures.dart';

void main() {
  setUp(() async {
    await initializeWidgetTestPrefs();
  });

  final refresh = BudgetRefreshState(
    generation: 1,
    evaluationDate: DateTime(2024, 2, 15),
    reason: BudgetRefreshReason.navigation,
  );

  Widget detailApp({
    required AsyncValue<BudgetConstraintSnapshot?> value,
    bool withRouter = false,
  }) {
    final overrides = [
      ...baseWidgetOverrides(refresh: refresh),
      budgetConstraintByIdProvider.overrideWith(
        (ref, _) => value,
      ),
    ];
    final child = const BudgetDetailsScreen(budgetId: 1);
    if (!withRouter) {
      return ProviderScope(
        key: UniqueKey(),
        overrides: overrides.cast(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: child,
        ),
      );
    }

    final router = GoRouter(
      initialLocation: '/budget-details',
      routes: [
        GoRoute(path: '/budget-details', builder: (_, __) => child),
        GoRoute(
          path: '/transactions',
          builder: (_, __) => const Text('transactions route'),
        ),
        GoRoute(
          path: '/add-transaction',
          builder: (_, __) => const Text('add transaction route'),
        ),
        GoRoute(
          path: '/add-budget',
          builder: (_, __) => const Text('edit budget route'),
        ),
      ],
    );
    return ProviderScope(
      overrides: overrides.cast(),
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
      ),
    );
  }

  BudgetConstraintSnapshot snapshot({
    required double spent,
    BudgetConstraintUrgency urgency = BudgetConstraintUrgency.withinLimit,
    BudgetState state = BudgetState.ok,
  }) {
    final budget = makeBudget(
      id: 1,
      name: 'Canonical budget',
      amount: 1000,
      start: DateTime(2024, 2, 1),
      end: DateTime(2024, 2, 29),
      recurrence: BudgetRecurrence.monthly,
    );
    final period = makeSnapshot(
      budget: budget,
      evaluationDate: refresh.evaluationDate,
      periodStart: DateTime(2024, 2, 1),
      periodEnd: DateTime(2024, 2, 29),
      spent: spent,
    );
    return makeConstraint(
      period,
      currentDailySpend: 20,
      allowedDailySpend: 30,
      remainingDailyAllowance: 25,
      urgency: urgency,
      state: state,
    );
  }

  testWidgets(
      'detail renders canonical period dates and preserves route action',
      (tester) async {
    final value = snapshot(spent: 250);
    await tester.pumpWidget(
      detailApp(value: AsyncValue.data(value), withRouter: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('Canonical budget'), findsOneWidget);
    expect(find.textContaining('Feb'), findsWidgets);
    expect(find.text('View Transactions'), findsOneWidget);
    expect(find.byType(CurrencyText), findsWidgets);

    await tester.tap(find.text('View Transactions'));
    await tester.pumpAndSettle();
    expect(find.text('transactions route'), findsOneWidget);
  });

  testWidgets('detail clamps exceeded progress and keeps over-limit state safe',
      (tester) async {
    final value = snapshot(
      spent: 1250,
      urgency: BudgetConstraintUrgency.breached,
      state: BudgetState.breach,
    );
    await tester.pumpWidget(detailApp(value: AsyncValue.data(value)));
    await tester.pumpAndSettle();

    final progress = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(progress.value, 1.0);
    expect(progress.value!.isFinite, isTrue);
  });

  testWidgets('detail loading, not-found, error, and retry states are safe',
      (tester) async {
    await tester.pumpWidget(detailApp(value: const AsyncValue.loading()));
    await tester.pump();
    expect(find.byType(BudgetCardSkeleton), findsWidgets);
    expect(find.text('Canonical budget'), findsNothing);

    await tester.pumpWidget(
      detailApp(value: const AsyncValue.data(null)),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('No Budgets'), findsOneWidget);

    await tester.pumpWidget(
      detailApp(
        value: AsyncValue.error('detail refresh failed', StackTrace.empty),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Canonical budget'), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.text('Canonical budget'), findsNothing);
  });
}

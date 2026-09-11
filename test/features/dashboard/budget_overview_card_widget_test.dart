import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/budget_refresh_provider.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/features/budget/presentation/widgets/budget_overview_card.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../budget/budget_widget_fixtures.dart';

void main() {
  setUp(() {
    BaseCurrency.sync('INR');
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  final refresh = BudgetRefreshState(
    generation: 1,
    evaluationDate: DateTime(2024, 2, 15),
    reason: BudgetRefreshReason.navigation,
  );

  Widget cardApp({
    required AsyncValue<DashboardData> dashboard,
    bool withRouter = false,
  }) {
    final overrides = [
      ...baseWidgetOverrides(refresh: refresh),
      dashboardDataProvider.overrideWithValue(dashboard),
    ];
    final child = const BudgetOverviewCard();
    if (!withRouter) {
      return ProviderScope(
        overrides: overrides.cast(),
        child: localizedApp(child),
      );
    }

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, __) => child),
        GoRoute(
          path: '/budget-dashboard',
          builder: (_, __) => const Text('budget dashboard route'),
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

  BudgetWithProgress progress({
    required int id,
    required String name,
    required double amount,
    required double spent,
    required BudgetRecurrence recurrence,
    DateTime? start,
    DateTime? end,
  }) {
    final periodStart = start ?? DateTime(2024, 2, 1);
    final periodEnd = end ?? DateTime(2024, 2, 29);
    final budget = makeBudget(
      id: id,
      name: name,
      amount: amount,
      start: periodStart,
      end: periodEnd,
      recurrence: recurrence,
    );
    return makeProgress(
      makeSnapshot(
        budget: budget,
        evaluationDate: refresh.evaluationDate,
        periodStart: periodStart,
        periodEnd: periodEnd,
        spent: spent,
      ),
    );
  }

  testWidgets('monthly card renders title, metrics, finite progress, and route',
      (tester) async {
    final budget = progress(
      id: 1,
      name: 'Monthly',
      amount: 1000,
      spent: 250,
      recurrence: BudgetRecurrence.monthly,
    );
    final data = makeDashboardData(
      budgets: [budget],
      generation: refresh.generation,
      evaluationDate: refresh.evaluationDate,
    );

    await tester.pumpWidget(
        cardApp(dashboard: AsyncValue.data(data), withRouter: true));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Monthly Budget'), findsOneWidget);
    expect(find.text('Remaining'), findsOneWidget);
    expect(find.text('Per Day'), findsOneWidget);
    final tween = tester.widget<TweenAnimationBuilder<double>>(
      find.byType(TweenAnimationBuilder<double>),
    );
    expect(tween.tween.end, inInclusiveRange(0.0, 1.0));
    expect(tween.tween.end!.isFinite, isTrue);

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    expect(find.text('budget dashboard route'), findsOneWidget);
  });

  testWidgets(
      'mixed periods use safe overview label and period-aware daily sum',
      (tester) async {
    final budgets = [
      progress(
        id: 1,
        name: 'Daily',
        amount: 100,
        spent: 50,
        recurrence: BudgetRecurrence.daily,
        start: DateTime(2024, 2, 15),
        end: DateTime(2024, 2, 15),
      ),
      progress(
        id: 2,
        name: 'Weekly',
        amount: 140,
        spent: 70,
        recurrence: BudgetRecurrence.weekly,
        start: DateTime(2024, 2, 15),
        end: DateTime(2024, 2, 21),
      ),
      progress(
        id: 3,
        name: 'Monthly',
        amount: 300,
        spent: 100,
        recurrence: BudgetRecurrence.monthly,
        start: DateTime(2024, 2, 1),
        end: DateTime(2024, 2, 29),
      ),
      progress(
        id: 4,
        name: 'Yearly',
        amount: 3650,
        spent: 365,
        recurrence: BudgetRecurrence.yearly,
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 12, 31),
      ),
      progress(
        id: 5,
        name: 'Custom',
        amount: 100,
        spent: 20,
        recurrence: BudgetRecurrence.none,
        start: DateTime(2024, 2, 15),
        end: DateTime(2024, 2, 15),
      ),
    ];
    final data = makeDashboardData(
      budgets: budgets,
      generation: refresh.generation,
      evaluationDate: refresh.evaluationDate,
    );

    await tester.pumpWidget(cardApp(dashboard: AsyncValue.data(data)));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Monthly Budget'), findsNothing);
    expect(find.text('Budget'), findsOneWidget);
    final amounts = tester.widgetList<CurrencyText>(find.byType(CurrencyText));
    expect(
      amounts.map((widget) => widget.amount).toList(),
      contains(3685.0),
    );
    expect(
      amounts.map((widget) => widget.amount).toList(),
      contains(closeTo(96.452, 0.01)),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('zero limit and negative remaining stay safe and finite',
      (tester) async {
    final data = makeDashboardData(
      budgets: [
        progress(
          id: 1,
          name: 'Zero',
          amount: 0,
          spent: 0,
          recurrence: BudgetRecurrence.none,
        ),
        progress(
          id: 2,
          name: 'Exceeded',
          amount: 100,
          spent: 250,
          recurrence: BudgetRecurrence.weekly,
        ),
      ],
      generation: refresh.generation,
      evaluationDate: refresh.evaluationDate,
    );

    await tester.pumpWidget(cardApp(dashboard: AsyncValue.data(data)));
    await tester.pump(const Duration(seconds: 2));

    final tween = tester.widget<TweenAnimationBuilder<double>>(
      find.byType(TweenAnimationBuilder<double>),
    );
    expect(tween.tween.end, 1.0);
    expect(tween.tween.end!.isFinite, isTrue);
    final amounts = tester.widgetList<CurrencyText>(find.byType(CurrencyText));
    expect(amounts.any((widget) => widget.amount == -150), isTrue);
  });

  testWidgets('loading, error, empty, and stale generation hide current values',
      (tester) async {
    final budget = progress(
      id: 1,
      name: 'Current',
      amount: 100,
      spent: 25,
      recurrence: BudgetRecurrence.monthly,
    );
    final data = makeDashboardData(
      budgets: [budget],
      generation: refresh.generation,
      evaluationDate: refresh.evaluationDate,
    );

    for (final dashboard in <AsyncValue<DashboardData>>[
      const AsyncValue.loading(),
      AsyncValue.error('refresh failed', StackTrace.empty),
      const AsyncValue.data(DashboardData(
        transactions: [],
        accounts: [],
        accountBalances: {},
        budgets: [],
        recurringExpenses: [],
        goals: [],
        totalIncome: 0,
        totalExpense: 0,
        totalBalance: 0,
        netWorth: 0,
        pendingSmsCount: 0,
      )),
    ]) {
      await tester.pumpWidget(cardApp(dashboard: dashboard));
      await tester.pump();
      expect(find.text('Remaining'), findsNothing);
    }

    final stale = makeDashboardData(
      budgets: [budget],
      generation: refresh.generation + 1,
      evaluationDate: refresh.evaluationDate,
    );
    await tester.pumpWidget(cardApp(dashboard: AsyncValue.data(stale)));
    await tester.pump();
    expect(find.text('Remaining'), findsNothing);

    // Keep data fixture used so this test documents stale-vs-current contract.
    expect(data.budgetGeneration, refresh.generation);
  });
}

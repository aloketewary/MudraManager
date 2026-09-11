import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/core/domain/budget_constraint_snapshot.dart';
import 'package:mudra_manager/core/domain/budget_period_snapshot.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/providers/budget_refresh_provider.dart';
import 'package:mudra_manager/features/budget/data/budget_constraint_provider.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/features/budget/presentation/screens/adaptive_budget_dashboard.dart';
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

  Widget dashboardApp({
    required AsyncValue<List<BudgetConstraintSnapshot>> constraints,
    required AsyncValue<List<BudgetHistoryEntry>> history,
    AsyncValue<BudgetPortfolio>? portfolio,
    bool withRouter = false,
  }) {
    final overrides = [
      ...baseWidgetOverrides(refresh: refresh),
      budgetConstraintsProvider.overrideWithValue(constraints),
      budgetHistoryProvider.overrideWithValue(history),
      budgetPortfolioProvider.overrideWithValue(
        portfolio ??
            const AsyncValue.data(
              BudgetPortfolio(
                totalBudgets: 1,
                totalRemaining: 750,
                breachedCount: 0,
                paceRiskCount: 0,
              ),
            ),
      ),
    ];

    final child = const AdaptiveBudgetDashboard();
    if (!withRouter) {
      return ProviderScope(
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
      initialLocation: '/budget-dashboard',
      routes: [
        GoRoute(path: '/budget-dashboard', builder: (_, __) => child),
        GoRoute(
          path: '/budget-details',
          builder: (_, __) => const Text('detail route'),
        ),
        GoRoute(
          path: '/add-budget',
          builder: (_, __) => const Text('add budget route'),
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

  BudgetPeriodSnapshot currentSnapshot() {
    final budget = makeBudget(
      id: 1,
      name: 'Current budget',
      amount: 1000,
      start: DateTime(2024, 2, 1),
      end: DateTime(2024, 2, 29),
      recurrence: BudgetRecurrence.monthly,
    );
    return makeSnapshot(
      budget: budget,
      evaluationDate: refresh.evaluationDate,
      periodStart: DateTime(2024, 2, 1),
      periodEnd: DateTime(2024, 2, 29),
      spent: 250,
    );
  }

  BudgetHistoryEntry historyEntry({
    required int id,
    required String name,
    required DateTime end,
    required BudgetPeriodStatus? status,
  }) {
    return BudgetHistoryEntry(
      occurrenceKey: '$id:${end.toIso8601String()}',
      budgetId: id,
      budgetName: name,
      recurrence: BudgetRecurrence.monthly,
      periodStart: end.subtract(const Duration(days: 29)),
      periodEnd: end,
      limit: 1000,
      spent: status == BudgetPeriodStatus.exceeded ? 1250 : 1000,
      status: status,
      limitIsKnown: true,
    );
  }

  testWidgets(
      'dashboard renders current period and completed history separately',
      (tester) async {
    final current = currentSnapshot();
    final entries = [
      historyEntry(
        id: 2,
        name: 'Later completed',
        end: DateTime(2024, 2, 10),
        status: BudgetPeriodStatus.exceeded,
      ),
      historyEntry(
        id: 3,
        name: 'Earlier completed',
        end: DateTime(2024, 1, 31),
        status: BudgetPeriodStatus.met,
      ),
    ];

    await tester.pumpWidget(
      dashboardApp(
        constraints: AsyncValue.data([makeConstraint(current)]),
        history: AsyncValue.data(entries),
        withRouter: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Current budget'), findsOneWidget);
    expect(find.text('Later completed'), findsOneWidget);
    expect(find.text('Earlier completed'), findsOneWidget);
    expect(find.text('Exceeded'), findsOneWidget);
    expect(find.text('Met'), findsOneWidget);
    expect(find.textContaining('Feb'), findsWidgets);

    final laterIndex = tester
        .widgetList<Text>(find.byType(Text))
        .toList()
        .indexWhere((text) => text.data == 'Later completed');
    final earlierIndex = tester
        .widgetList<Text>(find.byType(Text))
        .toList()
        .indexWhere((text) => text.data == 'Earlier completed');
    expect(laterIndex, lessThan(earlierIndex));

    await tester.tap(find.text('Current budget'));
    await tester.pumpAndSettle();
    expect(find.text('detail route'), findsOneWidget);
  });

  testWidgets('history renders recurrence and unknown limit metadata',
      (tester) async {
    final entry = BudgetHistoryEntry(
      occurrenceKey: '4:2024-01-31',
      budgetId: 4,
      budgetName: 'Legacy budget',
      recurrence: BudgetRecurrence.yearly,
      periodStart: DateTime(2023, 1, 1),
      periodEnd: DateTime(2023, 12, 31),
      limit: 0,
      spent: 250,
      status: null,
      limitIsKnown: false,
      valueSource: BudgetHistoryValueSource.unknown,
    );

    await tester.pumpWidget(
      dashboardApp(
        constraints: const AsyncValue.data([]),
        history: AsyncValue.data([entry]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Legacy budget'), findsOneWidget);
    expect(find.textContaining('yearly'), findsOneWidget);
    expect(find.text('Unknown'), findsOneWidget);
    expect(find.text('Historical limit unavailable'), findsOneWidget);
    expect(find.text('Limit unavailable'), findsOneWidget);
  });

  testWidgets('empty current and history states remain distinct',
      (tester) async {
    await tester.pumpWidget(
      dashboardApp(
        constraints: const AsyncValue.data([]),
        history: const AsyncValue.data([]),
        portfolio: const AsyncValue.data(
          BudgetPortfolio(
            totalBudgets: 0,
            totalRemaining: 0,
            breachedCount: 0,
            paceRiskCount: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AdaptiveBudgetDashboard), findsOneWidget);
    expect(find.text('No completed budgets'), findsOneWidget);
    expect(find.text('Current budget'), findsNothing);
  });

  testWidgets('loading and error states do not expose stale current values',
      (tester) async {
    await tester.pumpWidget(
      dashboardApp(
        constraints: const AsyncValue.loading(),
        history: const AsyncValue.loading(),
      ),
    );
    await tester.pump();
    expect(find.byType(BudgetCardSkeleton), findsWidgets);
    expect(find.text('Current budget'), findsNothing);

    await tester.pumpWidget(
      dashboardApp(
        constraints:
            AsyncValue.error('budget refresh failed', StackTrace.empty),
        history: AsyncValue.error('history refresh failed', StackTrace.empty),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Current budget'), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.text('Current budget'), findsNothing);
  });
}

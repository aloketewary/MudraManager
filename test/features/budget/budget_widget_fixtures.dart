import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mudra_manager/core/domain/budget_constraint_snapshot.dart';
import 'package:mudra_manager/core/domain/financial_states.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/budget_type.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/budget_refresh_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';

Budget makeBudget({
  required int id,
  required String name,
  required double amount,
  required DateTime start,
  required DateTime end,
  required BudgetRecurrence recurrence,
}) {
  final budget = Budget.create(
    name: name,
    amount: amount,
    startDate: start,
    endDate: end,
  )
    ..id = id
    ..budgetType = BudgetType.categoryWise
    ..recurrence = recurrence;
  return budget;
}

BudgetPeriodSnapshot makeSnapshot({
  required Budget budget,
  required DateTime evaluationDate,
  required DateTime periodStart,
  required DateTime periodEnd,
  required double spent,
}) {
  return BudgetPeriodSnapshot.fromBudget(
    budget: budget,
    evaluationDate: evaluationDate,
    periodStart: periodStart,
    periodEnd: periodEnd,
    spent: spent,
  );
}

BudgetWithProgress makeProgress(BudgetPeriodSnapshot snapshot) {
  return BudgetWithProgress.fromSnapshot(snapshot);
}

DashboardData makeDashboardData({
  required List<BudgetWithProgress> budgets,
  required int generation,
  required DateTime evaluationDate,
}) {
  return DashboardData(
    transactions: const [],
    accounts: const [],
    accountBalances: const {},
    budgets: budgets,
    recurringExpenses: const [],
    goals: const [],
    totalIncome: 0,
    totalExpense: 0,
    totalBalance: 0,
    netWorth: 0,
    pendingSmsCount: 0,
    budgetEvaluationDate: evaluationDate,
    budgetGeneration: generation,
  );
}

BudgetConstraintSnapshot makeConstraint(
  BudgetPeriodSnapshot snapshot, {
  double? currentDailySpend,
  double? allowedDailySpend,
  double? remainingDailyAllowance,
  BudgetConstraintUrgency urgency = BudgetConstraintUrgency.withinLimit,
  BudgetState state = BudgetState.ok,
}) {
  final totalDays =
      snapshot.periodEnd.difference(snapshot.periodStart).inDays + 1;
  final daysPassed = snapshot.evaluationDate
      .difference(snapshot.periodStart)
      .inDays
      .clamp(0, totalDays);
  final daysLeft = snapshot.periodEnd
      .difference(snapshot.evaluationDate)
      .inDays
      .clamp(0, totalDays);
  return BudgetConstraintSnapshot(
    budgetId: snapshot.budgetId,
    budgetName: snapshot.budgetName,
    remaining: snapshot.remaining,
    spent: snapshot.spent,
    limit: snapshot.limit,
    currentDailySpend: currentDailySpend ?? 0,
    allowedDailySpend: allowedDailySpend ?? 0,
    remainingDailyAllowance: remainingDailyAllowance ?? 0,
    dailyGap: 0,
    daysUntilLimit: null,
    isForecastVisible: false,
    recoverySignal: null,
    daysLeft: daysLeft,
    daysPassed: daysPassed,
    totalDays: totalDays,
    budgetSnapshot: snapshot,
    periodStart: snapshot.periodStart,
    periodEnd: snapshot.periodEnd,
    urgency: urgency,
    state: state,
  );
}

class FixedBudgetRefreshNotifier extends BudgetRefreshNotifier {
  FixedBudgetRefreshNotifier({
    this.generation = 1,
    DateTime? evaluationDate,
  }) : evaluationDate = evaluationDate ?? DateTime(2024, 2, 15);

  final int generation;
  final DateTime evaluationDate;

  @override
  BudgetRefreshState build() => BudgetRefreshState(
        generation: generation,
        evaluationDate: evaluationDate,
        reason: BudgetRefreshReason.navigation,
      );

  @override
  void refresh(BudgetRefreshReason reason, {DateTime? evaluationDate}) {}
}

Widget localizedApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: child),
  );
}

List baseWidgetOverrides({
  required BudgetRefreshState refresh,
}) {
  return [
    spacingProvider.overrideWithValue(const AppSpacing()),
    budgetRefreshProvider.overrideWith(
      () => FixedBudgetRefreshNotifier(
        generation: refresh.generation,
        evaluationDate: refresh.evaluationDate,
      ),
    ),
  ];
}

Future<void> initializeWidgetTestPrefs() async {
  SharedPreferences.setMockInitialValues({});
  SharedPrefsUtil.init(await SharedPreferences.getInstance());
}

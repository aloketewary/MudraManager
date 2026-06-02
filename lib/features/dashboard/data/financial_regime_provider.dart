import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';

/// Observable structural properties of a user's financial data.
/// Determines which briefing signals are regime-admissible.
///
/// Regime is recomputed whenever dashboard data changes.
/// Binary admissibility: a signal is in the pool or it's not.
class FinancialRegime {
  final bool hasRegularIncome;
  final int spendingDepthMonths;
  final int activeAccountCount;
  final bool hasBudgets;
  final bool hasGoals;

  const FinancialRegime({
    required this.hasRegularIncome,
    required this.spendingDepthMonths,
    required this.activeAccountCount,
    required this.hasBudgets,
    required this.hasGoals,
  });
}

final financialRegimeProvider = Provider<FinancialRegime>((ref) {
  final data = ref.watch(dashboardDataProvider).value;
  if (data == null) {
    return const FinancialRegime(
      hasRegularIncome: false,
      spendingDepthMonths: 0,
      activeAccountCount: 0,
      hasBudgets: false,
      hasGoals: false,
    );
  }

  final txns = data.transactions;
  final now = DateTime.now();

  // ── Income regularity: CV of monthly income over last 6 months ──
  final monthlyIncome = <double>[];
  for (int i = 0; i < 6; i++) {
    final monthStart = DateTime(now.year, now.month - i, 1);
    final monthEnd = DateTime(now.year, now.month - i + 1, 0, 23, 59, 59);
    // Skip current month if less than half over
    if (i == 0 && now.day < 15) continue;
    final income = txns
        .where((t) =>
            !t.isExpense &&
            !t.isTransfer &&
            !t.date.isBefore(monthStart) &&
            !t.date.isAfter(monthEnd),)
        .fold<double>(0, (s, t) => s + t.baseAmount);
    if (income > 0) monthlyIncome.add(income);
  }

  final hasRegularIncome = monthlyIncome.length >= 3 &&
      _coefficientOfVariation(monthlyIncome) < 0.3;

  // ── Spending depth: months with ≥5 expense transactions ──
  int spendingDepthMonths = 0;
  for (int i = 0; i < 6; i++) {
    final monthStart = DateTime(now.year, now.month - i, 1);
    final monthEnd = DateTime(now.year, now.month - i + 1, 0, 23, 59, 59);
    final count = txns
        .where((t) =>
            t.isExpense &&
            !t.isTransfer &&
            !t.date.isBefore(monthStart) &&
            !t.date.isAfter(monthEnd),)
        .length;
    if (count >= 5) spendingDepthMonths++;
  }

  // ── Active accounts ──
  final activeAccountCount = data.accounts.length;

  // ── Budgets & goals ──
  final hasBudgets = data.budgets.isNotEmpty;
  final hasGoals = data.goals.where((g) => g.isActive).isNotEmpty;

  return FinancialRegime(
    hasRegularIncome: hasRegularIncome,
    spendingDepthMonths: spendingDepthMonths,
    activeAccountCount: activeAccountCount,
    hasBudgets: hasBudgets,
    hasGoals: hasGoals,
  );
});

double _coefficientOfVariation(List<double> values) {
  if (values.length < 2) return 1.0;
  final mean = values.reduce((a, b) => a + b) / values.length;
  if (mean == 0) return 1.0;
  final variance =
      values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
          values.length;
  return sqrt(variance) / mean;
}

import 'package:mudra_manager/core/domain/insight.dart';
import 'package:mudra_manager/core/engine/dashboard_engine.dart';

/// Facts extracted from EngineInput for generators to consume.
/// Generators receive this — never raw Isar models, never providers.
class Facts {
  // ── Budget facts ──
  final List<EngineBudget> budgets;
  final String? worstBudgetName;
  final double worstBudgetSpent;
  final double worstBudgetLimit;

  // ── Bill facts ──
  final List<EngineBill> bills;
  final bool recurringScanDone;

  // ── Cashflow facts ──
  final double totalIncome;
  final double totalExpense;

  // ── Comparison facts ──
  final Map<String, CategoryFact>? categoryComparison;
  final int dayOfMonth;
  final int daysInMonth;
  final int daysRemaining;

  // ── Time ──
  final DateTime now;

  const Facts({
    required this.budgets,
    this.worstBudgetName,
    this.worstBudgetSpent = 0,
    this.worstBudgetLimit = 0,
    required this.bills,
    required this.recurringScanDone,
    required this.totalIncome,
    required this.totalExpense,
    this.categoryComparison,
    required this.dayOfMonth,
    required this.daysInMonth,
    required this.daysRemaining,
    required this.now,
  });
}

/// Per-category comparison data for the insight generators.
class CategoryFact {
  final String name;
  final double currentMonthSpend;
  final double lastMonthTotal;

  /// Rolling 7-day pace in current month for this category.
  final double currentPace;

  /// Average daily spend from the comparison month.
  final double baselinePace;

  const CategoryFact({
    required this.name,
    required this.currentMonthSpend,
    required this.lastMonthTotal,
    required this.currentPace,
    required this.baselinePace,
  });
}

/// Contract for all insight generators.
/// Generators are pure functions over Facts. No persistence. No providers.
abstract class InsightGenerator {
  /// Unique identifier for diagnostics and source attribution.
  String get source;

  /// Emit zero, one, or many insights from the given facts.
  List<Insight> generate(Facts facts);
}

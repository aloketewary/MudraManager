import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';

class SpendingPersonality {
  final String topCategory;
  final String topCategoryEmoji;
  final String spendingPattern;
  final String behaviorType;
  final String spendingTrend;

  // Rich signals for personality detection
  final double savingsRate;
  final double budgetAdherence;
  final int activeGoals;
  final int txnCount;
  final double avgTxnAmount;
  final double weekendRatio;
  final int highActivityDays;
  final double essentialRatio;

  SpendingPersonality({
    required this.topCategory,
    required this.topCategoryEmoji,
    required this.spendingPattern,
    required this.behaviorType,
    required this.spendingTrend,
    this.savingsRate = 0,
    this.budgetAdherence = 0,
    this.activeGoals = 0,
    this.txnCount = 0,
    this.avgTxnAmount = 0,
    this.weekendRatio = 0,
    this.highActivityDays = 0,
    this.essentialRatio = 0,
  });
}

class SpendingAnalyzer {
  static Future<Isar> _getIsar() async {
    final existing = Isar.getInstance();
    if (existing != null && existing.isOpen) return existing;
    return await IsarService.initIsar();
  }

  static Future<SpendingPersonality?> analyzePersonality() async {
    final isar = await _getIsar();
    final now = DateTime.now();
    final last30Days = now.subtract(const Duration(days: 30));

    final expenses = await isar.transactions
        .filter()
        .isExpenseEqualTo(true)
        .isSettlementEqualTo(false)
        .and()
        .dateBetween(last30Days, now)
        .findAll();

    if (expenses.length < 5) return null;

    for (final tx in expenses) {
      await tx.category.load();
    }

    // ── Top category ──
    final categorySpending = <String, double>{};
    for (final tx in expenses) {
      final cat = tx.category.value?.name ?? 'Other';
      categorySpending[cat] = (categorySpending[cat] ?? 0) + tx.effectiveAmount;
    }
    final topCat =
        categorySpending.entries.reduce((a, b) => a.value > b.value ? a : b);

    // ── Essential vs discretionary ratio ──
    final essentialKeywords = [
      'grocery',
      'groceries',
      'rent',
      'utility',
      'utilities',
      'bill',
      'insurance',
      'medical',
      'health',
      'fuel',
      'gas',
      'electricity',
      'water',
      'emi',
      'loan',
    ];
    double essentialAmount = 0;
    double totalExpense = 0;
    for (final tx in expenses) {
      totalExpense += tx.effectiveAmount;
      final catName = (tx.category.value?.name ?? '').toLowerCase();
      if (essentialKeywords.any((k) => catName.contains(k))) {
        essentialAmount += tx.effectiveAmount;
      }
    }
    final essentialRatio =
        totalExpense > 0 ? essentialAmount / totalExpense : 0.0;

    // ── Weekend vs weekday ──
    double weekendAmount = 0;
    for (final tx in expenses) {
      if (tx.date.weekday >= 6) weekendAmount += tx.effectiveAmount;
    }
    final weekendRatio = totalExpense > 0 ? weekendAmount / totalExpense : 0.0;

    // ── Impulse detection ──
    final dailyTxCount = <String, int>{};
    for (final tx in expenses) {
      final key = '${tx.date.year}-${tx.date.month}-${tx.date.day}';
      dailyTxCount[key] = (dailyTxCount[key] ?? 0) + 1;
    }
    final highActivityDays = dailyTxCount.values.where((c) => c > 3).length;
    final isImpulse = highActivityDays >= 2;

    // ── Spending trend ──
    final midPoint = last30Days.add(const Duration(days: 15));
    double firstHalf = 0, secondHalf = 0;
    for (final tx in expenses) {
      if (tx.date.isBefore(midPoint)) {
        firstHalf += tx.effectiveAmount;
      } else {
        secondHalf += tx.effectiveAmount;
      }
    }
    final trendDiff = firstHalf > 0
        ? ((secondHalf - firstHalf) / firstHalf * 100).abs()
        : 0.0;
    final trend = trendDiff < 10
        ? 'Steady spender'
        : secondHalf > firstHalf
            ? 'Spending increasing'
            : 'Spending decreasing';

    // ── Savings rate ──
    final income = await isar.transactions
        .filter()
        .isExpenseEqualTo(false)
        .isTransferEqualTo(false)
        .isSettlementEqualTo(false)
        .dateBetween(last30Days, now)
        .findAll();
    double totalIncome = 0;
    for (final tx in income) {
      totalIncome += tx.effectiveAmount;
    }
    final savingsRate = totalIncome > 0
        ? ((totalIncome - totalExpense) / totalIncome * 100).clamp(0.0, 100.0)
        : 0.0;

    // ── Budget adherence ──
    final budgets = await isar.budgets.where().findAll();
    double adherence = 0;
    if (budgets.isNotEmpty) {
      int withinBudget = 0;
      for (final b in budgets) {
        // Simple check: if budget exists and is active, count it
        if (b.amount > 0) withinBudget++;
      }
      adherence = withinBudget / budgets.length * 100;
    }

    // ── Goal activity ──
    final goals = await isar.goals.filter().isActiveEqualTo(true).findAll();

    return SpendingPersonality(
      topCategory: topCat.key,
      topCategoryEmoji: _getCategoryEmoji(topCat.key),
      spendingPattern:
          weekendRatio > 0.4 ? 'Weekend spender' : 'Weekday spender',
      behaviorType: isImpulse ? 'Impulse buyer' : 'Planned spender',
      spendingTrend: trend,
      savingsRate: savingsRate,
      budgetAdherence: adherence,
      activeGoals: goals.length,
      txnCount: expenses.length,
      avgTxnAmount: expenses.isNotEmpty ? totalExpense / expenses.length : 0,
      weekendRatio: weekendRatio,
      highActivityDays: highActivityDays,
      essentialRatio: essentialRatio,
    );
  }

  static String _getCategoryEmoji(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('food') || lower.contains('dining')) return 'utensils';
    if (lower.contains('transport') || lower.contains('travel')) return 'car';
    if (lower.contains('shop') || lower.contains('clothing')) {
      return 'shopping-bag';
    }
    if (lower.contains('entertainment') || lower.contains('movie')) {
      return 'film';
    }
    if (lower.contains('health') || lower.contains('medical')) {
      return 'heart-pulse';
    }
    if (lower.contains('education')) return 'book-open';
    if (lower.contains('utilities') || lower.contains('bill')) return 'zap';
    if (lower.contains('groceries')) return 'shopping-cart';
    return 'wallet';
  }
}

import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';

class SpendingPersonality {
  final String topCategory;
  final String topCategoryEmoji;
  final String spendingPattern;
  final String behaviorType;
  final String spendingTrend;

  SpendingPersonality({
    required this.topCategory,
    required this.topCategoryEmoji,
    required this.spendingPattern,
    required this.behaviorType,
    required this.spendingTrend,
  });
}

class SpendingAnalyzer {
  static Future<Isar> _getIsar() async {
    if (Isar.instanceNames.isEmpty) {
      throw Exception('Isar not initialized');
    }
    return Isar.getInstance()!;
  }

  static Future<SpendingPersonality?> analyzePersonality() async {
    final isar = await _getIsar();
    final now = DateTime.now();
    final last30Days = now.subtract(const Duration(days: 30));

    final transactions = await isar.transactions
        .filter()
        .isExpenseEqualTo(true)
        .and()
        .dateBetween(last30Days, now)
        .findAll();

    if (transactions.length < 5) return null;

    // Load categories
    for (final tx in transactions) {
      await tx.category.load();
    }

    // Top category
    final categorySpending = <String, double>{};
    for (final tx in transactions) {
      final cat = tx.category.value?.name ?? 'Other';
      categorySpending[cat] = (categorySpending[cat] ?? 0) + tx.amount;
    }
    final topCat = categorySpending.entries.reduce((a, b) => a.value > b.value ? a : b);

    // Weekend vs weekday (by amount spent)
    double weekendAmount = 0;
    double totalAmount = 0;
    for (final tx in transactions) {
      totalAmount += tx.amount;
      if (tx.date.weekday >= 6) weekendAmount += tx.amount;
    }
    final isWeekendSpender = weekendAmount > totalAmount * 0.5;

    // Impulse detection: >3 transactions on same day at least twice
    final dailyTxCount = <String, int>{};
    for (final tx in transactions) {
      final key = '${tx.date.year}-${tx.date.month}-${tx.date.day}';
      dailyTxCount[key] = (dailyTxCount[key] ?? 0) + 1;
    }
    final highActivityDays = dailyTxCount.values.where((count) => count > 3).length;
    final isImpulseBuyer = highActivityDays >= 2;

    // Spending trend: compare first 15 days vs last 15 days
    final midPoint = last30Days.add(const Duration(days: 15));
    double firstHalfAmount = 0;
    double secondHalfAmount = 0;
    for (final tx in transactions) {
      if (tx.date.isBefore(midPoint)) {
        firstHalfAmount += tx.amount;
      } else {
        secondHalfAmount += tx.amount;
      }
    }
    final trendDiff = ((secondHalfAmount - firstHalfAmount) / firstHalfAmount * 100).abs();
    String trend;
    if (trendDiff < 10) {
      trend = 'Steady spender';
    } else if (secondHalfAmount > firstHalfAmount) {
      trend = 'Spending increasing';
    } else {
      trend = 'Spending decreasing';
    }

    return SpendingPersonality(
      topCategory: topCat.key,
      topCategoryEmoji: _getCategoryEmoji(topCat.key),
      spendingPattern: isWeekendSpender ? 'Weekend spender' : 'Weekday spender',
      behaviorType: isImpulseBuyer ? 'Impulse buyer' : 'Planned spender',
      spendingTrend: trend,
    );
  }

  static String _getCategoryEmoji(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('food') || lower.contains('dining')) return 'utensils';
    if (lower.contains('transport') || lower.contains('travel')) return 'car';
    if (lower.contains('shop') || lower.contains('clothing')) return 'shopping-bag';
    if (lower.contains('entertainment') || lower.contains('movie')) return 'film';
    if (lower.contains('health') || lower.contains('medical')) return 'heart-pulse';
    if (lower.contains('education')) return 'book-open';
    if (lower.contains('utilities') || lower.contains('bill')) return 'zap';
    if (lower.contains('groceries')) return 'shopping-cart';
    return 'wallet';
  }
}

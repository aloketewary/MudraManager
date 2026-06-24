/// Classifies goal state and computes pace/gap/attention.
/// Pure functions. No side effects. No dependencies.
/// Testable with plain unit tests.
abstract final class GoalStateMachine {
  /// Recent pace: contributions in last 90 days / 3 months.
  /// Fallback to lifetime average if < 90 days of history.
  static double recentPace(
    List<GoalContributionData> contributions,
    DateTime now,
  ) {
    if (contributions.isEmpty) return 0;

    final cutoff = now.subtract(const Duration(days: 90));
    final recent = contributions.where((c) => c.date.isAfter(cutoff)).toList();

    if (recent.isNotEmpty) {
      return recent.fold(0.0, (sum, c) => sum + c.amount) / 3;
    }

    // Fallback: lifetime average
    final total = contributions.fold(0.0, (sum, c) => sum + c.amount);
    final first =
        contributions.reduce((a, b) => a.date.isBefore(b.date) ? a : b).date;
    final months = now.difference(first).inDays / 30;
    if (months < 1) return total;
    return total / months;
  }

  /// Needed per month to reach target by deadline.
  /// Returns 0 if no deadline. Returns full remaining if past deadline.
  static double neededPerMonth(
    double remaining,
    DateTime? targetDate,
    DateTime now,
  ) {
    if (targetDate == null) return 0;
    final daysLeft = targetDate.difference(now).inDays;
    if (daysLeft <= 0) return remaining;
    final monthsLeft = daysLeft / 30;
    return remaining / monthsLeft;
  }

  /// Gap = recentPace - neededPerMonth.
  /// Positive = ahead of pace, negative = behind pace.
  static double paceGap(double pace, double needed) {
    if (needed <= 0) return 0;
    return pace - needed;
  }

  /// Whether goal needs attention (raw failure conditions).
  /// No interpretation — just arithmetic thresholds.
  static bool needsAttention({
    required double progressPercent,
    required double gap,
    required int daysRemaining,
    required DateTime? predictedDate,
    required DateTime? targetDate,
  }) {
    if (progressPercent >= 1.0) return false;
    if (gap < 0) return true;
    if (daysRemaining > 0 && daysRemaining < 90) return true;
    if (predictedDate != null &&
        targetDate != null &&
        predictedDate.isAfter(targetDate)) {
      return true;
    }
    return false;
  }

  /// Priority sort score (lower = higher priority).
  /// Behind → Near deadline (<90d) → On track → No deadline → Completed.
  static int sortPriority({
    required double progressPercent,
    required double gap,
    required int daysRemaining,
    required bool hasDeadline,
  }) {
    if (progressPercent >= 1.0) return 100;
    if (gap < 0) return 0;
    if (daysRemaining > 0 && daysRemaining < 90) return 1;
    if (hasDeadline) return 2;
    return 3;
  }

  /// Suggested deposit: last contribution amount, or neededPerMonth rounded
  /// up to nearest 500.
  static double suggestedDeposit(
    List<GoalContributionData> contributions,
    double neededPerMonth,
  ) {
    if (contributions.isNotEmpty) {
      final sorted = contributions.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return sorted.first.amount;
    }
    if (neededPerMonth > 0) return (neededPerMonth / 500).ceil() * 500;
    return 1000;
  }

  /// Predicted completion date. Returns null if insufficient data.
  /// Gate: minimum 3 contributions AND 30+ days elapsed.
  static DateTime? predictedCompletion({
    required double progressPercent,
    required DateTime creationDate,
    required DateTime now,
    required int contributionCount,
  }) {
    final elapsed = now.difference(creationDate).inDays;
    if (progressPercent <= 0 || elapsed <= 0) return null;
    if (contributionCount < 3 || elapsed < 30) return null;

    final daysForFull = (elapsed / progressPercent).ceil();
    return creationDate.add(Duration(days: daysForFull));
  }

  /// Days remaining until target date. Returns 0 if past or no deadline.
  static int daysRemaining(DateTime? targetDate, DateTime now) {
    if (targetDate == null) return 0;
    final days = targetDate.difference(now).inDays;
    return days > 0 ? days : 0;
  }
}

/// Minimal data for pace computation (decoupled from Isar model).
class GoalContributionData {
  final double amount;
  final DateTime date;

  const GoalContributionData({required this.amount, required this.date});
}

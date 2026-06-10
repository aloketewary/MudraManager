import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';

enum GoalStatus { onTrack, behind, ahead, completed, noDeadline }

class GoalHealth {
  final GoalStatus status;
  final int daysLeft;
  final int daysAheadOrBehind;
  final double dailyNeeded;
  final double monthlyNeeded;
  final DateTime? predictedDate;

  const GoalHealth({
    required this.status,
    required this.daysLeft,
    this.daysAheadOrBehind = 0,
    this.dailyNeeded = 0,
    this.monthlyNeeded = 0,
    this.predictedDate,
  });

  static GoalHealth compute(Goal goal) {
    if (goal.progressPercent >= 1.0) {
      return const GoalHealth(status: GoalStatus.completed, daysLeft: 0);
    }

    if (goal.targetDate == null) {
      return const GoalHealth(status: GoalStatus.noDeadline, daysLeft: 0);
    }

    final now = DateTime.now();
    final daysLeft = goal.targetDate!.difference(now).inDays;
    final remaining = goal.remainingAmount;

    if (daysLeft <= 0) {
      return GoalHealth(
        status: GoalStatus.behind,
        daysLeft: 0,
        dailyNeeded: remaining,
        monthlyNeeded: remaining,
      );
    }

    final dailyNeeded = remaining / daysLeft;
    final monthlyNeeded =
        remaining / (daysLeft / 30).clamp(0.1, double.infinity);

    // Calculate expected progress based on elapsed time
    final totalDays = goal.targetDate!.difference(goal.creationDate).inDays;
    final elapsed = now.difference(goal.creationDate).inDays;
    final expectedProgress = totalDays > 0 ? elapsed / totalDays : 0.0;
    final actualProgress = goal.progressPercent;

    // Predict completion date based on current pace
    DateTime? predictedDate;
    if (actualProgress > 0 && elapsed > 0) {
      final daysForFull = (elapsed / actualProgress).ceil();
      predictedDate = goal.creationDate.add(Duration(days: daysForFull));
    }

    GoalStatus status;
    int daysAheadOrBehind = 0;

    if (actualProgress >= expectedProgress) {
      // Ahead or on track
      final diff = actualProgress - expectedProgress;
      daysAheadOrBehind = (diff * totalDays).round();
      status = daysAheadOrBehind > 2 ? GoalStatus.ahead : GoalStatus.onTrack;
    } else {
      final diff = expectedProgress - actualProgress;
      daysAheadOrBehind = (diff * totalDays).round();
      status = daysAheadOrBehind > 2 ? GoalStatus.behind : GoalStatus.onTrack;
    }

    return GoalHealth(
      status: status,
      daysLeft: daysLeft,
      daysAheadOrBehind: daysAheadOrBehind,
      dailyNeeded: dailyNeeded,
      monthlyNeeded: monthlyNeeded,
      predictedDate: predictedDate,
    );
  }

  Color statusColor(ColorScheme color) {
    switch (status) {
      case GoalStatus.completed:
      case GoalStatus.ahead:
        return FinanceColors.statusGood;
      case GoalStatus.onTrack:
      case GoalStatus.noDeadline:
        return color.primary;
      case GoalStatus.behind:
        return FinanceColors.statusWarning;
    }
  }

  String insightMessage(Goal goal) {
    final tone = Tone.current;
    final name = goal.name;
    final code = goal.currencyCode;

    if (status == GoalStatus.completed) {
      return tone.goalMilestone100(name);
    }

    // Milestone messages
    final pct = goal.progressPercent;
    if (pct >= 0.75) return tone.goalMilestone75(name);
    if (pct >= 0.50) return tone.goalMilestone50(name);
    if (pct >= 0.25) return tone.goalMilestone25(name);

    if (status == GoalStatus.noDeadline) {
      return tone.goalNoDeadline(name);
    }
    if (status == GoalStatus.ahead) {
      return tone.goalAhead(name, '$daysAheadOrBehind');
    }
    if (status == GoalStatus.behind) {
      return tone.goalBehind(name);
    }

    // On track — show daily needed
    if (dailyNeeded > 0) {
      return tone.goalDailyNeeded(
        formatCurrency(dailyNeeded, code: code, decimals: 0),
      );
    }
    return tone.goalOnTrack(name);
  }

  String? secondaryInsight(Goal goal) {
    final tone = Tone.current;
    final code = goal.currencyCode;

    if (status == GoalStatus.completed || status == GoalStatus.noDeadline) {
      return null;
    }
    if (predictedDate != null) {
      return tone.goalPredictedDate(predictedDateFormatted);
    }
    if (dailyNeeded > 0) {
      return tone.goalDailyNeeded(
        formatCurrency(dailyNeeded, code: code, decimals: 0),
      );
    }
    return null;
  }

  /// Average monthly contribution from actual deposit history.
  static double avgMonthlyContribution(Goal goal) {
    final contributions = goal.contributions;
    if (contributions.isEmpty) return 0;
    final total = contributions.fold(0.0, (sum, c) => sum + c.amount);
    final first =
        contributions.reduce((a, b) => a.date.isBefore(b.date) ? a : b).date;
    final months = DateTime.now().difference(first).inDays / 30;
    if (months < 1) return total;
    return total / months;
  }

  /// Contribution this month from the goal's history.
  static double contributionThisMonth(Goal goal) {
    final now = DateTime.now();
    return goal.contributions
        .where((c) => c.date.year == now.year && c.date.month == now.month)
        .fold(0.0, (sum, c) => sum + c.amount);
  }

  String get predictedDateFormatted => predictedDate != null
      ? DateFormat('dd MMM yyyy').format(predictedDate!)
      : '';

  String get milestoneMessage {
    return ''; // Handled by tone system
  }
}

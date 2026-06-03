import 'package:mudra_manager/core/domain/financial_states.dart';
import 'package:mudra_manager/core/domain/metrics.dart';

/// Classifies bill state from due date and scan status.
/// Pure function. No side effects. No dependencies.
abstract final class BillStateMachine {
  static BillState classify(
    DateTime dueDate,
    DateTime today, {
    required bool scanDone,
  }) {
    if (!scanDone) return BillState.unknown;
    final days = Metrics.daysUntilDue(dueDate, today);
    if (days < 0) return BillState.overdue;
    if (days == 0) return BillState.dueToday;
    if (days <= 2) return BillState.dueSoon;
    if (days <= 7) return BillState.upcoming;
    return BillState.clear;
  }
}

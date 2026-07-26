import 'package:equatable/equatable.dart';

export 'package:mudra_manager/core/db/models/debt.dart' show Debt, DebtSortOrder;

// ─── Snowball Result ────────────────────────────────────────────────────────

/// Result of snowball strategy calculation.
class SnowballResult extends Equatable {
  final double totalDebt;
  final double totalInterest;
  final int monthsToDebtFree;
  final double monthlyExtraNeeded;
  final List<DebtPaymentSchedule> paymentSchedule;

  const SnowballResult({
    required this.totalDebt,
    required this.totalInterest,
    required this.monthsToDebtFree,
    required this.monthlyExtraNeeded,
    required this.paymentSchedule,
  });

  @override
  List<Object?> get props =>
      [totalDebt, totalInterest, monthsToDebtFree, monthlyExtraNeeded, paymentSchedule];
}

/// Payment schedule for a single debt in the snowball order.
class DebtPaymentSchedule extends Equatable {
  final int debtId;
  final String debtName;
  final int order;
  final int startMonth;
  final int? endMonth; // null if still being paid
  final double monthlyPayment;

  const DebtPaymentSchedule({
    required this.debtId,
    required this.debtName,
    required this.order,
    required this.startMonth,
    this.endMonth,
    required this.monthlyPayment,
  });

  @override
  List<Object?> get props => [debtId, debtName, order, startMonth, endMonth, monthlyPayment];
}

// ─── Enums ───────────────────────────────────────────────────────────────────

enum DebtStatus {
  active,
  paidOff,
  paused,
}

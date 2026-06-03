import 'package:mudra_manager/core/domain/financial_states.dart';
import 'package:mudra_manager/core/logic/briefing_selector.dart';
import 'package:mudra_manager/core/logic/cashflow_engine.dart';

/// The single truth snapshot that the dashboard UI reads.
/// Produced ONLY by DashboardEngine. Never constructed in UI code.
class DashboardState {
  final DataValidityLevel gate;

  final double balance;
  final CashflowSnapshot cashflow;

  final BudgetState budgetState;
  final double budgetSpent;
  final double budgetLimit;
  final String? budgetName;

  final BillState billState;
  final int billCount;
  final DateTime? nearestBillDate;
  final String? nearestBillName;
  final double? nearestBillAmount;

  final int convergenceCount;

  final StateTransition budgetTransition;
  final StateTransition billTransition;
  final StateTransition cashflowTransition;

  final BriefingSelection? briefing;

  const DashboardState({
    required this.gate,
    required this.balance,
    required this.cashflow,
    required this.budgetState,
    required this.budgetSpent,
    required this.budgetLimit,
    this.budgetName,
    required this.billState,
    required this.billCount,
    this.nearestBillDate,
    this.nearestBillName,
    this.nearestBillAmount,
    required this.convergenceCount,
    required this.budgetTransition,
    required this.billTransition,
    required this.cashflowTransition,
    this.briefing,
  });

  bool get isStable =>
      budgetTransition == StateTransition.stable &&
      billTransition == StateTransition.stable &&
      cashflowTransition == StateTransition.stable;
}

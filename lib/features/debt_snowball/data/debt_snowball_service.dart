import 'dart:math' as math;

import 'package:mudra_manager/features/debt_snowball/domain/debt_models.dart';

// ─── Service ────────────────────────────────────────────────────────────────

/// Calculates debt snowball or avalanche payoff schedules.
///
/// Pure calculator — takes a snapshot of debts, does not read/write Isar.
/// Persistence lives in [DebtService] (see debt_provider.dart).
class DebtSnowballService {
  const DebtSnowballService();

  /// Calculate payoff schedule using given strategy.
  SnowballResult calculatePayoff({
    required List<Debt> debts,
    required DebtSortOrder order,
  }) {
    final activeDebts = debts.where((d) => d.balance > 0).toList();
    if (activeDebts.isEmpty) {
      return const SnowballResult(
        totalDebt: 0,
        totalInterest: 0,
        monthsToDebtFree: 0,
        monthlyExtraNeeded: 0,
        paymentSchedule: [],
      );
    }

    // Sort debts based on strategy (order determines snowball priority).
    final sorted = _sortDebts(activeDebts, order);

    final totalDebt = sorted.fold<double>(0, (sum, d) => sum + d.balance);

    // Mutable working copy of balances, keyed by list index (sorted order
    // is stable for the life of this calculation).
    final balances = sorted.map((d) => d.balance).toList();
    final startMonth = List<int>.filled(sorted.length, 1);
    final endMonth = List<int?>.filled(sorted.length, null);

    double totalInterest = 0;
    int month = 0;

    while (balances.any((b) => b > 0) && month < 360) {
      month++;

      // Extra payment rolls to the highest-priority (first) debt still
      // outstanding — the "snowball" — plus any explicit extraPayment set
      // on individual debts.
      double rollingExtra = 0;

      for (int i = 0; i < sorted.length; i++) {
        if (balances[i] <= 0) continue;
        final debt = sorted[i];

        final interest = balances[i] * (debt.interestRate / 100 / 12);
        totalInterest += interest;
        balances[i] += interest;

        rollingExtra += debt.extraPayment ?? 0;
      }

      for (int i = 0; i < sorted.length; i++) {
        if (balances[i] <= 0) continue;
        final debt = sorted[i];

        var payment = debt.minimumPayment;
        if (rollingExtra > 0) {
          final applied = math.min(rollingExtra, balances[i]);
          payment += applied;
          rollingExtra -= applied;
        }

        balances[i] = math.max(0, balances[i] - payment);

        if (balances[i] <= 0 && endMonth[i] == null) {
          endMonth[i] = month;
        }
      }
    }

    final paymentSchedule = <DebtPaymentSchedule>[
      for (int i = 0; i < sorted.length; i++)
        DebtPaymentSchedule(
          debtId: sorted[i].id,
          debtName: sorted[i].name,
          order: i,
          startMonth: startMonth[i],
          endMonth: endMonth[i],
          monthlyPayment: sorted[i].totalPayment,
        ),
    ];

    return SnowballResult(
      totalDebt: totalDebt,
      totalInterest: totalInterest,
      monthsToDebtFree: month,
      monthlyExtraNeeded: 0,
      paymentSchedule: paymentSchedule,
    );
  }

  /// Sort debts based on strategy.
  List<Debt> _sortDebts(List<Debt> debts, DebtSortOrder order) {
    return [...debts]..sort((a, b) {
        switch (order) {
          case DebtSortOrder.balanceAscending:
            if (a.balance != b.balance) return a.balance.compareTo(b.balance);
            return b.interestRate.compareTo(a.interestRate);
          case DebtSortOrder.balanceDescending:
            if (b.interestRate != a.interestRate) {
              return b.interestRate.compareTo(a.interestRate);
            }
            return a.balance.compareTo(b.balance);
        }
      });
  }
}

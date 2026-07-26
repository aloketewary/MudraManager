import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/collection_watchers.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';

class CreditCardSummary {
  final Account account;
  final double outstanding;
  final int? daysUntilDue;
  final double? utilization;
  final double minimumDue;
  final double availableCredit;
  final double billingCycleSpend;
  final DateTime? nextStatementDate;
  final DateTime? nextDueDate;

  /// True when this cycle's due date has already passed and there's still
  /// an unpaid outstanding balance. [daysUntilDue]/[nextDueDate] always
  /// point at the *next upcoming* occurrence (for the info chip), so they
  /// can't be used to detect overdue on their own.
  final bool isOverdue;

  const CreditCardSummary({
    required this.account,
    required this.outstanding,
    this.daysUntilDue,
    this.utilization,
    this.minimumDue = 0,
    this.availableCredit = 0,
    this.billingCycleSpend = 0,
    this.nextStatementDate,
    this.nextDueDate,
    this.isOverdue = false,
  });
}

class CreditCardBillsSummary {
  final double totalOutstanding;
  final double totalMinimumDue;
  final double totalAvailableCredit;
  final int overdueCount;
  final int dueSoonCount;
  final int highUtilizationCount;
  final int cardCount;

  const CreditCardBillsSummary({
    required this.totalOutstanding,
    required this.totalMinimumDue,
    required this.totalAvailableCredit,
    required this.overdueCount,
    required this.dueSoonCount,
    required this.highUtilizationCount,
    required this.cardCount,
  });
}

class CreditCardBillsData {
  final CreditCardBillsSummary summary;
  final List<CreditCardSummary> cards;

  const CreditCardBillsData({
    required this.summary,
    required this.cards,
  });
}

/// Returns [dayOfMonth] within [year]/[month], clamped to the last valid
/// day of that month (e.g. day 31 in February clamps to 28/29).
DateTime _dateInMonth(int year, int month, int dayOfMonth) {
  // Normalize month overflow/underflow (month can be 0 or 13+ from callers,
  // e.g. "previous month from January" passes month=0). Dart's `~/`
  // truncates toward zero rather than flooring, so for negative
  // `month - 1` (month <= 0) it computed the wrong *year* — e.g.
  // (0 - 1) ~/ 12 == 0 instead of -1, leaving `normalizedYear` unchanged
  // and rolling to December of the *same* year instead of the previous
  // one. Use floor division to handle this correctly.
  final delta = month - 1;
  final normalizedYear = year + (delta - (delta % 12)) ~/ 12;
  final normalizedMonth = ((delta % 12) + 12) % 12 + 1;
  final daysInMonth = DateTime(normalizedYear, normalizedMonth + 1, 0).day;
  final safeDay = dayOfMonth > daysInMonth ? daysInMonth : dayOfMonth;
  return DateTime(normalizedYear, normalizedMonth, safeDay);
}

/// Next occurrence of [dayOfMonth] strictly after today, clamping to the
/// last day of the month when the month is shorter (e.g. 31st in April).
DateTime _nextOccurrence(int dayOfMonth) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  var date = _dateInMonth(now.year, now.month, dayOfMonth);
  if (!date.isAfter(today)) {
    date = _dateInMonth(now.year, now.month + 1, dayOfMonth);
  }
  return date;
}

final creditCardBillsProvider =
    FutureProvider.autoDispose<CreditCardBillsData>((ref) async {
  ref.watch(transactionChangeProvider);
  ref.watch(accountChangeProvider);

  final accountService = ref.watch(accountServiceProvider);
  final accounts = await ref.watch(allAccountsProvider.future);
  final isar = await ref.watch(isarServiceProvider).getInstance();

  final cards = accounts
      .where((a) => a.accountType == AccountType.creditCard && a.isActive)
      .toList();

  final summaries = <CreditCardSummary>[];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  for (final card in cards) {
    final balance = await accountService.getAccountBalance(card.id);
    final outstanding = balance < 0 ? balance.abs() : 0.0;

    // Due date: check *this* cycle's due date first. If it has already
    // passed and there's still an outstanding balance, the card is overdue
    // (daysUntilDue goes negative, matching the "Overdue by N days" copy).
    // If it passed with nothing owed, roll forward to next month's due date
    // instead — `_nextOccurrence` alone always returns a future date, which
    // made overdue detection unreachable dead code.
    int? daysUntilDue;
    DateTime? nextDueDate;
    var isOverdue = false;
    if (card.dueDay != null) {
      final dueThisCycle = _dateInMonth(now.year, now.month, card.dueDay!);
      if (!dueThisCycle.isAfter(today)) {
        if (outstanding > 0) {
          isOverdue = true;
          nextDueDate = dueThisCycle;
        } else {
          nextDueDate = _dateInMonth(now.year, now.month + 1, card.dueDay!);
        }
      } else {
        nextDueDate = dueThisCycle;
      }
      daysUntilDue = nextDueDate.difference(today).inDays;
    }

    DateTime? nextStatementDate;
    if (card.statementDay != null) {
      nextStatementDate = _nextOccurrence(card.statementDay!);
    }

    // Utilization = outstanding / creditLimit
    final utilization = card.creditLimit != null && card.creditLimit! > 0
        ? (outstanding / card.creditLimit!) * 100
        : null;

    // Available credit
    final availableCredit = card.creditLimit != null && card.creditLimit! > 0
        ? (card.creditLimit! - outstanding).clamp(0.0, card.creditLimit!)
        : 0.0;

    // Minimum due: ~5% of outstanding or ₹200, whichever is higher (Indian CC
    // norm), but never more than the outstanding balance itself. Computed as
    // max(5%, 200) then capped at outstanding — avoids the `clamp(200,
    // outstanding)` crash when outstanding < 200 (lowerLimit > upperLimit).
    final minimumDue = outstanding > 0
        ? math.min(math.max(outstanding * 0.05, 200.0), outstanding)
        : 0.0;

    // Billing cycle spend: expenses since last statement date, excluding
    // transfers/settlements (mirrors Transaction.affectsStats) and using
    // effectiveAmount so split/shared expenses and multi-currency
    // conversions are represented correctly.
    double billingCycleSpend = 0;
    if (card.statementDay != null) {
      var cycleStart = _dateInMonth(now.year, now.month, card.statementDay!);
      if (cycleStart.isAfter(today)) {
        cycleStart =
            _dateInMonth(now.year, now.month - 1, card.statementDay!);
      }
      final cycleTxns = await isar.transactions
          .filter()
          .account((q) => q.idEqualTo(card.id))
          .isExpenseEqualTo(true)
          .isTransferEqualTo(false)
          .isSettlementEqualTo(false)
          .dateGreaterThan(cycleStart)
          .findAll();
      billingCycleSpend =
          cycleTxns.fold<double>(0.0, (sum, t) => sum + t.effectiveAmount);
    }

    summaries.add(
      CreditCardSummary(
        account: card,
        outstanding: outstanding,
        daysUntilDue: daysUntilDue,
        utilization: utilization,
        minimumDue: minimumDue,
        availableCredit: availableCredit,
        billingCycleSpend: billingCycleSpend,
        nextStatementDate: nextStatementDate,
        nextDueDate: nextDueDate,
        isOverdue: isOverdue,
      ),
    );
  }

  // Sort: overdue first, then nearest due date
  summaries
      .sort((a, b) => (a.daysUntilDue ?? 999).compareTo(b.daysUntilDue ?? 999));

  // Compute aggregate summary
  final summary = CreditCardBillsSummary(
    totalOutstanding: summaries.fold(0, (s, c) => s + c.outstanding),
    totalMinimumDue: summaries.fold(0, (s, c) => s + c.minimumDue),
    totalAvailableCredit: summaries.fold(0, (s, c) => s + c.availableCredit),
    overdueCount: summaries.where((c) => c.isOverdue).length,
    // Bug: `(c.daysUntilDue ?? 999) > 0 && c.daysUntilDue! <= 3` crashes
    // with a null-check error for cards with no due date set — the first
    // clause coalesces to 999 (true), so `&&` doesn't short-circuit and
    // force-unwraps the real (null) value in the second clause. Read the
    // field into a local first so both checks agree on the same value.
    dueSoonCount: summaries.where((c) {
      final days = c.daysUntilDue;
      return days != null && days > 0 && days <= 3;
    }).length,
    highUtilizationCount:
        summaries.where((c) => (c.utilization ?? 0) > 80).length,
    cardCount: summaries.length,
  );

  return CreditCardBillsData(summary: summary, cards: summaries);
});

/// Backward-compatible provider for existing consumers
final creditCardSummariesProvider =
    FutureProvider.autoDispose<List<CreditCardSummary>>((ref) async {
  final data = await ref.watch(creditCardBillsProvider.future);
  return data.cards;
});

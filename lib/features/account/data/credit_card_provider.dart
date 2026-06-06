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

DateTime _nextOccurrence(int dayOfMonth) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  var date = DateTime(now.year, now.month, dayOfMonth);
  if (date.month != now.month) {
    date = DateTime(now.year, now.month + 1, 0); // clamp
  }
  if (!date.isAfter(today)) {
    date = DateTime(now.year, now.month + 1, dayOfMonth);
    if (date.month != now.month + 1 && date.month != 1) {
      date = DateTime(now.year, now.month + 2, 0);
    }
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

    int? daysUntilDue;
    DateTime? nextDueDate;
    if (card.dueDay != null) {
      nextDueDate = _nextOccurrence(card.dueDay!);
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

    // Minimum due: ~5% of outstanding or ₹200, whichever is higher (Indian CC norm)
    final minimumDue =
        outstanding > 0 ? (outstanding * 0.05).clamp(200.0, outstanding) : 0.0;

    // Billing cycle spend: expenses since last statement date
    double billingCycleSpend = 0;
    if (card.statementDay != null) {
      var cycleStart = DateTime(now.year, now.month, card.statementDay!);
      if (cycleStart.isAfter(today)) {
        cycleStart = DateTime(now.year, now.month - 1, card.statementDay!);
      }
      billingCycleSpend = await isar.transactions
          .filter()
          .account((q) => q.idEqualTo(card.id))
          .isExpenseEqualTo(true)
          .dateGreaterThan(cycleStart)
          .amountProperty()
          .sum();
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
    overdueCount: summaries.where((c) => (c.daysUntilDue ?? 999) < 0).length,
    dueSoonCount: summaries
        .where((c) => (c.daysUntilDue ?? 999) > 0 && c.daysUntilDue! <= 3)
        .length,
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

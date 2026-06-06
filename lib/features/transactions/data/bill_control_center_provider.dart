import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/frequency.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/transactions/data/recurring_transaction_provider.dart';

// ─── Affordability ────────────────────────────────────────────────────────────

enum AffordabilityState { safe, low, negative }

class BillAffordabilitySummary {
  final double totalBalance;
  final double upcomingTotal;
  final double remainingBalance;
  final AffordabilityState state;

  // Future: sequential depletion
  final int fundedCount;
  final int unfundedCount;

  const BillAffordabilitySummary({
    required this.totalBalance,
    required this.upcomingTotal,
    required this.remainingBalance,
    required this.state,
    this.fundedCount = 0,
    this.unfundedCount = 0,
  });
}

// ─── View Model ───────────────────────────────────────────────────────────────

class BillControlCenterData {
  final BillAffordabilitySummary affordability;
  final Set<int> paidBillIds;
  final List<RecurringTransaction> overdue;
  final List<RecurringTransaction> dueSoon;
  final List<RecurringTransaction> thisMonth;
  final List<RecurringTransaction> later;
  final double monthlyTotal;
  final double thisWeekTotal;
  final int thisWeekCount;
  final int activeCount;
  final RecurringTransaction? largestBill;

  const BillControlCenterData({
    required this.affordability,
    required this.paidBillIds,
    required this.overdue,
    required this.dueSoon,
    required this.thisMonth,
    required this.later,
    required this.monthlyTotal,
    required this.thisWeekTotal,
    required this.thisWeekCount,
    required this.activeCount,
    this.largestBill,
  });
}

// ─── Provider ─────────────────────────────────────────────────────────────────

const _dueSoonDays = 7;

final billControlCenterProvider =
    FutureProvider.autoDispose<BillControlCenterData>((ref) async {
  final bills = await ref.watch(recurringTransactionsProvider.future);
  final accounts = await ref.watch(accountsProvider.future);
  final accountService = ref.watch(accountServiceProvider);
  final isar = await ref.watch(isarServiceProvider).getInstance();

  final active = bills.where((b) => b.isActive).toList();
  final now = DateTime.now();

  // ── Group by urgency ──
  final overdue = <RecurringTransaction>[];
  final dueSoon = <RecurringTransaction>[];
  final thisMonth = <RecurringTransaction>[];
  final later = <RecurringTransaction>[];

  for (final b in active) {
    final days = b.nextDueDate.difference(now).inDays;
    if (b.nextDueDate.isBefore(now)) {
      overdue.add(b);
    } else if (days <= _dueSoonDays) {
      dueSoon.add(b);
    } else if (b.nextDueDate.month == now.month &&
        b.nextDueDate.year == now.year) {
      thisMonth.add(b);
    } else {
      later.add(b);
    }
  }

  overdue.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
  dueSoon.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
  thisMonth.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
  later.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

  // ── Batch paid detection ──
  final upcoming = [...overdue, ...dueSoon];
  final paidBillIds = <int>{};

  if (upcoming.isNotEmpty) {
    // Single query: find all transactions linked to any active recurring bill
    // within the relevant date window
    final earliestDue = upcoming
        .map((b) => b.nextDueDate)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final searchStart =
        DateTime(earliestDue.year, earliestDue.month, earliestDue.day)
            .subtract(const Duration(days: 1));
    final searchEnd = now.add(const Duration(days: 1));

    final paidTxns = await isar.transactions
        .filter()
        .dateBetween(searchStart, searchEnd)
        .recurringTransactionSource((q) => q.idGreaterThan(0))
        .findAll();

    for (final txn in paidTxns) {
      await txn.recurringTransactionSource.load();
      final sourceId = txn.recurringTransactionSource.value?.id;
      if (sourceId != null) {
        paidBillIds.add(sourceId);
      }
    }
  }

  // ── Affordability ──
  final balanceMap = await accountService.getAccountBalanceMap();
  final totalBalance =
      accounts.fold(0.0, (sum, a) => sum + (balanceMap[a.id] ?? 0));
  final upcomingTotal = upcoming.fold(0.0, (s, b) => s + b.amount);
  final remainingBalance = totalBalance - upcomingTotal;

  // Buffer threshold: > 30% = safe, 0-30% = low, negative = negative
  final AffordabilityState affordState;
  if (remainingBalance < 0) {
    affordState = AffordabilityState.negative;
  } else if (totalBalance > 0 && remainingBalance / totalBalance <= 0.3) {
    affordState = AffordabilityState.low;
  } else {
    affordState = AffordabilityState.safe;
  }

  // Sequential depletion (account-aware, dueDate ASC + amount DESC tie-break)
  final billsForDepletion = [...upcoming]..sort((a, b) {
      final dateCmp = a.nextDueDate.compareTo(b.nextDueDate);
      if (dateCmp != 0) return dateCmp;
      return b.amount.compareTo(a.amount); // larger first on tie
    });

  var depleting = totalBalance;
  var funded = 0;
  var unfunded = 0;
  for (final bill in billsForDepletion) {
    if (paidBillIds.contains(bill.id)) {
      funded++;
      continue;
    }
    if (depleting >= bill.amount) {
      depleting -= bill.amount;
      funded++;
    } else {
      unfunded++;
    }
  }

  // ── Monthly total ──
  final monthlyTotal =
      active.fold(0.0, (sum, b) => sum + _monthlyEquivalent(b));

  // ── This week required ──
  final thisWeekBills = upcoming.where((b) => !paidBillIds.contains(b.id));
  final thisWeekTotal = thisWeekBills.fold(0.0, (s, b) => s + b.amount);
  final thisWeekCount = thisWeekBills.length;

  // ── Largest bill ──
  RecurringTransaction? largest;
  if (active.isNotEmpty) {
    largest = active.reduce((a, b) => a.amount > b.amount ? a : b);
  }

  return BillControlCenterData(
    affordability: BillAffordabilitySummary(
      totalBalance: totalBalance,
      upcomingTotal: upcomingTotal,
      remainingBalance: remainingBalance,
      state: affordState,
      fundedCount: funded,
      unfundedCount: unfunded,
    ),
    paidBillIds: paidBillIds,
    overdue: overdue,
    dueSoon: dueSoon,
    thisMonth: thisMonth,
    later: later,
    monthlyTotal: monthlyTotal,
    thisWeekTotal: thisWeekTotal,
    thisWeekCount: thisWeekCount,
    activeCount: active.length,
    largestBill: largest,
  );
});

double _monthlyEquivalent(RecurringTransaction b) => switch (b.frequency) {
      Frequency.daily => b.amount * 30,
      Frequency.weekly => b.amount * 4.33,
      Frequency.monthly => b.amount,
      Frequency.yearly => b.amount / 12,
    };

import 'package:mudra_manager/core/db/models/trip.dart';
import 'package:mudra_manager/features/trip/domain/group_action.dart';
import 'package:mudra_manager/features/trip/domain/group_detail_state.dart';

/// Pure assembler that projects persistence models into the read model.
///
/// No Riverpod. No Isar. No Flutter. No side effects.
/// Testable with plain unit tests.
class GroupDetailAssembler {
  const GroupDetailAssembler();

  GroupDetailState build({
    required Trip group,
    required List<TripTransaction> transactions,
    required List<TripParticipant> participants,
    required Map<String, Map<String, double>> pendingSettlements,
  }) {
    final header = _buildHeader(group, participants);
    final currencyCode = group.currencyCode;
    final ownerId = participants.where((p) => p.isOwner).firstOrNull?.id;

    // Separate expenses from settlements
    final expenseTxns = <TripTransaction>[];
    final settlementTxns = <TripTransaction>[];

    for (final txn in transactions) {
      if (_isSettlement(txn)) {
        settlementTxns.add(txn);
      } else {
        expenseTxns.add(txn);
      }
    }

    // Build resolved expenses
    final resolvedExpenses = expenseTxns
        .map((txn) => _resolveExpense(txn, participants, currencyCode, ownerId))
        .where((e) => e != null)
        .cast<GroupExpenseView>()
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final timeline = _buildTimeline(resolvedExpenses, currencyCode);
    final settlements = _buildSettlements(
      pendingSettlements,
      settlementTxns,
      participants,
      currencyCode,
    );
    final insights = _buildInsights(resolvedExpenses, participants);
    final actions = _computeActions(group, pendingSettlements);

    return GroupDetailState(
      header: header,
      timeline: timeline,
      settlements: settlements,
      insights: insights,
      allowedActions: actions,
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  GroupHeaderView _buildHeader(Trip group, List<TripParticipant> participants) {
    final duration = group.endDate.difference(group.startDate).inDays + 1;
    return GroupHeaderView(
      id: group.id,
      name: group.name,
      description: group.description,
      isTrip: group.isTrip,
      isActive: group.isActive,
      startDate: group.startDate,
      endDate: group.endDate,
      durationDays: duration,
      memberCount: participants.length,
      budget: group.budget,
      currencyCode: group.currencyCode,
    );
  }

  // ─── Expense Resolution ───────────────────────────────────────────────────

  GroupExpenseView? _resolveExpense(
    TripTransaction txn,
    List<TripParticipant> participants,
    String? targetCurrency,
    int? ownerId,
  ) {
    final amount = txn.resolvedAmountIn(targetCurrency);
    if (amount == null) return null;

    final paidBy = txn.paidBy.value;
    final paidById = paidBy?.id ?? 0;
    final paidByName = paidBy?.name ?? 'Unknown';
    final paidByOwner = ownerId != null && paidById == ownerId;

    // Resolve title from transaction category or split expense description
    final mainTxn = txn.transaction.value;
    final splitExp = txn.splitExpense.value;
    final categoryName = mainTxn?.category.value?.name;
    final title = categoryName ?? splitExp?.description ?? 'Uncategorized';
    final description = txn.resolvedDescription;

    // Build shares
    final shares = <ParticipantShare>[];
    double? ownerShareAmount;

    for (var i = 0; i < txn.participantIds.length; i++) {
      final pid = txn.participantIds[i];
      final shareAmount =
          i < txn.splitAmounts.length ? txn.splitAmounts[i] : 0.0;
      final participant = participants.where((p) => p.id == pid).firstOrNull;
      final name = participant?.name ?? 'Unknown';

      shares.add(
        ParticipantShare(
          participantId: pid,
          name: name,
          amount: shareAmount,
        ),
      );

      if (ownerId != null && pid == ownerId) {
        ownerShareAmount = shareAmount;
      }
    }

    final date = txn.resolvedDate ?? DateTime(2000);

    return GroupExpenseView(
      id: txn.id,
      title: title,
      description: description != title ? description : null,
      amount: amount,
      currencyCode: targetCurrency,
      date: date,
      paidByName: paidByName,
      paidById: paidById,
      paidByOwner: paidByOwner,
      splitType: txn.splitType,
      shares: shares,
      categoryName: categoryName,
      isSettlement: false,
      ownerShareAmount: ownerShareAmount,
    );
  }

  // ─── Timeline ─────────────────────────────────────────────────────────────

  TimelineView _buildTimeline(
    List<GroupExpenseView> expenses,
    String? currencyCode,
  ) {
    if (expenses.isEmpty) return TimelineView.empty;

    // Group by date (day granularity)
    final Map<DateTime, List<GroupExpenseView>> grouped = {};
    for (final expense in expenses) {
      final dayKey = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      grouped.putIfAbsent(dayKey, () => []).add(expense);
    }

    // Build days sorted descending (most recent first)
    final days = grouped.entries.map((entry) {
      final dayExpenses = entry.value;
      final dayTotal = dayExpenses.fold<double>(0, (sum, e) => sum + e.amount);
      return TimelineDay(
        date: entry.key,
        totalSpent: dayTotal,
        expenseCount: dayExpenses.length,
        expenses: dayExpenses,
      );
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final totalSpent = expenses.fold<double>(0, (sum, e) => sum + e.amount);

    return TimelineView(
      days: days,
      totalExpenseCount: expenses.length,
      totalSpent: totalSpent,
    );
  }

  // ─── Settlements ──────────────────────────────────────────────────────────

  SettlementView _buildSettlements(
    Map<String, Map<String, double>> pendingMap,
    List<TripTransaction> settlementTxns,
    List<TripParticipant> participants,
    String? currencyCode,
  ) {
    // Pending settlements
    final pending = <PendingSettlement>[];
    pendingMap.forEach((fromName, toMap) {
      toMap.forEach((toName, amount) {
        final fromP = participants.where((p) => p.name == fromName).firstOrNull;
        final toP = participants.where((p) => p.name == toName).firstOrNull;
        pending.add(
          PendingSettlement(
            fromName: fromName,
            toName: toName,
            fromId: fromP?.id ?? 0,
            toId: toP?.id ?? 0,
            amount: amount,
          ),
        );
      });
    });

    // Settlement history from recorded settlement transactions
    final history = <SettlementRecord>[];
    for (final txn in settlementTxns) {
      final paidBy = txn.paidBy.value;
      final amount = txn.resolvedAmountIn(currencyCode) ?? 0;
      final date = txn.resolvedDate ?? DateTime.now();

      // The "to" person is in participantIds
      final toId =
          txn.participantIds.isNotEmpty ? txn.participantIds.first : null;
      final toName = toId != null
          ? participants.where((p) => p.id == toId).firstOrNull?.name ??
              'Unknown'
          : 'Unknown';

      history.add(
        SettlementRecord(
          fromName: paidBy?.name ?? 'Someone',
          toName: toName,
          amount: amount,
          date: date,
        ),
      );
    }

    // Sort history by date descending
    history.sort((a, b) => b.date.compareTo(a.date));

    return SettlementView(
      pending: pending,
      history: history,
      pendingCount: pending.length,
    );
  }

  // ─── Insights ─────────────────────────────────────────────────────────────

  InsightsView _buildInsights(
    List<GroupExpenseView> expenses,
    List<TripParticipant> participants,
  ) {
    if (expenses.isEmpty) return InsightsView.empty;

    final totalCost = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final participantCount = participants.length;
    final perPerson = participantCount > 0 ? totalCost / participantCount : 0.0;
    final avgPerTxn = expenses.isNotEmpty ? totalCost / expenses.length : 0.0;

    // Category breakdown
    final Map<String, double> categoryTotals = {};
    for (final expense in expenses) {
      final cat = expense.categoryName ?? expense.title;
      categoryTotals[cat] = (categoryTotals[cat] ?? 0) + expense.amount;
    }
    final categories = categoryTotals.entries
        .map(
          (e) => CategoryBreakdown(
            name: e.key,
            amount: e.value,
            percentage: totalCost > 0 ? e.value / totalCost * 100 : 0,
          ),
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    // Per-participant spending (amount paid, not owed)
    final Map<int, double> paidMap = {};
    for (final expense in expenses) {
      paidMap[expense.paidById] =
          (paidMap[expense.paidById] ?? 0) + expense.amount;
    }

    final participantSpending = participants.map((p) {
      final paid = paidMap[p.id] ?? 0;
      return ParticipantSpending(
        id: p.id,
        name: p.name,
        amountPaid: paid,
        percentage: totalCost > 0 ? paid / totalCost * 100 : 0,
      );
    }).toList()
      ..sort((a, b) => b.amountPaid.compareTo(a.amountPaid));

    final topSpender =
        participantSpending.isNotEmpty ? participantSpending.first : null;

    return InsightsView(
      totalCost: totalCost,
      transactionCount: expenses.length,
      participantCount: participantCount,
      perPersonAverage: perPerson,
      averagePerTransaction: avgPerTxn,
      categories: categories,
      participantSpending: participantSpending,
      topSpender: topSpender,
    );
  }

  // ─── Permissions ──────────────────────────────────────────────────────────

  Set<GroupAction> _computeActions(
    Trip group,
    Map<String, Map<String, double>> pendingSettlements,
  ) {
    final actions = <GroupAction>{};

    if (group.isActive) {
      actions.add(GroupAction.addExpense);
      actions.add(GroupAction.editGroup);
      actions.add(GroupAction.archiveGroup);
    }

    if (!group.isActive) {
      actions.add(GroupAction.exportPdf);
    }

    // Settlement marking: allowed for split groups (always) or archived trips
    final hasPending = pendingSettlements.isNotEmpty;
    if (hasPending && (!group.isTrip || !group.isActive)) {
      actions.add(GroupAction.markSettlementPaid);
    }

    return actions;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  bool _isSettlement(TripTransaction txn) {
    return txn.splitExpense.value?.description == 'Settlement';
  }
}

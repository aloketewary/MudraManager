import 'package:flutter/foundation.dart';
import 'package:mudra_manager/core/db/models/trip.dart';
import 'package:mudra_manager/features/trip/domain/group_action.dart';

/// Root read model for the group detail screen.
/// Fully materialized, immutable snapshot — no lazy computation.
@immutable
class GroupDetailState {
  final GroupHeaderView header;
  final TimelineView timeline;
  final SettlementView settlements;
  final InsightsView insights;
  final Set<GroupAction> allowedActions;

  const GroupDetailState({
    required this.header,
    required this.timeline,
    required this.settlements,
    required this.insights,
    required this.allowedActions,
  });
}

/// Identity and metadata for the group.
@immutable
class GroupHeaderView {
  final int id;
  final String name;
  final String? description;
  final bool isTrip;
  final bool isActive;
  final DateTime startDate;
  final DateTime endDate;
  final int durationDays;
  final int memberCount;
  final double? budget;
  final String? currencyCode;

  const GroupHeaderView({
    required this.id,
    required this.name,
    this.description,
    required this.isTrip,
    required this.isActive,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    required this.memberCount,
    this.budget,
    this.currencyCode,
  });
}

/// Pre-grouped expenses by day. UI iterates days → expenses.
@immutable
class TimelineView {
  final List<TimelineDay> days;
  final int totalExpenseCount;
  final double totalSpent;

  const TimelineView({
    required this.days,
    required this.totalExpenseCount,
    required this.totalSpent,
  });

  static const empty = TimelineView(
    days: [],
    totalExpenseCount: 0,
    totalSpent: 0,
  );
}

/// A single day's expenses, pre-sorted and pre-summed.
@immutable
class TimelineDay {
  final DateTime date;
  final double totalSpent;
  final int expenseCount;
  final List<GroupExpenseView> expenses;

  const TimelineDay({
    required this.date,
    required this.totalSpent,
    required this.expenseCount,
    required this.expenses,
  });
}

/// Fully resolved expense — no Isar links, no null-checking two sources.
@immutable
class GroupExpenseView {
  final int id;
  final String title;
  final String? description;
  final double amount;
  final String? currencyCode;
  final DateTime date;
  final String paidByName;
  final int paidById;
  final bool paidByOwner;
  final SplitType splitType;
  final List<ParticipantShare> shares;
  final String? categoryName;
  final bool isSettlement;

  /// Owner's share amount (pre-computed for "You owe ₹X" display).
  final double? ownerShareAmount;

  const GroupExpenseView({
    required this.id,
    required this.title,
    this.description,
    required this.amount,
    this.currencyCode,
    required this.date,
    required this.paidByName,
    required this.paidById,
    required this.paidByOwner,
    required this.splitType,
    required this.shares,
    this.categoryName,
    required this.isSettlement,
    this.ownerShareAmount,
  });
}

/// A participant's share in an expense.
@immutable
class ParticipantShare {
  final int participantId;
  final String name;
  final double amount;

  const ParticipantShare({
    required this.participantId,
    required this.name,
    required this.amount,
  });
}

/// Settlement state — pending + history.
@immutable
class SettlementView {
  final List<PendingSettlement> pending;
  final List<SettlementRecord> history;
  final int pendingCount;

  const SettlementView({
    required this.pending,
    required this.history,
    required this.pendingCount,
  });

  static const empty = SettlementView(
    pending: [],
    history: [],
    pendingCount: 0,
  );
}

/// A computed debt: person A owes person B some amount.
@immutable
class PendingSettlement {
  final String fromName;
  final String toName;
  final int fromId;
  final int toId;
  final double amount;

  const PendingSettlement({
    required this.fromName,
    required this.toName,
    required this.fromId,
    required this.toId,
    required this.amount,
  });
}

/// A recorded settlement payment.
@immutable
class SettlementRecord {
  final String fromName;
  final String toName;
  final double amount;
  final DateTime date;

  const SettlementRecord({
    required this.fromName,
    required this.toName,
    required this.amount,
    required this.date,
  });
}

/// Pre-computed analytics for the Insights tab.
@immutable
class InsightsView {
  final double totalCost;
  final int transactionCount;
  final int participantCount;
  final double perPersonAverage;
  final double averagePerTransaction;
  final List<CategoryBreakdown> categories;
  final List<ParticipantSpending> participantSpending;
  final ParticipantSpending? topSpender;

  const InsightsView({
    required this.totalCost,
    required this.transactionCount,
    required this.participantCount,
    required this.perPersonAverage,
    required this.averagePerTransaction,
    required this.categories,
    required this.participantSpending,
    this.topSpender,
  });

  static const empty = InsightsView(
    totalCost: 0,
    transactionCount: 0,
    participantCount: 0,
    perPersonAverage: 0,
    averagePerTransaction: 0,
    categories: [],
    participantSpending: [],
  );
}

/// Category spend breakdown for insights.
@immutable
class CategoryBreakdown {
  final String name;
  final double amount;
  final double percentage;

  const CategoryBreakdown({
    required this.name,
    required this.amount,
    required this.percentage,
  });
}

/// Per-participant spending for insights.
@immutable
class ParticipantSpending {
  final int id;
  final String name;
  final double amountPaid;
  final double percentage;

  const ParticipantSpending({
    required this.id,
    required this.name,
    required this.amountPaid,
    required this.percentage,
  });
}

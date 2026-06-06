import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/trip.dart';
import 'package:mudra_manager/features/trip/domain/group_action.dart';
import 'package:mudra_manager/features/trip/domain/group_detail_assembler.dart';

void main() {
  const assembler = GroupDetailAssembler();

  late Trip activeTrip;
  late Trip archivedSplit;
  late List<TripParticipant> participants;

  setUp(() {
    activeTrip = Trip.create(
      name: 'Goa Trip',
      startDate: DateTime(2024, 1, 10),
      endDate: DateTime(2024, 1, 15),
      isTrip: true,
      budget: 50000,
    )..id = 1;

    archivedSplit = Trip.create(
      name: 'Flat Expenses',
      startDate: DateTime(2024, 1, 1),
      endDate: DateTime(2024, 12, 31),
      isTrip: false,
    )
      ..id = 2
      ..isActive = false;

    final p1 = TripParticipant.create(name: 'Aloke', isOwner: true)..id = 10;
    final p2 = TripParticipant.create(name: 'Rahul')..id = 11;
    final p3 = TripParticipant.create(name: 'Priya')..id = 12;
    participants = [p1, p2, p3];
  });

  group('GroupDetailAssembler - Header', () {
    test('builds header from active trip', () {
      final state = assembler.build(
        group: activeTrip,
        transactions: [],
        participants: participants,
        pendingSettlements: {},
      );

      expect(state.header.name, 'Goa Trip');
      expect(state.header.isTrip, true);
      expect(state.header.isActive, true);
      expect(state.header.durationDays, 6);
      expect(state.header.memberCount, 3);
      expect(state.header.budget, 50000);
    });

    test('builds header from archived split group', () {
      final state = assembler.build(
        group: archivedSplit,
        transactions: [],
        participants: participants,
        pendingSettlements: {},
      );

      expect(state.header.name, 'Flat Expenses');
      expect(state.header.isTrip, false);
      expect(state.header.isActive, false);
    });
  });

  group('GroupDetailAssembler - Timeline', () {
    test('empty transactions produce empty timeline', () {
      final state = assembler.build(
        group: activeTrip,
        transactions: [],
        participants: participants,
        pendingSettlements: {},
      );

      expect(state.timeline.days, isEmpty);
      expect(state.timeline.totalExpenseCount, 0);
      expect(state.timeline.totalSpent, 0);
    });

    test('groups expenses by day', () {
      final txn1 = _makeSplitExpenseTxn(
        id: 1,
        amount: 1000,
        date: DateTime(2024, 1, 10, 14, 30),
        description: 'Lunch',
        paidBy: participants[0],
        participantIds: [10, 11, 12],
        splitAmounts: [334, 333, 333],
      );
      final txn2 = _makeSplitExpenseTxn(
        id: 2,
        amount: 500,
        date: DateTime(2024, 1, 10, 18, 0),
        description: 'Snacks',
        paidBy: participants[1],
        participantIds: [10, 11, 12],
        splitAmounts: [167, 166, 167],
      );
      final txn3 = _makeSplitExpenseTxn(
        id: 3,
        amount: 2000,
        date: DateTime(2024, 1, 11, 10, 0),
        description: 'Hotel',
        paidBy: participants[0],
        participantIds: [10, 11, 12],
        splitAmounts: [667, 667, 666],
      );

      final state = assembler.build(
        group: activeTrip,
        transactions: [txn1, txn2, txn3],
        participants: participants,
        pendingSettlements: {},
      );

      expect(state.timeline.days.length, 2);
      expect(state.timeline.totalExpenseCount, 3);
      expect(state.timeline.totalSpent, 3500);

      // Most recent day first
      final day1 = state.timeline.days[0]; // Jan 11
      expect(day1.date, DateTime(2024, 1, 11));
      expect(day1.expenseCount, 1);
      expect(day1.totalSpent, 2000);

      final day2 = state.timeline.days[1]; // Jan 10
      expect(day2.date, DateTime(2024, 1, 10));
      expect(day2.expenseCount, 2);
      expect(day2.totalSpent, 1500);
    });

    test('excludes settlements from timeline', () {
      final expense = _makeSplitExpenseTxn(
        id: 1,
        amount: 1000,
        date: DateTime(2024, 1, 10),
        description: 'Dinner',
        paidBy: participants[0],
        participantIds: [10, 11],
        splitAmounts: [500, 500],
      );
      final settlement = _makeSplitExpenseTxn(
        id: 2,
        amount: 500,
        date: DateTime(2024, 1, 12),
        description: 'Settlement',
        paidBy: participants[1],
        participantIds: [10],
        splitAmounts: [500],
      );

      final state = assembler.build(
        group: activeTrip,
        transactions: [expense, settlement],
        participants: participants,
        pendingSettlements: {},
      );

      expect(state.timeline.totalExpenseCount, 1);
      expect(state.timeline.totalSpent, 1000);
    });
  });

  group('GroupDetailAssembler - Expense Resolution', () {
    test('resolves expense with owner share', () {
      final txn = _makeSplitExpenseTxn(
        id: 1,
        amount: 900,
        date: DateTime(2024, 1, 10),
        description: 'Dinner',
        paidBy: participants[1], // Rahul paid
        participantIds: [10, 11, 12],
        splitAmounts: [300, 300, 300],
      );

      final state = assembler.build(
        group: activeTrip,
        transactions: [txn],
        participants: participants,
        pendingSettlements: {},
      );

      final expense = state.timeline.days.first.expenses.first;
      expect(expense.title, 'Dinner');
      expect(expense.amount, 900);
      expect(expense.paidByName, 'Rahul');
      expect(expense.paidByOwner, false);
      expect(expense.ownerShareAmount, 300);
      expect(expense.shares.length, 3);
      expect(expense.isSettlement, false);
    });

    test('identifies owner as payer', () {
      final txn = _makeSplitExpenseTxn(
        id: 1,
        amount: 600,
        date: DateTime(2024, 1, 10),
        description: 'Taxi',
        paidBy: participants[0], // Aloke (owner) paid
        participantIds: [10, 11],
        splitAmounts: [300, 300],
      );

      final state = assembler.build(
        group: activeTrip,
        transactions: [txn],
        participants: participants,
        pendingSettlements: {},
      );

      final expense = state.timeline.days.first.expenses.first;
      expect(expense.paidByOwner, true);
    });
  });

  group('GroupDetailAssembler - Settlements', () {
    test('maps pending settlements with participant IDs', () {
      final pendingMap = {
        'Rahul': {'Aloke': 500.0},
        'Priya': {'Aloke': 300.0},
      };

      final state = assembler.build(
        group: activeTrip,
        transactions: [],
        participants: participants,
        pendingSettlements: pendingMap,
      );

      expect(state.settlements.pendingCount, 2);
      expect(state.settlements.pending[0].fromName, 'Rahul');
      expect(state.settlements.pending[0].toName, 'Aloke');
      expect(state.settlements.pending[0].fromId, 11);
      expect(state.settlements.pending[0].toId, 10);
      expect(state.settlements.pending[0].amount, 500);
    });

    test('builds settlement history from settlement transactions', () {
      final settlement = _makeSplitExpenseTxn(
        id: 1,
        amount: 500,
        date: DateTime(2024, 1, 15),
        description: 'Settlement',
        paidBy: participants[1], // Rahul paid
        participantIds: [10], // to Aloke
        splitAmounts: [500],
      );

      final state = assembler.build(
        group: activeTrip,
        transactions: [settlement],
        participants: participants,
        pendingSettlements: {},
      );

      expect(state.settlements.history.length, 1);
      expect(state.settlements.history[0].fromName, 'Rahul');
      expect(state.settlements.history[0].toName, 'Aloke');
      expect(state.settlements.history[0].amount, 500);
    });
  });

  group('GroupDetailAssembler - Insights', () {
    test('computes insights from expenses', () {
      final txn1 = _makeSplitExpenseTxn(
        id: 1,
        amount: 1000,
        date: DateTime(2024, 1, 10),
        description: 'Hotel',
        paidBy: participants[0],
        participantIds: [10, 11, 12],
        splitAmounts: [334, 333, 333],
      );
      final txn2 = _makeSplitExpenseTxn(
        id: 2,
        amount: 500,
        date: DateTime(2024, 1, 11),
        description: 'Food',
        paidBy: participants[1],
        participantIds: [10, 11, 12],
        splitAmounts: [167, 166, 167],
      );

      final state = assembler.build(
        group: activeTrip,
        transactions: [txn1, txn2],
        participants: participants,
        pendingSettlements: {},
      );

      expect(state.insights.totalCost, 1500);
      expect(state.insights.transactionCount, 2);
      expect(state.insights.participantCount, 3);
      expect(state.insights.perPersonAverage, 500);
      expect(state.insights.averagePerTransaction, 750);
      expect(state.insights.topSpender?.name, 'Aloke');
      expect(state.insights.topSpender?.amountPaid, 1000);
    });

    test('computes category breakdown sorted by amount', () {
      final txn1 = _makeSplitExpenseTxn(
        id: 1,
        amount: 2000,
        date: DateTime(2024, 1, 10),
        description: 'Hotel',
        paidBy: participants[0],
        participantIds: [10, 11],
        splitAmounts: [1000, 1000],
      );
      final txn2 = _makeSplitExpenseTxn(
        id: 2,
        amount: 500,
        date: DateTime(2024, 1, 10),
        description: 'Food',
        paidBy: participants[0],
        participantIds: [10, 11],
        splitAmounts: [250, 250],
      );

      final state = assembler.build(
        group: activeTrip,
        transactions: [txn1, txn2],
        participants: participants,
        pendingSettlements: {},
      );

      expect(state.insights.categories.length, 2);
      expect(state.insights.categories[0].name, 'Hotel');
      expect(state.insights.categories[0].amount, 2000);
      expect(state.insights.categories[1].name, 'Food');
    });

    test('empty expenses produce empty insights', () {
      final state = assembler.build(
        group: activeTrip,
        transactions: [],
        participants: participants,
        pendingSettlements: {},
      );

      expect(state.insights.totalCost, 0);
      expect(state.insights.categories, isEmpty);
      expect(state.insights.topSpender, isNull);
    });
  });

  group('GroupDetailAssembler - Permissions', () {
    test('active trip allows add, edit, archive', () {
      final state = assembler.build(
        group: activeTrip,
        transactions: [],
        participants: participants,
        pendingSettlements: {},
      );

      expect(state.allowedActions, contains(GroupAction.addExpense));
      expect(state.allowedActions, contains(GroupAction.editGroup));
      expect(state.allowedActions, contains(GroupAction.archiveGroup));
      expect(
        state.allowedActions,
        isNot(contains(GroupAction.exportPdf)),
      );
    });

    test('archived group allows export', () {
      final state = assembler.build(
        group: archivedSplit,
        transactions: [],
        participants: participants,
        pendingSettlements: {},
      );

      expect(state.allowedActions, contains(GroupAction.exportPdf));
      expect(
        state.allowedActions,
        isNot(contains(GroupAction.addExpense)),
      );
    });

    test('active split with pending settlements allows marking paid', () {
      final state = assembler.build(
        group: Trip.create(
          name: 'Active Split',
          startDate: DateTime(2024),
          endDate: DateTime(2024, 12, 31),
          isTrip: false,
        )..id = 3,
        transactions: [],
        participants: participants,
        pendingSettlements: {'Rahul': {'Aloke': 500}},
      );

      expect(
        state.allowedActions,
        contains(GroupAction.markSettlementPaid),
      );
    });

    test('active trip with pending settlements blocks marking paid', () {
      final state = assembler.build(
        group: activeTrip,
        transactions: [],
        participants: participants,
        pendingSettlements: {'Rahul': {'Aloke': 500}},
      );

      expect(
        state.allowedActions,
        isNot(contains(GroupAction.markSettlementPaid)),
      );
    });
  });
}

/// Helper to create a TripTransaction backed by a SplitExpense.
/// This simulates the fully-loaded state that TripService.getTripById returns.
TripTransaction _makeSplitExpenseTxn({
  required int id,
  required double amount,
  required DateTime date,
  required String description,
  required TripParticipant paidBy,
  required List<int> participantIds,
  required List<double> splitAmounts,
}) {
  final expense = SplitExpense.create(
    amount: amount,
    description: description,
    date: date,
  )..id = id * 100;

  final txn = TripTransaction.create(
    splitType: SplitType.equal,
    participantIds: participantIds,
    splitAmounts: splitAmounts,
  )..id = id;

  txn.splitExpense.value = expense;
  txn.paidBy.value = paidBy;

  return txn;
}

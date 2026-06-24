import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/trip.dart';
import 'package:mudra_manager/features/trip/data/trip_service.dart';
import 'package:mudra_manager/features/trip/domain/group_action.dart';
import 'package:mudra_manager/features/trip/domain/group_detail_assembler.dart';

void main() {
  const assembler = GroupDetailAssembler();

  late List<TripParticipant> participants;

  setUp(() {
    participants = [
      TripParticipant.create(name: 'Alice', isOwner: true)..id = 1,
      TripParticipant.create(name: 'Bob')..id = 2,
      TripParticipant.create(name: 'Charlie')..id = 3,
    ];
  });

  group('Settlement detection', () {
    test('detects settlement via isSettlement field', () {
      final trip = Trip.create(
        name: 'Test',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 10),
        isTrip: true,
      )..id = 1;

      // Regular expense
      final expense = TripTransaction.create(
        splitType: SplitType.equal,
        participantIds: [1, 2, 3],
        splitAmounts: [100, 100, 100],
      )..id = 10;

      // Settlement with boolean field
      final settlement = TripTransaction.create(
        splitType: SplitType.equal,
        participantIds: [2],
        splitAmounts: [100],
      )
        ..id = 11
        ..isSettlement = true;

      final state = assembler.build(
        group: trip,
        transactions: [expense, settlement],
        participants: participants,
        pendingSettlements: {},
      );

      // Settlement should NOT appear in timeline expenses
      expect(state.timeline.totalExpenseCount, 0);
      // settlement is in settlement history (but since no paidBy loaded, 
      // it may not resolve — the key test is that it's excluded from expenses)
    });

    test('fallback detects settlement via description for old data', () {
      final trip = Trip.create(
        name: 'Test',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 10),
        isTrip: false,
      )..id = 1;

      // Old-style settlement (no boolean, relies on description)
      final oldSettlement = TripTransaction.create(
        splitType: SplitType.equal,
        participantIds: [2],
        splitAmounts: [200],
      )..id = 20;
      // Simulate old data: splitExpense with 'Settlement' description
      final splitExp = SplitExpense.create(
        amount: 200,
        description: 'Settlement',
        date: DateTime(2025, 1, 5),
      )..id = 30;
      oldSettlement.splitExpense.value = splitExp;

      final state = assembler.build(
        group: trip,
        transactions: [oldSettlement],
        participants: participants,
        pendingSettlements: {},
      );

      // Old settlement should also be excluded from timeline
      expect(state.timeline.totalExpenseCount, 0);
    });

    test('non-settlement expense appears in timeline', () {
      final trip = Trip.create(
        name: 'Test',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 10),
        isTrip: true,
      )..id = 1;

      final splitExp = SplitExpense.create(
        amount: 600,
        description: 'Dinner',
        date: DateTime(2025, 1, 5),
      )..id = 40;

      final expense = TripTransaction.create(
        splitType: SplitType.equal,
        participantIds: [1, 2, 3],
        splitAmounts: [200, 200, 200],
      )..id = 12;
      expense.splitExpense.value = splitExp;
      expense.paidBy.value = participants[0]; // Alice paid

      final state = assembler.build(
        group: trip,
        transactions: [expense],
        participants: participants,
        pendingSettlements: {},
      );

      expect(state.timeline.totalExpenseCount, 1);
      expect(state.timeline.totalSpent, 600);
    });
  });

  group('Settlement view', () {
    test('pending settlements rendered from map', () {
      final trip = Trip.create(
        name: 'Test',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 10),
        isTrip: false,
      )
        ..id = 1
        ..isActive = false;

      final pendingSettlements = {
        'Bob': {'Alice': 300.0},
        'Charlie': {'Alice': 150.0},
      };

      final state = assembler.build(
        group: trip,
        transactions: [],
        participants: participants,
        pendingSettlements: pendingSettlements,
      );

      expect(state.settlements.pendingCount, 2);
      expect(
        state.settlements.pending.any(
          (s) => s.fromName == 'Bob' && s.toName == 'Alice' && s.amount == 300,
        ),
        true,
      );
      expect(
        state.settlements.pending.any(
          (s) =>
              s.fromName == 'Charlie' &&
              s.toName == 'Alice' &&
              s.amount == 150,
        ),
        true,
      );
    });

    test('empty pending settlements', () {
      final trip = Trip.create(
        name: 'Test',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 10),
        isTrip: true,
      )..id = 1;

      final state = assembler.build(
        group: trip,
        transactions: [],
        participants: participants,
        pendingSettlements: {},
      );

      expect(state.settlements.pendingCount, 0);
      expect(state.settlements.pending, isEmpty);
    });
  });

  group('Insights', () {
    test('empty expenses produce empty insights', () {
      final trip = Trip.create(
        name: 'Test',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 10),
        isTrip: true,
      )..id = 1;

      final state = assembler.build(
        group: trip,
        transactions: [],
        participants: participants,
        pendingSettlements: {},
      );

      expect(state.insights.totalCost, 0);
      expect(state.insights.transactionCount, 0);
    });

    test('per-person average calculated correctly', () {
      final trip = Trip.create(
        name: 'Test',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 10),
        isTrip: true,
      )..id = 1;

      final splitExp = SplitExpense.create(
        amount: 900,
        description: 'Hotel',
        date: DateTime(2025, 1, 5),
      )..id = 50;

      final expense = TripTransaction.create(
        splitType: SplitType.equal,
        participantIds: [1, 2, 3],
        splitAmounts: [300, 300, 300],
      )..id = 15;
      expense.splitExpense.value = splitExp;
      expense.paidBy.value = participants[0];

      final state = assembler.build(
        group: trip,
        transactions: [expense],
        participants: participants,
        pendingSettlements: {},
      );

      expect(state.insights.totalCost, 900);
      expect(state.insights.perPersonAverage, 300);
      expect(state.insights.participantCount, 3);
    });
  });

  group('Actions', () {
    test('active trip allows addExpense and editGroup', () {
      final trip = Trip.create(
        name: 'Active',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 10),
        isTrip: true,
      )..id = 1;

      final state = assembler.build(
        group: trip,
        transactions: [],
        participants: participants,
        pendingSettlements: {},
      );

      expect(state.allowedActions.contains(GroupAction.addExpense), true);
      expect(state.allowedActions.contains(GroupAction.editGroup), true);
    });

    test('archived trip allows exportPdf', () {
      final trip = Trip.create(
        name: 'Done',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 10),
        isTrip: true,
      )
        ..id = 1
        ..isActive = false;

      final state = assembler.build(
        group: trip,
        transactions: [],
        participants: participants,
        pendingSettlements: {},
      );

      expect(state.allowedActions.contains(GroupAction.exportPdf), true);
      expect(state.allowedActions.contains(GroupAction.addExpense), false);
    });
  });

  group('TripSummary model', () {
    test('youOwe when netBalance negative', () {
      const s = TripSummary(
        participantCount: 3,
        totalSpent: 900,
        ownerShare: 300,
        ownerPaid: 0,
        netBalance: -300,
      );
      expect(s.youOwe, true);
      expect(s.youGet, false);
    });

    test('youGet when netBalance positive', () {
      const s = TripSummary(
        participantCount: 3,
        totalSpent: 900,
        ownerShare: 300,
        ownerPaid: 900,
        netBalance: 600,
      );
      expect(s.youOwe, false);
      expect(s.youGet, true);
    });

    test('settled when zero balance and has spent', () {
      const s = TripSummary(
        participantCount: 2,
        totalSpent: 500,
        ownerShare: 250,
        ownerPaid: 250,
        netBalance: 0,
      );
      expect(s.settled, true);
    });

    test('not settled when zero spent', () {
      const s = TripSummary(
        participantCount: 2,
        totalSpent: 0,
        ownerShare: 0,
        ownerPaid: 0,
        netBalance: 0,
      );
      expect(s.settled, false);
    });
  });
}

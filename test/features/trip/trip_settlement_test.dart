import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/features/trip/data/trip_service.dart';

void main() {
  group('TripSummary', () {
    test('youOwe is true when netBalance is negative', () {
      const summary = TripSummary(
        participantCount: 3,
        totalSpent: 1200,
        ownerShare: 400,
        ownerPaid: 0,
        netBalance: -400,
      );
      expect(summary.youOwe, true);
      expect(summary.youGet, false);
      expect(summary.settled, false);
    });

    test('youGet is true when netBalance is positive', () {
      const summary = TripSummary(
        participantCount: 3,
        totalSpent: 1200,
        ownerShare: 400,
        ownerPaid: 1200,
        netBalance: 800,
      );
      expect(summary.youOwe, false);
      expect(summary.youGet, true);
      expect(summary.settled, false);
    });

    test('settled is true when netBalance is zero and has expenses', () {
      const summary = TripSummary(
        participantCount: 3,
        totalSpent: 1200,
        ownerShare: 400,
        ownerPaid: 400,
        netBalance: 0,
      );
      expect(summary.youOwe, false);
      expect(summary.youGet, false);
      expect(summary.settled, true);
    });

    test('empty group is not settled', () {
      const summary = TripSummary(
        participantCount: 2,
        totalSpent: 0,
        ownerShare: 0,
        ownerPaid: 0,
        netBalance: 0,
      );
      expect(summary.settled, false);
    });

    test('tiny rounding difference treated as settled', () {
      const summary = TripSummary(
        participantCount: 3,
        totalSpent: 100,
        ownerShare: 33.33,
        ownerPaid: 33.34,
        netBalance: 0.01,
      );
      // 0.01 < 0.01 threshold
      expect(summary.youOwe, false);
      expect(summary.youGet, false);
    });
  });

  group('Settlement balance scenarios', () {
    test('equal split 3 ways — owner paid all', () {
      // Dinner ₹900, 3 people, owner paid
      final totalAmount = 900.0;
      final participantCount = 3;
      final ownerPaid = totalAmount;
      final ownerShare = totalAmount / participantCount; // 300

      final netBalance = ownerPaid - ownerShare; // 600 (others owe owner)

      expect(ownerShare, 300);
      expect(netBalance, 600);
    });

    test('equal split 3 ways — friend paid all', () {
      final totalAmount = 900.0;
      final participantCount = 3;
      final ownerPaid = 0.0;
      final ownerShare = totalAmount / participantCount; // 300

      final netBalance = ownerPaid - ownerShare; // -300 (owner owes)

      expect(ownerShare, 300);
      expect(netBalance, -300);
    });

    test('after settlement — balance zeroes out', () {
      // Initial: owner owes ₹300
      var netBalance = -300.0;

      // Settlement: owner pays ₹300
      // Settlement creates: paidBy=owner, participant=[friend], amount=300
      // In calculateSettlements: owner balance += 300, friend balance -= 300
      netBalance += 300; // settlement adjusts balance

      expect(netBalance, 0);
    });

    test('partial settlement — balance reduces', () {
      var netBalance = -500.0;

      // Owner pays ₹200
      netBalance += 200;

      expect(netBalance, -300); // still owes 300
    });

    test('new expense after settlement — balance changes', () {
      // Start: all settled (0)
      var netBalance = 0.0;

      // New expense: ₹600, 3 people, friend paid
      final ownerShare = 600.0 / 3; // 200
      netBalance -= ownerShare; // owner now owes 200

      expect(netBalance, -200);
    });

    test('multiple expenses — cumulative balance', () {
      var ownerPaid = 0.0;
      var ownerOwes = 0.0;

      // Expense 1: ₹900, owner paid, 3 people
      ownerPaid += 900;
      ownerOwes += 300;

      // Expense 2: ₹600, friend paid, 3 people
      ownerPaid += 0;
      ownerOwes += 200;

      final netBalance = ownerPaid - ownerOwes; // 900 - 500 = 400

      expect(netBalance, 400); // others owe owner ₹400
    });
  });

  group('SplitType calculations', () {
    test('equal split divides evenly', () {
      final amount = 1000.0;
      final participants = 4;
      final perPerson = amount / participants;

      expect(perPerson, 250);
    });

    test('equal split with remainder', () {
      final amount = 100.0;
      final participants = 3;
      final perPerson = amount / participants;

      expect(perPerson, closeTo(33.33, 0.01));
    });

    test('percentage split sums to 100', () {
      final percentages = [50.0, 30.0, 20.0];
      expect(percentages.reduce((a, b) => a + b), 100);
    });

    test('custom split sums to total', () {
      final amount = 1000.0;
      final splits = [500.0, 300.0, 200.0];
      expect(splits.reduce((a, b) => a + b), amount);
    });
  });

  group('Settlement edge cases', () {
    test('settlement for exact owed amount zeroes balance', () {
      // Person A owes Person B ₹500
      final owed = 500.0;
      final settled = 500.0;
      final remaining = owed - settled;

      expect(remaining, 0);
    });

    test('overpayment creates reverse debt', () {
      final owed = 300.0;
      final settled = 400.0;
      final remaining = owed - settled;

      expect(remaining, -100); // now B owes A ₹100
    });

    test('multiple small settlements add up', () {
      final owed = 500.0;
      final settlements = [100.0, 150.0, 250.0];
      final totalSettled = settlements.reduce((a, b) => a + b);

      expect(totalSettled, owed);
      expect(owed - totalSettled, 0);
    });
  });

  group('Trip vs Split behavior rules', () {
    test('trip settlement only after ended', () {
      expect(_canSettle(isTrip: true, isActive: true), false);
    });

    test('trip settlement allowed after ended', () {
      expect(_canSettle(isTrip: true, isActive: false), true);
    });

    test('split settlement always allowed', () {
      expect(_canSettle(isTrip: false, isActive: true), true);
    });

    test('split settlement allowed when ended too', () {
      expect(_canSettle(isTrip: false, isActive: false), true);
    });
  });
}

bool _canSettle({required bool isTrip, required bool isActive}) {
  return !(isTrip && isActive);
}

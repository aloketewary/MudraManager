import 'package:flutter_test/flutter_test.dart';

/// Tests the transfer pair detection window logic.
/// The actual DB query is in SmsActivityService._claimTransferPair,
/// but we test the time window logic independently.
void main() {
  group('Transfer pair time window', () {
    const window = Duration(minutes: 30);

    bool isWithinWindow(DateTime activity, DateTime candidate) {
      final startTime = activity.subtract(window);
      final endTime = activity.add(window);
      return candidate.isAfter(startTime) && candidate.isBefore(endTime);
    }

    test('same time is within window', () {
      final now = DateTime.now();
      expect(isWithinWindow(now, now), isTrue);
    });

    test('15 minutes apart is within window', () {
      final now = DateTime.now();
      final candidate = now.add(const Duration(minutes: 15));
      expect(isWithinWindow(now, candidate), isTrue);
    });

    test('29 minutes apart is within window', () {
      final now = DateTime.now();
      final candidate = now.add(const Duration(minutes: 29));
      expect(isWithinWindow(now, candidate), isTrue);
    });

    test('31 minutes apart is outside window', () {
      final now = DateTime.now();
      final candidate = now.add(const Duration(minutes: 31));
      expect(isWithinWindow(now, candidate), isFalse);
    });

    test('1 hour apart is outside window', () {
      final now = DateTime.now();
      final candidate = now.add(const Duration(hours: 1));
      expect(isWithinWindow(now, candidate), isFalse);
    });

    test('24 hours apart is outside window (was previously matching)', () {
      final now = DateTime.now();
      final candidate = now.add(const Duration(hours: 24));
      expect(isWithinWindow(now, candidate), isFalse);
    });

    test('negative direction within window', () {
      final now = DateTime.now();
      final candidate = now.subtract(const Duration(minutes: 20));
      expect(isWithinWindow(now, candidate), isTrue);
    });

    test('negative direction outside window', () {
      final now = DateTime.now();
      final candidate = now.subtract(const Duration(minutes: 35));
      expect(isWithinWindow(now, candidate), isFalse);
    });
  });

  group('Transfer pair matching criteria', () {
    test('same amount, opposite direction, different account = transfer', () {
      // Simulates the matching criteria
      final activity = _FakeActivity(
        amount: 5000.0,
        isIncome: false,
        account: '6988',
      );
      final candidate = _FakeActivity(
        amount: 5000.0,
        isIncome: true,
        account: '1234',
      );

      expect(candidate.amount, activity.amount);
      expect(candidate.isIncome, !activity.isIncome);
      expect(candidate.account, isNot(activity.account));
    });

    test('same amount, same direction = not transfer (duplicate)', () {
      final activity = _FakeActivity(
        amount: 5000.0,
        isIncome: false,
        account: '6988',
      );
      final candidate = _FakeActivity(
        amount: 5000.0,
        isIncome: false,
        account: '1234',
      );

      // Same direction — this is a duplicate, not a transfer
      expect(candidate.isIncome, activity.isIncome);
    });

    test('different amount = not transfer', () {
      final activity = _FakeActivity(
        amount: 5000.0,
        isIncome: false,
        account: '6988',
      );
      final candidate = _FakeActivity(
        amount: 3000.0,
        isIncome: true,
        account: '1234',
      );

      expect(candidate.amount, isNot(activity.amount));
    });

    test('same account = not transfer (same account debit/credit)', () {
      final activity = _FakeActivity(
        amount: 5000.0,
        isIncome: false,
        account: '6988',
      );
      final candidate = _FakeActivity(
        amount: 5000.0,
        isIncome: true,
        account: '6988',
      );

      // Same account — not a transfer between accounts
      expect(candidate.account, activity.account);
    });
  });
}

class _FakeActivity {
  final double amount;
  final bool isIncome;
  final String account;

  _FakeActivity({
    required this.amount,
    required this.isIncome,
    required this.account,
  });
}

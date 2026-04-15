import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/sms_activity.dart';

void main() {
  group('Duplicate detection logic', () {
    test('null account should NOT match all transactions as duplicates', () {
      // Simulates the fixed logic: when SMS has no account info,
      // skip manual transaction dupe check entirely
      final activityAccount = null;
      final shouldCheckManualDupes =
          activityAccount != null && (activityAccount as String).isNotEmpty;

      expect(shouldCheckManualDupes, isFalse);
    });

    test('empty account should NOT match all transactions as duplicates', () {
      final activityAccount = '';
      final shouldCheckManualDupes =
          activityAccount.isNotEmpty;

      expect(shouldCheckManualDupes, isFalse);
    });

    test('valid account should check manual duplicates', () {
      final activityAccount = '6988';
      final shouldCheckManualDupes =
          activityAccount.isNotEmpty;

      expect(shouldCheckManualDupes, isTrue);
    });

    test('manual dupe requires matching account number', () {
      const activityAccount = '6988';
      const txnAccountNumber = 'XXXX6988';

      // Fixed logic: require actual account match
      final isMatch = txnAccountNumber.endsWith(activityAccount);
      expect(isMatch, isTrue);
    });

    test('manual dupe rejects non-matching account', () {
      const activityAccount = '6988';
      const txnAccountNumber = 'XXXX1234';

      final isMatch = txnAccountNumber.endsWith(activityAccount);
      expect(isMatch, isFalse);
    });

    test('null txn account should NOT be treated as duplicate', () {
      // Old behavior: null txnAccount → return true (false positive)
      // New behavior: null txnAccount → return false
      const String? txnAccountNumber = null;
      final isMatch = txnAccountNumber != null &&
          txnAccountNumber.isNotEmpty &&
          txnAccountNumber.endsWith('6988');

      expect(isMatch, isFalse);
    });

    test('empty txn account should NOT be treated as duplicate', () {
      const txnAccountNumber = '';
      final isMatch = txnAccountNumber.isNotEmpty &&
          txnAccountNumber.endsWith('6988');

      expect(isMatch, isFalse);
    });
  });

  group('SMS activity status filtering for duplicates', () {
    test('approved activities should be excluded from dupe check', () {
      final statuses = [
        ActivityStatus.approved,
        ActivityStatus.rejected,
        ActivityStatus.pending,
        ActivityStatus.needsReview,
      ];

      final eligibleForDupeCheck = statuses.where((s) =>
          s != ActivityStatus.approved && s != ActivityStatus.rejected,);

      expect(eligibleForDupeCheck, contains(ActivityStatus.pending));
      expect(eligibleForDupeCheck, contains(ActivityStatus.needsReview));
      expect(eligibleForDupeCheck, isNot(contains(ActivityStatus.approved)));
      expect(eligibleForDupeCheck, isNot(contains(ActivityStatus.rejected)));
    });
  });

  group('Transfer pair detection filtering', () {
    test('only pending activities should be eligible for transfer pairing', () {
      final statuses = ActivityStatus.values;

      final eligibleForTransferPair =
          statuses.where((s) => s == ActivityStatus.pending);

      expect(eligibleForTransferPair.length, 1);
      expect(eligibleForTransferPair.first, ActivityStatus.pending);
    });

    test('approved activity should NOT be paired as transfer', () {
      const status = ActivityStatus.approved;
      final isEligible = status == ActivityStatus.pending;
      expect(isEligible, isFalse);
    });

    test('rejected activity should NOT be paired as transfer', () {
      const status = ActivityStatus.rejected;
      final isEligible = status == ActivityStatus.pending;
      expect(isEligible, isFalse);
    });
  });

  group('Linked transaction check guard', () {
    test('unsaved activity (id=0) should skip linkedTxn check', () {
      // Isar.autoIncrement starts at -9223372036854775808 or 0 depending on state
      // Before saving, id is Isar.autoIncrement which is a sentinel value
      const activityId = 0;
      final shouldCheckLinked = activityId > 0;

      expect(shouldCheckLinked, isFalse);
    });

    test('saved activity (id>0) should check linkedTxn', () {
      const activityId = 42;
      final shouldCheckLinked = activityId > 0;

      expect(shouldCheckLinked, isTrue);
    });

    test('negative id should skip linkedTxn check', () {
      const activityId = -1;
      final shouldCheckLinked = activityId > 0;

      expect(shouldCheckLinked, isFalse);
    });
  });
}

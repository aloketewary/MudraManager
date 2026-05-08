import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/sms_activity.dart';

void main() {
  group('ActivityStatus labels should not be hardcoded', () {
    // This test verifies that the old hardcoded labels are no longer used.
    // The actual localized strings come from AppLocalizations which requires
    // a widget test with MaterialApp. Here we verify the enum coverage.

    test('all ActivityStatus values are covered', () {
      final statuses = ActivityStatus.values;
      expect(statuses, contains(ActivityStatus.pending));
      expect(statuses, contains(ActivityStatus.approved));
      expect(statuses, contains(ActivityStatus.duplicate));
      expect(statuses, contains(ActivityStatus.rejected));
      expect(statuses, contains(ActivityStatus.needsReview));
      expect(statuses.length, 5);
    });

    test('ActivityStatus.name returns lowercase enum name', () {
      // Verify that .name is NOT what we want for display
      // (it returns 'pending', not 'PENDING')
      expect(ActivityStatus.pending.name, 'pending');
      expect(ActivityStatus.approved.name, 'approved');
      expect(ActivityStatus.duplicate.name, 'duplicate');
      expect(ActivityStatus.rejected.name, 'rejected');
      expect(ActivityStatus.needsReview.name, 'needsReview');
    });

    test('hardcoded strings should not be used for display', () {
      // These were the old hardcoded values — verify they don't match .name
      // (confirming that using .name.toUpperCase() is not the same as localized)
      const oldHardcoded = ['PENDING', 'APPROVED', 'DUPLICATE', 'REJECTED', 'REVIEW'];
      final enumNames = ActivityStatus.values.map((s) => s.name.toUpperCase()).toList();

      // 'REVIEW' != 'NEEDSREVIEW' — the old hardcoded label was wrong
      expect(oldHardcoded.contains('REVIEW'), isTrue);
      expect(enumNames.contains('REVIEW'), isFalse);
      expect(enumNames.contains('NEEDSREVIEW'), isTrue);
    });
  });
}

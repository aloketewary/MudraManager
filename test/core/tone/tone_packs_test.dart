import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/tone/tone_pack.dart';
import 'package:mudra_manager/core/tone/tone_packs.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';

void main() {
  final packs = <TonePack>[
    FriendlyTonePack(),
    ProfessionalTonePack(),
    MotivationalTonePack(),
    CalmTonePack(),
  ];

  group('Tone pack registry', () {
    test('all packs are registered', () {
      expect(allTonePacks.length, 4);
    });

    test('all packs have unique IDs', () {
      final ids = allTonePacks.map((p) => p.id).toSet();
      expect(ids.length, allTonePacks.length);
    });

    test('all packs have names and descriptions', () {
      for (final pack in allTonePacks) {
        expect(pack.id, isNotEmpty);
        expect(pack.name, isNotEmpty);
        expect(pack.description, isNotEmpty);
        expect(pack.emoji, isNotEmpty);
      }
    });
  });

  for (final pack in packs) {
    group('${pack.name} tone pack', () {
      test('transaction messages are non-empty', () {
        expect(pack.txnAdded, isNotEmpty);
        expect(pack.txnUpdated, isNotEmpty);
        expect(pack.txnDeleted, isNotEmpty);
        expect(pack.txnFailed, isNotEmpty);
      });

      test('validation messages are non-empty', () {
        expect(pack.enterAmount, isNotEmpty);
        expect(pack.pickAccount, isNotEmpty);
        expect(pack.pickCategory, isNotEmpty);
        expect(pack.fillAllFields, isNotEmpty);
        expect(pack.invalidAmount, isNotEmpty);
      });

      test('budget messages are non-empty', () {
        expect(pack.budgetCreated, isNotEmpty);
        expect(pack.budgetUpdated, isNotEmpty);
        expect(pack.budgetDeleted, isNotEmpty);
      });

      test('goal messages are non-empty', () {
        expect(pack.goalCreated, isNotEmpty);
        expect(pack.goalUpdated, isNotEmpty);
        expect(pack.goalDeleted, isNotEmpty);
      });

      test('goal insight messages work with parameters', () {
        expect(pack.goalMilestone25('Test Goal'), isNotEmpty);
        expect(pack.goalMilestone50('Test Goal'), isNotEmpty);
        expect(pack.goalMilestone75('Test Goal'), isNotEmpty);
        expect(pack.goalMilestone100('Test Goal'), isNotEmpty);
        expect(pack.goalOnTrack('Test Goal'), isNotEmpty);
        expect(pack.goalBehind('Test Goal'), isNotEmpty);
        expect(pack.goalAhead('Test Goal', '5'), isNotEmpty);
        expect(pack.goalDailyNeeded('₹500'), isNotEmpty);
        expect(pack.goalNoDeadline('Test Goal'), isNotEmpty);
      });

      test('trip messages work with isTrip parameter', () {
        expect(pack.tripCreated(true), isNotEmpty);
        expect(pack.tripCreated(false), isNotEmpty);
        expect(pack.tripUpdated(true), isNotEmpty);
        expect(pack.tripDeleted(true), isNotEmpty);
        expect(pack.tripNameRequired(true), isNotEmpty);
        expect(pack.tripLimitReached(false), isNotEmpty);
        expect(pack.expenseAddedToTrip(true), isNotEmpty);
      });

      test('empty state messages are non-empty', () {
        expect(pack.noTransactions, isNotEmpty);
        expect(pack.noBudgets, isNotEmpty);
        expect(pack.noGoals, isNotEmpty);
        expect(pack.noBills, isNotEmpty);
        expect(pack.noAccounts, isNotEmpty);
        expect(pack.noRecurring, isNotEmpty);
      });

      test('budget insight messages work with parameters', () {
        expect(pack.budgetExceededBy('₹1000'), isNotEmpty);
        expect(pack.budgetSlowDown('₹500', 5), isNotEmpty);
        expect(pack.budgetSafePerDay('₹200'), isNotEmpty);
        expect(pack.budgetOnTrack('₹3000'), isNotEmpty);
      });

      test('confirmation messages are non-empty', () {
        expect(pack.deleteTitle, isNotEmpty);
        expect(pack.deleteMessage('item'), isNotEmpty);
        expect(pack.deleteConfirm, isNotEmpty);
        expect(pack.deleteCancel, isNotEmpty);
      });

      test('greeting messages work with name', () {
        expect(pack.greetingMorning('User'), isNotEmpty);
        expect(pack.greetingAfternoon('User'), isNotEmpty);
        expect(pack.greetingEvening('User'), isNotEmpty);
      });

      test('error messages are non-empty', () {
        expect(pack.genericError, isNotEmpty);
        expect(pack.errorWith('test error'), isNotEmpty);
      });
    });
  }

  group('Tone static accessor', () {
    test('default tone is Friendly', () {
      expect(Tone.current.id, 'friendly');
    });

    test('sync changes active tone', () {
      Tone.sync(ProfessionalTonePack());
      expect(Tone.current.id, 'professional');

      // Reset
      Tone.sync(FriendlyTonePack());
      expect(Tone.current.id, 'friendly');
    });
  });
}

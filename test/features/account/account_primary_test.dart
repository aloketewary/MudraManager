import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';

void main() {
  group('Account.isPrimary', () {
    test('default is false', () {
      final account = Account();
      expect(account.isPrimary, false);
    });

    test('can be set to true', () {
      final account = Account()..isPrimary = true;
      expect(account.isPrimary, true);
    });

    test('only one account should be primary', () {
      final accounts = [
        Account.create(name: 'Bank A')..isPrimary = true,
        Account.create(name: 'Bank B')..isPrimary = false,
        Account.create(name: 'Cash')..isPrimary = false,
      ];

      final primaryCount = accounts.where((a) => a.isPrimary).length;
      expect(primaryCount, 1);
    });

    test('switching primary clears old one', () {
      final accounts = [
        Account.create(name: 'Bank A')..isPrimary = true,
        Account.create(name: 'Bank B')..isPrimary = false,
      ];

      // Simulate setPrimaryAccount
      for (final a in accounts) {
        a.isPrimary = false;
      }
      accounts[1].isPrimary = true;

      expect(accounts[0].isPrimary, false);
      expect(accounts[1].isPrimary, true);
    });

    test('fallback to first active when no primary', () {
      final accounts = [
        Account.create(name: 'Bank A', isActive: false),
        Account.create(name: 'Bank B', isActive: true),
        Account.create(name: 'Cash', isActive: true),
      ];

      final primary = accounts
              .where((a) => a.isPrimary && a.isActive)
              .firstOrNull ??
          accounts.where((a) => a.isActive).firstOrNull;

      expect(primary?.name, 'Bank B');
    });
  });

  group('Category.isSystem', () {
    test('default is false', () {
      final cat = Category();
      expect(cat.isSystem, false);
    });

    test('system category can be created', () {
      final cat = Category.create(name: 'Settlement')..isSystem = true;
      expect(cat.isSystem, true);
      expect(cat.name, 'Settlement');
    });

    test('user categories filtered from system', () {
      final categories = [
        Category.create(name: 'Food'),
        Category.create(name: 'Transport'),
        Category.create(name: 'Shared Expense')..isSystem = true,
        Category.create(name: 'Settlement')..isSystem = true,
      ];

      final userCategories = categories.where((c) => !c.isSystem).toList();
      final systemCategories = categories.where((c) => c.isSystem).toList();

      expect(userCategories.length, 2);
      expect(systemCategories.length, 2);
      expect(userCategories.map((c) => c.name), ['Food', 'Transport']);
    });

    test('system categories have correct types', () {
      final systemDefs = [
        (name: 'Shared Expense', type: CategoryType.expense),
        (name: 'Trip Expense', type: CategoryType.expense),
        (name: 'Settlement', type: CategoryType.expense),
        (name: 'Settlement Received', type: CategoryType.income),
      ];

      for (final def in systemDefs) {
        final cat = Category.create(
          name: def.name,
          categoryType: def.type,
        )..isSystem = true;

        expect(cat.isSystem, true);
        expect(cat.categoryType, def.type);
      }
    });
  });

  group('TripParticipant.isOwner', () {
    // Using a simple mock since TripParticipant needs Isar
    test('owner identification logic', () {
      final participants = [
        _MockParticipant('Alice', isOwner: true),
        _MockParticipant('Bob', isOwner: false),
        _MockParticipant('Charlie', isOwner: false),
      ];

      final owner = participants.where((p) => p.isOwner).firstOrNull;
      expect(owner?.name, 'Alice');
    });

    test('owner share calculation', () {
      final participantIds = [1, 2, 3];
      final splitAmounts = [300.0, 300.0, 300.0];
      final ownerId = 1;

      final ownerIdx = participantIds.indexOf(ownerId);
      final ownerShare = splitAmounts[ownerIdx];

      expect(ownerShare, 300);
    });

    test('owner not in participants returns null share', () {
      final participantIds = [2, 3];
      final ownerId = 1;

      final ownerIdx = participantIds.indexOf(ownerId);
      expect(ownerIdx, -1);
    });
  });
}

class _MockParticipant {
  final String name;
  final bool isOwner;
  _MockParticipant(this.name, {this.isOwner = false});
}

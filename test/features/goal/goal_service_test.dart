import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/features/goal/data/goal_provider.dart';

late Isar isar;
late Directory tmpDir;
late GoalService goalService;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({'smart_alerts_enabled': false});

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('goal_service_test_');
    final existing = Isar.getInstance();
    if (existing != null && existing.isOpen) await existing.close();

    isar = await Isar.open(
      [GoalSchema, AccountSchema],
      directory: tmpDir.path,
    );

    final isarService = IsarService();
    goalService = GoalService(isarService, null);
  });

  tearDown(() async {
    await isar.close();
    tmpDir.deleteSync(recursive: true);
  });

  group('GoalService.addGoal', () {
    test('stores goal in database', () async {
      final goal = Goal.create(
        name: 'Laptop',
        targetAmount: 80000,
        targetDate: DateTime(2026, 1, 1),
      );

      await goalService.addGoal(goal);

      final stored = await isar.goals.where().findAll();
      expect(stored.length, 1);
      expect(stored.first.targetAmount, 80000);
    });

    test('preserves all fields', () async {
      final goal = Goal.create(
        name: 'Vacation',
        targetAmount: 100000,
        targetDate: DateTime(2025, 12, 31),
      )
        ..currencyCode = 'INR'
        ..iconName = 'plane'
        ..colorValue = 0xFF2196F3
        ..description = 'Bali trip';

      await goalService.addGoal(goal);

      final stored = (await isar.goals.where().findAll()).first;
      expect(stored.currencyCode, 'INR');
      expect(stored.iconName, 'plane');
      expect(stored.colorValue, 0xFF2196F3);
      expect(stored.isActive, true);
    });

    test('multiple goals stored independently', () async {
      await goalService.addGoal(
        Goal.create(name: 'Goal A', targetAmount: 50000),
      );
      await goalService.addGoal(
        Goal.create(name: 'Goal B', targetAmount: 75000),
      );

      final stored = await isar.goals.where().findAll();
      expect(stored.length, 2);
    });
  });

  group('GoalService.addContribution', () {
    test('increases currentAmount', () async {
      final goal = Goal.create(name: 'Fund', targetAmount: 50000);
      await goalService.addGoal(goal);
      final id = (await isar.goals.where().findAll()).first.id;

      await goalService.addContribution(id, 5000);

      final updated = await isar.goals.get(id);
      expect(updated!.currentAmount, 5000);
    });

    test('appends to contributions list', () async {
      final goal = Goal.create(name: 'Fund', targetAmount: 50000);
      await goalService.addGoal(goal);
      final id = (await isar.goals.where().findAll()).first.id;

      await goalService.addContribution(id, 3000);
      await goalService.addContribution(id, 2000);

      final updated = await isar.goals.get(id);
      expect(updated!.contributions.length, 2);
      expect(updated.contributions[0].amount, 3000);
      expect(updated.contributions[1].amount, 2000);
    });

    test('updates lastContributionDate', () async {
      final goal = Goal.create(name: 'Fund', targetAmount: 50000);
      await goalService.addGoal(goal);
      final id = (await isar.goals.where().findAll()).first.id;

      final before = DateTime.now().subtract(const Duration(seconds: 1));
      await goalService.addContribution(id, 1000);

      final updated = await isar.goals.get(id);
      expect(updated!.lastContributionDate, isNotNull);
      expect(
        updated.lastContributionDate!.isAfter(before),
        true,
      );
    });

    test('accumulates correctly across multiple contributions', () async {
      final goal = Goal.create(name: 'Fund', targetAmount: 50000);
      await goalService.addGoal(goal);
      final id = (await isar.goals.where().findAll()).first.id;

      await goalService.addContribution(id, 10000);
      await goalService.addContribution(id, 15000);
      await goalService.addContribution(id, 5000);

      final updated = await isar.goals.get(id);
      expect(updated!.currentAmount, 30000);
      expect(updated.progressPercent, closeTo(0.6, 0.01));
    });

    test('completing goal sets progress to 100%', () async {
      final goal = Goal.create(name: 'Fund', targetAmount: 10000);
      await goalService.addGoal(goal);
      final id = (await isar.goals.where().findAll()).first.id;

      await goalService.addContribution(id, 10000);

      final updated = await isar.goals.get(id);
      expect(updated!.currentAmount, 10000);
      expect(updated.progressPercent, 1.0);
    });

    test('over-contributing is allowed', () async {
      final goal = Goal.create(name: 'Fund', targetAmount: 10000);
      await goalService.addGoal(goal);
      final id = (await isar.goals.where().findAll()).first.id;

      await goalService.addContribution(id, 12000);

      final updated = await isar.goals.get(id);
      expect(updated!.currentAmount, 12000);
      // progressPercent is clamped to 1.0 by the model
      expect(updated.progressPercent, 1.0);
    });
  });

  group('GoalService.updateGoal', () {
    test('updates name and target', () async {
      final goal = Goal.create(name: 'Old Name', targetAmount: 50000);
      await goalService.addGoal(goal);
      final stored = (await isar.goals.where().findAll()).first;

      stored.name = 'New Name';
      stored.targetAmount = 75000;
      await goalService.updateGoal(stored);

      final updated = await isar.goals.get(stored.id);
      expect(updated!.name, 'New Name');
      expect(updated.targetAmount, 75000);
    });
  });

  group('GoalService.deleteGoal', () {
    test('removes goal from database', () async {
      final goal = Goal.create(name: 'Delete Me', targetAmount: 10000);
      await goalService.addGoal(goal);
      final id = (await isar.goals.where().findAll()).first.id;

      await goalService.deleteGoal(id);

      final remaining = await isar.goals.where().findAll();
      expect(remaining, isEmpty);
    });

    test('only deletes the specified goal', () async {
      await goalService.addGoal(
        Goal.create(name: 'Keep', targetAmount: 10000),
      );
      await goalService.addGoal(
        Goal.create(name: 'Delete', targetAmount: 20000),
      );

      final goals = await isar.goals.where().findAll();
      final deleteId = goals.firstWhere((g) => g.name == 'Delete').id;

      await goalService.deleteGoal(deleteId);

      final remaining = await isar.goals.where().findAll();
      expect(remaining.length, 1);
      expect(remaining.first.name, 'Keep');
    });
  });

  group('GoalService.watchAll', () {
    test('emits initial data', () async {
      await goalService.addGoal(
        Goal.create(name: 'Watch Test', targetAmount: 10000),
      );

      final stream = goalService.watchAll();
      final first = await stream.first;
      expect(first.length, 1);
      expect(first.first.name, 'Watch Test');
    });
  });
}

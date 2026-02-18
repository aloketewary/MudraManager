import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/services/notification_service.dart';

final goalServiceProvider = Provider<GoalService>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return GoalService(isarService);
});

final goalsProvider = StreamProvider<List<Goal>>((ref) {
  final service = ref.watch(goalServiceProvider);
  return service.watchAll();
});

class GoalService {
  final IsarService isarService;

  GoalService(this.isarService);

  Future<void> addGoal(Goal goal) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      await isar.goals.put(goal);
    });
    await _updateGoalReminders();
  }

  Future<void> updateGoal(Goal goal) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      await isar.goals.put(goal);
    });
    await _updateGoalReminders();
  }

  Future<void> deleteGoal(int id) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      await isar.goals.delete(id);
    });
    await _updateGoalReminders();
  }

  Future<void> addContribution(int goalId, double amount) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      final goal = await isar.goals.get(goalId);
      if (goal != null) {
        goal.currentAmount += amount;
        await isar.goals.put(goal);
      }
    });
    await _updateGoalReminders();
  }

  Future<void> _updateGoalReminders() async {
    final isar = await isarService.getInstance();
    final goals = await isar.goals.where().findAll();
    if (goals.isEmpty) {
      // If we want to cancel the specific goal reminder ID, we should use that ID (1)
      // await NotificationService.cancelGoalReminder(); // if we added such a method
      return;
    }

    String summary = 'You have ${goals.length} active goals.';
    final topGoal = goals.reduce(
      (a, b) => a.progressPercent > b.progressPercent ? a : b,
    );
    summary +=
        ' ${topGoal.name} is ${(topGoal.progressPercent * 100).toStringAsFixed(0)}% complete!';

    await NotificationService.scheduleMonthlyGoalReminder(summary);
  }

  Stream<List<Goal>> watchAll() async* {
    final isar = await isarService.getInstance();
    yield* isar.goals.where().watch(fireImmediately: true);
  }
}

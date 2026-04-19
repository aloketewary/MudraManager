import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/services/notification_service.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/features/gamification/models/gamification_enum.dart';
import 'package:mudra_manager/features/gamification/providers/gamification_providers.dart';
import 'package:mudra_manager/features/gamification/services/gamification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final goalServiceProvider = Provider<GoalService>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  final gamificationService = ref.watch(gamificationServiceProvider);
  return GoalService(isarService, gamificationService);
});

final goalsProvider = StreamProvider.autoDispose<List<Goal>>((ref) {
  final service = ref.watch(goalServiceProvider);
  return service.watchAll();
});

class GoalService {
  final IsarService isarService;
  final GamificationService? gamificationService;

  GoalService(this.isarService, this.gamificationService);

  Future<void> addGoal(Goal goal) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      await isar.goals.put(goal);
    });
    await _updateGoalReminders();
    await gamificationService?.track(GamificationEvent.goalCreated);
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
    Goal? goal;
    await isar.writeTxn(() async {
      goal = await isar.goals.get(goalId);
      if (goal != null) {
        goal!.currentAmount += amount;
        goal!.contributions.add(GoalContribution.create(amount));
        await isar.goals.put(goal!);
      }
    });
    await _updateGoalReminders();
    if (goal != null && goal!.currentAmount >= goal!.targetAmount) {
      await gamificationService?.track(GamificationEvent.goalCompleted);
    }
  }

  Future<void> _updateGoalReminders() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('smart_alerts_enabled') ?? true)) return;

    final isar = await isarService.getInstance();
    final goals = await isar.goals.where().findAll();
    if (goals.isEmpty) {
      // If we want to cancel the specific goal reminder ID, we should use that ID (1)
      // await NotificationService.cancelGoalReminder(); // if we added such a method
      return;
    }

    final topGoal = goals.reduce(
      (a, b) => a.progressPercent > b.progressPercent ? a : b,
    );
    final pct = (topGoal.progressPercent * 100).toStringAsFixed(0);
    final summary = Tone.appL10n?.notif_goalStatusBody(goals.length, topGoal.name, pct) ??
        'You have ${goals.length} active goals. ${topGoal.name} is $pct% complete!';

    await NotificationService.scheduleMonthlyGoalReminder(summary);
  }

  Stream<List<Goal>> watchAll() async* {
    final isar = await isarService.getInstance();
    yield* isar.goals.where().watch(fireImmediately: true);
  }
}

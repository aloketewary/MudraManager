import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/features/gamification/models/achievement.dart';
import 'package:mudra_manager/features/gamification/services/gamification_service.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';

final gamificationServiceProvider = Provider<GamificationService?>((ref) {
  final asyncValue = ref.watch(gamificationServiceInitProvider);
  return asyncValue.valueOrNull;
});

final achievementsProvider = StreamProvider<List<Achievement>>((ref) async* {
  final service = await ref.watch(gamificationServiceInitProvider.future);
  yield* service.watchAchievements();
});

final streaksProvider = StreamProvider<List<Streak>>((ref) async* {
  final service = await ref.watch(gamificationServiceInitProvider.future);
  yield* service.watchStreaks();
});

final dailyStreakProvider = Provider<Streak?>((ref) {
  final streaksAsync = ref.watch(streaksProvider);
  return streaksAsync.maybeWhen(
    data: (streaks) => streaks.where((s) => s.type == 'daily_checkin').firstOrNull,
    orElse: () => null,
  );
});

final userLevelProvider = StreamProvider<UserLevel?>((ref) async* {
  final service = await ref.watch(gamificationServiceInitProvider.future);
  yield* service.watchUserLevel();
});

final dailyCheckInProvider = FutureProvider<String?>((ref) async {
  final service = await ref.watch(gamificationServiceInitProvider.future);
  return await service.updateDailyCheckIn();
});

final lastSeenLevelProvider = StateProvider<int?>((ref) => null);

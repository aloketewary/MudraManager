import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/features/gamification/models/achievement.dart';
import 'package:mudra_manager/features/gamification/services/gamification_service.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';

final gamificationServiceProvider = Provider<GamificationService>((ref) {
  return ref.watch(gamificationServiceInitProvider).maybeWhen(
    data: (service) => service,
    orElse: () => throw UnimplementedError('GamificationService not initialized'),
  );
});

final achievementsProvider = StreamProvider<List<Achievement>>((ref) {
  final service = ref.watch(gamificationServiceProvider);
  return service.watchAchievements();
});

final streaksProvider = StreamProvider<List<Streak>>((ref) {
  final service = ref.watch(gamificationServiceProvider);
  return service.watchStreaks();
});

final dailyStreakProvider = Provider<Streak?>((ref) {
  final streaksAsync = ref.watch(streaksProvider);
  return streaksAsync.maybeWhen(
    data: (streaks) => streaks.where((s) => s.type == 'daily_checkin').firstOrNull,
    orElse: () => null,
  );
});

final userLevelProvider = StreamProvider<UserLevel?>((ref) {
  final service = ref.watch(gamificationServiceProvider);
  return service.watchUserLevel();
});

final dailyCheckInProvider = FutureProvider<String?>((ref) async {
  final service = ref.watch(gamificationServiceProvider);
  return await service.updateDailyCheckIn();
});

final lastSeenLevelProvider = StateProvider<int?>((ref) => null);


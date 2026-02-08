// lib/providers/user_profile_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/db/isar_service.dart';
import 'package:mudra_manager/db/models/user_profile.dart' show GetUserProfileCollection, UserProfile, UserProfileQuerySortBy;

import 'isar_provider.dart';

final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return UserProfileService(isarService);
});

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final service = ref.watch(userProfileServiceProvider);
  return await service.getProfile();
});


class UserProfileService {
  final IsarService isarService;

  UserProfileService(this.isarService);

  Future<void> saveProfile(UserProfile profile) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      await isar.userProfiles.put(profile);
    });
  }

  Future<UserProfile?> getProfile() async {
    final isar = await isarService.getInstance();
    return await isar.userProfiles.where().findFirst();
  }
}

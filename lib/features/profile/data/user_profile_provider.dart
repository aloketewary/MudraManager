// lib/providers/user_profile_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/extensions/field_encryption_ext.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/user_profile.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';

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
    // Create a copy for storage so the caller's object stays decrypted
    final toStore = UserProfile()
      ..id = profile.id
      ..name = profile.name
      ..email = profile.email
      ..phone = profile.phone
      ..avatarIndex = profile.avatarIndex
      ..createdAt = profile.createdAt
      ..updateAt = profile.updateAt;
    toStore.encryptFields();
    await isar.writeTxn(() async {
      await isar.userProfiles.put(toStore);
    });
    // Sync the ID back in case it was a new profile
    profile.id = toStore.id;
  }

  Future<UserProfile?> getProfile() async {
    final isar = await isarService.getInstance();
    return await isar.userProfiles.where().findFirst().withDecryption();
  }
}

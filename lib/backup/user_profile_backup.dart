import 'package:mudra_manager/backup/backable_model.dart' show BackupAdapter, Backupable;
import 'package:mudra_manager/db/models/user_profile.dart' show UserProfile;

class UserProfileBackup implements BackupAdapter<UserProfile> {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final int? avatarIndex;
  final String createdAt;
  final String updatedAt;

  UserProfileBackup.fromUserProfile(UserProfile profile)
      : id = profile.id,
        name = profile.name,
        email = profile.email,
        phone = profile.phone,
        avatarIndex = profile.avatarIndex,
        createdAt = profile.createdAt.toIso8601String(),
        updatedAt = profile.updateAt.toIso8601String();

  UserProfileBackup():
      id = 0,
      name = '',
      email = '',
      phone = '',
      avatarIndex = 0,
      createdAt = '',
      updatedAt = '';

  @override
  Map<String, dynamic> toBackupJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'avatarIndex': avatarIndex,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  @override
  UserProfile fromBackupJson(Map<String, dynamic> json, Map<String, dynamic> linkedRefs) {
    final profile = UserProfile()
      ..id = json['id']
      ..name = json['name']
      ..email = json['email'] as String?
      ..phone = json['phone'] as String?
      ..avatarIndex = json['avatarIndex'] as int?
      ..createdAt = DateTime.parse(json['createdAt'])
      ..updateAt = DateTime.parse(json['updatedAt']);

    return profile;
  }
}
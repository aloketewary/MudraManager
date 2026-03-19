// lib/models/user_profile.dart

import 'package:isar_community/isar.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@collection
@JsonSerializable()
class UserProfile {
  Id id = Isar.autoIncrement;

  String? name;
  String? email;
  String? phone;
  int? avatarIndex; // Optional local path to an image
  DateTime createdAt = DateTime.now();
  DateTime updateAt = DateTime.now();

  UserProfile();

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
}

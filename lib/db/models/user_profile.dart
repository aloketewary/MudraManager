// lib/models/user_profile.dart

import 'package:isar/isar.dart';

part 'user_profile.g.dart';

@collection
class UserProfile {
  Id id = Isar.autoIncrement;

  late String name;
  String? email;
  String? phone;
  int? avatarIndex; // Optional local path to an image
  DateTime createdAt = DateTime.now();
  DateTime updateAt = DateTime.now();
}

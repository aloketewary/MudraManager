import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/features/backup/data/backable_model.dart';

class TagBackup implements BackupAdapter<Tag> {
  final int id;
  final String name;

  TagBackup.fromTag(Tag tag) : id = tag.id, name = tag.name;

  TagBackup() : id = 0, name = '';

  @override
  Map<String, dynamic> toBackupJson() => {'id': id, 'name': name};

  @override
  Tag fromBackupJson(
    Map<String, dynamic> json,
    Map<String, dynamic> linkedRefs,
  ) {
    final tag = Tag()
      ..id = json['id']
      ..name = json['name'];

    return tag;
  }
}

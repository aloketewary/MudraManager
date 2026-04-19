import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/providers/collection_watchers.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';


final tagListProvider = FutureProvider.autoDispose<List<Tag>>((ref) async {
  ref.watch(tagChangeProvider);
  final isarService = ref.watch(isarServiceProvider);
  final isar = await isarService.getInstance();
  return await isar.tags.where().sortByName().findAll();
});

final tagServiceProvider = Provider<TagService>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return TagService(isarService);
});

class TagService {
  final IsarService isarService;
  TagService(this.isarService);

  Future<List<Tag>> getAllTags() async {
    final isar = await isarService.getInstance();
    return await isar.tags.where().findAll();
  }

  Future<Tag> createTag(String name) async {
    final isar = await isarService.getInstance();
    final tag = Tag()..name = name;
    await isar.writeTxn(() async {
      await isar.tags.put(tag);
    });
    return tag;
  }
}
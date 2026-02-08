import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/db/isar_service.dart' show IsarService;
import 'package:mudra_manager/db/models/tag.dart' show GetTagCollection, Tag, TagQuerySortBy;
import 'package:mudra_manager/providers/isar_provider.dart';

final tagListProvider = FutureProvider<List<Tag>>((ref) async {
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
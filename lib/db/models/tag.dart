import 'package:isar/isar.dart';

part 'tag.g.dart';

@collection
class Tag {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value, unique: true, caseSensitive: false) // Ensure unique tag names
  late String name; // e.g., "Vacation2025", "Business Trip", "Project X"

  // Isar requires a default constructor
  Tag();

  // Optional: Convenience constructor
  Tag.create({required this.name});
}
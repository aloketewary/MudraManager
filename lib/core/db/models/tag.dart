import 'package:isar_community/isar.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tag.g.dart';

@collection
@JsonSerializable()
class Tag {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value, unique: true, caseSensitive: false) // Ensure unique tag names
  late String name; // e.g., "Vacation2025", "Business Trip", "Project X"

  // Isar requires a default constructor
  Tag();

  // Optional: Convenience constructor
  Tag.create({required this.name});

  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);
  Map<String, dynamic> toJson() => _$TagToJson(this);
}
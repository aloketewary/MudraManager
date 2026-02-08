import 'package:isar_community/isar.dart';

part 'backup_metadata.g.dart';

@collection
class BackupMetadata {
  Id id = Isar.autoIncrement;
  
  late DateTime backupDate;
  late int fileSize;
  late String fileName;
  String? filePath;
  late bool includesAttachments;
  late int recordCount;
  
  BackupMetadata();
  
  BackupMetadata.create({
    required this.backupDate,
    required this.fileSize,
    required this.fileName,
    this.filePath,
    required this.includesAttachments,
    required this.recordCount,
  });
}

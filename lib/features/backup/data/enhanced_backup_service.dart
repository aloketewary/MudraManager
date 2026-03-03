import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/services/backup_restore_service.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';

enum BackupMethod { local, shareToCloud }

class EnhancedBackupService extends BackupService {
  static final _log = AppLog(getLogger(), 'EnhancedBackupService');

  static Future<String?> createBackupWithShare(
    String password, {
    BackupMethod method = BackupMethod.local,
    bool includeAttachments = true,
  }) async {
    final localPath = await BackupService.createEncryptedBackup(
      password,
      includeAttachments: includeAttachments,
    );

    if (localPath == null) return null;

    if (method == BackupMethod.shareToCloud) {
      await shareBackupFile(localPath);
    }

    return localPath;
  }

  static Future<void> shareBackupFile(String filePath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = filePath.split('/').last;
      final tempFile = File('${tempDir.path}/$fileName');

      await File(filePath).copy(tempFile.path);
      await OpenFile.open(tempFile.path);

      _log.i('Backup file prepared for sharing: $fileName');
    } catch (e) {
      _log.e('Failed to share backup file', e);
    }
  }

  static Future<List<BackupInfo>> getAvailableBackups() async {
    final backups = <BackupInfo>[];

    final localBackups = await BackupService.getBackupHistory();
    for (final backup in localBackups) {
      backups.add(
        BackupInfo(
          id: backup.id.toString(),
          name: backup.fileName,
          size: backup.fileSize,
          date: backup.backupDate,
          location: BackupLocation.local,
          path: backup.filePath,
        ),
      );
    }

    backups.sort((a, b) => b.date.compareTo(a.date));
    return backups;
  }
}

enum BackupLocation { local }

class BackupInfo {
  final String id;
  final String name;
  final int size;
  final DateTime date;
  final BackupLocation location;
  final String? path;

  BackupInfo({
    required this.id,
    required this.name,
    required this.size,
    required this.date,
    required this.location,
    this.path,
  });
}

final enhancedBackupServiceProvider = Provider<EnhancedBackupService>((ref) {
  return EnhancedBackupService();
});

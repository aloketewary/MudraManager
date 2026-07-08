import 'dart:io';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/services/backup_restore_service.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AutoBackupService {
  static const String taskName = 'auto_backup_task';
  static const String _backupPasswordKey = 'auto_backup_password';
  static const int maxBackupAgeDays = 7;
  static const String _autoBackupPrefix = 'mudra_auto_';
  static final _log = AppLog(getLogger(), 'AutoBackup');
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<void> setBackupPassword(String password) async {
    await _storage.write(key: _backupPasswordKey, value: password);
  }

  static Future<String?> getBackupPassword() async {
    return await _storage.read(key: _backupPasswordKey);
  }

  static Future<void> scheduleAutoBackup(BackupFrequency frequency) async {
    await Workmanager().cancelByUniqueName(taskName);

    final hours = switch (frequency) {
      BackupFrequency.daily => 24,
      BackupFrequency.weekly => 168,
      BackupFrequency.monthly => 720,
      BackupFrequency.never => 0,
    };

    if (hours > 0) {
      await Workmanager().registerPeriodicTask(
        taskName,
        taskName,
        frequency: Duration(hours: hours),
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresCharging: false,
        ),
      );
      _log.i('Auto backup scheduled: every $hours hours');
    }
  }

  static Future<void> cancelAutoBackup() async {
    await Workmanager().cancelByUniqueName(taskName);
  }

  /// Create an auto backup with the rolling prefix.
  /// Returns the file path if successful.
  static Future<String?> createAutoBackup(String password, AppSpacing spacing) async {
    try {
      // Ensure Isar is initialized (critical for background isolate)
      await IsarService().getInstance();

      final directory = await getApplicationDocumentsDirectory();
      final dateTime = DateTime.now();
      final fileName =
          '$_autoBackupPrefix${DateFormat('yyyyMMdd_HHmmss').format(dateTime)}.mudra';
      final content = await _createBackupBytes(password, spacing);
      if (content == null) return null;

      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(content);
      _log.i('Auto backup created: $fileName');
      return file.path;
    } catch (e) {
      _log.e('Auto backup creation failed', e);
      return null;
    }
  }

  static Future<List<int>?> _createBackupBytes(String password, AppSpacing spacing,) async {
    final path = await BackupService.createEncryptedBackup(
      password, spacing,
      interactive: false,
    );
    if (path == null) return null;

    final file = File(path);
    final bytes = await file.readAsBytes();

    try {
      await file.delete();
    } catch (_) {}

    return bytes;
  }

  /// Delete auto backups older than [maxBackupAgeDays].
  /// Keeps manual backups (those without the auto prefix) untouched.
  static Future<int> cleanupOldBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cutoff = DateTime.now().subtract(
        const Duration(days: maxBackupAgeDays),
      );
      int deleted = 0;

      final files = directory.listSync().whereType<File>().where((f) {
        final name = f.path.split('/').last;
        return name.startsWith(_autoBackupPrefix) && name.endsWith('.mudra');
      }).toList();

      for (final file in files) {
        final date = _parseDateFromFilename(file.path.split('/').last);
        if (date != null && date.isBefore(cutoff)) {
          await file.delete();
          deleted++;
          _log.d('Deleted old auto backup: ${file.path.split('/').last}');
        }
      }

      if (deleted > 0) {
        _log.i('Cleaned up $deleted old auto backup(s)');
      }
      return deleted;
    } catch (e) {
      _log.e('Cleanup failed', e);
      return 0;
    }
  }

  /// Parse date from filename like `mudra_auto_20260424_121600.mudra`
  static DateTime? _parseDateFromFilename(String filename) {
    try {
      final withoutPrefix = filename.replaceFirst(_autoBackupPrefix, '');
      final withoutExt = withoutPrefix.replaceFirst('.mudra', '');
      return DateFormat('yyyyMMdd_HHmmss').parse(withoutExt);
    } catch (_) {
      return null;
    }
  }

  /// List all auto backup files sorted by date (newest first).
  static Future<List<AutoBackupInfo>> listAutoBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync().whereType<File>().where((f) {
        final name = f.path.split('/').last;
        return name.startsWith(_autoBackupPrefix) && name.endsWith('.mudra');
      }).toList();

      final backups = <AutoBackupInfo>[];
      for (final file in files) {
        final name = file.path.split('/').last;
        final date = _parseDateFromFilename(name);
        if (date != null) {
          backups.add(AutoBackupInfo(
            path: file.path,
            name: name,
            date: date,
            size: file.lengthSync(),
          ),);
        }
      }

      backups.sort((a, b) => b.date.compareTo(a.date));
      return backups;
    } catch (e) {
      _log.e('List auto backups failed', e);
      return [];
    }
  }
}

class AutoBackupInfo {
  final String path;
  final String name;
  final DateTime date;
  final int size;

  AutoBackupInfo({
    required this.path,
    required this.name,
    required this.date,
    required this.size,
  });
}

enum BackupFrequency { never, daily, weekly, monthly }

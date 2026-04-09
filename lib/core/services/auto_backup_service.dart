import 'package:mudra_manager/core/services/backup_restore_service.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AutoBackupService {
  static const String taskName = 'auto_backup_task';
  static const String _backupPasswordKey = 'auto_backup_password';
  static final _log = AppLog(getLogger(), 'AutoBackup');
  static const _storage = FlutterSecureStorage();

  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);
  }

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
          networkType: NetworkType.connected,
          requiresCharging: false,
        ),
      );
      _log.i('Auto backup scheduled: every $hours hours');
    }
  }

  static Future<void> cancelAutoBackup() async {
    await Workmanager().cancelByUniqueName(taskName);
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  final log = AppLog(getLogger(), 'AutoBackup');
  Workmanager().executeTask((task, inputData) async {
    if (task == AutoBackupService.taskName) {
      try {
        final password = await AutoBackupService.getBackupPassword();
        if (password == null || password.isEmpty) {
          log.w('No backup password set, skipping auto backup');
          return true;
        }
        await BackupService.createEncryptedBackup(password, interactive: false);
        log.i('Auto backup completed');
        return true;
      } catch (e) {
        log.e('Auto backup failed', e);
        return false;
      }
    }
    return false;
  });
}

enum BackupFrequency { never, daily, weekly, monthly }

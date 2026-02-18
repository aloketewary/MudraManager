import 'package:mudra_manager/core/services/backup_restore_service.dart';
import 'package:workmanager/workmanager.dart';

class AutoBackupService {
  static const String taskName = 'auto_backup_task';

  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);
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
    }
  }

  static Future<void> cancelAutoBackup() async {
    await Workmanager().cancelByUniqueName(taskName);
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == AutoBackupService.taskName) {
      try {
        await BackupService.createEncryptedBackup('default_password');
        return true;
      } catch (e) {
        return false;
      }
    }
    return false;
  });
}

enum BackupFrequency { never, daily, weekly, monthly }

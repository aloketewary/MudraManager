import 'package:mudra_manager/features/backup/data/enhanced_backup_service.dart';

class BackupConfig {
  final bool autoBackupEnabled;
  final int autoBackupFrequencyDays;
  final BackupMethod preferredMethod;
  final bool includeAttachments;
  final bool encryptionEnabled;
  final int maxBackupsToKeep;

  const BackupConfig({
    this.autoBackupEnabled = false,
    this.autoBackupFrequencyDays = 7,
    this.preferredMethod = BackupMethod.local,
    this.includeAttachments = true,
    this.encryptionEnabled = true,
    this.maxBackupsToKeep = 10,
  });

  BackupConfig copyWith({
    bool? autoBackupEnabled,
    int? autoBackupFrequencyDays,
    BackupMethod? preferredMethod,
    bool? includeAttachments,
    bool? encryptionEnabled,
    int? maxBackupsToKeep,
  }) {
    return BackupConfig(
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      autoBackupFrequencyDays: autoBackupFrequencyDays ?? this.autoBackupFrequencyDays,
      preferredMethod: preferredMethod ?? this.preferredMethod,
      includeAttachments: includeAttachments ?? this.includeAttachments,
      encryptionEnabled: encryptionEnabled ?? this.encryptionEnabled,
      maxBackupsToKeep: maxBackupsToKeep ?? this.maxBackupsToKeep,
    );
  }

  Map<String, dynamic> toJson() => {
    'autoBackupEnabled': autoBackupEnabled,
    'autoBackupFrequencyDays': autoBackupFrequencyDays,
    'preferredMethod': preferredMethod.index,
    'includeAttachments': includeAttachments,
    'encryptionEnabled': encryptionEnabled,
    'maxBackupsToKeep': maxBackupsToKeep,
  };

  factory BackupConfig.fromJson(Map<String, dynamic> json) => BackupConfig(
    autoBackupEnabled: json['autoBackupEnabled'] ?? false,
    autoBackupFrequencyDays: json['autoBackupFrequencyDays'] ?? 7,
    preferredMethod: BackupMethod.values[json['preferredMethod'] ?? 0],
    includeAttachments: json['includeAttachments'] ?? true,
    encryptionEnabled: json['encryptionEnabled'] ?? true,
    maxBackupsToKeep: json['maxBackupsToKeep'] ?? 10,
  );
}
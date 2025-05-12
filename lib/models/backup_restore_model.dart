
class BackupData {
  final bool includeDatabase;
  final bool includeSettings;

  BackupData({
    required this.includeDatabase,
    required this.includeSettings,
  });

  Map<String, dynamic> toJson() => {
    'includeDatabase': includeDatabase,
    'includeSettings': includeSettings,
  };

  static BackupData fromJson(Map<String, dynamic> json) => BackupData(
    includeDatabase: json['includeDatabase'] ?? false,
    includeSettings: json['includeSettings'] ?? false,
  );
}

enum BackupOption { database, settings }
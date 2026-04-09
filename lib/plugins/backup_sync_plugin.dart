import 'package:mudra_plugin_sdk/mudra_plugin_sdk.dart';

class BackupSyncPlugin extends MudraPlugin {
  @override
  String get id => 'com.mudra.backup_sync';

  @override
  String get name => 'Backup & Sync';

  @override
  String get version => '1.0.0';

  /// Host app uses this to resolve the correct settings screen.
  String get settingsRoute => '/backup-sync';

  @override
  void onLoad() {}

  @override
  void onStart() {}
}

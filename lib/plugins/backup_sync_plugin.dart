import 'package:mudra_plugin_sdk/mudra_plugin_sdk.dart';
import 'package:mudra_manager/features/backup/presentation/backup_sync_screen.dart';
import 'package:flutter/material.dart';

class BackupSyncPlugin extends MudraPlugin {
  @override
  String get id => 'com.mudra.backup_sync';

  @override
  String get name => 'Backup & Sync';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Backup data locally and share to cloud';

  @override
  String get author => 'Mudra Team';

  @override
  Widget? get settingsWidget => const BackupSyncScreen();

  @override
  void onLoad() {}

  @override
  void onStart() {}
}

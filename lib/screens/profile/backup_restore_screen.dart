import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/providers/isar_provider.dart';
import 'package:mudra_manager/providers/shared_preference_provider.dart';
import 'package:mudra_manager/screens/profile/profile_tile.dart';
import 'package:mudra_manager/service/backup_restore_service.dart'
    show BackupService;

class BackupRestoreScreen extends ConsumerWidget {
  const BackupRestoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Backup & Restore",
          style: textTheme.titleLarge?.copyWith(color: color.onPrimary),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileTile(
              title: "Backup Data",
              subtitle: "You can backup all db and settings data",
              icon: Icons.backup_outlined,
              onTap: () async {
                await BackupService.createEncryptedBackup();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Backup completed")),
                );
              },
            ),
            ProfileTile(
              title: "Restore Backup",
              subtitle: "Restore full db and settings data",
              icon: Icons.restore_outlined,
              onTap: () async {
                final isar = await ref.read(isarServiceProvider).getInstance();
                final data = await BackupService.restoreEncryptedBackup(context, isar);
                if (data != null) {
                  // await restoreAppFromJson(data); // your data restorer
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Restore successful")),
                  );
                }
              },
            ),
            Divider(),
            FutureBuilder<DateTime?>(
              future: SharedPrefsUtil.instance.getLastBackupDate(),
              builder:
                  (_, snapshot) => Text(
                    snapshot.hasData
                        ? "Last backup: ${DateFormat.yMd().add_jm().format(snapshot.data!)}"
                        : "No backup found",
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

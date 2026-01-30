import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/providers/isar_provider.dart';
import 'package:mudra_manager/providers/shared_preference_provider.dart';
import 'package:mudra_manager/service/backup_restore_service.dart' show BackupService;
import 'package:mudra_manager/util/snackbar_service.dart';

class BackupRestoreScreen extends ConsumerWidget {
  const BackupRestoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Backup & Restore")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingCard(context, color, textTheme, Icons.backup_outlined, "Backup Data", "Export all database and settings", () async {
            HapticFeedback.mediumImpact();
            await BackupService.createEncryptedBackup();
            SnackbarService.success("Backup completed");
          }),
          SizedBox(height: 8),
          _buildSettingCard(context, color, textTheme, Icons.restore_outlined, "Restore Backup", "Import database and settings", () async {
            HapticFeedback.mediumImpact();
            final isar = await ref.read(isarServiceProvider).getInstance();
            final data = await BackupService.restoreEncryptedBackup(context, isar);
            if (data != null) {
              SnackbarService.success("Restore successful");
            }
          }),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.surfaceContainerHighest, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.outlineVariant.withValues(alpha: 0.5))),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: color.primary, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: FutureBuilder<DateTime?>(
                    future: SharedPrefsUtil.instance.getLastBackupDate(),
                    builder: (_, snapshot) => Text(
                      snapshot.hasData ? "Last backup: ${DateFormat.yMd().add_jm().format(snapshot.data!)}" : "No backup found",
                      style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(BuildContext context, ColorScheme color, TextTheme textTheme, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: color.primary.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color.primary, size: 24)),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text(subtitle, style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

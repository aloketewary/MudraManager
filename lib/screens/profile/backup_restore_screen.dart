import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/providers/isar_provider.dart';
import 'package:mudra_manager/providers/shared_preference_provider.dart';
import 'package:mudra_manager/service/backup_restore_service.dart' show BackupService;
import 'package:mudra_manager/theme/app_colors.dart';
import 'package:mudra_manager/util/dialog_utils.dart';
import 'package:mudra_manager/util/snackbar_service.dart';

class BackupRestoreScreen extends ConsumerWidget {
  const BackupRestoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Backup & Restore")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingCard(context, ref, color, textTheme, isDark, Icons.backup_outlined, "Backup Data", "Export all database and settings", () async {
            HapticFeedback.mediumImpact();
            final password = await DialogUtils.showPasswordDialog(context, isRestore: false);
            if (password == null) return;
            
            final includeAttachments = await DialogUtils.showConfirmation(
              context,
              title: 'Include Attachments?',
              message: 'Include receipt images in backup? This will increase file size.',
              confirmText: 'Yes',
              cancelText: 'No',
              icon: Icons.attach_file,
            );
            
            final filePath = await BackupService.createEncryptedBackup(password, includeAttachments: includeAttachments ?? false);
            if (filePath != null) {
              SnackbarService.success("Backup completed");
            }
          }),
          SizedBox(height: 8),
          _buildSettingCard(context, ref, color, textTheme, isDark, Icons.restore_outlined, "Restore Backup", "Import database and settings", () async {
            HapticFeedback.mediumImpact();
            final password = await DialogUtils.showPasswordDialog(context, isRestore: true);
            if (password == null) return;
            
            final isar = await ref.read(isarServiceProvider).getInstance();
            final data = await BackupService.restoreEncryptedBackup(context, isar, password);
            if (data != null) {
              SnackbarService.success("Restore successful");
            }
          }),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.glassGradient(color.primary, isDark),
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.primary.withValues(alpha: 0.3), width: 1.5),
              boxShadow: AppColors.glassShadow(color.primary, isDark),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: color.primary, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: FutureBuilder<DateTime?>(
                    future: SharedPrefsUtil.instance.getLastBackupDate(),
                    builder: (_, snapshot) => Text(
                      snapshot.hasData ? "Last backup: ${DateFormat.yMd().add_jm().format(snapshot.data!)}" : "No backup found",
                      style: textTheme.bodySmall?.copyWith(color: color.primary),
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

  Widget _buildSettingCard(BuildContext context, WidgetRef ref, ColorScheme color, TextTheme textTheme, bool isDark, IconData icon, String title, String subtitle, VoidCallback onTap) {
    final gradientColors = AppColors.glassGradient(color.primary, isDark);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.primary.withValues(alpha: 0.3), width: 1.5),
          boxShadow: AppColors.glassShadow(color.primary, isDark),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.primary.withValues(alpha: 0.2), blurRadius: 8, offset: Offset(0, 2))]),
              child: Icon(icon, color: color.primary, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: color.primary)),
                  SizedBox(height: 2),
                  Text(subtitle, style: textTheme.bodySmall?.copyWith(color: color.primary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.primary),
          ],
        ),
      ),
    );
  }
}

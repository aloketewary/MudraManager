import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/services/backup_restore_service.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';

final _dateFormatter = DateFormat.yMd().add_jm();

class BackupRestoreScreen extends ConsumerWidget {
  const BackupRestoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(ctxt.backup_backupRestoreTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: color.surfaceContainerHighest,
            child: InkWell(
              onTap: () async {
                HapticFeedback.mediumImpact();
                final password = await DialogUtils.showPasswordDialog(
                  context,
                  isRestore: false,
                );
                if (password == null) return;

                final includeAttachments = await DialogUtils.showConfirmation(
                  context,
                  title: ctxt.backup_includeAttachmentsTitle,
                  message: ctxt.backup_includeAttachmentsMessage,
                  confirmText: ctxt.backup_yesLabel,
                  cancelText: ctxt.backup_noLabel,
                  icon: Icons.attach_file,
                );

                final filePath = await BackupService.createEncryptedBackup(
                  password,
                  includeAttachments: includeAttachments ?? false,
                );
                if (filePath != null) {
                  SnackbarService.success(ctxt.backup_completedMessage);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.backup_outlined,
                        color: color.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ctxt.backup_backupDataTitle,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ctxt.backup_backupDataSubtitle,
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: color.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: color.surfaceContainerHighest,
            child: InkWell(
              onTap: () async {
                HapticFeedback.mediumImpact();
                final password = await DialogUtils.showPasswordDialog(
                  context,
                  isRestore: true,
                );
                if (password == null) return;

                final isar = await ref.read(isarServiceProvider).getInstance();
                final data = await BackupService.restoreEncryptedBackup(
                  context,
                  isar,
                  password,
                );
                if (data != null) {
                  SnackbarService.success(ctxt.backup_restoreSuccessMessage);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.restore_outlined,
                        color: color.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ctxt.backup_restoreBackupTitle,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ctxt.backup_restoreBackupSubtitle,
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: color.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            color: color.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: color.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FutureBuilder<DateTime?>(
                      future: SharedPrefsUtil.instance.getLastBackupDate(),
                      builder: (_, snapshot) => Text(
                        snapshot.hasData
                            ? ctxt.backup_lastBackupLabel(
                                _dateFormatter.format(snapshot.data!),
                              )
                            : ctxt.backup_noBackupFoundLabel,
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

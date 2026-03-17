// lib/features/profile/presentation/screens/backup_restore_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/backup_metadata.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/services/backup_restore_service.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/gamification/models/gamification_enum.dart';
import 'package:mudra_manager/features/gamification/providers/gamification_providers.dart';

final _backupHistoryProvider = FutureProvider.autoDispose((ref) {
  return BackupService.getBackupHistory();
});

class BackupRestoreScreen extends ConsumerWidget {
  const BackupRestoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctxt = AppLocalizations.of(context)!;
    final historyAsync = ref.watch(_backupHistoryProvider);

    final lastBackup = historyAsync.valueOrNull?.isNotEmpty == true
        ? historyAsync.value!.first
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(ctxt.backup_backupRestoreTitle)),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.cardHorizontal,
          vertical: spacing.cardVertical,
        ),
        children: [
          // ── HERO STATUS CARD ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.primary.withValues(alpha: isDark ? 0.2 : 0.12),
                  color.primaryContainer.withValues(alpha: 0.4),
                ],
              ),
              border: Border.all(
                color: color.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutBack,
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      lastBackup != null
                          ? LucideIcons.shieldCheck
                          : LucideIcons.shieldAlert,
                      color: color.primary,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lastBackup != null ? 'Last backup' : 'No backups yet',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: color.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastBackup != null
                            ? _formatRelativeDate(lastBackup.backupDate)
                            : 'Create your first backup to protect your data',
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── ACTIONS ──
          _buildSectionHeader('Actions', color, textTheme),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: color.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              side: BorderSide(
                color: color.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildActionRow(
                  icon: LucideIcons.cloudUpload,
                  title: ctxt.backup_backupDataTitle,
                  subtitle: ctxt.backup_backupDataSubtitle,
                  color: color,
                  textTheme: textTheme,
                  onTap: () => _performBackup(context, ref, ctxt),
                ),
                Divider(
                  height: 1,
                  indent: 58,
                  color: color.outlineVariant.withValues(alpha: 0.4),
                ),
                _buildActionRow(
                  icon: LucideIcons.cloudDownload,
                  title: ctxt.backup_restoreBackupTitle,
                  subtitle: ctxt.backup_restoreBackupSubtitle,
                  color: color,
                  textTheme: textTheme,
                  onTap: () => _performRestore(context, ref, ctxt),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── BACKUP HISTORY ──
          _buildSectionHeader('History', color, textTheme),
          const SizedBox(height: 10),
          historyAsync.when(
            data: (history) {
              if (history.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    color: color.surfaceContainerLow,
                    border: Border.all(
                      color: color.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.archiveX,
                        size: 36,
                        color: color.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No backup history',
                        style: textTheme.bodyMedium?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                color: color.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  side: BorderSide(
                    color: color.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children:
                      history.take(5).toList().asMap().entries.map((entry) {
                    final backup = entry.value;
                    final isLast = entry.key ==
                        (history.length > 5 ? 4 : history.length - 1);
                    return Column(
                      children: [
                        _buildHistoryRow(
                          backup: backup,
                          color: color,
                          textTheme: textTheme,
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            indent: 58,
                            color: color.outlineVariant.withValues(alpha: 0.4),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),

          // ── INFO ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              color: color.primary.withValues(alpha: 0.06),
              border: Border.all(
                color: color.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.info, color: color.primary, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Backups are encrypted with your password and saved as .mudra files. Keep your password safe — it cannot be recovered.',
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                      height: 1.4,
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

  // ── BUILDERS ──

  Widget _buildSectionHeader(
    String title,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: color.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required ColorScheme color,
    required TextTheme textTheme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall
                        ?.copyWith(color: color.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: color.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryRow({
    required BackupMetadata backup,
    required ColorScheme color,
    required TextTheme textTheme,
  }) {
    final dateStr = DateFormat.yMMMd().add_jm().format(backup.backupDate);
    final sizeStr = _formatFileSize(backup.fileSize);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.tertiary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(LucideIcons.archive, color: color.tertiary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${backup.recordCount} records',
                      style: textTheme.bodySmall
                          ?.copyWith(color: color.onSurfaceVariant),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      sizeStr,
                      style: textTheme.bodySmall
                          ?.copyWith(color: color.onSurfaceVariant),
                    ),
                    if (backup.includesAttachments) ...[
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      Icon(
                        LucideIcons.paperclip,
                        size: 12,
                        color: color.onSurfaceVariant,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── ACTIONS ──

  Future<void> _performBackup(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations ctxt,
  ) async {
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
      ref.invalidate(_backupHistoryProvider);
      ref
          .read(gamificationServiceProvider)
          ?.track(GamificationEvent.backupCreated);
    }
  }

  Future<void> _performRestore(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations ctxt,
  ) async {
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
      ref.invalidate(_backupHistoryProvider);
    }
  }

  // ── HELPERS ──

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatRelativeDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.yMMMd().format(date);
  }
}

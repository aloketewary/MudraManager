import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/core/entitlement/entitlement_feature.dart';
import 'package:mudra_manager/core/utils/safe_date_format.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:mudra_manager/core/services/google_drive_service.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/backup_metadata.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/services/backup_restore_service.dart';
import 'package:mudra_manager/core/services/auto_backup_service.dart';
import 'package:mudra_manager/shared/widgets/pro_gate.dart';
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

    final lastBackup = historyAsync.value?.isNotEmpty == true
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
                  color.primary.withValues(alpha: isDark ? 0.08 : 0.04),
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
                        lastBackup != null ? ctxt.backup_lastBackup : ctxt.backup_noBackups,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: color.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastBackup != null
                            ? _formatRelativeDate(lastBackup.backupDate, ctxt)
                            : ctxt.backup_createFirst,
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
          _buildSectionHeader(ctxt.backup_actions, color, textTheme),
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

          // ── CLOUD BACKUP (Pro) ──
          _buildSectionHeader(ctxt.backup_cloudBackup, color, textTheme, isPro: true),
          const SizedBox(height: 10),
          ProGate(
            feature: ProFeature.cloudBackup,
            child: _CloudBackupSection(color: color, textTheme: textTheme, spacing: spacing),
          ),
          const SizedBox(height: 24),

          // ── AUTO BACKUP (Pro) ──
          _buildSectionHeader(ctxt.backup_autoBackup, color, textTheme, isPro: true),
          const SizedBox(height: 10),
          ProGate(
            feature: ProFeature.autoBackup,
            child: _AutoBackupSection(color: color, textTheme: textTheme, spacing: spacing),
          ),
          const SizedBox(height: 24),

          // ── BACKUP HISTORY ──
          _buildSectionHeader(ctxt.backup_history, color, textTheme),
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
                        ctxt.backup_noHistory,
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
                        _buildHistoryRow(ctxt: ctxt, 
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
                    ctxt.backup_infoText,
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
    TextTheme textTheme, {
    bool isPro = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color.primary,
              letterSpacing: 0.5,
            ),
          ),
          if (isPro) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                'PRO',
                style: textTheme.labelSmall?.copyWith(
                  color: const Color(0xFFD4AF37),
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ],
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
                borderRadius: BorderRadius.circular(Tone.current.borderRadius),
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
              LucideIcons.chevronRight,
              color: color.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryRow({
    required AppLocalizations ctxt, required BackupMetadata backup,
    required ColorScheme color,
    required TextTheme textTheme,
  }) {
    final dateStr = safeDateFormat('yMMMd',).add_jm().format(backup.backupDate);
    final sizeStr = _formatFileSize(backup.fileSize);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.tertiary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Tone.current.borderRadius),
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
                      ctxt.backup_recordCount(backup.recordCount),
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
    if (password == null || !context.mounted) return;

    final includeAttachments = await DialogUtils.showConfirmation(
      context,
      title: ctxt.backup_includeAttachmentsTitle,
      message: ctxt.backup_includeAttachmentsMessage,
      confirmText: ctxt.backup_yesLabel,
      cancelText: ctxt.backup_noLabel,
      icon: LucideIcons.paperclip,
    );

    final filePath = await BackupService.createEncryptedBackup(
      password,
      includeAttachments: includeAttachments ?? false,
    );
    if (filePath != null) {
      SnackbarService.success(BuddyMessages.backupSuccess);
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
    if (!context.mounted) return;
    final data = await BackupService.restoreEncryptedBackup(
      context,
      isar,
      password,
    );
    if (data != null) {
      SnackbarService.success(BuddyMessages.restoreSuccess);
      ref.invalidate(_backupHistoryProvider);
    }
  }

  // ── HELPERS ──

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatRelativeDate(DateTime date, AppLocalizations ctxt) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return ctxt.backup_justNow;
    if (diff.inHours < 1) return ctxt.backup_minutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return ctxt.backup_hoursAgo(diff.inHours);
    if (diff.inDays < 7) return ctxt.backup_daysAgo(diff.inDays);
    return safeDateFormat('yMMMd', ctxt.localeName).format(date);
  }
}

class _CloudBackupSection extends ConsumerStatefulWidget {
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;

  const _CloudBackupSection({
    required this.color,
    required this.textTheme,
    required this.spacing,
  });

  @override
  ConsumerState<_CloudBackupSection> createState() =>
      _CloudBackupSectionState();
}

class _CloudBackupSectionState extends ConsumerState<_CloudBackupSection> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final textTheme = widget.textTheme;
    final spacing = widget.spacing;
    final ctxt = AppLocalizations.of(context)!;
    final isSignedIn = ref.watch(driveSignedInProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isSignedIn) {
      return _buildSignInCard(color, textTheme, spacing, ctxt, isDark);
    }

    return _buildCloudActions(color, textTheme, spacing, ctxt, isDark);
  }

  Widget _buildSignInCard(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
            LucideIcons.cloudOff,
            size: 36,
            color: color.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            ctxt.backup_signInRequired,
            style: textTheme.bodyMedium?.copyWith(
              color: color.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isLoading ? null : _signIn,
            icon: const Icon(LucideIcons.logIn, size: 18),
            label: Text(ctxt.backup_signInGoogle),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudActions(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
    bool isDark,
  ) {
    final driveBackups = ref.watch(driveBackupsProvider);
    final email = ref.watch(driveEmailProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Signed-in status + actions
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
              // Signed-in pill
              if (email != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Icon(LucideIcons.circleCheck,
                          size: 16, color: color.primary,),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ctxt.backup_signedInAs(email),
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: _signOut,
                        child: Text(
                          ctxt.backup_signOut,
                          style: textTheme.labelSmall?.copyWith(
                            color: color.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Upload to Drive
              InkWell(
                onTap: _isLoading ? null : _uploadToDrive,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(Tone.current.borderRadius),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: color.primary,
                                ),
                              )
                            : Icon(LucideIcons.cloudUpload,
                                color: color.primary, size: 20,),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ctxt.backup_cloudBackup,
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              ctxt.backup_cloudSubtitle,
                              style: textTheme.bodySmall?.copyWith(
                                color: color.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(LucideIcons.chevronRight,
                          color: color.onSurfaceVariant, size: 20,),
                    ],
                  ),
                ),
              ),
              Divider(
                height: 1,
                indent: 58,
                color: color.outlineVariant.withValues(alpha: 0.4),
              ),
              // Restore from Drive
              InkWell(
                onTap: _isLoading ? null : () => _showCloudRestoreSheet(ctxt),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(Tone.current.borderRadius),
                        ),
                        child: Icon(LucideIcons.cloudDownload,
                            color: color.primary, size: 20,),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ctxt.backup_cloudRestore,
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              ctxt.backup_cloudBackups,
                              style: textTheme.bodySmall?.copyWith(
                                color: color.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Show count badge if backups exist
                      driveBackups.maybeWhen(
                        data: (backups) => backups.isNotEmpty
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2,),
                                decoration: BoxDecoration(
                                  color: color.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(Tone.current.borderRadius),
                                ),
                                child: Text(
                                  '${backups.length}',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: color.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                        orElse: () => const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 8),
                      Icon(LucideIcons.chevronRight,
                          color: color.onSurfaceVariant, size: 20,),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      final success = await GoogleDriveService.signIn();
      if (success) {
        ref.read(driveSignedInProvider.notifier).set(true);
        ref.read(driveEmailProvider.notifier).set(
            GoogleDriveService.userEmail,
        );
        ref.invalidate(driveBackupsProvider);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await GoogleDriveService.signOut();
    ref.read(driveSignedInProvider.notifier).set(false);
    ref.read(driveEmailProvider.notifier).set(null);
  }

  Future<void> _uploadToDrive() async {
    final ctxt = AppLocalizations.of(context)!;
    final password = await DialogUtils.showPasswordDialog(
      context,
      isRestore: false,
    );
    if (password == null || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final localPath = await BackupService.createEncryptedBackup(
        password,
        interactive: false,
      );
      if (localPath == null) {
        SnackbarService.error(BuddyMessages.backupFailed);
        return;
      }

      final uploaded = await GoogleDriveService.uploadBackup(localPath);
      if (uploaded) {
        SnackbarService.success(ctxt.backup_uploadSuccess);
        ref.invalidate(driveBackupsProvider);
        ref.invalidate(_backupHistoryProvider);
      } else {
        SnackbarService.error(ctxt.backup_uploadFailed);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCloudRestoreSheet(AppLocalizations ctxt) {
    final driveBackups = ref.read(driveBackupsProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Tone.current.borderRadius * 2)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) {
          final color = Theme.of(context).colorScheme;
          final textTheme = Theme.of(context).textTheme;

          return Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: color.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  ctxt.backup_cloudBackups,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: driveBackups.when(
                  data: (backups) {
                    if (backups.isEmpty) {
                      return Center(
                        child: Text(
                          ctxt.backup_noCloudBackups,
                          style: textTheme.bodyMedium?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      itemCount: backups.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        indent: 58,
                        color: color.outlineVariant.withValues(alpha: 0.4),
                      ),
                      itemBuilder: (_, i) {
                        final backup = backups[i];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.tertiary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(Tone.current.borderRadius),
                            ),
                            child: Icon(LucideIcons.cloud,
                                color: color.tertiary, size: 20,),
                          ),
                          title: Text(
                            backup.name,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '${_formatFileSize(backup.size)} • ${safeDateFormat('yMMMd').add_jm().format(backup.date)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                          trailing: Icon(LucideIcons.download,
                              color: color.primary, size: 20,),
                          onTap: () {
                            Navigator.pop(context);
                            _restoreFromDrive(backup);
                          },
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => Center(
                    child: Text(
                      'Failed to load cloud backups',
                      style: textTheme.bodyMedium?.copyWith(
                        color: color.error,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _restoreFromDrive(DriveBackupInfo backup) async {
    final ctxt = AppLocalizations.of(context)!;
    final password = await DialogUtils.showPasswordDialog(
      context,
      isRestore: true,
    );
    if (password == null || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final localPath = await GoogleDriveService.downloadBackup(backup.id);
      if (localPath == null) {
        SnackbarService.error(ctxt.backup_uploadFailed);
        return;
      }

      final isar = await ref.read(isarServiceProvider).getInstance();
      if (!mounted) return;

      // Read the downloaded file and restore
      final file = File(localPath);
      final fileContent = await file.readAsString();
      final backupData = jsonDecode(fileContent);

      final key = BackupService.deriveKey(password);
      final iv = encrypt.IV.fromBase64(backupData['iv']);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      final decrypted = encrypter.decrypt64(backupData['data'], iv: iv);
      final data = jsonDecode(decrypted);

      if (data['db'] != null) {
        await BackupService.performRestore(isar, data['db']);
      }
      if (data['settings'] != null) {
        await SharedPrefsUtil.instance.importAll(data['settings']);
      }

      SnackbarService.success(BuddyMessages.restoreSuccess);
      ref.invalidate(_backupHistoryProvider);
    } catch (e) {
      SnackbarService.error(
        'Restore failed: Invalid password or corrupted file',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _AutoBackupSection extends ConsumerStatefulWidget {
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;

  const _AutoBackupSection({
    required this.color,
    required this.textTheme,
    required this.spacing,
  });

  @override
  ConsumerState<_AutoBackupSection> createState() => _AutoBackupSectionState();
}

class _AutoBackupSectionState extends ConsumerState<_AutoBackupSection> {
  BackupFrequency _frequency = BackupFrequency.never;
  bool _hasPassword = false;
  List<AutoBackupInfo> _recentBackups = [];

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final password = await AutoBackupService.getBackupPassword();
    final backups = await AutoBackupService.listAutoBackups();
    if (!mounted) return;
    setState(() {
      _hasPassword = password != null && password.isNotEmpty;
      _recentBackups = backups;
      _frequency = SharedPrefsUtil.instance.getAutoBackupFrequency();
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final textTheme = widget.textTheme;
    final spacing = widget.spacing;
    final ctxt = AppLocalizations.of(context)!;

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
        children: [
          // Description
          Padding(
            padding: EdgeInsets.fromLTRB(spacing.cardInner, spacing.cardInner - 2, spacing.cardInner, 0),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacing.elementGap),
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(Tone.current.borderRadius),
                  ),
                  child: Icon(LucideIcons.timer, color: color.primary, size: 20),
                ),
                SizedBox(width: spacing.cardInner - 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ctxt.backup_autoBackup,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        ctxt.backup_autoBackupDesc,
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

          SizedBox(height: spacing.elementGap + 4),

          // Frequency selector
          Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing.cardInner),
            child: Row(
              children: [
                Text(
                  ctxt.backup_autoFrequency,
                  style: textTheme.labelMedium?.copyWith(
                    color: color.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                SegmentedButton<BackupFrequency>(
                  segments: [
                    ButtonSegment(
                      value: BackupFrequency.never,
                      label: Text(ctxt.backup_autoNever),
                    ),
                    ButtonSegment(
                      value: BackupFrequency.daily,
                      label: Text(ctxt.backup_autoDaily),
                    ),
                    ButtonSegment(
                      value: BackupFrequency.weekly,
                      label: Text(ctxt.backup_autoWeekly),
                    ),
                  ],
                  selected: {_frequency},
                  onSelectionChanged: (selected) => _setFrequency(selected.first),
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: WidgetStatePropertyAll(
                      textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Password setup prompt
          if (_frequency != BackupFrequency.never && !_hasPassword) ...[
            SizedBox(height: spacing.elementGap + 4),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing.cardInner),
              child: InkWell(
                onTap: _setPassword,
                borderRadius: BorderRadius.circular(Tone.current.borderRadius),
                child: Container(
                  padding: EdgeInsets.all(spacing.elementGap + 4),
                  decoration: BoxDecoration(
                    color: color.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(Tone.current.borderRadius),
                    border: Border.all(
                      color: color.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.keyRound, size: 16, color: color.error),
                      SizedBox(width: spacing.elementGap + 2),
                      Expanded(
                        child: Text(
                          ctxt.backup_autoSetPassword,
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onErrorContainer,
                          ),
                        ),
                      ),
                      Icon(LucideIcons.chevronRight, size: 16, color: color.error),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // Recent auto backups
          if (_recentBackups.isNotEmpty) ...[
            SizedBox(height: spacing.elementGap + 4),
            Divider(
              height: 1,
              color: color.outlineVariant.withValues(alpha: 0.4),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(spacing.cardInner, spacing.elementGap + 2, spacing.cardInner, 0),
              child: Row(
                children: [
                  Icon(LucideIcons.history, size: 14, color: color.onSurfaceVariant),
                  SizedBox(width: spacing.elementGap),
                  Text(
                    ctxt.backup_autoLastRun(
                      safeDateFormat('yMMMd').add_jm().format(_recentBackups.first.date),
                    ),
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_recentBackups.length} saved',
                    style: textTheme.labelSmall?.copyWith(
                      color: color.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: spacing.cardInner - 2),
        ],
      ),
    );
  }

  Future<void> _setFrequency(BackupFrequency freq) async {
    setState(() => _frequency = freq);
    await SharedPrefsUtil.instance.setAutoBackupFrequency(freq.name);

    if (freq == BackupFrequency.never) {
      await AutoBackupService.cancelAutoBackup();
    } else {
      if (!_hasPassword) {
        await _setPassword();
        if (!_hasPassword) {
          // User cancelled password — revert to never
          setState(() => _frequency = BackupFrequency.never);
          await SharedPrefsUtil.instance.setAutoBackupFrequency('never');
          return;
        }
      }
      await AutoBackupService.scheduleAutoBackup(freq);
    }
  }

  Future<void> _setPassword() async {
    final ctxt = AppLocalizations.of(context)!;
    final password = await DialogUtils.showPasswordDialog(
      context,
      isRestore: false,
    );
    if (password == null || password.isEmpty) return;

    await AutoBackupService.setBackupPassword(password);
    if (mounted) {
      setState(() => _hasPassword = true);
      SnackbarService.success(ctxt.backup_passwordSet);
    }
  }
}

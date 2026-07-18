import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/backup_metadata.dart';
import 'package:mudra_manager/core/entitlement/entitlement_feature.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/services/auto_backup_service.dart';
import 'package:mudra_manager/core/services/backup_restore_service.dart';
import 'package:mudra_manager/core/services/google_drive_service.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/safe_date_format.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/gamification/models/gamification_enum.dart';
import 'package:mudra_manager/features/gamification/providers/gamification_providers.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/shared/widgets/pro_gate.dart';
import 'package:mudra_manager/shared/widgets/section_header.dart';
import 'package:mudra_manager/shared/widgets/settings_group_card.dart';
import 'package:mudra_manager/shared/widgets/setting_item.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';

final _backupHistoryProvider = FutureProvider.autoDispose((ref) {
  return BackupService.getBackupHistory();
});

class BackupRestoreScreen extends ConsumerWidget {
  const BackupRestoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctxt = AppLocalizations.of(context)!;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final loaded = ref.watch(_backupHistoryProvider).maybeWhen(
          data: (_) => true,
          orElse: () => false,
        );

    return ScreenShell(
      config: ScreenShellConfig(
        title: ctxt.backup_backupRestoreTitle,
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      actions: ScreenActions.empty,
      body: _BuildBody(
        reduceMotion: reduceMotion,
        loaded: loaded,
      ),
    );
  }
}

class _BuildBody extends ConsumerWidget {
  final bool reduceMotion;
  final bool loaded;

  const _BuildBody({required this.reduceMotion, required this.loaded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final historyAsync = ref.watch(_backupHistoryProvider);
    final lastBackup = historyAsync.value?.isNotEmpty == true
        ? historyAsync.value!.first
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth > 600 ? 600.0 : double.infinity;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              key: ValueKey(loaded),
              child: loaded
                  ? _ContentView(
                      lastBackup: lastBackup,
                      historyAsync: historyAsync,
                      color: color,
                      textTheme: textTheme,
                      spacing: spacing,
                      reduceMotion: reduceMotion,
                    )
                  : _LoadingView(spacing: spacing, color: color),
            ),
          ),
        );
      },
    );
  }
}

class _ContentView extends ConsumerWidget {
  final BackupMetadata? lastBackup;
  final AsyncValue<List<BackupMetadata>> historyAsync;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;
  final bool reduceMotion;

  const _ContentView({
    required this.lastBackup,
    required this.historyAsync,
    required this.color,
    required this.textTheme,
    required this.spacing,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctxt = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: EdgeInsets.only(
        left: spacing.cardHorizontal,
        right: spacing.cardHorizontal,
        top: spacing.cardVertical,
        bottom: 0,
      ),
      children: [
        BackupHeroCard(
            lastBackup: lastBackup,
            isDark: isDark,
            reduceMotion: reduceMotion,
            ctxt: ctxt,),
        SizedBox(height: spacing.sectionGap),
        SectionHeader(ctxt.backup_actions),
        SizedBox(height: spacing.elementGap),
        const _ActionsSection(),
        SizedBox(height: spacing.sectionGap),
        SectionHeader(ctxt.backup_cloudBackup, isPro: true),
        SizedBox(height: spacing.elementGap),
        const ProGate(
          feature: ProFeature.cloudBackup,
          child: _CloudBackupSection(),
        ),
        SizedBox(height: spacing.sectionGap),
        SectionHeader(ctxt.backup_autoBackup, isPro: true),
        SizedBox(height: spacing.elementGap),
        const ProGate(
          feature: ProFeature.autoBackup,
          child: _AutoBackupSection(),
        ),
        SizedBox(height: spacing.sectionGap),
        SectionHeader(ctxt.backup_history),
        SizedBox(height: spacing.elementGap),
        _HistorySection(historyAsync: historyAsync),
        SizedBox(height: spacing.sectionGap),
        const _InfoCard(),
        SizedBox(height: spacing.sectionGap),
        const AmbientBrandSection(
            showSignature: true, absorbBottomInset: false,),
      ],
    );
  }
}

class _LoadingView extends ConsumerWidget {
  final AppSpacing spacing;
  final ColorScheme color;

  const _LoadingView({required this.spacing, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: EdgeInsets.only(
        left: spacing.cardHorizontal,
        right: spacing.cardHorizontal,
        top: spacing.cardVertical,
        bottom: 0,
      ),
      children: [
        _BackupHeroSkeleton(spacing: spacing, color: color),
        SizedBox(height: spacing.sectionGap),
        _SettingsGroupSkeleton(spacing: spacing, color: color),
        SizedBox(height: spacing.sectionGap),
        _SettingsGroupSkeleton(spacing: spacing, color: color),
        SizedBox(height: spacing.sectionGap),
        _HistorySkeleton(spacing: spacing, color: color),
        SizedBox(height: spacing.sectionGap),
        const AmbientBrandSection(
            showSignature: true, absorbBottomInset: false,),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ║                          BACKUP HERO CARD                                  ║
// ════════════════════════════════════════════════════════════════════════════

class BackupHeroCard extends ConsumerWidget {
  final BackupMetadata? lastBackup;
  final bool isDark;
  final bool reduceMotion;
  final AppLocalizations ctxt;

  const BackupHeroCard({
    super.key,
    required this.lastBackup,
    required this.isDark,
    required this.reduceMotion,
    required this.ctxt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final hasBackup = lastBackup != null;

    return Semantics(
      label: hasBackup
          ? 'Last backup: ${_formatRelativeDate(lastBackup!.backupDate, ctxt)}'
          : 'No backups created yet',
      child: AnimatedContainer(
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
        padding: EdgeInsets.all(spacing.cardInner),
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
          border: Border.all(color: color.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          color.primary.withValues(alpha: isDark ? 0.15 : 0.1),
                    ),
                  ),
                  ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: const SizedBox(width: 56, height: 56),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 800),
                    curve: Curves.easeOutBack,
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) =>
                        Transform.scale(scale: value, child: child),
                    child: Container(
                      padding: EdgeInsets.all(spacing.elementGap * 1.5),
                      decoration: BoxDecoration(
                        color: color.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        hasBackup
                            ? LucideIcons.shieldCheck
                            : LucideIcons.shieldAlert,
                        color: color.primary,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: spacing.sectionGap),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color.primary,
                    ) ??
                    const TextStyle(fontWeight: FontWeight.w700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hasBackup
                        ? ctxt.backup_lastBackup
                        : ctxt.backup_noBackups,),
                    SizedBox(height: spacing.elementGapUltraMin),
                    Text(
                      hasBackup
                          ? _formatRelativeDate(lastBackup!.backupDate, ctxt)
                          : ctxt.backup_createFirst,
                      style: textTheme.bodySmall
                          ?.copyWith(color: color.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

// ═════════════════════════════════════════════════════════════════════════════
// ║                          HISTORY SECTION                                   ║
// ════════════════════════════════════════════════════════════════════════════

class _HistorySection extends ConsumerWidget {
  final AsyncValue<List<BackupMetadata>> historyAsync;

  const _HistorySection({required this.historyAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctxt = AppLocalizations.of(context)!;

    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return const _EmptyHistoryCard();
        }
        return SettingsGroupCard(
          items: history.take(5).map((backup) {
            final dateStr = safeDateFormat('yMMMd').add_jm().format(backup.backupDate);
            final sizeStr = _formatFileSize(backup.fileSize);
            return SettingItem(
              icon: LucideIcons.archive,
              title: dateStr,
              subtitle: '${ctxt.backup_recordCount(backup.recordCount)} • $sizeStr${backup.includesAttachments ? ' • with attachments' : ''}',
              onTap: () {},
              selected: true,
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox(height: 150, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _EmptyHistoryCard extends ConsumerWidget {
  const _EmptyHistoryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(spacing.cardInner * 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        color: color.surfaceContainerLow,
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.archiveX, size: 36, color: color.onSurfaceVariant.withValues(alpha: 0.4)),
          SizedBox(height: spacing.elementGap * 1.5),
          Text(ctxt.backup_noHistory, style: textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ║                          ACTIONS SECTION                                   ║
// ════════════════════════════════════════════════════════════════════════════

class _ActionsSection extends ConsumerWidget {
  const _ActionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;
    return SettingsGroupCard(
      items: [
        SettingItem(
          icon: LucideIcons.cloudUpload,
          title: ctxt.backup_backupDataTitle,
          subtitle: ctxt.backup_backupDataSubtitle,
          onTap: () => _performBackup(context, ref, spacing),
          selected: false,
        ),
        SettingItem(
          icon: LucideIcons.cloudDownload,
          title: ctxt.backup_restoreBackupTitle,
          subtitle: ctxt.backup_restoreBackupSubtitle,
          onTap: () => _performRestore(context, ref, spacing),
          selected: false,
        ),
      ],
    );
  }

  Future<void> _performBackup(
      BuildContext context, WidgetRef ref, AppSpacing spacing,) async {
    final ctxt = AppLocalizations.of(context)!;
    final password = await DialogUtils.showPasswordDialog(context, spacing,
        isRestore: false,);
    if (password == null || !context.mounted) return;

    final includeAttachments = await DialogUtils.showConfirmation(
      context,
      spacing,
      title: ctxt.backup_includeAttachmentsTitle,
      message: ctxt.backup_includeAttachmentsMessage,
      confirmText: ctxt.backup_yesLabel,
      cancelText: ctxt.backup_noLabel,
      icon: LucideIcons.paperclip,
    );

    final filePath = await BackupService.createEncryptedBackup(
        password, spacing,
        includeAttachments: includeAttachments ?? false,);
    if (filePath != null) {
      SnackbarService.success(BuddyMessages.backupSuccess, spacing);
      ref.invalidate(_backupHistoryProvider);
      ref
          .read(gamificationServiceProvider)
          ?.track(GamificationEvent.backupCreated);
    }
  }

  Future<void> _performRestore(
      BuildContext context, WidgetRef ref, AppSpacing spacing,) async {
    final password =
        await DialogUtils.showPasswordDialog(context, spacing, isRestore: true);
    if (password == null) return;

    final isar = await ref.read(isarServiceProvider).getInstance();
    if (!context.mounted) return;
    final data = await BackupService.restoreEncryptedBackup(
        context, spacing, isar, password,);
    if (data != null) {
      SnackbarService.success(BuddyMessages.restoreSuccess, spacing);
      ref.invalidate(_backupHistoryProvider);
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ║                            INFO CARD                                       ║
// ════════════════════════════════════════════════════════════════════════════

class _InfoCard extends ConsumerWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;

    return Semantics(
      label: 'Backup information',
      child: Container(
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          color: color.primary.withValues(alpha: 0.06),
          border: Border.all(color: color.primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.info, color: color.primary, size: 18),
            SizedBox(width: spacing.elementGap),
            Expanded(
              child: Text(
                ctxt.backup_infoText,
                style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ║                          SKELETON LOADERS                                  ║
// ════════════════════════════════════════════════════════════════════════════

class _BackupHeroSkeleton extends StatelessWidget {
  final AppSpacing spacing;
  final ColorScheme color;

  const _BackupHeroSkeleton({required this.spacing, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        color: color.surfaceContainerLow,
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          SkeletonLoader(
              width: 56, height: 56, borderRadius: BorderRadius.circular(28),),
          SizedBox(width: spacing.sectionGap),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: 100, height: 18),
                SizedBox(height: 8),
                SkeletonLoader(width: 150, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroupSkeleton extends StatelessWidget {
  final AppSpacing spacing;
  final ColorScheme color;

  const _SettingsGroupSkeleton({required this.spacing, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(spacing.radiusMedium + 4),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: List.generate(2, (index) {
          final isLast = index == 1;
          return Padding(
            padding: EdgeInsets.only(
              left: spacing.cardInner,
              right: spacing.cardInner,
              top: spacing.cardInner,
              bottom: isLast ? spacing.cardInner : spacing.elementGapMin,
            ),
            child: Row(
              children: [
                SkeletonLoader(
                    width: 40,
                    height: 40,
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),),
                SizedBox(width: spacing.cardInner),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader(width: 120, height: 16),
                      SizedBox(height: 6),
                      SkeletonLoader(width: 80, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _HistorySkeleton extends StatelessWidget {
  final AppSpacing spacing;
  final ColorScheme color;

  const _HistorySkeleton({required this.spacing, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner * 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        color: color.surfaceContainerLow,
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SkeletonLoader(
              width: 36, height: 36, borderRadius: BorderRadius.circular(18),),
          SizedBox(height: spacing.elementGap * 1.5),
          const SkeletonLoader(width: 120, height: 16),
        ],
      ),
    );
  }
}

class _CloudBackupSection extends ConsumerStatefulWidget {
  const _CloudBackupSection();

  @override
  ConsumerState<_CloudBackupSection> createState() =>
      _CloudBackupSectionState();
}

class _CloudBackupSectionState extends ConsumerState<_CloudBackupSection> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;
    final isSignedIn = ref.watch(driveSignedInProvider);

    if (!isSignedIn) {
      return _buildSignInCard(color, textTheme, spacing, ctxt);
    }

    return _buildCloudActions(color, textTheme, spacing, ctxt);
  }

  Widget _buildSignInCard(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
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
                      Icon(
                        LucideIcons.circleCheck,
                        size: 16,
                        color: color.primary,
                      ),
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
                onTap: () => _isLoading ? null : _uploadToDrive(spacing),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.primary.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(spacing.radiusSmall),
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
                            : Icon(
                                LucideIcons.cloudUpload,
                                color: color.primary,
                                size: 20,
                              ),
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
                      Icon(
                        LucideIcons.chevronRight,
                        color: color.onSurfaceVariant,
                        size: 20,
                      ),
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
                onTap: _isLoading
                    ? null
                    : () => _showCloudRestoreSheet(ctxt, spacing),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.primary.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(spacing.radiusSmall),
                        ),
                        child: Icon(
                          LucideIcons.cloudDownload,
                          color: color.primary,
                          size: 20,
                        ),
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
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: color.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                      spacing.radiusSmall,),
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
                      Icon(
                        LucideIcons.chevronRight,
                        color: color.onSurfaceVariant,
                        size: 20,
                      ),
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

  Future<void> _uploadToDrive(AppSpacing spacing) async {
    final ctxt = AppLocalizations.of(context)!;
    final password = await DialogUtils.showPasswordDialog(
      context,
      spacing,
      isRestore: false,
    );
    if (password == null || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final localPath = await BackupService.createEncryptedBackup(
        password,
        spacing,
        interactive: false,
      );
      if (localPath == null) {
        SnackbarService.error(BuddyMessages.backupFailed, spacing);
        return;
      }

      final uploaded = await GoogleDriveService.uploadBackup(localPath);
      if (uploaded) {
        SnackbarService.success(ctxt.backup_uploadSuccess, spacing);
        ref.invalidate(driveBackupsProvider);
        ref.invalidate(_backupHistoryProvider);
      } else {
        SnackbarService.error(ctxt.backup_uploadFailed, spacing);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCloudRestoreSheet(AppLocalizations ctxt, AppSpacing spacing) {
    final driveBackups = ref.read(driveBackupsProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(spacing.radiusSmall * 2),),
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
                              borderRadius:
                                  BorderRadius.circular(spacing.radiusSmall),
                            ),
                            child: Icon(
                              LucideIcons.cloud,
                              color: color.tertiary,
                              size: 20,
                            ),
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
                          trailing: Icon(
                            LucideIcons.download,
                            color: color.primary,
                            size: 20,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _restoreFromDrive(backup, spacing);
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

  Future<void> _restoreFromDrive(
      DriveBackupInfo backup, AppSpacing spacing,) async {
    final ctxt = AppLocalizations.of(context)!;
    final password = await DialogUtils.showPasswordDialog(
      context,
      spacing,
      isRestore: true,
    );
    if (password == null || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final localPath = await GoogleDriveService.downloadBackup(backup.id);
      if (localPath == null) {
        SnackbarService.error(ctxt.backup_uploadFailed, spacing);
        return;
      }

      final isar = await ref.read(isarServiceProvider).getInstance();
      if (!mounted) return;

      // Read the downloaded file and restore
      final file = File(localPath);
      final fileContent = await file.readAsString();
      final backupData = jsonDecode(fileContent);

      final encrypt.Key key;
      if (backupData['kdf'] == 'pbkdf2' && backupData['salt'] != null) {
        final salt = base64Decode(backupData['salt'] as String);
        final (derivedKey, _) =
            BackupService.deriveKeyWithSalt(password, Uint8List.fromList(salt));
        key = derivedKey;
      } else {
        // ignore: deprecated_member_use_from_same_package
        key = BackupService.deriveKeyLegacy(password);
      }
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

      SnackbarService.success(BuddyMessages.restoreSuccess, spacing);
      ref.invalidate(_backupHistoryProvider);
    } catch (e) {
      SnackbarService.error(
          'Restore failed: Invalid password or corrupted file', spacing,);
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
  const _AutoBackupSection();

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
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
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
            padding: EdgeInsets.fromLTRB(
                spacing.cardInner, spacing.cardInner - 2, spacing.cardInner, 0,),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacing.elementGap),
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  ),
                  child:
                      Icon(LucideIcons.timer, color: color.primary, size: 20),
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
                  onSelectionChanged: (selected) =>
                      _setFrequency(selected.first, spacing),
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: WidgetStatePropertyAll(
                      textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
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
                onTap: () => _setPassword(spacing),
                borderRadius: BorderRadius.circular(spacing.radiusSmall),
                child: Container(
                  padding: EdgeInsets.all(spacing.elementGap + 4),
                  decoration: BoxDecoration(
                    color: color.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
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
                      Icon(LucideIcons.chevronRight,
                          size: 16, color: color.error,),
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
              padding: EdgeInsets.fromLTRB(spacing.cardInner,
                  spacing.elementGap + 2, spacing.cardInner, 0,),
              child: Row(
                children: [
                  Icon(LucideIcons.history,
                      size: 14, color: color.onSurfaceVariant,),
                  SizedBox(width: spacing.elementGap),
                  Text(
                    ctxt.backup_autoLastRun(
                      safeDateFormat('yMMMd')
                          .add_jm()
                          .format(_recentBackups.first.date),
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

  Future<void> _setFrequency(BackupFrequency freq, AppSpacing spacing) async {
    setState(() => _frequency = freq);
    await SharedPrefsUtil.instance.setAutoBackupFrequency(freq.name);

    if (freq == BackupFrequency.never) {
      await AutoBackupService.cancelAutoBackup();
    } else {
      if (!_hasPassword) {
        await _setPassword(spacing);
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

  Future<void> _setPassword(AppSpacing spacing) async {
    final ctxt = AppLocalizations.of(context)!;
    final password = await DialogUtils.showPasswordDialog(
      context,
      spacing,
      isRestore: false,
    );
    if (password == null || password.isEmpty) return;

    await AutoBackupService.setBackupPassword(password);
    if (mounted) {
      setState(() => _hasPassword = true);
      SnackbarService.success(ctxt.backup_passwordSet, spacing);
    }
  }
}

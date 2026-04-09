import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/permission_provider.dart';
import 'package:mudra_manager/features/sms/data/notification_listener_service.dart';
import 'package:mudra_manager/features/sms/presentation/screens/sms_activity_screen.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class SmsImportSettingsScreen extends ConsumerStatefulWidget {
  const SmsImportSettingsScreen({super.key});

  @override
  ConsumerState<SmsImportSettingsScreen> createState() =>
      _SmsImportSettingsScreenState();
}

class _SmsImportSettingsScreenState
    extends ConsumerState<SmsImportSettingsScreen> with WidgetsBindingObserver {
  bool _smsImportEnabled = SharedPrefsUtil.instance.getSmsImportEnabled();
  bool _permissionGranted = false;
  bool _loaded = false;
  int _permissionDisableTapCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationListenerBridge.isPermissionGranted().then((granted) {
      if (!mounted) return;
      setState(() {
        _permissionGranted = granted;
        _loaded = true;
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationListenerBridge.isPermissionGranted().then((granted) {
        if (!mounted) return;
        if (granted != _permissionGranted) {
          setState(() => _permissionGranted = granted);
          ref.invalidate(smsPermissionGrantedProvider);
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) return _buildIosPlaceholder(color, textTheme, spacing);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.smsImport_autoImport)),
      body: !_loaded
          ? ListView(children: List.generate(3, (_) => const DashboardCardSkeleton()))
          : ListView(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontal,
                vertical: spacing.cardVertical,
              ),
              children: [
                // ── HERO STATUS ──
                _buildHeroCard(color, textTheme, spacing, isDark),
                SizedBox(height: spacing.sectionGap),

                // ── PERMISSIONS ──
                _buildSectionHeader(AppLocalizations.of(context)!.smsImport_permissions, color, textTheme),
                SizedBox(height: spacing.sectionGap),
                _buildGroupedCard(
                  spacing: spacing,
                  color: color,
                  children: [
                    _buildToggleRow(
                      icon: LucideIcons.shieldCheck,
                      title: AppLocalizations.of(context)!.smsImport_notifAccess,
                      subtitle: _permissionGranted
                          ? AppLocalizations.of(context)!.smsImport_notifAccessEnabled
                          : AppLocalizations.of(context)!.smsImport_allowReadingNotif,
                      value: _permissionGranted,
                      onChanged: _handlePermissionToggle,
                      color: color,
                      textTheme: textTheme,
                    ),
                    _divider(color),
                    _buildToggleRow(
                      icon: LucideIcons.messageSquare,
                      title: AppLocalizations.of(context)!.smsImport_autoImport,
                      subtitle: AppLocalizations.of(context)!.smsImport_autoDetectTxn,
                      value: _smsImportEnabled && _permissionGranted,
                      onChanged:
                          _permissionGranted ? _handleAutoImportToggle : null,
                      color: color,
                      textTheme: textTheme,
                      disabled: !_permissionGranted,
                    ),
                  ],
                ),
                SizedBox(height: spacing.sectionGap),
                Container(
                  padding: EdgeInsets.all(spacing.cardInner),
                  margin: EdgeInsets.only(bottom: spacing.cardVertical),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    color: color.tertiary.withValues(alpha: 0.08),
                    border: Border.all(
                      color: color.tertiary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.shieldCheck,
                        color: color.tertiary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.smsImport_privacyNote,
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── TOOLS ──
                _buildSectionHeader(AppLocalizations.of(context)!.smsImport_tools, color, textTheme),
                SizedBox(height: spacing.sectionGap),
                _buildGroupedCard(
                  spacing: spacing,
                  color: color,
                  children: [
                    _buildTapRow(
                      icon: LucideIcons.activity,
                      title: AppLocalizations.of(context)!.smsImport_txnActivity,
                      subtitle: AppLocalizations.of(context)!.smsImport_viewDetectedTxn,
                      onTap: () => context.push(AppRoutes.smsActivity),
                      color: color,
                      textTheme: textTheme,
                      badge: ref
                          .watch(pendingCountProvider)
                          .maybeWhen(
                            data: (c) => c,
                            orElse: () => null,
                          ),
                    ),
                    _divider(color),
                    _buildTapRow(
                      icon: LucideIcons.trash2,
                      title: AppLocalizations.of(context)!.smsImport_clearHistory,
                      subtitle: AppLocalizations.of(context)!.smsImport_resetDetection,
                      onTap: _permissionGranted
                          ? () => _showClearHistoryConfirmation(context)
                          : null,
                      color: color,
                      textTheme: textTheme,
                      disabled: !_permissionGranted,
                      destructive: true,
                    ),
                  ],
                ),
                SizedBox(height: spacing.sectionGap),

                // ── HOW IT WORKS ──
                _buildSectionHeader(AppLocalizations.of(context)!.smsImport_howItWorks, color, textTheme),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    color: color.surfaceContainerLow,
                    border: Border.all(
                      color: color.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildInfoPoint(
                        LucideIcons.landmark,
                        AppLocalizations.of(context)!.smsImport_readsBankNotif,
                        color,
                        textTheme,
                      ),
                      SizedBox(height: spacing.elementGap),
                      _buildInfoPoint(
                        LucideIcons.lock,
                        AppLocalizations.of(context)!.smsImport_dataStaysOnDevice,
                        color,
                        textTheme,
                      ),
                      SizedBox(height: spacing.elementGap),
                      _buildInfoPoint(
                        LucideIcons.sparkles,
                        AppLocalizations.of(context)!.smsImport_autoCreatesTxn,
                        color,
                        textTheme,
                      ),
                      SizedBox(height: spacing.elementGap),
                      _buildInfoPoint(
                        LucideIcons.eyeOff,
                        AppLocalizations.of(context)!.smsImport_personalIgnored,
                        color,
                        textTheme,
                      ),
                      SizedBox(height: spacing.elementGap),
                      _buildInfoPoint(
                        LucideIcons.cloudOff,
                        AppLocalizations.of(context)!.smsImport_noDataSent,
                        color,
                        textTheme,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ── HERO ──

  Widget _buildHeroCard(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    bool isDark,
  ) {
    final active = _permissionGranted && _smsImportEnabled;
    final heroColor = active ? color.primary : color.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(spacing.radiusLarge),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            heroColor.withValues(alpha: isDark ? 0.2 : 0.12),
            heroColor.withValues(alpha: isDark ? 0.08 : 0.04),
          ],
        ),
        border: Border.all(
          color: heroColor.withValues(alpha: 0.3),
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
                color: heroColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                active
                    ? LucideIcons.messageSquareCheck
                    : LucideIcons.messageSquareOff,
                color: heroColor,
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
                  active ? AppLocalizations.of(context)!.smsImport_active : AppLocalizations.of(context)!.smsImport_inactive,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: heroColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  active
                      ? AppLocalizations.of(context)!.smsImport_autoImporting
                      : _permissionGranted
                          ? AppLocalizations.of(context)!.smsImport_enableToStart
                          : AppLocalizations.of(context)!.smsImport_grantAccess,
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── iOS PLACEHOLDER ──

  Widget _buildIosPlaceholder(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.smsImport_autoImport)),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(spacing.cardHorizontalMax),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.smartphoneNfc,
                  color: color.primary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.smsImport_notAvailableIos,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.smsImport_iosRestriction,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: color.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── SHARED BUILDERS ──

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

  Widget _buildGroupedCard({
    required AppSpacing spacing,
    required ColorScheme color,
    required List<Widget> children,
  }) {
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
      child: Column(children: children),
    );
  }

  Widget _divider(ColorScheme color) {
    return Divider(
      height: 1,
      indent: 58,
      color: color.outlineVariant.withValues(alpha: 0.4),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required ColorScheme color,
    required TextTheme textTheme,
    bool disabled = false,
  }) {
    final alpha = disabled ? 0.4 : 1.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: 0.12 * alpha),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color.primary.withValues(alpha: alpha),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: color.onSurface.withValues(alpha: alpha),
                  ),
                ),
                Text(
                  disabled ? AppLocalizations.of(context)!.smsImport_enableAccessFirst : subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant.withValues(alpha: alpha),
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: disabled ? null : onChanged),
        ],
      ),
    );
  }

  Widget _buildTapRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    required ColorScheme color,
    required TextTheme textTheme,
    bool disabled = false,
    bool destructive = false,
    int? badge,
  }) {
    final alpha = disabled ? 0.4 : 1.0;
    final iconColor = destructive
        ? color.error.withValues(alpha: alpha)
        : color.primary.withValues(alpha: alpha);

    return InkWell(
      onTap: disabled
          ? null
          : () {
              HapticFeedback.mediumImpact();
              onTap?.call();
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: color.onSurface.withValues(alpha: alpha),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant.withValues(alpha: alpha),
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null && badge > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: TextStyle(
                    color: color.onError,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Icon(
              LucideIcons.chevronRight,
              color: color.onSurfaceVariant.withValues(alpha: alpha),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPoint(
    IconData icon,
    String text,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        Icon(icon, color: color.primary, size: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodySmall?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
  // ── BOTTOM SHEETS ──

  Future<bool?> _showSmsPermissionDisclosure(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: color.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(LucideIcons.shieldCheck, color: color.primary, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.smsImport_notifAccessRequired,
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.smsImport_notifAccessDesc,
              style:
                  textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  _disclosurePoint(
                    LucideIcons.listFilter,
                    AppLocalizations.of(context)!.smsImport_onlyBankRead,
                    color,
                    textTheme,
                  ),
                  const SizedBox(height: 12),
                  _disclosurePoint(
                    LucideIcons.smartphone,
                    AppLocalizations.of(context)!.smsImport_dataStaysOnDevice,
                    color,
                    textTheme,
                  ),
                  const SizedBox(height: 12),
                  _disclosurePoint(
                    LucideIcons.ban,
                    AppLocalizations.of(context)!.smsImport_personalNeverRead,
                    color,
                    textTheme,
                  ),
                  const SizedBox(height: 12),
                  _disclosurePoint(
                    LucideIcons.cloudOff,
                    AppLocalizations.of(context)!.smsImport_noDataSent,
                    color,
                    textTheme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ctx.pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(AppLocalizations.of(context)!.common_cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () => ctx.pop(true),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(AppLocalizations.of(context)!.smsImport_openSettings),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _disclosurePoint(
    IconData icon,
    String text,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        Icon(icon, color: color.primary, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodyMedium?.copyWith(color: color.onSurface),
          ),
        ),
      ],
    );
  }

  Future<void> _showClearHistoryConfirmation(BuildContext context) async {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: color.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(LucideIcons.triangleAlert, color: color.error, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.smsImport_clearHistoryConfirm,
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.info, color: color.error, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.smsImport_clearHistoryWarning,
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () => ctx.pop(false),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(AppLocalizations.of(context)!.common_cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ctx.pop(true),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: color.error,
                      side: BorderSide(color: color.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(AppLocalizations.of(context)!.txnList_clear),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      SharedPrefsUtil.instance.clearProcessedHashes();
      if (!context.mounted) return;
      SnackbarService.success(BuddyMessages.settingsSaved);
    }
  }

  // ── SCAN LOGIC (unchanged) ──
  Future<void> _handlePermissionToggle(bool on) async {
    HapticFeedback.mediumImpact();
    if (on) {
      final confirmed = await _showSmsPermissionDisclosure(context);
      if (confirmed != true) return;

      await NotificationListenerBridge.openSettings();
      // After returning from settings, re-check
      final granted = await NotificationListenerBridge.isPermissionGranted();
      if (granted) {
        setState(() => _permissionGranted = true);
        ref.invalidate(smsPermissionGrantedProvider);
        SnackbarService.success(BuddyMessages.smsImportEnabled);
      } else {
        SnackbarService.error(BuddyMessages.notificationAccessDenied);
      }
    } else {
      _permissionDisableTapCount++;
      if (_permissionDisableTapCount >= 2) {
        await NotificationListenerBridge.openSettings();
        _permissionDisableTapCount = 0;
      } else {
        SnackbarService.info(AppLocalizations.of(context)!.smsImport_tapAgainSettings);
      }
    }
  }

  Future<void> _handleAutoImportToggle(bool on) async {
    HapticFeedback.mediumImpact();
    setState(() => _smsImportEnabled = on);
    SharedPrefsUtil.instance.setSmsImportEnabled(on);
    ref.invalidate(smsPermissionGrantedProvider);
    if (on) {
      if (!mounted) return;
      SnackbarService.success(BuddyMessages.smsImportEnabled);
    } else {
      SnackbarService.info(BuddyMessages.toggledOff(AppLocalizations.of(context)!.smsImport_autoImport));
    }
  }
}

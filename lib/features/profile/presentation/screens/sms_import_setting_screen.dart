import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/extension/case_extention.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/permission_provider.dart';
import 'package:mudra_manager/features/sms/data/notification_listener_service.dart';
import 'package:mudra_manager/features/sms/domain/detection_level.dart';
import 'package:mudra_manager/features/sms/presentation/screens/sms_activity_screen.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/shared/widgets/section_header.dart';
import 'package:mudra_manager/shared/widgets/settings_group_card.dart';
import 'package:mudra_manager/shared/widgets/setting_item.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SmsImportSettingsScreen extends ConsumerStatefulWidget {
  const SmsImportSettingsScreen({super.key});

  @override
  ConsumerState<SmsImportSettingsScreen> createState() =>
      _SmsImportSettingsScreenState();
}

class _SmsImportSettingsScreenState
    extends ConsumerState<SmsImportSettingsScreen> with WidgetsBindingObserver {
  bool _smsImportEnabled = false;
  bool _permissionGranted = false;
  bool _loaded = false;
  int _permissionDisableTapCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final smsEnabled = prefs.getBool('sms_import_enabled') ?? false;
    final granted = await NotificationListenerBridge.isPermissionGranted();
    if (!mounted) return;
    setState(() {
      _smsImportEnabled = smsEnabled;
      _permissionGranted = granted;
      _loaded = true;
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

  Future<void> _handlePermissionToggle(bool on, AppSpacing spacing) async {
    HapticFeedback.mediumImpact();
    if (on) {
      final confirmed = await _showSmsPermissionDisclosure(context);
      if (confirmed != true) return;
      await NotificationListenerBridge.openSettings();
      final granted = await NotificationListenerBridge.isPermissionGranted();
      if (granted) {
        setState(() => _permissionGranted = true);
        ref.invalidate(smsPermissionGrantedProvider);
        SnackbarService.success(BuddyMessages.smsImportEnabled, spacing);
      } else {
        SnackbarService.error(BuddyMessages.notificationAccessDenied, spacing);
      }
    } else {
      _permissionDisableTapCount++;
      if (_permissionDisableTapCount >= 2) {
        await NotificationListenerBridge.openSettings();
        _permissionDisableTapCount = 0;
      } else {
        SnackbarService.info(
            AppLocalizations.of(context)!.smsImport_tapAgainSettings, spacing,);
      }
    }
  }

  Future<void> _handleAutoImportToggle(bool on, AppSpacing spacing) async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sms_import_enabled', on);
    setState(() => _smsImportEnabled = on);
    ref.invalidate(smsPermissionGrantedProvider);
    if (on) {
      if (!context.mounted) return;
      SnackbarService.success(BuddyMessages.smsImportEnabled, spacing);
    } else {
      SnackbarService.info(
        BuddyMessages.toggledOff(
            AppLocalizations.of(context)!.smsImport_autoImport,),
        spacing,
      );
    }
  }

  Future<void> _showClearHistoryConfirmation(BuildContext context) async {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    final spacing = ref.watch(spacingProvider);

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(spacing.radiusSmall * 2)),
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
              child: Icon(LucideIcons.triangleAlert, color: color.error, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              ctxt.smsImport_clearHistoryConfirm,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(spacing.radiusSmall),
                border: Border.all(color: color.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.info, color: color.error, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ctxt.smsImport_clearHistoryWarning,
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
                        borderRadius: BorderRadius.circular(spacing.radiusSmall),
                      ),
                    ),
                    child: Text(ctxt.common_cancel),
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
                        borderRadius: BorderRadius.circular(spacing.radiusSmall),
                      ),
                    ),
                    child: Text(ctxt.txnList_clear),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('processed_sms_hashes');
      if (!context.mounted) return;
      SnackbarService.success(BuddyMessages.settingsSaved, spacing);
    }
  }

  Future<bool?> _showSmsPermissionDisclosure(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    final spacing = ref.watch(spacingProvider);

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(spacing.radiusSmall * 2)),
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
              child: Icon(LucideIcons.shieldCheck, color: color.primary, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              ctxt.smsImport_notifAccessRequired,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              ctxt.smsImport_notifAccessDesc,
              style:
                  textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.surfaceContainerLow,
                borderRadius: BorderRadius.circular(spacing.radiusSmall),
                border: Border.all(color: color.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  _buildDisclosurePoint(
                    LucideIcons.listFilter,
                    ctxt.smsImport_onlyBankRead,
                    color,
                    textTheme,
                  ),
                  const SizedBox(height: 12),
                  _buildDisclosurePoint(
                    LucideIcons.smartphone,
                    ctxt.smsImport_dataStaysOnDevice,
                    color,
                    textTheme,
                  ),
                  const SizedBox(height: 12),
                  _buildDisclosurePoint(
                    LucideIcons.ban,
                    ctxt.smsImport_personalNeverRead,
                    color,
                    textTheme,
                  ),
                  const SizedBox(height: 12),
                  _buildDisclosurePoint(
                    LucideIcons.cloudOff,
                    ctxt.smsImport_noDataSent,
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
                        borderRadius: BorderRadius.circular(spacing.radiusSmall),
                      ),
                    ),
                    child: Text(ctxt.common_cancel),
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
                        borderRadius: BorderRadius.circular(spacing.radiusSmall),
                      ),
                    ),
                    child: Text(ctxt.smsImport_openSettings),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclosurePoint(
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

  @override
  Widget build(BuildContext context) {
    final ctxt = AppLocalizations.of(context)!;

    if (Platform.isIOS) {
      return _buildIosPlaceholder(ctxt);
    }

    return ScreenShell(
      config: ScreenShellConfig(
        title: ctxt.smsImport_autoImport,
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      actions: ScreenActions.empty,
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final ctxt = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth > 600 ? 600.0 : double.infinity;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: AnimatedSwitcher(
              duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              key: ValueKey(_loaded),
              child: _loaded
                  ? _buildContent(context, color, textTheme, spacing, isDark, reduceMotion, ctxt)
                  : _buildLoading(spacing, color),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    bool isDark,
    bool reduceMotion,
    AppLocalizations ctxt,
  ) {
    return ListView(
      padding: EdgeInsets.only(
        left: spacing.cardHorizontal,
        right: spacing.cardHorizontal,
        top: spacing.cardVertical,
        bottom: 0,
      ),
      children: [
        // Hero status card
        SmsHeroCard(
          permissionGranted: _permissionGranted,
          smsImportEnabled: _smsImportEnabled,
          isDark: isDark,
          reduceMotion: reduceMotion,
        ),
        SizedBox(height: spacing.sectionGap),

        // Permissions section
        SectionHeader(ctxt.smsImport_permissions),
        SizedBox(height: spacing.elementGap),
        SettingsGroupCard(
          items: [
            SettingItem(
              icon: LucideIcons.shieldCheck,
              title: ctxt.smsImport_notifAccess,
              subtitle: _permissionGranted
                  ? ctxt.smsImport_notifAccessEnabled
                  : ctxt.smsImport_allowReadingNotif,
              onTap: () => _handlePermissionToggle(!_permissionGranted, spacing),
              disabled: !_permissionGranted,
            ),
            SettingItem(
              icon: LucideIcons.messageSquare,
              title: ctxt.smsImport_autoImport,
              subtitle: ctxt.smsImport_autoDetectTxn,
              onTap: () => _permissionGranted
                  ? _handleAutoImportToggle(!_smsImportEnabled, spacing)
                  : null,
              disabled: !_permissionGranted,
            ),
            SettingItem(
              icon: LucideIcons.settings,
              title: 'Smart Detection Settings',
              subtitle: 'How automatic should transaction detection be?',
              onTap: () {
                HapticFeedback.mediumImpact();
                DialogUtils.showListItems(
                  context: context,
                  spacing: spacing,
                  title: 'Select Detection Sensitivity',
                  items: DetectionSensitivity.values
                      .map((d) => d.name.toTitleCase())
                      .toList(),
                  selectedValue: SharedPrefsUtil.instance
                      .getDetectionMode()
                      .name
                      .toTitleCase(),
                  onItemSelected: (val) {
                    final level = switch (val) {
                      'Strict' => DetectionSensitivity.strict,
                      'Balanced' => DetectionSensitivity.balanced,
                      'Aggressive' => DetectionSensitivity.aggressive,
                      _ => DetectionSensitivity.balanced,
                    };
                    SharedPrefsUtil.instance.setString('detection_mode', level.name);
                    SnackbarService.info(
                      'Detection sensitivity set to ${level.name.toTitleCase()}',
                      spacing,
                    );
                  },
                );
              },
            ),
          ],
        ),
        SizedBox(height: spacing.sectionGap),

        // Privacy note
        Semantics(
          label: 'Privacy information',
          child: Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.shieldCheck,
                  color: color.tertiary,
                  size: 20,
                ),
                SizedBox(width: spacing.elementGap),
                Expanded(
                  child: Text(
                    ctxt.smsImport_privacyNote,
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tools section
        SectionHeader(ctxt.smsImport_tools),
        SizedBox(height: spacing.elementGap),
        SettingsGroupCard(
          items: [
            SettingItem(
              icon: LucideIcons.activity,
              title: ctxt.smsImport_txnActivity,
              subtitle: ctxt.smsImport_viewDetectedTxn,
              onTap: () => context.push(AppRoutes.smsActivity),
              trailing: ref.watch(pendingCountProvider).maybeWhen(
                    data: (count) => count > 0
                        ? Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.error,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                color: color.onError,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                    orElse: () => null,
                  ),
            ),
            SettingItem(
              icon: LucideIcons.trash2,
              title: ctxt.smsImport_clearHistory,
              subtitle: ctxt.smsImport_resetDetection,
              onTap: () => _permissionGranted
                  ? () => _showClearHistoryConfirmation(context)
                  : null,
              disabled: !_permissionGranted,
            ),
          ],
        ),
        SizedBox(height: spacing.sectionGap),

        // How it works section
        SectionHeader(ctxt.smsImport_howItWorks),
        SizedBox(height: spacing.elementGap),
        _buildHowItWorksCard(color, textTheme, spacing, ctxt),
        SizedBox(height: spacing.sectionGap),

        const AmbientBrandSection(showSignature: true, absorbBottomInset: false),
      ],
    );
  }

  Widget _buildLoading(AppSpacing spacing, ColorScheme color) {
    return ListView(
      padding: EdgeInsets.only(
        left: spacing.cardHorizontal,
        right: spacing.cardHorizontal,
        top: spacing.cardVertical,
        bottom: 0,
      ),
      children: [
        _SmsHeroSkeleton(spacing: spacing, color: color),
        SizedBox(height: spacing.sectionGap),
        _SettingsGroupSkeleton(spacing: spacing, color: color),
        SizedBox(height: spacing.sectionGap),
        SizedBox(height: spacing.sectionGap),
        const AmbientBrandSection(showSignature: true, absorbBottomInset: false),
      ],
    );
  }

  Widget _buildHowItWorksCard(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        color: color.surfaceContainerLow,
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _buildInfoPoint(LucideIcons.landmark, ctxt.smsImport_readsBankNotif, color),
          SizedBox(height: spacing.elementGap),
          _buildInfoPoint(LucideIcons.lock, ctxt.smsImport_dataStaysOnDevice, color),
          SizedBox(height: spacing.elementGap),
          _buildInfoPoint(LucideIcons.sparkles, ctxt.smsImport_autoCreatesTxn, color),
          SizedBox(height: spacing.elementGap),
          _buildInfoPoint(LucideIcons.eyeOff, ctxt.smsImport_personalIgnored, color),
          SizedBox(height: spacing.elementGap),
          _buildInfoPoint(LucideIcons.cloudOff, ctxt.smsImport_noDataSent, color),
        ],
      ),
    );
  }

  Widget _buildInfoPoint(IconData icon, String text, ColorScheme color) {
    return Row(
      children: [
        Icon(icon, color: color.primary, size: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _buildIosPlaceholder(AppLocalizations ctxt) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);

    return ScreenShell(
      config: ScreenShellConfig(
        title: ctxt.smsImport_autoImport,
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      actions: ScreenActions.empty,
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
              SizedBox(height: spacing.sectionGap),
              Text(
                ctxt.smsImport_notAvailableIos,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color.primary,
                ),
              ),
              SizedBox(height: spacing.elementGap),
              Text(
                ctxt.smsImport_iosRestriction,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ║                          SMS HERO CARD                                    ║
// ════════════════════════════════════════════════════════════════════════════

class SmsHeroCard extends ConsumerWidget {
  final bool permissionGranted;
  final bool smsImportEnabled;
  final bool isDark;
  final bool reduceMotion;

  const SmsHeroCard({
    super.key,
    required this.permissionGranted,
    required this.smsImportEnabled,
    required this.isDark,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;

    final active = permissionGranted && smsImportEnabled;
    final heroColor = color.primary;

    return Semantics(
      label: active
          ? 'SMS import active. Auto-importing transactions'
          : 'SMS import inactive',
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              heroColor.withValues(alpha: isDark ? 0.2 : 0.12),
              heroColor.withValues(alpha: isDark ? 0.08 : 0.04),
            ],
          ),
          border: Border.all(color: heroColor.withValues(alpha: 0.3)),
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
                      color: heroColor.withValues(alpha: isDark ? 0.15 : 0.1),
                    ),
                  ),
                  ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(width: 56, height: 56),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutBack,
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) =>
                        Transform.scale(scale: value, child: child),
                    child: Container(
                      padding: EdgeInsets.all(spacing.elementGap * 1.5),
                      decoration: BoxDecoration(
                        color: heroColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        active
                            ? LucideIcons.messageSquareCheck
                            : LucideIcons.messageSquareOff,
                        color: heroColor,
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
                duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: heroColor,
                ) ?? const TextStyle(fontWeight: FontWeight.w700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(active ? ctxt.smsImport_active : ctxt.smsImport_inactive),
                    SizedBox(height: spacing.elementGapUltraMin),
                    Text(
                      active
                          ? ctxt.smsImport_autoImporting
                          : permissionGranted
                              ? ctxt.smsImport_enableToStart
                              : ctxt.smsImport_grantAccess,
                      style:
                          textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
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
}

// ═════════════════════════════════════════════════════════════════════════════
// ║                            SKELETON LOADERS                               ║
// ════════════════════════════════════════════════════════════════════════════

class _SmsHeroSkeleton extends StatelessWidget {
  final AppSpacing spacing;
  final ColorScheme color;

  const _SmsHeroSkeleton({required this.spacing, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        color: color.surfaceContainerLow,
      ),
      child: Row(
        children: [
          SkeletonLoader(
            width: 56,
            height: 56,
            borderRadius: BorderRadius.circular(28),
          ),
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
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
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
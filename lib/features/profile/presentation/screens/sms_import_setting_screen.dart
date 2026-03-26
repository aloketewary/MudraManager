import 'dart:convert';
import 'dart:io';

import 'package:another_telephony/telephony.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/core/utils/transaction_msg_util.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/permission_provider.dart';
import 'package:mudra_manager/features/sms/data/sms_processor_service.dart';
import 'package:mudra_manager/features/sms/presentation/screens/sms_activity_screen.dart';
import 'package:mudra_manager/features/transactions/data/pending_transaction_prodiver.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/main.dart' show setupSmsListener;
import 'package:permission_handler/permission_handler.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class SmsImportSettingsScreen extends ConsumerStatefulWidget {
  const SmsImportSettingsScreen({super.key});

  @override
  ConsumerState<SmsImportSettingsScreen> createState() =>
      _SmsImportSettingsScreenState();
}

class _SmsImportSettingsScreenState
    extends ConsumerState<SmsImportSettingsScreen> {
  bool _smsImportEnabled = SharedPrefsUtil.instance.getSmsImportEnabled();
  final TransactionUtil _transactionUtil = TransactionUtil();
  bool _permissionGranted = false;
  bool _loaded = false;
  int _permissionDisableTapCount = 0;

  @override
  void initState() {
    super.initState();
    Permission.sms.status.then((status) {
      if (!mounted) return;
      setState(() {
        _permissionGranted = status == PermissionStatus.granted;
        _loaded = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) return _buildIosPlaceholder(color, textTheme, spacing);

    return Scaffold(
      appBar: AppBar(title: const Text('SMS Import')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
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
                _buildSectionHeader('Permissions', color, textTheme),
                SizedBox(height: spacing.sectionGap),
                _buildGroupedCard(
                  spacing: spacing,
                  color: color,
                  children: [
                    _buildToggleRow(
                      icon: LucideIcons.shieldCheck,
                      title: 'SMS Permission',
                      subtitle: _permissionGranted
                          ? 'Access granted'
                          : 'Grant access to read SMS',
                      value: _permissionGranted,
                      onChanged: _handlePermissionToggle,
                      color: color,
                      textTheme: textTheme,
                    ),
                    _divider(color),
                    _buildToggleRow(
                      icon: LucideIcons.messageSquare,
                      title: 'Auto Import',
                      subtitle: 'Auto-detect transactions from SMS',
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
                    color: const Color(0xFF009688).withValues(alpha: 0.08),
                    border: Border.all(
                      color: const Color(0xFF009688).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.shieldCheck,
                        color: Color(0xFF009688),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'SMS is read locally on your device to detect transactions. Nothing is uploaded or shared — ever.',
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
                _buildSectionHeader('Tools', color, textTheme),
                SizedBox(height: spacing.sectionGap),
                _buildGroupedCard(
                  spacing: spacing,
                  color: color,
                  children: [
                    _buildTapRow(
                      icon: LucideIcons.activity,
                      title: 'SMS Activity',
                      subtitle: 'View all SMS transactions',
                      onTap: () => context.push(AppRoutes.smsActivity),
                      color: color,
                      textTheme: textTheme,
                      badge: ref
                          .watch(pendingCountProvider)
                          .whenData((c) => c)
                          .value,
                    ),
                    _divider(color),
                    _buildTapRow(
                      icon: LucideIcons.refreshCw,
                      title: 'Rescan SMS',
                      subtitle: 'Scan recent messages for transactions',
                      onTap: _permissionGranted
                          ? () => _showSmsScanOptions(context)
                          : null,
                      color: color,
                      textTheme: textTheme,
                      disabled: !_permissionGranted,
                    ),
                    _divider(color),
                    _buildTapRow(
                      icon: LucideIcons.trash2,
                      title: 'Clear Processing History',
                      subtitle: 'Reset SMS scan history',
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
                _buildSectionHeader('How It Works', color, textTheme),
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
                        'Only scans bank & wallet SMS',
                        color,
                        textTheme,
                      ),
                      SizedBox(height: spacing.elementGap),
                      _buildInfoPoint(
                        LucideIcons.lock,
                        'All data stays on your device',
                        color,
                        textTheme,
                      ),
                      SizedBox(height: spacing.elementGap),
                      _buildInfoPoint(
                        LucideIcons.sparkles,
                        'Automatically creates transactions',
                        color,
                        textTheme,
                      ),
                      SizedBox(height: spacing.elementGap),
                      _buildInfoPoint(
                        LucideIcons.eyeOff,
                        'Personal messages are never read',
                        color,
                        textTheme,
                      ),
                      SizedBox(height: spacing.elementGap),
                      _buildInfoPoint(
                        LucideIcons.cloudOff,
                        'No data sent to any server',
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
    final heroColor = active ? const Color(0xFF4CAF50) : color.primary;

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
                  active ? 'Active' : 'Inactive',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: heroColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  active
                      ? 'SMS transactions are being imported automatically'
                      : _permissionGranted
                          ? 'Enable auto import to start tracking SMS'
                          : 'Grant SMS permission to get started',
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
      appBar: AppBar(title: const Text('SMS Import')),
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
                'Not Available on iOS',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'SMS import is only available on Android due to iOS platform restrictions.',
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
                  disabled ? 'Enable SMS permission first' : subtitle,
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
              Icons.chevron_right,
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
              'SMS Permission Required',
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Mudra Manager needs SMS permission to automatically detect transactions from your bank and wallet messages.',
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
                    'Only bank/wallet SMS are scanned',
                    color,
                    textTheme,
                  ),
                  const SizedBox(height: 12),
                  _disclosurePoint(
                    LucideIcons.smartphone,
                    'All data stays on your device',
                    color,
                    textTheme,
                  ),
                  const SizedBox(height: 12),
                  _disclosurePoint(
                    LucideIcons.ban,
                    'Personal messages are never read',
                    color,
                    textTheme,
                  ),
                  const SizedBox(height: 12),
                  _disclosurePoint(
                    LucideIcons.cloudOff,
                    'No data sent to servers',
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
                    child: const Text('Cancel'),
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
                    child: const Text('Allow Permission'),
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
              'Clear Processing History?',
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
                      'Previously scanned SMS will be processed again, which may create duplicate transactions.',
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
                    child: const Text('Cancel'),
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
                    child: const Text('Clear'),
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
      SnackbarService.success('Processing history cleared');
    }
  }

  void _showSmsScanOptions(BuildContext context) async {
    final now = DateTime.now();
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final options = {
      'Today': DateTime(now.year, now.month, now.day),
      'Yesterday': DateTime(now.year, now.month, now.day - 1),
      'This Month': DateTime(now.year, now.month, 1),
      'Last Month': DateTime(now.year, now.month - 1, 1),
      'Last 2 Months': DateTime(now.year, now.month - 2, 1),
      'Last 3 Months': DateTime(now.year, now.month - 3, 1),
    };

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 16),
            Text(
              'Select Scan Period',
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...options.entries.map((entry) {
              return ListTile(
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                leading:
                    Icon(LucideIcons.calendar, color: color.primary, size: 20),
                title: Text(
                  entry.key,
                  style: textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: color.onSurfaceVariant,
                  size: 20,
                ),
                onTap: () => ctx.pop(entry.value),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ).then((selectedStartDate) async {
      if (selectedStartDate != null && selectedStartDate is DateTime) {
        final permission = await Permission.sms.status;
        if (permission.isGranted) {
          _rescanSmsFrom(selectedStartDate);
        } else {
          await Permission.sms.request();
        }
      }
    });
  }

  // ── SMS SCAN LOGIC (unchanged) ──

  void _rescanSmsFrom(DateTime startDate) async {
    final now = DateTime.now();
    int processedCount = 0;
    int scannedCount = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final color = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.shadow.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: color.primary),
                const SizedBox(height: 20),
                Text(
                  'Scanning your SMS...',
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final telephony = Telephony.instance;
      final startMillis = startDate.millisecondsSinceEpoch;
      final allMessages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(SmsColumn.DATE)
            .greaterThanOrEqualTo(startMillis.toString()),
      );

      if (!mounted) return;

      final filteredMessages = allMessages.where((sms) {
        if (sms.date == null) return false;
        final smsDate = DateTime.fromMillisecondsSinceEpoch(sms.date!);
        return smsDate.isBefore(now);
      }).toList();

      for (var sms in filteredMessages) {
        scannedCount++;
        if (!checkForTransactionalMessage(sms.body)) continue;

        final smsHash = _generateSmsHash(
          sms.address ?? '',
          sms.date,
          sms.body ?? '',
        );
        if (SharedPrefsUtil.instance.isAlreadyProcessed(smsHash)) continue;

        SharedPrefsUtil.instance.storeProcessedHash(smsHash);
        final transactionInfo = _transactionUtil.getTransactionInfo(
          sms.body,
          sms.address,
          null,
          smsHash,
        );

        _processSmsForSaving(transactionInfo);
        processedCount++;

        if (processedCount % 10 == 0) {
          await Future.delayed(const Duration(milliseconds: 1));
        }
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        ref.invalidate(pendingTxnServiceProvider);
        ref.invalidate(pendingTxnDataProvider);
        ref.invalidate(transactionProvider);
        ref.invalidate(smsActivityProvider);
        ref.invalidate(pendingCountProvider);
      }
    } catch (e) {
      debugPrint('Error scanning SMS: $e');
      if (mounted) SnackbarService.error('Failed to scan SMS');
    } finally {
      if (context.mounted) context.pop();
      if (mounted) {
        final msg = processedCount > 0
            ? '🔎 Found $processedCount SMS related messages!'
            : 'No SMS found for selected period.';
        SnackbarService.info(msg);
      }
    }
  }

  void _processSmsForSaving(TransactionInfo sms) {
    if (!mounted) return;
    SmsProcessorService.instance.processSmsForSaving(
      sms,
      sms.transactionTime?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  String _generateSmsHash(String address, int? date, String body) {
    final input = '$address|$date|$body';
    return sha256.convert(utf8.encode(input)).toString();
  }

  Future<void> _handlePermissionToggle(bool on) async {
    HapticFeedback.mediumImpact();
    if (on) {
      final confirmed = await _showSmsPermissionDisclosure(context);
      if (confirmed != true) return;

      final permission = await Permission.sms.request();
      if (permission.isGranted) {
        setState(() => _permissionGranted = true);
        ref.invalidate(smsPermissionGrantedProvider);
        SnackbarService.success('SMS permission granted');
      } else {
        SnackbarService.error('SMS permission denied');
      }
    } else {
      _permissionDisableTapCount++;
      if (_permissionDisableTapCount >= 2) {
        openAppSettings();
      } else {
        SnackbarService.info('Tap again to open system settings');
      }
    }
  }

  Future<void> _handleAutoImportToggle(bool on) async {
    HapticFeedback.mediumImpact();
    setState(() => _smsImportEnabled = on);
    SharedPrefsUtil.instance.setSmsImportEnabled(on);
    ref.invalidate(smsPermissionGrantedProvider);
    if (on) {
      await setupSmsListener();
      if (!mounted) return;
      SnackbarService.success('Auto import enabled');
    } else {
      SnackbarService.info('Auto import disabled');
    }
  }
}

import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
// lib/features/profile/presentation/screens/setting_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/auth_service.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/profile/presentation/widgets/pin_entry_dialog.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState
    extends ConsumerState<SecuritySettingsScreen> {
  bool _biometricAvailable = false;
  bool _pinEnabled = false;
  bool _bioEnabled = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final auth = ref.read(authServiceProvider);
    final results = await Future.wait([
      auth.canCheckBiometrics(),
      auth.hasPin(),
      auth.isBiometricEnabled(),
    ]);
    if (!mounted) return;
    setState(() {
      _biometricAvailable = results[0];
      _pinEnabled = results[1];
      _bioEnabled = results[2];
      _loaded = true;
    });
  }

  Future<void> _toggleBiometric(bool on) async {
    HapticFeedback.mediumImpact();
    final auth = ref.read(authServiceProvider);
    final ctxt = AppLocalizations.of(context)!;
    if (on) {
      final ok = await auth.authenticateBiometric();
      if (!ok) {
        SnackbarService.error(BuddyMessages.biometricFailed);
        return;
      }
    }
    await auth.setBiometricEnabled(on);
    setState(() => _bioEnabled = on);
    SnackbarService.success(
      on ? ctxt.security_biometricEnabled : ctxt.security_biometricDisabled,
    );
  }

  Future<void> _togglePin(bool on) async {
    HapticFeedback.mediumImpact();
    final auth = ref.read(authServiceProvider);
    if (on) {
      final pin = await showDialog<String>(
        context: context,
        builder: (_) => const PinEntryDialog(length: 4),
      );
      if (pin == null || pin.length < 4) return;
      await auth.setPin(pin);
      SnackbarService.success(BuddyMessages.toggledOn('PIN'));
    } else {
      await auth.clearPin();
      await auth.setBiometricEnabled(false);
      setState(() => _bioEnabled = false);
      SnackbarService.success(BuddyMessages.toggledOff('PIN'));
    }
    setState(() => _pinEnabled = on);
  }

  Future<void> _changePin() async {
    HapticFeedback.mediumImpact();
    final auth = ref.read(authServiceProvider);

    // Verify current PIN first
    final current = await showDialog<String>(
      context: context,
      builder: (_) => const PinEntryDialog(length: 4),
    );
    if (current == null) return;
    if (!await auth.validatePin(current)) {
      SnackbarService.error(BuddyMessages.incorrectPin);
      return;
    }

    if (!context.mounted) return;

    // Enter new PIN
    final newPin = await showDialog<String>(
      context: context,
      builder: (_) => const PinEntryDialog(length: 4),
    );
    if (newPin == null || newPin.length < 4) return;

    await auth.setPin(newPin);
    SnackbarService.success(BuddyMessages.settingsSaved);
  }

  int get _securityScore {
    int score = 0;
    if (_pinEnabled) score++;
    if (_bioEnabled) score++;
    return score;
  }

  String _securityLabel(AppLocalizations ctxt) {
    switch (_securityScore) {
      case 0:
        return ctxt.security_unprotected;
      case 1:
        return ctxt.security_basic;
      default:
        return ctxt.security_strong;
    }
  }

  String _securityDescription(AppLocalizations ctxt) {
    if (_securityScore == 0) return ctxt.security_unprotectedDesc;
    return ctxt.security_protectionsActive(
      _securityScore,
      _biometricAvailable ? 2 : 1,
    );
  }

  Color _securityColor(ColorScheme color) {
    switch (_securityScore) {
      case 0:
        return color.error;
      case 1:
        return color.tertiary;
      default:
        return color.primary;
    }
  }

  IconData get _securityIcon {
    switch (_securityScore) {
      case 0:
        return LucideIcons.shieldOff;
      case 1:
        return LucideIcons.shield;
      default:
        return LucideIcons.shieldCheck;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctxt = AppLocalizations.of(context)!;
    final secColor = _securityColor(color);

    return Scaffold(
      appBar: AppBar(title: Text(ctxt.security_title)),
      body: !_loaded
          ? Padding(
              padding: EdgeInsets.all(spacing.cardHorizontal),
              child: Column(
                children: [
                  const DashboardCardSkeleton(),
                  SizedBox(height: spacing.elementGap),
                  const DashboardCardSkeleton(),
                ],
              ),
            )
          : ListView(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontal,
                vertical: spacing.cardVertical,
              ),
              children: [
                // ── HERO STATUS CARD ──
                Container(
                  padding: EdgeInsets.all(spacing.cardInner),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        secColor.withValues(alpha: isDark ? 0.2 : 0.12),
                        secColor.withValues(alpha: isDark ? 0.08 : 0.04),
                      ],
                    ),
                    border: Border.all(
                      color: secColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Animated shield icon
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutBack,
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) => Transform.scale(
                          scale: value,
                          child: child,
                        ),
                        child: Container(
                          padding: EdgeInsets.all(spacing.cardInner),
                          decoration: BoxDecoration(
                            color: secColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _securityIcon,
                            color: secColor,
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
                              _securityLabel(ctxt),
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: secColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _securityDescription(ctxt),
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

                _buildSectionHeader(
                  ctxt.security_authentication,
                  color,
                  textTheme,
                ),
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
                      // PIN toggle
                      _buildToggleRow(
                        icon: LucideIcons.keyRound,
                        title: ctxt.security_pinLock,
                        subtitle: _pinEnabled
                            ? ctxt.security_pinActive
                            : ctxt.security_pinSet,
                        value: _pinEnabled,
                        onChanged: _togglePin,
                        color: color,
                        textTheme: textTheme,
                        ctxt: ctxt,
                      ),
                      // Biometric toggle (conditional)
                      if (_biometricAvailable) ...[
                        Divider(
                          height: 1,
                          indent: 58,
                          color: color.outlineVariant.withValues(alpha: 0.4),
                        ),
                        _buildToggleRow(
                          icon: LucideIcons.scanFace,
                          title: ctxt.security_biometric,
                          subtitle: ctxt.security_biometricDesc,
                          value: _bioEnabled,
                          onChanged: _pinEnabled ? _toggleBiometric : null,
                          color: color,
                          textTheme: textTheme,
                          disabled: !_pinEnabled,
                          ctxt: ctxt,
                        ),
                      ],
                    ],
                  ),
                ),

                // ── MANAGE GROUP (only when PIN is active) ──
                if (_pinEnabled) ...[
                  const SizedBox(height: 24),
                  _buildSectionHeader(ctxt.security_manage, color, textTheme),
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
                    child: InkWell(
                      onTap: _changePin,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                LucideIcons.refreshCw,
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
                                    ctxt.security_changePin,
                                    style: textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    ctxt.security_changePinDesc,
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
                  ),
                ],
                const SizedBox(height: 24),

                // ── INFO CARD ──
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
                      Icon(
                        LucideIcons.info,
                        color: color.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ctxt.security_infoText,
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

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required ColorScheme color,
    required TextTheme textTheme,
    bool disabled = false,
    required AppLocalizations ctxt,
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
                  disabled ? ctxt.security_enablePinFirst : subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant.withValues(alpha: alpha),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: disabled ? null : onChanged,
          ),
        ],
      ),
    );
  }
}

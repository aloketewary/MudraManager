import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/auth_service.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/profile/presentation/widgets/pin_entry_dialog.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/shared/widgets/section_header.dart';
import 'package:mudra_manager/shared/widgets/setting_item.dart';
import 'package:mudra_manager/shared/widgets/settings_group_card.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';

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

  Future<void> _toggleBiometric(bool on, AppSpacing spacing) async {
    HapticFeedback.mediumImpact();
    final auth = ref.read(authServiceProvider);
    final ctxt = AppLocalizations.of(context)!;
    if (on) {
      final ok = await auth.authenticateBiometric();
      if (!ok) {
        SnackbarService.error(BuddyMessages.biometricFailed, spacing);
        return;
      }
    }
    await auth.setBiometricEnabled(on);
    setState(() => _bioEnabled = on);
    SnackbarService.success(
      on ? ctxt.security_biometricEnabled : ctxt.security_biometricDisabled,
      spacing,
    );
  }

  Future<void> _togglePin(bool on, AppSpacing spacing) async {
    HapticFeedback.mediumImpact();
    final auth = ref.read(authServiceProvider);
    if (on) {
      final pin = await showDialog<String>(
        context: context,
        builder: (_) => const PinEntryDialog(length: 4),
      );
      if (pin == null || pin.length < 4) return;
      await auth.setPin(pin);
      SnackbarService.success(BuddyMessages.toggledOn('PIN'), spacing);
    } else {
      await auth.clearPin();
      await auth.setBiometricEnabled(false);
      setState(() => _bioEnabled = false);
      SnackbarService.success(BuddyMessages.toggledOff('PIN'), spacing);
    }
    setState(() => _pinEnabled = on);
  }

  Future<void> _changePin(AppSpacing spacing) async {
    HapticFeedback.mediumImpact();
    final auth = ref.read(authServiceProvider);

    final current = await showDialog<String>(
      context: context,
      builder: (_) => const PinEntryDialog(length: 4),
    );
    if (current == null) return;
    if (!await auth.validatePin(current)) {
      SnackbarService.error(BuddyMessages.incorrectPin, spacing);
      return;
    }

    if (!context.mounted) return;

    final newPin = await showDialog<String>(
      context: context,
      builder: (_) => const PinEntryDialog(length: 4),
    );
    if (newPin == null || newPin.length < 4) return;

    await auth.setPin(newPin);
    SnackbarService.success(BuddyMessages.settingsSaved, spacing);
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
    final ctxt = AppLocalizations.of(context)!;

    return ScreenShell(
      config: ScreenShellConfig(
        title: ctxt.security_title,
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
    final secColor = _securityColor(color);

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
                  ? _buildContent(context, color, textTheme, spacing, isDark, ctxt, secColor)
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
    AppLocalizations ctxt,
    Color secColor,
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
        SecurityHeroCard(
          secColor: secColor,
          isDark: isDark,
          icon: _securityIcon,
          label: _securityLabel(ctxt),
          description: _securityDescription(ctxt),
          reduceMotion: MediaQuery.of(context).disableAnimations,
        ),
        SizedBox(height: spacing.sectionGap),

        // Authentication
        SectionHeader(ctxt.security_authentication),
        SizedBox(height: spacing.elementGap),
        SettingsGroupCard(
          items: [
            SettingItem(
              icon: LucideIcons.keyRound,
              title: ctxt.security_pinLock,
              subtitle: _pinEnabled ? ctxt.security_pinActive : ctxt.security_pinSet,
              onTap: () => _togglePin(!_pinEnabled, spacing),
              selected: _pinEnabled,
            ),
            if (_biometricAvailable)
              SettingItem(
                icon: LucideIcons.scanFace,
                title: ctxt.security_biometric,
                subtitle: _pinEnabled ? ctxt.security_biometricDesc : ctxt.security_enablePinFirst,
                onTap: () => _pinEnabled ? () => _toggleBiometric(!_bioEnabled, spacing) : null,
                disabled: !_pinEnabled,
                selected: _bioEnabled,
              ),
          ],
        ),
        SizedBox(height: spacing.elementGap * 2),

        // Manage
        if (_pinEnabled) ...[
          SectionHeader(ctxt.security_manage),
          SizedBox(height: spacing.elementGap),
          SettingsGroupCard(
            items: [
              SettingItem(
                icon: LucideIcons.refreshCw,
                title: ctxt.security_changePin,
                subtitle: ctxt.security_changePinDesc,
                onTap: () => _changePin(spacing),
              ),
            ],
          ),
          SizedBox(height: spacing.elementGap * 2),
        ],

        // Info
        SecurityInfoCard(color: color, textTheme: textTheme, spacing: spacing, ctxt: ctxt),
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
        _SecurityHeroSkeleton(spacing: spacing, color: color),
        SizedBox(height: spacing.sectionGap),
        _SettingsGroupSkeleton(spacing: spacing, color: color),
        SizedBox(height: spacing.elementGap * 2),
        _SettingsGroupSkeleton(spacing: spacing, color: color),
        SizedBox(height: spacing.sectionGap),
        SizedBox(height: spacing.sectionGap),
        AmbientBrandSection(showSignature: true, absorbBottomInset: false),
      ],
    );
  }
}

/// Hero card with ambient glow and animations
class SecurityHeroCard extends ConsumerWidget {
  final Color secColor;
  final bool isDark;
  final IconData icon;
  final String label;
  final String description;
  final bool reduceMotion;

  const SecurityHeroCard({
    super.key,
    required this.secColor,
    required this.isDark,
    required this.icon,
    required this.label,
    required this.description,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);

    return Semantics(
      label: 'Security status: $label',
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
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
          border: Border.all(color: secColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            // Icon with ambient glow
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
                      color: secColor.withValues(alpha: isDark ? 0.15 : 0.1),
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
                    builder: (context, value, child) => Transform.scale(
                      scale: value,
                      child: child,
                    ),
                    child: Container(
                      padding: EdgeInsets.all(spacing.elementGap * 1.5),
                      decoration: BoxDecoration(
                        color: secColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: secColor, size: 24),
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
                  color: secColor,
                ) ?? const TextStyle(fontWeight: FontWeight.w700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label),
                    SizedBox(height: spacing.elementGapUltraMin),
                    Text(
                      description,
                      style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
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

/// Info card with gradient background
class SecurityInfoCard extends StatelessWidget {
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;
  final AppLocalizations ctxt;

  const SecurityInfoCard({
    super.key,
    required this.color,
    required this.textTheme,
    required this.spacing,
    required this.ctxt,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Security information',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          gradient: LinearGradient(
            colors: [
              color.primary.withValues(alpha: 0.06),
              color.primary.withValues(alpha: 0.02),
            ],
          ),
          border: Border.all(color: color.primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(spacing.elementGapMin + 2),
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(spacing.radiusSmall),
              ),
              child: Icon(LucideIcons.info, color: color.primary, size: 16),
            ),
            SizedBox(width: spacing.elementGap),
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
    );
  }
}

/// Skeleton loader for hero card
class _SecurityHeroSkeleton extends StatelessWidget {
  final AppSpacing spacing;
  final ColorScheme color;

  const _SecurityHeroSkeleton({required this.spacing, required this.color});

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

/// Skeleton loader for settings group
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
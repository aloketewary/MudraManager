import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/theme/theme_provider.dart';
import 'package:mudra_manager/core/tone/tone_pack.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/account_display_style_provider.dart';
import 'package:mudra_manager/features/marketplace/services/marketplace_service.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/shared/widgets/pro_gate.dart';

final _guestModePluginProvider = FutureProvider.autoDispose((ref) async {
  return await MarketplaceService().isPluginEnabled('com.mudra.guest_mode');
});

class AppearanceScreen extends ConsumerStatefulWidget {
  const AppearanceScreen({super.key});

  @override
  ConsumerState<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends ConsumerState<AppearanceScreen> {
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentTheme = ref.watch(themeModeProvider);
    final highContrast = ref.watch(highContrastModeProvider);
    final guestPluginAsync = ref.watch(_guestModePluginProvider);
    final isGuestMode = ref.watch(guestModeProvider);
    final activeTone = ref.watch(tonePackProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.cardHorizontal,
          vertical: spacing.cardVertical,
        ),
        children: [
          // ── HERO STATUS CARD ──
          _buildHeroCard(
            color,
            textTheme,
            spacing,
            isDark,
            currentTheme,
            activeTone,
          ),
          const SizedBox(height: 24),

          // ── THEME MODE ──
          _buildSectionHeader('Theme Mode', color, textTheme),
          const SizedBox(height: 10),
          _buildThemeModeCard(color, textTheme, spacing, currentTheme),
          const SizedBox(height: 24),
          // ── COLOR THEME ──
          _buildSectionHeader('Color Theme', color, textTheme),
          const SizedBox(height: 10),
          _buildColorThemeCard(color, textTheme, spacing),
          const SizedBox(height: 24),
          _buildAccountStyleRow(color, textTheme),
          Divider(
            height: 1,
            indent: 58,
            color: color.outlineVariant.withValues(alpha: 0.4),
          ),
          // ── DISPLAY ──
          _buildSectionHeader('Display', color, textTheme),
          const SizedBox(height: 10),
          _buildDisplayCard(
            color,
            textTheme,
            spacing,
            highContrast,
            guestPluginEnabled: guestPluginAsync.valueOrNull == true,
            isGuestMode: isGuestMode,
          ),
          const SizedBox(height: 24),

          // ── TONE & VOICE ──
          _buildSectionHeader('Tone & Voice', color, textTheme),
          const SizedBox(height: 10),
          _buildToneCard(color, textTheme, spacing, activeTone, ref),
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
                Icon(LucideIcons.info, color: color.primary, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Theme and display changes apply instantly.',
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

  // ── HERO STATUS CARD ──
  Widget _buildHeroCard(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    bool isDark,
    AppThemeMode currentTheme,
    TonePack activeTone,
  ) {
    final accent = color.primary;
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: isDark ? 0.2 : 0.12),
            accent.withValues(alpha: isDark ? 0.08 : 0.04),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
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
              padding: EdgeInsets.all(spacing.cardInner),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.palette, color: accent, size: 28),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _themeModeLabel(currentTheme),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${activeTone.name} tone • '
                  '${isDark ? 'Dark' : 'Light'} appearance',
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

  Widget _buildAccountStyleRow(ColorScheme color, TextTheme textTheme) {
    final current = ref.watch(accountDisplayStyleProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              LucideIcons.layoutDashboard,
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
                  'Account Style',
                  style: textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                SegmentedButton<AccountDisplayStyle>(
                  segments: const [
                    ButtonSegment(
                      value: AccountDisplayStyle.carousel,
                      icon: Icon(LucideIcons.galleryHorizontalEnd, size: 16),
                      label: Text('Cards'),
                    ),
                    ButtonSegment(
                      value: AccountDisplayStyle.stack,
                      icon: Icon(LucideIcons.layers, size: 16),
                      label: Text('Stack'),
                    ),
                    ButtonSegment(
                      value: AccountDisplayStyle.bento,
                      icon: Icon(LucideIcons.layoutGrid, size: 16),
                      label: Text('Bento'),
                    ),
                  ],
                  selected: {current},
                  onSelectionChanged: (s) {
                    HapticFeedback.mediumImpact();
                    ref.read(accountDisplayStyleProvider.notifier).set(s.first);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorThemeCard(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final currentColorTheme = ref.watch(themeNotifierProvider);

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
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push(AppRoutes.themePicker);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: currentColorTheme.seedColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: currentColorTheme.seedColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          currentColorTheme.label,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (currentColorTheme.isPro) const ProBadge(),
                      ],
                    ),
                    Text(
                      currentColorTheme.subtitle,
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
    );
  }

  // ── THEME MODE CARD ──
  Widget _buildThemeModeCard(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppThemeMode currentTheme,
  ) {
    const modes = [
      (AppThemeMode.system, LucideIcons.smartphone, 'System Default'),
      (AppThemeMode.light, LucideIcons.sun, 'Light'),
      (AppThemeMode.dark, LucideIcons.moon, 'Dark'),
      (AppThemeMode.amoled, LucideIcons.eclipse, 'AMOLED'),
    ];

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
        children: modes.asMap().entries.map((entry) {
          final (mode, icon, label) = entry.value;
          final isLast = entry.key == modes.length - 1;
          final isSelected = currentTheme == mode;

          return Column(
            children: [
              InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  ref.read(themeModeProvider.notifier).setTheme(mode);
                },
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
                          color: (isSelected ? color.primary : color.onSurface)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected
                              ? color.primary
                              : color.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          label,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? color.primary : color.onSurface,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          LucideIcons.check,
                          color: color.primary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
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
  }

  // ── DISPLAY CARD ──
  Widget _buildDisplayCard(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    bool highContrast, {
    required bool guestPluginEnabled,
    required bool isGuestMode,
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
      child: Column(
        children: [
          _buildToggleRow(
            icon: LucideIcons.contrast,
            title: 'High Contrast',
            subtitle: 'Improves readability for low vision',
            value: highContrast,
            onChanged: (val) {
              HapticFeedback.mediumImpact();
              SharedPrefsUtil.instance.setHighContrastMode(val);
              ref.read(highContrastModeProvider.notifier).set(val);
            },
            color: color,
            textTheme: textTheme,
          ),
          if (guestPluginEnabled) ...[
            Divider(
              height: 1,
              indent: 58,
              color: color.outlineVariant.withValues(alpha: 0.4),
            ),
            _buildToggleRow(
              icon: LucideIcons.eyeOff,
              title: 'Guest Mode',
              subtitle: isGuestMode
                  ? 'Real amounts are hidden'
                  : 'Hide sensitive financial data',
              value: isGuestMode,
              onChanged: (val) {
                HapticFeedback.mediumImpact();
                ref.read(guestModeProvider.notifier).setGuestMode(val);
              },
              color: color,
              textTheme: textTheme,
            ),
          ],
        ],
      ),
    );
  }


  // ── TONE & VOICE CARD ──
  Widget _buildToneCard(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    TonePack activeTone,
    WidgetRef ref,
  ) {
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
          ...allTonePacks.asMap().entries.map((entry) {
            final tone = entry.value;
            final isLast = entry.key == allTonePacks.length - 1;
            final isSelected = activeTone.id == tone.id;
            final icon = _toneIcon(tone.id);

            return Column(
              children: [
                InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    ref.read(tonePackProvider.notifier).select(tone);
                    SnackbarService.success(
                      '${tone.name} tone activated',
                    );
                  },
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
                            color: (isSelected
                                    ? color.tertiary
                                    : color.onSurface)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            icon,
                            color: isSelected
                                ? color.tertiary
                                : color.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tone.name,
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? color.tertiary
                                      : color.onSurface,
                                ),
                              ),
                              Text(
                                tone.description,
                                style: textTheme.bodySmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            LucideIcons.check,
                            color: color.tertiary,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    indent: 58,
                    color: color.outlineVariant.withValues(alpha: 0.4),
                  ),
              ],
            );
          }),
          // Preview
          Divider(
            height: 1,
            color: color.outlineVariant.withValues(alpha: 0.4),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  LucideIcons.messageSquareQuote,
                  size: 16,
                  color: color.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '"${activeTone.txnAdded}"',
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _toneIcon(String id) {
    return switch (id) {
      'buddy' => LucideIcons.handshake,
      'professional' => LucideIcons.briefcase,
      'playful' => LucideIcons.gamepad2,
      'zen' => LucideIcons.leaf,
      _ => LucideIcons.messageCircle,
    };
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

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ColorScheme color,
    required TextTheme textTheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  String _themeModeLabel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Light Mode';
      case AppThemeMode.dark:
        return 'Dark Mode';
      case AppThemeMode.amoled:
        return 'AMOLED Mode';
      case AppThemeMode.system:
        return 'System Default';
    }
  }
}

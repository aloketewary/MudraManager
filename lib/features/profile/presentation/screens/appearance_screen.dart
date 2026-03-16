// lib/features/profile/presentation/screens/appearance_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/l10n_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/theme_provider.dart';
import 'package:mudra_manager/features/marketplace/services/marketplace_service.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';

final _guestModePluginProvider = FutureProvider.autoDispose((ref) async {
  return await MarketplaceService().isPluginEnabled('com.mudra.guest_mode');
});

class AppearanceScreen extends ConsumerStatefulWidget {
  const AppearanceScreen({super.key});

  @override
  ConsumerState<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends ConsumerState<AppearanceScreen> {
  static const _betaLanguages = {'bn', 'hi'};

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentTheme = ref.watch(themeModeProvider);
    final currentLocale = ref.watch(localeProvider);
    final highContrast = ref.watch(highContrastModeProvider);
    final guestPluginAsync = ref.watch(_guestModePluginProvider);
    final isGuestMode = ref.watch(guestModeProvider);

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
            currentLocale,
          ),
          const SizedBox(height: 24),

          // ── THEME MODE ──
          _buildSectionHeader('Theme Mode', color, textTheme),
          const SizedBox(height: 10),
          _buildThemeModeCard(color, textTheme, spacing, currentTheme),
          const SizedBox(height: 24),

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

          // ── LANGUAGE ──
          _buildSectionHeader('Language', color, textTheme),
          const SizedBox(height: 10),
          _buildLanguageCard(color, textTheme, spacing, currentLocale),
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
                    'Theme and language changes apply instantly. '
                    'Guest mode can be enabled from the Plugins screen.',
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
    Locale currentLocale,
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
                  '${currentLocale.displayName()} • '
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

  // ── LANGUAGE CARD ──
  Widget _buildLanguageCard(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    Locale currentLocale,
  ) {
    final locales = AppLocalizations.supportedLocales;

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
        children: locales.asMap().entries.map((entry) {
          final locale = entry.value;
          final isLast = entry.key == locales.length - 1;
          final isSelected = currentLocale.languageCode == locale.languageCode;
          final isBeta = _betaLanguages.contains(locale.languageCode);

          return Column(
            children: [
              InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  LanguageService.changeLanguage(context, ref, locale);
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
                          LucideIcons.languages,
                          color: isSelected
                              ? color.primary
                              : color.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              locale.displayName(),
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? color.primary
                                    : color.onSurface,
                              ),
                            ),
                            if (isBeta) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: color.tertiary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'beta',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: color.tertiary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
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

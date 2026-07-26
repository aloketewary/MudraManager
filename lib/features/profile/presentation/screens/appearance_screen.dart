import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/theme/theme_provider.dart';
import 'package:mudra_manager/core/tone/tone_pack.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/account_display_style_provider.dart';
import 'package:mudra_manager/features/marketplace/services/marketplace_service.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/shared/widgets/pro_gate.dart';
import 'package:mudra_manager/shared/widgets/section_header.dart';
import 'package:mudra_manager/shared/widgets/settings_group_card.dart';
import 'package:mudra_manager/shared/widgets/setting_item.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';

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
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentTheme = ref.watch(themeModeProvider);
    final highContrast = ref.watch(highContrastModeProvider);
    final guestPluginAsync = ref.watch(_guestModePluginProvider);
    final isGuestMode = ref.watch(guestModeProvider);
    final activeTone = ref.watch(tonePackProvider);
    final currentColorTheme = ref.watch(themeNotifierProvider);
    final accountStyle = ref.watch(accountDisplayStyleProvider);

    final guestPluginEnabled = guestPluginAsync.maybeWhen(
        data: (v) => v, orElse: () => false);
    final loaded = guestPluginAsync.maybeWhen(
        data: (_) => true, orElse: () => false);

    return ScreenShell(
      config: ScreenShellConfig(
        title: AppLocalizations.of(context)!.appearance_title,
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      actions: ScreenActions.empty,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth > 600 ? 600.0 : double.infinity;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: AnimatedSwitcher(
                duration:
                    reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                key: ValueKey(loaded),
                child: loaded
                    ? _AppearanceContent(
                        reduceMotion: reduceMotion,
                        isDark: isDark,
                        currentTheme: currentTheme,
                        highContrast: highContrast,
                        guestPluginEnabled: guestPluginEnabled,
                        isGuestMode: isGuestMode,
                        activeTone: activeTone,
                        currentColorTheme: currentColorTheme,
                        accountStyle: accountStyle,
                      )
                    : const _AppearanceLoading(),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ║                          APPEARANCE CONTENT                                ║
// ════════════════════════════════════════════════════════════════════════════

class _AppearanceContent extends ConsumerWidget {
  final bool reduceMotion;
  final bool isDark;
  final AppThemeMode currentTheme;
  final bool highContrast;
  final bool guestPluginEnabled;
  final bool isGuestMode;
  final TonePack activeTone;
  final AppColorTheme currentColorTheme;
  final AccountDisplayStyle accountStyle;

  const _AppearanceContent({
    required this.reduceMotion,
    required this.isDark,
    required this.currentTheme,
    required this.highContrast,
    required this.guestPluginEnabled,
    required this.isGuestMode,
    required this.activeTone,
    required this.currentColorTheme,
    required this.accountStyle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      children: [
        _HeroCard(
          reduceMotion: reduceMotion,
          isDark: isDark,
          currentTheme: currentTheme,
          activeTone: activeTone,
        ),
        SizedBox(height: spacing.sectionGap),
        _ThemeModeSection(
          reduceMotion: reduceMotion,
          currentTheme: currentTheme,
          color: color,
          textTheme: textTheme,
          spacing: spacing,
          ctxt: ctxt,
        ),
        SizedBox(height: spacing.sectionGap),
        _ColorThemeSection(
          currentColorTheme: currentColorTheme,
          color: color,
          textTheme: textTheme,
          spacing: spacing,
          ctxt: ctxt,
        ),
        SizedBox(height: spacing.sectionGap),
        _AccountStyleSection(
          accountStyle: accountStyle,
          color: color,
          textTheme: textTheme,
          spacing: spacing,
          ctxt: ctxt,
        ),
        SizedBox(height: spacing.sectionGap),
        _DisplaySection(
          highContrast: highContrast,
          guestPluginEnabled: guestPluginEnabled,
          isGuestMode: isGuestMode,
          color: color,
          textTheme: textTheme,
          spacing: spacing,
          ctxt: ctxt,
        ),
        SizedBox(height: spacing.sectionGap),
        _ToneSection(
          activeTone: activeTone,
          color: color,
          textTheme: textTheme,
          spacing: spacing,
          ctxt: ctxt,
        ),
        SizedBox(height: spacing.sectionGap),
        const AmbientBrandSection(showSignature: false, absorbBottomInset: false),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ║                          LOADING STATE                                     ║
// ════════════════════════════════════════════════════════════════════════════

class _AppearanceLoading extends ConsumerWidget {
  const _AppearanceLoading();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      children: [
        _HeroSkeleton(spacing: spacing, color: color),
        SizedBox(height: spacing.sectionGap),
        _ThemeModeSkeleton(spacing: spacing, color: color),
        SizedBox(height: spacing.sectionGap),
        _ColorThemeSkeleton(spacing: spacing, color: color),
        SizedBox(height: spacing.sectionGap),
        _DisplaySkeleton(spacing: spacing, color: color),
        SizedBox(height: spacing.sectionGap),
        _ToneSkeleton(spacing: spacing, color: color),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ║                          HERO CARD                                         ║
// ════════════════════════════════════════════════════════════════════════════

class _HeroCard extends ConsumerWidget {
  final bool reduceMotion;
  final bool isDark;
  final AppThemeMode currentTheme;
  final TonePack activeTone;

  const _HeroCard({
    required this.reduceMotion,
    required this.isDark,
    required this.currentTheme,
    required this.activeTone,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;
    final accent = color.primary;

    return Semantics(
      label: '${_themeModeLabel(ctxt, currentTheme)} theme, ${activeTone.name} tone',
      child: Container(
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
        child: TweenAnimationBuilder<double>(
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) =>
              Transform.scale(scale: value, child: child),
          child: Padding(
            padding: EdgeInsets.all(spacing.cardInner),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacing.cardInner),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.palette, color: accent, size: 28),
                ),
                SizedBox(width: spacing.cardInner),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _themeModeLabel(ctxt, currentTheme),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                      Text(
                        '${activeTone.name} tone • '
                        '${isDark ? ctxt.appearance_darkAppearance : ctxt.appearance_lightAppearance}',
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
        ),
      ),
    );
  }

  String _themeModeLabel(AppLocalizations ctxt, AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.light => ctxt.appearance_lightMode,
      AppThemeMode.dark => ctxt.appearance_darkMode,
      AppThemeMode.amoled => ctxt.appearance_amoledMode,
      AppThemeMode.system => ctxt.appearance_systemDefault,
    };
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ║                          THEME MODE SECTION                                ║
// ════════════════════════════════════════════════════════════════════════════

class _ThemeModeSection extends ConsumerWidget {
  final bool reduceMotion;
  final AppThemeMode currentTheme;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;
  final AppLocalizations ctxt;

  const _ThemeModeSection({
    required this.reduceMotion,
    required this.currentTheme,
    required this.color,
    required this.textTheme,
    required this.spacing,
    required this.ctxt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modes = [
      (AppThemeMode.system, LucideIcons.smartphone, ctxt.appearance_systemDefault),
      (AppThemeMode.light, LucideIcons.sun, ctxt.appearance_lightMode),
      (AppThemeMode.dark, LucideIcons.moon, ctxt.appearance_darkMode),
      (AppThemeMode.amoled, LucideIcons.eclipse, 'AMOLED'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(ctxt.appearance_themeMode),
        SizedBox(height: spacing.elementGap),
        SettingsGroupCard(
          items: modes.map((modeData) {
            final (mode, icon, label) = modeData;
            final isSelected = currentTheme == mode;
            return SettingItem(
              icon: icon,
              title: label,
              subtitle: '',
              onTap: () {
                HapticFeedback.mediumImpact();
                ref.read(themeModeProvider.notifier).setTheme(mode);
              },
              selected: isSelected,
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ════════════════════════════��════════════════════════════════════════════════
// ║                          COLOR THEME SECTION                               ║
// ════════════════════════════════════════════════════════════════════════════

class _ColorThemeSection extends ConsumerWidget {
  final AppColorTheme currentColorTheme;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;
  final AppLocalizations ctxt;

  const _ColorThemeSection({
    required this.currentColorTheme,
    required this.color,
    required this.textTheme,
    required this.spacing,
    required this.ctxt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(ctxt.appearance_colorTheme),
        SizedBox(height: spacing.elementGap),
        SettingsGroupCard(
          items: [
            SettingItem(
              icon: LucideIcons.palette,
              title: currentColorTheme.label,
              subtitle: currentColorTheme.subtitle,
              onTap: () {
                HapticFeedback.mediumImpact();
                context.push(AppRoutes.skinPicker);
              },
              selected: true,
              trailing: currentColorTheme.isPro
                  ? const ProBadge()
                  : Icon(
                      LucideIcons.chevronRight,
                      color: color.onSurfaceVariant,
                      size: 20,
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ║                          ACCOUNT STYLE SECTION                             ║
// ════════════════════════════════════════════════════════════════════════════

class _AccountStyleSection extends ConsumerWidget {
  final AccountDisplayStyle accountStyle;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;
  final AppLocalizations ctxt;

  const _AccountStyleSection({
    required this.accountStyle,
    required this.color,
    required this.textTheme,
    required this.spacing,
    required this.ctxt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(ctxt.appearance_accountStyle),
        SizedBox(height: spacing.elementGap),
        Container(
          padding: EdgeInsets.all(spacing.cardInner),
          decoration: BoxDecoration(
            color: color.surfaceContainerLow,
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            border: Border.all(color: color.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
                child: Icon(
                  LucideIcons.layoutDashboard,
                  color: color.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: spacing.cardInner),
              Expanded(
                child: SegmentedButton<AccountDisplayStyle>(
                  segments: [
                    ButtonSegment(
                      value: AccountDisplayStyle.carousel,
                      icon: const Icon(LucideIcons.galleryHorizontalEnd, size: 16),
                      label: Text(ctxt.appearance_cards),
                    ),
                    ButtonSegment(
                      value: AccountDisplayStyle.stack,
                      icon: const Icon(LucideIcons.layers, size: 16),
                      label: Text(ctxt.appearance_stack),
                    ),
                    ButtonSegment(
                      value: AccountDisplayStyle.bento,
                      icon: const Icon(LucideIcons.layoutGrid, size: 16),
                      label: Text(ctxt.appearance_bento),
                    ),
                  ],
                  selected: {accountStyle},
                  onSelectionChanged: (s) {
                    HapticFeedback.mediumImpact();
                    ref.read(accountDisplayStyleProvider.notifier).set(s.first);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ║                          DISPLAY SECTION                                   ║
// ════════════════════════════════════════════════════════════════════════════

class _DisplaySection extends ConsumerWidget {
  final bool highContrast;
  final bool guestPluginEnabled;
  final bool isGuestMode;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;
  final AppLocalizations ctxt;

  const _DisplaySection({
    required this.highContrast,
    required this.guestPluginEnabled,
    required this.isGuestMode,
    required this.color,
    required this.textTheme,
    required this.spacing,
    required this.ctxt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = <SettingItem>[
      SettingItem(
        icon: LucideIcons.contrast,
        title: ctxt.appearance_highContrast,
        subtitle: ctxt.appearance_highContrastDesc,
        onTap: () {
          HapticFeedback.mediumImpact();
          final newValue = !highContrast;
          SharedPrefsUtil.instance.setHighContrastMode(newValue);
          ref.read(highContrastModeProvider.notifier).set(newValue);
        },
        selected: true,
      ),
    ];

    if (guestPluginEnabled) {
      items.add(
        SettingItem(
          icon: LucideIcons.eyeOff,
          title: ctxt.appearance_guestMode,
          subtitle:
              isGuestMode ? ctxt.appearance_guestModeOnDesc : ctxt.appearance_guestModeOffDesc,
          onTap: () {
            HapticFeedback.mediumImpact();
            ref.read(guestModeProvider.notifier).setGuestMode(!isGuestMode);
          },
          selected: true,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(ctxt.appearance_display),
        SizedBox(height: spacing.elementGap),
        SettingsGroupCard(items: items),
        SizedBox(height: spacing.sectionGap),
        Container(
          padding: const EdgeInsets.all(14),
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
                  ctxt.appearance_changesApplyInstantly,
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
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ║                          TONE SECTION                                      ║
// ═════════════════════════════���══════════════════════════════════════════════

class _ToneSection extends ConsumerWidget {
  final TonePack activeTone;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;
  final AppLocalizations ctxt;

  const _ToneSection({
    required this.activeTone,
    required this.color,
    required this.textTheme,
    required this.spacing,
    required this.ctxt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(ctxt.appearance_toneVoice),
        SizedBox(height: spacing.elementGap),
        SettingsGroupCard(
          items: allTonePacks.map((tone) {
            final isSelected = activeTone.id == tone.id;
            final icon = _toneIcon(tone.id);
            return SettingItem(
              icon: icon,
              title: tone.name,
              subtitle: tone.description,
              onTap: () {
                HapticFeedback.mediumImpact();
                ref.read(tonePackProvider.notifier).select(tone);
                SnackbarService.success(
                  ctxt.appearance_toneActivated(tone.name),
                  spacing,
                );
              },
              selected: isSelected,
            );
          }).toList(),
        ),
        SizedBox(height: spacing.elementGap),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            children: [
              Icon(
                LucideIcons.messageSquareQuote,
                size: 16,
                color: color.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              SizedBox(width: spacing.elementGap),
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
    );
  }

  IconData _toneIcon(String id) {
    return switch (id) {
      'friendly' => LucideIcons.handshake,
      'professional' => LucideIcons.briefcase,
      'motivational' => LucideIcons.trophy,
      'calm' => LucideIcons.leaf,
      _ => LucideIcons.messageCircle,
    };
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ║                          SKELETON LOADERS                                  ║
// ════════════════════════════════════════════════════════════════════════════

class _HeroSkeleton extends StatelessWidget {
  final AppSpacing spacing;
  final ColorScheme color;

  const _HeroSkeleton({required this.spacing, required this.color});

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
            width: 56,
            height: 56,
            borderRadius: BorderRadius.circular(28),
          ),
          SizedBox(width: spacing.cardInner),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader(width: 120, height: 20),
                SizedBox(height: spacing.elementGapMin),
                const SkeletonLoader(width: 180, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeSkeleton extends StatelessWidget {
  final AppSpacing spacing;
  final ColorScheme color;

  const _ThemeModeSkeleton({required this.spacing, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonLoader(width: 120, height: 20),
        SizedBox(height: spacing.elementGap),
        Container(
          decoration: BoxDecoration(
            color: color.surfaceContainerLow,
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: List.generate(4, (index) {
              final isLast = index == 3;
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
                      child: SkeletonLoader(width: 100, height: 16),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _ColorThemeSkeleton extends StatelessWidget {
  final AppSpacing spacing;
  final ColorScheme color;

  const _ColorThemeSkeleton({required this.spacing, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonLoader(width: 100, height: 20),
        SizedBox(height: spacing.elementGap),
        Container(
          decoration: BoxDecoration(
            color: color.surfaceContainerLow,
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SkeletonLoader(
                width: 36,
                height: 36,
                borderRadius: BorderRadius.circular(spacing.radiusSmall),
              ),
              SizedBox(width: spacing.cardInner),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonLoader(width: 80, height: 16),
                    SizedBox(height: spacing.elementGapMin),
                    const SkeletonLoader(width: 120, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DisplaySkeleton extends StatelessWidget {
  final AppSpacing spacing;
  final ColorScheme color;

  const _DisplaySkeleton({required this.spacing, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonLoader(width: 80, height: 20),
        SizedBox(height: spacing.elementGap),
        Container(
          decoration: BoxDecoration(
            color: color.surfaceContainerLow,
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SkeletonLoader(width: 100, height: 16),
                          SizedBox(height: spacing.elementGapMin),
                          const SkeletonLoader(width: 150, height: 12),
                        ],
                      ),
                    ),
                    SkeletonLoader(
                      width: 52,
                      height: 32,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _ToneSkeleton extends StatelessWidget {
  final AppSpacing spacing;
  final ColorScheme color;

  const _ToneSkeleton({required this.spacing, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonLoader(width: 100, height: 20),
        SizedBox(height: spacing.elementGap),
        Container(
          decoration: BoxDecoration(
            color: color.surfaceContainerLow,
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: List.generate(4, (index) {
              final isLast = index == 3;
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SkeletonLoader(width: 80, height: 16),
                          SizedBox(height: spacing.elementGapMin),
                          const SkeletonLoader(width: 150, height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
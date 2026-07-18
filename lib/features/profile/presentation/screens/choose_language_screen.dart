import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/l10n_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';
import 'package:mudra_manager/shared/widgets/section_header.dart';
import 'package:mudra_manager/shared/widgets/settings_group_card.dart';
import 'package:mudra_manager/shared/widgets/setting_item.dart';

class ChooseLanguageScreen extends ConsumerStatefulWidget {
  const ChooseLanguageScreen({super.key});

  @override
  ConsumerState<ChooseLanguageScreen> createState() =>
      _ChooseLanguageScreenState();
}

class _ChooseLanguageScreenState extends ConsumerState<ChooseLanguageScreen> {
  static final List<String> betaLanguage = [
    'bn', 'hi', 'es', 'pt', 'id',
    'fr', 'de', 'ar', 'tr', 'th', 'vi', 'sw',
    'ko', 'ja', 'zh', 'ms', 'ta', 'te', 'mr', 'gu', 'kn', 'ml',
    'pa', 'or', 'as', 'ur', 'sd', 'ne', 'si', 'bo',
    'doi', 'kok', 'mai', 'mni', 'sat', 'brx',
  ];

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.read(localeProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;

    return ScreenShell(
      config: ScreenShellConfig(
        title: ctxt.language_settings_appbar_title,
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
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontal,
                  vertical: spacing.cardVertical,
                ),
                children: [
                  SectionHeader(ctxt.language_settings_appbar_title),
                  SizedBox(height: spacing.elementGap),
                  _LanguageList(
                    currentLocale: currentLocale,
                    betaLanguage: betaLanguage,
                    color: color,
                    textTheme: textTheme,
                    spacing: spacing,
                    ctxt: ctxt,
                  ),
                  SizedBox(height: spacing.sectionGap),
                  const _InfoCard(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LanguageList extends ConsumerWidget {
  final Locale currentLocale;
  final List<String> betaLanguage;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;
  final AppLocalizations ctxt;

  const _LanguageList({
    required this.currentLocale,
    required this.betaLanguage,
    required this.color,
    required this.textTheme,
    required this.spacing,
    required this.ctxt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsGroupCard(
      items: AppLocalizations.supportedLocales.map((locale) {
        final isSelected = currentLocale.languageCode == locale.languageCode;
        final isBeta = betaLanguage.contains(locale.languageCode);

        return SettingItem(
          icon: LucideIcons.globe,
          title: locale.displayName(),
          subtitle: isBeta ? 'beta' : '',
          onTap: () {
            HapticFeedback.mediumImpact();
            LanguageService.changeLanguage(context, ref, locale);
          },
          selected: isSelected,
        );
      }).toList(),
    );
  }
}

class _InfoCard extends ConsumerWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;

    return Container(
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
              ctxt.language_settings_appbar_title,
              style: textTheme.bodySmall?.copyWith(
                color: color.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
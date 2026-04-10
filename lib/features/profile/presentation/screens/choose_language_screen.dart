import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/l10n_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

class ChooseLanguageScreen extends ConsumerStatefulWidget {
  const ChooseLanguageScreen({super.key});

  @override
  ConsumerState<ChooseLanguageScreen> createState() =>
      _ChooseLanguageScreenState();
}

class _ChooseLanguageScreenState extends ConsumerState<ChooseLanguageScreen> {
  static final List<String> betaLanguage = ['bn', 'hi'];

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.read(localeProvider);
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ctxt.language_settings_appbar_title,
          style: textTheme.titleLarge,
        ),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: spacing.cardVertical),
        children: [
          ...AppLocalizations.supportedLocales.map(
            (locale) {
              final isSelected = currentLocale.languageCode == locale.languageCode;
              final isBeta = betaLanguage.contains(locale.languageCode);

              return ListTile(
                leading: Icon(
                  isSelected ? LucideIcons.languages : LucideIcons.globe,
                  color: isSelected ? color.primary : color.onSurfaceVariant,
                ),
                title: Row(
                  children: [
                    Text(locale.displayName()),
                    if (isBeta) ...[
                      SizedBox(width: spacing.elementGap),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: spacing.elementGap,
                          vertical: spacing.elementGapUltraMin,
                        ),
                        decoration: BoxDecoration(
                          color: color.primary,
                          borderRadius: BorderRadius.circular(spacing.radiusMedium),
                        ),
                        child: Text(
                          'beta',
                          style: textTheme.labelSmall?.copyWith(color: color.onPrimary),
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: isSelected
                    ? Icon(LucideIcons.check, color: color.primary)
                    : null,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  LanguageService.changeLanguage(context, ref, locale);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

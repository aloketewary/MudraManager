import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/l10n/app_localizations.dart' show AppLocalizations;
import 'package:mudra_manager/providers/l10n_provider.dart';
import 'package:mudra_manager/util/localization_extension.dart';

class ChooseLanguageScreen extends ConsumerStatefulWidget {
  const ChooseLanguageScreen({super.key});

  @override
  ConsumerState<ChooseLanguageScreen> createState() => _ChooseLanguageScreenState();
}

class _ChooseLanguageScreenState extends ConsumerState<ChooseLanguageScreen> {
  static final List<String> betaLanguage = ['bn', 'hi'];

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.read(localeProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.language_settings_appbar_title, style: textTheme.titleLarge?.copyWith(color: color.onPrimary)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...AppLocalizations.supportedLocales.map(
              (locale) => _buildLanguageTile(
                context,
                ref,
                language: locale.displayName(),
                locale: locale,
                isSelected: currentLocale.languageCode == locale.languageCode,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  static Widget _buildLanguageTile(
    BuildContext context,
    WidgetRef ref, {
    required String language,
    required Locale locale,
    required bool isSelected,
  }) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isBeta = betaLanguage.contains(locale.languageCode);

    return ListTile(
      leading: Icon(isSelected ? Icons.language_outlined : Icons.language),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(language),
          if (isBeta) SizedBox(width: 8),
          if (isBeta) Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            decoration: BoxDecoration(
              color: color.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text('beta', style: textTheme.labelSmall?.copyWith(color: color.onPrimary)),
          ),
        ],
      ),
      trailing: isSelected ? Icon(Icons.check, color: color.primary) : null,
      onTap: () => LanguageService.changeLanguage(context, ref, locale),
    );
  }
}
